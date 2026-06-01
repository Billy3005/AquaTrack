from typing import Generator

from sqlalchemy import create_engine, inspect, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import Session, sessionmaker

from app.core.config import settings

# SQLAlchemy engine
engine = create_engine(
    settings.database_url,
    pool_pre_ping=True,  # Verify connections before use
    pool_recycle=300,  # Recycle connections every 5 minutes
    echo=settings.ENVIRONMENT == "development",  # Log SQL queries in development
)

# SessionLocal class for database sessions
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# Base class for SQLAlchemy models
Base = declarative_base()


def get_db() -> Generator[Session, None, None]:
    """
    Dependency for getting database session.
    Yields a database session and ensures it's closed after use.
    """
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db() -> None:
    """
    Initialize database - create all tables.
    This should be called when the application starts.
    """
    # Import all models here to ensure they're registered
    from app.models import (Achievement, Challenge, Conversation,
                            ConversationSession, DailySummary, Friend,
                            FriendRequest, IntakeLog, LeaderboardEntry,
                            QuestClaim, ReminderLog, ScanHistory, User,
                            UserInsight)

    Base.metadata.create_all(bind=engine)
    _ensure_user_columns()


def _ensure_user_columns() -> None:
    """Lightweight migration: add columns introduced after a table's creation.

    create_all() creates missing tables but never alters existing ones, so new
    columns on long-lived tables (e.g. users.coins) must be added explicitly.
    """
    inspector = inspect(engine)
    if "users" not in inspector.get_table_names():
        return
    existing = {col["name"] for col in inspector.get_columns("users")}
    if "coins" not in existing:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE users ADD COLUMN coins INTEGER DEFAULT 0"))
