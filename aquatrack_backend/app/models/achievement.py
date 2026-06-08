import enum
import uuid

from sqlalchemy import Boolean, Column, DateTime
from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class AchievementType(enum.Enum):
    """Types of achievements"""

    STREAK = "streak"  # Based on consecutive days
    TOTAL_VOLUME = "total_volume"  # Based on total water consumed
    LEVEL = "level"  # Based on reaching certain level
    DAILY_GOAL = "daily_goal"  # Based on achieving daily goals
    FREQUENCY = "frequency"  # Based on number of logs


class AchievementRarity(enum.Enum):
    """Achievement rarity levels"""

    COMMON = "common"
    RARE = "rare"
    EPIC = "epic"
    LEGENDARY = "legendary"


class Achievement(Base):
    """Model for user achievements and milestones"""

    __tablename__ = "achievements"

    # Primary key
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)

    # Foreign key to user
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Achievement definition
    achievement_id = Column(
        String, nullable=False, index=True
    )  # e.g., "first_week_streak"
    title = Column(String, nullable=False)
    description = Column(Text, nullable=False)
    icon = Column(String, nullable=False)  # Icon identifier for Flutter

    # Achievement mechanics
    type = Column(SQLEnum(AchievementType), nullable=False)
    rarity = Column(SQLEnum(AchievementRarity), default=AchievementRarity.COMMON)
    required_value = Column(Integer, nullable=False)  # Target value to achieve
    current_value = Column(Integer, default=0)  # Current progress

    # Rewards
    xp_reward = Column(Integer, default=0)
    unlock_avatar_id = Column(
        String, nullable=True
    )  # Avatar unlocked by this achievement
    unlock_badge_id = Column(
        String, nullable=True
    )  # Badge unlocked by this achievement

    # Status
    is_unlocked = Column(Boolean, default=False)
    is_claimed = Column(Boolean, default=False)  # Whether user has claimed rewards
    unlocked_at = Column(DateTime(timezone=True), nullable=True)
    claimed_at = Column(DateTime(timezone=True), nullable=True)

    # Progress tracking
    progress_percentage = Column(Integer, default=0)  # 0-100

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    # Relationships
    user = relationship("User", back_populates="achievements")

    def __repr__(self):
        return (
            f"<Achievement(user_id={self.user_id}, title={self.title}, "
            f"unlocked={self.is_unlocked})>"
        )

    def update_progress(self, new_value: int):
        """Update achievement progress"""
        self.current_value = new_value
        self.progress_percentage = min(
            int((new_value / self.required_value) * 100), 100
        )

        if new_value >= self.required_value and not self.is_unlocked:
            self.unlock()

    def unlock(self):
        """Unlock the achievement"""
        self.is_unlocked = True
        self.unlocked_at = func.now()
        self.progress_percentage = 100

    def claim_rewards(self):
        """Mark achievement rewards as claimed"""
        if self.is_unlocked and not self.is_claimed:
            self.is_claimed = True
            self.claimed_at = func.now()
            return True
        return False

    @classmethod
    def create_default_achievements(cls, user_id: str):
        """Create default set of achievements for a new user"""
        default_achievements = [
            # Streak achievements
            {
                "achievement_id": "first_day",
                "title": "Bước đầu tiên",
                "description": "Hoàn thành ngày đầu tiên tracking nước",
                "icon": "first_day",
                "type": AchievementType.STREAK,
                "rarity": AchievementRarity.COMMON,
                "required_value": 1,
                "xp_reward": 50,
            },
            {
                "achievement_id": "week_warrior",
                "title": "Chiến binh tuần",
                "description": "Đạt mục tiêu 7 ngày liên tiếp",
                "icon": "week_warrior",
                "type": AchievementType.STREAK,
                "rarity": AchievementRarity.RARE,
                "required_value": 7,
                "xp_reward": 200,
                "unlock_avatar_id": "avatar_2",
            },
            {
                "achievement_id": "month_master",
                "title": "Bậc thầy tháng",
                "description": "Đạt mục tiêu 30 ngày liên tiếp",
                "icon": "month_master",
                "type": AchievementType.STREAK,
                "rarity": AchievementRarity.EPIC,
                "required_value": 30,
                "xp_reward": 1000,
                "unlock_avatar_id": "avatar_5",
            },
            # Volume achievements
            {
                "achievement_id": "first_liter",
                "title": "Lít đầu tiên",
                "description": "Uống tổng cộng 1 lít nước",
                "icon": "first_liter",
                "type": AchievementType.TOTAL_VOLUME,
                "rarity": AchievementRarity.COMMON,
                "required_value": 1000,
                "xp_reward": 25,
            },
            {
                "achievement_id": "hydration_hero",
                "title": "Anh hùng hydration",
                "description": "Uống tổng cộng 100 lít nước",
                "icon": "hydration_hero",
                "type": AchievementType.TOTAL_VOLUME,
                "rarity": AchievementRarity.LEGENDARY,
                "required_value": 100000,
                "xp_reward": 5000,
                "unlock_avatar_id": "avatar_8",
            },
            # Level achievements
            {
                "achievement_id": "level_5",
                "title": "Trình độ 5",
                "description": "Đạt level 5",
                "icon": "level_5",
                "type": AchievementType.LEVEL,
                "rarity": AchievementRarity.COMMON,
                "required_value": 5,
                "xp_reward": 100,
                "unlock_avatar_id": "avatar_3",
            },
            {
                "achievement_id": "level_20",
                "title": "Chuyên gia",
                "description": "Đạt level 20",
                "icon": "level_20",
                "type": AchievementType.LEVEL,
                "rarity": AchievementRarity.EPIC,
                "required_value": 20,
                "xp_reward": 2000,
                "unlock_avatar_id": "avatar_7",
            },
            # Frequency achievements
            {
                "achievement_id": "frequent_drinker",
                "title": "Người uống chăm chỉ",
                "description": "Log nước 100 lần",
                "icon": "frequent_drinker",
                "type": AchievementType.FREQUENCY,
                "rarity": AchievementRarity.RARE,
                "required_value": 100,
                "xp_reward": 300,
                "unlock_avatar_id": "avatar_4",
            },
        ]

        achievements = []
        for data in default_achievements:
            achievement = cls(user_id=user_id, **data)
            achievements.append(achievement)

        return achievements


class AchievementClaim(Base):
    """Records that a user has Claimed a milestone Achievement (once, for life).

    Mirrors QuestClaim but without a period_key: achievements never reset, so the
    unique constraint is simply (user_id, achievement_id). Achievement *progress*
    is derived on read from source tables (see achievement_service); this table
    persists only the fact that the Milestone XP was collected. See
    docs/adr/0003-levels-and-achievements.md.
    """

    __tablename__ = "achievement_claims"
    __table_args__ = (
        UniqueConstraint("user_id", "achievement_id", name="uq_achievement_claim"),
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Achievement identifier from the registry, e.g. "scan_first", "streak_7".
    achievement_id = Column(String, nullable=False, index=True)

    # Milestone XP actually granted at claim time (snapshot for audit).
    reward_xp = Column(Integer, default=0)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="achievement_claims")

    def __repr__(self):
        return (
            f"<AchievementClaim(user_id={self.user_id}, "
            f"achievement_id={self.achievement_id})>"
        )
