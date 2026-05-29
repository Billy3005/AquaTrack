import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import Boolean, Column, DateTime, ForeignKey, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class Friend(Base):
    """Friend relationship model for social features"""

    __tablename__ = "friends"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    friend_user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Friendship status tracking
    is_active = Column(Boolean, default=True, nullable=False)
    is_blocked = Column(Boolean, default=False, nullable=False)

    # Timestamps
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False)
    updated_at = Column(DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    # Relationships
    user = relationship("User", foreign_keys=[user_id], back_populates="friends")
    friend_user = relationship("User", foreign_keys=[friend_user_id])

    def __repr__(self):
        return f"<Friend(id={self.id}, user_id={self.user_id}, friend_user_id={self.friend_user_id})>"

    @property
    def is_mutual(self) -> bool:
        """Check if friendship is mutual (both users are friends with each other)"""
        # This will be implemented in the service layer with database queries
        return True

    def to_dict(self):
        """Convert to dictionary for API responses"""
        return {
            "id": self.id,
            "user_id": self.user_id,
            "friend_user_id": self.friend_user_id,
            "is_active": self.is_active,
            "is_blocked": self.is_blocked,
            "created_at": self.created_at.isoformat() if self.created_at else None,
            "updated_at": self.updated_at.isoformat() if self.updated_at else None,
        }
