#!/usr/bin/env python3
"""
Simple FastAPI server for AquaTrack testing
"""

import json
from datetime import datetime, timedelta
from typing import Any, Dict, List

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI(title="AquaTrack Simple Server")

# CORS settings
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:8000",
        "http://localhost:8080",
        "http://localhost:64038",
        "http://127.0.0.1:64038",
        "*",
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Simple data storage (in memory)
drink_logs = []
user_stats = {"daily_goal": 2000, "current_intake": 850, "streak": 5, "level": 3}


class LoginRequest(BaseModel):
    email: str
    password: str


class RegisterRequest(BaseModel):
    email: str
    password: str
    username: str = None
    full_name: str = None


class DrinkLog(BaseModel):
    container_type: str
    amount: int
    liquid_type: str = "water"
    notes: str = ""


@app.get("/api/v1/ping")
async def ping():
    return {"message": "pong", "status": "AquaTrack server working"}


@app.post("/api/v1/auth/login")
async def login(request: LoginRequest):
    """Simple login endpoint"""
    print(f"Login request: {request.email}")

    if request.email == "demo@aquatrack.com" and request.password == "demo123":
        return {
            "access_token": "mock_access_token_for_testing",
            "refresh_token": "mock_refresh_token_for_testing",
            "token_type": "bearer",
            "expires_in": 3600,
            "user": {
                "id": "1",  # String instead of int
                "email": "demo@aquatrack.com",
                "username": "demo_user",
                "full_name": "Demo User",
                "level": 3,
                "total_xp": 1500,
                "daily_goal_ml": 2000,
                "notifications_enabled": True,
                "theme_preference": "auto",
                "language_preference": "vi",
                "sound_enabled": True,
                "timezone": "Asia/Ho_Chi_Minh",
                "created_at": "2024-01-01T00:00:00Z",
                "last_active_at": datetime.now().isoformat() + "Z",
            },
        }

    raise HTTPException(status_code=401, detail="Invalid credentials")


@app.post("/api/v1/auth/register")
async def register(request: RegisterRequest):
    """Simple register endpoint"""
    return {
        "access_token": "mock_access_token_new_user",
        "refresh_token": "mock_refresh_token_new_user",
        "token_type": "bearer",
        "expires_in": 3600,
        "user": {
            "id": "2",  # String instead of int
            "email": request.email,
            "username": request.username or "new_user",
            "full_name": request.full_name or "New User",
            "level": 1,
            "total_xp": 0,
            "daily_goal_ml": 2000,
            "notifications_enabled": True,
            "theme_preference": "auto",
            "language_preference": "vi",
            "sound_enabled": True,
            "timezone": "Asia/Ho_Chi_Minh",
            "created_at": datetime.now().isoformat() + "Z",
            "last_active_at": datetime.now().isoformat() + "Z",
        },
    }


@app.post("/api/v1/drinks")
async def log_drink(drink: DrinkLog):
    """Log a new drink"""
    new_log = {
        "id": len(drink_logs) + 1,
        "container_type": drink.container_type,
        "amount": drink.amount,
        "liquid_type": drink.liquid_type,
        "notes": drink.notes,
        "timestamp": datetime.now().isoformat(),
        "user_id": 1,
    }

    drink_logs.append(new_log)

    # Update stats
    user_stats["current_intake"] += drink.amount

    return new_log


@app.get("/api/v1/drinks")
async def get_drinks():
    """Get drink history"""
    return {"drinks": drink_logs, "total": len(drink_logs)}


@app.get("/api/v1/stats")
async def get_stats():
    """Get user hydration stats"""
    return user_stats


@app.get("/api/v1/user/profile")
async def get_profile():
    """Get user profile"""
    return {
        "id": "1",
        "email": "demo@aquatrack.com",
        "username": "demo_user",
        "full_name": "Demo User",
        "level": user_stats["level"],
        "total_xp": 1500,
        "daily_goal_ml": user_stats["daily_goal"],
        "notifications_enabled": True,
        "theme_preference": "auto",
        "language_preference": "vi",
        "sound_enabled": True,
        "timezone": "Asia/Ho_Chi_Minh",
        "created_at": "2024-01-01T00:00:00Z",
        "last_active_at": datetime.now().isoformat() + "Z",
    }


# Additional endpoints for complete app functionality


@app.get("/api/v1/intake/summary/today")
async def get_today_summary():
    """Get today's intake summary"""
    return {
        "total_ml": user_stats["current_intake"],
        "goal_ml": user_stats["daily_goal"],
        "percentage": round(
            (user_stats["current_intake"] / user_stats["daily_goal"]) * 100, 1
        ),
        "drinks_count": len(drink_logs),
        "streak": user_stats["streak"],
    }


@app.get("/api/v1/coach/conversation/sessions")
async def get_conversation_sessions(skip: int = 0, limit: int = 10):
    """Get AI coach conversation sessions"""
    return {"sessions": [], "total": 0, "skip": skip, "limit": limit}


@app.get("/api/v1/levels/current")
async def get_current_level():
    """Get current user level info"""
    current_xp = 1500
    xp_for_next = 2000
    return {
        "current_level": user_stats["level"],
        "current_xp": current_xp,
        "xp_for_next_level": xp_for_next,
        "xp_to_next_level": xp_for_next - current_xp,
        "level_progress_percentage": round((current_xp / xp_for_next) * 100, 1),
        "total_xp_earned": 1500,
    }


@app.get("/api/v1/levels/achievements")
async def get_achievements():
    """Get user achievements"""
    return [
        {
            "id": "first_drink",
            "title": "First Drop",
            "description": "Log your first drink",
            "icon": "🥇",
            "type": "milestone",
            "rarity": "common",
            "current_value": 1,
            "required_value": 1,
            "progress_percentage": 100,
            "is_unlocked": True,
            "is_claimed": True,
            "xp_reward": 10,
            "unlock_avatar_id": None,
        },
        {
            "id": "week_streak",
            "title": "Week Warrior",
            "description": "Maintain a 7-day streak",
            "icon": "🔥",
            "type": "streak",
            "rarity": "rare",
            "current_value": 7,
            "required_value": 7,
            "progress_percentage": 100,
            "is_unlocked": True,
            "is_claimed": True,
            "xp_reward": 50,
            "unlock_avatar_id": "fire_hero",
        },
        {
            "id": "hydration_master",
            "title": "Hydration Master",
            "description": "Drink 30 glasses of water",
            "icon": "💧",
            "type": "volume",
            "rarity": "epic",
            "current_value": 15,
            "required_value": 30,
            "progress_percentage": 50,
            "is_unlocked": False,
            "is_claimed": False,
            "xp_reward": 100,
            "unlock_avatar_id": "water_master",
        },
    ]


@app.get("/api/v1/levels/unlocked-avatars")
async def get_unlocked_avatars():
    """Get unlocked avatars"""
    return {"unlocked_avatars": ["water_drop", "aqua_hero", "fire_hero"]}


@app.get("/api/v1/levels/stats")
async def get_level_stats():
    """Get level statistics"""
    return {
        "level": user_stats["level"],
        "total_xp": 1500,
        "xp_this_week": 200,
        "achievements": {
            "total": 10,
            "unlocked": 2,
            "claimed": 2,
            "completion_percentage": 20.0,
        },
        "next_milestone": {"level": 4, "xp_needed": 500, "progress_percentage": 75.0},
    }


@app.get("/api/v1/stats/dashboard")
async def get_stats_dashboard():
    """Get stats dashboard data"""
    return {
        "today": {
            "total_effective_ml": user_stats["current_intake"],
            "log_count": len(drink_logs),
            "total_xp_earned": 85,
            "progress_percentage": round(
                (user_stats["current_intake"] / user_stats["daily_goal"]) * 100, 1
            ),
        },
        "week": {
            "total_effective_ml": 12600,
            "log_count": 42,
            "average_daily_ml": 1800.0,
            "days_with_intake": 7,
        },
        "month": {
            "total_effective_ml": 54000,
            "log_count": 180,
            "average_daily_ml": 1800.0,
            "days_with_intake": 30,
        },
        "streaks": {"current_streak": user_stats["streak"], "longest_streak": 14},
    }


@app.get("/api/v1/stats/goals/progress")
async def get_goals_progress(days: int = 7):
    """Get goals progress over time"""
    daily_data = []
    for i in range(days):
        date = datetime.now() - timedelta(days=days - i - 1)
        total_effective = 1800 + (i * 50)
        daily_data.append(
            {
                "date": date.strftime("%Y-%m-%d"),
                "total_effective_ml": total_effective,
                "daily_goal_ml": 2000,
                "progress_percentage": round((total_effective / 2000) * 100, 1),
                "goal_achieved": total_effective >= 2000,
                "log_count": 6 + (i % 3),
            }
        )

    return {
        "period": f"{days}d",
        "goal_info": {
            "daily_goal_ml": 2000,
            "total_days_analyzed": days,
            "days_achieved": sum(1 for d in daily_data if d["goal_achieved"]),
            "achievement_rate_percentage": round(
                sum(1 for d in daily_data if d["goal_achieved"]) / days * 100, 1
            ),
        },
        "averages": {"daily_ml": 1900.0, "achievement_rate": 85.7},
        "daily_data": daily_data,
    }


@app.get("/api/v1/stats/liquid-types")
async def get_liquid_types_stats(days: int = 7):
    """Get liquid types distribution"""
    return {
        "period": f"{days}d",
        "totals": {"water": 1400, "tea": 400, "coffee": 200},
        "breakdown": [
            {
                "liquid_type": "water",
                "total_volume_ml": 1400,
                "total_effective_ml": 1400,
                "log_count": 20,
                "volume_percentage": 70.0,
                "effective_percentage": 70.0,
                "frequency_percentage": 65.0,
            },
            {
                "liquid_type": "tea",
                "total_volume_ml": 400,
                "total_effective_ml": 320,
                "log_count": 8,
                "volume_percentage": 20.0,
                "effective_percentage": 16.0,
                "frequency_percentage": 25.0,
            },
            {
                "liquid_type": "coffee",
                "total_volume_ml": 200,
                "total_effective_ml": 120,
                "log_count": 3,
                "volume_percentage": 10.0,
                "effective_percentage": 6.0,
                "frequency_percentage": 10.0,
            },
        ],
    }


@app.get("/api/v1/stats/trends/daily")
async def get_daily_trends(days: int = 7):
    """Get daily intake trends"""
    start_date = datetime.now() - timedelta(days=days - 1)
    end_date = datetime.now()

    data = []
    for i in range(days):
        date = datetime.now() - timedelta(days=days - i - 1)
        data.append(
            {
                "date": date.strftime("%Y-%m-%d"),
                "log_count": 6 + (i % 3),
                "total_volume_ml": 1600 + (i * 80),
                "total_effective_ml": 1600 + (i * 80),
                "total_xp_earned": 160 + (i * 8),
                "average_volume_ml": 200.0 + (i * 10),
            }
        )

    return {
        "period": f"{days}d",
        "start_date": start_date.strftime("%Y-%m-%d"),
        "end_date": end_date.strftime("%Y-%m-%d"),
        "data": data,
    }


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
