"""Password Reset (ADR 0006): recovery via short-lived 6-digit emailed code.

Behaviours under test:
  - requesting a reset emails a 6-digit code and stores only its hash
  - unknown emails are answered silently (no account-existence leak)
  - the correct code sets a new password and clears the reset state
  - wrong codes count attempts; 5 failures burn the code
  - expired codes are rejected
  - the flow re-arms a password disabled by Account Linking
"""

import re
from datetime import datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.crud import user_crud
from app.main import app
from app.services import password_reset_service as prs


class FakeMailer:
    def __init__(self):
        self.sent = []

    def send(self, to, subject, body):
        self.sent.append({"to": to, "subject": subject, "body": body})
        return True


@pytest.fixture
def mailer():
    return FakeMailer()


def code_from(mailer):
    return re.search(r"\b(\d{6})\b", mailer.sent[-1]["body"]).group(1)


# ── request ──────────────────────────────────────────────────────────────────


def test_request_reset_emails_a_6_digit_code(db, user, mailer):
    ok = prs.request_reset(db, email=user.email, mailer=mailer)

    assert ok is True
    assert len(mailer.sent) == 1
    assert mailer.sent[0]["to"] == user.email
    code = code_from(mailer)
    db.refresh(user)
    assert user.reset_code_hash  # only the hash is stored
    assert code not in user.reset_code_hash
    assert user.reset_code_expires_at > datetime.utcnow()


def test_request_reset_unknown_email_is_silent(db, mailer):
    ok = prs.request_reset(db, email="nobody@x.com", mailer=mailer)

    assert ok is False
    assert mailer.sent == []


# ── reset ────────────────────────────────────────────────────────────────────


def test_correct_code_sets_new_password(db, user, mailer):
    prs.request_reset(db, email=user.email, mailer=mailer)

    ok = prs.reset_password(
        db, email=user.email, code=code_from(mailer), new_password="newpass123"
    )

    assert ok is True
    db.refresh(user)
    assert user.reset_code_hash is None  # one-shot
    assert user_crud.authenticate(db, email=user.email, password="newpass123")


def test_wrong_code_counts_attempts_then_burns(db, user, mailer):
    prs.request_reset(db, email=user.email, mailer=mailer)
    code = code_from(mailer)

    for _ in range(5):
        assert not prs.reset_password(
            db, email=user.email, code="000000", new_password="newpass123"
        )

    # Even the correct code is dead now — request a fresh one.
    assert not prs.reset_password(
        db, email=user.email, code=code, new_password="newpass123"
    )


def test_expired_code_is_rejected(db, user, mailer):
    prs.request_reset(db, email=user.email, mailer=mailer)
    code = code_from(mailer)
    user.reset_code_expires_at = datetime.utcnow() - timedelta(minutes=1)
    db.commit()

    assert not prs.reset_password(
        db, email=user.email, code=code, new_password="newpass123"
    )


def test_reset_rearms_password_disabled_by_linking(db, user, mailer):
    user.hashed_password = ""  # disabled by Account Linking / Google-first
    db.commit()
    assert not user_crud.authenticate(db, email=user.email, password="newpass123")

    prs.request_reset(db, email=user.email, mailer=mailer)
    prs.reset_password(
        db, email=user.email, code=code_from(mailer), new_password="newpass123"
    )

    assert user_crud.authenticate(db, email=user.email, password="newpass123")


# ── endpoints ────────────────────────────────────────────────────────────────


@pytest.fixture
def client(db, mailer):
    from app.api.v1.endpoints.auth import get_email_service

    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_email_service] = lambda: mailer
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_forgot_endpoint_is_generic_for_known_and_unknown(client, user):
    known = client.post("/api/v1/auth/forgot-password", json={"email": user.email})
    unknown = client.post("/api/v1/auth/forgot-password", json={"email": "no@x.com"})

    assert known.status_code == 200
    assert unknown.status_code == 200
    assert known.json() == unknown.json()  # no account-existence leak


def test_reset_endpoint_full_flow(client, db, user, mailer):
    client.post("/api/v1/auth/forgot-password", json={"email": user.email})

    bad = client.post(
        "/api/v1/auth/reset-password",
        json={"email": user.email, "code": "000000", "new_password": "newpass123"},
    )
    assert bad.status_code == 400

    good = client.post(
        "/api/v1/auth/reset-password",
        json={
            "email": user.email,
            "code": code_from(mailer),
            "new_password": "newpass123",
        },
    )
    assert good.status_code == 200

    login = client.post(
        "/api/v1/auth/login",
        json={"email": user.email, "password": "newpass123"},
    )
    assert login.status_code == 200
