"""Response schemas for the derived-on-read friends endpoints.

These mirror exactly what `social_service.dart` parses (snake_case, envelopes,
nested `from_user`). They live apart from the legacy `social.py` schemas, which
describe the relationship/leveling model that the new read paths replaced. See
docs/adr/0003-friends-derived-on-read.md.
"""

from typing import List, Optional

from pydantic import BaseModel


class FriendOut(BaseModel):
    """A friend with hydration standing derived for today."""

    id: str
    username: str
    display_name: str
    avatar_url: Optional[str] = None
    hydration_level: float
    daily_progress: float
    current_streak: int
    is_online: bool
    status: str  # normal | stressed | thirsty | offline
    last_active: Optional[str] = None
    weekly_rank: Optional[int] = None
    weekly_score: Optional[float] = None


class FriendsResponse(BaseModel):
    friends: List[FriendOut]


class FriendRequestOut(BaseModel):
    id: str
    from_user_id: str
    to_user_id: str
    from_user: Optional[FriendOut] = None
    status: str
    created_at: Optional[str] = None
    responded_at: Optional[str] = None
    message: Optional[str] = None


class FriendRequestsResponse(BaseModel):
    requests: List[FriendRequestOut]


class LeaderboardEntryOut(BaseModel):
    user_id: str
    username: str
    display_name: str
    avatar_url: Optional[str] = None
    weekly_score: float
    hydration_percentage: float
    daily_goal_achieved: int
    total_volume_ml: int
    rank: int


class WeeklyLeaderboardOut(BaseModel):
    leaderboard: List[LeaderboardEntryOut]


class InteractionEntryOut(BaseModel):
    user_id: str
    username: str
    display_name: str
    avatar_url: Optional[str] = None
    interaction_count: int
    rank: int


class InteractionLeaderboardOut(BaseModel):
    interactions: List[InteractionEntryOut]
    total_friends: int
    unlocked: bool


class SocialStatsOut(BaseModel):
    total_friends: int
    online_friends: int
    thirsty_friends: int
    stressed_friends: int
    pending_requests: int
    my_rank: Optional[int] = None
    my_weekly_score: Optional[float] = None
