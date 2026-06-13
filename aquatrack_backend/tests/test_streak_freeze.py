"""Streak Freeze (ADR 0004, amended): a one-time consumable that bridges a
single missed day so the derived streak does not reset.

Duolingo semantics ("dùng là mất"): the Freeze burns on the FIRST fully-passed
missed day it protects — at that midnight, deterministically — whether or not
the streak ultimately survives. Reads only *record* that already-decided fact
(lazy reconciliation), so the inventory resets and the Shop sells a new one.

Behaviours under test:
  - a recorded frozen day bridges a gap but adds 0 to streak length
  - reconcile on read consumes the Freeze for yesterday's miss (streak lives)
  - two missed days: Freeze burns on the first, streak still breaks
  - a Freeze never covers days missed before it was purchased (no resurrection)
  - today (pending) never consumes the Freeze
  - legacy rows without freeze_purchased_on still consume (no date bound)
  - purchase_freeze deducts coins, stamps the purchase date, binary inventory
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


def give_freeze(db, user, purchased_on=None):
    user.streak_freeze_owned = True
    user.freeze_purchased_on = purchased_on
    db.commit()


# ── pure resolver (no provisional bridging — only recorded frozen days) ──────


def test_frozen_day_bridges_gap_without_adding_length():
    # Achieved today, today-1, today-3; today-2 missed but frozen.
    achieved = {d(0), d(1), d(3)}
    frozen = {d(2)}
    # 3 achieved days, bridged by the frozen day → length 3 (frozen adds 0).
    assert StreakService._resolve_streak(achieved, TODAY, frozen) == 3


def test_unfrozen_gap_breaks_the_run():
    achieved = {d(0), d(1), d(3)}
    # today-2 missed and not frozen → run stops at the gap.
    assert StreakService._resolve_streak(achieved, TODAY, set()) == 2


def test_frozen_head_gap_keeps_streak_current():
    # Achieved through today-2; yesterday missed but frozen; today pending.
    achieved = {d(3), d(2)}
    assert StreakService._resolve_streak(achieved, TODAY, set()) == 0
    assert StreakService._resolve_streak(achieved, TODAY, {d(1)}) == 2


def test_today_not_logged_still_counts():
    achieved = {d(2), d(1)}
    assert StreakService._resolve_streak(achieved, TODAY, set()) == 2


# ── reconciliation (lazy consume on read) ────────────────────────────────────


def test_yesterday_miss_consumes_freeze_and_streak_survives(db, user):
    # Achieved up to today-2, missed yesterday, freeze owned since today-2.
    add_summary(db, user.id, d(3))
    add_summary(db, user.id, d(2))
    give_freeze(db, user, purchased_on=d(2))

    consumed = StreakService.reconcile_freeze(db, user.id)

    assert consumed is True
    db.refresh(user)
    assert user.streak_freeze_owned is False  # Shop resets — repurchasable
    assert d(1).isoformat() in (user.frozen_dates or [])
    # The bridged run is alive: 2 achieved days, frozen day adds 0.
    assert StreakService.calculate_current_streak(db, user.id) == 2


def test_body_gap_consumed_after_user_achieves_again(db, user):
    # Achieved today-2, missed yesterday, achieved today (freeze owned all along).
    add_summary(db, user.id, d(2))
    add_summary(db, user.id, d(0))
    give_freeze(db, user, purchased_on=d(2))

    assert StreakService.reconcile_freeze(db, user.id) is True
    db.refresh(user)
    assert user.streak_freeze_owned is False
    assert d(1).isoformat() in (user.frozen_dates or [])
    assert StreakService.calculate_current_streak(db, user.id) == 2


def test_two_day_gap_burns_freeze_on_first_miss_and_streak_breaks(db, user):
    # The user's bug-report scenario: achieve, buy, then never achieve again.
    # Freeze burns on the FIRST missed day; the second miss kills the streak;
    # the Shop must show the item as consumed (repurchasable).
    add_summary(db, user.id, d(3))
    give_freeze(db, user, purchased_on=d(3))

    assert StreakService.reconcile_freeze(db, user.id) is True
    db.refresh(user)
    assert user.streak_freeze_owned is False
    assert d(2).isoformat() in (user.frozen_dates or [])
    assert StreakService.calculate_current_streak(db, user.id) == 0


def test_freeze_does_not_cover_days_missed_before_purchase(db, user):
    # Streak died (gap at today-4), THEN the user bought a Freeze yesterday.
    # The Freeze must not resurrect the dead run.
    add_summary(db, user.id, d(5))
    give_freeze(db, user, purchased_on=d(1))

    assert StreakService.reconcile_freeze(db, user.id) is False
    db.refresh(user)
    assert user.streak_freeze_owned is True  # waits for the next streak
    assert not (user.frozen_dates or [])
    assert StreakService.calculate_current_streak(db, user.id) == 0


def test_pending_today_does_not_consume(db, user):
    # Achieved yesterday; today has no goal yet — still pending, no miss.
    add_summary(db, user.id, d(1))
    give_freeze(db, user, purchased_on=d(1))

    assert StreakService.reconcile_freeze(db, user.id) is False
    db.refresh(user)
    assert user.streak_freeze_owned is True
    assert StreakService.calculate_current_streak(db, user.id) == 1


def test_legacy_freeze_without_purchase_date_still_consumes(db, user):
    # Rows from before the freeze_purchased_on column: no date bound.
    add_summary(db, user.id, d(2))
    give_freeze(db, user, purchased_on=None)

    assert StreakService.reconcile_freeze(db, user.id) is True
    db.refresh(user)
    assert user.streak_freeze_owned is False
    assert d(1).isoformat() in (user.frozen_dates or [])


def test_legacy_freeze_burns_current_gap_not_an_ancient_one(db, user):
    # Legacy row (no purchase date) with an old dead run AND a live run that
    # missed yesterday. The burn must land on the current run's miss (mirrors
    # the old provisional behaviour) — burning the ancient gap would kill the
    # live streak.
    add_summary(db, user.id, d(8))  # old run, died at d(7)
    add_summary(db, user.id, d(2))  # current run
    give_freeze(db, user, purchased_on=None)

    assert StreakService.reconcile_freeze(db, user.id) is True
    db.refresh(user)
    assert user.frozen_dates == [d(1).isoformat()]
    assert StreakService.calculate_current_streak(db, user.id) == 1


def test_reconcile_noop_without_owned_freeze(db, user):
    add_summary(db, user.id, d(2))
    add_summary(db, user.id, d(0))
    db.commit()

    assert StreakService.reconcile_freeze(db, user.id) is False


def test_calculate_current_streak_reconciles_inline(db, user):
    # The read path itself must materialise the consumption — no separate call.
    add_summary(db, user.id, d(2))
    give_freeze(db, user, purchased_on=d(2))

    assert StreakService.calculate_current_streak(db, user.id) == 1
    db.refresh(user)
    assert user.streak_freeze_owned is False
    assert d(1).isoformat() in (user.frozen_dates or [])


# ── purchase ─────────────────────────────────────────────────────────────────


def test_purchase_deducts_coins_and_stamps_date(db, user):
    user.coins = 500
    db.commit()

    StreakService.purchase_freeze(db, user)

    db.refresh(user)
    assert user.streak_freeze_owned is True
    assert user.coins == 500 - StreakService.STREAK_FREEZE_PRICE
    assert user.freeze_purchased_on == date.today()


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


def test_consume_then_repurchase_then_consume_again(db, user):
    # Full lifecycle: the whole point of A — the item is a repeatable coin sink.
    add_summary(db, user.id, d(4))
    give_freeze(db, user, purchased_on=d(4))
    user.coins = 400
    db.commit()

    # Burns on d(3), the first miss after purchase.
    assert StreakService.reconcile_freeze(db, user.id) is True

    # Re-buy today; it must not touch older gaps (d(2), d(1) stay unbridged).
    db.refresh(user)
    StreakService.purchase_freeze(db, user)
    assert StreakService.reconcile_freeze(db, user.id) is False
    db.refresh(user)
    assert user.streak_freeze_owned is True
    assert user.frozen_dates == [d(3).isoformat()]
