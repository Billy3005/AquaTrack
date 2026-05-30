import os
import sys

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool

# Make `app` importable when running pytest from the backend root.
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

import app.models  # noqa: F401  (register all models on Base)
from app.core.database import Base


@pytest.fixture
def db():
    """Isolated in-memory SQLite session with all tables created."""
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    TestingSession = sessionmaker(bind=engine, autocommit=False, autoflush=False)
    session = TestingSession()
    try:
        yield session
    finally:
        session.close()


@pytest.fixture
def user(db):
    from app.models import User

    u = User(
        id="user-1",
        email="quest@test.com",
        hashed_password="x",
        username="Tester",
        daily_goal_ml=2000,
        calculated_daily_goal_ml=2000,
        timezone="Asia/Ho_Chi_Minh",
        total_xp=0,
        coins=0,
        current_streak=0,
    )
    db.add(u)
    db.commit()
    db.refresh(u)
    return u
