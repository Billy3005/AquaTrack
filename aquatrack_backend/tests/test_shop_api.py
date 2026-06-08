"""Shop API — Streak Freeze purchase (ADR 0004)."""

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.main import app


@pytest.fixture
def client(db, user):
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_current_user_id] = lambda: user.id
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_status_reports_price_and_ownership(client, user):
    res = client.get("/api/v1/shop/streak-freeze")
    assert res.status_code == 200
    body = res.json()
    assert body == {"owned": False, "price": 300}


def test_purchase_succeeds_then_conflicts(client, db, user):
    user.coins = 500
    db.commit()

    res = client.post("/api/v1/shop/streak-freeze/purchase")
    assert res.status_code == 200
    body = res.json()
    assert body["owned"] is True
    assert body["coins"] == 200

    # Already owned -> rejected.
    res2 = client.post("/api/v1/shop/streak-freeze/purchase")
    assert res2.status_code == 400


def test_purchase_rejected_when_too_poor(client, db, user):
    user.coins = 50
    db.commit()

    res = client.post("/api/v1/shop/streak-freeze/purchase")
    assert res.status_code == 400
    db.refresh(user)
    assert user.coins == 50
