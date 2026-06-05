"""Avatar ownership + coin purchase rules.

Ownership is permanent and comes from either a derived threshold
(level/streak) or a stored coin purchase. The default avatar is always owned;
mission avatars are never ownable yet.
"""

import pytest

from app.services.avatar_service import AvatarPurchaseError, AvatarService


def test_default_avatar_always_owned(db, user):
    assert AvatarService.is_owned(user, "giot_nuoc") is True


def test_level_avatar_owned_only_at_threshold(db, user):
    user.current_level = 5
    assert AvatarService.is_owned(user, "suoi_non") is False  # needs level 6
    user.current_level = 6
    assert AvatarService.is_owned(user, "suoi_non") is True


def test_streak_avatar_owned_at_longest_streak(db, user):
    user.longest_streak = 99
    assert AvatarService.is_owned(user, "long_thuy") is False
    user.longest_streak = 100
    assert AvatarService.is_owned(user, "long_thuy") is True


def test_coin_avatar_locked_until_purchased(db, user):
    user.coins = 5000
    assert AvatarService.is_owned(user, "thuy_linh") is False
    AvatarService.purchase(db, user, "thuy_linh")
    assert AvatarService.is_owned(user, "thuy_linh") is True
    assert user.coins == 5000 - 1100
    assert "thuy_linh" in user.owned_avatars


def test_purchase_rejected_without_enough_coins(db, user):
    user.coins = 100
    with pytest.raises(AvatarPurchaseError):
        AvatarService.purchase(db, user, "thuy_linh")  # costs 1100
    assert user.coins == 100


def test_cannot_buy_non_coin_avatar(db, user):
    user.coins = 9999
    with pytest.raises(AvatarPurchaseError):
        AvatarService.purchase(db, user, "long_thuy")  # streak-only
    with pytest.raises(AvatarPurchaseError):
        AvatarService.purchase(db, user, "lam_ha")  # mission


def test_dual_unlock_owned_by_level_or_coin(db, user):
    # dong_chay: Cấp 10 hoặc 280 xu
    user.current_level = 10
    assert AvatarService.is_owned(user, "dong_chay") is True
    # Already owned via level → buying is rejected.
    user.coins = 1000
    with pytest.raises(AvatarPurchaseError):
        AvatarService.purchase(db, user, "dong_chay")

    user.current_level = 1
    assert AvatarService.is_owned(user, "dong_chay") is False
    AvatarService.purchase(db, user, "dong_chay")
    assert AvatarService.is_owned(user, "dong_chay") is True


def test_unknown_avatar_never_owned(db, user):
    assert AvatarService.is_owned(user, "avatar_1") is False
