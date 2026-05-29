"""
Water Formula Service - Calculate daily water intake based on user profile
Implements the AquaTrack water calculation formula from aquatrack-water-formula.md
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional


class Gender(str, Enum):
    MALE = "male"
    FEMALE = "female"
    OTHER = "other"


class ActivityLevel(str, Enum):
    SEDENTARY = "sedentary"  # 0 ml/kg
    LIGHT = "light"  # 12 ml/kg
    MODERATE = "moderate"  # 14 ml/kg
    ACTIVE = "active"  # 16 ml/kg
    VERY_ACTIVE = "very_active"  # 19 ml/kg


class JobType(str, Enum):
    OFFICE = "office"  # 0 ml
    MIXED = "mixed"  # +150 ml
    OUTDOOR = "outdoor"  # +400 ml
    MANUAL = "manual"  # +500 ml


class HealthCondition(str, Enum):
    NONE = "none"  # 0 ml
    DIABETES = "diabetes"  # +200 ml
    HYPERTENSION = "hypertension"  # +150 ml
    NEUROLOGICAL = "neurological"  # 0 ml (warning)
    HEART = "heart"  # 0 ml (warning)
    PREGNANT = "pregnant"  # +500 ml
    LACTATING = "lactating"  # +700 ml
    GOUT = "gout"  # +300 ml


class VeggieIntake(str, Enum):
    LOW = "low"  # -100 ml (< 1 phần/ngày)
    MEDIUM = "medium"  # -250 ml (1-2 phần/ngày)
    HIGH = "high"  # -400 ml (3+ phần/ngày)


@dataclass
class UserWaterProfile:
    """User profile data for water calculation"""

    # B1 - Body
    gender: Gender
    age: int
    height: int  # cm
    weight: float  # kg

    # B2 - Lifestyle
    activity_level: ActivityLevel
    job_type: JobType

    # B3 - Health (can select multiple)
    health_conditions: List[HealthCondition]

    # B4 - Diet
    veggie_intake: VeggieIntake
    coffee_cups_per_day: int
    alcohol_units_per_day: int


@dataclass
class WaterCalculationResult:
    """Result of water calculation with breakdown"""

    total_ml: int
    daily_goal_l: float
    daily_goal_cups: int

    # Breakdown for transparency
    base_ml: int
    activity_add: int
    job_add: int
    health_add: int
    veggie_add: int
    coffee_add: int
    alcohol_add: int

    # Warnings for health conditions
    has_warnings: bool
    warning_message: Optional[str]


class WaterFormulaService:
    """Service to calculate daily water intake using AquaTrack formula"""

    # Activity level multipliers (ml per kg)
    ACTIVITY_MULTIPLIERS = {
        ActivityLevel.SEDENTARY: 0,
        ActivityLevel.LIGHT: 12,
        ActivityLevel.MODERATE: 14,
        ActivityLevel.ACTIVE: 16,
        ActivityLevel.VERY_ACTIVE: 19,
    }

    # Job type additions (ml)
    JOB_ADDITIONS = {
        JobType.OFFICE: 0,
        JobType.MIXED: 150,
        JobType.OUTDOOR: 400,
        JobType.MANUAL: 500,
    }

    # Health condition additions (ml)
    HEALTH_ADDITIONS = {
        HealthCondition.NONE: 0,
        HealthCondition.DIABETES: 200,
        HealthCondition.HYPERTENSION: 150,
        HealthCondition.NEUROLOGICAL: 0,
        HealthCondition.HEART: 0,
        HealthCondition.PREGNANT: 500,
        HealthCondition.LACTATING: 700,
        HealthCondition.GOUT: 300,
    }

    # Veggie intake adjustments (ml)
    VEGGIE_ADJUSTMENTS = {
        VeggieIntake.LOW: -100,
        VeggieIntake.MEDIUM: -250,
        VeggieIntake.HIGH: -400,
    }

    # Constants
    BASE_ML_PER_KG = 35
    FEMALE_MULTIPLIER = 0.95
    COFFEE_ML_PER_CUP = 120
    ALCOHOL_ML_PER_UNIT = 200
    MINIMUM_DAILY_ML = 1500
    ROUND_TO_ML = 50

    @classmethod
    def calculate_daily_water(cls, profile: UserWaterProfile) -> WaterCalculationResult:
        """Calculate daily water intake based on user profile"""

        # B1 - Base calculation (weight × 35 × gender factor)
        base_ml = profile.weight * cls.BASE_ML_PER_KG
        if profile.gender == Gender.FEMALE:
            base_ml *= cls.FEMALE_MULTIPLIER
        base_ml = int(base_ml)

        # B2 - Activity addition
        activity_add = int(
            profile.weight * cls.ACTIVITY_MULTIPLIERS[profile.activity_level]
        )

        # B2 - Job addition
        job_add = cls.JOB_ADDITIONS[profile.job_type]

        # B3 - Health conditions addition (sum of all selected)
        health_add = sum(
            cls.HEALTH_ADDITIONS[condition] for condition in profile.health_conditions
        )

        # B4 - Veggie adjustment (negative)
        veggie_add = cls.VEGGIE_ADJUSTMENTS[profile.veggie_intake]

        # B4 - Coffee addition
        coffee_add = profile.coffee_cups_per_day * cls.COFFEE_ML_PER_CUP

        # B4 - Alcohol addition
        alcohol_add = profile.alcohol_units_per_day * cls.ALCOHOL_ML_PER_UNIT

        # Total calculation
        total_ml = (
            base_ml
            + activity_add
            + job_add
            + health_add
            + veggie_add
            + coffee_add
            + alcohol_add
        )

        # Round to nearest 50ml
        total_ml = round(total_ml / cls.ROUND_TO_ML) * cls.ROUND_TO_ML

        # Apply minimum
        total_ml = max(total_ml, cls.MINIMUM_DAILY_ML)

        # Calculate display values
        daily_goal_l = round(total_ml / 1000, 3)
        daily_goal_cups = round(total_ml / 250)

        # Check for health warnings
        has_warnings = any(
            condition in [HealthCondition.NEUROLOGICAL, HealthCondition.HEART]
            for condition in profile.health_conditions
        )
        warning_message = None
        if has_warnings:
            warning_message = (
                "Thông tin này không thay thế lời khuyên y tế. "
                "Với bệnh thần kinh hoặc tim mạch, hãy hỏi bác sĩ "
                "về lượng nước phù hợp."
            )

        return WaterCalculationResult(
            total_ml=total_ml,
            daily_goal_l=daily_goal_l,
            daily_goal_cups=daily_goal_cups,
            base_ml=base_ml,
            activity_add=activity_add,
            job_add=job_add,
            health_add=health_add,
            veggie_add=veggie_add,
            coffee_add=coffee_add,
            alcohol_add=alcohol_add,
            has_warnings=has_warnings,
            warning_message=warning_message,
        )

    @classmethod
    def validate_profile(cls, profile: UserWaterProfile) -> Dict[str, str]:
        """Validate user profile data, return dict of field errors"""
        errors = {}

        # Age validation
        if not (0 < profile.age <= 120):
            errors["age"] = "Tuổi phải từ 1 đến 120"

        # Height validation
        if not (130 <= profile.height <= 210):
            errors["height"] = "Chiều cao phải từ 130cm đến 210cm"

        # Weight validation
        if not (30 <= profile.weight <= 150):
            errors["weight"] = "Cân nặng phải từ 30kg đến 150kg"

        # Coffee validation
        if not (0 <= profile.coffee_cups_per_day <= 10):
            errors["coffee_cups_per_day"] = "Số cốc cà phê phải từ 0 đến 10"

        # Alcohol validation
        if not (0 <= profile.alcohol_units_per_day <= 10):
            errors["alcohol_units_per_day"] = "Số đơn vị rượu bia phải từ 0 đến 10"

        return errors


def test_formula():
    """Test function to verify formula with demo data"""
    # Test case from formula doc: Nam, 28 tuổi, 168cm, 60kg, Vừa phải, Văn phòng,
    # Không bệnh, Rau vừa, 1 cà phê, 0 rượu → Expected: 2850ml

    profile = UserWaterProfile(
        gender=Gender.MALE,
        age=28,
        height=168,
        weight=60.0,
        activity_level=ActivityLevel.MODERATE,
        job_type=JobType.OFFICE,
        health_conditions=[HealthCondition.NONE],
        veggie_intake=VeggieIntake.MEDIUM,
        coffee_cups_per_day=1,
        alcohol_units_per_day=0,
    )

    result = WaterFormulaService.calculate_daily_water(profile)
    print(f"Expected: 2850ml, Got: {result.total_ml}ml")
    print(
        f"Breakdown: base={result.base_ml}, activity={result.activity_add}, "
        f"veggie={result.veggie_add}, coffee={result.coffee_add}"
    )

    return result


if __name__ == "__main__":
    test_formula()
