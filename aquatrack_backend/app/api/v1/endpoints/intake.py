from datetime import date, datetime
from typing import Any, List, Optional

from fastapi import APIRouter, Depends, HTTPException, Query, status
from pydantic import BaseModel
from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.intake_log import intake_log_crud
from app.models.daily_summary import DailySummary
from app.models.intake_log import IntakeLog
from app.schemas.intake_log import IntakeLogCreate, IntakeLogResponse, IntakeLogUpdate


# Response schemas
class AchievementUnlocked(BaseModel):
    achievement_id: str
    achievement_key: str
    achievement_type: str
    title: str
    description: str
    icon: str
    xp_reward: int
    unlocked_at: Any


class IntakeLogWithAchievements(BaseModel):
    intake_log: IntakeLogResponse
    achievements: List[AchievementUnlocked] = []
    level_progress: Optional[dict] = None


router = APIRouter()


@router.post("/debug", status_code=status.HTTP_201_CREATED)
async def create_intake_log_debug(
    intake_log_data: IntakeLogCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Debug endpoint for intake log creation - simple response
    """
    from app.crud.user import user_crud

    try:
        # Create simple intake log
        db_intake_log = intake_log_crud.create(
            db=db, obj_in=intake_log_data, user_id=current_user_id
        )

        # Return simple response to test if creation works
        return {
            "success": True,
            "intake_log_id": db_intake_log.id,
            "volume_ml": db_intake_log.volume_ml,
            "effective_volume_ml": db_intake_log.effective_volume_ml,
        }
    except Exception as e:
        return {"success": False, "error": str(e)}


@router.post(
    "/", response_model=IntakeLogWithAchievements, status_code=status.HTTP_201_CREATED
)
async def create_intake_log(
    intake_log_data: IntakeLogCreate,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Create new intake log entry with achievement processing and streak tracking
    """
    # Import services here to avoid circular imports
    # Create intake log (temporarily disable streak for testing)
    from app.crud.user import user_crud
    from app.services.achievement_service import achievement_service

    # Create simple intake log
    db_intake_log = intake_log_crud.create(
        db=db, obj_in=intake_log_data, user_id=current_user_id
    )
    achievements = []  # No achievements for now

    # Calculate today's total for UI
    today_summary_result = (
        db.query(func.coalesce(func.sum(IntakeLog.effective_volume_ml), 0))
        .filter(
            and_(
                IntakeLog.user_id == current_user_id,
                func.date(IntakeLog.logged_at) == date.today(),
            )
        )
        .scalar()
    )

    today_total_ml = int(today_summary_result or 0)

    # Get user info
    user = user_crud.get(db, current_user_id)
    daily_goal = user.daily_goal_ml if user else 2000

    # Check if goal achieved today (80% threshold)
    goal_achieved = today_total_ml >= (daily_goal * 0.8)

    # Only update streak once per day when goal first achieved
    if goal_achieved and user:
        # Check if we already updated streak today by checking DailySummary
        today = date.today()

        existing_summary = (
            db.query(DailySummary)
            .filter(DailySummary.user_id == current_user_id, DailySummary.date == today)
            .first()
        )

        if not existing_summary or not existing_summary.goal_achieved:
            # First time achieving goal today - update streak
            new_streak = user.current_streak + 1
            user_crud.update_stats(db, user_id=current_user_id, new_streak=new_streak)
            current_streak = new_streak
            longest_streak = max(user.longest_streak, new_streak)

            # Update or create DailySummary
            if existing_summary:
                existing_summary.goal_achieved = True
                existing_summary.total_volume_ml = today_total_ml
                existing_summary.total_effective_ml = today_total_ml
            else:
                daily_summary = DailySummary(
                    user_id=current_user_id,
                    date=today,
                    daily_goal_ml=daily_goal,  # Fix: Add required field
                    total_volume_ml=today_total_ml,
                    total_effective_ml=today_total_ml,
                    goal_achieved=True,
                )
                db.add(daily_summary)
            db.commit()
        else:
            # Goal already achieved today - no streak update
            current_streak = user.current_streak
            longest_streak = user.longest_streak
    else:
        current_streak = user.current_streak if user else 0
        longest_streak = user.longest_streak if user else 0

    print(
        f"MANUAL STREAK: Total: {today_total_ml}/{daily_goal}ml, Goal: {goal_achieved}, Streak: {current_streak}"
    )

    # Get updated user level progress
    user = user_crud.get(db, current_user_id)
    level_progress = None
    if user:
        level_progress = achievement_service.get_level_progress(user.total_xp)
        # Add streak info to level progress
        level_progress.update(
            {
                "current_streak": current_streak,
                "longest_streak": longest_streak,
                "goal_achieved_today": goal_achieved,
                "today_total_ml": today_total_ml,
                "daily_goal_ml": user.daily_goal_ml or 2000,
            }
        )

    # Convert achievements to response format
    achievement_responses = [
        AchievementUnlocked(
            achievement_id=ach["achievement_id"],
            achievement_key=ach["achievement_key"],
            achievement_type=(
                ach["achievement_type"].value
                if hasattr(ach["achievement_type"], "value")
                else str(ach["achievement_type"])
            ),
            title=ach["title"],
            description=ach["description"],
            icon=ach["icon"],
            xp_reward=ach["xp_reward"],
            unlocked_at=ach["unlocked_at"],
        )
        for ach in achievements
    ]

    return IntakeLogWithAchievements(
        intake_log=db_intake_log,
        achievements=achievement_responses,
        level_progress=level_progress,
    )


@router.get("/", response_model=List[IntakeLogResponse])
async def get_intake_logs(
    skip: int = Query(0, ge=0),
    limit: int = Query(100, ge=1, le=1000),
    date_from: Optional[date] = Query(None, description="Filter logs from this date"),
    date_to: Optional[date] = Query(None, description="Filter logs until this date"),
    liquid_type: Optional[str] = Query(None, description="Filter by liquid type"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get user's intake logs with optional filters
    """
    # Build filters
    filters = [IntakeLog.user_id == current_user_id]

    if date_from:
        filters.append(func.date(IntakeLog.logged_at) >= date_from)
    if date_to:
        filters.append(func.date(IntakeLog.logged_at) <= date_to)
    if liquid_type:
        filters.append(IntakeLog.liquid_type == liquid_type)

    # Query with filters
    query = db.query(IntakeLog).filter(and_(*filters))
    query = query.order_by(IntakeLog.logged_at.desc())
    query = query.offset(skip).limit(limit)

    return query.all()


@router.get("/today", response_model=List[IntakeLogResponse])
async def get_today_intake_logs(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get today's intake logs for current user
    """
    today = date.today()
    filters = [
        IntakeLog.user_id == current_user_id,
        func.date(IntakeLog.logged_at) == today,
    ]

    query = db.query(IntakeLog).filter(and_(*filters))
    query = query.order_by(IntakeLog.logged_at.desc())

    return query.all()


@router.get("/summary/today")
async def get_today_summary(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get today's intake summary (total volume, effective volume, log count, XP)
    """
    today = date.today()

    # Query today's logs
    result = (
        db.query(
            func.count(IntakeLog.id).label("log_count"),
            func.coalesce(func.sum(IntakeLog.volume_ml), 0).label("total_volume"),
            func.coalesce(func.sum(IntakeLog.effective_volume_ml), 0).label(
                "total_effective"
            ),
            func.coalesce(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp), 0).label(
                "total_xp"
            ),
        )
        .filter(
            and_(
                IntakeLog.user_id == current_user_id,
                func.date(IntakeLog.logged_at) == today,
            )
        )
        .first()
    )

    return {
        "date": today,
        "log_count": result.log_count or 0,
        "total_volume_ml": result.total_volume or 0,
        "total_effective_ml": result.total_effective or 0,
        "total_xp_earned": result.total_xp or 0,
    }


@router.get("/recent", response_model=List[IntakeLogResponse])
async def get_recent_intake_logs(
    limit: int = Query(10, ge=1, le=50),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get recent intake logs for current user
    """
    query = db.query(IntakeLog).filter(IntakeLog.user_id == current_user_id)
    query = query.order_by(IntakeLog.logged_at.desc()).limit(limit)

    return query.all()


@router.get("/{intake_log_id}", response_model=IntakeLogResponse)
async def get_intake_log(
    intake_log_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get specific intake log by ID
    """
    intake_log = intake_log_crud.get(db=db, id=intake_log_id)
    if not intake_log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Intake log not found"
        )

    # Check ownership
    if intake_log.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to access this intake log",
        )

    return intake_log


@router.put("/{intake_log_id}", response_model=IntakeLogResponse)
async def update_intake_log(
    intake_log_id: str,
    intake_log_update: IntakeLogUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Update intake log
    """
    # Get existing log
    intake_log = intake_log_crud.get(db=db, id=intake_log_id)
    if not intake_log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Intake log not found"
        )

    # Check ownership
    if intake_log.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to update this intake log",
        )

    # Recalculate if volume or liquid type changed
    update_data = intake_log_update.dict(exclude_unset=True)

    if "volume_ml" in update_data or "liquid_type" in update_data:
        new_volume = update_data.get("volume_ml", intake_log.volume_ml)
        new_liquid_type = update_data.get("liquid_type", intake_log.liquid_type)

        hydration_factors = {
            "water": 1.0,
            "tea": 0.85,
            "coffee": 0.8,
            "juice": 0.7,
            "sports_drink": 0.9,
            "other": 0.75,
        }

        hydration_factor = hydration_factors.get(new_liquid_type, 0.75)
        effective_volume = int(new_volume * hydration_factor)
        base_xp = max(1, new_volume // 100)

        update_data.update(
            {
                "hydration_factor": hydration_factor,
                "effective_volume_ml": effective_volume,
                "xp_earned": base_xp,
            }
        )

    # Update log
    updated_log = intake_log_crud.update(db=db, db_obj=intake_log, obj_in=update_data)
    return updated_log


@router.delete("/{intake_log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_intake_log(
    intake_log_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Delete intake log
    """
    # Get existing log
    intake_log = intake_log_crud.get(db=db, id=intake_log_id)
    if not intake_log:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Intake log not found"
        )

    # Check ownership
    if intake_log.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Not enough permissions to delete this intake log",
        )

    # Delete log
    intake_log_crud.remove(db=db, id=intake_log_id)
    return


@router.get("/stats/liquid-types")
async def get_liquid_types_stats(
    days: int = Query(7, ge=1, le=365, description="Number of days to analyze"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get liquid types distribution for the last N days
    """
    from datetime import timedelta

    start_date = date.today() - timedelta(days=days - 1)

    # Query liquid types distribution
    result = (
        db.query(
            IntakeLog.liquid_type,
            func.count(IntakeLog.id).label("count"),
            func.sum(IntakeLog.volume_ml).label("total_volume"),
            func.sum(IntakeLog.effective_volume_ml).label("total_effective"),
        )
        .filter(
            and_(
                IntakeLog.user_id == current_user_id,
                func.date(IntakeLog.logged_at) >= start_date,
            )
        )
        .group_by(IntakeLog.liquid_type)
        .all()
    )

    return [
        {
            "liquid_type": r.liquid_type,
            "log_count": r.count,
            "total_volume_ml": r.total_volume or 0,
            "total_effective_ml": r.total_effective or 0,
        }
        for r in result
    ]
