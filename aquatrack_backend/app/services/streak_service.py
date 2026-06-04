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
        Calculate the current consecutive streak for a user.

        A streak is the run of consecutive days (each meeting the goal
        threshold) ending at the most recent achieved day. It is only
        considered *current* (non-zero) if that most recent achieved day is
        today or yesterday — this gives the user until the end of today to keep
        it alive, but resets to 0 once a full day is missed.

        Returns:
            int: Length of the current streak (0 if broken).
        """
        user = user_crud.get(db, user_id)
        if not user:
            return 0

        daily_goal_ml = user.daily_goal_ml or 2000
        threshold = daily_goal_ml * 0.8  # 80% counts as "achieved"
        today = date.today()

        # Achieved days, most recent first.
        rows = (
            db.query(DailySummary.date)
            .filter(
                DailySummary.user_id == user_id,
                DailySummary.total_effective_ml >= threshold,
            )
            .order_by(DailySummary.date.desc())
            .all()
        )
        if not rows:
            return 0

        achieved = [(d.date() if isinstance(d, datetime) else d) for (d,) in rows]

        # If the latest achieved day is older than yesterday, the streak is
        # broken (a full day was missed).
        most_recent = achieved[0]
        if most_recent < today - timedelta(days=1):
            return 0

        # Count consecutive days backwards from the most recent achieved day.
        streak = 0
        expected = most_recent
        for d in achieved:
            if d == expected:
                streak += 1
                expected -= timedelta(days=1)
            elif d < expected:
                break
            # d > expected (shouldn't happen with unique daily rows): skip.

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
