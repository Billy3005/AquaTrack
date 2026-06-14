"""Tests for intake log XP logic: flat 20 XP per log, 200 XP/day cap."""

from app.crud.intake_log import intake_log_crud
from app.models.intake_log import IntakeLog
from app.schemas.intake_log import IntakeLogCreate


def _log(db, user_id: str, volume: int = 250) -> IntakeLog:
    return intake_log_crud.create(
        db=db,
        obj_in=IntakeLogCreate(
            volume_ml=volume, liquid_type="water", source="quick_log"
        ),
        user_id=user_id,
    )


def test_single_log_earns_20_xp(db, user):
    log = _log(db, user.id)
    assert log.xp_earned == 20


def test_xp_is_flat_regardless_of_volume(db, user):
    for volume in (100, 250, 500, 1000):
        log = _log(db, user.id, volume=volume)
        assert log.xp_earned == 20, f"Expected 20 XP for {volume}ml"


def test_daily_cap_at_200_xp(db, user):
    # 10 logs × 20 XP = 200 XP (last log that earns XP)
    logs = [_log(db, user.id) for _ in range(10)]
    assert all(entry.xp_earned == 20 for entry in logs)

    # 11th log: cap reached → 0 XP
    over_cap = _log(db, user.id)
    assert over_cap.xp_earned == 0


def test_cap_does_not_spill_to_next_log(db, user):
    for _ in range(15):  # 15 logs, first 10 get XP
        _log(db, user.id)
    logs = (
        db.query(IntakeLog)
        .filter(IntakeLog.user_id == user.id)
        .order_by(IntakeLog.logged_at)
        .all()
    )
    capped = [entry for entry in logs if entry.xp_earned == 0]
    assert len(capped) == 5  # last 5 earn nothing
