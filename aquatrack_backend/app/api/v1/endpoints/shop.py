"""Shop endpoints — the coin storefront (ADR 0004).

Avatar purchases live in `/avatars`. This router covers the non-avatar Shop
inventory: currently the one-time **Streak Freeze** consumable.
"""

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud import user_crud
from app.services.streak_service import FreezePurchaseError, StreakService

router = APIRouter()


class StreakFreezeStatus(BaseModel):
    owned: bool
    price: int


class StreakFreezePurchaseResponse(BaseModel):
    owned: bool
    coins: int
    price: int


@router.get("/streak-freeze", response_model=StreakFreezeStatus)
async def get_streak_freeze_status(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Whether the user currently owns a Streak Freeze, and its price."""
    user = user_crud.get(db, current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    return StreakFreezeStatus(
        owned=bool(user.streak_freeze_owned),
        price=StreakService.STREAK_FREEZE_PRICE,
    )


@router.post("/streak-freeze/purchase", response_model=StreakFreezePurchaseResponse)
async def purchase_streak_freeze(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Buy one Streak Freeze. Binary inventory — rejects if already owned."""
    user = user_crud.get(db, current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    try:
        user = StreakService.purchase_freeze(db, user)
    except FreezePurchaseError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))

    return StreakFreezePurchaseResponse(
        owned=bool(user.streak_freeze_owned),
        coins=user.coins,
        price=StreakService.STREAK_FREEZE_PRICE,
    )
