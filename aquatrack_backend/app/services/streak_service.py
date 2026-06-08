"""
Streak calculation service for tracking user hydration streaks.

Calculates consecutive days where user achieved their daily hydration goal.
"""

from datetime import date, datetime, timedelta
from typing import Optional

from sqlalchemy import and_, func, update
from sqlalchemy.orm import Session

from app.crud.user import user_crud
from app.models.daily_summary import DailySummary
from app.models.user import User


class FreezePurchaseError(Exception):
    """Raised when a Streak Freeze purchase cannot be completed."""


class StreakService:
    """Service for calculating and managing user streak data"""

    # Price of one Streak Freeze in Coins (ADR 0004).
    STREAK_FREEZE_PRICE = 300

    @staticmethod
    def _parse_frozen(raw) -> set:
        """Normalise the stored `frozen_dates` JSON into a set of `date`."""
        out = set()
        for item in raw or []:
            if isinstance(item, date) and not isinstance(item, datetime):
                out.add(item)
            elif isinstance(item, datetime):
                out.add(item.date())
            else:
                try:
                    out.add(date.fromisoformat(str(item)[:10]))
                except ValueError:
                    continue
        return out

    @staticmethod
    def _resolve_streak(
        achieved: set, today: date, frozen: set, freeze_owned: bool
    ) -> int:
        """Pure streak computation with Streak Freeze bridging (ADR 0004).

        A run is the consecutive achieved days ending at the most recent achieved
        day. A *frozen* day bridges a gap (keeps the run continuous) but adds 0 to
        length. An owned-but-unconsumed Freeze (`freeze_owned`) provisionally
        bridges the single most-recent missed day at the head, so a live streak
        never shows a false break before the next log reconciles it. Today is
        pending and never breaks the streak.
        """
        if not achieved:
            return 0

        most_recent = max(achieved)
        provisional = freeze_owned

        # Head: bridge the gap from the most recent achieved day up to yesterday
        # so the run counts as "current". One provisional bridge max.
        cursor = today - timedelta(days=1)
        while cursor > most_recent:
            if cursor in frozen:
                cursor -= timedelta(days=1)
            elif provisional:
                provisional = False
                cursor -= timedelta(days=1)
            else:
                return 0  # unbridgeable gap → streak broken

        # Body: count consecutive achieved days, bridging recorded frozen days.
        streak = 0
        expected = most_recent
        while True:
            if expected in achieved:
                streak += 1
                expected -= timedelta(days=1)
            elif expected in frozen:
                expected -= timedelta(days=1)
            else:
                break
        return streak

    @staticmethod
    def _achieved_dates(db: Session, user: User) -> list:
        """Achieved days (>= 80% goal) for a user, most recent first."""
        threshold = (user.daily_goal_ml or 2000) * 0.8
        rows = (
            db.query(DailySummary.date)
            .filter(
                DailySummary.user_id == user.id,
                DailySummary.total_effective_ml >= threshold,
            )
            .order_by(DailySummary.date.desc())
            .all()
        )
        return [(d.date() if isinstance(d, datetime) else d) for (d,) in rows]

    @staticmethod
    def calculate_current_streak(db: Session, user_id: str) -> int:
        """
        Calculate the current consecutive streak for a user.

        A streak is the run of consecutive days (each meeting the goal
        threshold) ending at the most recent achieved day. It is only
        considered *current* (non-zero) if that most recent achieved day is
        today or yesterday — this gives the user until the end of today to keep
        it alive, but resets to 0 once a full day is missed. A Streak Freeze can
        bridge a single missed day (see `_resolve_streak`).

        Returns:
            int: Length of the current streak (0 if broken).
        """
        user = user_crud.get(db, user_id)
        if not user:
            return 0

        achieved = set(StreakService._achieved_dates(db, user))
        frozen = StreakService._parse_frozen(user.frozen_dates)
        return StreakService._resolve_streak(
            achieved, date.today(), frozen, bool(user.streak_freeze_owned)
        )

    @staticmethod
    def reconcile_freeze(db: Session, user_id: str) -> bool:
        """Consume an owned Freeze at log time to permanently bridge a single
        missed day between the two most recent achieved days.

        Called after an intake log records today's achievement. If exactly one
        day separates the two most recent achieved days and the user owns a
        Freeze, that missing day is recorded in `frozen_dates` and the Freeze is
        consumed. Multi-day gaps are not bridged (one Freeze covers one day).

        Returns:
            bool: True if a Freeze was consumed.
        """
        user = user_crud.get(db, user_id)
        if not user or not user.streak_freeze_owned:
            return False

        achieved = StreakService._achieved_dates(db, user)
        if len(achieved) < 2:
            return False

        most_recent, prev = achieved[0], achieved[1]
        # Only reconcile on the log that just made *today* achieved, so the
        # bridged day is always yesterday (the head gap) — never an older gap a
        # sub-goal log happens to sit next to.
        if most_recent != date.today():
            return False
        # Exactly one missing day between the two most recent achieved days.
        if (most_recent - prev).days != 2:
            return False

        missing = most_recent - timedelta(days=1)
        frozen = StreakService._parse_frozen(user.frozen_dates)
        if missing in frozen:
            return False

        frozen.add(missing)
        user.frozen_dates = sorted(d.isoformat() for d in frozen)
        user.streak_freeze_owned = False
        db.add(user)
        db.commit()
        db.refresh(user)
        return True

    @staticmethod
    def purchase_freeze(db: Session, user: User) -> User:
        """Spend Coins to own a single Streak Freeze. Binary inventory: rejects
        the purchase if one is already owned or coins are insufficient.

        The deduction is a single conditional UPDATE so two concurrent purchases
        cannot both succeed (each guarded by the un-owned + affordable predicate).
        """
        price = StreakService.STREAK_FREEZE_PRICE
        if user.streak_freeze_owned:
            raise FreezePurchaseError("Bạn đang sở hữu một lá đóng băng")
        if (user.coins or 0) < price:
            raise FreezePurchaseError("Không đủ xu")

        result = db.execute(
            update(User)
            .where(
                User.id == user.id,
                User.streak_freeze_owned.is_(False),
                User.coins >= price,
            )
            .values(coins=User.coins - price, streak_freeze_owned=True)
        )
        db.commit()
        if result.rowcount == 0:
            # Lost the race (already owned / spent concurrently).
            raise FreezePurchaseError("Mua thất bại")
        db.refresh(user)
        return user

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
