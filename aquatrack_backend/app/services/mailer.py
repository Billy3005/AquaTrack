"""Plain-text transactional mailer (ADR 0006).

Transport priority:
1. Brevo HTTPS API (BREVO_API_KEY) — required on cloud hosts that block the
   SMTP ports (Railway/Render block 25/465/587).
2. SMTP (SMTP_USERNAME/PASSWORD) — local dev, where outbound SMTP is allowed.
3. Dev log fallback — neither configured: the mail body is logged so flows
   like Password Reset stay testable end-to-end locally.

Deliberately separate from the legacy `email_service.py` (HTML templates,
in-memory verification tokens — unwired); this is the minimal surface the
Password Reset flow needs, and fakeable in tests via `send()`.
"""

import logging
import smtplib
from email.mime.text import MIMEText

import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)

_BREVO_ENDPOINT = "https://api.brevo.com/v3/smtp/email"


class Mailer:
    """Transactional sender — Brevo HTTPS API in prod, SMTP for local dev."""

    def send(self, to: str, subject: str, body: str) -> bool:
        if settings.BREVO_API_KEY:
            return self._send_via_brevo(to, subject, body)

        if not settings.SMTP_USERNAME or not settings.SMTP_PASSWORD:
            # Dev fallback: surface the mail in the server log so the flow
            # can be exercised without any email account.
            logger.warning(
                "Email transport not configured — email to %s NOT sent."
                "\nSubject: %s\n%s",
                to,
                subject,
                body,
            )
            return settings.ENVIRONMENT == "development"

        return self._send_via_smtp(to, subject, body)

    def _send_via_brevo(self, to: str, subject: str, body: str) -> bool:
        """Send over Brevo's HTTPS API (port 443 — not blocked by Railway)."""
        payload = {
            "sender": {"name": settings.FROM_NAME, "email": settings.FROM_EMAIL},
            "to": [{"email": to}],
            "subject": subject,
            "textContent": body,
        }
        headers = {
            "api-key": settings.BREVO_API_KEY,
            "content-type": "application/json",
            "accept": "application/json",
        }
        try:
            resp = httpx.post(
                _BREVO_ENDPOINT, json=payload, headers=headers, timeout=15.0
            )
            if resp.status_code in (200, 201):
                return True
            logger.error(
                "Brevo rejected email to %s: %s %s", to, resp.status_code, resp.text
            )
            return False
        except Exception:
            logger.exception("Failed to send email to %s via Brevo", to)
            return False

    def _send_via_smtp(self, to: str, subject: str, body: str) -> bool:
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
