"""Streak Freeze (ADR 0004): a one-time consumable that bridges a single missed
day so the derived streak does not reset.

Behaviours under test:
  - a recorded frozen day bridges a gap but adds 0 to streak length
  - an owned (unconsumed) Freeze provisionally keeps a live streak alive on read
  - one Freeze covers one missed day only; two missed days still break
  - reconcile_freeze consumes the Freeze at log time, recording the missed day
  - purchase_freeze deducts coins / enforces the binary inventory
"""

from datetime import date, timedelta

import pytest

from app.models.daily_summary import DailySummary
from app.services.streak_service import FreezePurchaseError, StreakService

TODAY = date.today()


def d(delta):
    return TODAY - timedelta(days=delta)


def add_summary(db, uid, day, effective=2000, goal=2000):
    db.add(
        DailySummary(
            user_id=uid,
            date=day,
            daily_goal_ml=goal,
            total_volume_ml=effective,
            total_effective_ml=effective,
            progress_percentage=effective / goal * 100.0,
            goal_achieved=effective >= goal,
            log_count=1 if effective else 0,
        )
    )
    db.commit()


# ── pure resolver ────────────────────────────────────────────────────────────


def test_frozen_day_bridges_gap_without_adding_length():
    # Achieved today, today-1, today-3; today-2 missed but frozen.
    achieved = {d(0), d(1), d(3)}
    frozen = {d(2)}
    # 3 achieved days, bridged by the frozen day → length 3 (frozen adds 0).
    assert StreakService._resolve_streak(achieved, TODAY, frozen, False) == 3


def test_unfrozen_gap_breaks_the_run():
    achieved = {d(0), d(1), d(3)}
    # today-2 missed and not frozen, no freeze owned → run stops at the gap.
    assert StreakService._resolve_streak(achieved, TODAY, set(), False) == 2


def test_owned_freeze_keeps_streak_alive_when_yesterday_missed():
    # Achieved through today-2; yesterday (today-1) missed; today not logged yet.
    achieved = {d(3), d(2)}
    # Without a freeze the streak is dead (most recent older than yesterday).
    assert StreakService._resolve_streak(achieved, TODAY, set(), False) == 0
    # Owning a freeze provisionally bridges yesterday → streak stays at 2.
    assert StreakService._resolve_streak(achieved, TODAY, set(), True) == 2


def test_one_freeze_covers_one_day_only():
    # Achieved through today-3, then today-2 AND today-1 both missed: a two-day
    # head gap. A single freeze bridges one day only → the streak is dead.
    achieved = {d(4), d(3)}
    assert StreakService._resolve_streak(achieved, TODAY, set(), True) == 0
    # Sanity: with both gap days frozen, the run survives (length 2, no add).
    assert StreakService._resolve_streak(achieved, TODAY, {d(2), d(1)}, False) == 2


def test_today_not_logged_still_counts_with_no_freeze():
    achieved = {d(2), d(1)}
    assert StreakService._resolve_streak(achieved, TODAY, set(), False) == 2


# ── DB-backed read ───────────────────────────────────────────────────────────


def test_calculate_current_streak_uses_frozen_dates(db, user):
    add_summary(db, user.id, d(0))
    add_summary(db, user.id, d(1))
    add_summary(db, user.id, d(3))
    user.frozen_dates = [d(2).isoformat()]
    db.commit()

    assert StreakService.calculate_current_streak(db, user.id) == 3


# ── reconciliation (consume at log time) ─────────────────────────────────────


def test_reconcile_consumes_freeze_for_single_missed_day(db, user):
    # Achieved today-2, missed yesterday, achieved today (just logged).
    add_summary(db, user.id, d(2))
    add_summary(db, user.id, d(0))
    user.streak_freeze_owned = True
    db.commit()

    consumed = StreakService.reconcile_freeze(db, user.id)

    assert consumed is True
    db.refresh(user)
    assert user.streak_freeze_owned is False
    assert d(1).isoformat() in (user.frozen_dates or [])


def test_reconcile_does_not_consume_for_two_day_gap(db, user):
    add_summary(db, user.id, d(3))
    add_summary(db, user.id, d(0))
    user.streak_freeze_owned = True
    db.commit()

    assert StreakService.reconcile_freeze(db, user.id) is False
    db.refresh(user)
    assert user.streak_freeze_owned is True
    assert not (user.frozen_dates or [])


def test_reconcile_skips_when_today_not_achieved(db, user):
    # Achieved yesterday and 3 days ago; today not logged to goal yet. A sub-goal
    # log must NOT consume the Freeze on the older gap (only the log that makes
    # today achieved may consume it).
    add_summary(db, user.id, d(1))
    add_summary(db, user.id, d(3))
    user.streak_freeze_owned = True
    db.commit()

    assert StreakService.reconcile_freeze(db, user.id) is False
    db.refresh(user)
    assert user.streak_freeze_owned is True
    assert not (user.frozen_dates or [])


def test_reconcile_noop_without_owned_freeze(db, user):
    add_summary(db, user.id, d(2))
    add_summary(db, user.id, d(0))
    db.commit()

    assert StreakService.reconcile_freeze(db, user.id) is False


# ── purchase ─────────────────────────────────────────────────────────────────


def test_purchase_deducts_coins_and_sets_inventory(db, user):
    user.coins = 500
    db.commit()

    StreakService.purchase_freeze(db, user)

    db.refresh(user)
    assert user.streak_freeze_owned is True
    assert user.coins == 500 - StreakService.STREAK_FREEZE_PRICE


def test_purchase_rejected_when_already_owned(db, user):
    user.coins = 500
    user.streak_freeze_owned = True
    db.commit()

    with pytest.raises(FreezePurchaseError):
        StreakService.purchase_freeze(db, user)


def test_purchase_rejected_when_insufficient_coins(db, user):
    user.coins = 10
    db.commit()

    with pytest.raises(FreezePurchaseError):
        StreakService.purchase_freeze(db, user)
    db.refresh(user)
    assert user.coins == 10
    assert user.streak_freeze_owned is False
