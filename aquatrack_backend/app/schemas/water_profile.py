"""
Pydantic schemas for water profile and calculation
"""

from datetime import datetime
from typing import Dict, List, Optional

from pydantic import BaseModel, validator

from app.services.water_formula_service import (ActivityLevel, Gender,
                                                HealthCondition, JobType,
                                                VeggieIntake)


class WaterProfileBase(BaseModel):
    """Base schema for water profile"""

    # B1 - Body
    gender: Optional[Gender] = None
    age: Optional[int] = None
    height: Optional[int] = None  # cm
    weight: Optional[float] = None  # kg

    # B2 - Lifestyle
    activity_level: Optional[ActivityLevel] = None
    job_type: Optional[JobType] = None

    # B3 - Health
    health_conditions: List[HealthCondition] = ["none"]

    # B4 - Diet
    veggie_intake: Optional[VeggieIntake] = None
    coffee_cups_per_day: int = 0
    alcohol_units_per_day: int = 0

    @validator("health_conditions")
    def validate_health_conditions(cls, v):
        """Ensure health_conditions is always a list"""
        if not v:
            return ["none"]
        if "none" in v and len(v) > 1:
            # If "none" is selected with others, remove "none"
            return [cond for cond in v if cond != "none"]
        return v

    @validator("age")
    def validate_age(cls, v):
        if v is not None and not (1 <= v <= 120):
            raise ValueError("Tuổi phải từ 1 đến 120")
        return v

    @validator("height")
    def validate_height(cls, v):
        if v is not None and not (130 <= v <= 210):
            raise ValueError("Chiều cao phải từ 130cm đến 210cm")
        return v

    @validator("weight")
    def validate_weight(cls, v):
        if v is not None and not (30 <= v <= 150):
            raise ValueError("Cân nặng phải từ 30kg đến 150kg")
        return v

    @validator("coffee_cups_per_day")
    def validate_coffee(cls, v):
        if not (0 <= v <= 10):
            raise ValueError("Số cốc cà phê phải từ 0 đến 10")
        return v

    @validator("alcohol_units_per_day")
    def validate_alcohol(cls, v):
        if not (0 <= v <= 10):
            raise ValueError("Số đơn vị rượu bia phải từ 0 đến 10")
        return v


class WaterProfileCreate(WaterProfileBase):
    """Schema for creating water profile"""


class WaterProfileUpdate(WaterProfileBase):
    """Schema for updating water profile"""


class WaterCalculationBreakdown(BaseModel):
    """Breakdown of water calculation components"""

    base_ml: int
    activity_add: int
    job_add: int
    health_add: int
    veggie_add: int
    coffee_add: int
    alcohol_add: int


class WaterCalculationResponse(BaseModel):
    """Response schema for water calculation"""

    total_ml: int
    daily_goal_l: float
    daily_goal_cups: int
    breakdown: WaterCalculationBreakdown
    has_warnings: bool
    warning_message: Optional[str] = None
    calculated_at: datetime


class WaterProfileResponse(WaterProfileBase):
    """Response schema for water profile"""

    profile_complete: bool
    calculated_daily_goal_ml: Optional[int] = None
    formula_last_updated: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserSummaryResponse(BaseModel):
    """User summary for B5 Review screen"""

    gender_age: str  # "Nam - 28 tuổi"
    height_weight: str  # "168 cm - 60 kg"
    activity: str  # "Vừa phải"
    job: str  # "Văn phòng"

    class Config:
        from_attributes = True


# Enums for frontend display
class WaterProfileEnums(BaseModel):
    """Available enum values for frontend dropdowns"""

    genders: Dict[str, str] = {"male": "Nam", "female": "Nữ", "other": "Khác"}

    activity_levels: Dict[str, str] = {
        "sedentary": "Ít vận động",
        "light": "Nhẹ nhàng",
        "moderate": "Vừa phải",
        "active": "Năng động",
        "very_active": "Rất năng động",
    }

    job_types: Dict[str, str] = {
        "office": "Văn phòng",
        "mixed": "Hỗn hợp",
        "outdoor": "Ngoài trời",
        "manual": "Tay chân",
    }

    health_conditions: Dict[str, str] = {
        "none": "Không có",
        "diabetes": "Tiểu đường",
        "hypertension": "Cao huyết áp",
        "neurological": "Bệnh thần kinh",
        "heart": "Tim mạch",
        "pregnant": "Đang mang thai",
        "lactating": "Đang cho con bú",
        "gout": "Gout",
    }

    veggie_intakes: Dict[str, str] = {
        "low": "Ít (< 1 phần/ngày)",
        "medium": "Vừa (1-2 phần/ngày)",
        "high": "Nhiều (3+ phần/ngày)",
    }
