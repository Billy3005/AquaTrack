"""Referral system (ADR-0007).

A Referral brings a brand-new user onto AquaTrack via the inviter's permanent
Referral Code. It is distinct from an in-app Friend Request. A referral is
created (pending) at the invited user's sign-up and *validated* on that user's
first water log, at which point the referred user receives a one-time welcome
coin bonus and the referrer earns Ambassador-Quest credit.
"""

import secrets
from datetime import datetime
from typing import Optional

from sqlalchemy.orm import Session

from app.models import Referral, User

# One-time welcome bonus granted to the referred user on validation.
WELCOME_BONUS_COINS = 50

# Unambiguous alphabet (no O/0, I/1) for human-readable, shareable codes.
_CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
_CODE_LENGTH = 6
_CODE_PREFIX = "AQUA-"


def _random_code() -> str:
    body = "".join(secrets.choice(_CODE_ALPHABET) for _ in range(_CODE_LENGTH))
    return f"{_CODE_PREFIX}{body}"


def generate_unique_code(db: Session) -> str:
    """Return a referral code not already in use."""
    while True:
        code = _random_code()
        exists = db.query(User.id).filter(User.referral_code == code).first()
        if exists is None:
            return code


def get_or_create_code(db: Session, user: User) -> str:
    """Return the user's permanent referral code, generating it on first use."""
    if user.referral_code:
        return user.referral_code
    code = generate_unique_code(db)
    user.referral_code = code
    db.add(user)
    db.commit()
    db.refresh(user)
    return user.referral_code


def attach_referral(db: Session, *, referred_id: str, code: str) -> Optional[Referral]:
    """At sign-up: link the referred user to the owner of ``code`` (pending).

    Returns the new Referral, or None when the code is unknown, self-applied,
    or the referred user already has a referral. Never raises on bad input —
    a bad code simply produces no referral (registration must still succeed).
    """
    if not code:
        return None
    referrer = db.query(User).filter(User.referral_code == code).first()
    if referrer is None or referrer.id == referred_id:
        return None
    already = db.query(Referral).filter(Referral.referred_id == referred_id).first()
    if already is not None:
        return None

    referral = Referral(referrer_id=referrer.id, referred_id=referred_id)
    db.add(referral)
    db.commit()
    db.refresh(referral)
    return referral


def validate_referral(
    db: Session, *, referred_id: str, now: Optional[datetime] = None
) -> bool:
    """On the referred user's first water log: stamp validation + welcome bonus.

    Idempotent — only the first call does work (a referral validates once).
    Returns True when this call performed the validation, else False.
    """
    referral = (
        db.query(Referral)
        .filter(
            Referral.referred_id == referred_id,
            Referral.validated_at.is_(None),
        )
        .first()
    )
    if referral is None:
        return False

    # Naive UTC to match the rest of the codebase (quest windows + every
    # counted source use naive UTC); an aware value would mis-compare on DBs
    # with real timestamptz columns.
    referral.validated_at = now or datetime.utcnow()
    referred = db.query(User).filter(User.id == referred_id).first()
    if referred is not None:
        referred.coins = (referred.coins or 0) + WELCOME_BONUS_COINS
        db.add(referred)
    db.add(referral)
    db.commit()
    return True
