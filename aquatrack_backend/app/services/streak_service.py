"""
Streak calculation service for tracking user hydration streaks.

Calculates consecutive days where user achieved their daily hydration goal.
"""

from datetime import date, datetime, timedelta
from typing import Optional

from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.crud.user import user_crud
from app.models.daily_summary import DailySummary
from app.models.user import User


class StreakService:
    """Service for calculating and managing user streak data"""

    @staticmethod
    def calculate_current_streak(db: Session, user_id: str) -> int:
        """
        Calculate current consecutive streak for a user.

        Returns:
            int: Number of consecutive days user achieved daily goal (including today if achieved)
        """
        user = user_crud.get(db, user_id)
        if not user:
            return 0

        daily_goal_ml = user.daily_goal_ml or 2000
        today = date.today()

        # Check all daily summaries in reverse chronological order
        summaries = (
            db.query(DailySummary)
            .filter(
                DailySummary.user_id == user_id,
                DailySummary.total_effective_ml
                >= daily_goal_ml * 0.8,  # 80% threshold for "achieved"
            )
            .order_by(DailySummary.date.desc())
            .all()
        )

        if not summaries:
            return 0

        # Calculate consecutive days from most recent achievement
        streak = 0
        current_date = today

        for summary in summaries:
            summary_date = (
                summary.date.date()
                if isinstance(summary.date, datetime)
                else summary.date
            )

            # If this summary is for the current date we're checking
            if summary_date == current_date:
                streak += 1
                current_date -= timedelta(days=1)
            # If there's a gap, stop counting
            elif summary_date < current_date:
                break

        return streak

    @staticmethod
    def update_streak_for_user(
        db: Session, user_id: str, achieved_goal_today: bool = False
    ) -> tuple[int, int]:
        """
        Update user's current and longest streak.

        Args:
            db: Database session
            user_id: User ID
            achieved_goal_today: Whether user just achieved goal today

        Returns:
            tuple[current_streak, longest_streak]: Updated streak values
        """
        user = user_crud.get(db, user_id)
        if not user:
            return 0, 0

        # Calculate new current streak
        new_current_streak = StreakService.calculate_current_streak(db, user_id)

        # Update longest streak if needed
        new_longest_streak = max(user.longest_streak, new_current_streak)

        # Update user stats only if streak changed or goal achieved today
        if new_current_streak != user.current_streak or achieved_goal_today:
            user_crud.update_stats(db, user_id=user_id, new_streak=new_current_streak)

            # Update longest streak separately if needed
            if new_longest_streak > user.longest_streak:
                user.longest_streak = new_longest_streak
                db.add(user)
                db.commit()
                db.refresh(user)

        return new_current_streak, new_longest_streak

    @staticmethod
    def check_and_update_daily_achievement(
        db: Session, user_id: str, today_total_ml: int
    ) -> tuple[bool, int, int]:
        """
        Check if user achieved daily goal and update streak accordingly.

        Args:
            db: Database session
            user_id: User ID
            today_total_ml: Total effective volume for today

        Returns:
            tuple[goal_achieved, current_streak, longest_streak]
        """
        user = user_crud.get(db, user_id)
        if not user:
            return False, 0, 0

        daily_goal_ml = user.daily_goal_ml or 2000
        goal_achieved = today_total_ml >= (daily_goal_ml * 0.8)  # 80% threshold

        # Update streak
        current_streak, longest_streak = StreakService.update_streak_for_user(
            db, user_id, goal_achieved
        )

        return goal_achieved, current_streak, longest_streak

    @staticmethod
    def get_streak_stats(db: Session, user_id: str) -> dict:
        """
        Get comprehensive streak statistics for a user.

        Returns:
            dict: Streak statistics including current, longest, and recent achievements
        """
        user = user_crud.get(db, user_id)
        if not user:
            return {
                "current_streak": 0,
                "longest_streak": 0,
                "goal_achieved_today": False,
                "days_with_goal": 0,
            }

        # Get current streak (fresh calculation)
        current_streak = StreakService.calculate_current_streak(db, user_id)

        # Check if goal achieved today
        today = date.today()
        today_summary = (
            db.query(DailySummary)
            .filter(
                and_(
                    DailySummary.user_id == user_id,
                    func.date(DailySummary.date) == today,
                )
            )
            .first()
        )

        daily_goal_ml = user.daily_goal_ml or 2000
        goal_achieved_today = (
            today_summary is not None
            and today_summary.total_effective_ml >= (daily_goal_ml * 0.8)
        )

        # Count total days with goal achieved
        days_with_goal = (
            db.query(DailySummary)
            .filter(
                DailySummary.user_id == user_id,
                DailySummary.total_effective_ml >= (daily_goal_ml * 0.8),
            )
            .count()
        )

        return {
            "current_streak": current_streak,
            "longest_streak": user.longest_streak,
            "goal_achieved_today": goal_achieved_today,
            "days_with_goal": days_with_goal,
        }

    @staticmethod
    def reset_streak(db: Session, user_id: str) -> bool:
        """
        Reset user's streak to 0 (for admin/testing purposes).

        Returns:
            bool: Success status
        """
        try:
            user_crud.update_stats(db, user_id=user_id, new_streak=0)

            user = user_crud.get(db, user_id)
            if user:
                user.longest_streak = 0
                db.add(user)
                db.commit()

            return True
        except Exception:
            return False
