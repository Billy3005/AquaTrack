from datetime import datetime

import pytest
from fastapi.testclient import TestClient

from app.core.database import get_db
from app.core.security import get_current_user_id
from app.main import app
from app.models import ScanHistory


@pytest.fixture
def client(db, user):
    app.dependency_overrides[get_db] = lambda: db
    app.dependency_overrides[get_current_user_id] = lambda: user.id
    yield TestClient(app)
    app.dependency_overrides.clear()


def test_get_quests_returns_daily_and_weekly_with_balance(client, user):
    res = client.get("/api/v1/quests/")
    assert res.status_code == 200
    body = res.json()
    assert len(body["daily"]) == 5  # 4 base + daily_bonus
    assert len(body["weekly"]) == 4  # 3 base + weekly_bonus
    assert body["coins"] == 0
    assert any(q["id"] == "smart_scan" for q in body["daily"])


def test_claim_not_done_returns_400(client, user):
    res = client.post("/api/v1/quests/smart_scan/claim")
    assert res.status_code == 400


def test_claim_flow_credits_then_conflicts(client, db, user):
    for _ in range(4):
        db.add(
            ScanHistory(
                user_id=user.id,
                container_label="Ly thủy tinh",
                container_capacity_ml=200,
                fill_level_percent=1.0,
                liquid_type="water",
                confidence_score=0.9,
                estimated_volume_ml=200,
                created_at=datetime.utcnow(),
            )
        )
    db.commit()

    res = client.post("/api/v1/quests/smart_scan/claim")
    assert res.status_code == 200
    assert res.json()["coins"] == 15

    # Second claim same period -> 409 conflict.
    res2 = client.post("/api/v1/quests/smart_scan/claim")
    assert res2.status_code == 409
