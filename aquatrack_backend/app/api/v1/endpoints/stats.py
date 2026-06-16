import asyncio
import json
import logging
import re
import time
from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.intake_log import intake_log_crud
from app.crud.user import user_crud
from app.models.intake_log import IntakeLog

router = APIRouter()
logger = logging.getLogger(__name__)

# In-memory insight cache to cap Claude calls (cost control). Keyed by
# user+period; a result is reused while the data "signature" is unchanged and
# the entry is younger than the TTL. Resets on redeploy — acceptable, the goal
# is just to avoid calling Claude on every Stats screen open.
_INSIGHT_CACHE: dict = {}
_INSIGHT_TTL_SECONDS = 6 * 3600


def _insight_signature(num_logs: int, avg_daily: float, top_liquid: str) -> str:
    """Changes only when the stats meaningfully change (avg bucketed to 50ml)."""
    return f"{num_logs}:{round(avg_daily / 50) * 50}:{top_liquid}"


def _generate_insights_via_claude(
    *,
    avg_daily: float,
    days: int,
    num_logs: int,
    liquid_types: dict,
    most_common_hour,
    daily_goal_ml: int,
) -> list | None:
    """Ask the cheapest Claude model for 2-3 personalised insights.

    Returns None on any failure so the caller can fall back to rules.
    """
    if not settings.ANTHROPIC_API_KEY:
        return None
    try:
        import anthropic

        client = anthropic.Anthropic(api_key=settings.ANTHROPIC_API_KEY)
        water_share = liquid_types.get("water", 0) / max(num_logs, 1)
        prompt = (
            "Dữ liệu hydration của người dùng:\n"
            f"- Trung bình: {avg_daily:.0f}ml/ngày (mục tiêu {daily_goal_ml}ml)\n"
            f"- Số lần uống trong {days} ngày: {num_logs}\n"
            f"- Tỉ lệ nước lọc: {water_share * 100:.0f}%\n"
            f"- Giờ uống nhiều nhất: {most_common_hour}h\n"
            f"- Phân bố loại nước: {liquid_types}\n\n"
            "Tạo 2-3 insight cá nhân hoá, NGẮN GỌN, tiếng Việt tự nhiên. "
            'Trả về DUY NHẤT một mảng JSON, mỗi phần tử: {"type","title","message","priority"}. '
            "type ∈ warning|suggestion|achievement|motivational; "
            "priority ∈ high|medium|low. title ≤ 6 từ, message ≤ 1 câu. "
            "Không thêm chữ nào ngoài JSON."
        )
        resp = client.messages.create(
            model=settings.INSIGHTS_MODEL,
            max_tokens=400,
            temperature=0.5,
            system=(
                "Bạn là chuyên gia hydration của AquaTrack. Phân tích số liệu và "
                "đưa lời khuyên thực tế, động viên, bằng tiếng Việt. Chỉ trả JSON."
            ),
            messages=[{"role": "user", "content": prompt}],
        )
        text = resp.content[0].text.strip()
        # Tolerate code fences / stray prose around the JSON array
        match = re.search(r"\[.*\]", text, re.DOTALL)
        if not match:
            return None
        parsed = json.loads(match.group(0))
        insights = []
        for item in parsed[:3]:
            if not isinstance(item, dict) or "message" not in item:
                continue
            insights.append(
                {
                    "type": str(item.get("type", "suggestion")),
                    "title": str(item.get("title", "Gợi ý"))[:60],
                    "message": str(item["message"])[:200],
                    "priority": str(item.get("priority", "medium")),
                }
            )
        return insights or None
    except Exception:
        logger.exception("Claude insight generation failed — falling back to rules")
        return None


def _rule_based_insights(
    *,
    avg_daily: float,
    num_logs: int,
    most_common_hour,
    liquid_types: dict,
) -> list:
    """Deterministic fallback when Claude is unavailable."""
    insights = []
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
    if most_common_hour and most_common_hour >= 22:
        insights.append(
            {
                "type": "suggestion",
                "title": "Uống nước sớm hơn",
                "message": "Uống nước muộn có thể ảnh hưởng giấc ngủ. Thử hydrate sớm hơn trong ngày.",
                "priority": "low",
            }
        )
    if liquid_types.get("water", 0) / max(num_logs, 1) < 0.7:
        insights.append(
            {
                "type": "suggestion",
                "title": "Tăng lượng nước lọc",
                "message": "Nước lọc là lựa chọn tốt nhất cho hydration hiệu quả.",
                "priority": "medium",
            }
        )
    return insights


@router.get("/dashboard")
async def get_dashboard_stats(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get comprehensive dashboard statistics with real user data
    """
    # Get user for daily goal and streak data
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    today = date.today()
    week_ago = today - timedelta(days=7)
    month_ago = today - timedelta(days=30)

    # Today's stats
    today_stats = intake_log_crud.get_daily_stats(db, current_user_id, today)

    # Calculate today's progress vs user's daily goal
    today_volume = today_stats["total_effective_ml"]
    daily_goal = user.daily_goal_ml
    progress_percentage = (
        min(100, round((today_volume / daily_goal) * 100, 1)) if daily_goal > 0 else 0
    )

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

    # Real streak calculation based on goal achievement
    current_streak = await _calculate_current_streak(db, current_user_id, daily_goal)

    return {
        "today": {
            "total_effective_ml": today_volume,
            "log_count": today_stats["log_count"],
            "total_xp_earned": today_stats["total_xp_earned"],
            "progress_percentage": progress_percentage,  # Real progress vs user goal!
            "daily_goal_ml": daily_goal,  # Include user's daily goal
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
            "current_streak": current_streak,  # Real streak based on goal achievement
            "longest_streak": user.longest_streak,  # From user model!
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

    # DEBUG: Print date range
    print(
        f"🧪 [DEBUG] Trends query: {start_date} to {end_date} for user {current_user_id}"
    )

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

    # DEBUG: Print actual data found
    print(f"🧪 [DEBUG] Trends API - Found {len(daily_data)} data rows")
    for row in daily_data:
        print(
            f"🧪 [DEBUG] Row: {row.date} ({type(row.date)}) - {row.total_volume}ml total"
        )
    print(f"🧪 [DEBUG] Date dict keys: {list(data_dict.keys())}")

    result = []
    current_date = start_date
    while current_date <= end_date:
        # Ensure current_date is same type as data_dict keys
        check_date = current_date
        print(
            f"🧪 [DEBUG] Checking date: {check_date} ({type(check_date)}) - in dict: {check_date in data_dict}"
        )
        if check_date in data_dict:
            row = data_dict[check_date]
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

    # Get user's daily goal from database
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    daily_goal_ml = user.daily_goal_ml

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
    Get detailed streak analytics with real user data
    """
    # Get user for daily goal and streak data
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    # Current streak based on goal achievement
    current_streak = await _calculate_current_streak(
        db, current_user_id, user.daily_goal_ml
    )

    # Real longest streak from user model
    longest_streak = user.longest_streak

    return {
        "current_streak": current_streak,
        "longest_streak": longest_streak,  # Real data from user model!
        "streaks_this_month": 0,  # TODO: Implement
        "streak_history": [],  # TODO: Implement
        "daily_goal_ml": user.daily_goal_ml,  # Include user's goal for reference
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

    # Real AI insights via the cheapest Claude model, cached per user+period and
    # only regenerated when the data signature changes or the TTL lapses — so
    # repeatedly opening Stats does NOT keep spending tokens.
    top_liquid = max(liquid_types, key=liquid_types.get) if liquid_types else "water"
    sig = _insight_signature(len(week_logs), avg_daily, top_liquid)
    cache_key = f"{current_user_id}:{days}"
    cached = _INSIGHT_CACHE.get(cache_key)
    now = time.monotonic()
    if cached and cached["sig"] == sig and (now - cached["ts"]) < _INSIGHT_TTL_SECONDS:
        return {"insights": cached["insights"]}

    user = user_crud.get(db, id=current_user_id)
    daily_goal_ml = user.daily_goal_ml if user else 2000

    insights = await asyncio.to_thread(
        _generate_insights_via_claude,
        avg_daily=avg_daily,
        days=days,
        num_logs=len(week_logs),
        liquid_types=liquid_types,
        most_common_hour=most_common_hour,
        daily_goal_ml=daily_goal_ml,
    )
    if not insights:
        insights = _rule_based_insights(
            avg_daily=avg_daily,
            num_logs=len(week_logs),
            most_common_hour=most_common_hour,
            liquid_types=liquid_types,
        )

    _INSIGHT_CACHE[cache_key] = {"insights": insights, "ts": now, "sig": sig}
    return {"insights": insights}


# Helper functions
async def _calculate_current_streak(
    db: Session, user_id: str, daily_goal_ml: int
) -> int:
    """Calculate current consecutive days streak based on goal achievement"""
    today = date.today()
    streak = 0
    current_date = today

    # Check each day working backwards from today
    while True:
        # Get daily stats for this date
        day_stats = intake_log_crud.get_daily_stats(db, user_id, current_date)
        daily_volume = day_stats["total_effective_ml"]

        # Check if user achieved their daily goal
        if daily_volume >= daily_goal_ml:
            streak += 1
            current_date -= timedelta(days=1)
        else:
            # Streak broken - stop counting
            break

        # Prevent infinite loop (max 1 year streak)
        if streak > 365:
            break

    return streak
