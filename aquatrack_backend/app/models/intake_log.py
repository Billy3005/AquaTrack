import uuid

from sqlalchemy import Boolean, Column, DateTime, Float, ForeignKey, Integer, String
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class IntakeLog(Base):
    """Model for individual water intake logs"""

    __tablename__ = "intake_logs"

    # Primary key
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)

    # Foreign key to user
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Intake details
    volume_ml = Column(Integer, nullable=False)  # Original volume
    liquid_type = Column(
        String, nullable=False, default="water"
    )  # water, tea, coffee, etc.
    hydration_factor = Column(Float, default=1.0)  # Multiplier based on liquid type
    effective_volume_ml = Column(
        Integer, nullable=False
    )  # volume_ml * hydration_factor

    # Gamification
    xp_earned = Column(Integer, default=0)
    bonus_xp = Column(Integer, default=0)  # Extra XP from achievements, streaks, etc.

    # Metadata
    logged_at = Column(DateTime(timezone=True), server_default=func.now())
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Optional tracking
    temperature = Column(String, nullable=True)  # "cold", "room", "warm", "hot"
    location = Column(String, nullable=True)  # "home", "work", "gym", etc.
    mood_before = Column(String, nullable=True)  # "tired", "energetic", etc.
    mood_after = Column(String, nullable=True)

    # Source tracking
    source = Column(
        String, default="manual"
    )  # "manual", "quick_log", "ai_suggestion", "smart_scan"
    device_info = Column(String, nullable=True)  # Device/platform info

    # Validation flags
    is_validated = Column(
        Boolean, default=True
    )  # For AI/scan logs that might need verification
    confidence_score = Column(Float, nullable=True)  # For ML-detected volumes (0.0-1.0)

    # Relationships
    user = relationship("User", back_populates="intake_logs")

    def __repr__(self):
        return (
            f"<IntakeLog(id={self.id}, user_id={self.user_id}, "
            f"volume_ml={self.volume_ml})>"
        )

    @property
    def local_time(self):
        """Get logged_at time in user's timezone"""
        # TODO: Implement timezone conversion based on user.timezone
        return self.logged_at
