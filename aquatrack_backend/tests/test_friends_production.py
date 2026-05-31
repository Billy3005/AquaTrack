"""Production-hardening behaviors for the friends feature.

Covers: presence touch, reminder rate-limiting, mutual-invite auto-accept.
See docs/adr/0003-friends-derived-on-read.md (production hardening section).
"""

import asyncio
from datetime import datetime, timedelta, timezone

import pytest

from app.crud.friend import friend_crud
from app.crud.user import user_crud
from app.models import User
from app.models.friend_request import FriendRequest, FriendRequestStatus
from app.services import friends_view_service as fvs

NOW = datetime(2026, 5, 31, 3, 0, tzinfo=timezone.utc)


def make_user(db, uid, username, last_login=None):
    u = User(
        id=uid,
        email=f"{uid}@test.com",
        hashed_password="x",
        username=username,
        full_name=username,
        timezone="Asia/Ho_Chi_Minh",
        daily_goal_ml=2000,
        calculated_daily_goal_ml=2000,
        total_xp=0,
        coins=0,
        current_streak=0,
        last_login=last_login,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


# --- item 1: presence touch ---------------------------------------------


def test_touch_activity_sets_last_login_when_null(db, user):
    user_crud.touch_activity(db, user_id=user.id, now=NOW.replace(tzinfo=None))
    db.refresh(user)
    assert user.last_login is not None


def test_touch_activity_skips_when_fresh(db):
    fresh = (NOW - timedelta(seconds=10)).replace(tzinfo=None)
    u = make_user(db, "u2", "user2", last_login=fresh)
    user_crud.touch_activity(
        db, user_id="u2", now=NOW.replace(tzinfo=None), threshold_seconds=60
    )
    db.refresh(u)
    assert u.last_login == fresh  # untouched, no write churn


def test_touch_activity_refreshes_when_stale(db):
    stale = (NOW - timedelta(minutes=30)).replace(tzinfo=None)
    u = make_user(db, "u2", "user2", last_login=stale)
    user_crud.touch_activity(
        db, user_id="u2", now=NOW.replace(tzinfo=None), threshold_seconds=60
    )
    db.refresh(u)
    assert u.last_login > stale


# --- item 2: reminder rate limit ----------------------------------------


def _add_reminders(db, sender_id, n, when):
    from app.models import ReminderLog

    for i in range(n):
        db.add(ReminderLog(user_id=sender_id, friend_id=f"friend-{i}", created_at=when))
    db.commit()


def test_reminders_sent_today_counts_only_today(db, user):
    _add_reminders(db, user.id, 3, NOW.replace(tzinfo=None))
    _add_reminders(db, user.id, 5, (NOW - timedelta(days=1)).replace(tzinfo=None))

    assert fvs.reminders_sent_today(db, user.id, NOW) == 3


def test_send_reminder_blocked_past_daily_limit(db, user):
    from app.services.social_service import social_service

    friend = make_user(db, "f1", "friend1")
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=friend.id)
    _add_reminders(db, user.id, fvs.REMINDER_DAILY_LIMIT, NOW.replace(tzinfo=None))

    result = asyncio.run(
        social_service.send_hydration_reminder(
            db, sender_id=user.id, friend_username="friend1", message=None
        )
    )
    assert result["success"] is False


def test_send_reminder_succeeds_under_limit(db, user):
    from app.services.social_service import social_service

    friend = make_user(db, "f1", "friend1")
    friend_crud.create_friendship(db, user_id=user.id, friend_user_id=friend.id)

    result = asyncio.run(
        social_service.send_hydration_reminder(
            db, sender_id=user.id, friend_username="friend1", message=None
        )
    )
    assert result["success"] is True
    assert fvs.reminders_sent_today(db, user.id, NOW) >= 1


# --- item 5: mutual-invite auto-accept ----------------------------------


def test_mutual_invite_auto_accepts(db, user):
    make_user(db, "u2", "user2")
    db.add(
        FriendRequest(
            id="req-1",
            sender_id="u2",
            receiver_id=user.id,
            status=FriendRequestStatus.PENDING,
        )
    )
    db.commit()

    from app.services.social_service import social_service

    result = asyncio.run(
        social_service.send_friend_request(
            db, sender_id=user.id, receiver_username="user2", message=None
        )
    )
    assert result["success"] is True
    assert friend_crud.are_friends(db, user_id=user.id, other_user_id="u2")
