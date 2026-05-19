import uuid
from datetime import datetime
from enum import Enum
from typing import Optional

from sqlalchemy import Column, DateTime, Enum as SQLEnum, ForeignKey, String, Text
from sqlalchemy.orm import relationship

from app.core.database import Base


class FriendRequestStatus(str, Enum):
    """Friend request status options"""

    PENDING = "pending"
    ACCEPTED = "accepted"
    DECLINED = "declined"
    CANCELLED = "cancelled"


class FriendRequest(Base):
    """Friend request model for social features"""

    __tablename__ = "friend_requests"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    sender_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    receiver_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Request details
    status = Column(
        SQLEnum(FriendRequestStatus),
        default=FriendRequestStatus.PENDING,
        nullable=False,
        index=True,
    )
    message = Column(Text, nullable=True)  # Optional message with friend request

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    responded_at = Column(DateTime, nullable=True)  # When request was accepted/declined

    # Relationships
    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

    def __repr__(self):
        return f"<FriendRequest(id={self.id}, sender_id={self.sender_id}, receiver_id={self.receiver_id}, status={self.status})>"

    @property
    def is_pending(self) -> bool:
        """Check if request is still pending"""
        return self.status == FriendRequestStatus.PENDING

    @property
    def is_resolved(self) -> bool:
        """Check if request has been resolved (accepted, declined, or cancelled)"""
        return self.status in [
            FriendRequestStatus.ACCEPTED,
            FriendRequestStatus.DECLINED,
            FriendRequestStatus.CANCELLED,
        ]

    def accept(self):
        """Mark request as accepted"""
        self.status = FriendRequestStatus.ACCEPTED
        self.responded_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def decline(self):
        """Mark request as declined"""
        self.status = FriendRequestStatus.DECLINED
        self.responded_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def cancel(self):
        """Mark request as cancelled (by sender)"""
        self.status = FriendRequestStatus.CANCELLED
        self.responded_at = datetime.utcnow()
        self.updated_at = datetime.utcnow()

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "id": self.id,
            "sender_id": self.sender_id,
            "receiver_id": self.receiver_id,
            "status": self.status.value,
            "message": self.message,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
            "responded_at": self.responded_at.isoformat() if self.responded_at else None,
        }