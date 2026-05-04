from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, validator


class IntakeLogCreate(BaseModel):
    """Schema for creating intake log"""

    volume_ml: int = Field(..., ge=1, le=2000)
    liquid_type: str = Field("water", max_length=20)
    temperature: Optional[str] = Field(None, pattern="^(cold|room|warm|hot)$")
    location: Optional[str] = Field(None, max_length=50)
    mood_before: Optional[str] = Field(None, max_length=20)
    source: str = Field("manual", max_length=20)

    @validator("liquid_type")
    def validate_liquid_type(cls, v):
        allowed_types = ["water", "tea", "coffee", "juice", "sports_drink", "other"]
        if v not in allowed_types:
            raise ValueError(f'Liquid type must be one of: {", ".join(allowed_types)}')
        return v


class IntakeLogUpdate(BaseModel):
    """Schema for updating intake log"""

    volume_ml: Optional[int] = Field(None, ge=1, le=2000)
    liquid_type: Optional[str] = Field(None, max_length=20)
    temperature: Optional[str] = Field(None, pattern="^(cold|room|warm|hot)$")
    location: Optional[str] = Field(None, max_length=50)
    mood_after: Optional[str] = Field(None, max_length=20)


class IntakeLogResponse(BaseModel):
    """Schema for intake log response"""

    id: str
    user_id: str
    volume_ml: int
    liquid_type: str
    hydration_factor: float
    effective_volume_ml: int
    xp_earned: int
    bonus_xp: int
    logged_at: datetime
    created_at: datetime
    temperature: Optional[str]
    location: Optional[str]
    mood_before: Optional[str]
    mood_after: Optional[str]
    source: str
    device_info: Optional[str]
    is_validated: bool
    confidence_score: Optional[float]

    class Config:
        from_attributes = True
