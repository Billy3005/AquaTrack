import uuid
from datetime import datetime
from enum import Enum

from sqlalchemy import Column, DateTime
from sqlalchemy import Enum as SQLEnum
from sqlalchemy import ForeignKey, Integer, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class ChallengeStatus(str, Enum):
    """Lifecycle of a friend hydration race ("cuộc đua")."""

    PENDING = "pending"  # invite sent, waiting for opponent to accept
    ACTIVE = "active"  # accepted, race in progress
    COMPLETED = "completed"  # race window has ended
    DECLINED = "declined"  # opponent declined the invite


class Challenge(Base):
    """A head-to-head hydration race between two friends.

    Only the agreement and its window are stored here; each side's score is
    derived on read from ``daily_summaries`` over [started_at, ends_at] — same
    derived-on-read approach as the friends/leaderboard views (ADR 0003).
    """

    __tablename__ = "challenges"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    challenger_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    opponent_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    status = Column(
        SQLEnum(ChallengeStatus),
        default=ChallengeStatus.PENDING,
        nullable=False,
        index=True,
    )
    duration_days = Column(Integer, default=7, nullable=False)
    message = Column(Text, nullable=True)

    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    started_at = Column(DateTime, nullable=True)  # set when accepted
    ends_at = Column(DateTime, nullable=True)  # started_at + duration_days
    responded_at = Column(DateTime, nullable=True)

    challenger = relationship("User", foreign_keys=[challenger_id])
    opponent = relationship("User", foreign_keys=[opponent_id])

    def __repr__(self):
        return (
            f"<Challenge(id={self.id}, challenger={self.challenger_id}, "
            f"opponent={self.opponent_id}, status={self.status})>"
        )
