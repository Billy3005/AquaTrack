"""Smart Scan vision service (ADR-0005).

Pure Vision API strategy: Claude estimates a continuous container capacity
(reading printed labels when visible) plus fill level. Volume is computed
server-side as capacity x fill. The response carries physical volume only —
the hydration coefficient is applied exactly once, at the log step.

Every successful scan is persisted with its resized image: user-confirmed and
user-corrected scans are the training dataset for the hybrid phase. Fallback
results (API failure) are never persisted so they cannot poison that dataset.
"""

import base64
import json
import logging
import os
import time
import uuid
from io import BytesIO
from typing import Optional, Tuple

import anthropic
from PIL import Image
from sqlalchemy.orm import Session

from app.core.config import settings
from app.crud.scan_history import scan_history_crud
from app.schemas.vision import ScanHistoryCreate, VisionEstimateResponse

logger = logging.getLogger(__name__)

LIQUID_TYPES = ["water", "tea", "coffee", "juice", "smoothie"]
MIN_CAPACITY_ML = 50
MAX_CAPACITY_ML = 5000

# Structured output schema — guarantees parseable JSON, no manual extraction
VISION_OUTPUT_SCHEMA = {
    "type": "object",
    "properties": {
        "container_label": {
            "type": "string",
            "description": "Short Vietnamese label for the container, "
            "e.g. 'Chai nhựa 500ml', 'Ly thủy tinh', 'Bình giữ nhiệt'",
        },
        "container_capacity_ml": {
            "type": "integer",
            "description": "Full capacity of the container in ml. Read the "
            "printed volume on the label if visible (e.g. '500ml', '1.5L'); "
            "otherwise estimate from size and shape cues.",
        },
        "fill_level": {
            "type": "number",
            "description": "How full the container is, 0.0 (empty) to 1.0 (full)",
        },
        "liquid_type": {
            "type": "string",
            "enum": LIQUID_TYPES,
            "description": "Type of liquid in the container",
        },
        "confidence": {
            "type": "number",
            "description": "Overall confidence, 0.0 to 1.0. A value of 0.85 "
            "or higher means you are confident the volume estimate is within "
            "15% of the true value. If you cannot clearly see the liquid "
            "surface line, confidence must be below 0.5.",
        },
    },
    "required": [
        "container_label",
        "container_capacity_ml",
        "fill_level",
        "liquid_type",
        "confidence",
    ],
    "additionalProperties": False,
}

VISION_PROMPT = (
    "Analyze the drink container in this image.\n\n"
    "1. CAPACITY: read any printed volume on the label first (e.g. '500ml', "
    "'330ml', '1.5L') — that is the most reliable signal. Otherwise estimate "
    "from size and shape.\n\n"
    "2. FILL LEVEL: locate the liquid surface line, then measure its height "
    "relative to the container's interior height. Clear water in a "
    "transparent container is subtle — look for the meniscus, the change in "
    "refraction/distortion of objects behind the container, or the "
    "elliptical reflection of the liquid surface. Do not assume a typical "
    "fill level; measure what you actually see. An empty container is 0.0.\n\n"
    "3. CONFIDENCE: be honest and calibrated. Report 0.85+ only when you "
    "clearly see both the capacity and the liquid surface line. If you "
    "cannot clearly locate the liquid surface, report below 0.5 instead of "
    "guessing confidently."
)


class VisionService:
    """Claude Vision-powered container and volume detection"""

    def __init__(self, client: Optional[object] = None):
        if client is not None:
            self.anthropic_client = client
        elif settings.ANTHROPIC_API_KEY:
            self.anthropic_client = anthropic.Anthropic(
                api_key=settings.ANTHROPIC_API_KEY
            )
        else:
            self.anthropic_client = None
            logger.warning(
                "ANTHROPIC_API_KEY not set — Smart Scan will return "
                "zero-confidence fallbacks"
            )

    async def estimate_volume_from_image(
        self,
        image_data: bytes,
        user_id: str,
        db: Session,
        save_to_history: bool = True,
    ) -> VisionEstimateResponse:
        """Process an image and estimate the physical volume of liquid.

        Raises ValueError for invalid images (endpoint maps it to 400).
        API failures degrade to a zero-confidence fallback that is NOT saved.
        """
        started = time.monotonic()

        # Resize once; the same JPEG bytes go to the API and to disk
        jpeg_data = self._preprocess_image(image_data)

        try:
            label, capacity, fill_level, liquid_type, confidence = self._run_inference(
                jpeg_data
            )
        except Exception:
            logger.exception(
                "Vision inference failed for user %s — returning fallback", user_id
            )
            return self._fallback_response(started)

        estimated_volume_ml = round(capacity * fill_level)

        scan_id = None
        if save_to_history:
            scan_id = self._save_to_history(
                db=db,
                user_id=user_id,
                jpeg_data=jpeg_data,
                label=label,
                capacity=capacity,
                fill_level=fill_level,
                liquid_type=liquid_type,
                confidence=confidence,
                estimated_volume_ml=estimated_volume_ml,
            )

        return VisionEstimateResponse(
            container_label=label,
            container_capacity_ml=capacity,
            fill_level_percent=fill_level,
            liquid_type=liquid_type,
            confidence=confidence,
            estimated_volume_ml=estimated_volume_ml,
            scan_id=scan_id,
            processing_time_ms=int((time.monotonic() - started) * 1000),
        )

    def _preprocess_image(self, image_data: bytes) -> bytes:
        """Validate, resize to max dimension, and re-encode as JPEG"""
        try:
            image = Image.open(BytesIO(image_data))
            if image.mode != "RGB":
                image = image.convert("RGB")

            max_dim = settings.VISION_MAX_IMAGE_DIMENSION
            if max(image.size) > max_dim:
                ratio = max_dim / max(image.size)
                new_size = tuple(int(dim * ratio) for dim in image.size)
                image = image.resize(new_size, Image.Resampling.LANCZOS)

            buf = BytesIO()
            image.save(buf, format="JPEG", quality=85)
            return buf.getvalue()
        except Exception as e:
            raise ValueError(f"Invalid image format: {str(e)}")

    def _run_inference(self, jpeg_data: bytes) -> Tuple[str, int, float, str, float]:
        """Call Claude Vision with structured outputs and clamp the result"""
        if self.anthropic_client is None:
            raise RuntimeError("Anthropic client not configured")

        response = self.anthropic_client.messages.create(
            model=settings.VISION_MODEL,
            max_tokens=512,
            output_config={
                "format": {"type": "json_schema", "schema": VISION_OUTPUT_SCHEMA}
            },
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": "image/jpeg",
                                "data": base64.b64encode(jpeg_data).decode("utf-8"),
                            },
                        },
                        {"type": "text", "text": VISION_PROMPT},
                    ],
                }
            ],
        )

        text = next(b.text for b in response.content if b.type == "text")
        result = json.loads(text)

        label = str(result["container_label"])[:100]
        capacity = max(
            MIN_CAPACITY_ML, min(MAX_CAPACITY_ML, int(result["container_capacity_ml"]))
        )
        fill_level = max(0.0, min(1.0, float(result["fill_level"])))
        liquid_type = result["liquid_type"]
        if liquid_type not in LIQUID_TYPES:
            liquid_type = "water"
        confidence = max(0.0, min(1.0, float(result["confidence"])))

        return label, capacity, fill_level, liquid_type, confidence

    def _save_to_history(
        self,
        db: Session,
        user_id: str,
        jpeg_data: bytes,
        label: str,
        capacity: int,
        fill_level: float,
        liquid_type: str,
        confidence: float,
        estimated_volume_ml: int,
    ) -> str:
        """Persist the scan and its image (training data for the hybrid phase)"""
        image_path = self._save_image(jpeg_data, user_id)

        scan_record = scan_history_crud.create_with_user(
            db=db,
            obj_in=ScanHistoryCreate(
                image_path=image_path,
                container_label=label,
                container_capacity_ml=capacity,
                fill_level_percent=fill_level,
                liquid_type=liquid_type,
                confidence_score=confidence,
                estimated_volume_ml=estimated_volume_ml,
            ),
            user_id=user_id,
        )
        return scan_record.id

    def _save_image(self, jpeg_data: bytes, user_id: str) -> Optional[str]:
        """Write the resized JPEG to disk; a failed write must not block the scan"""
        try:
            scan_dir = os.path.join(settings.UPLOAD_DIRECTORY, "scans", user_id)
            os.makedirs(scan_dir, exist_ok=True)
            path = os.path.join(scan_dir, f"{uuid.uuid4()}.jpg")
            with open(path, "wb") as f:
                f.write(jpeg_data)
            return path
        except OSError:
            logger.exception("Failed to save scan image for user %s", user_id)
            return None

    def _fallback_response(self, started: float) -> VisionEstimateResponse:
        """Zero-confidence fallback when inference fails — never persisted"""
        return VisionEstimateResponse(
            container_label="Không nhận diện được",
            container_capacity_ml=300,
            fill_level_percent=0.75,
            liquid_type="water",
            confidence=0.0,
            estimated_volume_ml=225,
            scan_id=None,
            processing_time_ms=int((time.monotonic() - started) * 1000),
        )


# Global service instance
vision_service = VisionService()
