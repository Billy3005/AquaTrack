from datetime import date
from typing import List, Optional

from sqlalchemy import and_, desc, func
from sqlalchemy.orm import Session

from app.crud.base import CRUDBase
from app.models.scan_history import ScanHistory
from app.schemas.vision import ScanHistoryCreate, ScanHistoryUpdate


class CRUDScanHistory(CRUDBase[ScanHistory, ScanHistoryCreate, ScanHistoryUpdate]):
    """CRUD operations for ScanHistory model"""

    def create_with_user(
        self, db: Session, *, obj_in: ScanHistoryCreate, user_id: str
    ) -> ScanHistory:
        """Create new scan history record for a user"""
        db_obj = ScanHistory(
            user_id=user_id,
            image_path=obj_in.image_path,
            container_type=obj_in.container_type,
            fill_level_percent=obj_in.fill_level_percent,
            liquid_type=obj_in.liquid_type,
            confidence_score=obj_in.confidence_score,
            estimated_volume_ml=obj_in.estimated_volume_ml,
            effective_volume_ml=obj_in.effective_volume_ml,
        )

        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def update_with_validation(
        self, db: Session, *, db_obj: ScanHistory, obj_in: ScanHistoryUpdate
    ) -> ScanHistory:
        """Update scan history with user validation/correction"""
        if obj_in.user_corrected_volume_ml is not None:
            db_obj.user_corrected_volume_ml = obj_in.user_corrected_volume_ml

        if obj_in.is_validated is not None:
            db_obj.is_validated = obj_in.is_validated
            if obj_in.is_validated:
                db_obj.validated_at = func.now()

        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_by_user(
        self,
        db: Session,
        user_id: str,
        skip: int = 0,
        limit: int = 100,
        validated_only: Optional[bool] = None,
    ) -> List[ScanHistory]:
        """Get scan history for a user with optional filtering"""
        query = db.query(self.model).filter(self.model.user_id == user_id)

        if validated_only is not None:
            query = query.filter(self.model.is_validated == validated_only)

        return (
            query.order_by(desc(self.model.created_at))
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_by_user_and_date(
        self,
        db: Session,
        user_id: str,
        target_date: date,
    ) -> List[ScanHistory]:
        """Get all scan history for a user on a specific date"""
        return (
            db.query(self.model)
            .filter(
                and_(
                    self.model.user_id == user_id,
                    func.date(self.model.created_at) == target_date,
                )
            )
            .order_by(desc(self.model.created_at))
            .all()
        )

    def get_recent_by_user(
        self, db: Session, user_id: str, limit: int = 10
    ) -> List[ScanHistory]:
        """Get recent scan history for a user"""
        return (
            db.query(self.model)
            .filter(self.model.user_id == user_id)
            .order_by(desc(self.model.created_at))
            .limit(limit)
            .all()
        )

    def get_confidence_stats(self, db: Session, user_id: str) -> dict:
        """Get confidence statistics for a user's scans"""
        scans = self.get_by_user(db, user_id)

        if not scans:
            return {
                "total_scans": 0,
                "avg_confidence": 0.0,
                "high_confidence_count": 0,
                "medium_confidence_count": 0,
                "low_confidence_count": 0,
            }

        total_scans = len(scans)
        avg_confidence = sum(scan.confidence_score for scan in scans) / total_scans

        high_confidence = sum(1 for scan in scans if scan.confidence_score >= 0.8)
        medium_confidence = sum(
            1 for scan in scans if 0.6 <= scan.confidence_score < 0.8
        )
        low_confidence = sum(1 for scan in scans if scan.confidence_score < 0.6)

        return {
            "total_scans": total_scans,
            "avg_confidence": round(avg_confidence, 3),
            "high_confidence_count": high_confidence,
            "medium_confidence_count": medium_confidence,
            "low_confidence_count": low_confidence,
        }

    def get_accuracy_stats(self, db: Session, user_id: str) -> dict:
        """Get accuracy statistics based on user validations"""
        validated_scans = self.get_by_user(db, user_id, validated_only=True)

        if not validated_scans:
            return {
                "validated_scans": 0,
                "correction_rate": 0.0,
                "avg_correction_difference": 0.0,
            }

        corrected_scans = [
            scan for scan in validated_scans if scan.user_corrected_volume_ml is not None
        ]

        correction_rate = len(corrected_scans) / len(validated_scans)

        if corrected_scans:
            correction_differences = [
                abs(scan.estimated_volume_ml - scan.user_corrected_volume_ml)
                for scan in corrected_scans
            ]
            avg_correction_difference = sum(correction_differences) / len(correction_differences)
        else:
            avg_correction_difference = 0.0

        return {
            "validated_scans": len(validated_scans),
            "correction_rate": round(correction_rate, 3),
            "avg_correction_difference": round(avg_correction_difference, 1),
        }


# Create instance for use in endpoints
scan_history_crud = CRUDScanHistory(ScanHistory)