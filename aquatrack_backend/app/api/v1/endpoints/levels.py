from datetime import date, datetime, timedelta
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel
from sqlalchemy import and_, func
from sqlalchemy.orm import Session

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.crud.achievement import achievement_crud
from app.crud.intake_log import intake_log_crud
from app.crud.user import user_crud
from app.models.achievement import Achievement, AchievementType
from app.models.intake_log import IntakeLog

router = APIRouter()


# Response models
class LevelInfo(BaseModel):
    current_level: int
    current_xp: int
    xp_for_next_level: int
    xp_to_next_level: int
    level_progress_percentage: float
    total_xp_earned: int


class AchievementProgress(BaseModel):
    id: str
    title: str
    description: str
    icon: str
    type: str
    rarity: str
    current_value: int
    required_value: int
    progress_percentage: int
    is_unlocked: bool
    is_claimed: bool
    xp_reward: int
    unlock_avatar_id: Optional[str]


class LevelReward(BaseModel):
    level: int
    title: str
    description: str
    avatar_unlock: Optional[str] = None
    badge_unlock: Optional[str] = None
    xp_bonus: int = 0


@router.get("/current", response_model=LevelInfo)
async def get_current_level(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get user's current level and XP information
    """
    # Calculate total XP from intake logs
    total_xp = (
        db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp))
        .filter(IntakeLog.user_id == current_user_id)
        .scalar()
        or 0
    )

    # Calculate level and progress
    level_info = _calculate_level_from_xp(total_xp)

    return LevelInfo(
        current_level=level_info["level"],
        current_xp=level_info["current_xp"],
        xp_for_next_level=level_info["xp_for_next_level"],
        xp_to_next_level=level_info["xp_to_next_level"],
        level_progress_percentage=level_info["progress_percentage"],
        total_xp_earned=total_xp,
    )


@router.get("/achievements", response_model=List[AchievementProgress])
async def get_achievements(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get all achievements with current progress
    """
    # Get user's achievements
    achievements = (
        db.query(Achievement).filter(Achievement.user_id == current_user_id).all()
    )

    # If no achievements exist, create default ones
    if not achievements:
        default_achievements = Achievement.create_default_achievements(current_user_id)
        for achievement in default_achievements:
            db.add(achievement)
        db.commit()

        # Refresh achievements list
        achievements = (
            db.query(Achievement).filter(Achievement.user_id == current_user_id).all()
        )

    # Update achievements with current progress
    await _update_achievements_progress(db, current_user_id, achievements)

    # Convert to response format
    response = []
    for achievement in achievements:
        response.append(
            AchievementProgress(
                id=achievement.id,
                title=achievement.title,
                description=achievement.description,
                icon=achievement.icon,
                type=achievement.type.value,
                rarity=achievement.rarity.value,
                current_value=achievement.current_value,
                required_value=achievement.required_value,
                progress_percentage=achievement.progress_percentage,
                is_unlocked=achievement.is_unlocked,
                is_claimed=achievement.is_claimed,
                xp_reward=achievement.xp_reward,
                unlock_avatar_id=achievement.unlock_avatar_id,
            )
        )

    return response


@router.post("/achievements/{achievement_id}/claim")
async def claim_achievement(
    achievement_id: str,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Claim achievement rewards
    """
    achievement = achievement_crud.get(db, achievement_id)
    if not achievement:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Achievement not found"
        )

    if achievement.user_id != current_user_id:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN, detail="Not enough permissions"
        )

    if not achievement.is_unlocked:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Achievement not unlocked yet",
        )

    if achievement.is_claimed:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Achievement already claimed",
        )

    # Claim the achievement
    success = achievement.claim_rewards()
    if success:
        db.commit()

        return {
            "message": "Achievement claimed successfully!",
            "xp_reward": achievement.xp_reward,
            "unlock_avatar_id": achievement.unlock_avatar_id,
            "unlock_badge_id": achievement.unlock_badge_id,
        }
    else:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Failed to claim achievement",
        )


@router.get("/unlocked-avatars")
async def get_unlocked_avatars(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get list of unlocked avatars from achievements
    """
    unlocked_avatars = (
        db.query(Achievement.unlock_avatar_id)
        .filter(
            and_(
                Achievement.user_id == current_user_id,
                Achievement.is_unlocked == True,
                Achievement.unlock_avatar_id.isnot(None),
            )
        )
        .distinct()
        .all()
    )

    avatars = [avatar[0] for avatar in unlocked_avatars if avatar[0]]

    # Add default avatar
    avatars.insert(0, "avatar_1")  # Default avatar

    return {"unlocked_avatars": avatars}


@router.get("/leaderboard")
async def get_leaderboard(
    period: str = "month",  # week, month, all_time
    limit: int = 10,
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get leaderboard based on XP
    """
    # Calculate date range
    today = date.today()
    if period == "week":
        start_date = today - timedelta(days=7)
    elif period == "month":
        start_date = today - timedelta(days=30)
    else:  # all_time
        start_date = date(2020, 1, 1)

    # Get top users by XP in period
    if period == "all_time":
        leaderboard_query = (
            db.query(
                IntakeLog.user_id,
                func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp).label("total_xp"),
                func.count(IntakeLog.id).label("total_logs"),
                func.sum(IntakeLog.effective_volume_ml).label("total_volume"),
            )
            .filter(IntakeLog.user_id.isnot(None))
            .group_by(IntakeLog.user_id)
            .order_by(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp).desc())
            .limit(limit)
            .all()
        )
    else:
        leaderboard_query = (
            db.query(
                IntakeLog.user_id,
                func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp).label("total_xp"),
                func.count(IntakeLog.id).label("total_logs"),
                func.sum(IntakeLog.effective_volume_ml).label("total_volume"),
            )
            .filter(
                and_(
                    IntakeLog.user_id.isnot(None),
                    func.date(IntakeLog.logged_at) >= start_date,
                )
            )
            .group_by(IntakeLog.user_id)
            .order_by(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp).desc())
            .limit(limit)
            .all()
        )

    leaderboard = []
    for rank, entry in enumerate(leaderboard_query, 1):
        user_level = _calculate_level_from_xp(entry.total_xp)["level"]

        # Get real user data
        user = user_crud.get(db, id=entry.user_id)
        real_username = user.username if user else "Unknown User"

        # Check if this is current user
        is_current_user = entry.user_id == current_user_id

        leaderboard.append(
            {
                "rank": rank,
                "user_id": entry.user_id,
                "username": real_username,  # Real username from database!
                "avatar_id": (
                    user.avatar_id if user else "avatar_1"
                ),  # Include user avatar
                "total_xp": entry.total_xp,
                "level": user_level,
                "total_logs": entry.total_logs,
                "total_volume_ml": entry.total_volume,
                "is_current_user": is_current_user,
            }
        )

    # Find current user rank if not in top list
    current_user_rank = None
    if not any(entry["is_current_user"] for entry in leaderboard):
        # Query current user's rank
        user_xp_query = (
            db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp))
            .filter(
                and_(
                    IntakeLog.user_id == current_user_id,
                    (
                        func.date(IntakeLog.logged_at) >= start_date
                        if period != "all_time"
                        else True
                    ),
                )
            )
            .scalar()
            or 0
        )

        # Count users with higher XP
        if period == "all_time":
            higher_xp_count = (
                db.query(func.count(func.distinct(IntakeLog.user_id)))
                .filter(IntakeLog.user_id != current_user_id)
                .having(
                    func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp) > user_xp_query
                )
                .group_by(IntakeLog.user_id)
                .count()
            )
        else:
            higher_xp_count = (
                db.query(func.count(func.distinct(IntakeLog.user_id)))
                .filter(
                    and_(
                        IntakeLog.user_id != current_user_id,
                        func.date(IntakeLog.logged_at) >= start_date,
                    )
                )
                .having(
                    func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp) > user_xp_query
                )
                .group_by(IntakeLog.user_id)
                .count()
            )

        current_user_rank = higher_xp_count + 1

    return {
        "period": period,
        "leaderboard": leaderboard,
        "current_user_rank": current_user_rank,
    }


@router.get("/rewards/preview")
async def get_level_rewards():
    """
    Get preview of rewards for each level
    """
    rewards = []

    level_rewards_data = [
        {"level": 1, "title": "Người mới", "avatar": None, "xp_bonus": 0},
        {"level": 2, "title": "Học viên hydration", "avatar": None, "xp_bonus": 10},
        {"level": 3, "title": "Người uống nước", "avatar": "avatar_2", "xp_bonus": 15},
        {
            "level": 5,
            "title": "Thành viên tích cực",
            "avatar": "avatar_3",
            "xp_bonus": 25,
        },
        {
            "level": 8,
            "title": "Chuyên gia hydration",
            "avatar": "avatar_4",
            "xp_bonus": 40,
        },
        {"level": 10, "title": "Bậc thầy nước", "avatar": "avatar_5", "xp_bonus": 50},
        {"level": 15, "title": "Ninja hydration", "avatar": "avatar_6", "xp_bonus": 75},
        {
            "level": 20,
            "title": "Huyền thoại H2O",
            "avatar": "avatar_7",
            "xp_bonus": 100,
        },
        {"level": 25, "title": "Thần nước", "avatar": "avatar_8", "xp_bonus": 150},
        {"level": 30, "title": "Aqua Master", "avatar": "avatar_9", "xp_bonus": 200},
    ]

    for reward in level_rewards_data:
        xp_needed = _calculate_xp_for_level(reward["level"])
        rewards.append(
            LevelReward(
                level=reward["level"],
                title=reward["title"],
                description=f"Đạt level {reward['level']} - {reward['title']}",
                avatar_unlock=reward["avatar"],
                xp_bonus=reward["xp_bonus"],
            )
        )

    return {"rewards": rewards}


@router.get("/stats")
async def get_level_stats(
    current_user_id: str = Depends(get_current_user_id),
    db: Session = Depends(get_db),
):
    """
    Get detailed level and achievement statistics
    """
    # Total XP and level
    total_xp = (
        db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp))
        .filter(IntakeLog.user_id == current_user_id)
        .scalar()
        or 0
    )

    level_info = _calculate_level_from_xp(total_xp)

    # Achievement stats
    achievements = (
        db.query(Achievement).filter(Achievement.user_id == current_user_id).all()
    )

    unlocked_count = sum(1 for a in achievements if a.is_unlocked)
    claimed_count = sum(1 for a in achievements if a.is_claimed)
    total_count = len(achievements)

    # XP breakdown
    last_week = date.today() - timedelta(days=7)
    week_xp = (
        db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp))
        .filter(
            and_(
                IntakeLog.user_id == current_user_id,
                func.date(IntakeLog.logged_at) >= last_week,
            )
        )
        .scalar()
        or 0
    )

    return {
        "level": level_info["level"],
        "total_xp": total_xp,
        "xp_this_week": week_xp,
        "achievements": {
            "total": total_count,
            "unlocked": unlocked_count,
            "claimed": claimed_count,
            "completion_percentage": round(
                (unlocked_count / total_count * 100) if total_count > 0 else 0, 1
            ),
        },
        "next_milestone": {
            "level": level_info["level"] + 1,
            "xp_needed": level_info["xp_to_next_level"],
            "progress_percentage": level_info["progress_percentage"],
        },
    }


# Helper functions
def _calculate_level_from_xp(total_xp: int) -> dict:
    """Calculate level, current XP, and progress from total XP"""
    level = 1
    xp_for_current_level = 0

    # Level formula: XP needed = level * 100 + (level-1) * 50
    while True:
        xp_for_next_level = _calculate_xp_for_level(level + 1)
        if total_xp < xp_for_next_level:
            break
        level += 1
        xp_for_current_level = xp_for_next_level

    # Calculate progress within current level
    xp_for_next_level = _calculate_xp_for_level(level + 1)
    current_xp = total_xp - xp_for_current_level
    xp_to_next_level = xp_for_next_level - total_xp
    progress_percentage = (
        current_xp / (xp_for_next_level - xp_for_current_level)
    ) * 100

    return {
        "level": level,
        "current_xp": current_xp,
        "xp_for_next_level": xp_for_next_level - xp_for_current_level,
        "xp_to_next_level": xp_to_next_level,
        "progress_percentage": round(progress_percentage, 1),
    }


def _calculate_xp_for_level(level: int) -> int:
    """Calculate total XP needed to reach a specific level"""
    if level <= 1:
        return 0

    total_xp = 0
    for l in range(2, level + 1):
        # Progressive XP requirement: level * 100 + (level-1) * 50
        total_xp += l * 100 + (l - 1) * 50

    return total_xp


async def _update_achievements_progress(
    db: Session, user_id: str, achievements: List[Achievement]
) -> None:
    """Update achievement progress based on current user data"""

    # Get user stats
    today = date.today()
    total_xp = (
        db.query(func.sum(IntakeLog.xp_earned + IntakeLog.bonus_xp))
        .filter(IntakeLog.user_id == user_id)
        .scalar()
        or 0
    )

    total_volume = (
        db.query(func.sum(IntakeLog.effective_volume_ml))
        .filter(IntakeLog.user_id == user_id)
        .scalar()
        or 0
    )

    total_logs = (
        db.query(func.count(IntakeLog.id)).filter(IntakeLog.user_id == user_id).scalar()
        or 0
    )

    current_level = _calculate_level_from_xp(total_xp)["level"]

    # Get real current streak from user model
    user = user_crud.get(db, id=user_id)
    current_streak = user.current_streak if user else 0

    # Update each achievement
    for achievement in achievements:
        if achievement.type == AchievementType.LEVEL:
            achievement.update_progress(current_level)
        elif achievement.type == AchievementType.TOTAL_VOLUME:
            achievement.update_progress(total_volume)
        elif achievement.type == AchievementType.FREQUENCY:
            achievement.update_progress(total_logs)
        elif achievement.type == AchievementType.STREAK:
            achievement.update_progress(current_streak)

    db.commit()
