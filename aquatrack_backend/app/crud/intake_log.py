from datetime import date, datetime
from typing import List

from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.crud.base import CRUDBase
from app.models.intake_log import IntakeLog
from app.schemas.intake_log import IntakeLogCreate, IntakeLogUpdate


class CRUDIntakeLog(CRUDBase[IntakeLog, IntakeLogCreate, IntakeLogUpdate]):
    """CRUD operations for IntakeLog model"""

    def create(
        self, db: Session, *, obj_in: IntakeLogCreate, user_id: str
    ) -> IntakeLog:
        """Create new intake log with server-side calculations"""
        # Calculate hydration factor based on liquid type
        hydration_factors = {
            "water": 1.0,
            "tea": 0.85,
            "coffee": 0.8,
            "juice": 0.7,
            "sports_drink": 0.9,
            "other": 0.75,
        }

        hydration_factor = hydration_factors.get(obj_in.liquid_type, 0.75)
        effective_volume = int(obj_in.volume_ml * hydration_factor)

        # Flat 20 XP per log, capped at 200 XP per calendar day.
        _XP_PER_LOG = 20
        _DAILY_XP_CAP = 200
        today_xp = (
            db.query(func.coalesce(func.sum(IntakeLog.xp_earned), 0))
            .filter(
                IntakeLog.user_id == user_id,
                func.date(IntakeLog.logged_at) == datetime.now().date(),
            )
            .scalar()
        ) or 0
        base_xp = _XP_PER_LOG if today_xp < _DAILY_XP_CAP else 0

        # Create database object với explicit logged_at
        db_obj = IntakeLog(
            user_id=user_id,
            volume_ml=obj_in.volume_ml,
            liquid_type=obj_in.liquid_type,
            hydration_factor=hydration_factor,
            effective_volume_ml=effective_volume,
            xp_earned=base_xp,
            temperature=obj_in.temperature,
            location=obj_in.location,
            mood_before=obj_in.mood_before,
            source=obj_in.source,
            logged_at=datetime.now(),  # Force current timestamp for consistent date queries
        )

        db.add(db_obj)
        db.commit()
        db.refresh(db_obj)
        return db_obj

    def get_by_user_and_date(
        self,
        db: Session,
        user_id: str,
        target_date: date,
    ) -> List[IntakeLog]:
        """Get all intake logs for a user on a specific date"""
        return (
            db.query(self.model)
            .filter(
                and_(
                    self.model.user_id == user_id,
                    func.date(self.model.logged_at) == target_date,
                )
            )
            .order_by(self.model.logged_at.desc())
            .all()
        )

    def get_by_user_date_range(
        self,
        db: Session,
        user_id: str,
        date_from: date,
        date_to: date,
        skip: int = 0,
        limit: int = 100,
    ) -> List[IntakeLog]:
        """Get intake logs for a user within a date range"""
        return (
            db.query(self.model)
            .filter(
                and_(
                    self.model.user_id == user_id,
                    func.date(self.model.logged_at) >= date_from,
                    func.date(self.model.logged_at) <= date_to,
                )
            )
            .order_by(self.model.logged_at.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    def get_recent_by_user(
        self,
        db: Session,
        user_id: str,
        limit: int = 10,
    ) -> List[IntakeLog]:
        """Get recent intake logs for a user"""
        return (
            db.query(self.model)
            .filter(self.model.user_id == user_id)
            .order_by(self.model.logged_at.desc())
            .limit(limit)
            .all()
        )

    def get_daily_stats(
        self,
        db: Session,
        user_id: str,
        target_date: date,
    ) -> dict:
        """Get daily intake statistics for a user"""
        result = (
            db.query(
                func.count(self.model.id).label("log_count"),
                func.coalesce(func.sum(self.model.volume_ml), 0).label("total_volume"),
                func.coalesce(func.sum(self.model.effective_volume_ml), 0).label(
                    "total_effective"
                ),
                func.coalesce(
                    func.sum(self.model.xp_earned + self.model.bonus_xp), 0
                ).label("total_xp"),
                func.avg(self.model.volume_ml).label("avg_volume"),
            )
            .filter(
                and_(
                    self.model.user_id == user_id,
                    func.date(self.model.logged_at) == target_date,
                )
            )
            .first()
        )

        return {
            "date": target_date,
            "log_count": result.log_count or 0,
            "total_volume_ml": result.total_volume or 0,
            "total_effective_ml": result.total_effective or 0,
            "total_xp_earned": result.total_xp or 0,
            "average_volume_ml": float(result.avg_volume or 0),
        }

    def get_liquid_type_stats(
        self,
        db: Session,
        user_id: str,
        date_from: date,
        date_to: date,
    ) -> List[dict]:
        """Get liquid type distribution statistics"""
        result = (
            db.query(
                self.model.liquid_type,
                func.count(self.model.id).label("count"),
                func.sum(self.model.volume_ml).label("total_volume"),
                func.sum(self.model.effective_volume_ml).label("total_effective"),
                func.avg(self.model.volume_ml).label("avg_volume"),
            )
            .filter(
                and_(
                    self.model.user_id == user_id,
                    func.date(self.model.logged_at) >= date_from,
                    func.date(self.model.logged_at) <= date_to,
                )
            )
            .group_by(self.model.liquid_type)
            .all()
        )

        return [
            {
                "liquid_type": r.liquid_type,
                "log_count": r.count,
                "total_volume_ml": r.total_volume or 0,
                "total_effective_ml": r.total_effective or 0,
                "average_volume_ml": float(r.avg_volume or 0),
            }
            for r in result
        ]

    def count_by_user_and_date(
        self,
        db: Session,
        user_id: str,
        target_date: date,
    ) -> int:
        """Count intake logs for a user on a specific date"""
        return (
            db.query(func.count(self.model.id))
            .filter(
                and_(
                    self.model.user_id == user_id,
                    func.date(self.model.logged_at) == target_date,
                )
            )
            .scalar()
        )


def authoritative_total_xp(db: Session, user) -> int:
    """The user's true Total XP — the single value the Level is derived from
    everywhere (matches /levels/current): repeatable intake XP
    (xp_earned + bonus_xp) plus the quest/milestone XP stored on user.total_xp.
    Use this (never user.total_xp alone) when reconciling Level-Up coins so the
    high-water mark tracks the real level."""
    intake_xp = (
        db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp))
        .filter(IntakeLog.user_id == user.id)
        .scalar()
        or 0
    )
    return int(intake_xp) + (user.total_xp or 0)


# Global instance
intake_log_crud = CRUDIntakeLog(IntakeLog)
