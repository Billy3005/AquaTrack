from datetime import datetime, timedelta
from typing import Optional, Union

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

# Password hashing context
pwd_context = CryptContext(schemes=["argon2"], deprecated="auto")

# JWT token security
security = HTTPBearer()


def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain password against a hashed password"""
    return pwd_context.verify(plain_password, hashed_password)


def get_password_hash(password: str) -> str:
    """Hash a password"""
    return pwd_context.hash(password)


def create_access_token(
    subject: Union[str, int], expires_delta: Optional[timedelta] = None
) -> str:
    """Create JWT access token"""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(
            minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES
        )

    to_encode = {"exp": expire, "sub": str(subject), "type": "access"}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def create_refresh_token(subject: Union[str, int]) -> str:
    """Create JWT refresh token"""
    expire = datetime.utcnow() + timedelta(days=settings.REFRESH_TOKEN_EXPIRE_DAYS)
    to_encode = {"exp": expire, "sub": str(subject), "type": "refresh"}
    encoded_jwt = jwt.encode(
        to_encode, settings.SECRET_KEY, algorithm=settings.ALGORITHM
    )
    return encoded_jwt


def verify_token(token: str) -> Optional[str]:
    """Verify JWT token and return subject"""
    try:
        payload = jwt.decode(
            token, settings.SECRET_KEY, algorithms=[settings.ALGORITHM]
        )
        subject: str = payload.get("sub")
        token_type: str = payload.get("type")

        if subject is None or token_type != "access":
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED,
                detail="Invalid authentication token",
                headers={"WWW-Authenticate": "Bearer"},
            )
        return subject
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authentication token",
            headers={"WWW-Authenticate": "Bearer"},
        )


def get_current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(security),
) -> str:
    """Dependency to get current authenticated user ID.

    Also refreshes the caller's presence timestamp so friends can show them as
    "online". A short-lived session is opened here (not the request's ``get_db``
    dependency) so presence never interferes with the request's own transaction
    and stays trivially overridable in tests. The update is throttled inside the
    query, and failures here must never break authentication.
    """
    user_id = verify_token(credentials.credentials)
    try:
        from app.core.database import SessionLocal
        from app.crud.user import user_crud

        presence_db = SessionLocal()
        try:
            user_crud.touch_activity(presence_db, user_id=user_id)
        finally:
            presence_db.close()
    except Exception:
        pass
    return user_id
