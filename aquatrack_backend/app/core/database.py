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

    from app.models import CoinGift  # noqa: F401
    from app.models import (Achievement, Challenge, Conversation,  # noqa: F401
                            ConversationSession, DailySummary, Friend,
                            FriendRequest, IntakeLog, LeaderboardEntry,
                            QuestClaim, Referral, ReminderLog, ScanHistory,
                            User, UserInsight)

    Base.metadata.create_all(bind=engine)
    _ensure_user_columns()


# Spendable coins granted to every user exactly once (see _ensure_user_columns).
STARTING_COINS = 100


def _ensure_user_columns() -> None:
    """Lightweight migration: add columns introduced after a table's creation.

    create_all() creates missing tables but never alters existing ones, so new
    columns on long-lived tables (e.g. users.coins) must be added explicitly.
    Also grants each user a one-time starting coin balance, guarded by the
    ``coins_seeded`` marker so a restart never re-grants coins to someone who
    has since spent (gifted) them down to zero.
    """
    inspector = inspect(engine)
    if "users" not in inspector.get_table_names():
        return
    existing = {col["name"] for col in inspector.get_columns("users")}
    with engine.begin() as conn:
        if "coins" not in existing:
            conn.execute(
                text(
                    "ALTER TABLE users ADD COLUMN coins INTEGER "
                    f"DEFAULT {STARTING_COINS}"
                )
            )
        if "coins_seeded" not in existing:
            # First rollout of coins: add the marker, grant the starting balance
            # to anyone with none yet, then mark every existing user as seeded.
            conn.execute(
                text("ALTER TABLE users ADD COLUMN coins_seeded INTEGER DEFAULT 0")
            )
            conn.execute(
                text(
                    "UPDATE users SET coins = :start WHERE coins IS NULL OR coins = 0"
                ),
                {"start": STARTING_COINS},
            )
            conn.execute(text("UPDATE users SET coins_seeded = 1"))
        if "owned_avatars" not in existing:
            # Avatar Catalog rollout: add the purchased-avatars store and migrate
            # legacy icon-based ids (avatar_1..8) to the new default water-spirit.
            conn.execute(
                text("ALTER TABLE users ADD COLUMN owned_avatars JSON DEFAULT '[]'")
            )
            conn.execute(
                text(
                    "UPDATE users SET avatar_id = 'giot_nuoc' "
                    "WHERE avatar_id IS NULL OR avatar_id LIKE 'avatar%'"
                )
            )
        if "streak_freeze_owned" not in existing:
            # Streak Freeze rollout (ADR 0004): binary inventory + the missed days
            # a Freeze has bridged so the derived streak stays continuous.
            conn.execute(
                text(
                    "ALTER TABLE users ADD COLUMN streak_freeze_owned "
                    "BOOLEAN DEFAULT 0"
                )
            )
        if "frozen_dates" not in existing:
            conn.execute(
                text("ALTER TABLE users ADD COLUMN frozen_dates JSON DEFAULT '[]'")
            )
        if "freeze_purchased_on" not in existing:
            # Duolingo-semantics amendment (ADR 0004): the purchase date bounds
            # which missed days a Freeze may cover. NULL (legacy) = no bound.
            conn.execute(text("ALTER TABLE users ADD COLUMN freeze_purchased_on DATE"))
        if "google_sub" not in existing:
            # Google Sign-In rollout (ADR 0006): permanent Google subject ID
            # (identity key) + Password Reset code state.
            conn.execute(text("ALTER TABLE users ADD COLUMN google_sub VARCHAR"))
            conn.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_google_sub "
                    "ON users (google_sub)"
                )
            )
            conn.execute(text("ALTER TABLE users ADD COLUMN reset_code_hash VARCHAR"))
            conn.execute(
                text("ALTER TABLE users ADD COLUMN reset_code_expires_at DATETIME")
            )
            conn.execute(
                text(
                    "ALTER TABLE users ADD COLUMN reset_code_attempts "
                    "INTEGER DEFAULT 0"
                )
            )
        if "referral_code" not in existing:
            # Referral rollout (ADR-0007): permanent per-user invite code,
            # generated lazily on first read. Unique index guards collisions.
            conn.execute(text("ALTER TABLE users ADD COLUMN referral_code VARCHAR"))
            conn.execute(
                text(
                    "CREATE UNIQUE INDEX IF NOT EXISTS ix_users_referral_code "
                    "ON users (referral_code)"
                )
            )
