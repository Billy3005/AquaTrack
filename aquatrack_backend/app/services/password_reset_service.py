"""Password Reset via short-lived 6-digit emailed code (ADR 0006).

The same flow re-arms a password disabled by Account Linking and lets a
Passwordless Account (Google-first) add a password later.

Security model for a low-entropy 6-digit code: only the hash is stored, the
code lives CODE_TTL_MINUTES, and MAX_ATTEMPTS wrong guesses burn it. Requests
for unknown emails return silently — endpoints answer generically either way
so account existence never leaks.
"""

import hashlib
import logging
import secrets
from datetime import datetime, timedelta

from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.crud.user import user_crud

logger = logging.getLogger(__name__)

CODE_TTL_MINUTES = 10
MAX_ATTEMPTS = 5


def _hash_code(code: str, user_id: str) -> str:
    # Salted with the user id so identical codes never share a hash.
    return hashlib.sha256(f"{user_id}:{code}".encode()).hexdigest()


def request_reset(db: Session, *, email: str, mailer) -> bool:
    """Generate, store (hashed) and email a fresh reset code.

    Returns False for unknown emails — callers must NOT expose the difference.
    """
    user = user_crud.get_by_email(db, email=email)
    if not user:
        return False

    code = f"{secrets.randbelow(1_000_000):06d}"
    user.reset_code_hash = _hash_code(code, user.id)
    user.reset_code_expires_at = datetime.utcnow() + timedelta(minutes=CODE_TTL_MINUTES)
    user.reset_code_attempts = 0
    db.add(user)
    db.commit()

    sent = mailer.send(
        to=user.email,
        subject="AquaTrack — Mã đặt lại mật khẩu",
        body=(
            f"Xin chào {user.username},\n\n"
            f"Mã đặt lại mật khẩu của bạn là: {code}\n\n"
            f"Mã có hiệu lực trong {CODE_TTL_MINUTES} phút. "
            "Nếu bạn không yêu cầu, hãy bỏ qua email này.\n\n"
            "— AquaTrack"
        ),
    )
    if not sent:
        logger.error("Reset code generated but email failed for %s", email)
    return True


def reset_password(db: Session, *, email: str, code: str, new_password: str) -> bool:
    """Validate the code and set the new password. One shot: success or a
    burned-out code both clear the reset state."""
    user = user_crud.get_by_email(db, email=email)
    if not user or not user.reset_code_hash or not user.reset_code_expires_at:
        return False

    if datetime.utcnow() > user.reset_code_expires_at:
        return False
    if (user.reset_code_attempts or 0) >= MAX_ATTEMPTS:
        return False

    if user.reset_code_hash != _hash_code(code, user.id):
        user.reset_code_attempts = (user.reset_code_attempts or 0) + 1
        db.add(user)
        db.commit()
        return False

    user.hashed_password = get_password_hash(new_password)
    user.reset_code_hash = None
    user.reset_code_expires_at = None
    user.reset_code_attempts = 0
    db.add(user)
    db.commit()
    return True
