"""The pre-launch cleanup runs against production — pin down what it may touch."""

from datetime import datetime

import pytest

from app.models import Friend, IntakeLog, User
from scripts.cleanup_test_accounts import delete_users, find_candidates


def _user(db, uid, email, role="user"):
    db.add(User(id=uid, email=email, hashed_password="x", role=role, is_active=True))


def _log(db, uid):
    db.add(
        IntakeLog(
            user_id=uid,
            volume_ml=250,
            effective_volume_ml=250,
            logged_at=datetime.utcnow(),
        )
    )


@pytest.fixture
def accounts(db):
    _user(db, "idle", "cv1781556059030909300@aquatrack.com")
    _user(db, "active", "tester01@wafubitest.com")
    _user(db, "review", "playreview@wafubitest.com")
    _user(db, "real", "kiet@gmail.com")
    _user(db, "staff", "admin.test@gmail.com", role="super_admin")
    db.flush()
    for uid in ("active", "review", "real"):
        _log(db, uid)
    db.add(Friend(user_id="active", friend_user_id="real"))
    db.commit()
    return db


def _emails(users):
    return {u.email for u in users}


def test_default_spares_accounts_with_logs(accounts):
    candidates, _, spared = find_candidates(accounts, set())
    assert _emails(candidates) == {"cv1781556059030909300@aquatrack.com"}
    assert _emails(u for u, _ in spared) == {"tester01@wafubitest.com"}


def test_include_active_takes_logged_test_accounts(accounts):
    candidates, _, spared = find_candidates(accounts, set(), include_active=True)
    assert _emails(candidates) == {
        "cv1781556059030909300@aquatrack.com",
        "tester01@wafubitest.com",
    }
    assert spared == []


def test_play_review_login_and_staff_are_never_candidates(accounts):
    candidates, _, _ = find_candidates(accounts, set(), include_active=True)
    assert "playreview@wafubitest.com" not in _emails(candidates)
    assert "admin.test@gmail.com" not in _emails(candidates)


def test_delete_removes_logs_and_friendships_but_not_others(accounts):
    candidates, _, _ = find_candidates(accounts, set(), include_active=True)
    delete_users(accounts, candidates)

    assert {u.email for u in accounts.query(User).all()} == {
        "playreview@wafubitest.com",
        "kiet@gmail.com",
        "admin.test@gmail.com",
    }
    assert accounts.query(IntakeLog).filter_by(user_id="active").count() == 0
    assert accounts.query(IntakeLog).filter_by(user_id="real").count() == 1
    assert accounts.query(Friend).count() == 0
