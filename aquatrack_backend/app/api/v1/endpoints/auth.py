from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import HTTPBearer
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.database import get_db
from app.core.security import (create_access_token, create_refresh_token,
                               get_current_user_id)
from app.crud import user_crud
from app.schemas.auth import (ForgotPasswordRequest, GoogleLoginRequest,
                              RefreshToken, ResetPasswordRequest,
                              TokenRefreshResponse)
from app.schemas.user import UserCreate, UserLogin, UserResponse
from app.services import password_reset_service
from app.services.mailer import Mailer
from app.services.social_auth_service import GoogleAuthError, GoogleAuthService

router = APIRouter()
security = HTTPBearer()


def get_google_auth_service() -> GoogleAuthService:
    """DI hook — tests override this with a fake-verifier service."""
    return GoogleAuthService()


def get_email_service() -> Mailer:
    """DI hook — tests override this with a capturing fake."""
    return Mailer()


def _auth_response(user) -> dict:
    """Tokens + user payload shared by register / login / Google sign-in."""
    return {
        "access_token": create_access_token(subject=user.id),
        "refresh_token": create_refresh_token(subject=user.id),
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "user": {
            "id": user.id,
            "email": user.email,
            "username": user.username,
            "full_name": user.full_name,
            "avatar_id": user.avatar_id,
            "level": user.current_level,
            "total_xp": user.total_xp,
            "daily_goal_ml": user.daily_goal_ml,
            "calculated_daily_goal_ml": user.calculated_daily_goal_ml,
            # Level & progression
            "current_streak": user.current_streak,
            "longest_streak": user.longest_streak,
            # Statistics for profile
            "total_logs_count": user.total_logs_count,
            "total_volume_ml": user.total_volume_ml,
            # Settings
            "notifications_enabled": user.notifications_enabled,
            "theme_preference": user.theme_preference,
            "language_preference": user.language_preference,
            "sound_enabled": user.sound_enabled,
            "timezone": user.timezone,
            # Body information for profile display
            "gender": user.gender,
            "age": user.age,
            "height": user.height,
            "weight": user.weight,
            "activity_level": user.activity_level,
            "job_type": user.job_type,
            "health_conditions": user.health_conditions,
            "coffee_cups_per_day": user.coffee_cups_per_day,
            "alcohol_units_per_day": user.alcohol_units_per_day,
            "created_at": user.created_at.isoformat() if user.created_at else None,
            "last_active_at": (
                user.last_login.isoformat() if user.last_login else None
            ),
            "is_active": user.is_active,
        },
    }


@router.post("/register")
async def register_user(user_create: UserCreate, db: Session = Depends(get_db)):
    """
    Register new user with real database integration and auto-login
    """
    try:
        # Debug: Log registration data received
        print("[DEBUG] REGISTRATION DEBUG:")
        print(f"  [EMAIL] Email: {user_create.email}")
        print(f"  [USER] Username: {user_create.username}")
        print(f"  [NAME] Full Name: {user_create.full_name}")
        print(f"  [GOAL] Daily Goal: {user_create.daily_goal_ml}")

        # Check if user already exists
        print("[DEBUG] Checking existing user...")
        existing_user = user_crud.get_by_email(db, email=user_create.email)
        if existing_user:
            print(f"[ERROR] User already exists: {user_create.email}")
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Email already registered",
            )

        # Check username if provided
        if user_create.username:
            print(f"[DEBUG] Checking username: {user_create.username}")
            existing_username = user_crud.get_by_username(
                db, username=user_create.username
            )
            if existing_username:
                print(f"[ERROR] Username already taken: {user_create.username}")
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Username already taken",
                )

        # Create new user
        print("[DEBUG] Creating new user...")
        user = user_crud.create(db, obj_in=user_create)
        print(
            f"✅ User created - ID: {user.id}, Username: {user.username}, Email: {user.email}"
        )

        # Referral (ADR-0007): if an invite code was supplied, attach a pending
        # referral. A bad/self code is ignored — registration must still succeed.
        if user_create.referral_code:
            from app.services import referral_service

            referral_service.attach_referral(
                db, referred_id=user.id, code=user_create.referral_code.strip()
            )

        # Same response shape as login for Flutter compatibility
        return _auth_response(user)
    except HTTPException:
        raise  # 400s must stay 400s, not be swallowed into a 500
    except Exception as e:
        print(f"[ERROR] REGISTRATION ERROR: {str(e)}")
        print(f"[ERROR] Exception type: {type(e).__name__}")
        import traceback

        print(f"[ERROR] Traceback: {traceback.format_exc()}")
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Registration failed: {str(e)}",
        )


@router.post("/test-login")
async def test_login(request: UserLogin):
    """
    Test endpoint to debug schema parsing
    """
    return {"email": request.email, "password": request.password, "status": "received"}


@router.post("/test-db")
async def test_db_connection(db: Session = Depends(get_db)):
    """
    Test database connection
    """
    try:
        # Try to query user table
        result = db.execute("SELECT COUNT(*) FROM users")
        count = result.scalar()
        return {"status": "success", "user_count": count}
    except Exception as e:
        return {"status": "error", "error": str(e)}


@router.get("/test-simple")
async def test_simple():
    """
    Simple test endpoint
    """
    return {"status": "working", "message": "Endpoint is accessible"}


@router.post("/login")
async def login(request: UserLogin, db: Session = Depends(get_db)):
    """
    Real user authentication with database integration
    """
    email = request.email
    password = request.password

    # Debug logging
    print(f"DEBUG: Login attempt - email: {email}, password: {password}")

    # Simple validation to avoid 500 errors
    if not email or not password:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email and password required",
        )

    # Passwordless Account (ADR 0006): answer honestly instead of a generic
    # wrong-password error — the account has no password to be wrong about.
    existing = user_crud.get_by_email(db, email=email)
    if existing and not existing.hashed_password and existing.google_sub:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Tài khoản này đăng nhập bằng Google. "
            "Hãy dùng nút 'Tiếp tục với Google' hoặc đặt mật khẩu qua Quên mật khẩu.",
        )

    # Authenticate user with database
    user = user_crud.authenticate(db, email=email, password=password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password"
        )

    # Check if user is active
    if not user_crud.is_active(user):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Account is deactivated"
        )

    # Update last login timestamp
    user_crud.update_last_login(db, user_id=user.id)

    return _auth_response(user)


@router.post("/google")
async def google_sign_in(
    request: GoogleLoginRequest,
    db: Session = Depends(get_db),
    service: GoogleAuthService = Depends(get_google_auth_service),
):
    """Google Sign-In (ADR 0006): verify the ID token, find-or-create the
    user (auto-linking by verified email), return ordinary app tokens."""
    try:
        user = service.authenticate(db, id_token=request.id_token)
    except GoogleAuthError as exc:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=str(exc))

    if not user_crud.is_active(user):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED, detail="Account is deactivated"
        )

    user_crud.update_last_login(db, user_id=user.id)
    return _auth_response(user)


@router.post("/forgot-password")
async def forgot_password(
    request: ForgotPasswordRequest,
    db: Session = Depends(get_db),
    mailer: Mailer = Depends(get_email_service),
):
    """Password Reset step 1: email a 6-digit code.

    Always answers generically — account existence must not leak.
    """
    password_reset_service.request_reset(db, email=request.email, mailer=mailer)
    return {"message": "Nếu email tồn tại, mã đặt lại đã được gửi."}


@router.post("/reset-password")
async def reset_password(
    request: ResetPasswordRequest,
    db: Session = Depends(get_db),
):
    """Password Reset step 2: trade the emailed code for a new password."""
    ok = password_reset_service.reset_password(
        db, email=request.email, code=request.code, new_password=request.new_password
    )
    if not ok:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Mã không đúng hoặc đã hết hạn. Hãy yêu cầu mã mới.",
        )
    return {"message": "Mật khẩu đã được đặt lại. Hãy đăng nhập."}


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


@router.get("/debug-user/{user_email}")
async def debug_user_data(user_email: str, db: Session = Depends(get_db)):
    """
    Debug endpoint to check user data including body information
    """
    user = user_crud.get_by_email(db, email=user_email)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="User not found"
        )

    return {
        "id": user.id,
        "email": user.email,
        "username": user.username,
        "full_name": user.full_name,
        "gender": user.gender,
        "age": user.age,
        "height": user.height,
        "weight": user.weight,
        "activity_level": user.activity_level,
        "job_type": user.job_type,
        "health_conditions": user.health_conditions,
        "coffee_cups_per_day": user.coffee_cups_per_day,
        "alcohol_units_per_day": user.alcohol_units_per_day,
        "profile_complete": user.profile_complete,
    }


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
