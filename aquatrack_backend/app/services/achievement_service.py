"""
Achievement service for automatic progression and XP calculation
Handles achievement unlocking, level progression, and rewards
"""

from datetime import date, datetime, timedelta
from typing import Dict, List, Optional, Tuple

from sqlalchemy.orm import Session

from app.core.config import settings
from app.crud.achievement import achievement_crud
from app.crud.daily_summary import daily_summary_crud
from app.crud.intake_log import intake_log_crud
from app.crud.user import user_crud
from app.models.achievement import Achievement, AchievementType
from app.models.daily_summary import DailySummary
from app.models.intake_log import IntakeLog
from app.models.user import User


class AchievementService:
    """Service for managing achievements and user progression"""

    def __init__(self):
        self.xp_rewards = {
            AchievementType.DAILY_GOAL: 50,
            AchievementType.STREAK: 100,
            AchievementType.TOTAL_VOLUME: 200,
            AchievementType.LEVEL: 75,
            AchievementType.FREQUENCY: 150,
        }

    def calculate_level_from_xp(self, total_xp: int) -> int:
        """Calculate level based on total XP with exponential scaling"""
        if total_xp <= 0:
            return 1

        # Formula: XP needed = base * (multiplier ^ (level - 1))
        base_xp = settings.BASE_XP_PER_LEVEL
        multiplier = settings.XP_MULTIPLIER

        level = 1
        xp_needed = 0

        while level <= settings.MAX_LEVEL:
            level_xp = int(base_xp * (multiplier ** (level - 1)))
            if xp_needed + level_xp > total_xp:
                break
            xp_needed += level_xp
            level += 1

        return min(level, settings.MAX_LEVEL)

    def calculate_xp_for_level(self, level: int) -> int:
        """Calculate total XP needed to reach a specific level"""
        if level <= 1:
            return 0

        base_xp = settings.BASE_XP_PER_LEVEL
        multiplier = settings.XP_MULTIPLIER

        total_xp = 0
        for l in range(1, level):
            level_xp = int(base_xp * (multiplier ** (l - 1)))
            total_xp += level_xp

        return total_xp

    def get_level_progress(self, total_xp: int) -> Dict[str, int]:
        """Get current level and progress to next level"""
        current_level = self.calculate_level_from_xp(total_xp)

        if current_level >= settings.MAX_LEVEL:
            return {
                "current_level": current_level,
                "current_level_xp": total_xp
                - self.calculate_xp_for_level(current_level),
                "next_level_xp": 0,
                "progress_percent": 100,
            }

        current_level_min_xp = self.calculate_xp_for_level(current_level)
        next_level_min_xp = self.calculate_xp_for_level(current_level + 1)

        current_level_xp = total_xp - current_level_min_xp
        next_level_xp = next_level_min_xp - current_level_min_xp

        progress_percent = (
            int((current_level_xp / next_level_xp) * 100) if next_level_xp > 0 else 0
        )

        return {
            "current_level": current_level,
            "current_level_xp": current_level_xp,
            "next_level_xp": next_level_xp,
            "progress_percent": min(progress_percent, 100),
        }

    async def process_intake_log_achievements(
        self, db: Session, user_id: str, intake_log: IntakeLog
    ) -> List[Dict[str, any]]:
        """Process all achievements triggered by a new intake log"""
        unlocked_achievements = []

        # Get user and current stats
        user = user_crud.get(db, user_id)
        if not user:
            return unlocked_achievements

        today = date.today()

        # Get or create today's daily summary
        daily_summary = daily_summary_crud.get_or_create_daily_summary(
            db, user_id=user_id, date=today
        )

        # Update daily summary with new intake
        self._update_daily_summary(db, daily_summary, intake_log)

        # Check all achievement categories
        unlocked_achievements.extend(
            await self._check_hydration_achievements(db, user_id, daily_summary)
        )
        unlocked_achievements.extend(
            await self._check_streak_achievements(db, user_id, daily_summary)
        )
        unlocked_achievements.extend(
            await self._check_milestone_achievements(db, user_id, user)
        )
        unlocked_achievements.extend(
            await self._check_consistency_achievements(db, user_id)
        )

        # Calculate total XP gained
        total_xp_gained = sum(
            self.xp_rewards.get(AchievementType(ach["achievement_type"]), 0)
            for ach in unlocked_achievements
        )

        # Update user XP and level if achievements were unlocked
        if total_xp_gained > 0:
            old_level = user.current_level
            new_total_xp = user.total_xp + total_xp_gained
            new_level = self.calculate_level_from_xp(new_total_xp)

            user_crud.update_stats(
                db, user_id=user_id, xp_gained=total_xp_gained, new_level=new_level
            )

            # Check for level-up achievements
            if new_level > old_level:
                level_achievements = await self._check_level_achievements(
                    db, user_id, old_level, new_level
                )
                unlocked_achievements.extend(level_achievements)

        return unlocked_achievements

    def _update_daily_summary(
        self, db: Session, daily_summary: DailySummary, intake_log: IntakeLog
    ):
        """Update daily summary with new intake log"""
        daily_summary.total_volume_ml += intake_log.effective_volume_ml
        daily_summary.log_count += 1
        daily_summary.last_log_at = intake_log.logged_at

        # Update goal achievement
        daily_summary.goal_achieved = (
            daily_summary.total_volume_ml >= daily_summary.daily_goal_ml
        )

        # Calculate completion percentage
        daily_summary.completion_percentage = min(
            int((daily_summary.total_volume_ml / daily_summary.daily_goal_ml) * 100),
            100,
        )

        db.add(daily_summary)
        db.commit()

    async def _check_hydration_achievements(
        self, db: Session, user_id: str, daily_summary: DailySummary
    ) -> List[Dict[str, any]]:
        """Check for daily hydration achievements"""
        achievements = []

        # First Goal Achievement
        if daily_summary.goal_achieved and daily_summary.log_count == 1:
            if not self._is_achievement_unlocked(db, user_id, "FIRST_GOAL"):
                achievements.append(
                    await self._unlock_achievement(
                        db, user_id, "FIRST_GOAL", AchievementType.DAILY_GOAL
                    )
                )

        # Daily Goal Achievement
        elif daily_summary.goal_achieved:
            if not self._is_achievement_unlocked(db, user_id, "DAILY_GOAL"):
                achievements.append(
                    await self._unlock_achievement(
                        db, user_id, "DAILY_GOAL", AchievementType.DAILY_GOAL
                    )
                )

        # Overachiever (150% of goal)
        if daily_summary.total_volume_ml >= daily_summary.daily_goal_ml * 1.5:
            if not self._is_achievement_unlocked(db, user_id, "OVERACHIEVER"):
                achievements.append(
                    await self._unlock_achievement(
                        db, user_id, "OVERACHIEVER", AchievementType.DAILY_GOAL
                    )
                )

        # Hydration Hero (200% of goal)
        if daily_summary.total_volume_ml >= daily_summary.daily_goal_ml * 2.0:
            if not self._is_achievement_unlocked(db, user_id, "HYDRATION_HERO"):
                achievements.append(
                    await self._unlock_achievement(
                        db, user_id, "HYDRATION_HERO", AchievementType.DAILY_GOAL
                    )
                )

        return achievements

    async def _check_streak_achievements(
        self, db: Session, user_id: str, daily_summary: DailySummary
    ) -> List[Dict[str, any]]:
        """Check for streak-based achievements"""
        achievements = []

        if not daily_summary.goal_achieved:
            return achievements

        # Calculate current streak
        current_streak = self._calculate_current_streak(db, user_id)

        # Update user streak
        user_crud.update_stats(db, user_id=user_id, new_streak=current_streak)

        # Streak milestones
        streak_milestones = {
            3: "STREAK_3",
            7: "WEEK_WARRIOR",
            14: "STREAK_14",
            30: "MONTH_MASTER",
            60: "STREAK_60",
            100: "CENTURION",
        }

        for streak_days, achievement_key in streak_milestones.items():
            if current_streak >= streak_days:
                if not self._is_achievement_unlocked(db, user_id, achievement_key):
                    achievements.append(
                        await self._unlock_achievement(
                            db, user_id, achievement_key, AchievementType.STREAK
                        )
                    )

        return achievements

    async def _check_milestone_achievements(
        self, db: Session, user_id: str, user: User
    ) -> List[Dict[str, any]]:
        """Check for milestone achievements based on total volume"""
        achievements = []

        # Volume milestones (in liters)
        volume_milestones = {
            10: "FIRST_10_LITERS",
            50: "MILESTONE_50L",
            100: "MILESTONE_100L",
            500: "MILESTONE_500L",
            1000: "MILLENNIUM_HYDRATOR",
        }

        total_volume_l = user.total_volume_ml / 1000

        for milestone_l, achievement_key in volume_milestones.items():
            if total_volume_l >= milestone_l:
                if not self._is_achievement_unlocked(db, user_id, achievement_key):
                    achievements.append(
                        await self._unlock_achievement(
                            db, user_id, achievement_key, AchievementType.TOTAL_VOLUME
                        )
                    )

        return achievements

    async def _check_consistency_achievements(
        self, db: Session, user_id: str
    ) -> List[Dict[str, any]]:
        """Check for consistency-based achievements"""
        achievements = []

        # Check weekly consistency (7 days goal achievement)
        end_date = date.today()
        start_date = end_date - timedelta(days=6)  # Last 7 days

        week_summaries = daily_summary_crud.get_summaries_by_date_range(
            db, user_id=user_id, start_date=start_date, end_date=end_date
        )

        goals_achieved = sum(1 for summary in week_summaries if summary.goal_achieved)

        if goals_achieved >= 7:
            if not self._is_achievement_unlocked(db, user_id, "WEEKLY_CONSISTENT"):
                achievements.append(
                    await self._unlock_achievement(
                        db, user_id, "WEEKLY_CONSISTENT", AchievementType.FREQUENCY
                    )
                )

        # Check monthly consistency (28 days)
        month_start = end_date - timedelta(days=27)  # Last 28 days
        month_summaries = daily_summary_crud.get_summaries_by_date_range(
            db, user_id=user_id, start_date=month_start, end_date=end_date
        )

        month_goals = sum(1 for summary in month_summaries if summary.goal_achieved)

        if month_goals >= 28:
            if not self._is_achievement_unlocked(db, user_id, "MONTHLY_MASTER"):
                achievements.append(
                    await self._unlock_achievement(
                        db, user_id, "MONTHLY_MASTER", AchievementType.FREQUENCY
                    )
                )

        return achievements

    async def _check_level_achievements(
        self, db: Session, user_id: str, old_level: int, new_level: int
    ) -> List[Dict[str, any]]:
        """Check for level-based achievements"""
        achievements = []

        level_milestones = {
            5: "LEVEL_5",
            10: "LEVEL_10",
            20: "LEVEL_20",
            30: "LEVEL_30",
            50: "MAX_LEVEL",
        }

        for milestone_level, achievement_key in level_milestones.items():
            if new_level >= milestone_level and old_level < milestone_level:
                if not self._is_achievement_unlocked(db, user_id, achievement_key):
                    achievements.append(
                        await self._unlock_achievement(
                            db, user_id, achievement_key, AchievementType.TOTAL_VOLUME
                        )
                    )

        return achievements

    def _calculate_current_streak(self, db: Session, user_id: str) -> int:
        """Calculate current consecutive goal achievement streak"""
        current_date = date.today()
        streak = 0

        # Check backwards from today until we find a non-goal day
        for days_back in range(365):  # Max check 1 year
            check_date = current_date - timedelta(days=days_back)

            summary = daily_summary_crud.get_daily_summary(
                db, user_id=user_id, date=check_date
            )

            if summary and summary.goal_achieved:
                streak += 1
            else:
                break

        return streak

    def _is_achievement_unlocked(
        self, db: Session, user_id: str, achievement_key: str
    ) -> bool:
        """Check if user has already unlocked this achievement"""
        achievement = achievement_crud.get_user_achievement(
            db, user_id=user_id, achievement_key=achievement_key
        )
        return achievement and achievement.unlocked

    async def _unlock_achievement(
        self,
        db: Session,
        user_id: str,
        achievement_key: str,
        achievement_type: AchievementType,
    ) -> Dict[str, any]:
        """Unlock an achievement for user"""
        # Get achievement definition
        achievement_data = self._get_achievement_data(achievement_key)

        # Update achievement as unlocked
        achievement = achievement_crud.unlock_achievement(
            db, user_id=user_id, achievement_key=achievement_key
        )

        return {
            "achievement_id": achievement.id,
            "achievement_key": achievement_key,
            "achievement_type": achievement_type,
            "title": achievement_data["title"],
            "description": achievement_data["description"],
            "icon": achievement_data["icon"],
            "xp_reward": self.xp_rewards.get(achievement_type, 0),
            "unlocked_at": achievement.unlocked_at,
        }

    def _get_achievement_data(self, achievement_key: str) -> Dict[str, str]:
        """Get achievement title, description, and icon"""
        achievement_definitions = {
            # Hydration achievements
            "FIRST_GOAL": {
                "title": "Khởi đầu tuyệt vời!",
                "description": "Đạt mục tiêu hydration ngày đầu tiên",
                "icon": "🌱",
            },
            "DAILY_GOAL": {
                "title": "Mục tiêu hàng ngày",
                "description": "Hoàn thành mục tiêu hydration trong ngày",
                "icon": "🎯",
            },
            "OVERACHIEVER": {
                "title": "Siêu vượt mức",
                "description": "Đạt 150% mục tiêu trong ngày",
                "icon": "⚡",
            },
            "HYDRATION_HERO": {
                "title": "Anh hùng hydration",
                "description": "Đạt 200% mục tiêu trong ngày",
                "icon": "🦸‍♂️",
            },
            # Streak achievements
            "STREAK_3": {
                "title": "Streak 3 ngày",
                "description": "Duy trì mục tiêu 3 ngày liên tiếp",
                "icon": "🔥",
            },
            "WEEK_WARRIOR": {
                "title": "Chiến binh tuần",
                "description": "Duy trì mục tiêu 7 ngày liên tiếp",
                "icon": "⚔️",
            },
            "STREAK_14": {
                "title": "Streak 14 ngày",
                "description": "Duy trì mục tiêu 2 tuần liên tiếp",
                "icon": "🌟",
            },
            "MONTH_MASTER": {
                "title": "Bậc thầy tháng",
                "description": "Duy trì mục tiêu 30 ngày liên tiếp",
                "icon": "👑",
            },
            "STREAK_60": {
                "title": "Streak 60 ngày",
                "description": "Duy trì mục tiêu 2 tháng liên tiếp",
                "icon": "💎",
            },
            "CENTURION": {
                "title": "Centurion",
                "description": "Duy trì mục tiêu 100 ngày liên tiếp",
                "icon": "🏛️",
            },
            # Milestone achievements
            "FIRST_10_LITERS": {
                "title": "10 lít đầu tiên",
                "description": "Tích lũy 10 lít nước",
                "icon": "💧",
            },
            "MILESTONE_50L": {
                "title": "50 lít chinh phục",
                "description": "Tích lũy 50 lít nước",
                "icon": "🌊",
            },
            "MILESTONE_100L": {
                "title": "100 lít thành công",
                "description": "Tích lũy 100 lít nước",
                "icon": "🌊",
            },
            "MILESTONE_500L": {
                "title": "500 lít khủng",
                "description": "Tích lũy 500 lít nước",
                "icon": "🌊",
            },
            "MILLENNIUM_HYDRATOR": {
                "title": "Hydrator Thiên niên kỷ",
                "description": "Tích lũy 1000 lít nước",
                "icon": "🏆",
            },
            # Level achievements
            "LEVEL_5": {
                "title": "Cấp 5 đạt được",
                "description": "Đạt level 5",
                "icon": "🆙",
            },
            "LEVEL_10": {
                "title": "Cấp 10 chinh phục",
                "description": "Đạt level 10",
                "icon": "⬆️",
            },
            "LEVEL_20": {
                "title": "Cấp 20 uy lực",
                "description": "Đạt level 20",
                "icon": "🚀",
            },
            "LEVEL_30": {
                "title": "Cấp 30 siêu phàm",
                "description": "Đạt level 30",
                "icon": "✨",
            },
            "MAX_LEVEL": {
                "title": "Cấp tối đa",
                "description": "Đạt level cao nhất",
                "icon": "🏆",
            },
            # Consistency achievements
            "WEEKLY_CONSISTENT": {
                "title": "Nhất quán tuần",
                "description": "Đạt mục tiêu 7 ngày trong tuần",
                "icon": "📅",
            },
            "MONTHLY_MASTER": {
                "title": "Bậc thầy tháng",
                "description": "Đạt mục tiêu 28 ngày trong tháng",
                "icon": "📊",
            },
        }

        return achievement_definitions.get(
            achievement_key,
            {
                "title": "Achievement không xác định",
                "description": "Mô tả achievement",
                "icon": "🏅",
            },
        )


# Global achievement service instance
achievement_service = AchievementService()
