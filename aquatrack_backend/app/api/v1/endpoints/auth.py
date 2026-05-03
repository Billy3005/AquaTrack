from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import (create_access_token, create_refresh_token,
                               get_current_user_id)
from app.crud import user_crud
from app.schemas.auth import RefreshToken, Token, TokenRefreshResponse
from app.schemas.user import UserCreate, UserLogin, UserResponse

router = APIRouter()
security = HTTPBearer()


@router.post(
    "/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED
)
async def register_user(user_create: UserCreate, db: Session = Depends(get_db)):
    """
    Register a new user account.

    Creates a new user with hashed password and default achievements.
    """
    # Check if user already exists
    existing_user = user_crud.get_by_email(db, email=user_create.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Email already registered"
        )

    # Check if username is taken (if provided)
    if user_create.username:
        existing_username = user_crud.get_by_username(db, username=user_create.username)
        if existing_username:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST, detail="Username already taken"
            )

    # Create new user
    user = user_crud.create(db, obj_in=user_create)
    return user


@router.post("/login", response_model=Token)
async def login(user_login: UserLogin, db: Session = Depends(get_db)):
    """
    User login with email and password.

    Returns access token and refresh token for authenticated requests.
    """
    # Authenticate user
    user = user_crud.authenticate(
        db, email=user_login.email, password=user_login.password
    )
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password",
            headers={"WWW-Authenticate": "Bearer"},
        )

    if not user_crud.is_active(user):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Account is deactivated"
        )

    # Update last login
    user_crud.update_last_login(db, user_id=user.id)

    # Create tokens
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        subject=user.id, expires_delta=access_token_expires
    )
    refresh_token = create_refresh_token(subject=user.id)

    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
    }


@router.post("/refresh", response_model=TokenRefreshResponse)
async def refresh_access_token(
    refresh_data: RefreshToken, db: Session = Depends(get_db)
):
    """
    Refresh access token using refresh token.

    Validates refresh token and issues new access token.
    """
    try:
        from jose import JWTError, jwt

        # Decode refresh token
        payload = jwt.decode(
            refresh_data.refresh_token,
            settings.SECRET_KEY,
            algorithms=[settings.ALGORITHM],
        )
        user_id: str = payload.get("sub")
        token_type: str = payload.get("type")

        if user_id is None or token_type != "refresh":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid refresh token",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Verify user still exists and is active
        user = user_crud.get(db, id=user_id)
        if not user or not user_crud.is_active(user):
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="User not found or deactivated",
                headers={"WWW-Authenticate": "Bearer"},
            )

        # Create new access token
        access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
        access_token = create_access_token(
            subject=user.id, expires_delta=access_token_expires
        )

        return {
            "access_token": access_token,
            "token_type": "bearer",
            "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        }

    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid refresh token",
            headers={"WWW-Authenticate": "Bearer"},
        )


@router.get("/me", response_model=UserResponse)
async def get_current_user(
    current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)
):
    """
    Get current authenticated user profile.

    Returns detailed user information for the authenticated user.
    """
    user = user_crud.get(db, id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    return user


@router.post("/logout")
async def logout(
    current_user_id: str = Depends(get_current_user_id),
):
    """
    User logout.

    Note: JWT tokens are stateless, so logout is handled on client-side
    by removing stored tokens. This endpoint confirms successful authentication
    and can be used for logout event tracking.
    """
    return {"message": "Successfully logged out"}


@router.post("/deactivate")
async def deactivate_account(
    current_user_id: str = Depends(get_current_user_id), db: Session = Depends(get_db)
):
    """
    Deactivate user account.

    Disables the account while preserving data for potential reactivation.
    """
    user = user_crud.deactivate(db, user_id=current_user_id)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )
    return {"message": "Account deactivated successfully"}
