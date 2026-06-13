"""Quest progress (derived-on-read) and reward claiming.

See docs/adr/0002-derived-on-read-quests.md. Progress is computed from source
tables for the current reset period; only claims are persisted. A claim is
unique per (user, quest_id, period_key), which both prevents double-claiming
and makes resets implicit.
"""

import random
from dataclasses import dataclass
from datetime import date, datetime, timedelta, timezone
from typing import Callable, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo

from sqlalchemy import func
from sqlalchemy.orm import Session

from app.core.leveling import calculate_level_from_xp
from app.models import (Conversation, DailySummary, QuestClaim, Referral,
                        ReminderLog, ScanHistory, User)

CHEST_COIN_MIN = 50
CHEST_COIN_MAX = 150


# --- errors -------------------------------------------------------------


class QuestError(Exception):
    """Base class for quest claim errors."""


class QuestNotFound(QuestError):
    pass


class QuestNotDone(QuestError):
    pass


class QuestAlreadyClaimed(QuestError):
    pass


# --- registry -----------------------------------------------------------


@dataclass(frozen=True)
class QuestDef:
    id: str
    period: str  # "daily" | "weekly"
    name: str
    description: str
    unit: str
    reward_xp: int
    reward_coin: int
    target: int  # static target; ignored when progress_fn returns its own target
    # (progress, target) given (db, user, window). target None -> use static.
    progress_fn: Callable[[Session, User, "PeriodWindow"], Tuple[int, Optional[int]]]
    is_bonus: bool = False
    is_chest: bool = False


@dataclass
class PeriodWindow:
    start_utc: datetime  # naive UTC, inclusive
    end_utc: datetime  # naive UTC, exclusive
    start_date: date  # local, inclusive
    end_date: date  # local, exclusive
    key: str


def get_period_window(now: datetime, tz_name: str, period: str) -> PeriodWindow:
    """Compute the current reset window in the user's local timezone."""
    tz = ZoneInfo(tz_name or "UTC")
    now_local = now.astimezone(tz)

    if period == "daily":
        start_local = now_local.replace(hour=0, minute=0, second=0, microsecond=0)
        end_local = start_local + timedelta(days=1)
        key = start_local.strftime("%Y-%m-%d")
    elif period == "weekly":
        monday = now_local - timedelta(days=now_local.weekday())
        start_local = monday.replace(hour=0, minute=0, second=0, microsecond=0)
        end_local = start_local + timedelta(days=7)
        iso = start_local.isocalendar()
        key = f"{iso.year}-W{iso.week:02d}"
    else:
        raise ValueError(f"Unknown period: {period}")

    start_utc = start_local.astimezone(timezone.utc).replace(tzinfo=None)
    end_utc = end_local.astimezone(timezone.utc).replace(tzinfo=None)
    return PeriodWindow(start_utc, end_utc, start_local.date(), end_local.date(), key)


# --- progress functions (derived on read) -------------------------------


def _goal_ml(user: User, summary: Optional[DailySummary]) -> int:
    if summary and summary.daily_goal_ml:
        return summary.daily_goal_ml
    return user.calculated_daily_goal_ml or user.daily_goal_ml or 2000


def _progress_breakthrough(db, user, window) -> Tuple[int, Optional[int]]:
    summary = (
        db.query(DailySummary)
        .filter(
            DailySummary.user_id == user.id,
            DailySummary.date >= window.start_date,
            DailySummary.date < window.end_date,
        )
        .first()
    )
    progress = summary.total_effective_ml if summary else 0
    target = round(0.8 * _goal_ml(user, summary))
    return progress, target


def _progress_smart_scan(db, user, window) -> Tuple[int, Optional[int]]:
    count = (
        db.query(func.count(ScanHistory.id))
        .filter(
            ScanHistory.user_id == user.id,
            ScanHistory.created_at >= window.start_utc,
            ScanHistory.created_at < window.end_utc,
        )
        .scalar()
        or 0
    )
    return count, None


def _progress_friend_reminder(db, user, window) -> Tuple[int, Optional[int]]:
    count = (
        db.query(func.count(ReminderLog.id))
        .filter(
            ReminderLog.user_id == user.id,
            ReminderLog.created_at >= window.start_utc,
            ReminderLog.created_at < window.end_utc,
        )
        .scalar()
        or 0
    )
    return count, None


def _progress_ai_companion(db, user, window) -> Tuple[int, Optional[int]]:
    count = (
        db.query(func.count(Conversation.id))
        .filter(
            Conversation.user_id == user.id,
            Conversation.message_type == "user",
            Conversation.created_at >= window.start_utc,
            Conversation.created_at < window.end_utc,
        )
        .scalar()
        or 0
    )
    return count, None


def _progress_streak(db, user, window) -> Tuple[int, Optional[int]]:
    # Validated against the server-side streak counter, never self-reported.
    return user.current_streak or 0, None


def _progress_hydration_warrior(db, user, window) -> Tuple[int, Optional[int]]:
    count = (
        db.query(func.count(DailySummary.id))
        .filter(
            DailySummary.user_id == user.id,
            DailySummary.goal_achieved.is_(True),
            DailySummary.date >= window.start_date,
            DailySummary.date < window.end_date,
        )
        .scalar()
        or 0
    )
    return count, None


def _progress_water_scientist(db, user, window) -> Tuple[int, Optional[int]]:
    count = (
        db.query(func.count(func.distinct(ScanHistory.liquid_type)))
        .filter(
            ScanHistory.user_id == user.id,
            ScanHistory.created_at >= window.start_utc,
            ScanHistory.created_at < window.end_utc,
        )
        .scalar()
        or 0
    )
    return count, None


def _progress_hydration_ambassador(db, user, window) -> Tuple[int, Optional[int]]:
    # Count referrals this user made that were *validated* within the week.
    count = (
        db.query(func.count(Referral.id))
        .filter(
            Referral.referrer_id == user.id,
            Referral.validated_at.isnot(None),
            Referral.validated_at >= window.start_utc,
            Referral.validated_at < window.end_utc,
        )
        .scalar()
        or 0
    )
    return count, None


def _progress_zero(db, user, window) -> Tuple[int, Optional[int]]:
    return 0, None


# --- quest definitions (spec: quests_spec.md) ---------------------------

DAILY_QUESTS: List[QuestDef] = [
    QuestDef(
        "breakthrough_hydration",
        "daily",
        "Bứt Phá Hydration",
        "Uống đủ 80% lượng nước mục tiêu hôm nay",
        "ml",
        25,
        10,
        0,
        _progress_breakthrough,
    ),
    QuestDef(
        "smart_scan",
        "daily",
        "Quét Thông Minh",
        "Dùng AI Smart Scan để nhận diện lượng nước 4 lần",
        "lần",
        30,
        15,
        4,
        _progress_smart_scan,
    ),
    QuestDef(
        "friend_reminder",
        "daily",
        "Hội Bạn Cùng Uống",
        "Nhắc nhở cho bạn bè uống nước 2 lần",
        "lần",
        10,
        5,
        2,
        _progress_friend_reminder,
    ),
    QuestDef(
        "ai_companion",
        "daily",
        "AI Đồng Hành",
        "Chat với AI Coach ít nhất 1 lần trong ngày",
        "lần",
        15,
        5,
        1,
        _progress_ai_companion,
    ),
]

WEEKLY_QUESTS: List[QuestDef] = [
    QuestDef(
        "persistence_week",
        "weekly",
        "Tuần Lễ Kiên Trì",
        "Streak 7 ngày liên tiếp",
        "ngày",
        100,
        40,
        7,
        _progress_streak,
    ),
    QuestDef(
        "hydration_warrior",
        "weekly",
        "Chiến Binh Hydration",
        "Đạt mục tiêu uống nước hàng ngày trong 5 ngày",
        "ngày",
        75,
        30,
        5,
        _progress_hydration_warrior,
    ),
    QuestDef(
        "water_scientist",
        "weekly",
        "Nhà Khoa Học Nước",
        "Thử 3 loại đồ uống khác nhau được AI nhận diện trong tuần",
        "loại",
        50,
        25,
        3,
        _progress_water_scientist,
    ),
    QuestDef(
        "hydration_ambassador",
        "weekly",
        "Đại Sứ Hydration",
        "Mời 1 người bạn mới dùng AquaTrack (đã uống nước lần đầu)",
        "người",
        75,
        40,
        1,
        _progress_hydration_ambassador,
    ),
]

# Completion bonuses: target = number of base quests in the period.
DAILY_BONUS = QuestDef(
    "daily_bonus",
    "daily",
    "Hoàn thành hằng ngày",
    "Hoàn thành tất cả nhiệm vụ ngày",
    "",
    20,
    15,
    len(DAILY_QUESTS),
    _progress_zero,
    is_bonus=True,
)
WEEKLY_BONUS = QuestDef(
    "weekly_bonus",
    "weekly",
    "Rương May Mắn",
    "Hoàn thành tất cả nhiệm vụ tuần",
    "",
    0,
    0,
    len(WEEKLY_QUESTS),
    _progress_zero,
    is_bonus=True,
    is_chest=True,
)

_BY_PERIOD = {"daily": DAILY_QUESTS, "weekly": WEEKLY_QUESTS}
_BONUS_BY_PERIOD = {"daily": DAILY_BONUS, "weekly": WEEKLY_BONUS}
_ALL_DEFS: Dict[str, QuestDef] = {
    q.id: q for q in DAILY_QUESTS + WEEKLY_QUESTS + [DAILY_BONUS, WEEKLY_BONUS]
}


# Vietnamese day-of-week labels (Monday=0 … Sunday=6)
_DAY_LABELS = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"]


def _summary_pct(summary) -> int:
    """Derive progress % from raw ml columns — the stored column is stale in prod."""
    goal = summary.daily_goal_ml or 0
    if goal <= 0:
        return 0
    return round(summary.total_effective_ml / goal * 100)


def build_week_strip(db: Session, user: User, now: datetime) -> list:
    """Return a 7-item list describing each day of the current ISO week."""
    tz = ZoneInfo(user.timezone or "UTC")
    now_local = now.astimezone(tz)
    today_local = now_local.date()

    # Monday of the current ISO week.
    monday = today_local - timedelta(days=today_local.weekday())
    week_dates = [monday + timedelta(days=i) for i in range(7)]

    # Fetch all DailySummary rows for this week in one query.
    summaries = {
        s.date: s
        for s in db.query(DailySummary)
        .filter(
            DailySummary.user_id == user.id,
            DailySummary.date >= monday,
            DailySummary.date <= week_dates[-1],
        )
        .all()
    }

    strip = []
    for i, day_date in enumerate(week_dates):
        summary = summaries.get(day_date)
        if day_date > today_local:
            strip.append(
                {
                    "day_label": _DAY_LABELS[i],
                    "date_iso": day_date.isoformat(),
                    "status": "future",
                    "progress_pct": None,
                }
            )
        elif day_date == today_local:
            pct = _summary_pct(summary) if summary else 0
            strip.append(
                {
                    "day_label": _DAY_LABELS[i],
                    "date_iso": day_date.isoformat(),
                    "status": "today",
                    "progress_pct": pct,
                }
            )
        else:
            if summary and summary.goal_achieved:
                status = "done"
                pct = 100
            elif summary and summary.total_effective_ml > 0:
                status = "partial"
                pct = min(99, _summary_pct(summary))
            else:
                status = "future"  # no log for a past day — treat as missed
                pct = 0
            strip.append(
                {
                    "day_label": _DAY_LABELS[i],
                    "date_iso": day_date.isoformat(),
                    "status": status,
                    "progress_pct": pct,
                }
            )
    return strip


def get_reset_times(now: datetime, tz_name: str) -> dict:
    """ISO-8601 strings for next daily and weekly reset in local timezone."""
    tz = ZoneInfo(tz_name or "UTC")
    now_local = now.astimezone(tz)

    next_daily = (now_local + timedelta(days=1)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    days_to_monday = (7 - now_local.weekday()) % 7 or 7
    next_weekly = (now_local + timedelta(days=days_to_monday)).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    return {
        "daily_reset_at": next_daily.isoformat(),
        "weekly_reset_at": next_weekly.isoformat(),
    }


# --- read ---------------------------------------------------------------


def _now_utc(now: Optional[datetime]) -> datetime:
    if now is None:
        return datetime.now(timezone.utc)
    if now.tzinfo is None:
        return now.replace(tzinfo=timezone.utc)
    return now


def _claimed_keys(db, user_id: str, period_keys: List[str]) -> set:
    rows = (
        db.query(QuestClaim.quest_id, QuestClaim.period_key)
        .filter(
            QuestClaim.user_id == user_id,
            QuestClaim.period_key.in_(period_keys),
        )
        .all()
    )
    return {(r[0], r[1]) for r in rows}


def get_quests(db: Session, user: User, now: Optional[datetime] = None) -> List[dict]:
    """Return all quests (daily + weekly + bonuses) with derived progress."""
    now = _now_utc(now)
    windows = {p: get_period_window(now, user.timezone, p) for p in ("daily", "weekly")}
    claimed = _claimed_keys(db, user.id, [w.key for w in windows.values()])

    out: List[dict] = []
    for period in ("daily", "weekly"):
        window = windows[period]
        base_done = 0
        for qdef in _BY_PERIOD[period]:
            progress, dyn_target = qdef.progress_fn(db, user, window)
            target = dyn_target if dyn_target is not None else qdef.target
            done = progress >= target
            is_claimed = (qdef.id, window.key) in claimed
            # A claimed quest counts toward the chest even if progress later regresses.
            if done or is_claimed:
                base_done += 1
            out.append(_state(qdef, progress, target, done, is_claimed))

        # Completion bonus for this period.
        bonus = _BONUS_BY_PERIOD[period]
        bonus_done = base_done >= bonus.target
        out.append(
            _state(
                bonus,
                base_done,
                bonus.target,
                bonus_done,
                (bonus.id, window.key) in claimed,
            )
        )

    return out


def _state(
    qdef: QuestDef, progress: int, target: int, done: bool, claimed: bool
) -> dict:
    return {
        "id": qdef.id,
        "period": qdef.period,
        "name": qdef.name,
        "description": qdef.description,
        "unit": qdef.unit,
        "progress": int(progress),
        "target": int(target),
        "reward_xp": qdef.reward_xp,
        "reward_coin": qdef.reward_coin,
        "is_bonus": qdef.is_bonus,
        "is_chest": qdef.is_chest,
        "done": bool(done),
        "claimed": bool(claimed),
    }


# --- claim --------------------------------------------------------------


def _is_done(db, user, qdef: QuestDef, window: PeriodWindow) -> bool:
    if qdef.is_bonus:
        claimed = _claimed_keys(db, user.id, [window.key])
        base_done = 0
        for base in _BY_PERIOD[qdef.period]:
            progress, dyn_target = base.progress_fn(db, user, window)
            target = dyn_target if dyn_target is not None else base.target
            if progress >= target or (base.id, window.key) in claimed:
                base_done += 1
        return base_done >= qdef.target
    progress, dyn_target = qdef.progress_fn(db, user, window)
    target = dyn_target if dyn_target is not None else qdef.target
    return progress >= target


def claim_quest(
    db: Session, user: User, quest_id: str, now: Optional[datetime] = None
) -> dict:
    """Validate a quest is Done and unclaimed, then grant its reward once."""
    qdef = _ALL_DEFS.get(quest_id)
    if qdef is None:
        raise QuestNotFound(quest_id)

    now = _now_utc(now)
    window = get_period_window(now, user.timezone, qdef.period)

    if not _is_done(db, user, qdef, window):
        raise QuestNotDone(quest_id)

    existing = (
        db.query(QuestClaim)
        .filter(
            QuestClaim.user_id == user.id,
            QuestClaim.quest_id == quest_id,
            QuestClaim.period_key == window.key,
        )
        .first()
    )
    if existing is not None:
        raise QuestAlreadyClaimed(quest_id)

    reward_xp = qdef.reward_xp
    reward_coin = qdef.reward_coin
    if qdef.is_chest:
        reward_coin = random.randint(CHEST_COIN_MIN, CHEST_COIN_MAX)

    claim = QuestClaim(
        user_id=user.id,
        quest_id=quest_id,
        period_key=window.key,
        reward_xp=reward_xp,
        reward_coin=reward_coin,
    )
    db.add(claim)

    user.total_xp = (user.total_xp or 0) + reward_xp
    user.coins = (user.coins or 0) + reward_coin
    user.current_level = calculate_level_from_xp(user.total_xp)["level"]

    db.commit()
    db.refresh(user)

    return {
        "quest_id": quest_id,
        "reward_xp": reward_xp,
        "reward_coin": reward_coin,
        "total_xp": user.total_xp,
        "coins": user.coins,
        "current_level": user.current_level,
    }
