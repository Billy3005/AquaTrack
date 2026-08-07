"""GET /users/stats must report what the user actually did.

`users.total_logs_count` and `users.total_volume_ml` are columns nothing in the
API writes to. The endpoint used to return them verbatim, so the Level screen
showed 0 logs / 0 ml for every account whose data came from using the app
instead of a seed script. These tests pin the derived-on-read behaviour, and
one of them deliberately puts wrong values in the columns to prove they are
ignored.
"""

from datetime import datetime, timedelta

import pytest

from app.crud.intake_log import lifetime_totals
from app.models import IntakeLog, User


@pytest.fixture
def drinker(db):
    u = User(
        id="u-stats",
        email="stats@test.com",
        hashed_password="x",
        full_name="Stats",
        is_active=True,
        # Deliberately wrong: these are the columns the endpoint must not trust.
        total_logs_count=999,
        total_volume_ml=999_999,
        total_xp=50,  # quest/milestone XP, which IS real and must be included
    )
    db.add(u)
    db.flush()

    now = datetime.utcnow()
    db.add_all(
        [
            IntakeLog(
                user_id="u-stats",
                volume_ml=500,
                effective_volume_ml=500,
                xp_earned=20,
                bonus_xp=0,
                logged_at=now,
            ),
            IntakeLog(
                user_id="u-stats",
                volume_ml=300,
                effective_volume_ml=240,  # coffee: hydration-adjusted
                xp_earned=20,
                bonus_xp=5,
                logged_at=now - timedelta(hours=2),
            ),
        ]
    )
    # A second user whose data must not leak into the first one's totals.
    other = User(id="u-other", email="o@test.com", hashed_password="x", is_active=True)
    db.add(other)
    db.flush()
    db.add(
        IntakeLog(
            user_id="u-other",
            volume_ml=9999,
            effective_volume_ml=9999,
            xp_earned=20,
            logged_at=now,
        )
    )
    db.commit()
    return u


def test_lifetime_totals_counts_only_this_user(db, drinker):
    count, volume = lifetime_totals(db, "u-stats")

    assert count == 2
    assert volume == 740  # 500 + 240, not 500 + 300


def test_lifetime_totals_ignores_the_stale_columns(db, drinker):
    count, volume = lifetime_totals(db, "u-stats")

    assert count != drinker.total_logs_count
    assert volume != drinker.total_volume_ml


def test_lifetime_totals_for_a_user_with_no_logs(db, drinker):
    empty = User(id="u-empty", email="e@test.com", hashed_password="x", is_active=True)
    db.add(empty)
    db.commit()

    assert lifetime_totals(db, "u-empty") == (0, 0)


def test_uses_effective_volume_so_screens_agree(db, drinker):
    """The daily summary and the leaderboard both sum effective_volume_ml.

    If this used the raw volume, a coffee would count differently depending on
    which screen you were looking at.
    """
    _, volume = lifetime_totals(db, "u-stats")

    raw_total = 500 + 300
    assert volume < raw_total
    assert volume == 740


def test_authoritative_xp_includes_intake_and_quest_xp(db, drinker):
    from app.crud.intake_log import authoritative_total_xp

    # 20 + (20 + 5) intake, plus 50 sitting on user.total_xp from quests.
    assert authoritative_total_xp(db, drinker) == 95
