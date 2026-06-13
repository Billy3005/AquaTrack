"""Google Sign-In (ADR 0006): direct ID-token verification on the backend.

Behaviours under test:
  - a verified Google identity creates a Passwordless Account (find-or-create)
  - identity is keyed by google_sub, never by email
  - verified-email match auto-links into the existing password account;
    linking into a never-verified account disables its password
  - linking into a verified account keeps its password
  - unverified Google emails and invalid tokens are rejected
  - password login against a Passwordless Account answers honestly
"""

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.main import app
from app.models import User
from app.services.social_auth_service import GoogleAuthError, GoogleAuthService

CLAIMS = {
    "sub": "google-sub-123",
    "email": "minh@gmail.com",
    "email_verified": True,
    "name": "Minh Nguyễn",
}


def service(claims=CLAIMS, error=None):
    def verifier(id_token):
        if error is not None:
            raise error
        return dict(claims)

    return GoogleAuthService(verifier=verifier)


# ── find-or-create ───────────────────────────────────────────────────────────


def test_new_google_user_is_created_passwordless(db):
    user = service().authenticate(db, id_token="tok")

    assert user.google_sub == "google-sub-123"
    assert user.email == "minh@gmail.com"
    assert user.username == "Minh Nguyễn"
    assert user.is_verified is True  # Google verified the email for us
    assert not user.hashed_password  # Passwordless Account


def test_existing_google_sub_logs_in_even_if_email_changed(db):
    first = service().authenticate(db, id_token="tok")
    changed = dict(CLAIMS, email="new-address@gmail.com")
    second = service(claims=changed).authenticate(db, id_token="tok")

    assert second.id == first.id  # sub is the key, not email
    assert db.query(User).count() == 1


def test_username_collision_gets_suffix(db, user):
    claims = dict(CLAIMS, name=user.username)  # "Tester" already taken
    created = service(claims=claims).authenticate(db, id_token="tok")

    assert created.id != user.id
    assert created.username != user.username
    assert created.username.startswith(user.username)


# ── account linking ──────────────────────────────────────────────────────────


def test_link_by_verified_email_disables_unverified_password(db, user):
    user.email = CLAIMS["email"]
    user.is_verified = False  # our app never verified this email
    db.commit()

    linked = service().authenticate(db, id_token="tok")

    assert linked.id == user.id  # one person, one account, two doors
    assert linked.google_sub == "google-sub-123"
    assert not linked.hashed_password  # old password disabled (takeover hole)
    assert linked.is_verified is True
    assert db.query(User).count() == 1


def test_link_to_verified_account_keeps_password(db, user):
    user.email = CLAIMS["email"]
    user.is_verified = True
    db.commit()

    linked = service().authenticate(db, id_token="tok")

    assert linked.id == user.id
    assert linked.google_sub == "google-sub-123"
    assert linked.hashed_password == "x"  # untouched


# ── rejection paths ──────────────────────────────────────────────────────────


def test_unverified_google_email_is_rejected(db):
    claims = dict(CLAIMS, email_verified=False)
    with pytest.raises(GoogleAuthError):
        service(claims=claims).authenticate(db, id_token="tok")
    assert db.query(User).count() == 0


def test_invalid_token_is_rejected(db):
    with pytest.raises(GoogleAuthError):
        service(error=ValueError("bad token")).authenticate(db, id_token="tok")
    assert db.query(User).count() == 0


# ── endpoints ────────────────────────────────────────────────────────────────


@pytest.fixture
def client(db):
    from app.api.v1.endpoints.auth import get_google_auth_service

    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_google_auth_service] = lambda: service()
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_google_endpoint_returns_app_tokens(client):
    res = client.post("/api/v1/auth/google", json={"id_token": "tok"})

    assert res.status_code == 200
    body = res.json()
    assert body["access_token"]
    assert body["refresh_token"]
    assert body["user"]["email"] == "minh@gmail.com"


def test_password_login_on_passwordless_account_explains(client, db):
    client.post("/api/v1/auth/google", json={"id_token": "tok"})

    res = client.post(
        "/api/v1/auth/login",
        json={"email": "minh@gmail.com", "password": "whatever123"},
    )
    assert res.status_code == 400
    assert "Google" in res.json()["detail"]
