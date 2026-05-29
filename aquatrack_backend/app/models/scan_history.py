import uuid

from sqlalchemy import (Boolean, Column, DateTime, Float, ForeignKey, Integer,
                        String)
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func

from app.core.database import Base


class ScanHistory(Base):
    """Model for Smart Scan image processing history and validation"""

    __tablename__ = "scan_history"

    # Primary key
    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()), index=True)

    # Foreign key to user
    user_id = Column(String, ForeignKey("users.id"), nullable=False, index=True)

    # Image information
    image_path = Column(String, nullable=True)  # Path to stored image file

    # AI Detection Results
    container_type = Column(String, nullable=False)  # glass_small, bottle_500, etc.
    fill_level_percent = Column(Float, nullable=False)  # 0.0 - 1.0
    liquid_type = Column(String, nullable=False)  # water, tea, coffee, juice, smoothie
    confidence_score = Column(Float, nullable=False)  # 0.0 - 1.0 AI confidence

    # Volume Calculations
    estimated_volume_ml = Column(Integer, nullable=False)  # Raw volume estimate
    effective_volume_ml = Column(Integer, nullable=False)  # With hydration coefficient

    # Validation and Correction
    is_validated = Column(Boolean, default=False)  # User confirmed accuracy
    user_corrected_volume_ml = Column(
        Integer, nullable=True
    )  # User's manual correction
    validated_at = Column(DateTime(timezone=True), nullable=True)

    # Metadata
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    # Relationships
    user = relationship("User", back_populates="scan_history")

    def __repr__(self):
        return (
            f"<ScanHistory(id={self.id}, user_id={self.user_id}, "
            f"container={self.container_type}, volume={self.estimated_volume_ml}ml, "
            f"confidence={self.confidence_score:.2f})>"
        )

    @property
    def final_volume_ml(self):
        """Get the final volume - user correction if available, otherwise estimated"""
        return self.user_corrected_volume_ml or self.estimated_volume_ml

    @property
    def confidence_category(self):
        """Categorize confidence score for UI display"""
        if self.confidence_score >= 0.80:
            return "high"
        elif self.confidence_score >= 0.60:
            return "medium"
        else:
            return "low"
