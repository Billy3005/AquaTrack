from typing import Generator

from sqlalchemy import create_engine
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
    from app.models import (
        Achievement,
        Conversation,
        ConversationSession,
        DailySummary,
        Friend,
        FriendRequest,
        IntakeLog,
        LeaderboardEntry,
        ScanHistory,
        User,
        UserInsight,
    )

    Base.metadata.create_all(bind=engine)
