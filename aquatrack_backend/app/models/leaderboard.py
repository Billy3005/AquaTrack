import uuid
from datetime import date, datetime
from typing import Optional

from sqlalchemy import Column, Date, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class LeaderboardEntry(Base):
    """Weekly leaderboard entry for hydration tracking"""

    __tablename__ = "leaderboard_entries"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Week tracking
    week_start_date = Column(Date, nullable=False, index=True)  # Monday of the week
    week_year = Column(Integer, nullable=False, index=True)  # Year for easier querying

    # Hydration metrics
    total_volume_ml = Column(Integer, default=0, nullable=False)
    goal_achievement_days = Column(
        Integer, default=0, nullable=False
    )  # Days goal was met
    streak_days = Column(
        Integer, default=0, nullable=False
    )  # Current streak in that week
    average_daily_ml = Column(Integer, default=0, nullable=False)  # Average per day

    # Ranking
    rank_position = Column(Integer, nullable=True, index=True)  # 1-based ranking
    total_participants = Column(Integer, default=0, nullable=False)

    # XP and achievements in that week
    xp_earned = Column(Integer, default=0, nullable=False)
    achievements_unlocked = Column(Integer, default=0, nullable=False)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    calculated_at = Column(DateTime, nullable=True)  # When ranking was last calculated

    # Relationships
    user = relationship("User", back_populates="leaderboard_entries")

    def __repr__(self):
        return f"<LeaderboardEntry(id={self.id}, user_id={self.user_id}, week={self.week_start_date}, rank={self.rank_position})>"

    @property
    def is_current_week(self) -> bool:
        """Check if this entry is for the current week"""
        from datetime import date, timedelta

        today = date.today()
        # Find Monday of current week
        current_week_start = today - timedelta(days=today.weekday())
        return self.week_start_date == current_week_start

    @property
    def goal_achievement_percentage(self) -> float:
        """Calculate goal achievement percentage for the week"""
        return (
            (self.goal_achievement_days / 7) * 100
            if self.goal_achievement_days > 0
            else 0.0
        )

    @property
    def rank_suffix(self) -> str:
        """Get rank with proper suffix (1st, 2nd, 3rd, etc.)"""
        if not self.rank_position:
            return "Unranked"

        if self.rank_position == 1:
            return "1st"
        elif self.rank_position == 2:
            return "2nd"
        elif self.rank_position == 3:
            return "3rd"
        else:
            return f"{self.rank_position}th"

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "week_start_date": (
                self.week_start_date.isoformat() if self.week_start_date else None
            ),
            "week_year": self.week_year,
            "total_volume_ml": self.total_volume_ml,
            "goal_achievement_days": self.goal_achievement_days,
            "streak_days": self.streak_days,
            "average_daily_ml": self.average_daily_ml,
            "rank_position": self.rank_position,
            "total_participants": self.total_participants,
            "xp_earned": self.xp_earned,
            "achievements_unlocked": self.achievements_unlocked,
            "goal_achievement_percentage": self.goal_achievement_percentage,
            "rank_suffix": self.rank_suffix,
            "is_current_week": self.is_current_week,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "calculated_at": (
                self.calculated_at.isoformat() if self.calculated_at else None
            ),
        }
