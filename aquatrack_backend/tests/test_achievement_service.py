from datetime import datetime

import pytest

from app.models import (Conversation, ConversationSession, Friend, IntakeLog,
                        QuestClaim, ScanHistory)
from app.services import achievement_service
from app.services.achievement_service import (AchievementAlreadyClaimed,
                                              AchievementNotDone,
                                              AchievementNotFound)

WHEN = datetime(2026, 6, 7, 12, 0)


def _add_scan(db, user, liquid="water"):
    db.add(
        ScanHistory(
            user_id=user.id,
            container_label="Ly thủy tinh",
            container_capacity_ml=200,
            fill_level_percent=1.0,
            liquid_type=liquid,
            confidence_score=0.9,
            estimated_volume_ml=200,
            created_at=WHEN,
        )
    )
    db.commit()


def _achievement(achs, ach_id):
    return next(a for a in achs if a["id"] == ach_id)


# --- tracer: derived progress ------------------------------------------


def test_scan_progress_counts_lifetime_scans(db, user):
    _add_scan(db, user)
    _add_scan(db, user)

    achs = achievement_service.get_achievements(db, user)

    # First tier (target 1) is Done; progress is capped at target.
    first_scan = _achievement(achs, "scan_first")
    assert first_scan["domain"] == "scan"
    assert first_scan["progress"] == 1
    assert first_scan["target"] == 1
    assert first_scan["unlocked"] is True
    assert first_scan["claimed"] is False

    # A higher tier shows the raw running count (uncapped below its target).
    analyst = _achievement(achs, "scan_50")
    assert analyst["progress"] == 2
    assert analyst["target"] == 50
    assert analyst["unlocked"] is False


# --- claim semantics ----------------------------------------------------


def test_claim_not_done_raises(db, user):
    with pytest.raises(AchievementNotDone):
        achievement_service.claim_achievement(db, user, "scan_first")


def test_claim_done_credits_xp_once(db, user):
    _add_scan(db, user)  # scan_first (target 1) now Done

    result = achievement_service.claim_achievement(db, user, "scan_first")

    assert result["reward_xp"] == 50  # common tier
    assert user.total_xp == 50

    from app.models import AchievementClaim

    assert db.query(AchievementClaim).count() == 1

    # Second claim is rejected and does not double-credit.
    with pytest.raises(AchievementAlreadyClaimed):
        achievement_service.claim_achievement(db, user, "scan_first")
    assert user.total_xp == 50


def test_claim_unknown_id_raises(db, user):
    with pytest.raises(AchievementNotFound):
        achievement_service.claim_achievement(db, user, "does_not_exist")


def test_claimed_state_reflected_on_read(db, user):
    _add_scan(db, user)
    achievement_service.claim_achievement(db, user, "scan_first")

    achs = achievement_service.get_achievements(db, user)
    assert _achievement(achs, "scan_first")["claimed"] is True


# --- per-domain counting ------------------------------------------------


def test_streak_uses_longest_streak_not_current(db, user):
    user.current_streak = 2
    user.longest_streak = 7
    db.commit()

    achs = achievement_service.get_achievements(db, user)
    assert _achievement(achs, "streak_7")["unlocked"] is True
    assert _achievement(achs, "streak_3")["unlocked"] is True


def test_quest_domain_counts_quest_claims(db, user):
    for i in range(3):
        db.add(QuestClaim(user_id=user.id, quest_id=f"q{i}", period_key="2026-06-07"))
    db.commit()

    achs = achievement_service.get_achievements(db, user)
    assert _achievement(achs, "quest_10")["progress"] == 3


def test_coach_domain_counts_sessions_not_messages(db, user):
    # Two sessions, each with multiple messages — Coach counts sessions.
    for sid in ("s1", "s2"):
        db.add(ConversationSession(session_id=sid, user_id=user.id))
        for n in range(3):
            db.add(
                Conversation(
                    user_id=user.id,
                    session_id=sid,
                    message_id=f"{sid}-{n}",
                    content="hi",
                    message_type="user",
                )
            )
    db.commit()

    achs = achievement_service.get_achievements(db, user)
    assert _achievement(achs, "coach_10")["progress"] == 2


def test_social_domain_ignores_blocked_and_inactive(db, user):
    db.add(Friend(user_id=user.id, friend_user_id="f1"))
    db.add(Friend(user_id=user.id, friend_user_id="f2", is_blocked=True))
    db.add(Friend(user_id=user.id, friend_user_id="f3", is_active=False))
    db.commit()

    achs = achievement_service.get_achievements(db, user)
    assert _achievement(achs, "social_5")["progress"] == 1


def test_claim_sets_level_from_full_total_xp_not_bonus_only(db, user):
    # Intake XP (650) dominates; user.total_xp (bonus) is 0.
    from app.core.leveling import calculate_level_from_xp

    db.add(
        IntakeLog(
            user_id=user.id,
            volume_ml=1000,
            liquid_type="water",
            hydration_factor=1.0,
            effective_volume_ml=1000,
            xp_earned=650,
            bonus_xp=0,
        )
    )
    db.commit()

    # Claim a trivially-Done achievement (log_first, target 1).
    result = achievement_service.claim_achievement(db, user, "log_first")

    expected_level = calculate_level_from_xp(650 + result["reward_xp"])["level"]
    assert user.current_level == expected_level
    # Must NOT be the (much lower) level derived from bonus XP alone.
    assert user.current_level > calculate_level_from_xp(result["reward_xp"])["level"]
    assert result["total_xp"] == 650 + result["reward_xp"]


def test_reward_xp_scales_with_tier(db, user):
    achs = achievement_service.get_achievements(db, user)
    assert _achievement(achs, "streak_3")["reward_xp"] == 50  # common
    assert _achievement(achs, "streak_7")["reward_xp"] == 150  # rare
    assert _achievement(achs, "level_20")["reward_xp"] == 400  # epic
    assert _achievement(achs, "streak_100")["reward_xp"] == 1000  # legendary
