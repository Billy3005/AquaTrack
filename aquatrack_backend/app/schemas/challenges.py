"""Schemas for friend races (challenges) and the notifications inbox.

Field names match exactly what the Flutter ``SocialService`` / ``NotificationsScreen``
parse (snake_case keys mapped via @JsonKey on the Dart side).
"""

from typing import List, Optional

from pydantic import BaseModel, Field


class ChallengeCreate(BaseModel):
    """Body for creating a race invite (opponent comes from the URL)."""

    duration_days: int = Field(7, ge=1, le=30)
    message: Optional[str] = None


class ChallengeRespond(BaseModel):
    """Body for accepting / declining a race invite."""

    action: str = Field(..., description="'accept' or 'decline'")


class ChallengeOut(BaseModel):
    """A race shaped from the current user's point of view."""

    id: str
    status: str
    opponent_name: str
    opponent_username: str
    is_challenger: bool
    duration_days: int
    message: Optional[str] = None
    my_score_ml: int
    opponent_score_ml: int
    created_at: Optional[str] = None
    started_at: Optional[str] = None
    ends_at: Optional[str] = None


class ChallengesResponse(BaseModel):
    challenges: List[ChallengeOut]


class NotificationItem(BaseModel):
    id: str
    type: str  # "reminder" | "challenge" | "gift"
    sender_name: str
    message: str
    created_at: Optional[str] = None
    is_read: bool = False
    challenge_id: Optional[str] = None
    challenge_status: Optional[str] = None
    amount: Optional[int] = None  # coins, for "gift" notifications


class NotificationsResponse(BaseModel):
    notifications: List[NotificationItem]
