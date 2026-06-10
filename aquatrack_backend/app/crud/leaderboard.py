from datetime import date, datetime, timedelta
from typing import List, Optional

from sqlalchemy import and_, desc, func
from sqlalchemy.orm import Session

from app.crud.base import CRUDBase
from app.models.friend import Friend
from app.models.intake_log import IntakeLog
from app.models.leaderboard import LeaderboardEntry
from app.models.user import User


class CRUDLeaderboard(CRUDBase[LeaderboardEntry, dict, dict]):
    """CRUD operations for LeaderboardEntry model"""

    def get_current_week_start(self) -> date:
        """Get Monday of current week"""
        today = date.today()
        return today - timedelta(days=today.weekday())

    def calculate_user_week_stats(
        self, db: Session, *, user_id: str, week_start: date
    ) -> dict:
        """Calculate user's hydration stats for a specific week"""
        week_end = week_start + timedelta(days=6)

        # Get user's daily goal
        user = db.query(User).filter(User.id == user_id).first()
        daily_goal = user.daily_goal_ml if user else 2000

        # Get intake logs for the week
        intake_logs = (
            db.query(IntakeLog)
            .filter(
                and_(
                    IntakeLog.user_id == user_id,
                    func.date(IntakeLog.created_at) >= week_start,
                    func.date(IntakeLog.created_at) <= week_end,
                )
            )
            .all()
        )

        # Calculate daily totals
        daily_totals = {}
        total_volume = 0

        for log in intake_logs:
            day = log.created_at.date()
            if day not in daily_totals:
                daily_totals[day] = 0
            daily_totals[day] += log.volume_ml
            total_volume += log.volume_ml

        # Calculate goal achievement days
        goal_achievement_days = sum(
            1 for daily_total in daily_totals.values() if daily_total >= daily_goal
        )

        # Calculate average daily volume
        days_with_data = len(daily_totals) if daily_totals else 1
        average_daily_ml = total_volume // days_with_data

        # Calculate current streak (simplified - could be more sophisticated)
        current_date = date.today()
        streak_days = 0
        for i in range(7):
            check_date = current_date - timedelta(days=i)
            if check_date < week_start:
                break
            if daily_totals.get(check_date, 0) >= daily_goal:
                streak_days += 1
            else:
                break

        return {
            "total_volume_ml": total_volume,
            "goal_achievement_days": goal_achievement_days,
            "streak_days": streak_days,
            "average_daily_ml": average_daily_ml,
        }

    def update_or_create_week_entry(
        self, db: Session, *, user_id: str, week_start: Optional[date] = None
    ) -> LeaderboardEntry:
        """Update or create leaderboard entry for user's week"""
        if not week_start:
            week_start = self.get_current_week_start()

        # Check for existing entry
        existing_entry = (
            db.query(LeaderboardEntry)
            .filter(
                and_(
                    LeaderboardEntry.user_id == user_id,
                    LeaderboardEntry.week_start_date == week_start,
                )
            )
            .first()
        )

        # Calculate week stats
        week_stats = self.calculate_user_week_stats(
            db, user_id=user_id, week_start=week_start
        )

        if existing_entry:
            # Update existing entry
            for key, value in week_stats.items():
                setattr(existing_entry, key, value)
            existing_entry.updated_at = datetime.utcnow()
            db.commit()
            db.refresh(existing_entry)
            return existing_entry
        else:
            # Create new entry
            entry_data = {
                "user_id": user_id,
                "week_start_date": week_start,
                "week_year": week_start.year,
                **week_stats,
            }

            entry = LeaderboardEntry(**entry_data)
            db.add(entry)
            db.commit()
            db.refresh(entry)
            return entry

    def calculate_rankings(
        self, db: Session, *, week_start: Optional[date] = None
    ) -> None:
        """Calculate and update rankings for all users in a week"""
        if not week_start:
            week_start = self.get_current_week_start()

        # Get all entries for the week, ordered by total volume desc
        entries = (
            db.query(LeaderboardEntry)
            .filter(LeaderboardEntry.week_start_date == week_start)
            .order_by(
                desc(LeaderboardEntry.total_volume_ml),
                desc(LeaderboardEntry.goal_achievement_days),
                desc(LeaderboardEntry.streak_days),
            )
            .all()
        )

        total_participants = len(entries)

        # Assign rankings
        for i, entry in enumerate(entries, 1):
            entry.rank_position = i
            entry.total_participants = total_participants
            entry.calculated_at = datetime.utcnow()

        db.commit()

    def get_weekly_leaderboard(
        self,
        db: Session,
        *,
        week_start: Optional[date] = None,
        current_user_id: str,
        limit: int = 10,
    ) -> dict:
        """Get weekly leaderboard with user and friends context"""
        if not week_start:
            week_start = self.get_current_week_start()

        # Ensure rankings are up to date
        self.calculate_rankings(db, week_start=week_start)

        # Get top entries with user info
        top_entries = (
            db.query(LeaderboardEntry, User)
            .join(User, LeaderboardEntry.user_id == User.id)
            .filter(LeaderboardEntry.week_start_date == week_start)
            .order_by(LeaderboardEntry.rank_position)
            .limit(limit)
            .all()
        )

        # Get current user's entry
        current_user_entry = (
            db.query(LeaderboardEntry, User)
            .join(User, LeaderboardEntry.user_id == User.id)
            .filter(
                and_(
                    LeaderboardEntry.user_id == current_user_id,
                    LeaderboardEntry.week_start_date == week_start,
                )
            )
            .first()
        )

        # Get friends' entries
        friends_entries = (
            db.query(LeaderboardEntry, User, Friend)
            .join(User, LeaderboardEntry.user_id == User.id)
            .join(
                Friend,
                and_(
                    Friend.friend_user_id == LeaderboardEntry.user_id,
                    Friend.user_id == current_user_id,
                    Friend.is_active == True,
                    Friend.is_blocked == False,
                ),
            )
            .filter(LeaderboardEntry.week_start_date == week_start)
            .order_by(LeaderboardEntry.rank_position)
            .all()
        )

        # Helper function to format entry
        def format_entry(entry_tuple, is_current_user: bool = False):
            if len(entry_tuple) == 3:  # LeaderboardEntry, User, Friend
                entry, user, friend = entry_tuple
                is_friend = True
            else:  # LeaderboardEntry, User
                entry, user = entry_tuple
                is_friend = False

            return {
                "id": entry.id,
                "user_id": entry.user_id,
                "week_start_date": entry.week_start_date,
                "week_year": entry.week_year,
                "total_volume_ml": entry.total_volume_ml,
                "goal_achievement_days": entry.goal_achievement_days,
                "streak_days": entry.streak_days,
                "average_daily_ml": entry.average_daily_ml,
                "rank_position": entry.rank_position,
                "total_participants": entry.total_participants,
                "xp_earned": entry.xp_earned,
                "achievements_unlocked": entry.achievements_unlocked,
                "goal_achievement_percentage": entry.goal_achievement_percentage,
                "rank_suffix": entry.rank_suffix,
                "is_current_week": entry.is_current_week,
                "username": user.username,
                "avatar_id": user.avatar_id,
                "current_level": user.current_level,
                "is_current_user": is_current_user,
                "is_friend": is_friend,
            }

        # Format results
        result = {
            "week_start_date": week_start,
            "week_year": week_start.year,
            "total_participants": len(top_entries),
            "current_user_rank": None,
            "current_user_entry": None,
            "top_entries": [format_entry(entry) for entry in top_entries],
            "friends_entries": [format_entry(entry) for entry in friends_entries],
        }

        if current_user_entry:
            entry, user = current_user_entry
            result["current_user_rank"] = entry.rank_position
            result["current_user_entry"] = format_entry(
                current_user_entry, is_current_user=True
            )

        return result

    def get_user_leaderboard_history(
        self,
        db: Session,
        *,
        user_id: str,
        limit: int = 10,
    ) -> List[dict]:
        """Get user's leaderboard history"""
        entries = (
            db.query(LeaderboardEntry)
            .filter(LeaderboardEntry.user_id == user_id)
            .order_by(desc(LeaderboardEntry.week_start_date))
            .limit(limit)
            .all()
        )

        return [
            {
                "week_start_date": entry.week_start_date,
                "rank_position": entry.rank_position,
                "total_volume_ml": entry.total_volume_ml,
                "goal_achievement_days": entry.goal_achievement_days,
                "total_participants": entry.total_participants,
                "rank_suffix": entry.rank_suffix,
            }
            for entry in entries
        ]

    def get_user_best_rank(self, db: Session, *, user_id: str) -> Optional[int]:
        """Get user's best ever rank"""
        best_entry = (
            db.query(LeaderboardEntry)
            .filter(
                and_(
                    LeaderboardEntry.user_id == user_id,
                    LeaderboardEntry.rank_position.isnot(None),
                )
            )
            .order_by(LeaderboardEntry.rank_position)
            .first()
        )

        return best_entry.rank_position if best_entry else None

    def get_participation_count(self, db: Session, *, user_id: str) -> int:
        """Get number of weeks user has participated"""
        count = (
            db.query(func.count(LeaderboardEntry.id))
            .filter(LeaderboardEntry.user_id == user_id)
            .scalar()
        )

        return count or 0


# Global instance
leaderboard_crud = CRUDLeaderboard(LeaderboardEntry)
