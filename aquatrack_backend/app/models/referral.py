import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String, UniqueConstraint
from sqlalchemy.sql import func

from app.core.database import Base


class Referral(Base):
    """A one-directional invite of a brand-new user via a Referral Code (ADR-0007).

    Created (pending) when an invited user signs up with a referrer's code.
    `validated_at` is stamped on the referred user's first water log; only
    validated referrals grant rewards or count toward the Ambassador Quest.
    One referral per referred user (a new account can be referred at most once).
    """

    __tablename__ = "referrals"
    __table_args__ = (UniqueConstraint("referred_id", name="uq_referral_referred"),)

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)
    referrer_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)
    referred_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now())
    # Stamped at the referred user's first water log. NULL = pending.
    validated_at = Column(DateTime(timezone=True), nullable=True, index=True)

    def __repr__(self):
        state = "validated" if self.validated_at else "pending"
        return (
            f"<Referral(referrer={self.referrer_id}, referred={self.referred_id}, "
            f"{state})>"
        )
