"""API-level tests for the referral flow (ADR-0007):
register-with-code → pending referral → first water log validates it.
"""

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.main import app
from app.models import Referral, User
from app.services import referral_service as rs


@pytest.fixture
def client(db, user):
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_current_user_id] = lambda: user.id
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_get_referral_returns_code_and_counts(client, user):
    res = client.get("/api/v1/friends/referral")
    assert res.status_code == 200
    body = res.json()
    assert body["code"].startswith("AQUA-")
    assert body["invited_count"] == 0
    assert body["validated_count"] == 0


def test_register_with_code_creates_pending_referral(client, db, user):
    code = rs.get_or_create_code(db, user)
    res = client.post(
        "/api/v1/auth/register",
        json={
            "email": "newbie@test.com",
            "password": "secret1",
            "username": "newbie",
            "referral_code": code,
        },
    )
    assert res.status_code == 200
    ref = db.query(Referral).filter(Referral.referrer_id == user.id).first()
    assert ref is not None
    assert ref.referred_id == res.json()["user"]["id"]
    assert ref.validated_at is None


def test_register_with_bad_code_still_succeeds_without_referral(client, db, user):
    res = client.post(
        "/api/v1/auth/register",
        json={
            "email": "solo@test.com",
            "password": "secret1",
            "username": "solo",
            "referral_code": "AQUA-NOPE99",
        },
    )
    assert res.status_code == 200
    assert db.query(Referral).count() == 0


def test_first_log_validates_referral_and_grants_bonus(client, db, user):
    code = rs.get_or_create_code(db, user)
    reg = client.post(
        "/api/v1/auth/register",
        json={
            "email": "newbie@test.com",
            "password": "secret1",
            "username": "newbie",
            "referral_code": code,
        },
    )
    new_id = reg.json()["user"]["id"]
    coins_before = db.query(User).filter(User.id == new_id).first().coins or 0

    # Act as the newly-referred user and log water for the first time.
    app.dependency_overrides[get_current_user_id] = lambda: new_id
    res = client.post(
        "/api/v1/intake/", json={"volume_ml": 250, "liquid_type": "water"}
    )
    assert res.status_code == 201

    ref = db.query(Referral).filter(Referral.referred_id == new_id).first()
    assert ref.validated_at is not None
    new_coins = db.query(User).filter(User.id == new_id).first().coins or 0
    assert new_coins == coins_before + rs.WELCOME_BONUS_COINS
