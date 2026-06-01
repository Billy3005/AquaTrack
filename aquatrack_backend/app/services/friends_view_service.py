"""Derived-on-read social payloads, shaped for the Flutter friends UI.

See docs/adr/0003-friends-derived-on-read.md. Each friend's hydration standing
(daily progress, status, online) is derived from ``intake_logs`` on read, and
the weekly leaderboard from ``daily_summaries`` — nothing extra is stored. The
friends list keys status off the *recency of the last log* (not a stored %),
because ``DailySummary`` is only written once the daily goal is reached and so
leaves partial days looking empty. Response shapes match exactly what
`social_service.dart` parses.

Day boundaries use the **UTC** calendar date; see the ADR for that trade-off.
Friends list and leaderboard each issue a single batched query (no N+1).
"""

from datetime import date, datetime, timedelta, timezone
from typing import Dict, List, Optional

from sqlalchemy import and_, func
from sqlalchemy.orm import aliased, joinedload

from app.models import DailySummary, IntakeLog, User
from app.models.friend import Friend
from app.models.friend_request import FriendRequest, FriendRequestStatus

ONLINE_WINDOW = timedelta(minutes=15)
# A friend who has logged today but whose last drink is older than this is
# considered "đang khát" (a sub-state of offline). See _status().
THIRSTY_AFTER = timedelta(hours=2)

# Max hydration reminders one user may send per (UTC) day. Caps spam and stops
# the "Hội Bạn Cùng Uống" quest from being farmed.
REMINDER_DAILY_LIMIT = 20


# --- time helpers -------------------------------------------------------


def _now_utc(now: Optional[datetime]) -> datetime:
    if now is None:
        return datetime.now(timezone.utc)
    if now.tzinfo is None:
        return now.replace(tzinfo=timezone.utc)
    return now


def _to_naive_utc(dt: Optional[datetime]) -> Optional[datetime]:
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt
    return dt.astimezone(timezone.utc).replace(tzinfo=None)


def _iso_utc(dt: Optional[datetime]) -> Optional[str]:
    """Serialize a (possibly naive) UTC datetime as a tz-aware ISO string.

    DB timestamps are stored as naive UTC; emitting them without a zone makes
    Flutter's ``DateTime.parse`` read them as *local* time, so on a UTC+7 device
    a fresh login shows as "7 giờ trước". Tagging UTC fixes the relative-time
    display on the friend cards.
    """
    if dt is None:
        return None
    if dt.tzinfo is None:
        dt = dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc).isoformat()


def _utc_today(now: datetime) -> date:
    return now.astimezone(timezone.utc).date()


def _utc_day_bounds(now: datetime):
    """[start, end) of the UTC calendar day for ``now`` as naive UTC datetimes,
    matching how reminder rows store ``created_at``."""
    now_utc = now.astimezone(timezone.utc).replace(tzinfo=None)
    start = now_utc.replace(hour=0, minute=0, second=0, microsecond=0)
    return start, start + timedelta(days=1)


def _to_naive_local(dt: Optional[datetime]) -> Optional[datetime]:
    """Drop to naive *server-local* time, matching how ``IntakeLog.logged_at``
    is written (the intake CRUD uses ``datetime.now()``)."""
    if dt is None:
        return None
    if dt.tzinfo is None:
        return dt
    return dt.astimezone().replace(tzinfo=None)


def _now_local_naive(now: Optional[datetime]) -> datetime:
    """Server-local naive 'now'. Intake timestamps are stored in local time, so
    the "today" window and the last-drink recency check must use the same frame
    (using UTC here made everyone read as 7h off on a UTC+7 box — thirsty never
    triggered and early-morning logs fell outside "today")."""
    return _now_utc(now).astimezone().replace(tzinfo=None)


def _local_day_bounds(now_local: datetime):
    """[start, end) of the local calendar day, matching logged_at's frame."""
    start = now_local.replace(hour=0, minute=0, second=0, microsecond=0)
    return start, start + timedelta(days=1)


def reminders_sent_today(db, user_id: str, now: Optional[datetime] = None) -> int:
    """Count hydration reminders the user has sent in the current UTC day."""
    from app.models import ReminderLog

    now = _now_utc(now)
    start, end = _utc_day_bounds(now)
    return (
        db.query(ReminderLog)
        .filter(
            ReminderLog.user_id == user_id,
            ReminderLog.created_at >= start,
            ReminderLog.created_at < end,
        )
        .count()
    )


# --- per-friend derivation ----------------------------------------------


def _status(
    has_log_today: bool, last_log_at: Optional[datetime], now_local: datetime
) -> str:
    """Hydration-recency status (presence is reported separately via is_online).

    - ``dry``     : no water logged at all today ("khô").
    - ``thirsty`` : logged today, but the last drink was > THIRSTY_AFTER ago.
    - ``normal``  : logged today and drank within THIRSTY_AFTER ("đủ nước").

    ``now_local`` and ``last_log_at`` are both server-local naive (logged_at's
    frame); see _now_local_naive.
    """
    if not has_log_today or last_log_at is None:
        return "dry"
    last = _to_naive_local(last_log_at)
    if last is None:
        return "dry"
    return "thirsty" if (now_local - last) > THIRSTY_AFTER else "normal"


def _is_online(u: User, now: datetime) -> bool:
    now_naive = _to_naive_utc(now)
    candidates = [_to_naive_utc(u.last_login), _to_naive_utc(u.updated_at)]
    last = max((c for c in candidates if c is not None), default=None)
    if last is None:
        return False
    return (now_naive - last) <= ONLINE_WINDOW


def _last_active_iso(u: User) -> Optional[str]:
    candidates = [c for c in (u.last_login, u.updated_at) if c is not None]
    if not candidates:
        return None
    return _iso_utc(max(candidates))


# Per-user today's intake, batched: user_id -> (effective_ml, last_logged_at, count)
TodayIntake = Dict[str, tuple]


def _friend_dict(u: User, intake: Optional[tuple], now: datetime) -> dict:
    """Build the Flutter `Friend` shape for one user from pre-fetched intake.

    ``intake`` is ``(sum_effective_ml, last_logged_at, log_count)`` for today,
    supplied batched by the caller so this does no I/O (no N+1). Status and the
    progress bar are derived straight from ``intake_logs`` — not ``DailySummary``,
    which is only written when the daily goal is reached and so leaves partial
    days looking empty.
    """
    sum_ml, last_log_at, log_count = intake if intake else (0, None, 0)
    goal = u.daily_goal_ml or 2000
    daily_progress = round(min(sum_ml / goal, 1.0), 2) if goal else 0.0
    has_log_today = log_count > 0
    now_local = _now_local_naive(now)

    return {
        "id": u.id,
        "username": u.username,
        "display_name": u.full_name or u.username,
        "avatar_url": f"/avatars/{u.avatar_id}" if u.avatar_id else None,
        "hydration_level": daily_progress,
        "daily_progress": daily_progress,
        "current_streak": u.current_streak or 0,
        "is_online": _is_online(u, now),
        "status": _status(has_log_today, last_log_at, now_local),
        "last_active": _last_active_iso(u),
        "weekly_rank": None,
        "weekly_score": None,
    }


# --- batch fetch helpers ------------------------------------------------


def _friend_users(db, user_id: str) -> List[User]:
    FriendUser = aliased(User)
    return (
        db.query(FriendUser)
        .join(Friend, Friend.friend_user_id == FriendUser.id)
        .filter(
            and_(
                Friend.user_id == user_id,
                Friend.is_active.is_(True),
                Friend.is_blocked.is_(False),
            )
        )
        .all()
    )


def _intake_today(db, user_ids: List[str], now: datetime) -> TodayIntake:
    """One query: each user's today (UTC day) intake aggregate.

    Returns ``user_id -> (sum_effective_ml, last_logged_at, log_count)``. Drives
    both the progress bar (sum / goal) and the hydration status (recency of the
    last log) without touching ``DailySummary``.
    """
    if not user_ids:
        return {}
    # logged_at is stored in server-local time, so bound the "today" window in
    # the same frame (not UTC) — otherwise the window is shifted by the tz offset.
    start, end = _local_day_bounds(_now_local_naive(now))
    rows = (
        db.query(
            IntakeLog.user_id,
            func.coalesce(func.sum(IntakeLog.effective_volume_ml), 0),
            func.max(IntakeLog.logged_at),
            func.count(IntakeLog.id),
        )
        .filter(
            IntakeLog.user_id.in_(user_ids),
            IntakeLog.logged_at >= start,
            IntakeLog.logged_at < end,
        )
        .group_by(IntakeLog.user_id)
        .all()
    )
    return {r[0]: (int(r[1] or 0), r[2], int(r[3] or 0)) for r in rows}


def _summaries_for_week(
    db, user_ids: List[str], monday: date, end_day: date
) -> Dict[str, List[DailySummary]]:
    """One query: all summaries in [monday, end_day] per user, grouped by id."""
    grouped: Dict[str, List[DailySummary]] = {uid: [] for uid in user_ids}
    if not user_ids:
        return grouped
    rows = (
        db.query(DailySummary)
        .filter(
            DailySummary.user_id.in_(user_ids),
            DailySummary.date >= monday,
            DailySummary.date <= end_day,
        )
        .all()
    )
    for r in rows:
        grouped.setdefault(r.user_id, []).append(r)
    return grouped


# --- friends list -------------------------------------------------------


def build_friends_payload(db, user: User, now: Optional[datetime] = None) -> dict:
    now = _now_utc(now)
    friends = _friend_users(db, user.id)
    intake = _intake_today(db, [f.id for f in friends], now)
    return {"friends": [_friend_dict(f, intake.get(f.id), now) for f in friends]}


# --- friend requests ----------------------------------------------------


def build_requests_payload(db, user: User, now: Optional[datetime] = None) -> dict:
    now = _now_utc(now)
    requests = (
        db.query(FriendRequest)
        .filter(
            FriendRequest.receiver_id == user.id,
            FriendRequest.status == FriendRequestStatus.PENDING,
        )
        .options(joinedload(FriendRequest.sender))
        .order_by(FriendRequest.created_at.desc())
        .all()
    )
    sender_ids = [r.sender_id for r in requests if r.sender_id]
    intake = _intake_today(db, sender_ids, now)

    out = []
    for r in requests:
        from_user = (
            _friend_dict(r.sender, intake.get(r.sender_id), now) if r.sender else None
        )
        out.append(
            {
                "id": r.id,
                "from_user_id": r.sender_id,
                "to_user_id": r.receiver_id,
                "from_user": from_user,
                "status": r.status.value,
                "created_at": r.created_at.isoformat() if r.created_at else None,
                "responded_at": (
                    r.responded_at.isoformat() if r.responded_at else None
                ),
                "message": r.message,
            }
        )
    return {"requests": out}


# --- weekly leaderboard -------------------------------------------------


def _week_stats_from(summaries: List[DailySummary], days_elapsed: int) -> dict:
    pct_sum = sum(min(s.progress_percentage or 0.0, 100.0) for s in summaries)
    total_volume = sum(s.total_effective_ml or 0 for s in summaries)
    goal_days = sum(1 for s in summaries if s.goal_achieved)
    hydration_pct = pct_sum / days_elapsed if days_elapsed else 0.0
    return {
        "hydration_percentage": round(hydration_pct, 1),
        "total_volume_ml": int(total_volume),
        "daily_goal_achieved": goal_days,
    }


def _entry(u: User, stats: dict) -> dict:
    return {
        "user_id": u.id,
        "username": u.username,
        "display_name": u.full_name or u.username,
        "avatar_url": f"/avatars/{u.avatar_id}" if u.avatar_id else None,
        "weekly_score": stats["hydration_percentage"],
        "hydration_percentage": stats["hydration_percentage"],
        "daily_goal_achieved": stats["daily_goal_achieved"],
        "total_volume_ml": stats["total_volume_ml"],
        "rank": 0,
    }


def build_leaderboard_payload(db, user: User, now: Optional[datetime] = None) -> dict:
    """Rank the user together with their friends over the current ISO week,
    by average goal-achievement % (tie-break: total ml). Single summary query."""
    now = _now_utc(now)
    today = _utc_today(now)
    monday = today - timedelta(days=today.weekday())
    days_elapsed = (today - monday).days + 1

    participants = [user] + _friend_users(db, user.id)
    by_user = _summaries_for_week(db, [p.id for p in participants], monday, today)

    entries = [
        _entry(p, _week_stats_from(by_user.get(p.id, []), days_elapsed))
        for p in participants
    ]
    entries.sort(
        key=lambda e: (e["hydration_percentage"], e["total_volume_ml"]),
        reverse=True,
    )
    for i, e in enumerate(entries, start=1):
        e["rank"] = i
    return {"leaderboard": entries}


# --- social stats -------------------------------------------------------


def build_social_stats(db, user: User, now: Optional[datetime] = None) -> dict:
    now = _now_utc(now)
    friends = build_friends_payload(db, user, now)["friends"]
    pending = (
        db.query(FriendRequest)
        .filter(
            FriendRequest.receiver_id == user.id,
            FriendRequest.status == FriendRequestStatus.PENDING,
        )
        .count()
    )

    board = build_leaderboard_payload(db, user, now)["leaderboard"]
    me = next((e for e in board if e["user_id"] == user.id), None)

    return {
        "total_friends": len(friends),
        "online_friends": sum(1 for f in friends if f["is_online"]),
        "thirsty_friends": sum(1 for f in friends if f["status"] == "thirsty"),
        # "stressed" is retired; report "khô" (no log today) in its slot so the
        # existing SocialStats field stays populated for clients that read it.
        "stressed_friends": sum(1 for f in friends if f["status"] == "dry"),
        "pending_requests": pending,
        "my_rank": me["rank"] if me else None,
        "my_weekly_score": me["weekly_score"] if me else None,
    }
