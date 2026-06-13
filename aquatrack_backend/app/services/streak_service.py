"""
Streak calculation service for tracking user hydration streaks.

Calculates consecutive days where user achieved their daily hydration goal.
"""

from datetime import date, datetime, timedelta

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
    def _resolve_streak(achieved: set, today: date, frozen: set) -> int:
        """Pure streak computation with frozen-day bridging (ADR 0004, amended).

        A run is the consecutive achieved days ending at the most recent achieved
        day. A *frozen* day bridges a gap (keeps the run continuous) but adds 0 to
        length. Today is pending and never breaks the streak. There is no
        provisional bridging here: Freeze consumption is materialised by
        `reconcile_freeze` BEFORE this resolver runs, so only recorded frozen
        days bridge.
        """
        if not achieved:
            return 0

        most_recent = max(achieved)

        # Head: the gap from the most recent achieved day up to yesterday must
        # be fully frozen for the run to still count as "current".
        cursor = today - timedelta(days=1)
        while cursor > most_recent:
            if cursor in frozen:
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
        it alive, but resets to 0 once a full day is missed. A consumed Streak
        Freeze bridges a single missed day (see `reconcile_freeze`).

        Returns:
            int: Length of the current streak (0 if broken).
        """
        user = user_crud.get(db, user_id)
        if not user:
            return 0

        # Materialise any already-decided Freeze burn before resolving, so the
        # streak and the Shop always agree (ADR 0004, Duolingo semantics).
        if StreakService.reconcile_freeze(db, user_id):
            db.refresh(user)

        achieved = set(StreakService._achieved_dates(db, user))
        frozen = StreakService._parse_frozen(user.frozen_dates)
        return StreakService._resolve_streak(achieved, date.today(), frozen)

    @staticmethod
    def _live_entering(day: date, achieved: set, frozen: set) -> bool:
        """Whether a streak is alive going into `day` — the previous day chains
        back through frozen days to an achieved day."""
        cursor = day - timedelta(days=1)
        while cursor in frozen:
            cursor -= timedelta(days=1)
        return cursor in achieved

    @staticmethod
    def reconcile_freeze(db: Session, user_id: str) -> bool:
        """Lazily record an already-decided Freeze burn (ADR 0004, amended).

        Duolingo semantics ("dùng là mất"): an owned Freeze burns at the
        midnight of the FIRST fully-passed missed day that (a) had a live
        streak entering it and (b) is on/after the purchase date — whether or
        not the streak ultimately survives. Reads don't *spend* the item; the
        miss spent it. This call just materialises that fact in
        `frozen_dates` / `streak_freeze_owned` so the streak resolver and the
        Shop both see it (there is no nightly job to do it at the midnight).

        Returns:
            bool: True if a Freeze burn was recorded.
        """
        user = user_crud.get(db, user_id)
        if not user or not user.streak_freeze_owned:
            return False

        achieved = set(StreakService._achieved_dates(db, user))
        if not achieved:
            return False  # nothing to protect yet

        frozen = StreakService._parse_frozen(user.frozen_dates)
        today = date.today()
        purchased = user.freeze_purchased_on
        if purchased is None:
            # Legacy rows (pre freeze_purchased_on): the purchase date is
            # unknowable, so bound to the most recent achieved day — the burn
            # lands on the current run's miss (mirroring the old provisional
            # behaviour), never on an ancient gap of a long-dead run.
            purchased = max(achieved)

        # Candidate burns: the first uncovered day after each covered run.
        candidates = []
        for day in achieved | frozen:
            nxt = day + timedelta(days=1)
            if nxt in achieved or nxt in frozen:
                continue  # not a run end
            if nxt >= today:
                continue  # today is still pending — not a miss yet
            if nxt < purchased:
                continue  # Freeze didn't exist yet — never resurrect a dead run
            if StreakService._live_entering(nxt, achieved, frozen):
                candidates.append(nxt)
        if not candidates:
            return False

        # The earliest qualifying miss is when the Freeze actually burned.
        burned = min(candidates)
        frozen.add(burned)
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
            .values(
                coins=User.coins - price,
                streak_freeze_owned=True,
                # Bounds which missed days this Freeze may cover: it protects
                # from tonight onward, never gaps that predate the purchase.
                freeze_purchased_on=date.today(),
            )
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
