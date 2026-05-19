from typing import List, Optional

from fastapi import APIRouter, Depends, File, HTTPException, Query, UploadFile, status
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.scan_history import scan_history_crud
from app.schemas.vision import (
    ScanHistoryResponse,
    ScanHistoryUpdate,
    VisionEstimateRequest,
    VisionEstimateResponse,
)
from app.services.vision_service import vision_service

router = APIRouter()


@router.post(
    "/estimate-volume",
    response_model=VisionEstimateResponse,
    status_code=status.HTTP_200_OK,
)
async def estimate_volume(
    image: UploadFile = File(..., description="Image file for volume estimation"),
    confidence_threshold: float = Query(0.6, ge=0.0, le=1.0),
    save_to_history: bool = Query(True),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Estimate volume from uploaded image using ML

    - **image**: Image file (JPEG/PNG)
    - **confidence_threshold**: Minimum confidence threshold (0.0-1.0)
    - **save_to_history**: Whether to save scan to user's history
    """
    # Validate file type
    if image.content_type not in ["image/jpeg", "image/png", "image/jpg"]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Only JPEG and PNG images are supported"
        )

    # Validate file size (max 10MB)
    max_size = 10 * 1024 * 1024  # 10MB
    image_data = await image.read()
    if len(image_data) > max_size:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Image file too large. Maximum size is 10MB"
        )

    try:
        # Process image with vision service
        result = await vision_service.estimate_volume_from_image(
            image_data=image_data,
            user_id=current_user_id,
            db=db,
            save_to_history=save_to_history,
            confidence_threshold=confidence_threshold,
        )

        return result

    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=f"Image processing error: {str(e)}"
        )
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail="Internal server error during image processing"
        )


@router.get("/scan-history", response_model=List[ScanHistoryResponse])
async def get_scan_history(
    skip: int = Query(0, ge=0),
    limit: int = Query(50, ge=1, le=100),
    validated_only: Optional[bool] = Query(None, description="Filter validated scans only"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get user's scan history with optional filtering

    - **skip**: Number of records to skip (pagination)
    - **limit**: Maximum number of records to return
    - **validated_only**: Filter only validated scans
    """
    scans = scan_history_crud.get_by_user(
        db=db,
        user_id=current_user_id,
        skip=skip,
        limit=limit,
        validated_only=validated_only,
    )

    return scans


@router.get("/scan-history/{scan_id}", response_model=ScanHistoryResponse)
async def get_scan_by_id(
    scan_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get specific scan by ID"""
    scan = scan_history_crud.get(db=db, id=scan_id)

    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )

    # Verify scan belongs to current user
    if scan.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this scan"
        )

    return scan


@router.put("/scan-history/{scan_id}", response_model=ScanHistoryResponse)
async def update_scan_validation(
    scan_id: str,
    scan_update: ScanHistoryUpdate,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Update scan validation and user corrections

    - **scan_id**: ID of scan to update
    - **scan_update**: Update data (validation status, corrected volume)
    """
    # Get existing scan
    scan = scan_history_crud.get(db=db, id=scan_id)

    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )

    # Verify scan belongs to current user
    if scan.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this scan"
        )

    # Update scan with validation
    updated_scan = scan_history_crud.update_with_validation(
        db=db, db_obj=scan, obj_in=scan_update
    )

    return updated_scan


@router.get("/scan-history/stats/confidence", response_model=dict)
async def get_confidence_stats(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get confidence statistics for user's scans"""
    stats = scan_history_crud.get_confidence_stats(db=db, user_id=current_user_id)
    return stats


@router.get("/scan-history/stats/accuracy", response_model=dict)
async def get_accuracy_stats(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Get accuracy statistics based on user validations"""
    stats = scan_history_crud.get_accuracy_stats(db=db, user_id=current_user_id)
    return stats


@router.delete("/scan-history/{scan_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_scan(
    scan_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """Delete a scan from history"""
    # Get existing scan
    scan = scan_history_crud.get(db=db, id=scan_id)

    if not scan:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Scan not found"
        )

    # Verify scan belongs to current user
    if scan.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Access denied to this scan"
        )

    # Delete scan
    scan_history_crud.remove(db=db, id=scan_id)

    return None