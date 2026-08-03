"""
API Dependencies - Authentication and common dependencies
"""

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.admin_roles import (
    ROLE_RANK,
    ROLE_SUPPORT,
    ROLE_USER,
    has_capability,
    is_staff,
)
from app.core.database import get_db
from app.core.security import verify_token
from app.crud.user import get_user_by_id
from app.models.user import User

# Bearer token security
security = HTTPBearer()


def get_current_user(
    db: Session = Depends(get_db),
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> User:
    """
    Get current authenticated user from JWT token
    """
    token = credentials.credentials

    try:
        # Verify token and get user_id
        user_id = verify_token(token)
        if not user_id:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication credentials",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Get user from database
        user = get_user_by_id(db, user_id=user_id)
        if not user:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
            )

        return user

    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Could not validate credentials",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_active_user(current_user: User = Depends(get_current_user)) -> User:
    """
    Get current active user (not disabled)
    """
    if not current_user.is_active:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Inactive user"
        )
    return current_user


# ── Admin Console ────────────────────────────────────────────────────────────


def get_current_admin(current_user: User = Depends(get_current_active_user)) -> User:
    """Reject anyone who is not staff.

    Deliberately answers 403 (not 404): the caller holds a valid app token, so
    hiding the route's existence buys nothing, while a clear 403 lets the
    console show "tài khoản này không có quyền admin" instead of a dead end.
    """
    if not is_staff(current_user.role or ROLE_USER):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Tài khoản này không có quyền truy cập Admin Console",
        )
    return current_user


def require_admin(min_role: str = ROLE_SUPPORT):
    """Gate a route by seniority. Coarse pre-filter — prefer `require_cap`."""

    def dependency(current_user: User = Depends(get_current_admin)) -> User:
        if ROLE_RANK.get(current_user.role, 0) < ROLE_RANK[min_role]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=f"Cần vai trò {min_role} trở lên cho thao tác này",
            )
        return current_user

    return dependency


def require_cap(capability: str):
    """Gate a route by the exact capability matrix from the console design."""

    def dependency(current_user: User = Depends(get_current_admin)) -> User:
        if not has_capability(current_user.role, capability):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail=(f"Vai trò {current_user.role} không được phép: {capability}"),
            )
        return current_user

    return dependency
