"""TDD for the Referral system (ADR-0007).

Behaviours under test (public interface of app.services.referral_service):
- each user has a stable, unique referral code
- a code can be attached at sign-up, creating a pending referral
- self-referral and unknown codes are rejected
- a referral validates on the referred user's first water log: validated_at is
  stamped once and the referred user gets a one-time welcome coin bonus
"""

from app.models import Referral, User
from app.services import referral_service as rs


def _make_user(db, uid, email):
    u = User(
        id=uid,
        email=email,
        hashed_password="x",
        username=uid,
        coins=0,
        timezone="Asia/Ho_Chi_Minh",
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u


# --- referral code ------------------------------------------------------


def test_get_or_create_code_is_stable_and_prefixed(db):
    user = _make_user(db, "u1", "u1@test.com")
    code = rs.get_or_create_code(db, user)
    assert code.startswith("AQUA-")
    # Idempotent: asking again returns the same code, no new code generated.
    assert rs.get_or_create_code(db, user) == code


def test_codes_are_unique_across_users(db):
    a = _make_user(db, "a", "a@test.com")
    b = _make_user(db, "b", "b@test.com")
    assert rs.get_or_create_code(db, a) != rs.get_or_create_code(db, b)


# --- attach at registration ---------------------------------------------


def test_attach_referral_creates_pending_row(db):
    referrer = _make_user(db, "ref", "ref@test.com")
    code = rs.get_or_create_code(db, referrer)
    _make_user(db, "new", "new@test.com")

    referral = rs.attach_referral(db, referred_id="new", code=code)

    assert referral is not None
    assert referral.referrer_id == "ref"
    assert referral.referred_id == "new"
    assert referral.validated_at is None


def test_attach_referral_rejects_self_referral(db):
    user = _make_user(db, "self", "self@test.com")
    code = rs.get_or_create_code(db, user)

    referral = rs.attach_referral(db, referred_id="self", code=code)

    assert referral is None
    assert db.query(Referral).count() == 0


def test_attach_referral_rejects_unknown_code(db):
    _make_user(db, "new", "new@test.com")

    referral = rs.attach_referral(db, referred_id="new", code="AQUA-NOPE99")

    assert referral is None
    assert db.query(Referral).count() == 0


def test_attach_referral_is_one_per_referred_user(db):
    r1 = _make_user(db, "r1", "r1@test.com")
    r2 = _make_user(db, "r2", "r2@test.com")
    _make_user(db, "new", "new@test.com")

    first = rs.attach_referral(
        db, referred_id="new", code=rs.get_or_create_code(db, r1)
    )
    second = rs.attach_referral(
        db, referred_id="new", code=rs.get_or_create_code(db, r2)
    )

    assert first is not None
    assert second is None
    assert db.query(Referral).count() == 1


# --- validation on first log --------------------------------------------


def test_validate_stamps_and_grants_welcome_bonus_once(db):
    referrer = _make_user(db, "ref", "ref@test.com")
    referred = _make_user(db, "new", "new@test.com")
    rs.attach_referral(db, referred_id="new", code=rs.get_or_create_code(db, referrer))

    just_validated = rs.validate_referral(db, referred_id="new")

    assert just_validated is True
    db.refresh(referred)
    assert referred.coins == rs.WELCOME_BONUS_COINS
    referral = db.query(Referral).filter(Referral.referred_id == "new").first()
    assert referral.validated_at is not None

    # Second call (e.g. a later log) is a no-op: no double bonus, no re-stamp.
    again = rs.validate_referral(db, referred_id="new")
    assert again is False
    db.refresh(referred)
    assert referred.coins == rs.WELCOME_BONUS_COINS


def test_validate_no_pending_referral_is_noop(db):
    referred = _make_user(db, "solo", "solo@test.com")
    assert rs.validate_referral(db, referred_id="solo") is False
    db.refresh(referred)
    assert referred.coins == 0
