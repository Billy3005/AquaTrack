from typing import Optional

from pydantic import BaseModel


class Token(BaseModel):
    """JWT token response schema"""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds until expiration


class TokenData(BaseModel):
    """Token payload data schema"""

    sub: Optional[str] = None
    type: Optional[str] = None


class RefreshToken(BaseModel):
    """Refresh token request schema"""

    refresh_token: str


class TokenRefreshResponse(BaseModel):
    """New access token response from refresh"""

    access_token: str
    token_type: str = "bearer"
    expires_in: int


class PasswordReset(BaseModel):
    """Password reset request schema"""

    email: str


class PasswordResetConfirm(BaseModel):
    """Password reset confirmation schema"""

    token: str
    new_password: str
