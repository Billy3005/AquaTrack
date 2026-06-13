"""Plain-text transactional mailer (ADR 0006).

Gmail App Password is the intended transport at this stage (~500 mails/day,
plenty). In development with SMTP unconfigured, the mail body is logged
instead so flows like Password Reset stay testable end-to-end locally.

Deliberately separate from the legacy `email_service.py` (HTML templates,
in-memory verification tokens — unwired); this is the minimal surface the
Password Reset flow needs, and fakeable in tests via `send()`.
"""

import logging
import smtplib
from email.mime.text import MIMEText

from app.core.config import settings

logger = logging.getLogger(__name__)


class Mailer:
    """Thin synchronous SMTP sender."""

    def send(self, to: str, subject: str, body: str) -> bool:
        if not settings.SMTP_USERNAME or not settings.SMTP_PASSWORD:
            # Dev fallback: surface the mail in the server log so the flow
            # can be exercised without an SMTP account.
            logger.warning(
                "SMTP not configured — email to %s NOT sent.\nSubject: %s\n%s",
                to,
                subject,
                body,
            )
            return settings.ENVIRONMENT == "development"

        msg = MIMEText(body, "plain", "utf-8")
        msg["Subject"] = subject
        msg["From"] = f"{settings.FROM_NAME} <{settings.SMTP_USERNAME}>"
        msg["To"] = to

        try:
            with smtplib.SMTP(settings.SMTP_HOST, settings.SMTP_PORT) as smtp:
                if settings.SMTP_USE_TLS:
                    smtp.starttls()
                smtp.login(settings.SMTP_USERNAME, settings.SMTP_PASSWORD)
                smtp.send_message(msg)
            return True
        except Exception:
            logger.exception("Failed to send email to %s", to)
            return False
