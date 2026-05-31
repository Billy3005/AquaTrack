"""Derived-on-read social payloads, shaped for the Flutter friends UI.

See docs/adr/0003-friends-derived-on-read.md. Each friend's hydration standing
(daily progress, status, online) and the weekly leaderboard are computed from
existing source tables (daily_summaries, users) on every read — nothing extra is
stored. Response shapes match exactly what `social_service.dart` parses.

Day boundaries use the **UTC** calendar date to match how `DailySummary.date`
is written by the intake endpoint; see the ADR for that trade-off. Friends list
and leaderboard each issue a single batched summary query (no N+1).
"""

from datetime import date, datetime, timedelta, timezone
from typing import Dict, List, Optional

from sqlalchemy import and_
from sqlalchemy.orm import aliased, joinedload

from app.models import DailySummary, User
from app.models.friend import Friend
from app.models.friend_request import FriendRequest, FriendRequestStatus

ONLINE_WINDOW = timedelta(minutes=15)
STATUS_NORMAL_MIN = 0.8  # >= -> đủ nước
STATUS_STRESSED_MIN = 0.4  # >= -> hơi thấp; below -> đang khát

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


def _utc_today(now: datetime) -> date:
    return now.astimezone(timezone.utc).date()


def _utc_day_bounds(now: datetime):
    """[start, end) of the UTC calendar day for ``now`` as naive UTC datetimes,
    matching how reminder rows store ``created_at``."""
    now_utc = now.astimezone(timezone.utc).replace(tzinfo=None)
    start = now_utc.replace(hour=0, minute=0, second=0, microsecond=0)
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


def _status(daily_progress: float, has_activity: bool) -> str:
    if not has_activity:
        return "offline"
    if daily_progress >= STATUS_NORMAL_MIN:
        return "normal"
    if daily_progress >= STATUS_STRESSED_MIN:
        return "stressed"
    return "thirsty"


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
    return max(candidates).isoformat()


def _friend_dict(u: User, summary: Optional[DailySummary], now: datetime) -> dict:
    """Build the Flutter `Friend` shape for one user from a pre-fetched summary.

    The caller supplies today's summary (batched) so this does no I/O — keeping
    the friends list and leaderboard free of N+1 queries.
    """
    effective = (summary.total_effective_ml or 0) if summary else 0
    has_activity = effective > 0
    if summary and summary.progress_percentage:
        daily_progress = min(summary.progress_percentage / 100.0, 1.0)
    else:
        daily_progress = 0.0
    daily_progress = round(daily_progress, 2)

    return {
        "id": u.id,
        "username": u.username,
        "display_name": u.full_name or u.username,
        "avatar_url": f"/avatars/{u.avatar_id}" if u.avatar_id else None,
        "hydration_level": daily_progress,
        "daily_progress": daily_progress,
        "current_streak": u.current_streak or 0,
        "is_online": _is_online(u, now),
        "status": _status(daily_progress, has_activity),
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


def _summaries_for_day(db, user_ids: List[str], day: date) -> Dict[str, DailySummary]:
    """One query: the given day's DailySummary for every user, keyed by user_id."""
    if not user_ids:
        return {}
    rows = (
        db.query(DailySummary)
        .filter(DailySummary.user_id.in_(user_ids), DailySummary.date == day)
        .all()
    )
    return {r.user_id: r for r in rows}


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
    today = _utc_today(now)
    friends = _friend_users(db, user.id)
    summaries = _summaries_for_day(db, [f.id for f in friends], today)
    return {"friends": [_friend_dict(f, summaries.get(f.id), now) for f in friends]}


# --- friend requests ----------------------------------------------------


def build_requests_payload(db, user: User, now: Optional[datetime] = None) -> dict:
    now = _now_utc(now)
    today = _utc_today(now)
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
    summaries = _summaries_for_day(db, sender_ids, today)

    out = []
    for r in requests:
        from_user = (
            _friend_dict(r.sender, summaries.get(r.sender_id), now)
            if r.sender
            else None
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
        "stressed_friends": sum(1 for f in friends if f["status"] == "stressed"),
        "pending_requests": pending,
        "my_rank": me["rank"] if me else None,
        "my_weekly_score": me["weekly_score"] if me else None,
    }
