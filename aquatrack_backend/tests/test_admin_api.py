"""Admin Console API — access control, actions, and the audit trail.

The access-control tests matter more than the happy paths: before this feature
there was no such thing as an admin, so the only thing standing between an
ordinary app token and /admin/users is the role check exercised here.
"""

from datetime import datetime, timedelta

import pytest
from fastapi.testclient import TestClient

from app.api.deps import get_current_user
from app.core.database import get_db
from app.main import app
from app.models import AuditLog, IntakeLog, User


def make_user(db, email, role="user", **kwargs):
    user = User(
        email=email,
        hashed_password="x",
        username=kwargs.pop("username", email.split("@")[0]),
        full_name=kwargs.pop("full_name", email.split("@")[0]),
        role=role,
        is_active=kwargs.pop("is_active", True),
        daily_goal_ml=kwargs.pop("daily_goal_ml", 2000),
        created_at=kwargs.pop("created_at", datetime.utcnow() - timedelta(days=30)),
        **kwargs,
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return user


def log_water(db, user, days_ago=0, volume=500):
    entry = IntakeLog(
        user_id=user.id,
        volume_ml=volume,
        liquid_type="water",
        hydration_factor=1.0,
        effective_volume_ml=volume,
        xp_earned=10,
        bonus_xp=0,
        source="manual",
        logged_at=datetime.utcnow() - timedelta(days=days_ago),
    )
    db.add(entry)
    db.commit()
    return entry


@pytest.fixture
def members(db):
    """One account per role plus an ordinary user to act on."""
    return {
        "super": make_user(db, "super@aquatrack.vn", "super_admin"),
        "ops": make_user(db, "ops@aquatrack.vn", "operations"),
        "marketing": make_user(db, "mkt@aquatrack.vn", "marketing"),
        "support": make_user(db, "sup@aquatrack.vn", "support"),
        "plain": make_user(db, "player@example.com", "user", full_name="Người Chơi"),
    }


@pytest.fixture
def as_role(db, members):
    """Build a TestClient authenticated as any of the seeded accounts."""

    def _client(key):
        app.dependency_overrides[get_db] = lambda: db
        app.dependency_overrides[get_current_user] = lambda: members[key]
        return TestClient(app)

    yield _client
    app.dependency_overrides.clear()


# ── access control ───────────────────────────────────────────────────────────


def test_ordinary_user_cannot_reach_admin(as_role):
    res = as_role("plain").get("/api/v1/admin/users")
    assert res.status_code == 403


def test_admin_me_returns_role_and_capabilities(as_role):
    res = as_role("ops").get("/api/v1/admin/me")
    assert res.status_code == 200
    body = res.json()
    assert body["role"] == "operations"
    assert body["capabilities"]["user.grant"] is True
    # Only a super admin may wipe a user's data.
    assert body["capabilities"]["user.reset"] is False


def test_support_may_lock_but_not_grant(as_role, members):
    target = members["plain"].id
    support = as_role("support")

    granted = support.post(
        f"/api/v1/admin/users/{target}/grant",
        json={"coins": 10, "xp": 0, "reason": "thử vượt quyền"},
    )
    assert granted.status_code == 403

    locked = support.post(
        f"/api/v1/admin/users/{target}/lock", json={"reason": "spam bình luận"}
    )
    assert locked.status_code == 200


def test_marketing_may_export_but_support_may_not(as_role):
    assert as_role("marketing").get("/api/v1/admin/users/export").status_code == 200
    assert as_role("support").get("/api/v1/admin/users/export").status_code == 403


def test_preferences_cannot_grant_admin_role(db, members):
    """Regression: /users/preferences used to setattr any matching column, so
    a plain user could POST {"role": "super_admin"} and take over the console."""
    from app.core.security import get_current_user_id

    plain = members["plain"]
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_current_user_id] = lambda: plain.id
    client = TestClient(app)
    try:
        for payload in (
            {"role": "super_admin"},
            {"is_active": False},
            {"coins": 999999},
            {"total_xp": 999999},
            {"hashed_password": "pwned"},
            {"email": "attacker@example.com"},
        ):
            res = client.post("/api/v1/users/preferences", json=payload)
            assert res.status_code == 422, f"{payload} was accepted"

        db.refresh(plain)
        assert plain.role == "user"
        assert plain.is_active is True
        assert plain.email == "player@example.com"

        # Genuine preferences still work.
        ok = client.post(
            "/api/v1/users/preferences",
            json={"daily_goal_ml": 2500, "theme_preference": "light"},
        )
        assert ok.status_code == 200
        db.refresh(plain)
        assert plain.daily_goal_ml == 2500
    finally:
        app.dependency_overrides.clear()


def test_staff_cannot_lock_equal_or_higher_rank(as_role, db, members):
    ops = as_role("ops")
    body = {"reason": "kiểm thử vượt quyền nội bộ"}
    other_ops = make_user(db, "ops2@aquatrack.vn", "operations")

    # Operations may not touch a Super Admin...
    assert (
        ops.post(
            f"/api/v1/admin/users/{members['super'].id}/lock", json=body
        ).status_code
        == 409
    )
    # ...nor another Operations account (equal rank).
    assert (
        ops.post(f"/api/v1/admin/users/{other_ops.id}/lock", json=body).status_code
        == 409
    )
    # But an ordinary user is fair game.
    assert (
        ops.post(
            f"/api/v1/admin/users/{members['plain'].id}/lock", json=body
        ).status_code
        == 200
    )


def test_support_cannot_unlock_a_higher_ranked_account(as_role, db, members):
    """Unlocking is privilege-granting too — Support must not reinstate an
    Operations account that someone above them locked."""
    members["ops"].is_active = False
    db.commit()

    res = as_role("support").post(
        f"/api/v1/admin/users/{members['ops'].id}/unlock",
        json={"reason": "cố mở khoá cấp trên"},
    )
    assert res.status_code == 409


def test_super_admins_can_lock_each_other(as_role, db, members):
    """A departing or compromised super admin must be removable by a peer —
    the equal-rank rule is relaxed only for this tier."""
    boss = make_user(db, "boss@aquatrack.vn", "super_admin")
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_current_user] = lambda: boss

    res = TestClient(app).post(
        f"/api/v1/admin/users/{members['super'].id}/lock",
        json={"reason": "thu hồi quyền khi nghỉ việc"},
    )
    assert res.status_code == 200
    db.refresh(members["super"])
    assert members["super"].is_active is False


def test_last_active_super_admin_is_protected(db, members):
    """Service-level check. It cannot be reached through the API today (the
    actor would have to be an inactive super admin), but it is the backstop that
    makes peer-locking safe if that ever changes."""
    from app.services.admin_service import AdminActionError, lock_user

    ghost = make_user(db, "ghost@aquatrack.vn", "super_admin", is_active=False)

    with pytest.raises(AdminActionError, match="cuối cùng"):
        lock_user(db, ghost, members["super"], "khoá super admin cuối cùng")

    db.refresh(members["super"])
    assert members["super"].is_active is True


def test_reset_requires_super_admin(as_role, members):
    res = as_role("ops").post(
        f"/api/v1/admin/users/{members['plain'].id}/reset",
        json={"reason": "người dùng yêu cầu", "confirm": "RESET"},
    )
    assert res.status_code == 403


# ── actions + audit trail ────────────────────────────────────────────────────


def test_lock_writes_audit_and_blocks_login(as_role, db, members):
    target = members["plain"]
    res = as_role("ops").post(
        f"/api/v1/admin/users/{target.id}/lock",
        json={"reason": "spam bình luận thử thách"},
    )
    assert res.status_code == 200

    db.refresh(target)
    assert target.is_active is False  # the app's login check reads this flag

    entry = db.query(AuditLog).filter(AuditLog.action == "user.lock").one()
    assert entry.target_id == target.id
    assert entry.actor_role == "operations"
    assert entry.reason == "spam bình luận thử thách"


def test_locking_twice_conflicts(as_role, members):
    ops = as_role("ops")
    body = {"reason": "vi phạm nhiều lần"}
    assert (
        ops.post(
            f"/api/v1/admin/users/{members['plain'].id}/lock", json=body
        ).status_code
        == 200
    )
    second = ops.post(f"/api/v1/admin/users/{members['plain'].id}/lock", json=body)
    assert second.status_code == 409


def test_admin_cannot_lock_themselves(as_role, members):
    res = as_role("ops").post(
        f"/api/v1/admin/users/{members['ops'].id}/lock", json={"reason": "tự khoá thử"}
    )
    assert res.status_code == 409


def test_reason_is_mandatory(as_role, members):
    res = as_role("ops").post(
        f"/api/v1/admin/users/{members['plain'].id}/lock", json={"reason": "ngan"}
    )
    assert res.status_code == 422


def test_grant_credits_coins_and_xp(as_role, db, members):
    target = members["plain"]
    target.coins = 100
    target.total_xp = 50
    db.commit()

    res = as_role("ops").post(
        f"/api/v1/admin/users/{target.id}/grant",
        json={"coins": 200, "xp": 500, "reason": "bù sự cố đồng bộ"},
    )
    assert res.status_code == 200
    assert res.json() == {"coins": 300, "totalXp": 550}

    entry = db.query(AuditLog).filter(AuditLog.action == "user.grant").one()
    assert '"coins": 200' in entry.meta


def test_reset_deletes_logs_but_keeps_currency(as_role, db, members):
    target = members["plain"]
    target.coins = 900
    target.total_xp = 400
    target.current_streak = 12
    db.commit()
    log_water(db, target, days_ago=1)
    log_water(db, target, days_ago=2)

    res = as_role("super").post(
        f"/api/v1/admin/users/{target.id}/reset",
        json={"reason": "người dùng yêu cầu xoá lịch sử", "confirm": "RESET"},
    )
    assert res.status_code == 200
    assert res.json()["deletedLogs"] == 2

    db.refresh(target)
    assert db.query(IntakeLog).filter(IntakeLog.user_id == target.id).count() == 0
    assert target.current_streak == 0
    # Earned currency survives — the console only promises to erase hydration data.
    assert target.coins == 900
    assert target.total_xp == 400


def test_reset_rejects_wrong_confirmation_word(as_role, db, members):
    log_water(db, members["plain"])
    res = as_role("super").post(
        f"/api/v1/admin/users/{members['plain'].id}/reset",
        json={"reason": "gõ nhầm từ xác nhận", "confirm": "reset"},
    )
    assert res.status_code == 400
    assert db.query(IntakeLog).count() == 1


# ── listing & analytics ──────────────────────────────────────────────────────


def test_user_list_derives_status(as_role, db, members):
    active = make_user(db, "active@example.com")
    stale = make_user(db, "stale@example.com")
    locked = make_user(db, "locked@example.com", is_active=False)
    log_water(db, active, days_ago=1)
    log_water(db, stale, days_ago=40)

    body = as_role("ops").get("/api/v1/admin/users?page_size=100").json()
    by_id = {row["id"]: row for row in body["items"]}

    assert by_id[active.id]["status"] == "active"
    assert by_id[stale.id]["status"] == "inactive"
    assert by_id[locked.id]["status"] == "locked"
    # A user who has never logged anything counts as inactive, not active.
    assert by_id[members["plain"].id]["status"] == "inactive"


def test_user_list_search_and_status_filter(as_role, db):
    make_user(db, "findme@example.com", full_name="Đỗ Khánh Vy")

    hit = as_role("ops").get("/api/v1/admin/users?q=findme").json()
    assert [row["email"] for row in hit["items"]] == ["findme@example.com"]

    locked = as_role("ops").get("/api/v1/admin/users?status=locked").json()
    assert locked["items"] == []


def test_overview_reports_real_numbers(as_role, db, members):
    for offset in range(3):
        log_water(db, members["plain"], days_ago=offset, volume=2500)

    body = as_role("ops").get("/api/v1/admin/overview?range=30").json()
    assert len(body["dauSeries"]) == 30
    assert len(body["dauSeriesPrev"]) == 30
    assert len(body["hourlyDistribution"]) == 24
    assert body["kpis"]["dau"]["value"] == 1
    # 2500 ml against a 2000 ml goal is 125% — an "exceeded" day.
    assert body["goalBreakdown"]["exceeded"] == 100.0


def test_user_detail_zero_fills_the_week(as_role, db, members):
    log_water(db, members["plain"], days_ago=0, volume=800)

    body = as_role("ops").get(f"/api/v1/admin/users/{members['plain'].id}").json()
    assert len(body["weekly"]) == 7
    assert body["weekly"][-1]["ml"] == 800
    assert body["weekly"][0]["ml"] == 0
    assert body["rank"]


def test_user_detail_404_for_unknown_id(as_role):
    assert as_role("ops").get("/api/v1/admin/users/nope").status_code == 404


def test_audit_endpoint_paginates_newest_first(as_role, db, members):
    ops = as_role("ops")
    ops.post(
        f"/api/v1/admin/users/{members['plain'].id}/lock",
        json={"reason": "vi phạm quy tắc cộng đồng"},
    )
    ops.post(
        f"/api/v1/admin/users/{members['plain'].id}/unlock",
        json={"reason": "khiếu nại hợp lệ"},
    )

    body = ops.get("/api/v1/admin/audit").json()
    assert body["total"] == 2
    assert body["items"][0]["action"] == "user.unlock"
    assert body["items"][0]["actorRoleLabel"] == "Operations"
