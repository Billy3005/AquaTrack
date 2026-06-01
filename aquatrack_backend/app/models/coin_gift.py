import uuid
from datetime import datetime

from sqlalchemy import Column, DateTime, ForeignKey, Integer, String
from sqlalchemy.orm import relationship

from app.core.database import Base


class CoinGift(Base):
    """A coin gift ("tặng xu") sent from one friend to another.

    This table is the audit log + notification source, not the balance itself —
    the actual transfer mutates ``users.coins`` for both sides at send time (see
    ``services/gifts_service.py``). Kept queryable so the recipient gets an inbox
    notification and the per-day gifting cap can be enforced.
    """

    __tablename__ = "coin_gifts"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    sender_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    receiver_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    amount = Column(Integer, nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow, nullable=False, index=True)

    sender = relationship("User", foreign_keys=[sender_id])
    receiver = relationship("User", foreign_keys=[receiver_id])

    def __repr__(self):
        return (
            f"<CoinGift(id={self.id}, sender={self.sender_id}, "
            f"receiver={self.receiver_id}, amount={self.amount})>"
        )
