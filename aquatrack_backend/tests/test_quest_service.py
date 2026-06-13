from datetime import datetime, timezone

import pytest

from app.models import (Conversation, DailySummary, QuestClaim, Referral,
                        ScanHistory, User)
from app.services import quest_service
from app.services import referral_service as rs
from app.services.quest_service import QuestAlreadyClaimed, QuestNotDone

# Fixed "now": 2026-05-30 12:00 UTC = 19:00 local (Asia/Ho_Chi_Minh, a Saturday).
NOW = datetime(2026, 5, 30, 12, 0, tzinfo=timezone.utc)
# A timestamp that falls inside both the daily and weekly window for NOW.
IN_WINDOW = datetime(2026, 5, 30, 12, 0)


def _add_validated_referral(db, user, referred_id, when=IN_WINDOW):
    """user refers `referred_id`, validated at `when` (None = still pending)."""
    db.add(User(id=referred_id, email=f"{referred_id}@t.com", hashed_password="x"))
    db.add(
        Referral(
            referrer_id=user.id,
            referred_id=referred_id,
            validated_at=when,
        )
    )
    db.commit()


def _add_scan(db, user, liquid="water", when=IN_WINDOW):
    db.add(
        ScanHistory(
            user_id=user.id,
            container_label="Ly thủy tinh",
            container_capacity_ml=200,
            fill_level_percent=1.0,
            liquid_type=liquid,
            confidence_score=0.9,
            estimated_volume_ml=200,
            created_at=when,
        )
    )
    db.commit()


# --- period / windowing -------------------------------------------------


def test_period_key_daily_uses_local_date(user):
    window = quest_service.get_period_window(NOW, user.timezone, "daily")
    assert window.key == "2026-05-30"


def test_period_key_weekly_uses_iso_week(user):
    window = quest_service.get_period_window(NOW, user.timezone, "weekly")
    # 2026-05-30 is in ISO week 22.
    assert window.key == "2026-W22"


# --- derived progress ---------------------------------------------------


def test_smart_scan_progress_counts_scans_in_window(db, user):
    _add_scan(db, user)
    _add_scan(db, user)
    quests = quest_service.get_quests(db, user, now=NOW)
    scan = next(q for q in quests if q["id"] == "smart_scan")
    assert scan["progress"] == 2
    assert scan["target"] == 4
    assert scan["done"] is False
    assert scan["claimed"] is False


def test_ambassador_counts_validated_referrals_in_week(db, user):
    _add_validated_referral(db, user, "newbie-1")
    quests = quest_service.get_quests(db, user, now=NOW)
    amb = next(q for q in quests if q["id"] == "hydration_ambassador")
    assert amb["period"] == "weekly"
    assert amb["progress"] == 1
    assert amb["target"] == 1
    assert amb["done"] is True


def test_ambassador_counts_through_real_validate_path(db, user):
    # Exercise the real service path (attach → validate stamps validated_at)
    # so the quest's window comparison runs against a service-produced value,
    # not a hand-set one — guards the naive/aware datetime convention.
    code = rs.get_or_create_code(db, user)
    db.add(User(id="newbie", email="newbie@t.com", hashed_password="x"))
    db.commit()
    rs.attach_referral(db, referred_id="newbie", code=code)
    rs.validate_referral(db, referred_id="newbie", now=IN_WINDOW)

    quests = quest_service.get_quests(db, user, now=NOW)
    amb = next(q for q in quests if q["id"] == "hydration_ambassador")
    assert amb["progress"] == 1
    assert amb["done"] is True


def test_ambassador_ignores_pending_and_out_of_week_referrals(db, user):
    _add_validated_referral(db, user, "pending-1", when=None)  # not validated
    _add_validated_referral(
        db, user, "old-1", when=datetime(2026, 5, 1, 12, 0)
    )  # previous week
    quests = quest_service.get_quests(db, user, now=NOW)
    amb = next(q for q in quests if q["id"] == "hydration_ambassador")
    assert amb["progress"] == 0
    assert amb["done"] is False


# --- claim semantics ----------------------------------------------------


def test_claim_not_done_raises(db, user):
    _add_scan(db, user)  # only 1 of 4
    with pytest.raises(QuestNotDone):
        quest_service.claim_quest(db, user, "smart_scan", now=NOW)


def test_claim_done_credits_reward_once(db, user):
    for _ in range(4):
        _add_scan(db, user)

    result = quest_service.claim_quest(db, user, "smart_scan", now=NOW)

    assert result["reward_xp"] == 30
    assert result["reward_coin"] == 15
    assert user.total_xp == 30
    assert user.coins == 15
    assert db.query(QuestClaim).count() == 1

    # Second claim in same period is rejected and does not double-credit.
    with pytest.raises(QuestAlreadyClaimed):
        quest_service.claim_quest(db, user, "smart_scan", now=NOW)
    assert user.coins == 15


# --- completion bonus ---------------------------------------------------


def test_daily_bonus_unlocks_when_all_base_quests_done(db, user):
    # smart_scan done
    for _ in range(4):
        _add_scan(db, user)
    # ai_companion done (1 user chat)
    db.add(
        Conversation(
            user_id=user.id,
            session_id="s1",
            message_id="m1",
            content="hi",
            message_type="user",
            created_at=IN_WINDOW,
        )
    )
    db.commit()

    quests = quest_service.get_quests(db, user, now=NOW)
    bonus = next(q for q in quests if q["id"] == "daily_bonus")
    # Only 2 of 4 base daily quests are done → bonus locked.
    assert bonus["done"] is False
    with pytest.raises(QuestNotDone):
        quest_service.claim_quest(db, user, "daily_bonus", now=NOW)


def test_breakthrough_target_is_80_percent_of_goal(db, user):
    # goal 2000 -> target 1600; 1600 effective ml = done.
    db.add(
        DailySummary(
            user_id=user.id,
            date=IN_WINDOW.date(),
            daily_goal_ml=2000,
            total_effective_ml=1600,
            goal_achieved=False,
        )
    )
    db.commit()
    quests = quest_service.get_quests(db, user, now=NOW)
    q = next(q for q in quests if q["id"] == "breakthrough_hydration")
    assert q["target"] == 1600
    assert q["progress"] == 1600
    assert q["done"] is True


def test_weekly_chest_credits_random_coin_when_all_weekly_done(db, user):
    # persistence_week: streak 7
    user.current_streak = 7
    # hydration_warrior: 5 days goal achieved this week
    for i in range(5):
        db.add(
            DailySummary(
                user_id=user.id,
                date=__import__("datetime").date(2026, 5, 25 + i),
                daily_goal_ml=2000,
                total_effective_ml=2000,
                goal_achieved=True,
            )
        )
    # water_scientist: 3 distinct liquid types
    for liquid in ("water", "tea", "coffee"):
        _add_scan(db, user, liquid=liquid)
    # hydration_ambassador: 1 validated referral this week
    _add_validated_referral(db, user, "newbie-1")
    db.commit()

    result = quest_service.claim_quest(db, user, "weekly_bonus", now=NOW)
    assert 50 <= result["reward_coin"] <= 150
    assert result["reward_xp"] == 0
    assert user.coins == result["reward_coin"]
