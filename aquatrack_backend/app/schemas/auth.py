from typing import Optional

from pydantic import BaseModel, Field

from app.schemas.user import UserResponse


class Token(BaseModel):
    """JWT token response schema"""

    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    expires_in: int  # seconds until expiration
    user: Optional[UserResponse] = None


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


class GoogleLoginRequest(BaseModel):
    """Google Sign-In: the ID token from the google_sign_in plugin (ADR 0006)"""

    id_token: str


class ForgotPasswordRequest(BaseModel):
    """Password Reset step 1: request a 6-digit code by email"""

    email: str


class ResetPasswordRequest(BaseModel):
    """Password Reset step 2: trade the emailed code for a new password"""

    email: str
    code: str = Field(..., min_length=6, max_length=6)
    new_password: str = Field(..., min_length=8)
