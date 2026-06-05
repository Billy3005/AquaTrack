from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud import user_crud
from app.schemas.user import UserResponse, UserStats, UserUpdate
from app.services.avatar_service import AvatarService
from app.services.onboarding_service import OnboardingService
from app.services.streak_service import StreakService

router = APIRouter()


@router.get("/profile", response_model=UserResponse)
async def get_user_profile(
    current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)
):
    """
    Get detailed user profile.

    Returns comprehensive user information including stats and preferences.
    """
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    # Debug logging for API response
    print(f"\n=== DEBUG /users/profile for user {user.email} ===")
    print(f"Body data from DB:")
    print(f"  gender: {user.gender} (type: {type(user.gender)})")
    print(f"  age: {user.age} (type: {type(user.age)})")
    print(f"  height: {user.height} (type: {type(user.height)})")
    print(f"  weight: {user.weight} (type: {type(user.weight)})")
    print(
        f"  activity_level: {user.activity_level} (type: {type(user.activity_level)})"
    )
    print(f"  job_type: {user.job_type} (type: {type(user.job_type)})")
    print(
        f"  health_conditions: {user.health_conditions} (type: {type(user.health_conditions)})"
    )
    print(
        f"  coffee_cups_per_day: {user.coffee_cups_per_day} (type: {type(user.coffee_cups_per_day)})"
    )
    print(
        f"  alcohol_units_per_day: {user.alcohol_units_per_day} (type: {type(user.alcohol_units_per_day)})"
    )
    print(f"  timezone: {user.timezone} (type: {type(user.timezone)})")
    print(f"=== END DEBUG ===\n")

    return user


@router.put("/profile", response_model=UserResponse)
async def update_user_profile(
    user_update: UserUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Update user profile and preferences.

    Updates user settings like username, avatar, daily goal, notifications, etc.
    If body info is provided, automatically calculates new daily goal.
    """
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    # Only an owned avatar may be equipped.
    if user_update.avatar_id and user_update.avatar_id != user.avatar_id:
        if not AvatarService.is_owned(user, user_update.avatar_id):
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Bạn chưa sở hữu avatar này",
            )

    # Check if username is already taken (if being updated)
    if user_update.username and user_update.username != user.username:
        existing_user = user_crud.get_by_username(db, username=user_update.username)
        if existing_user:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken"
            )

    # Check if this is an onboarding update (contains body info)
    onboarding_fields = [
        "gender",
        "age",
        "height",
        "weight",
        "activity_level",
        "job_type",
    ]
    is_onboarding_update = any(
        getattr(user_update, field, None) is not None for field in onboarding_fields
    )

    if is_onboarding_update:
        # Convert UserUpdate to dict for onboarding service
        update_data = user_update.dict(exclude_unset=True)

        # Use onboarding service to calculate goal and update user
        OnboardingService.update_user_with_onboarding(user, update_data)

        # Commit the changes
        db.add(user)
        db.commit()
        db.refresh(user)

        return user
    else:
        # Regular profile update
        updated_user = user_crud.update(db, db_obj=user, obj_in=user_update)
        return updated_user


@router.get("/stats", response_model=UserStats)
async def get_user_stats(
    current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)
):
    """
    Get user statistics summary.

    Returns level, XP, streak, and volume statistics for the user.
    """
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    # Recompute the streak on read so it resets after a skipped day even when
    # the user hasn't logged anything (the stored value is only updated on log).
    current_streak = StreakService.calculate_current_streak(db, current_user_id)
    if current_streak != user.current_streak:
        user_crud.update_stats(db, user_id=current_user_id, new_streak=current_streak)

    return UserStats(
        current_level=user.current_level,
        total_xp=user.total_xp,
        current_streak=current_streak,
        longest_streak=user.longest_streak,
        total_logs_count=user.total_logs_count,
        total_volume_ml=user.total_volume_ml,
        total_volume_liters=user.total_volume_ml / 1000.0,
    )


@router.post("/preferences")
async def update_user_preferences(
    preferences: dict,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Update user preferences (batch update).

    Accepts a dictionary of preference updates for flexible settings management.
    """
    user = user_crud.update_preferences(
        db, user_id=current_user_id, preferences=preferences
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return {"message": "Preferences updated successfully"}


@router.delete("/account")
async def delete_user_account(
    current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)
):
    """
    Delete user account permanently.

    ⚠️ WARNING: This action cannot be undone.
    All user data including logs, achievements, and progress will be deleted.
    """
    # For safety, we'll deactivate instead of hard delete
    # Hard delete can be implemented separately if needed
    user = user_crud.deactivate(db, user_id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return {
        "message": (
            "Account has been deactivated. " "Contact support to permanently delete."
        )
    }


@router.post("/reactivate")
async def reactivate_user_account(
    current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)
):
    """
    Reactivate deactivated user account.

    Restores access to a previously deactivated account.
    """
    user = user_crud.reactivate(db, user_id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return {"message": "Account reactivated successfully"}
