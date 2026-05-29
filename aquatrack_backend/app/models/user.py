import uuid

from sqlalchemy import JSON, Boolean, Column, DateTime, Float, Integer, String, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class User(Base):
    """User model for authentication and profile"""

    __tablename__ = "users"

    # Primary key
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)

    # Authentication fields
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)

    # Profile fields
    username = Column(String, nullable=False, default="Aqua Warrior")
    full_name = Column(String, nullable=True)
    avatar_id = Column(String, default="avatar_1")  # Matches Flutter avatar system

    # Preferences
    daily_goal_ml = Column(Integer, default=2000)
    notifications_enabled = Column(Boolean, default=True)
    theme_preference = Column(String, default="dark")
    language_preference = Column(String, default="vi")
    sound_enabled = Column(Boolean, default=True)

    # Water Formula Profile - B1: Body
    gender = Column(String, nullable=True)  # male/female/other
    age = Column(Integer, nullable=True)
    height = Column(Integer, nullable=True)  # cm
    weight = Column(Float, nullable=True)  # kg

    # Water Formula Profile - B2: Lifestyle
    activity_level = Column(
        String, nullable=True
    )  # sedentary/light/moderate/active/very_active
    job_type = Column(String, nullable=True)  # office/mixed/outdoor/manual

    # Water Formula Profile - B3: Health (JSON array for multiple selections)
    health_conditions = Column(
        JSON, default=list
    )  # ["none"] or ["diabetes", "hypertension"] etc

    # Water Formula Profile - B4: Diet
    veggie_intake = Column(String, nullable=True)  # low/medium/high
    coffee_cups_per_day = Column(Integer, default=0)
    alcohol_units_per_day = Column(Integer, default=0)

    # Calculated water goal (auto-calculated when profile complete)
    calculated_daily_goal_ml = Column(Integer, nullable=True)
    formula_last_updated = Column(DateTime(timezone=True), nullable=True)
    profile_complete = Column(Boolean, default=False)

    # Level system
    current_level = Column(Integer, default=1)
    total_xp = Column(Integer, default=0)
    current_streak = Column(Integer, default=0)
    longest_streak = Column(Integer, default=0)

    # Statistics
    total_logs_count = Column(Integer, default=0)
    total_volume_ml = Column(Integer, default=0)

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_login = Column(DateTime(timezone=True), nullable=True)

    # Push notification settings
    push_token = Column(Text, nullable=True)
    timezone = Column(String, default="Asia/Ho_Chi_Minh")

    # Social features
    status = Column(String, default="normal")  # normal/thirsty/stressed/offline
    is_online = Column(Boolean, default=False)

    # Relationships
    intake_logs = relationship(
        "IntakeLog", back_populates="user", cascade="all, delete-orphan"
    )
    daily_summaries = relationship(
        "DailySummary", back_populates="user", cascade="all, delete-orphan"
    )
    achievements = relationship(
        "Achievement", back_populates="user", cascade="all, delete-orphan"
    )
    scan_history = relationship(
        "ScanHistory", back_populates="user", cascade="all, delete-orphan"
    )

    # Social relationships
    friends = relationship(
        "Friend",
        foreign_keys="Friend.user_id",
        back_populates="user",
        cascade="all, delete-orphan",
    )
    leaderboard_entries = relationship(
        "LeaderboardEntry", back_populates="user", cascade="all, delete-orphan"
    )
    insights = relationship(
        "UserInsight", back_populates="user", cascade="all, delete-orphan"
    )

    def __repr__(self):
        return f"<User(id={self.id}, email={self.email}, username={self.username})>"
