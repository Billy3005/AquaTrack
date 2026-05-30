import uuid

from sqlalchemy import (Column, DateTime, ForeignKey, Integer, String,
                        UniqueConstraint)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class QuestClaim(Base):
    """Records a single reward claim for a quest within a reset period.

    Progress itself is derived on read from source tables; this table only
    persists the fact that a reward was collected. The unique constraint on
    (user_id, quest_id, period_key) enforces one claim per quest per period
    and makes resets implicit (a new period_key has no claim).
    """

    __tablename__ = "quest_claims"
    __table_args__ = (
        UniqueConstraint(
            "user_id", "quest_id", "period_key", name="uq_quest_claim_period"
        ),
    )

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Quest identifier from the registry, e.g. "smart_scan", "daily_bonus".
    quest_id = Column(String, nullable=False, index=True)
    # Local-time period bucket: "2026-05-30" (daily) or "2026-W22" (weekly).
    period_key = Column(String, nullable=False, index=True)

    # Reward actually granted at claim time (snapshot for audit / chest randomness).
    reward_xp = Column(Integer, default=0)
    reward_coin = Column(Integer, default=0)

    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="quest_claims")

    def __repr__(self):
        return (
            f"<QuestClaim(user_id={self.user_id}, quest_id={self.quest_id}, "
            f"period={self.period_key})>"
        )


class ReminderLog(Base):
    """Lightweight log of hydration reminders sent to friends.

    Exists only so the 'Hội Bạn Cùng Uống' quest can count reminders per day;
    the legacy reminder flow does not persist them in a queryable form.
    """

    __tablename__ = "reminder_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    friend_id = Column(String, nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    user = relationship("User", back_populates="reminder_logs")

    def __repr__(self):
        return f"<ReminderLog(user_id={self.user_id}, friend_id={self.friend_id})>"
