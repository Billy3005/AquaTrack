"""
Permanent account deletion.

Google Play requires that an app offering account creation also offers real
deletion — of the account *and* the data attached to it — reachable from inside
the app. The old `DELETE /users/account` only flipped `is_active` and told the
caller to email support, which does not satisfy that.

None of the foreign keys to `users.id` declare ON DELETE behaviour and the
project has no Alembic migrations, so the fan-out is done here in application
code, in one transaction, parent rows last.

Audit logs are deliberately NOT deleted. `audit_logs.actor_id` is nullable, so
a staff member's rows are detached from the user instead: the record of who did
what to whom has to outlive the account, or the audit trail can be erased by
deleting the account it incriminates.
"""

import logging
from dataclasses import dataclass, field
from typing import Dict

from sqlalchemy import text
from sqlalchemy.orm import Session

logger = logging.getLogger(__name__)

# Tables owned outright by one user — every row with this column goes.
_OWNED: tuple[tuple[str, str], ...] = (
    ("intake_logs", "user_id"),
    ("daily_summaries", "user_id"),
    ("achievements", "user_id"),
    ("achievement_claims", "user_id"),
    ("quest_claims", "user_id"),
    ("reminder_logs", "user_id"),
    ("scan_history", "user_id"),
    ("user_insights", "user_id"),
    ("leaderboard_entries", "user_id"),
    # No FK constraint on these two, but they are per-user AI Coach history.
    ("conversations", "user_id"),
    ("conversation_sessions", "user_id"),
)

# Rows that join two users. The whole row goes when either side is deleted —
# half a friendship or a challenge with one participant missing is not data
# worth keeping, and the surviving user should not see a dangling entry.
_PAIRED: tuple[tuple[str, tuple[str, ...]], ...] = (
    ("friends", ("user_id", "friend_user_id")),
    ("friend_requests", ("sender_id", "receiver_id")),
    ("challenges", ("challenger_id", "opponent_id")),
    ("coin_gifts", ("sender_id", "receiver_id")),
    ("referrals", ("referrer_id", "referred_id")),
)

# Kept, but unlinked. See module docstring.
_DETACH: tuple[tuple[str, str], ...] = (("audit_logs", "actor_id"),)


@dataclass
class DeletionReport:
    """What the purge actually touched — returned so the caller can log it."""

    user_id: str
    deleted: Dict[str, int] = field(default_factory=dict)
    detached: Dict[str, int] = field(default_factory=dict)

    @property
    def rows_deleted(self) -> int:
        return sum(self.deleted.values())


def _table_exists(db: Session, table: str) -> bool:
    """Tolerate tables a given deployment has not created yet.

    Schema comes from `create_all()`, not migrations, so a database created
    before a model was added simply lacks that table. A missing table must not
    abort the deletion — the user still has the right to be gone.
    """
    return db.bind.dialect.has_table(db.connection(), table)


def purge_user_data(db: Session, user_id: str) -> DeletionReport:
    """Delete every row belonging to `user_id`, including the user.

    Does not commit — the caller owns the transaction, so the account row and
    its data disappear together or not at all.
    """
    report = DeletionReport(user_id=user_id)

    for table, column in _DETACH:
        if not _table_exists(db, table):
            continue
        result = db.execute(
            text(f"UPDATE {table} SET {column} = NULL WHERE {column} = :uid"),
            {"uid": user_id},
        )
        if result.rowcount:
            report.detached[table] = result.rowcount

    for table, columns in _PAIRED:
        if not _table_exists(db, table):
            continue
        where = " OR ".join(f"{c} = :uid" for c in columns)
        result = db.execute(
            text(f"DELETE FROM {table} WHERE {where}"), {"uid": user_id}
        )
        if result.rowcount:
            report.deleted[table] = result.rowcount

    for table, column in _OWNED:
        if not _table_exists(db, table):
            continue
        result = db.execute(
            text(f"DELETE FROM {table} WHERE {column} = :uid"), {"uid": user_id}
        )
        if result.rowcount:
            report.deleted[table] = result.rowcount

    result = db.execute(text("DELETE FROM users WHERE id = :uid"), {"uid": user_id})
    report.deleted["users"] = result.rowcount

    logger.info(
        "Account purged: user=%s rows=%d tables=%s detached=%s",
        user_id,
        report.rows_deleted,
        sorted(report.deleted),
        sorted(report.detached),
    )
    return report
