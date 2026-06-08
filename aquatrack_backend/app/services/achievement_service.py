"""Achievement progress (derived-on-read) and milestone-XP claiming.

See docs/adr/0003-levels-and-achievements.md. Achievements are lifetime
milestones: progress is computed from source tables, never stored per-row, and
only Claims are persisted (AchievementClaim). XP is credited on Claim, never on
unlock. The registry below is the single source of truth for the catalog
(mirrored to docs in achievements_spec.md); the legacy per-user Achievement
table and its XP-by-type map are no longer used by the Level screen.
"""

from dataclasses import dataclass
from typing import Callable, Dict, List

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.leveling import calculate_level_from_xp
from app.models import (AchievementClaim, ConversationSession, DailySummary,
                        Friend, IntakeLog, QuestClaim, ScanHistory, User)

# --- errors -------------------------------------------------------------


class AchievementError(Exception):
    """Base class for achievement claim errors."""


class AchievementNotFound(AchievementError):
    pass


class AchievementNotDone(AchievementError):
    pass


class AchievementAlreadyClaimed(AchievementError):
    pass


# --- per-tier Milestone XP ----------------------------------------------

_TIER_XP = {
    "common": 50,
    "rare": 150,
    "epic": 400,
    "legendary": 1000,
}


# --- derived user stats snapshot ----------------------------------------


@dataclass
class _Stats:
    longest_streak: int
    total_volume_ml: int
    level: int
    log_count: int
    goal_days: int
    quest_claims: int
    coach_sessions: int
    scans: int
    friends: int


def _scalar(db, query) -> int:
    return query.scalar() or 0


def _total_xp(db: Session, user: User) -> int:
    """True Total XP = intake-log XP + bonus/quest XP on the user record.

    The canonical level (and any level-gated avatar) must be derived from this
    full sum, never from user.total_xp alone (which holds only the bonus part).
    """
    intake_xp = _scalar(
        db,
        db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp)).filter(
            IntakeLog.user_id == user.id
        ),
    )
    return intake_xp + (user.total_xp or 0)


def _load_stats(db: Session, user: User) -> _Stats:
    """One snapshot of every counter the catalog measures (9 queries, not 41)."""
    total_xp = _total_xp(db, user)

    return _Stats(
        longest_streak=user.longest_streak or 0,
        total_volume_ml=_scalar(
            db,
            db.query(func.sum(IntakeLog.effective_volume_ml)).filter(
                IntakeLog.user_id == user.id
            ),
        ),
        level=calculate_level_from_xp(total_xp)["level"],
        log_count=_scalar(
            db, db.query(func.count(IntakeLog.id)).filter(IntakeLog.user_id == user.id)
        ),
        goal_days=_scalar(
            db,
            db.query(func.count(DailySummary.id)).filter(
                DailySummary.user_id == user.id,
                DailySummary.goal_achieved.is_(True),
            ),
        ),
        quest_claims=_scalar(
            db,
            db.query(func.count(QuestClaim.id)).filter(QuestClaim.user_id == user.id),
        ),
        coach_sessions=_scalar(
            db,
            db.query(func.count(ConversationSession.id)).filter(
                ConversationSession.user_id == user.id
            ),
        ),
        scans=_scalar(
            db,
            db.query(func.count(ScanHistory.id)).filter(ScanHistory.user_id == user.id),
        ),
        friends=_scalar(
            db,
            db.query(func.count(Friend.id)).filter(
                Friend.user_id == user.id,
                Friend.is_active.is_(True),
                Friend.is_blocked.is_(False),
            ),
        ),
    )


# --- registry (spec: achievements_spec.md) ------------------------------


@dataclass(frozen=True)
class AchievementDef:
    id: str
    domain: str
    tier: str
    name: str
    description: str
    icon: str
    target: int
    progress_fn: Callable[[_Stats], int]

    @property
    def reward_xp(self) -> int:
        return _TIER_XP[self.tier]


def _d(id, domain, tier, name, description, icon, target, fn) -> AchievementDef:
    return AchievementDef(id, domain, tier, name, description, icon, target, fn)


CATALOG: List[AchievementDef] = [
    # ── Streak (longest streak ever reached) ────────────────────────
    _d(
        "streak_3",
        "streak",
        "common",
        "Khởi đầu",
        "Giữ chuỗi 3 ngày liên tiếp",
        "🔥",
        3,
        lambda s: s.longest_streak,
    ),
    _d(
        "streak_7",
        "streak",
        "rare",
        "Chiến binh tuần",
        "Giữ chuỗi 7 ngày liên tiếp",
        "⚔️",
        7,
        lambda s: s.longest_streak,
    ),
    _d(
        "streak_14",
        "streak",
        "rare",
        "Nửa tháng bền bỉ",
        "Giữ chuỗi 14 ngày liên tiếp",
        "🌟",
        14,
        lambda s: s.longest_streak,
    ),
    _d(
        "streak_30",
        "streak",
        "epic",
        "Bậc thầy tháng",
        "Giữ chuỗi 30 ngày liên tiếp",
        "👑",
        30,
        lambda s: s.longest_streak,
    ),
    _d(
        "streak_60",
        "streak",
        "epic",
        "Hai tháng kiên định",
        "Giữ chuỗi 60 ngày liên tiếp",
        "💎",
        60,
        lambda s: s.longest_streak,
    ),
    _d(
        "streak_100",
        "streak",
        "legendary",
        "Centurion",
        "Giữ chuỗi 100 ngày liên tiếp",
        "🏛️",
        100,
        lambda s: s.longest_streak,
    ),
    _d(
        "streak_365",
        "streak",
        "legendary",
        "Trọn một năm",
        "Giữ chuỗi 365 ngày liên tiếp",
        "🗓️",
        365,
        lambda s: s.longest_streak,
    ),
    # ── Volume (lifetime effective ml) ──────────────────────────────
    _d(
        "volume_1l",
        "volume",
        "common",
        "Lít đầu tiên",
        "Tích luỹ 1 lít nước",
        "💧",
        1_000,
        lambda s: s.total_volume_ml,
    ),
    _d(
        "volume_10l",
        "volume",
        "common",
        "Thùng nước",
        "Tích luỹ 10 lít nước",
        "🪣",
        10_000,
        lambda s: s.total_volume_ml,
    ),
    _d(
        "volume_50l",
        "volume",
        "rare",
        "Bể nhỏ",
        "Tích luỹ 50 lít nước",
        "🛁",
        50_000,
        lambda s: s.total_volume_ml,
    ),
    _d(
        "volume_100l",
        "volume",
        "rare",
        "Biển nước",
        "Tích luỹ 100 lít nước",
        "🌊",
        100_000,
        lambda s: s.total_volume_ml,
    ),
    _d(
        "volume_500l",
        "volume",
        "epic",
        "Đại dương",
        "Tích luỹ 500 lít nước",
        "🌌",
        500_000,
        lambda s: s.total_volume_ml,
    ),
    _d(
        "volume_1000l",
        "volume",
        "legendary",
        "Hydrator Thiên niên kỷ",
        "Tích luỹ 1000 lít nước",
        "🏆",
        1_000_000,
        lambda s: s.total_volume_ml,
    ),
    # ── Level ───────────────────────────────────────────────────────
    _d(
        "level_5",
        "level",
        "common",
        "Tân binh",
        "Đạt cấp 5",
        "🆙",
        5,
        lambda s: s.level,
    ),
    _d(
        "level_10",
        "level",
        "rare",
        "Lão luyện",
        "Đạt cấp 10",
        "⬆️",
        10,
        lambda s: s.level,
    ),
    _d(
        "level_20",
        "level",
        "epic",
        "Chuyên gia",
        "Đạt cấp 20",
        "🚀",
        20,
        lambda s: s.level,
    ),
    _d(
        "level_30",
        "level",
        "epic",
        "Siêu phàm",
        "Đạt cấp 30",
        "✨",
        30,
        lambda s: s.level,
    ),
    _d(
        "level_50",
        "level",
        "legendary",
        "Đỉnh cao",
        "Đạt cấp 50",
        "🌠",
        50,
        lambda s: s.level,
    ),
    # ── Frequency (lifetime log count) ──────────────────────────────
    _d(
        "log_first",
        "frequency",
        "common",
        "Bước đầu",
        "Ghi nhận lần uống đầu tiên",
        "🎉",
        1,
        lambda s: s.log_count,
    ),
    _d(
        "log_100",
        "frequency",
        "rare",
        "Người uống chăm chỉ",
        "Ghi nhận 100 lần uống",
        "🔄",
        100,
        lambda s: s.log_count,
    ),
    _d(
        "log_500",
        "frequency",
        "epic",
        "Thói quen vàng",
        "Ghi nhận 500 lần uống",
        "📈",
        500,
        lambda s: s.log_count,
    ),
    _d(
        "log_1000",
        "frequency",
        "legendary",
        "Nghìn nhịp nước",
        "Ghi nhận 1000 lần uống",
        "🎯",
        1000,
        lambda s: s.log_count,
    ),
    # ── Daily goal (lifetime goal-achieved days) ────────────────────
    _d(
        "goal_first",
        "daily_goal",
        "common",
        "Hoàn thành đầu tiên",
        "Đạt mục tiêu ngày đầu tiên",
        "🌱",
        1,
        lambda s: s.goal_days,
    ),
    _d(
        "goal_10",
        "daily_goal",
        "common",
        "Mười ngày vàng",
        "Đạt mục tiêu 10 ngày",
        "✅",
        10,
        lambda s: s.goal_days,
    ),
    _d(
        "goal_50",
        "daily_goal",
        "rare",
        "Năm mươi cột mốc",
        "Đạt mục tiêu 50 ngày",
        "🥇",
        50,
        lambda s: s.goal_days,
    ),
    _d(
        "goal_100",
        "daily_goal",
        "epic",
        "Trăm ngày hoàn hảo",
        "Đạt mục tiêu 100 ngày",
        "💯",
        100,
        lambda s: s.goal_days,
    ),
    _d(
        "goal_365",
        "daily_goal",
        "legendary",
        "Cả năm trọn vẹn",
        "Đạt mục tiêu 365 ngày",
        "🏅",
        365,
        lambda s: s.goal_days,
    ),
    # ── Quest (lifetime Quests Claimed) ─────────────────────────────
    _d(
        "quest_10",
        "quest",
        "common",
        "Tân Binh",
        "Hoàn thành 10 nhiệm vụ",
        "📋",
        10,
        lambda s: s.quest_claims,
    ),
    _d(
        "quest_100",
        "quest",
        "rare",
        "Chiến Binh",
        "Hoàn thành 100 nhiệm vụ",
        "🎖️",
        100,
        lambda s: s.quest_claims,
    ),
    _d(
        "quest_1000",
        "quest",
        "legendary",
        "Huyền Thoại",
        "Hoàn thành 1000 nhiệm vụ",
        "🏆",
        1000,
        lambda s: s.quest_claims,
    ),
    # ── Coach (lifetime AI Coach sessions) ──────────────────────────
    _d(
        "coach_first",
        "coach",
        "common",
        "Cuộc Trò Chuyện Đầu Tiên",
        "Trò chuyện với AI Coach lần đầu",
        "💬",
        1,
        lambda s: s.coach_sessions,
    ),
    _d(
        "coach_10",
        "coach",
        "common",
        "Học Viên",
        "10 cuộc trò chuyện với AI Coach",
        "📚",
        10,
        lambda s: s.coach_sessions,
    ),
    _d(
        "coach_100",
        "coach",
        "rare",
        "Bạn Đồng Hành",
        "100 cuộc trò chuyện với AI Coach",
        "🤝",
        100,
        lambda s: s.coach_sessions,
    ),
    _d(
        "coach_500",
        "coach",
        "epic",
        "Tri Kỷ",
        "500 cuộc trò chuyện với AI Coach",
        "💙",
        500,
        lambda s: s.coach_sessions,
    ),
    # ── Scan (lifetime Smart Scans) ─────────────────────────────────
    _d(
        "scan_first",
        "scan",
        "common",
        "Scan lần đầu",
        "Dùng Smart Scan lần đầu tiên",
        "📷",
        1,
        lambda s: s.scans,
    ),
    _d(
        "scan_50",
        "scan",
        "rare",
        "Nhà Phân Tích",
        "Thực hiện 50 lần scan",
        "🔬",
        50,
        lambda s: s.scans,
    ),
    _d(
        "scan_500",
        "scan",
        "epic",
        "Chuyên Gia",
        "Thực hiện 500 lần scan",
        "🧪",
        500,
        lambda s: s.scans,
    ),
    # ── Social (current friend count) ───────────────────────────────
    _d(
        "social_first",
        "social",
        "common",
        "Mời bạn đầu tiên",
        "Kết nối người bạn đầu tiên",
        "👋",
        1,
        lambda s: s.friends,
    ),
    _d(
        "social_5",
        "social",
        "rare",
        "Người Kết Nối",
        "Có 5 người bạn",
        "🧑‍🤝‍🧑",
        5,
        lambda s: s.friends,
    ),
    _d(
        "social_20",
        "social",
        "epic",
        "Thủ Lĩnh",
        "Có 20 người bạn",
        "🫂",
        20,
        lambda s: s.friends,
    ),
    _d(
        "social_50",
        "social",
        "legendary",
        "Aqua Community Hero",
        "Có 50 người bạn",
        "🌐",
        50,
        lambda s: s.friends,
    ),
]

_BY_ID: Dict[str, AchievementDef] = {a.id: a for a in CATALOG}


# --- read ---------------------------------------------------------------


def _claimed_ids(db: Session, user_id: str) -> set:
    rows = (
        db.query(AchievementClaim.achievement_id)
        .filter(AchievementClaim.user_id == user_id)
        .all()
    )
    return {r[0] for r in rows}


def _state(adef: AchievementDef, progress: int, claimed: bool) -> dict:
    unlocked = progress >= adef.target
    return {
        "id": adef.id,
        "domain": adef.domain,
        "tier": adef.tier,
        "name": adef.name,
        "description": adef.description,
        "icon": adef.icon,
        "progress": min(int(progress), adef.target),
        "target": adef.target,
        "reward_xp": adef.reward_xp,
        "unlocked": bool(unlocked),
        "claimed": bool(claimed),
    }


def get_achievements(db: Session, user: User) -> List[dict]:
    """Return the full catalog with derived progress and claim state."""
    stats = _load_stats(db, user)
    claimed = _claimed_ids(db, user.id)
    return [
        _state(adef, adef.progress_fn(stats), adef.id in claimed) for adef in CATALOG
    ]


# --- claim --------------------------------------------------------------


def claim_achievement(db: Session, user: User, achievement_id: str) -> dict:
    """Validate an Achievement is Done and unclaimed, then grant its XP once."""
    adef = _BY_ID.get(achievement_id)
    if adef is None:
        raise AchievementNotFound(achievement_id)

    stats = _load_stats(db, user)
    if adef.progress_fn(stats) < adef.target:
        raise AchievementNotDone(achievement_id)

    existing = (
        db.query(AchievementClaim)
        .filter(
            AchievementClaim.user_id == user.id,
            AchievementClaim.achievement_id == achievement_id,
        )
        .first()
    )
    if existing is not None:
        raise AchievementAlreadyClaimed(achievement_id)

    reward_xp = adef.reward_xp
    db.add(
        AchievementClaim(
            user_id=user.id, achievement_id=achievement_id, reward_xp=reward_xp
        )
    )

    user.total_xp = (user.total_xp or 0) + reward_xp
    # Level must come from the FULL Total XP (intake + bonus), never user.total_xp
    # alone — otherwise current_level (and level-gated avatars) go stale.
    full_total_xp = _total_xp(db, user)
    user.current_level = calculate_level_from_xp(full_total_xp)["level"]

    db.commit()
    db.refresh(user)

    return {
        "achievement_id": achievement_id,
        "reward_xp": reward_xp,
        "total_xp": full_total_xp,
        "current_level": user.current_level,
    }
