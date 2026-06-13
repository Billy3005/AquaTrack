"""Google Sign-In service (ADR 0006).

Direct ID-token verification — no Firebase. The Flutter app obtains a Google
ID token via the google_sign_in plugin; this service verifies its signature
and audience, then finds-or-creates the AquaTrack user. The backend stays the
only identity authority: callers turn the returned user into ordinary app JWTs.

Identity is keyed by `google_sub` (Google's permanent subject ID). Email is
used once, for Account Linking — and only when Google attests it is verified.
"""

import logging
from typing import Callable, Optional

from sqlalchemy.orm import Session

from app.core.config import settings
from app.crud.user import user_crud
from app.models.user import User

logger = logging.getLogger(__name__)


class GoogleAuthError(Exception):
    """Raised when a Google ID token cannot be accepted."""


def _default_verifier(id_token: str) -> dict:
    """Verify signature + audience against Google's public keys."""
    from google.auth.transport import requests as google_requests
    from google.oauth2 import id_token as google_id_token

    if not settings.GOOGLE_CLIENT_ID:
        raise GoogleAuthError("GOOGLE_CLIENT_ID is not configured")
    return google_id_token.verify_oauth2_token(
        id_token, google_requests.Request(), audience=settings.GOOGLE_CLIENT_ID
    )


class GoogleAuthService:
    """Verify a Google ID token and resolve it to an AquaTrack user."""

    def __init__(self, verifier: Optional[Callable[[str], dict]] = None):
        self._verify = verifier or _default_verifier

    def authenticate(self, db: Session, *, id_token: str) -> User:
        """Find-or-create the user for this Google identity (ADR 0006).

        Raises GoogleAuthError for invalid tokens or unverified emails.
        """
        try:
            claims = self._verify(id_token)
        except GoogleAuthError:
            raise
        except Exception as exc:  # signature/audience/expiry failures
            logger.warning("Google ID token rejected: %s", exc)
            raise GoogleAuthError("Token Google không hợp lệ")

        sub = str(claims["sub"])

        # 1. Known Google identity → straight in. Email may have changed on
        #    Google's side; sub is the key, so that must not matter.
        user = db.query(User).filter(User.google_sub == sub).first()
        if user:
            return user

        email = claims.get("email")
        if not email or not claims.get("email_verified"):
            # Without a Google-verified email we can neither link nor create
            # safely — an unverified address could hijack someone's account.
            raise GoogleAuthError("Email Google chưa được xác minh")

        # 2. Verified email matches an existing account → Account Linking:
        #    one person, one account, two doors.
        user = user_crud.get_by_email(db, email=email)
        if user:
            user.google_sub = sub
            if not user.is_verified:
                # The password predates any email verification: it could have
                # been set by anyone who typed this address. Disable it; the
                # owner can re-arm it via Password Reset.
                user.hashed_password = ""
            user.is_verified = True
            db.add(user)
            db.commit()
            db.refresh(user)
            return user

        # 3. New person → Passwordless Account.
        user = User(
            email=email,
            hashed_password="",
            google_sub=sub,
            is_verified=True,
            username=self._unique_username(db, claims.get("name") or email),
        )
        db.add(user)
        db.commit()
        db.refresh(user)
        return user

    @staticmethod
    def _unique_username(db: Session, wanted: str) -> str:
        """Google display names collide; usernames must not."""
        base = (wanted.split("@")[0] if "@" in wanted else wanted).strip()[:40]
        base = base or "Aqua Warrior"
        candidate = base
        suffix = 2
        while user_crud.get_by_username(db, username=candidate):
            candidate = f"{base} {suffix}"
            suffix += 1
        return candidate
