import uuid

from sqlalchemy import Column, DateTime, ForeignKey, String, Text
from sqlalchemy.sql import func

from app.core.database import Base


class AuditLog(Base):
    """Append-only record of every sensitive Admin Console action.

    Written inside the same transaction as the action itself, so an action can
    never land without its log row. Rows are never updated — a correction is a
    new row, which is what makes the log admissible when a user disputes a lock
    or a manual XP grant.
    """

    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)

    # Who performed it. `actor_id` is FK-clean, but name/role are denormalised
    # on purpose: the log must still read correctly after a staff member is
    # renamed, demoted, or removed.
    actor_id = Column(String, ForeignKey("users.id"), nullable=True, index=True)
    actor_name = Column(String, nullable=False, default="Hệ thống")
    actor_role = Column(String, nullable=False, default="system")

    # What happened. `action` is a stable machine key (user.lock, user.grant…);
    # `action_label` is the Vietnamese phrase shown in the console.
    action = Column(String, nullable=False, index=True)
    action_label = Column(String, nullable=False, default="")
    tone = Column(String, nullable=False, default="slate")  # pill colour in UI

    # What it was performed on.
    target_type = Column(String, nullable=False, default="user")
    target_id = Column(String, nullable=True, index=True)
    target_label = Column(String, nullable=False, default="")

    # Why — required by the console for every destructive action.
    reason = Column(Text, nullable=False, default="")

    # Structured before/after payload (coins granted, ml deleted, …).
    meta = Column(Text, nullable=True)

    ip_address = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), index=True)

    def __repr__(self):
        return (
            f"<AuditLog(action={self.action}, actor={self.actor_name}, "
            f"target={self.target_label})>"
        )
