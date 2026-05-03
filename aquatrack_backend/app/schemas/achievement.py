from datetime import datetime
from typing import Optional

from pydantic import BaseModel

from app.models.achievement import AchievementRarity, AchievementType


class AchievementResponse(BaseModel):
    """Schema for achievement response"""

    id: str
    user_id: str
    achievement_id: str
    title: str
    description: str
    icon: str
    type: AchievementType
    rarity: AchievementRarity
    required_value: int
    current_value: int
    xp_reward: int
    unlock_avatar_id: Optional[str]
    unlock_badge_id: Optional[str]
    is_unlocked: bool
    is_claimed: bool
    unlocked_at: Optional[datetime]
    claimed_at: Optional[datetime]
    progress_percentage: int
    created_at: datetime

    class Config:
        from_attributes = True
        use_enum_values = True
