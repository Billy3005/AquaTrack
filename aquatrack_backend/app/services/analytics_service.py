"""
Advanced Analytics Service for Personalized AI Coaching
Analyzes user patterns, behavior, and preferences for enhanced coaching
"""

import statistics
from datetime import datetime, date, timedelta
from typing import Dict, List, Optional, Tuple
from collections import defaultdict, Counter

from sqlalchemy.orm import Session
from sqlalchemy import func, and_

from app.crud.intake_log import intake_log_crud
from app.crud.user import user_crud
from app.models.intake_log import IntakeLog
from app.models.user import User


class AnalyticsService:
    """
    Advanced analytics service for personalized AI coaching
    Provides deep insights into user behavior patterns
    """

    def __init__(self):
        """Initialize analytics service"""
        self.analysis_window_days = 30  # Default analysis window

    async def get_user_analytics_profile(
        self,
        db: Session,
        user_id: str,
        days: int = 30
    ) -> Dict:
        """
        Generate comprehensive user analytics profile for AI coaching
        """
        end_date = date.today()
        start_date = end_date - timedelta(days=days)

        # Get user and logs data
        user = user_crud.get(db, id=user_id)
        if not user:
            return self._get_default_profile()

        logs = intake_log_crud.get_by_user_date_range(
            db, user_id=user_id, start_date=start_date, end_date=end_date
        )

        if not logs:
            return self._get_new_user_profile(user)

        # Generate comprehensive profile
        profile = {
            "user_segment": self._classify_user_segment(logs, days),
            "hydration_patterns": self._analyze_hydration_patterns(logs),
            "timing_preferences": self._analyze_timing_preferences(logs),
            "liquid_preferences": self._analyze_liquid_preferences(logs),
            "consistency_metrics": self._analyze_consistency(logs, days),
            "goal_achievement": self._analyze_goal_achievement(logs, user.daily_goal_ml),
            "behavioral_insights": self._analyze_behavior(logs, days),
            "coaching_recommendations": self._generate_coaching_recommendations(logs, user),
            "personalization_context": self._build_personalization_context(logs, user),
            "risk_factors": self._identify_risk_factors(logs, user, days)
        }

        return profile

    def _classify_user_segment(self, logs: List[IntakeLog], days: int) -> Dict:
        """Classify user into behavioral segments"""
        total_logs = len(logs)
        avg_daily_logs = total_logs / days if days > 0 else 0

        # Calculate engagement metrics
        days_with_logs = len(set(log.logged_at.date() for log in logs))
        engagement_rate = (days_with_logs / days) * 100 if days > 0 else 0

        # Daily volumes
        daily_volumes = defaultdict(int)
        for log in logs:
            daily_volumes[log.logged_at.date()] += log.effective_volume_ml

        avg_daily_volume = statistics.mean(daily_volumes.values()) if daily_volumes else 0

        # Segment classification
        if engagement_rate >= 80 and avg_daily_volume >= 2000:
            segment = "champion"
        elif engagement_rate >= 60 and avg_daily_volume >= 1500:
            segment = "consistent_achiever"
        elif engagement_rate >= 40 and avg_daily_volume >= 1000:
            segment = "developing_habit"
        elif engagement_rate >= 20:
            segment = "occasional_tracker"
        else:
            segment = "needs_motivation"

        return {
            "segment": segment,
            "engagement_rate": round(engagement_rate, 1),
            "avg_daily_logs": round(avg_daily_logs, 1),
            "avg_daily_volume": round(avg_daily_volume),
            "active_days": days_with_logs
        }

    def _analyze_hydration_patterns(self, logs: List[IntakeLog]) -> Dict:
        """Analyze hydration patterns and trends"""
        if not logs:
            return {}

        # Daily pattern analysis
        daily_volumes = defaultdict(int)
        for log in logs:
            daily_volumes[log.logged_at.date()] += log.effective_volume_ml

        volumes = list(daily_volumes.values())

        # Volume statistics
        volume_stats = {
            "average": round(statistics.mean(volumes)),
            "median": round(statistics.median(volumes)),
            "std_dev": round(statistics.stdev(volumes)) if len(volumes) > 1 else 0,
            "min": min(volumes),
            "max": max(volumes),
            "consistency_score": self._calculate_consistency_score(volumes)
        }

        # Trend analysis (last 7 days vs previous 7 days)
        recent_logs = [log for log in logs if log.logged_at.date() >= date.today() - timedelta(days=7)]
        previous_logs = [log for log in logs
                        if log.logged_at.date() < date.today() - timedelta(days=7)
                        and log.logged_at.date() >= date.today() - timedelta(days=14)]

        recent_avg = statistics.mean([log.effective_volume_ml for log in recent_logs]) if recent_logs else 0
        previous_avg = statistics.mean([log.effective_volume_ml for log in previous_logs]) if previous_logs else 0

        trend = "improving" if recent_avg > previous_avg * 1.1 else \
                "declining" if recent_avg < previous_avg * 0.9 else "stable"

        return {
            "volume_stats": volume_stats,
            "trend": trend,
            "trend_change": round(((recent_avg - previous_avg) / previous_avg * 100) if previous_avg > 0 else 0, 1)
        }

    def _analyze_timing_preferences(self, logs: List[IntakeLog]) -> Dict:
        """Analyze when user prefers to drink water"""
        if not logs:
            return {}

        # Hourly distribution
        hourly_count = Counter(log.logged_at.hour for log in logs)

        # Find peak hours
        if hourly_count:
            peak_hour = hourly_count.most_common(1)[0][0]
            peak_period = self._get_time_period(peak_hour)
        else:
            peak_hour = 12
            peak_period = "afternoon"

        # Time period distribution
        morning_count = sum(count for hour, count in hourly_count.items() if 6 <= hour < 12)
        afternoon_count = sum(count for hour, count in hourly_count.items() if 12 <= hour < 18)
        evening_count = sum(count for hour, count in hourly_count.items() if 18 <= hour < 22)
        night_count = sum(count for hour, count in hourly_count.items() if hour >= 22 or hour < 6)

        total = len(logs)
        period_distribution = {
            "morning": round((morning_count / total) * 100, 1) if total > 0 else 0,
            "afternoon": round((afternoon_count / total) * 100, 1) if total > 0 else 0,
            "evening": round((evening_count / total) * 100, 1) if total > 0 else 0,
            "night": round((night_count / total) * 100, 1) if total > 0 else 0
        }

        return {
            "peak_hour": peak_hour,
            "peak_period": peak_period,
            "period_distribution": period_distribution,
            "most_active_periods": self._get_most_active_periods(period_distribution)
        }

    def _analyze_liquid_preferences(self, logs: List[IntakeLog]) -> Dict:
        """Analyze liquid type preferences"""
        if not logs:
            return {}

        liquid_count = Counter(log.liquid_type for log in logs)
        total = len(logs)

        preferences = {
            liquid_type: {
                "count": count,
                "percentage": round((count / total) * 100, 1)
            }
            for liquid_type, count in liquid_count.most_common()
        }

        diversity_score = len(liquid_count) / 6 * 100  # Assuming 6 main liquid types

        return {
            "preferences": preferences,
            "diversity_score": min(round(diversity_score, 1), 100),
            "most_preferred": liquid_count.most_common(1)[0][0] if liquid_count else "water"
        }

    def _analyze_consistency(self, logs: List[IntakeLog], days: int) -> Dict:
        """Analyze user consistency patterns"""
        if not logs or days == 0:
            return {}

        # Daily logging consistency
        dates_with_logs = set(log.logged_at.date() for log in logs)
        consistency_rate = (len(dates_with_logs) / days) * 100

        # Weekly pattern consistency
        weekly_patterns = defaultdict(list)
        for log in logs:
            week_start = log.logged_at.date() - timedelta(days=log.logged_at.weekday())
            weekly_patterns[week_start].append(log.effective_volume_ml)

        weekly_consistency = 0
        if len(weekly_patterns) > 1:
            weekly_volumes = [sum(volumes) for volumes in weekly_patterns.values()]
            weekly_consistency = 100 - (statistics.stdev(weekly_volumes) / statistics.mean(weekly_volumes) * 100) if weekly_volumes else 0
            weekly_consistency = max(0, min(100, weekly_consistency))

        return {
            "daily_consistency": round(consistency_rate, 1),
            "weekly_consistency": round(weekly_consistency, 1),
            "active_days": len(dates_with_logs),
            "streak_potential": self._calculate_streak_potential(logs)
        }

    def _analyze_goal_achievement(self, logs: List[IntakeLog], daily_goal: int) -> Dict:
        """Analyze goal achievement patterns"""
        if not logs:
            return {}

        # Daily goal achievement
        daily_volumes = defaultdict(int)
        for log in logs:
            daily_volumes[log.logged_at.date()] += log.effective_volume_ml

        achievement_days = sum(1 for volume in daily_volumes.values() if volume >= daily_goal)
        total_days = len(daily_volumes)
        achievement_rate = (achievement_days / total_days) * 100 if total_days > 0 else 0

        # Achievement trend (last week vs previous week)
        last_week_days = [date for date in daily_volumes.keys()
                         if date >= date.today() - timedelta(days=7)]
        prev_week_days = [date for date in daily_volumes.keys()
                         if date >= date.today() - timedelta(days=14)
                         and date < date.today() - timedelta(days=7)]

        last_week_achievement = sum(1 for d in last_week_days if daily_volumes[d] >= daily_goal)
        prev_week_achievement = sum(1 for d in prev_week_days if daily_volumes[d] >= daily_goal)

        last_week_rate = (last_week_achievement / len(last_week_days)) * 100 if last_week_days else 0
        prev_week_rate = (prev_week_achievement / len(prev_week_days)) * 100 if prev_week_days else 0

        trend = "improving" if last_week_rate > prev_week_rate else \
                "declining" if last_week_rate < prev_week_rate else "stable"

        return {
            "overall_achievement_rate": round(achievement_rate, 1),
            "achievement_days": achievement_days,
            "total_tracked_days": total_days,
            "recent_trend": trend,
            "weekly_comparison": {
                "last_week": round(last_week_rate, 1),
                "previous_week": round(prev_week_rate, 1)
            }
        }

    def _analyze_behavior(self, logs: List[IntakeLog], days: int) -> Dict:
        """Analyze behavioral patterns"""
        if not logs:
            return {}

        # Volume per log analysis
        volumes_per_log = [log.effective_volume_ml for log in logs]
        avg_volume_per_log = statistics.mean(volumes_per_log)

        # Frequency analysis
        daily_log_counts = defaultdict(int)
        for log in logs:
            daily_log_counts[log.logged_at.date()] += 1

        avg_logs_per_day = statistics.mean(daily_log_counts.values()) if daily_log_counts else 0

        # Behavioral classification
        if avg_volume_per_log >= 400:
            drinking_style = "large_portions"
        elif avg_volume_per_log >= 200:
            drinking_style = "moderate_portions"
        else:
            drinking_style = "frequent_small_sips"

        return {
            "avg_volume_per_log": round(avg_volume_per_log),
            "avg_logs_per_day": round(avg_logs_per_day, 1),
            "drinking_style": drinking_style,
            "total_interactions": len(logs)
        }

    def _generate_coaching_recommendations(self, logs: List[IntakeLog], user: User) -> List[Dict]:
        """Generate personalized coaching recommendations"""
        recommendations = []

        # Analyze patterns for recommendations
        daily_volumes = defaultdict(int)
        hourly_counts = Counter()

        for log in logs:
            daily_volumes[log.logged_at.date()] += log.effective_volume_ml
            hourly_counts[log.logged_at.hour] += 1

        # Volume-based recommendations
        volumes = list(daily_volumes.values())
        if volumes:
            avg_volume = statistics.mean(volumes)
            if avg_volume < user.daily_goal_ml * 0.7:
                recommendations.append({
                    "type": "volume_increase",
                    "priority": "high",
                    "message": "Tăng từ từ lượng nước mỗi ngày",
                    "action": "Thêm 200ml vào buổi sáng và chiều"
                })

        # Timing-based recommendations
        if hourly_counts:
            morning_logs = sum(count for hour, count in hourly_counts.items() if 6 <= hour < 12)
            if morning_logs < len(logs) * 0.3:
                recommendations.append({
                    "type": "morning_hydration",
                    "priority": "medium",
                    "message": "Tăng cường uống nước buổi sáng",
                    "action": "Uống 1 ly nước ngay sau khi thức dậy"
                })

        # Consistency-based recommendations
        active_days = len(set(log.logged_at.date() for log in logs))
        if active_days < 21:  # Less than 21 days in last 30
            recommendations.append({
                "type": "consistency_improvement",
                "priority": "high",
                "message": "Xây dựng thói quen tracking đều đặn",
                "action": "Set reminder mỗi 3 tiếng để log nước"
            })

        return recommendations

    def _build_personalization_context(self, logs: List[IntakeLog], user: User) -> Dict:
        """Build context for AI personalization"""
        if not logs:
            return {}

        # Recent performance
        recent_logs = [log for log in logs if log.logged_at.date() >= date.today() - timedelta(days=7)]
        recent_volume = sum(log.effective_volume_ml for log in recent_logs)
        recent_days = len(set(log.logged_at.date() for log in recent_logs))
        recent_avg = recent_volume / recent_days if recent_days > 0 else 0

        # Behavioral indicators
        preferred_times = self._get_preferred_drinking_times(logs)
        motivation_indicators = self._assess_motivation_level(logs, user)

        return {
            "recent_performance": {
                "avg_daily_volume": round(recent_avg),
                "days_active": recent_days,
                "goal_gap": max(0, user.daily_goal_ml - recent_avg)
            },
            "preferred_times": preferred_times,
            "motivation_indicators": motivation_indicators,
            "coaching_style_preference": self._determine_coaching_style(logs, user)
        }

    def _identify_risk_factors(self, logs: List[IntakeLog], user: User, days: int) -> List[Dict]:
        """Identify potential risk factors for goal achievement"""
        risks = []

        # Low engagement risk
        active_days = len(set(log.logged_at.date() for log in logs))
        if active_days < days * 0.5:
            risks.append({
                "type": "low_engagement",
                "severity": "high",
                "description": "Ít tương tác với app",
                "mitigation": "Tăng frequency của notifications"
            })

        # Declining trend risk
        recent_logs = [log for log in logs if log.logged_at.date() >= date.today() - timedelta(days=7)]
        older_logs = [log for log in logs
                     if log.logged_at.date() < date.today() - timedelta(days=7)
                     and log.logged_at.date() >= date.today() - timedelta(days=14)]

        if recent_logs and older_logs:
            recent_avg = statistics.mean([log.effective_volume_ml for log in recent_logs])
            older_avg = statistics.mean([log.effective_volume_ml for log in older_logs])

            if recent_avg < older_avg * 0.8:
                risks.append({
                    "type": "declining_intake",
                    "severity": "medium",
                    "description": "Lượng nước giảm dần",
                    "mitigation": "Intervention coaching cần thiết"
                })

        return risks

    # Helper methods
    def _get_default_profile(self) -> Dict:
        """Default profile for users without data"""
        return {
            "user_segment": {"segment": "new_user"},
            "hydration_patterns": {},
            "timing_preferences": {},
            "liquid_preferences": {},
            "consistency_metrics": {},
            "goal_achievement": {},
            "behavioral_insights": {},
            "coaching_recommendations": [
                {
                    "type": "getting_started",
                    "priority": "high",
                    "message": "Chào mừng đến AquaTrack!",
                    "action": "Bắt đầu với 1 ly nước ngay bây giờ"
                }
            ],
            "personalization_context": {},
            "risk_factors": []
        }

    def _get_new_user_profile(self, user: User) -> Dict:
        """Profile for new users with account but no logs"""
        return {
            "user_segment": {"segment": "new_user"},
            "coaching_recommendations": [
                {
                    "type": "onboarding",
                    "priority": "high",
                    "message": f"Hãy bắt đầu hành trình hydration với mục tiêu {user.daily_goal_ml}ml!",
                    "action": "Log ly nước đầu tiên"
                }
            ]
        }

    def _get_time_period(self, hour: int) -> str:
        """Convert hour to time period"""
        if 6 <= hour < 12:
            return "morning"
        elif 12 <= hour < 18:
            return "afternoon"
        elif 18 <= hour < 22:
            return "evening"
        else:
            return "night"

    def _get_most_active_periods(self, distribution: Dict) -> List[str]:
        """Get periods with highest activity"""
        sorted_periods = sorted(distribution.items(), key=lambda x: x[1], reverse=True)
        return [period for period, percentage in sorted_periods if percentage > 20]

    def _calculate_consistency_score(self, volumes: List[int]) -> float:
        """Calculate consistency score (0-100)"""
        if len(volumes) < 2:
            return 100.0

        mean_volume = statistics.mean(volumes)
        if mean_volume == 0:
            return 0.0

        coefficient_of_variation = statistics.stdev(volumes) / mean_volume
        consistency = max(0, 100 - (coefficient_of_variation * 100))
        return round(consistency, 1)

    def _calculate_streak_potential(self, logs: List[IntakeLog]) -> int:
        """Calculate potential streak days based on recent activity"""
        if not logs:
            return 0

        # Sort logs by date
        dates = sorted(set(log.logged_at.date() for log in logs))
        current_streak = 0
        max_streak = 0

        for i, date_val in enumerate(dates):
            if i == 0:
                current_streak = 1
            elif (date_val - dates[i-1]).days == 1:
                current_streak += 1
            else:
                current_streak = 1

            max_streak = max(max_streak, current_streak)

        return max_streak

    def _get_preferred_drinking_times(self, logs: List[IntakeLog]) -> List[int]:
        """Get user's preferred drinking times"""
        hourly_counts = Counter(log.logged_at.hour for log in logs)
        if not hourly_counts:
            return []

        # Return top 3 preferred hours
        return [hour for hour, count in hourly_counts.most_common(3)]

    def _assess_motivation_level(self, logs: List[IntakeLog], user: User) -> Dict:
        """Assess user's motivation level indicators"""
        if not logs:
            return {"level": "unknown"}

        # Recent activity trend
        recent_days = 7
        recent_logs = [log for log in logs
                      if log.logged_at.date() >= date.today() - timedelta(days=recent_days)]

        activity_score = len(set(log.logged_at.date() for log in recent_logs)) / recent_days * 100

        if activity_score >= 80:
            level = "high"
        elif activity_score >= 50:
            level = "medium"
        else:
            level = "low"

        return {
            "level": level,
            "activity_score": round(activity_score, 1),
            "recent_engagement": len(recent_logs)
        }

    def _determine_coaching_style(self, logs: List[IntakeLog], user: User) -> str:
        """Determine preferred coaching style based on user behavior"""
        if not logs:
            return "encouraging"

        # Analyze response to different coaching approaches
        # This is a simplified version - in practice, you'd track response to different message types

        daily_volumes = defaultdict(int)
        for log in logs:
            daily_volumes[log.logged_at.date()] += log.effective_volume_ml

        volumes = list(daily_volumes.values())
        if not volumes:
            return "encouraging"

        avg_achievement = statistics.mean(volumes) / user.daily_goal_ml

        if avg_achievement >= 1.0:
            return "supportive"  # Already achieving goals, supportive approach
        elif avg_achievement >= 0.7:
            return "encouraging"  # Close to goals, encouraging approach
        else:
            return "motivational"  # Far from goals, strong motivation needed


# Global service instance
analytics_service = AnalyticsService()