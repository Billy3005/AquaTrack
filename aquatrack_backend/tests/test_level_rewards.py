"""Level-Up Rewards (ADR 0008): reaching Level N grants (N-1)*10 coins,
once, tracked by a monotonic high-water mark (coins_granted_up_to_level).

reconcile_level_coins takes the AUTHORITATIVE total XP explicitly (callers
compute it as sum(IntakeLog.xp_earned + bonus_xp) + user.total_xp)."""

from app.core.leveling import reconcile_level_coins

# XP thresholds for the canonical curve (level*100 + (level-1)*50):
# Lv2=250, Lv3=650, Lv4=1200, Lv5=1900.


def test_single_level_up_grants_coins(db, user):
    # User just crossed into Level 2; coins not yet granted for it (marker=1).
    user.coins = 0
    user.coins_granted_up_to_level = 1
    db.commit()

    awarded = reconcile_level_coins(db, user, total_xp=250)

    assert awarded == 10  # reaching Lv2 = (2-1)*10
    assert user.coins == 10
    assert user.coins_granted_up_to_level == 2


def test_reconcile_is_idempotent(db, user):
    # Same XP, repeated reconciles (re-login / multi-device): pay once only.
    user.coins = 0
    user.coins_granted_up_to_level = 1
    db.commit()

    first = reconcile_level_coins(db, user, total_xp=250)  # Level 2
    second = reconcile_level_coins(db, user, total_xp=250)

    assert first == 10
    assert second == 0
    assert user.coins == 10  # not double-granted


def test_multi_level_jump_sums_each_level(db, user):
    # A big XP grant (e.g. claiming a Legendary achievement) crosses many levels
    # at once: pay every level in the span, not just the final one.
    user.coins = 0
    user.coins_granted_up_to_level = 1
    db.commit()

    awarded = reconcile_level_coins(db, user, total_xp=1900)  # Level 5

    # Lv2+Lv3+Lv4+Lv5 = 10 + 20 + 30 + 40
    assert awarded == 100
    assert user.coins == 100
    assert user.coins_granted_up_to_level == 5


def test_no_level_change_grants_nothing(db, user):
    # Already reconciled at the current level: no-op.
    user.coins = 55
    user.coins_granted_up_to_level = 3
    db.commit()

    awarded = reconcile_level_coins(db, user, total_xp=650)  # Level 3

    assert awarded == 0
    assert user.coins == 55
    assert user.coins_granted_up_to_level == 3
