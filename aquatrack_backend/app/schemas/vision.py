from datetime import datetime
from typing import Optional

from pydantic import BaseModel, Field, validator


class VisionEstimateRequest(BaseModel):
    """Schema for Smart Scan vision estimation request"""

    # Base64 encoded image data or file upload will be handled by FastAPI
    # This schema is for additional parameters if needed
    confidence_threshold: Optional[float] = Field(0.6, ge=0.0, le=1.0)
    save_to_history: bool = Field(True)


class VisionEstimateResponse(BaseModel):
    """Schema for vision estimation response - matches Flutter VisionResult format"""

    # AI Detection Results - exact field names expected by Flutter
    container_class: str = Field(..., description="Container type classification")
    fill_level_percent: float = Field(..., ge=0.0, le=1.0, description="Fill level as decimal (0.0-1.0)")
    liquid_type: str = Field(..., description="Detected liquid type")
    confidence: float = Field(..., ge=0.0, le=1.0, description="AI confidence score")

    # Volume Calculations
    estimated_volume_ml: int = Field(..., ge=1, le=5000, description="Raw volume estimate in ml")
    effective_volume_ml: int = Field(..., ge=1, le=5000, description="Hydration-adjusted volume in ml")

    # Optional metadata
    scan_id: Optional[str] = Field(None, description="Scan history ID if saved")
    processing_time_ms: Optional[int] = Field(None, description="Processing time in milliseconds")

    @validator("container_class")
    def validate_container_class(cls, v):
        allowed_containers = [
            "glass_small", "glass_large", "cup_plastic",
            "bottle_500", "bottle_750", "bottle_1000", "bottle_1500",
            "mug", "can_330", "other"
        ]
        if v not in allowed_containers:
            raise ValueError(f'Container class must be one of: {", ".join(allowed_containers)}')
        return v

    @validator("liquid_type")
    def validate_liquid_type(cls, v):
        allowed_liquids = ["water", "tea", "coffee", "juice", "smoothie"]
        if v not in allowed_liquids:
            raise ValueError(f'Liquid type must be one of: {", ".join(allowed_liquids)}')
        return v


class ScanHistoryCreate(BaseModel):
    """Schema for creating scan history record"""

    image_path: Optional[str] = Field(None, max_length=500)
    container_type: str = Field(..., max_length=50)
    fill_level_percent: float = Field(..., ge=0.0, le=1.0)
    liquid_type: str = Field(..., max_length=50)
    confidence_score: float = Field(..., ge=0.0, le=1.0)
    estimated_volume_ml: int = Field(..., ge=1, le=5000)
    effective_volume_ml: int = Field(..., ge=1, le=5000)

    @validator("container_type")
    def validate_container_type(cls, v):
        allowed_containers = [
            "glass_small", "glass_large", "cup_plastic",
            "bottle_500", "bottle_750", "bottle_1000", "bottle_1500",
            "mug", "can_330", "other"
        ]
        if v not in allowed_containers:
            raise ValueError(f'Container type must be one of: {", ".join(allowed_containers)}')
        return v

    @validator("liquid_type")
    def validate_liquid_type(cls, v):
        allowed_liquids = ["water", "tea", "coffee", "juice", "smoothie"]
        if v not in allowed_liquids:
            raise ValueError(f'Liquid type must be one of: {", ".join(allowed_liquids)}')
        return v


class ScanHistoryUpdate(BaseModel):
    """Schema for updating scan history (user corrections)"""

    user_corrected_volume_ml: Optional[int] = Field(None, ge=1, le=5000)
    is_validated: bool = Field(True)


class ScanHistoryResponse(BaseModel):
    """Schema for scan history response"""

    id: str
    user_id: str
    image_path: Optional[str]
    container_type: str
    fill_level_percent: float
    liquid_type: str
    confidence_score: float
    estimated_volume_ml: int
    effective_volume_ml: int
    is_validated: bool
    user_corrected_volume_ml: Optional[int]
    validated_at: Optional[datetime]
    created_at: datetime

    # Computed properties
    final_volume_ml: int
    confidence_category: str

    class Config:
        from_attributes = True