from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud import user_crud
from app.services.avatar_service import AvatarPurchaseError, AvatarService

router = APIRouter()


class AvatarPurchaseResponse(BaseModel):
    avatar_id: str
    coins: int
    owned_avatars: list


@router.post("/{avatar_id}/purchase", response_model=AvatarPurchaseResponse)
async def purchase_avatar(
    avatar_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Buy a coin-unlock avatar. Deducts coins and records ownership."""
    user = user_crud.get(db, current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    try:
        user = AvatarService.purchase(db, user, avatar_id)
    except AvatarPurchaseError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc))

    return AvatarPurchaseResponse(
        avatar_id=avatar_id,
        coins=user.coins,
        owned_avatars=list(user.owned_avatars or []),
    )
