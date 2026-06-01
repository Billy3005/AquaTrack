"""Derived-on-read friends payloads shaped for the Flutter contract.

See docs/adr/0003-friends-derived-on-read.md. The backend reshapes its
responses to exactly what social_service.dart parses, deriving each friend's
hydration standing and the weekly leaderboard on read.
"""

from datetime import date, datetime, timedelta, timezone

import pytest

from app.crud.friend import friend_crud
from app.models import DailySummary, IntakeLog, User
from app.models.friend_request import FriendRequest, FriendRequestStatus
from app.services import friends_view_service as fvs

# A fixed "now": 2026-05-31 03:00 UTC -> 10:00 Asia/Ho_Chi_Minh (Sunday).
NOW = datetime(2026, 5, 31, 3, 0, tzinfo=timezone.utc)
TODAY_LOCAL = date(2026, 5, 31)


def make_user(db, uid, username, full_name="", streak=0, last_login=NOW):
    u = User(
        id=uid,
        email=f"{uid}@test.com",
        hashed_password="x",
        username=username,
        full_name=full_name or username,
        avatar_id="avatar_02",
        timezone="Asia/Ho_Chi_Minh",
        daily_goal_ml=2000,
        calculated_daily_goal_ml=2000,
        current_streak=streak,
        total_xp=0,
        coins=0,
        current_level=1,
        last_login=last_login,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


def add_summary(db, uid, d, effective, goal=2000):
    pct = effective / goal * 100.0
    s = DailySummary(
        user_id=uid,
        date=d,
        daily_goal_ml=goal,
        total_volume_ml=effective,
        total_effective_ml=effective,
        progress_percentage=pct,
        goal_achieved=pct >= 100.0,
        log_count=1 if effective else 0,
    )
    db.add(s)
    db.commit()
    return s


def add_intake(db, uid, logged_at, effective=250):
    """Insert one intake log. Production writes ``logged_at`` with
    ``datetime.now()`` (server-local naive), so store the (tz-aware) ``logged_at``
    converted to server-local naive — matching how the service reads it back."""
    log = IntakeLog(
        user_id=uid,
        volume_ml=effective,
        liquid_type="water",
        hydration_factor=1.0,
        effective_volume_ml=effective,
        logged_at=logged_at.astimezone().replace(tzinfo=None),
    )
    db.add(log)
    db.commit()
    return log


def befriend(db, a, b):
    friend_crud.create_friendship(db, user_id=a, friend_user_id=b)


# --- friends payload ----------------------------------------------------


def test_friends_payload_envelope_and_derived_fields(db, user):
    f = make_user(db, "u2", "user2", full_name="Bạn Hai", streak=5)
    befriend(db, user.id, f.id)
    # 1800/2000 = 90% progress, logged just now -> normal (đủ nước).
    add_intake(db, f.id, NOW, effective=1800)

    payload = fvs.build_friends_payload(db, user, now=NOW)

    assert "friends" in payload
    assert len(payload["friends"]) == 1
    entry = payload["friends"][0]
    assert entry["username"] == "user2"
    assert entry["display_name"] == "Bạn Hai"
    assert entry["current_streak"] == 5
    assert entry["status"] == "normal"
    assert entry["daily_progress"] == pytest.approx(0.9, abs=0.01)
    assert entry["is_online"] is True


@pytest.mark.parametrize(
    "minutes_ago,expected",
    [(5, "normal"), (119, "normal"), (121, "thirsty"), (170, "thirsty")],
)
def test_friend_status_from_last_log_recency(db, user, minutes_ago, expected):
    """Status keys off when the friend last drank: within 2h -> normal,
    older than 2h (but still logged today) -> thirsty."""
    f = make_user(db, "u2", "user2")
    befriend(db, user.id, f.id)
    add_intake(db, f.id, NOW - timedelta(minutes=minutes_ago), effective=250)

    entry = fvs.build_friends_payload(db, user, now=NOW)["friends"][0]
    assert entry["status"] == expected


def test_friend_status_dry_without_log_today(db, user):
    f = make_user(db, "u2", "user2")
    befriend(db, user.id, f.id)  # no intake today

    entry = fvs.build_friends_payload(db, user, now=NOW)["friends"][0]
    assert entry["status"] == "dry"
    assert entry["daily_progress"] == 0.0


def test_is_online_false_when_last_login_stale(db, user):
    f = make_user(db, "u2", "user2", last_login=NOW - timedelta(minutes=30))
    befriend(db, user.id, f.id)
    add_intake(db, f.id, NOW, effective=1800)

    entry = fvs.build_friends_payload(db, user, now=NOW)["friends"][0]
    assert entry["is_online"] is False


# --- requests payload ---------------------------------------------------


def test_requests_payload_has_nested_from_user(db, user):
    sender = make_user(db, "u3", "user3", full_name="Người Gửi")
    db.add(
        FriendRequest(
            id="req-1",
            sender_id=sender.id,
            receiver_id=user.id,
            status=FriendRequestStatus.PENDING,
        )
    )
    db.commit()

    payload = fvs.build_requests_payload(db, user, now=NOW)

    assert len(payload["requests"]) == 1
    req = payload["requests"][0]
    assert req["from_user_id"] == "u3"
    assert req["to_user_id"] == user.id
    assert req["status"] == "pending"
    assert req["from_user"]["username"] == "user3"
    assert req["from_user"]["display_name"] == "Người Gửi"


# --- leaderboard --------------------------------------------------------


def test_leaderboard_ranks_user_and_friends_by_percentage(db, user):
    f = make_user(db, "u2", "user2")
    befriend(db, user.id, f.id)
    # Friend hits goal today (100%), requesting user only 50%.
    add_summary(db, f.id, TODAY_LOCAL, effective=2000)
    add_summary(db, user.id, TODAY_LOCAL, effective=1000)

    board = fvs.build_leaderboard_payload(db, user, now=NOW)["leaderboard"]

    assert [e["user_id"] for e in board] == ["u2", user.id]
    assert board[0]["rank"] == 1
    assert board[1]["rank"] == 2
    assert board[0]["hydration_percentage"] >= board[1]["hydration_percentage"]


# --- social stats -------------------------------------------------------


def test_social_stats_counts_statuses_and_requests(db, user):
    thirsty = make_user(db, "u2", "user2")
    befriend(db, user.id, thirsty.id)
    # Logged today but last drink 3h ago -> thirsty.
    add_intake(db, thirsty.id, NOW - timedelta(hours=3), effective=400)

    sender = make_user(db, "u3", "user3")
    db.add(
        FriendRequest(
            id="req-1",
            sender_id=sender.id,
            receiver_id=user.id,
            status=FriendRequestStatus.PENDING,
        )
    )
    db.commit()

    stats = fvs.build_social_stats(db, user, now=NOW)

    assert stats["total_friends"] == 1
    assert stats["thirsty_friends"] == 1
    assert stats["pending_requests"] == 1
    assert "online_friends" in stats
    assert "stressed_friends" in stats
