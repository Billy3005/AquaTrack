import uuid

from sqlalchemy import (Boolean, Column, Date, DateTime, Float, ForeignKey,
                        Integer, String)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class DailySummary(Base):
    """Daily hydration summary for each user"""

    __tablename__ = "daily_summaries"

    # Primary key
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)

    # Foreign key to user
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Date for this summary
    date = Column(Date, nullable=False, index=True)

    # Daily hydration data
    daily_goal_ml = Column(Integer, nullable=False)  # Goal for this day
    total_volume_ml = Column(Integer, default=0)  # Raw intake volume
    total_effective_ml = Column(Integer, default=0)  # Hydration-adjusted volume
    log_count = Column(Integer, default=0)  # Number of logs this day

    # Progress metrics
    progress_percentage = Column(Float, default=0.0)  # effective_ml / goal_ml
    goal_achieved = Column(Boolean, default=False)
    achievement_time = Column(
        DateTime(timezone=True), nullable=True
    )  # When goal was reached

    # XP and gamification
    xp_earned = Column(Integer, default=0)
    bonus_xp = Column(Integer, default=0)  # Bonus for streaks, achievements, etc.
    streak_day = Column(Integer, default=0)  # What day of streak this is

    # Environmental context
    location = Column(String, default="Unknown")
    temperature_celsius = Column(Float, nullable=True)
    weather = Column(String, nullable=True)

    # Analytics data
    avg_gap_hours = Column(Float, nullable=True)  # Average time between logs
    most_active_hour = Column(Integer, nullable=True)  # Hour with most logs (0-23)
    consistency_score = Column(Float, default=0.0)  # How evenly distributed logs are

    # Liquid type breakdown (stored as percentages)
    water_percentage = Column(Float, default=100.0)
    tea_percentage = Column(Float, default=0.0)
    coffee_percentage = Column(Float, default=0.0)
    other_percentage = Column(Float, default=0.0)

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="daily_summaries")

    def __repr__(self):
        return (
            f"<DailySummary(user_id={self.user_id}, date={self.date}, "
            f"progress={self.progress_percentage:.1f}%)>"
        )

    @property
    def is_today(self):
        """Check if this summary is for today"""
        from datetime import date

        return self.date == date.today()

    @property
    def progress_ratio(self):
        """Get progress as ratio (0.0-1.0)"""
        return min(self.progress_percentage / 100.0, 1.0)

    def calculate_progress(self):
        """Calculate and update progress percentage"""
        if self.daily_goal_ml > 0:
            self.progress_percentage = (
                self.total_effective_ml / self.daily_goal_ml
            ) * 100.0
            self.goal_achieved = self.progress_percentage >= 100.0
        return self.progress_percentage
