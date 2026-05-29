from datetime import date, datetime
from typing import List, Optional

from pydantic import BaseModel, Field

from app.models.friend_request import FriendRequestStatus


# Friend Request schemas
class FriendRequestBase(BaseModel):
    """Base friend request schema"""

    message: Optional[str] = Field(
        None, description="Optional message with friend request"
    )


class FriendRequestCreate(FriendRequestBase):
    """Schema for creating a friend request"""

    receiver_id: str = Field(..., description="ID of user to send friend request to")


class FriendRequestUpdate(BaseModel):
    """Schema for updating friend request status"""

    status: FriendRequestStatus = Field(
        ..., description="New status for the friend request"
    )


class FriendRequestResponse(FriendRequestBase):
    """Schema for friend request response"""

    id: str
    sender_id: str
    receiver_id: str
    status: FriendRequestStatus
    created_at: datetime
    updated_at: datetime
    responded_at: Optional[datetime] = None

    # Sender and receiver info for UI
    sender_username: Optional[str] = None
    sender_avatar_id: Optional[str] = None
    receiver_username: Optional[str] = None
    receiver_avatar_id: Optional[str] = None

    class Config:
        from_attributes = True


# Friend schemas
class FriendBase(BaseModel):
    """Base friend schema"""

    pass


class FriendResponse(FriendBase):
    """Schema for friend response"""

    id: str
    user_id: str
    friend_user_id: str
    is_active: bool
    is_blocked: bool
    created_at: datetime

    # Friend user info for UI
    friend_username: str = Field(..., description="Friend's username")
    friend_avatar_id: str = Field(..., description="Friend's avatar ID")
    friend_current_level: int = Field(..., description="Friend's current level")
    friend_total_xp: int = Field(..., description="Friend's total XP")

    # Social stats
    friendship_duration_days: int = Field(
        ..., description="Days since becoming friends"
    )
    last_seen: Optional[datetime] = Field(None, description="Friend's last activity")

    class Config:
        from_attributes = True


# User search schemas
class UserSearchResult(BaseModel):
    """Schema for user search results"""

    id: str
    username: str
    avatar_id: str
    current_level: int
    total_xp: int
    is_already_friend: bool = Field(
        ..., description="Whether current user is already friends with this user"
    )
    has_pending_request: bool = Field(
        ..., description="Whether there's a pending friend request"
    )

    class Config:
        from_attributes = True


# Leaderboard schemas
class LeaderboardEntryBase(BaseModel):
    """Base leaderboard entry schema"""

    pass


class LeaderboardEntryResponse(LeaderboardEntryBase):
    """Schema for leaderboard entry response"""

    id: str
    user_id: str
    week_start_date: date
    week_year: int
    total_volume_ml: int
    goal_achievement_days: int
    streak_days: int
    average_daily_ml: int
    rank_position: Optional[int]
    total_participants: int
    xp_earned: int
    achievements_unlocked: int
    goal_achievement_percentage: float
    rank_suffix: str
    is_current_week: bool

    # User info for UI
    username: str = Field(..., description="User's username")
    avatar_id: str = Field(..., description="User's avatar ID")
    current_level: int = Field(..., description="User's level")

    # Additional context
    is_current_user: bool = Field(
        ..., description="Whether this entry belongs to current user"
    )
    is_friend: bool = Field(..., description="Whether this user is a friend")

    class Config:
        from_attributes = True


class WeeklyLeaderboardResponse(BaseModel):
    """Schema for weekly leaderboard response"""

    week_start_date: date
    week_year: int
    total_participants: int
    current_user_rank: Optional[int] = None
    current_user_entry: Optional[LeaderboardEntryResponse] = None
    top_entries: List[LeaderboardEntryResponse] = Field(
        ..., description="Top 10 entries"
    )
    friends_entries: List[LeaderboardEntryResponse] = Field(
        ..., description="Friends' entries"
    )

    class Config:
        from_attributes = True


# Social stats schemas
class SocialStatsResponse(BaseModel):
    """Schema for user's social statistics"""

    total_friends: int = Field(..., description="Total number of friends")
    pending_requests: int = Field(..., description="Number of pending friend requests")
    current_week_rank: Optional[int] = Field(
        None, description="Current week leaderboard rank"
    )
    best_week_rank: Optional[int] = Field(None, description="Best ever week rank")
    weeks_participated: int = Field(
        ..., description="Number of weeks participated in leaderboard"
    )

    # Friendship activity
    recent_friend_activity: List[dict] = Field(
        ..., description="Recent hydration activity from friends"
    )

    class Config:
        from_attributes = True


# Friend reminder schemas
class FriendReminderRequest(BaseModel):
    """Schema for sending hydration reminder to friend"""

    message: Optional[str] = Field(
        None, description="Optional custom message with the reminder"
    )


class FriendReminderResponse(BaseModel):
    """Schema for friend reminder response"""

    success: bool
    message: str
    reminder_sent_at: datetime

    class Config:
        from_attributes = True
