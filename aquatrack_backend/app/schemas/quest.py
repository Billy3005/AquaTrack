from typing import List, Optional

from pydantic import BaseModel


class QuestOut(BaseModel):
    """A single quest with derived progress and claim state."""

    id: str
    period: str  # "daily" | "weekly"
    name: str
    description: str
    unit: str
    progress: int
    target: int
    reward_xp: int
    reward_coin: int
    is_bonus: bool
    is_chest: bool
    done: bool
    claimed: bool


class WeekDayStatus(BaseModel):
    """Status of one day in the current ISO week for the 7-day strip."""

    day_label: str  # "T2" … "CN"
    date_iso: str  # "2026-05-25"
    status: str  # "done" | "partial" | "today" | "future"
    progress_pct: Optional[int] = None  # 0–100, None for future days


class QuestsResponse(BaseModel):
    """All quests plus the user's reward balances for the header."""

    daily: List[QuestOut]
    weekly: List[QuestOut]
    coins: int
    total_xp: int
    current_level: int
    current_streak: int
    week_strip: List[WeekDayStatus]
    daily_reset_at: str  # ISO-8601 local datetime of next daily reset
    weekly_reset_at: str  # ISO-8601 local datetime of next weekly reset


class ClaimResponse(BaseModel):
    quest_id: str
    reward_xp: int
    reward_coin: int
    total_xp: int
    coins: int
    current_level: int
    # Level-Up Rewards (ADR 0008): present so a claim that crossed a level can
    # drive the celebration (carries coins_awarded for this claim).
    level_progress: Optional[dict] = None
