from datetime import datetime
from typing import Literal, Optional

from pydantic import BaseModel, Field

# Liquid types must stay in sync with Flutter AppConstants.hydrationCoeff keys
LiquidType = Literal["water", "tea", "coffee", "juice", "smoothie"]


class VisionEstimateResponse(BaseModel):
    """Vision estimation response (ADR-0005).

    Carries the physical volume only. The hydration coefficient is applied
    exactly once, at the log step — never here.
    """

    container_label: str = Field(
        ..., description="Display-only container description, e.g. 'Chai nhựa 650ml'"
    )
    container_capacity_ml: int = Field(
        ..., ge=50, le=5000, description="Estimated full capacity (continuous, ml)"
    )
    fill_level_percent: float = Field(
        ..., ge=0.0, le=1.0, description="Fill level as decimal (0.0-1.0)"
    )
    liquid_type: LiquidType = Field(..., description="Detected liquid type")
    confidence: float = Field(..., ge=0.0, le=1.0, description="AI confidence score")
    estimated_volume_ml: int = Field(
        ..., ge=0, le=5000, description="Physical volume: capacity x fill level"
    )

    scan_id: Optional[str] = Field(None, description="Scan history ID if saved")
    processing_time_ms: Optional[int] = Field(
        None, description="Processing time in milliseconds"
    )


class ScanHistoryCreate(BaseModel):
    """Schema for creating scan history record"""

    image_path: Optional[str] = Field(None, max_length=500)
    container_label: str = Field(..., max_length=100)
    container_capacity_ml: int = Field(..., ge=50, le=5000)
    fill_level_percent: float = Field(..., ge=0.0, le=1.0)
    liquid_type: LiquidType
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    estimated_volume_ml: int = Field(..., ge=0, le=5000)


class ScanHistoryUpdate(BaseModel):
    """Schema for updating scan history (user corrections)"""

    user_corrected_volume_ml: Optional[int] = Field(None, ge=1, le=5000)
    is_validated: bool = Field(True)


class ScanHistoryResponse(BaseModel):
    """Schema for scan history response"""

    id: str
    user_id: str
    image_path: Optional[str]
    container_label: str
    container_capacity_ml: int
    fill_level_percent: float
    liquid_type: str
    confidence_score: float
    estimated_volume_ml: int
    is_validated: bool
    user_corrected_volume_ml: Optional[int]
    validated_at: Optional[datetime]
    created_at: datetime

    # Computed properties
    final_volume_ml: int
    confidence_category: str

    class Config:
        from_attributes = True
