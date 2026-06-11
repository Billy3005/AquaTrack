"""Tests for Smart Scan vision service (ADR-0005).

Behaviors under test:
- Volume = continuous container capacity x fill level (no hardcoded container table)
- Response carries estimated (physical) volume only — no effective volume
- Model ID comes from settings (VISION_MODEL), structured outputs used
- API failure -> zero-confidence fallback, never persisted to scan_history
- Successful scans persist to scan_history with the resized image saved to disk
- User corrections update the record (training data for hybrid phase)
"""

import asyncio
import io
import json
import os
from types import SimpleNamespace

from PIL import Image

from app.core.config import settings
from app.crud.scan_history import scan_history_crud
from app.schemas.vision import ScanHistoryUpdate
from app.services.vision_service import VisionService


def make_image_bytes(width=800, height=1200, fmt="JPEG"):
    img = Image.new("RGB", (width, height), (0, 120, 200))
    buf = io.BytesIO()
    img.save(buf, format=fmt)
    return buf.getvalue()


class FakeMessages:
    def __init__(self, payload=None, error=None):
        self.payload = payload
        self.error = error
        self.calls = []

    def create(self, **kwargs):
        self.calls.append(kwargs)
        if self.error is not None:
            raise self.error
        block = SimpleNamespace(type="text", text=json.dumps(self.payload))
        return SimpleNamespace(content=[block])


class FakeClient:
    def __init__(self, payload=None, error=None):
        self.messages = FakeMessages(payload=payload, error=error)


GOOD_PAYLOAD = {
    "container_label": "Chai nhựa 650ml",
    "container_capacity_ml": 650,
    "fill_level": 0.8,
    "liquid_type": "coffee",
    "confidence": 0.92,
}


def estimate(service, db, user, image=None, save=True):
    return asyncio.run(
        service.estimate_volume_from_image(
            image_data=image or make_image_bytes(),
            user_id=user.id,
            db=db,
            save_to_history=save,
        )
    )


def test_volume_is_capacity_times_fill(db, user):
    service = VisionService(client=FakeClient(payload=GOOD_PAYLOAD))
    result = estimate(service, db, user, save=False)

    assert result.estimated_volume_ml == 520  # 650 * 0.8
    assert result.container_capacity_ml == 650
    assert result.container_label == "Chai nhựa 650ml"
    assert result.liquid_type == "coffee"
    assert result.confidence == 0.92
    # Effective volume is Log Drink's job — must not exist on vision response
    assert not hasattr(result, "effective_volume_ml")


def test_model_and_structured_output_from_settings(db, user):
    client = FakeClient(payload=GOOD_PAYLOAD)
    service = VisionService(client=client)
    estimate(service, db, user, save=False)

    call = client.messages.calls[0]
    assert call["model"] == settings.VISION_MODEL
    assert call["output_config"]["format"]["type"] == "json_schema"


def test_out_of_range_values_are_clamped(db, user):
    payload = {
        "container_label": "x",
        "container_capacity_ml": 99999,
        "fill_level": 1.7,
        "liquid_type": "beer",  # not in enum
        "confidence": 1.4,
    }
    service = VisionService(client=FakeClient(payload=payload))
    result = estimate(service, db, user, save=False)

    assert result.container_capacity_ml == 5000
    assert result.fill_level_percent == 1.0
    assert result.confidence == 1.0
    assert result.liquid_type == "water"
    assert result.estimated_volume_ml == 5000


def test_api_error_returns_zero_confidence_and_is_not_persisted(db, user):
    service = VisionService(client=FakeClient(error=RuntimeError("api down")))
    result = estimate(service, db, user, save=True)

    assert result.confidence == 0.0
    assert result.scan_id is None
    # Fallback guesses must never pollute the training dataset
    assert scan_history_crud.get_by_user(db, user_id=user.id) == []


def test_successful_scan_persists_record_with_image(db, user, tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIRECTORY", str(tmp_path))
    service = VisionService(client=FakeClient(payload=GOOD_PAYLOAD))
    result = estimate(service, db, user, save=True)

    assert result.scan_id is not None
    records = scan_history_crud.get_by_user(db, user_id=user.id)
    assert len(records) == 1
    record = records[0]
    assert record.container_capacity_ml == 650
    assert record.estimated_volume_ml == 520
    assert record.image_path is not None
    assert os.path.exists(record.image_path)


def test_large_image_is_saved_resized(db, user, tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIRECTORY", str(tmp_path))
    service = VisionService(client=FakeClient(payload=GOOD_PAYLOAD))
    estimate(service, db, user, image=make_image_bytes(2000, 3000), save=True)

    record = scan_history_crud.get_by_user(db, user_id=user.id)[0]
    with Image.open(record.image_path) as saved:
        assert max(saved.size) <= settings.VISION_MAX_IMAGE_DIMENSION


def test_user_correction_updates_record(db, user, tmp_path, monkeypatch):
    monkeypatch.setattr(settings, "UPLOAD_DIRECTORY", str(tmp_path))
    service = VisionService(client=FakeClient(payload=GOOD_PAYLOAD))
    result = estimate(service, db, user, save=True)

    record = scan_history_crud.get(db, id=result.scan_id)
    updated = scan_history_crud.update_with_validation(
        db,
        db_obj=record,
        obj_in=ScanHistoryUpdate(user_corrected_volume_ml=300, is_validated=True),
    )

    assert updated.user_corrected_volume_ml == 300
    assert updated.is_validated is True
    assert updated.final_volume_ml == 300
