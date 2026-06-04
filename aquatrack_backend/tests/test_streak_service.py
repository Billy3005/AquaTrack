"""Streak calculation: resets after a skipped day, with a grace window for
today (so it doesn't reset every morning before the user logs).

Regression: GET /users/stats used to return the stored user.current_streak,
which only updated on log — so skipping a day left a stale streak.
"""

from datetime import date, timedelta

from app.models.daily_summary import DailySummary
from app.services.streak_service import StreakService

TODAY = date.today()


def add_summary(db, uid, d, effective, goal=2000):
    pct = effective / goal * 100.0
    db.add(
        DailySummary(
            user_id=uid,
            date=d,
            daily_goal_ml=goal,
            total_volume_ml=effective,
            total_effective_ml=effective,
            progress_percentage=pct,
            goal_achieved=pct >= 100.0,
            log_count=1 if effective else 0,
        )
    )
    db.commit()


def test_streak_counts_consecutive_days_through_today(db, user):
    for delta in (2, 1, 0):
        add_summary(db, user.id, TODAY - timedelta(days=delta), effective=2000)

    assert StreakService.calculate_current_streak(db, user.id) == 3


def test_streak_alive_when_today_not_logged_yet(db, user):
    # Achieved through yesterday; today not logged → still counts (grace).
    add_summary(db, user.id, TODAY - timedelta(days=2), effective=2000)
    add_summary(db, user.id, TODAY - timedelta(days=1), effective=2000)

    assert StreakService.calculate_current_streak(db, user.id) == 2


def test_streak_resets_after_skipped_day(db, user):
    # Achieved 3 and 2 days ago, then skipped yesterday and today.
    add_summary(db, user.id, TODAY - timedelta(days=3), effective=2000)
    add_summary(db, user.id, TODAY - timedelta(days=2), effective=2000)

    assert StreakService.calculate_current_streak(db, user.id) == 0


def test_streak_zero_without_any_achievement(db, user):
    assert StreakService.calculate_current_streak(db, user.id) == 0


def test_below_threshold_does_not_count(db, user):
    # 1500ml < 80% of 2000 (1600) → not achieved.
    add_summary(db, user.id, TODAY, effective=1500)

    assert StreakService.calculate_current_streak(db, user.id) == 0
