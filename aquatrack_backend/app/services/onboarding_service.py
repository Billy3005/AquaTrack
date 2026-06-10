from datetime import datetime
from typing import Any, Dict


class OnboardingService:
    """Service để tính toán water goal từ thông tin body của user"""

    @staticmethod
    def calculate_daily_goal(
        gender: str,
        age: int,
        height: int,
        weight: float,
        activity_level: str,
        job_type: str,
        health_conditions: list,
        veggie_intake: str,
        coffee_cups_per_day: int,
        alcohol_units_per_day: int,
    ) -> int:
        """
        Tính toán daily goal (ml) dựa trên thông tin body.
        Logic giống hệt với Flutter BodyInfoScreen.calculateGoal()
        """
        # Base calculation: 35ml × weight
        goal = weight * 35

        # Activity multiplier
        activity_muls = {
            "sedentary": 1.0,
            "light": 1.15,
            "moderate": 1.3,
            "active": 1.45,
            "athlete": 1.6,
        }
        goal *= activity_muls.get(activity_level, 1.3)

        # Work multiplier
        work_muls = {
            "office": 1.0,
            "mixed": 1.05,
            "field": 1.2,
            "manual": 1.25,
            "sport": 1.35,
        }
        goal *= work_muls.get(job_type, 1.0)

        # Vegetable adjustment
        veg_muls = {"low": 1.05, "mid": 1.0, "high": 0.95}
        goal *= veg_muls.get(veggie_intake, 1.0)

        # Coffee and alcohol additions
        goal += coffee_cups_per_day * 120  # 120ml per coffee cup
        goal += alcohol_units_per_day * 200  # 200ml per alcohol unit

        # Health adjustments
        if "pregnant" in health_conditions:
            goal += 300
        if "lactating" in health_conditions:
            goal += 700
        if "kidney" in health_conditions:
            goal = min(goal, 1800)  # Clamp to max 1800 for kidney issues

        # Round to nearest 50
        return int(((goal / 50) + 0.5) * 50)

    @staticmethod
    def validate_onboarding_data(data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Validate và clean onboarding data trước khi save
        """
        # Ensure health_conditions is a list
        if "health_conditions" in data and data["health_conditions"]:
            if isinstance(data["health_conditions"], str):
                data["health_conditions"] = [data["health_conditions"]]
        else:
            data["health_conditions"] = ["none"]

        # Set defaults for missing fields
        defaults = {
            "gender": "male",
            "age": 28,
            "height": 168,
            "weight": 60.0,
            "activity_level": "moderate",
            "job_type": "office",
            "veggie_intake": "mid",
            "coffee_cups_per_day": 1,
            "alcohol_units_per_day": 0,
        }

        for key, default_value in defaults.items():
            if key not in data or data[key] is None:
                data[key] = default_value

        return data

    @staticmethod
    def update_user_with_onboarding(user, onboarding_data: Dict[str, Any]):
        """
        Cập nhật user object với onboarding data và tự động tính daily goal
        """
        # Validate và clean data
        clean_data = OnboardingService.validate_onboarding_data(onboarding_data)

        # Update user với body info
        for key, value in clean_data.items():
            if hasattr(user, key):
                setattr(user, key, value)

        # Tính toán daily goal
        calculated_goal = OnboardingService.calculate_daily_goal(
            gender=clean_data["gender"],
            age=clean_data["age"],
            height=clean_data["height"],
            weight=clean_data["weight"],
            activity_level=clean_data["activity_level"],
            job_type=clean_data["job_type"],
            health_conditions=clean_data["health_conditions"],
            veggie_intake=clean_data["veggie_intake"],
            coffee_cups_per_day=clean_data["coffee_cups_per_day"],
            alcohol_units_per_day=clean_data["alcohol_units_per_day"],
        )

        # Update user với calculated goal
        user.calculated_daily_goal_ml = calculated_goal
        user.daily_goal_ml = calculated_goal  # Set as current goal
        user.profile_complete = True
        user.formula_last_updated = datetime.utcnow()

        return user
