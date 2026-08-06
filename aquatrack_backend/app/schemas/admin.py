"""Request schemas for the Admin Console.

Every destructive action carries a mandatory `reason` — it is what makes the
audit trail worth keeping. The minimum length matches the console, which keeps
its confirm button disabled until the field is filled in.
"""

from typing import Optional

from pydantic import BaseModel, Field


class ReasonedAction(BaseModel):
    """Base for any action that must justify itself in the audit log."""

    reason: str = Field(..., min_length=6, max_length=500)


class LockUserRequest(ReasonedAction):
    pass


class UnlockUserRequest(ReasonedAction):
    pass


class ResetUserRequest(ReasonedAction):
    # The console makes the operator type RESET; the server re-checks it so the
    # guard is not merely cosmetic.
    confirm: str = Field(..., description="Phải bằng đúng 'RESET'")


class IssueResetCodeRequest(ReasonedAction):
    """No confirmation word: the action is reversible by simply waiting 10
    minutes for the code to expire, and a typed word would only slow down the
    support call it exists to serve."""


class GrantRequest(ReasonedAction):
    coins: int = Field(0, ge=0, le=100_000)
    xp: int = Field(0, ge=0, le=100_000)


class AdminUserQuery(BaseModel):
    q: str = ""
    status: str = "all"
    level: str = "all"
    page: int = 1
    page_size: int = 10


class AdminProfile(BaseModel):
    id: str
    name: str
    email: str
    role: str
    roleLabel: str
    capabilities: dict
    avatarHue: Optional[int] = None
