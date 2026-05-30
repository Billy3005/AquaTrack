from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.user import user_crud
from app.schemas.quest import ClaimResponse, QuestsResponse, WeekDayStatus
from app.services import quest_service
from app.services.quest_service import (QuestAlreadyClaimed, QuestNotDone,
                                        QuestNotFound)

router = APIRouter()


def _get_user(db: Session, user_id: str):
    user = user_crud.get(db, id=user_id)
    if user is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    return user


@router.get("/", response_model=QuestsResponse)
async def get_quests(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """List daily + weekly quests with derived progress and claim state."""
    user = _get_user(db, current_user_id)
    now = datetime.now(timezone.utc)
    quests = quest_service.get_quests(db, user, now=now)
    strip_raw = quest_service.build_week_strip(db, user, now)
    resets = quest_service.get_reset_times(now, user.timezone)

    return QuestsResponse(
        daily=[q for q in quests if q["period"] == "daily"],
        weekly=[q for q in quests if q["period"] == "weekly"],
        coins=user.coins or 0,
        total_xp=user.total_xp or 0,
        current_level=user.current_level or 1,
        current_streak=user.current_streak or 0,
        week_strip=[WeekDayStatus(**d) for d in strip_raw],
        daily_reset_at=resets["daily_reset_at"],
        weekly_reset_at=resets["weekly_reset_at"],
    )


@router.post("/{quest_id}/claim", response_model=ClaimResponse)
async def claim_quest(
    quest_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Claim a Done quest's reward (also handles daily_bonus / weekly_bonus)."""
    user = _get_user(db, current_user_id)
    try:
        result = quest_service.claim_quest(db, user, quest_id)
    except QuestNotFound:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Quest not found"
        )
    except QuestNotDone:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Quest is not completed yet",
        )
    except QuestAlreadyClaimed:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Reward already claimed for this period",
        )

    return ClaimResponse(**result)
