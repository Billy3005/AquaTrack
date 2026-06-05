"""Avatar Catalog + ownership/purchase logic.

The catalog is the source of truth for which avatars exist and how each is
unlocked. It mirrors the Flutter `avatar_catalog.dart` (and the design's
`avatar-data.jsx`) — only the *unlock rules* live here; visual specs (colors,
features) are rendered client-side.

Ownership model (see CONTEXT.md):
  - `level`  → owned when current_level >= level_req      (derived, not stored)
  - `streak` → owned when longest_streak >= streak_req    (derived, not stored)
  - `coin`   → owned once purchased                        (stored in owned_avatars)
  - `mission`→ planned, never owned yet ("Sắp ra mắt")
A few avatars offer two paths (e.g. level OR coin); meeting either grants it.
"""

from typing import Optional

from sqlalchemy.orm import Session

from app.models.user import User

DEFAULT_AVATAR_ID = "giot_nuoc"


class AvatarSpec:
    """Unlock rule for one avatar. Visuals are rendered on the client."""

    def __init__(
        self,
        avatar_id: str,
        *,
        level_req: Optional[int] = None,
        streak_req: Optional[int] = None,
        coin_price: Optional[int] = None,
        mission: bool = False,
        default: bool = False,
    ):
        self.id = avatar_id
        self.level_req = level_req
        self.streak_req = streak_req
        self.coin_price = coin_price
        self.mission = mission
        self.default = default


# Order matches the design tiers (common → legendary).
AVATAR_CATALOG: dict[str, AvatarSpec] = {
    s.id: s
    for s in [
        # COMMON — leveling
        AvatarSpec("giot_nuoc", level_req=1, default=True),
        AvatarSpec("suong_mai", level_req=3),
        AvatarSpec("suoi_non", level_req=6),
        # RARE — level OR coins / mission
        AvatarSpec("dong_chay", level_req=10, coin_price=280),
        AvatarSpec("thuy_ba", level_req=14, coin_price=320),
        AvatarSpec("lam_ha", mission=True),
        # EPIC — coins (some with a level alt)
        AvatarSpec("hai_lam", level_req=20, coin_price=900),
        AvatarSpec("thuy_linh", coin_price=1100),
        AvatarSpec("lam_than", level_req=28, coin_price=1400),
        # LEGENDARY — premium / streak / mastery
        AvatarSpec("hai_vuong", coin_price=2500),
        AvatarSpec("long_thuy", streak_req=100),
        AvatarSpec("thuy_de", level_req=40, coin_price=5000),
    ]
}


class AvatarPurchaseError(Exception):
    """Raised when a coin purchase cannot be completed."""


class AvatarService:
    """Ownership checks and coin purchases for avatars."""

    @staticmethod
    def is_owned(user: User, avatar_id: str) -> bool:
        spec = AVATAR_CATALOG.get(avatar_id)
        if spec is None:
            return False
        if spec.default:
            return True
        if spec.level_req is not None and (user.current_level or 1) >= spec.level_req:
            return True
        if (
            spec.streak_req is not None
            and (user.longest_streak or 0) >= spec.streak_req
        ):
            return True
        if spec.coin_price is not None and avatar_id in (user.owned_avatars or []):
            return True
        return False

    @staticmethod
    def purchase(db: Session, user: User, avatar_id: str) -> User:
        """Spend coins to own a `coin`-unlock avatar. Idempotency is the
        caller's concern only insofar as already-owned avatars are rejected."""
        spec = AVATAR_CATALOG.get(avatar_id)
        if spec is None:
            raise AvatarPurchaseError("Avatar không tồn tại")
        if spec.coin_price is None:
            raise AvatarPurchaseError("Avatar này không mua bằng xu")
        if AvatarService.is_owned(user, avatar_id):
            raise AvatarPurchaseError("Bạn đã sở hữu avatar này")
        if (user.coins or 0) < spec.coin_price:
            raise AvatarPurchaseError("Không đủ xu")

        user.coins = (user.coins or 0) - spec.coin_price
        # Reassign a new list so SQLAlchemy flags the JSON column dirty.
        user.owned_avatars = list(user.owned_avatars or []) + [avatar_id]
        db.add(user)
        db.commit()
        db.refresh(user)
        return user
