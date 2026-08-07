"""Account deletion has to actually delete — these tests assert the rows are gone.

Play requires the in-app path to remove the account and its data. The old
endpoint only flipped `is_active`, which is exactly the failure mode worth
pinning down with tests.
"""

from datetime import date, datetime

import pytest
from sqlalchemy import text

from app.models import (
    AuditLog,
    Conversation,
    DailySummary,
    Friend,
    IntakeLog,
    User,
)
from app.services import account_deletion_service


def _make_user(db, uid: str, email: str) -> User:
    u = User(
        id=uid,
        email=email,
        hashed_password="x",
        full_name=email.split("@")[0],
        is_active=True,
    )
    db.add(u)
    return u


@pytest.fixture
def populated(db):
    """One user with data across the fan-out, plus a second user they relate to."""
    victim = _make_user(db, "u-del", "del@test.com")
    bystander = _make_user(db, "u-keep", "keep@test.com")
    db.flush()

    def log(uid, ml):
        return IntakeLog(
            user_id=uid,
            volume_ml=ml,
            effective_volume_ml=ml,
            logged_at=datetime.utcnow(),
        )

    def summary(uid, ml):
        return DailySummary(
            user_id=uid, date=date.today(), daily_goal_ml=2000, total_volume_ml=ml
        )

    def message(uid):
        return Conversation(
            user_id=uid,
            session_id=f"s-{uid}",
            message_id=f"m-{uid}",
            content="hi",
            message_type="user",
        )

    db.add_all(
        [
            log("u-del", 250),
            log("u-del", 500),
            log("u-keep", 300),
            summary("u-del", 750),
            summary("u-keep", 300),
            message("u-del"),
            message("u-keep"),
            # Friendship rows point both ways in this schema.
            Friend(user_id="u-del", friend_user_id="u-keep"),
            Friend(user_id="u-keep", friend_user_id="u-del"),
        ]
    )
    db.commit()
    return victim, bystander


def _count(db, table, column, uid):
    return db.execute(
        text(f"SELECT COUNT(*) FROM {table} WHERE {column} = :uid"), {"uid": uid}
    ).scalar()


def test_purge_removes_the_user_row(db, populated):
    account_deletion_service.purge_user_data(db, "u-del")
    db.commit()

    assert db.query(User).filter(User.id == "u-del").first() is None


def test_purge_removes_owned_data(db, populated):
    assert _count(db, "intake_logs", "user_id", "u-del") == 2

    account_deletion_service.purge_user_data(db, "u-del")
    db.commit()

    for table in ("intake_logs", "daily_summaries", "conversations"):
        assert _count(db, table, "user_id", "u-del") == 0, f"{table} still has rows"


def test_purge_removes_friendship_from_both_directions(db, populated):
    assert db.query(Friend).count() == 2

    account_deletion_service.purge_user_data(db, "u-del")
    db.commit()

    # Neither the row they own nor the mirror row on the other user survives.
    assert db.query(Friend).count() == 0


def test_purge_leaves_other_users_untouched(db, populated):
    account_deletion_service.purge_user_data(db, "u-del")
    db.commit()

    assert db.query(User).filter(User.id == "u-keep").first() is not None
    assert _count(db, "intake_logs", "user_id", "u-keep") == 1
    assert _count(db, "daily_summaries", "user_id", "u-keep") == 1
    assert _count(db, "conversations", "user_id", "u-keep") == 1


def test_audit_log_survives_with_actor_detached(db, populated):
    """The record of a staff action must outlive the staff account.

    Otherwise deleting an account erases the evidence of what was done with it.
    """
    db.add(
        AuditLog(
            actor_id="u-del",
            actor_name="del@test.com",
            actor_role="super_admin",
            action="user.lock",
            target_type="user",
            target_id="u-keep",
        )
    )
    db.commit()

    account_deletion_service.purge_user_data(db, "u-del")
    db.commit()

    row = db.query(AuditLog).one()
    assert row.actor_id is None, "actor should be detached, not the row deleted"
    assert row.action == "user.lock"
    # The denormalised name stays so the trail is still readable.
    assert row.actor_name == "del@test.com"


def test_report_counts_what_it_deleted(db, populated):
    report = account_deletion_service.purge_user_data(db, "u-del")
    db.commit()

    assert report.user_id == "u-del"
    assert report.deleted["users"] == 1
    assert report.deleted["intake_logs"] == 2
    assert report.rows_deleted >= 6


def test_purge_is_idempotent_for_a_missing_user(db, populated):
    """Deleting an id that owns nothing must not raise."""
    report = account_deletion_service.purge_user_data(db, "u-nobody")
    db.commit()

    assert report.deleted["users"] == 0
    assert db.query(User).count() == 2
