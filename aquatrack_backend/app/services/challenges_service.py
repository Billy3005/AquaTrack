"""Friend hydration races ("cuộc đua") and the notifications inbox.

Challenges store only the agreement + window (see ``models/challenge.py``);
each side's score is derived on read from ``daily_summaries`` over the active
window — the same derived-on-read approach as ``friends_view_service`` (ADR
0003). The notifications inbox aggregates two existing event sources — hydration
reminders received (``reminder_logs``) and challenge invites/results — into one
feed shaped for the Flutter ``NotificationsScreen``.
"""

from datetime import datetime, timedelta
from typing import List, Optional

from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload

from app.models import (Challenge, ChallengeStatus, DailySummary, ReminderLog,
                        User)
from app.models.friend import Friend

# How far back the notifications inbox looks for reminders / finished races.
NOTIFICATION_WINDOW = timedelta(days=7)


# --- helpers ------------------------------------------------------------


def _now() -> datetime:
    return datetime.utcnow()


def _are_friends(db: Session, user_id: str, other_id: str) -> bool:
    return (
        db.query(Friend)
        .filter(
            Friend.user_id == user_id,
            Friend.friend_user_id == other_id,
            Friend.is_active.is_(True),
            Friend.is_blocked.is_(False),
        )
        .first()
        is not None
    )


def _display_name(u: Optional[User]) -> str:
    if u is None:
        return "Một người bạn"
    return u.full_name or u.username


def _window_volume_ml(db: Session, user_id: str, start: datetime, end: datetime) -> int:
    """Total effective ml a user logged within [start, end] (inclusive days)."""
    rows = (
        db.query(DailySummary)
        .filter(
            DailySummary.user_id == user_id,
            DailySummary.date >= start.date(),
            DailySummary.date <= end.date(),
        )
        .all()
    )
    return int(sum(r.total_effective_ml or 0 for r in rows))


# --- challenge CRUD-ish -------------------------------------------------


def create_challenge(
    db: Session,
    *,
    challenger_id: str,
    opponent_id: str,
    duration_days: int = 7,
    message: Optional[str] = None,
) -> dict:
    """Create a pending race invite from challenger to opponent."""
    if challenger_id == opponent_id:
        return {"success": False, "message": "Không thể thách đấu chính mình"}

    opponent = db.query(User).filter(User.id == opponent_id).first()
    if opponent is None:
        return {"success": False, "message": "Không tìm thấy người chơi"}

    if not _are_friends(db, challenger_id, opponent_id):
        return {"success": False, "message": "Chỉ có thể thách đấu bạn bè"}

    # Block duplicate live races between the same pair (either direction).
    existing = (
        db.query(Challenge)
        .filter(
            Challenge.status.in_([ChallengeStatus.PENDING, ChallengeStatus.ACTIVE]),
            or_(
                (Challenge.challenger_id == challenger_id)
                & (Challenge.opponent_id == opponent_id),
                (Challenge.challenger_id == opponent_id)
                & (Challenge.opponent_id == challenger_id),
            ),
        )
        .first()
    )
    if existing is not None:
        return {
            "success": False,
            "message": "Đã có một cuộc đua đang diễn ra với người này",
        }

    challenge = Challenge(
        challenger_id=challenger_id,
        opponent_id=opponent_id,
        duration_days=max(1, min(duration_days, 30)),
        message=message,
        status=ChallengeStatus.PENDING,
    )
    db.add(challenge)
    db.commit()
    db.refresh(challenge)
    return {"success": True, "message": "Đã gửi lời mời cuộc đua", "id": challenge.id}


def respond_to_challenge(
    db: Session, *, challenge_id: str, user_id: str, accept: bool
) -> dict:
    """Opponent accepts (start race) or declines a pending invite."""
    challenge = db.query(Challenge).filter(Challenge.id == challenge_id).first()
    if challenge is None:
        return {"success": False, "message": "Không tìm thấy cuộc đua"}

    if challenge.opponent_id != user_id:
        return {"success": False, "message": "Bạn không thể phản hồi cuộc đua này"}

    if challenge.status != ChallengeStatus.PENDING:
        return {"success": False, "message": "Cuộc đua không còn chờ phản hồi"}

    now = _now()
    challenge.responded_at = now
    if accept:
        challenge.status = ChallengeStatus.ACTIVE
        challenge.started_at = now
        challenge.ends_at = now + timedelta(days=challenge.duration_days)
        msg = "Đã chấp nhận cuộc đua! 🏁"
    else:
        challenge.status = ChallengeStatus.DECLINED
        msg = "Đã từ chối cuộc đua"

    db.commit()
    return {"success": True, "message": msg}


def _finalize_expired(db: Session, challenges: List[Challenge]) -> None:
    """Flip ACTIVE races whose window has passed to COMPLETED (lazy, on read)."""
    now = _now()
    changed = False
    for c in challenges:
        if c.status == ChallengeStatus.ACTIVE and c.ends_at and c.ends_at <= now:
            c.status = ChallengeStatus.COMPLETED
            changed = True
    if changed:
        db.commit()


def _challenge_dict(db: Session, c: Challenge, user_id: str) -> dict:
    """Shape a challenge for the Flutter UI, from the current user's view."""
    is_challenger = c.challenger_id == user_id
    me = c.challenger if is_challenger else c.opponent
    opp = c.opponent if is_challenger else c.challenger

    my_score = 0
    opp_score = 0
    if c.started_at:
        end = c.ends_at or _now()
        my_score = _window_volume_ml(db, me.id if me else user_id, c.started_at, end)
        opp_score = _window_volume_ml(db, opp.id, c.started_at, end) if opp else 0

    return {
        "id": c.id,
        "status": c.status.value,
        "opponent_name": _display_name(opp),
        "opponent_username": opp.username if opp else "",
        "is_challenger": is_challenger,
        "duration_days": c.duration_days,
        "message": c.message,
        "my_score_ml": my_score,
        "opponent_score_ml": opp_score,
        "created_at": c.created_at.isoformat() if c.created_at else None,
        "started_at": c.started_at.isoformat() if c.started_at else None,
        "ends_at": c.ends_at.isoformat() if c.ends_at else None,
    }


def list_challenges(db: Session, *, user_id: str) -> dict:
    """All non-declined races involving the user, newest first, with live scores."""
    challenges = (
        db.query(Challenge)
        .options(joinedload(Challenge.challenger), joinedload(Challenge.opponent))
        .filter(
            or_(
                Challenge.challenger_id == user_id,
                Challenge.opponent_id == user_id,
            ),
            Challenge.status != ChallengeStatus.DECLINED,
        )
        .order_by(Challenge.created_at.desc())
        .all()
    )
    _finalize_expired(db, challenges)
    return {"challenges": [_challenge_dict(db, c, user_id) for c in challenges]}


# --- notifications inbox ------------------------------------------------


def build_notifications(db: Session, *, user_id: str) -> dict:
    """Aggregate reminders received + challenge invites/results into one feed."""
    since = _now() - NOTIFICATION_WINDOW
    items: List[dict] = []

    # 1) Hydration reminders received from friends.
    reminders = (
        db.query(ReminderLog)
        .filter(ReminderLog.friend_id == user_id, ReminderLog.created_at >= since)
        .order_by(ReminderLog.created_at.desc())
        .all()
    )
    sender_ids = {r.user_id for r in reminders}
    senders = (
        {u.id: u for u in db.query(User).filter(User.id.in_(sender_ids)).all()}
        if sender_ids
        else {}
    )
    for r in reminders:
        name = _display_name(senders.get(r.user_id))
        items.append(
            {
                "id": f"reminder:{r.id}",
                "type": "reminder",
                "sender_name": name,
                "message": "nhắc bạn uống nước rồi đó! 💧",
                "created_at": r.created_at.isoformat() if r.created_at else None,
                "is_read": False,
                "challenge_id": None,
                "challenge_status": None,
            }
        )

    # 2) Challenge events involving the user.
    challenges = (
        db.query(Challenge)
        .options(joinedload(Challenge.challenger), joinedload(Challenge.opponent))
        .filter(
            or_(
                Challenge.challenger_id == user_id,
                Challenge.opponent_id == user_id,
            ),
            Challenge.created_at >= since,
        )
        .order_by(Challenge.created_at.desc())
        .all()
    )
    _finalize_expired(db, challenges)
    for c in challenges:
        is_opponent = c.opponent_id == user_id
        if c.status == ChallengeStatus.PENDING and is_opponent:
            items.append(
                {
                    "id": f"challenge:{c.id}",
                    "type": "challenge",
                    "sender_name": _display_name(c.challenger),
                    "message": "mời bạn vào một cuộc đua uống nước 🏆",
                    "created_at": c.created_at.isoformat() if c.created_at else None,
                    "is_read": False,
                    "challenge_id": c.id,
                    "challenge_status": c.status.value,
                }
            )
        elif c.status == ChallengeStatus.COMPLETED:
            other = c.challenger if is_opponent else c.opponent
            items.append(
                {
                    "id": f"challenge:{c.id}",
                    "type": "challenge",
                    "sender_name": _display_name(other),
                    "message": "cuộc đua uống nước đã kết thúc — xem kết quả! 🏁",
                    "created_at": (
                        c.ends_at.isoformat()
                        if c.ends_at
                        else (c.created_at.isoformat() if c.created_at else None)
                    ),
                    "is_read": False,
                    "challenge_id": c.id,
                    "challenge_status": c.status.value,
                }
            )

    items.sort(key=lambda x: x["created_at"] or "", reverse=True)
    return {"notifications": items}
