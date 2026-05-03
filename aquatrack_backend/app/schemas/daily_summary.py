from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel


class DailySummaryResponse(BaseModel):
    """Schema for daily summary response"""

    id: str
    user_id: str
    date: date
    daily_goal_ml: int
    total_volume_ml: int
    total_effective_ml: int
    log_count: int
    progress_percentage: float
    goal_achieved: bool
    achievement_time: Optional[datetime]
    xp_earned: int
    bonus_xp: int
    streak_day: int
    location: str
    temperature_celsius: Optional[float]
    weather: Optional[str]
    avg_gap_hours: Optional[float]
    most_active_hour: Optional[int]
    consistency_score: float
    water_percentage: float
    tea_percentage: float
    coffee_percentage: float
    other_percentage: float
    created_at: datetime
    updated_at: Optional[datetime]

    class Config:
        from_attributes = True
