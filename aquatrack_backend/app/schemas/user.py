from datetime import datetime
from typing import Optional

from pydantic import BaseModel, EmailStr, Field, validator


class UserLogin(BaseModel):
    """Schema for user login request"""

    email: EmailStr
    password: str = Field(..., min_length=6)


class UserCreate(BaseModel):
    """Schema for user registration request"""

    email: EmailStr
    password: str = Field(..., min_length=6, max_length=100)
    username: Optional[str] = Field(None, max_length=50)
    full_name: Optional[str] = Field(None, max_length=100)
    daily_goal_ml: Optional[int] = Field(2000, ge=1000, le=5000, description="Daily hydration goal in ml")

    @validator("username")
    def username_alphanumeric(cls, v):
        if v is not None and not v.replace("_", "").replace("-", "").isalnum():
            raise ValueError("Username must be alphanumeric with optional _ or -")
        return v


class UserUpdate(BaseModel):
    """Schema for updating user profile"""

    username: Optional[str] = Field(None, max_length=50)
    full_name: Optional[str] = Field(None, max_length=100)
    avatar_id: Optional[str] = Field(None, max_length=20)
    daily_goal_ml: Optional[int] = Field(None, ge=1000, le=5000)
    notifications_enabled: Optional[bool] = None
    theme_preference: Optional[str] = Field(None, pattern="^(light|dark|auto)$")
    language_preference: Optional[str] = Field(None, pattern="^(vi|en)$")
    sound_enabled: Optional[bool] = None
    timezone: Optional[str] = Field(None, max_length=50)

    # Onboarding / Body info fields
    gender: Optional[str] = Field(None, pattern="^(male|female|other)$")
    age: Optional[int] = Field(None, ge=10, le=100)
    height: Optional[int] = Field(None, ge=130, le=210, description="Height in cm")
    weight: Optional[float] = Field(None, ge=30, le=150, description="Weight in kg")

    # Lifestyle fields
    activity_level: Optional[str] = Field(None, pattern="^(sedentary|light|moderate|active|athlete)$")
    job_type: Optional[str] = Field(None, pattern="^(office|mixed|field|manual|sport)$")

    # Health conditions (JSON array)
    health_conditions: Optional[list] = Field(None, description="List of health conditions")

    # Diet fields
    veggie_intake: Optional[str] = Field(None, pattern="^(low|mid|high)$")
    coffee_cups_per_day: Optional[int] = Field(None, ge=0, le=10)
    alcohol_units_per_day: Optional[int] = Field(None, ge=0, le=10)

    @validator("username")
    def username_alphanumeric(cls, v):
        if v is not None and not v.replace("_", "").replace("-", "").isalnum():
            raise ValueError("Username must be alphanumeric with optional _ or -")
        return v


class UserResponse(BaseModel):
    """Schema for user data response"""

    id: str
    email: EmailStr
    username: str
    full_name: Optional[str]
    avatar_id: str
    is_active: bool
    is_verified: bool

    # Preferences
    daily_goal_ml: int
    notifications_enabled: bool
    theme_preference: str
    language_preference: str
    sound_enabled: bool
    timezone: str

    # Body info / Onboarding data
    gender: Optional[str]
    age: Optional[int]
    height: Optional[int]
    weight: Optional[float]
    activity_level: Optional[str]
    job_type: Optional[str]
    health_conditions: Optional[list]
    veggie_intake: Optional[str]
    coffee_cups_per_day: Optional[int]
    alcohol_units_per_day: Optional[int]

    # Formula calculation
    calculated_daily_goal_ml: Optional[int]
    profile_complete: bool

    # Level system
    current_level: int
    total_xp: int
    current_streak: int
    longest_streak: int

    # Statistics
    total_logs_count: int
    total_volume_ml: int

    # Metadata
    created_at: datetime
    last_login: Optional[datetime]

    class Config:
        from_attributes = True


class UserStats(BaseModel):
    """Schema for user statistics summary"""

    current_level: int
    total_xp: int
    current_streak: int
    longest_streak: int
    total_logs_count: int
    total_volume_ml: int
    total_volume_liters: float

    @validator("total_volume_liters", pre=False, always=True)
    def calculate_liters(cls, v, values):
        if "total_volume_ml" in values:
            return round(values["total_volume_ml"] / 1000.0, 2)
        return 0.0

    class Config:
        from_attributes = True
