"""Object storage for scan images (Cloudflare R2, S3-compatible).

Training images must survive container redeploys, so in production they are
uploaded to R2 instead of the ephemeral container disk. When R2 is not
configured (local dev), callers fall back to local disk. Upload failures never
raise — a storage problem must not break the scan flow.
"""

import logging
from typing import Optional

from app.core.config import settings

logger = logging.getLogger(__name__)

try:
    import boto3
    from botocore.config import Config as BotoConfig
    from botocore.exceptions import BotoCoreError, ClientError
except ImportError:  # boto3 absent (e.g. minimal dev env) — storage just disabled
    boto3 = None
    BotoConfig = None
    BotoCoreError = ClientError = Exception


class StorageService:
    """Uploads bytes to an S3-compatible bucket (Cloudflare R2)."""

    def __init__(self) -> None:
        self._client = None

    @property
    def enabled(self) -> bool:
        return boto3 is not None and settings.r2_enabled

    def _get_client(self):
        """Lazily build the boto3 S3 client pointed at the R2 endpoint."""
        if self._client is None:
            self._client = boto3.client(
                "s3",
                endpoint_url=settings.r2_endpoint,
                aws_access_key_id=settings.R2_ACCESS_KEY_ID,
                aws_secret_access_key=settings.R2_SECRET_ACCESS_KEY,
                region_name="auto",  # R2 ignores region but boto3 requires one
                config=BotoConfig(signature_version="s3v4"),
            )
        return self._client

    def upload_bytes(
        self, data: bytes, key: str, content_type: str = "image/jpeg"
    ) -> Optional[str]:
        """Upload `data` under `key`; return the key on success, else None.

        Never raises — a storage failure must not break the scan flow.
        """
        if not self.enabled:
            return None
        try:
            self._get_client().put_object(
                Bucket=settings.R2_BUCKET,
                Key=key,
                Body=data,
                ContentType=content_type,
            )
            return key
        except (BotoCoreError, ClientError):
            logger.exception("R2 upload failed for key %s", key)
            return None


# Global service instance
storage_service = StorageService()
