"""
Water Profile API endpoints - Set user profile and calculate daily water intake
"""

from datetime import datetime
from typing import Any

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.api import deps
from app.core.database import get_db
from app.models.user import User
from app.schemas.water_profile import (
    UserSummaryResponse,
    WaterCalculationBreakdown,
    WaterCalculationResponse,
    WaterProfileCreate,
    WaterProfileEnums,
    WaterProfileResponse,
    WaterProfileUpdate,
)
from app.services.water_formula_service import (
    ActivityLevel,
    Gender,
    HealthCondition,
    JobType,
    UserWaterProfile,
    VeggieIntake,
    WaterFormulaService,
)

router = APIRouter()


def _check_profile_complete(user: User) -> bool:
    """Check if user has complete water profile for calculation"""
    required_fields = [
        user.gender,
        user.age,
        user.height,
        user.weight,
        user.activity_level,
        user.job_type,
        user.veggie_intake,
    ]
    return all(field is not None for field in required_fields)


def _user_to_water_profile(user: User) -> UserWaterProfile:
    """Convert User model to UserWaterProfile for calculation"""
    if not _check_profile_complete(user):
        raise ValueError("Thông tin chưa đủ để tính toán")

    return UserWaterProfile(
        gender=Gender(user.gender),
        age=user.age,
        height=user.height,
        weight=user.weight,
        activity_level=ActivityLevel(user.activity_level),
        job_type=JobType(user.job_type),
        health_conditions=[
            HealthCondition(cond) for cond in (user.health_conditions or ["none"])
        ],
        veggie_intake=VeggieIntake(user.veggie_intake),
        coffee_cups_per_day=user.coffee_cups_per_day,
        alcohol_units_per_day=user.alcohol_units_per_day,
    )


@router.get("/enums", response_model=WaterProfileEnums)
def get_water_profile_enums() -> Any:
    """Get available enum values for frontend dropdowns"""
    return WaterProfileEnums()


@router.get("/", response_model=WaterProfileResponse)
def get_water_profile(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """Get current user's water profile"""

    # Update profile_complete status
    current_user.profile_complete = _check_profile_complete(current_user)
    db.commit()

    return WaterProfileResponse(
        gender=current_user.gender,
        age=current_user.age,
        height=current_user.height,
        weight=current_user.weight,
        activity_level=current_user.activity_level,
        job_type=current_user.job_type,
        health_conditions=current_user.health_conditions or ["none"],
        veggie_intake=current_user.veggie_intake,
        coffee_cups_per_day=current_user.coffee_cups_per_day,
        alcohol_units_per_day=current_user.alcohol_units_per_day,
        profile_complete=current_user.profile_complete,
        calculated_daily_goal_ml=current_user.calculated_daily_goal_ml,
        formula_last_updated=current_user.formula_last_updated,
    )


@router.put("/", response_model=WaterProfileResponse)
def update_water_profile(
    profile: WaterProfileUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """Update user's water profile and recalculate daily goal"""

    # Update profile fields (only if provided)
    update_data = profile.dict(exclude_unset=True)

    for field, value in update_data.items():
        if hasattr(current_user, field):
            setattr(current_user, field, value)

    # Check if profile is now complete
    current_user.profile_complete = _check_profile_complete(current_user)

    # Recalculate daily goal if profile is complete
    if current_user.profile_complete:
        try:
            user_profile = _user_to_water_profile(current_user)
            result = WaterFormulaService.calculate_daily_water(user_profile)

            current_user.calculated_daily_goal_ml = result.total_ml
            current_user.daily_goal_ml = result.total_ml  # Update main goal too
            current_user.formula_last_updated = datetime.utcnow()

        except Exception as e:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Lỗi tính toán: {str(e)}",
            )

    db.commit()
    db.refresh(current_user)

    return WaterProfileResponse(
        gender=current_user.gender,
        age=current_user.age,
        height=current_user.height,
        weight=current_user.weight,
        activity_level=current_user.activity_level,
        job_type=current_user.job_type,
        health_conditions=current_user.health_conditions or ["none"],
        veggie_intake=current_user.veggie_intake,
        coffee_cups_per_day=current_user.coffee_cups_per_day,
        alcohol_units_per_day=current_user.alcohol_units_per_day,
        profile_complete=current_user.profile_complete,
        calculated_daily_goal_ml=current_user.calculated_daily_goal_ml,
        formula_last_updated=current_user.formula_last_updated,
    )


@router.post("/calculate", response_model=WaterCalculationResponse)
def calculate_water_intake(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """Calculate daily water intake based on current profile"""

    if not _check_profile_complete(current_user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vui lòng hoàn thiện thông tin cá nhân trước khi tính toán",
        )

    try:
        user_profile = _user_to_water_profile(current_user)
        result = WaterFormulaService.calculate_daily_water(user_profile)

        # Update user's calculated goal
        current_user.calculated_daily_goal_ml = result.total_ml
        current_user.daily_goal_ml = result.total_ml
        current_user.formula_last_updated = datetime.utcnow()
        db.commit()

        return WaterCalculationResponse(
            total_ml=result.total_ml,
            daily_goal_l=result.daily_goal_l,
            daily_goal_cups=result.daily_goal_cups,
            breakdown=WaterCalculationBreakdown(
                base_ml=result.base_ml,
                activity_add=result.activity_add,
                job_add=result.job_add,
                health_add=result.health_add,
                veggie_add=result.veggie_add,
                coffee_add=result.coffee_add,
                alcohol_add=result.alcohol_add,
            ),
            has_warnings=result.has_warnings,
            warning_message=result.warning_message,
            calculated_at=datetime.utcnow(),
        )

    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail=f"Lỗi tính toán: {str(e)}"
        )


@router.get("/summary", response_model=UserSummaryResponse)
def get_user_summary(
    db: Session = Depends(get_db),
    current_user: User = Depends(deps.get_current_active_user),
) -> Any:
    """Get user summary for B5 Review screen display"""

    if not _check_profile_complete(current_user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Vui lòng hoàn thiện thông tin cá nhân",
        )

    # Gender + Age
    gender_map = {"male": "Nam", "female": "Nữ", "other": "Khác"}
    gender_display = gender_map.get(current_user.gender, "Không rõ")
    gender_age = f"{gender_display} - {current_user.age} tuoi"

    # Height + Weight
    height_weight = f"{current_user.height} cm - {current_user.weight} kg"

    # Activity level
    activity_map = {
        "sedentary": "Ít vận động",
        "light": "Nhẹ nhàng",
        "moderate": "Vừa phải",
        "active": "Năng động",
        "very_active": "Rất năng động",
    }
    activity = activity_map.get(current_user.activity_level, "Không rõ")

    # Job type
    job_map = {
        "office": "Văn phòng",
        "mixed": "Hỗn hợp",
        "outdoor": "Ngoài trời",
        "manual": "Tay chân",
    }
    job = job_map.get(current_user.job_type, "Không rõ")

    return UserSummaryResponse(
        gender_age=gender_age, height_weight=height_weight, activity=activity, job=job
    )
