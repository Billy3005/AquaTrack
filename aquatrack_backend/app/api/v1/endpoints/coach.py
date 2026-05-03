import random
from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from pydantic import BaseModel
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.intake_log import intake_log_crud
from app.crud.user import user_crud

router = APIRouter()


# Pydantic models for request/response
class ChatMessage(BaseModel):
    message: str
    context: Optional[dict] = None


class CoachResponse(BaseModel):
    response: str
    suggestions: List[str] = []
    action_items: List[str] = []
    motivation_level: str = "medium"  # low, medium, high
    coaching_type: str = "general"  # reminder, encouragement, advice, achievement


class UserContext(BaseModel):
    activity_level: Optional[str] = None  # "sedentary", "light", "moderate", "intense"
    mood: Optional[str] = None  # "tired", "energetic", "stressed", "happy"
    location: Optional[str] = None  # "home", "work", "gym", "outdoor"
    weather: Optional[str] = None  # "hot", "cold", "humid", "dry"
    sleep_quality: Optional[str] = None  # "poor", "average", "good", "excellent"


class CoachingSuggestion(BaseModel):
    title: str
    message: str
    priority: str  # "low", "medium", "high", "urgent"
    category: str  # "hydration", "timing", "habit", "health"
    action: Optional[str] = None


@router.post("/chat", response_model=CoachResponse)
async def chat_with_coach(
    chat_request: ChatMessage,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Chat interface with AI Coach - context-aware responses
    """
    user_message = chat_request.message.lower().strip()
    context = chat_request.context or {}

    # Get user's recent data for context
    today = date.today()
    today_stats = intake_log_crud.get_daily_stats(db, current_user_id, today)
    recent_logs = intake_log_crud.get_recent_by_user(db, current_user_id, 5)

    # Analyze user's current state
    current_hour = datetime.now().hour
    total_today = today_stats["total_effective_ml"]
    log_count_today = today_stats["log_count"]

    # Generate contextual response
    response = await _generate_coach_response(
        user_message, context, total_today, log_count_today, current_hour, recent_logs
    )

    return response


@router.get("/suggestions", response_model=List[CoachingSuggestion])
async def get_proactive_suggestions(
    limit: int = 5,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get proactive coaching suggestions based on user patterns
    """
    today = date.today()
    current_hour = datetime.now().hour

    # Get user data
    today_stats = intake_log_crud.get_daily_stats(db, current_user_id, today)
    week_logs = intake_log_crud.get_by_user_date_range(
        db, current_user_id, today - timedelta(days=7), today
    )

    suggestions = []

    # Hydration level suggestions
    total_today = today_stats["total_effective_ml"]
    if total_today < 500 and current_hour > 12:
        suggestions.append(
            CoachingSuggestion(
                title="Cần hydration ngay!",
                message="Bạn mới uống {total_today}ml hôm nay. Hãy uống 1 ly nước lớn để bắt kịp mục tiêu!".format(
                    total_today=total_today
                ),
                priority="high",
                category="hydration",
                action="log_water",
            )
        )
    elif total_today < 1000 and current_hour > 16:
        suggestions.append(
            CoachingSuggestion(
                title="Buổi chiều cần nước",
                message="Uống thêm nước để tăng năng lượng cho buổi chiều!",
                priority="medium",
                category="hydration",
                action="log_water",
            )
        )

    # Timing suggestions
    if current_hour == 8 and today_stats["log_count"] == 0:
        suggestions.append(
            CoachingSuggestion(
                title="Khởi đầu ngày tốt lành",
                message="Uống 1 ly nước ấm để đánh thức cơ thể sau giấc ngủ dài!",
                priority="medium",
                category="timing",
                action="log_morning_water",
            )
        )
    elif current_hour == 22 and today_stats["log_count"] > 0:
        suggestions.append(
            CoachingSuggestion(
                title="Chuẩn bị nghỉ ngơi",
                message="Uống ít nước thôi để không ảnh hưởng giấc ngủ nhé!",
                priority="low",
                category="timing",
            )
        )

    # Habit building suggestions
    if len(week_logs) < 10:  # Less than 1.4 logs per day
        suggestions.append(
            CoachingSuggestion(
                title="Xây dựng thói quen",
                message="Hãy thử set nhắc nhở mỗi 2 tiếng để uống nước đều đặn hơn.",
                priority="medium",
                category="habit",
                action="set_reminders",
            )
        )

    # Achievement suggestions
    if total_today >= 2000:
        suggestions.append(
            CoachingSuggestion(
                title="Xuất sắc! 🎉",
                message="Bạn đã đạt mục tiêu hôm nay! Tiếp tục duy trì nhé!",
                priority="low",
                category="health",
            )
        )

    return suggestions[:limit]


@router.get("/nudges")
async def get_smart_nudges(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get smart nudges based on time and user patterns
    """
    current_hour = datetime.now().hour
    today_stats = intake_log_crud.get_daily_stats(db, current_user_id, date.today())

    # Time-based nudges
    nudges = []

    if 6 <= current_hour <= 8:  # Morning
        nudges.append(
            {
                "type": "morning_boost",
                "title": "Chào buổi sáng! ☀️",
                "message": "Uống nước ngay để khởi động một ngày tuyệt vời!",
                "icon": "morning_sun",
                "timing": "immediate",
            }
        )
    elif 11 <= current_hour <= 13:  # Lunch time
        nudges.append(
            {
                "type": "lunch_reminder",
                "title": "Giờ ăn trưa rồi! 🍽️",
                "message": "Nhớ uống nước trong bữa ăn để hỗ trợ tiêu hóa nhé!",
                "icon": "lunch",
                "timing": "with_meal",
            }
        )
    elif 15 <= current_hour <= 17:  # Afternoon slump
        nudges.append(
            {
                "type": "afternoon_energy",
                "title": "Tăng năng lượng chiều! ⚡",
                "message": "Uống nước thay vì cafe để tăng tập trung tự nhiên!",
                "icon": "energy_boost",
                "timing": "immediate",
            }
        )
    elif 19 <= current_hour <= 21:  # Evening
        nudges.append(
            {
                "type": "evening_wind_down",
                "title": "Buổi tối thư giãn 🌙",
                "message": "Uống trà thảo mộc hoặc nước ấm để thư giãn!",
                "icon": "evening",
                "timing": "relaxed",
            }
        )

    # Progress-based nudges
    total_today = today_stats["total_effective_ml"]
    if total_today < 800 and current_hour > 14:
        nudges.append(
            {
                "type": "catch_up",
                "title": "Thời gian bắt kịp! 🏃‍♀️",
                "message": f"Bạn cần thêm {2000 - total_today}ml để đạt mục tiêu!",
                "icon": "target",
                "timing": "urgent",
            }
        )

    return {"nudges": nudges}


@router.post("/context")
async def update_user_context(
    context: UserContext,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Update user context for personalized coaching
    """
    # TODO: Store context in database for persistent personalization
    # For now, return immediate coaching based on context

    coaching_response = await _generate_contextual_advice(context)

    return {
        "message": "Context updated successfully",
        "immediate_advice": coaching_response,
    }


@router.get("/insights")
async def get_coaching_insights(
    days: int = 7,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get data-driven coaching insights
    """
    end_date = date.today()
    start_date = end_date - timedelta(days=days - 1)

    # Get user data
    week_logs = intake_log_crud.get_by_user_date_range(
        db, current_user_id, start_date, end_date
    )

    if not week_logs:
        return {
            "insights": [
                {
                    "category": "getting_started",
                    "title": "Bắt đầu hành trình!",
                    "insight": "Chào mừng đến với AquaTrack! Hãy bắt đầu bằng việc log ly nước đầu tiên.",
                    "action": "Log nước ngay bây giờ",
                    "confidence": 1.0,
                }
            ]
        }

    insights = []

    # Pattern analysis
    hourly_patterns = {}
    for log in week_logs:
        hour = log.logged_at.hour
        hourly_patterns[hour] = hourly_patterns.get(hour, 0) + 1

    if hourly_patterns:
        peak_hour = max(hourly_patterns, key=hourly_patterns.get)
        insights.append(
            {
                "category": "habit_pattern",
                "title": "Thói quen uống nước",
                "insight": f"Bạn thường uống nước nhiều nhất vào {peak_hour}h. Hãy tận dụng thời điểm này!",
                "action": f"Set nhắc nhở vào {peak_hour}h mỗi ngày",
                "confidence": 0.8,
            }
        )

    # Volume consistency
    daily_totals = {}
    for log in week_logs:
        day = log.logged_at.date()
        daily_totals[day] = daily_totals.get(day, 0) + log.effective_volume_ml

    if len(daily_totals) >= 3:
        volumes = list(daily_totals.values())
        avg_volume = sum(volumes) / len(volumes)

        if avg_volume < 1500:
            insights.append(
                {
                    "category": "volume_improvement",
                    "title": "Tăng lượng nước",
                    "insight": f"Trung bình {avg_volume:.0f}ml/ngày. Hãy từ từ tăng lên 2000ml!",
                    "action": "Thêm 1 ly nước vào buổi sáng và chiều",
                    "confidence": 0.9,
                }
            )
        elif avg_volume > 2500:
            insights.append(
                {
                    "category": "excellent_hydration",
                    "title": "Hydration xuất sắc! 🌟",
                    "insight": f"Trung bình {avg_volume:.0f}ml/ngày - rất tốt cho sức khỏe!",
                    "action": "Duy trì thói quen tuyệt vời này",
                    "confidence": 1.0,
                }
            )

    # Liquid type diversity
    liquid_types = {}
    for log in week_logs:
        liquid_types[log.liquid_type] = liquid_types.get(log.liquid_type, 0) + 1

    if len(liquid_types) == 1 and "water" in liquid_types:
        insights.append(
            {
                "category": "variety",
                "title": "Thêm sự đa dạng",
                "insight": "Thử thêm trà xanh hoặc trà thảo mộc để đa dạng hóa hydration!",
                "action": "Log 1 cốc trà trong tuần này",
                "confidence": 0.6,
            }
        )

    return {"insights": insights}


# Helper functions
async def _generate_coach_response(
    user_message: str,
    context: dict,
    total_today: int,
    log_count: int,
    current_hour: int,
    recent_logs: list,
) -> CoachResponse:
    """Generate contextual coach response"""

    suggestions = []
    action_items = []
    motivation_level = "medium"
    coaching_type = "general"

    # Greeting responses
    if any(word in user_message for word in ["xin chào", "chào", "hello", "hi"]):
        if current_hour < 12:
            response = f"Chào buổi sáng! 🌅 Bạn đã uống {total_today}ml hôm nay. Hãy bắt đầu ngày mới với một ly nước nhé!"
        elif current_hour < 18:
            response = f"Chào buổi chiều! ☀️ Bạn đã log {log_count} lần hôm nay. Cần uống thêm nước không?"
        else:
            response = (
                f"Chào buổi tối! 🌙 Hôm nay bạn đã uống {total_today}ml. Tuyệt vời!"
            )

        coaching_type = "greeting"

    # Progress inquiries
    elif any(
        word in user_message
        for word in ["tiến độ", "progress", "how am i doing", "thế nào"]
    ):
        if total_today >= 2000:
            response = (
                f"Xuất sắc! 🎉 Bạn đã đạt {total_today}ml - vượt mục tiêu hôm nay!"
            )
            motivation_level = "high"
            coaching_type = "achievement"
        elif total_today >= 1000:
            remaining = 2000 - total_today
            response = (
                f"Tốt lắm! Còn {remaining}ml nữa là đạt mục tiêu. Cố gắng nhé! 💪"
            )
            suggestions.append("Uống 2-3 ly nước nhỏ trong 2-3 giờ tới")
        else:
            response = f"Cần cố gắng hơn! Mới {total_today}ml thôi. Hãy uống ngay 1 ly nước lớn!"
            motivation_level = "high"
            action_items.append("Uống 500ml nước ngay bây giờ")

    # Motivation requests
    elif any(
        word in user_message
        for word in ["động lực", "motivation", "encourage", "khuyến khích"]
    ):
        motivational_quotes = [
            "Mỗi giọt nước là một bước đến sức khỏe tốt hơn! 💧",
            "Cơ thể bạn cảm ơn mỗi ly nước bạn uống! 🙏",
            "Hydration là chìa khóa năng lượng và sức khỏe! ⚡",
            "Bạn đang đầu tư vào sức khỏe tương lai của mình! 🌟",
        ]
        response = random.choice(motivational_quotes)
        motivation_level = "high"
        coaching_type = "encouragement"

    # Specific questions about hydration
    elif any(
        word in user_message for word in ["bao nhiều", "how much", "uống", "drink"]
    ):
        if current_hour < 12:
            response = "Buổi sáng nên uống 500-700ml để khởi động cơ thể. Bạn có thể uống nước ấm hoặc nước lọc!"
        elif current_hour < 18:
            response = (
                "Buổi chiều nên uống 300-500ml mỗi 2-3 tiếng. Hãy nghe cơ thể mình!"
            )
        else:
            response = "Buổi tối uống vừa phải thôi, khoảng 200-300ml để không ảnh hưởng giấc ngủ."
        suggestions.append("Set timer mỗi 2 tiếng để nhắc uống nước")

    # Tired/energy questions
    elif any(word in user_message for word in ["mệt", "tired", "năng lượng", "energy"]):
        if total_today < 1000:
            response = "Mệt mỏi có thể do thiếu nước! Hãy uống 1-2 ly nước và cảm nhận sự khác biệt."
            action_items.append("Uống nước ngay để tăng năng lượng")
        else:
            response = "Bạn đã hydrate tốt rồi! Mệt mỏi có thể do thiếu ngủ hoặc stress. Hãy nghỉ ngơi!"
        coaching_type = "advice"

    # Default response
    else:
        if total_today < 500:
            response = "Hôm nay bạn cần uống nhiều nước hơn! Hãy bắt đầu ngay với 1 ly nước lớn nhé! 💧"
            motivation_level = "high"
            action_items.append("Uống 500ml nước ngay")
        elif total_today >= 2000:
            response = "Tuyệt vời! Bạn đã đạt mục tiêu hôm nay. Tôi có thể giúp gì khác không? 😊"
            motivation_level = "low"
        else:
            response = "Tiếp tục cố gắng! Bạn đang trên đường đạt mục tiêu. Có cần gợi ý gì không? 💪"

    return CoachResponse(
        response=response,
        suggestions=suggestions,
        action_items=action_items,
        motivation_level=motivation_level,
        coaching_type=coaching_type,
    )


async def _generate_contextual_advice(context: UserContext) -> str:
    """Generate advice based on user context"""
    advice = []

    if context.activity_level == "intense":
        advice.append("Với hoạt động cao, bạn cần uống thêm 500-750ml nước!")
    elif context.activity_level == "sedentary":
        advice.append("Ít vận động thì cần uống nước đều đặn để tăng tuần hoàn!")

    if context.mood == "tired":
        advice.append("Mệt mỏi có thể do thiếu nước. Uống nước để tăng năng lượng!")
    elif context.mood == "stressed":
        advice.append("Stress tăng nhu cầu nước. Uống trà thảo mộc để thư giãn!")

    if context.location == "gym":
        advice.append("Tại gym, hãy uống 150-200ml mỗi 15-20 phút!")
    elif context.location == "outdoor":
        advice.append("Ngoài trời nắng, cần hydrate nhiều hơn bình thường!")

    if context.weather == "hot":
        advice.append("Thời tiết nóng cần tăng 20-30% lượng nước!")
    elif context.weather == "cold":
        advice.append("Trời lạnh vẫn cần uống đủ nước, thử nước ấm!")

    return (
        " ".join(advice) if advice else "Hãy tiếp tục duy trì thói quen uống nước tốt!"
    )
