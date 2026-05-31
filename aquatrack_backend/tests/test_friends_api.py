import os
import sys
from datetime import date, datetime, timezone

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import app.models  # noqa: F401
from app.core.database import Base, get_db
from app.core.security import get_current_user_id
from app.crud.friend import friend_crud
from app.main import app
from app.models import DailySummary, ReminderLog, User


@pytest.fixture
def client_and_db():
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    session = TestingSession()

    def override_get_db():
        try:
            yield session
        finally:
            pass

    app.dependency_overrides[get_db] = override_get_db
    app.dependency_overrides[get_current_user_id] = lambda: "user-1"

    session.add(
        User(
            id="user-1",
            email="api@test.com",
            hashed_password="x",
            username="ApiTester",
            daily_goal_ml=2000,
            calculated_daily_goal_ml=2000,
            timezone="Asia/Ho_Chi_Minh",
            total_xp=0,
            coins=0,
            current_streak=0,
        )
    )
    session.commit()

    client = TestClient(app)
    try:
        yield client, session
    finally:
        app.dependency_overrides.clear()
        session.close()


def _add_friend(session, fid, username):
    session.add(
        User(
            id=fid,
            email=f"{fid}@test.com",
            hashed_password="x",
            username=username,
            full_name=username,
            timezone="Asia/Ho_Chi_Minh",
            daily_goal_ml=2000,
            calculated_daily_goal_ml=2000,
            total_xp=0,
            coins=0,
            current_streak=0,
        )
    )
    session.commit()
    friend_crud.create_friendship(session, user_id="user-1", friend_user_id=fid)


def test_get_friends_returns_envelope(client_and_db):
    client, session = client_and_db
    _add_friend(session, "f1", "friend1")

    resp = client.get("/api/v1/friends/")
    assert resp.status_code == 200
    data = resp.json()
    assert "friends" in data
    assert len(data["friends"]) == 1
    assert data["friends"][0]["username"] == "friend1"
    assert "status" in data["friends"][0]


def test_get_requests_returns_envelope(client_and_db):
    client, _ = client_and_db
    resp = client.get("/api/v1/friends/requests/")
    assert resp.status_code == 200
    assert "requests" in resp.json()


def test_weekly_leaderboard_includes_self(client_and_db):
    client, session = client_and_db
    session.add(
        DailySummary(
            user_id="user-1",
            date=date.today(),
            daily_goal_ml=2000,
            total_effective_ml=2000,
            total_volume_ml=2000,
            progress_percentage=100.0,
            goal_achieved=True,
        )
    )
    session.commit()

    resp = client.get("/api/v1/friends/leaderboard/weekly/")
    assert resp.status_code == 200
    board = resp.json()["leaderboard"]
    assert any(e["user_id"] == "user-1" for e in board)


def test_social_stats_shape(client_and_db):
    client, _ = client_and_db
    resp = client.get("/api/v1/friends/stats/")
    assert resp.status_code == 200
    data = resp.json()
    for key in (
        "total_friends",
        "online_friends",
        "thirsty_friends",
        "pending_requests",
    ):
        assert key in data
