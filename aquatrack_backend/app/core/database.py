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

    from app.models import Challenge  # noqa: F401
    from app.models import CoinGift  # noqa: F401
    from app.models import Conversation  # noqa: F401
    from app.models import (  # noqa: F401
        Achievement,
        ConversationSession,
        DailySummary,
        Friend,
        FriendRequest,
        IntakeLog,
        LeaderboardEntry,
        QuestClaim,
        Referral,
        ReminderLog,
        ScanHistory,
        User,
        UserInsight,
    )

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
        if "coins_granted_up_to_level" not in existing:
            # Level-Up Rewards rollout (ADR 0008): high-water mark of the highest
            # Level already paid out in coins. Seed it to each existing user's
            # CURRENT level (derived from total_xp) so we never back-grant coins
            # for levels reached before this feature shipped — only future
            # level-ups pay out. New rows default to 1 (earn from Level 2 up).
            from app.core.leveling import calculate_level_from_xp

            conn.execute(
                text(
                    "ALTER TABLE users ADD COLUMN coins_granted_up_to_level "
                    "INTEGER DEFAULT 1"
                )
            )
            # Seed from the AUTHORITATIVE Total XP (intake xp+bonus + stored
            # total_xp) — the same value the Level is derived from at runtime.
            # Seeding from users.total_xp alone would mark heavy water-loggers
            # (whose XP lives on intake_logs, not total_xp) as Level 1 and then
            # back-grant a pile of coins on their next log.
            rows = conn.execute(
                text(
                    "SELECT u.id, "
                    "COALESCE(u.total_xp, 0) + COALESCE(("
                    "  SELECT SUM(il.xp_earned + il.bonus_xp) FROM intake_logs il"
                    "  WHERE il.user_id = u.id), 0) AS total_xp "
                    "FROM users u"
                )
            ).fetchall()
            for uid, total_xp in rows:
                level = calculate_level_from_xp(total_xp or 0)["level"]
                conn.execute(
                    text(
                        "UPDATE users SET coins_granted_up_to_level = :lvl "
                        "WHERE id = :uid"
                    ),
                    {"lvl": level, "uid": uid},
                )
