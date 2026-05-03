from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, Query
from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.daily_summary import daily_summary_crud
from app.crud.intake_log import intake_log_crud
from app.models.daily_summary import DailySummary
from app.models.intake_log import IntakeLog

router = APIRouter()


@router.get("/dashboard")
async def get_dashboard_stats(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get comprehensive dashboard statistics
    """
    today = date.today()
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)

    # Today's stats
    today_stats = intake_log_crud.get_daily_stats(db, current_user_id, today)

    # This week's stats
    week_logs = intake_log_crud.get_by_user_date_range(
        db, current_user_id, week_ago, today
    )

    week_total = sum(log.effective_volume_ml for log in week_logs)
    week_logs_count = len(week_logs)

    # This month's stats
    month_logs = intake_log_crud.get_by_user_date_range(
        db, current_user_id, month_ago, today
    )

    month_total = sum(log.effective_volume_ml for log in month_logs)
    month_logs_count = len(month_logs)

    # Calculate averages
    week_avg_daily = week_total / 7 if week_total > 0 else 0
    month_avg_daily = month_total / 30 if month_total > 0 else 0

    # Current streak calculation
    current_streak = await _calculate_current_streak(db, current_user_id)

    return {
        "today": {
            "total_effective_ml": today_stats["total_effective_ml"],
            "log_count": today_stats["log_count"],
            "total_xp_earned": today_stats["total_xp_earned"],
            "progress_percentage": 0,  # TODO: Calculate vs goal when user goals implemented
        },
        "week": {
            "total_effective_ml": week_total,
            "log_count": week_logs_count,
            "average_daily_ml": round(week_avg_daily, 1),
            "days_with_intake": len(set(log.logged_at.date() for log in week_logs)),
        },
        "month": {
            "total_effective_ml": month_total,
            "log_count": month_logs_count,
            "average_daily_ml": round(month_avg_daily, 1),
            "days_with_intake": len(set(log.logged_at.date() for log in month_logs)),
        },
        "streaks": {
            "current_streak": current_streak,
            "longest_streak": 0,  # TODO: Implement longest streak calculation
        },
    }


@router.get("/trends/daily")
async def get_daily_trends(
    days: int = Query(7, ge=1, le=365, description="Number of days to analyze"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get daily intake trends for chart visualization
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)

    # Get daily aggregated data
    daily_data = (
        db.query(
            func.date(IntakeLog.logged_at).label("date"),
            func.count(IntakeLog.id).label("log_count"),
            func.coalesce(func.sum(IntakeLog.volume_ml), 0).label("total_volume"),
            func.coalesce(func.sum(IntakeLog.effective_volume_ml), 0).label(
                "total_effective"
            ),
            func.coalesce(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp), 0).label(
                "total_xp"
            ),
            func.avg(IntakeLog.volume_ml).label("avg_volume"),
        )
        .filter(
            and_(
                IntakeLog.user_id == current_user_id,
                func.date(IntakeLog.logged_at) >= start_date,
                func.date(IntakeLog.logged_at) <= end_date,
            )
        )
        .group_by(func.date(IntakeLog.logged_at))
        .order_by(func.date(IntakeLog.logged_at))
        .all()
    )

    # Fill missing dates with zeros
    data_dict = {row.date: row for row in daily_data}

    result = []
    current_date = start_date
    while current_date <= end_date:
        if current_date in data_dict:
            row = data_dict[current_date]
            result.append(
                {
                    "date": current_date,
                    "log_count": row.log_count,
                    "total_volume_ml": row.total_volume,
                    "total_effective_ml": row.total_effective,
                    "total_xp_earned": row.total_xp,
                    "average_volume_ml": float(row.avg_volume or 0),
                }
            )
        else:
            result.append(
                {
                    "date": current_date,
                    "log_count": 0,
                    "total_volume_ml": 0,
                    "total_effective_ml": 0,
                    "total_xp_earned": 0,
                    "average_volume_ml": 0.0,
                }
            )
        current_date += timedelta(days=1)

    return {
        "period": f"{days} days",
        "start_date": start_date,
        "end_date": end_date,
        "data": result,
    }


@router.get("/trends/hourly")
async def get_hourly_patterns(
    days: int = Query(7, ge=1, le=90, description="Number of days to analyze"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get hourly intake patterns for habit analysis
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)

    # Get hourly data
    hourly_data = (
        db.query(
            func.extract("hour", IntakeLog.logged_at).label("hour"),
            func.count(IntakeLog.id).label("log_count"),
            func.coalesce(func.sum(IntakeLog.effective_volume_ml), 0).label(
                "total_effective"
            ),
            func.avg(IntakeLog.volume_ml).label("avg_volume"),
        )
        .filter(
            and_(
                IntakeLog.user_id == current_user_id,
                func.date(IntakeLog.logged_at) >= start_date,
                func.date(IntakeLog.logged_at) <= end_date,
            )
        )
        .group_by(func.extract("hour", IntakeLog.logged_at))
        .order_by(func.extract("hour", IntakeLog.logged_at))
        .all()
    )

    # Fill all 24 hours
    data_dict = {int(row.hour): row for row in hourly_data}

    result = []
    for hour in range(24):
        if hour in data_dict:
            row = data_dict[hour]
            result.append(
                {
                    "hour": hour,
                    "log_count": row.log_count,
                    "total_effective_ml": row.total_effective,
                    "average_volume_ml": float(row.avg_volume or 0),
                    "frequency_percentage": 0,  # Will calculate after getting all data
                }
            )
        else:
            result.append(
                {
                    "hour": hour,
                    "log_count": 0,
                    "total_effective_ml": 0,
                    "average_volume_ml": 0.0,
                    "frequency_percentage": 0,
                }
            )

    # Calculate frequency percentages
    total_logs = sum(item["log_count"] for item in result)
    if total_logs > 0:
        for item in result:
            item["frequency_percentage"] = round(
                (item["log_count"] / total_logs) * 100, 1
            )

    return {
        "period": f"{days} days",
        "total_logs_analyzed": total_logs,
        "most_active_hour": (
            max(result, key=lambda x: x["log_count"])["hour"]
            if total_logs > 0
            else None
        ),
        "data": result,
    }


@router.get("/liquid-types")
async def get_liquid_types_breakdown(
    days: int = Query(30, ge=1, le=365, description="Number of days to analyze"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get liquid types breakdown with trends
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)

    # Get liquid type stats
    liquid_stats = intake_log_crud.get_liquid_type_stats(
        db, current_user_id, start_date, end_date
    )

    # Calculate totals for percentages
    total_volume = sum(item["total_volume_ml"] for item in liquid_stats)
    total_effective = sum(item["total_effective_ml"] for item in liquid_stats)
    total_logs = sum(item["log_count"] for item in liquid_stats)

    # Add percentages
    for item in liquid_stats:
        item["volume_percentage"] = (
            round((item["total_volume_ml"] / total_volume) * 100, 1)
            if total_volume > 0
            else 0
        )
        item["effective_percentage"] = (
            round((item["total_effective_ml"] / total_effective) * 100, 1)
            if total_effective > 0
            else 0
        )
        item["frequency_percentage"] = (
            round((item["log_count"] / total_logs) * 100, 1) if total_logs > 0 else 0
        )

    return {
        "period": f"{days} days",
        "totals": {
            "total_volume_ml": total_volume,
            "total_effective_ml": total_effective,
            "total_logs": total_logs,
        },
        "breakdown": liquid_stats,
    }


@router.get("/goals/progress")
async def get_goal_progress(
    days: int = Query(30, ge=1, le=365, description="Number of days to analyze"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get goal achievement progress and patterns
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)

    # TODO: Get user's daily goal from user settings (default 2000ml for now)
    daily_goal_ml = 2000

    # Get daily summaries or calculate them
    daily_data = []
    current_date = start_date

    while current_date <= end_date:
        day_stats = intake_log_crud.get_daily_stats(db, current_user_id, current_date)

        effective_ml = day_stats["total_effective_ml"]
        progress_pct = (effective_ml / daily_goal_ml * 100) if daily_goal_ml > 0 else 0
        goal_achieved = progress_pct >= 100

        daily_data.append(
            {
                "date": current_date,
                "total_effective_ml": effective_ml,
                "daily_goal_ml": daily_goal_ml,
                "progress_percentage": round(progress_pct, 1),
                "goal_achieved": goal_achieved,
                "log_count": day_stats["log_count"],
            }
        )

        current_date += timedelta(days=1)

    # Calculate summary stats
    total_days = len(daily_data)
    days_achieved = sum(1 for day in daily_data if day["goal_achieved"])
    achievement_rate = (days_achieved / total_days * 100) if total_days > 0 else 0

    avg_progress = (
        sum(day["progress_percentage"] for day in daily_data) / total_days
        if total_days > 0
        else 0
    )
    avg_intake = (
        sum(day["total_effective_ml"] for day in daily_data) / total_days
        if total_days > 0
        else 0
    )

    return {
        "period": f"{days} days",
        "goal_info": {
            "daily_goal_ml": daily_goal_ml,
            "total_days_analyzed": total_days,
            "days_achieved": days_achieved,
            "achievement_rate_percentage": round(achievement_rate, 1),
        },
        "averages": {
            "average_progress_percentage": round(avg_progress, 1),
            "average_daily_intake_ml": round(avg_intake, 1),
        },
        "daily_data": daily_data,
    }


@router.get("/streaks")
async def get_streak_analytics(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get detailed streak analytics
    """
    # Current streak
    current_streak = await _calculate_current_streak(db, current_user_id)

    # TODO: Implement comprehensive streak calculation
    # This would involve analyzing all daily summaries to find:
    # - Longest streak ever
    # - Recent streaks
    # - Streak patterns

    return {
        "current_streak": current_streak,
        "longest_streak": 0,  # TODO: Implement
        "streaks_this_month": 0,  # TODO: Implement
        "streak_history": [],  # TODO: Implement
    }


@router.get("/insights")
async def get_ai_insights(
    days: int = Query(7, ge=1, le=30, description="Number of days to analyze"),
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get AI-generated insights based on intake patterns
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)

    # Get basic stats for insights
    week_logs = intake_log_crud.get_by_user_date_range(
        db, current_user_id, start_date, end_date
    )

    if not week_logs:
        return {
            "insights": [
                {
                    "type": "motivational",
                    "title": "Bắt đầu hành trình hydration!",
                    "message": "Hãy log ly nước đầu tiên để bắt đầu theo dõi sức khỏe hydration của bạn.",
                    "priority": "high",
                }
            ]
        }

    # Calculate patterns
    total_volume = sum(log.effective_volume_ml for log in week_logs)
    avg_daily = total_volume / days

    hours_with_intake = set(log.logged_at.hour for log in week_logs)
    most_common_hour = (
        max(
            hours_with_intake,
            key=lambda h: sum(1 for log in week_logs if log.logged_at.hour == h),
        )
        if hours_with_intake
        else None
    )

    liquid_types = {}
    for log in week_logs:
        liquid_types[log.liquid_type] = liquid_types.get(log.liquid_type, 0) + 1

    insights = []

    # Volume insights
    if avg_daily < 1500:
        insights.append(
            {
                "type": "warning",
                "title": "Cần uống nhiều nước hơn",
                "message": f"Trung bình {avg_daily:.0f}ml/ngày, thấp hơn khuyến nghị 2000ml.",
                "priority": "high",
            }
        )
    elif avg_daily > 3000:
        insights.append(
            {
                "type": "achievement",
                "title": "Hydration xuất sắc!",
                "message": f"Trung bình {avg_daily:.0f}ml/ngày - rất tốt cho sức khỏe!",
                "priority": "medium",
            }
        )

    # Timing insights
    if most_common_hour and most_common_hour >= 22:
        insights.append(
            {
                "type": "suggestion",
                "title": "Uống nước sớm hơn",
                "message": "Uống nước muộn có thể ảnh hưởng giấc ngủ. Thử hydrate sớm hơn trong ngày.",
                "priority": "low",
            }
        )

    # Liquid type insights
    if liquid_types.get("water", 0) / len(week_logs) < 0.7:
        insights.append(
            {
                "type": "suggestion",
                "title": "Tăng lượng nước lọc",
                "message": "Nước lọc là lựa chọn tốt nhất cho hydration hiệu quả.",
                "priority": "medium",
            }
        )

    return {"insights": insights}


# Helper functions
async def _calculate_current_streak(db: Session, user_id: str) -> int:
    """Calculate current consecutive days streak"""
    today = date.today()
    streak = 0
    current_date = today

    # TODO: This should check daily summaries with goal achievement
    # For now, just check if user has any logs each day
    while True:
        day_logs = intake_log_crud.get_by_user_and_date(db, user_id, current_date)
        if day_logs:
            streak += 1
            current_date -= timedelta(days=1)
        else:
            break

        # Prevent infinite loop
        if streak > 365:
            break

    return streak
