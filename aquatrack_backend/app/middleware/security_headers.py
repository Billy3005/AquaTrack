"""
Security response headers for AquaTrack.

Replaces the former middleware/security.py, whose regex-based SQL/XSS scanner
was never wired into main.py and could not be: it matched the bare words
`update`, `select`, `create`, `drop`, ... anywhere in a JSON body, which blocks
ordinary AI Coach messages and any display name containing "Drop" — the app's
own core metaphor. The API talks to the database exclusively through SQLAlchemy
ORM with bound parameters, so that layer defended against a threat that does not
exist here. The response headers below were the part worth keeping.
"""

from fastapi import Request

# Static headers, built once at import time.
_SECURITY_HEADERS = {
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    # The API serves JSON to the Flutter app and the admin console; it renders
    # no HTML of its own, so it can lock scripting down entirely.
    "Content-Security-Policy": "default-src 'none'; frame-ancestors 'none'",
    "Permissions-Policy": (
        "geolocation=(), camera=(), microphone=(), payment=(), usb=()"
    ),
}

# Swagger/ReDoc need to load their own JS/CSS and render HTML, so the strict
# CSP above would break them. They are only mounted in development.
_DOCS_PATHS = {"/docs", "/redoc", "/openapi.json"}


async def security_headers_middleware(request: Request, call_next):
    """Attach security headers to every response."""
    response = await call_next(request)

    for name, value in _SECURITY_HEADERS.items():
        if name == "Content-Security-Policy" and request.url.path in _DOCS_PATHS:
            continue
        response.headers[name] = value

    # HSTS only over HTTPS — sending it over plain HTTP is meaningless, and in
    # local dev it would pin localhost to https:// in the browser for a year.
    if request.url.scheme == "https":
        response.headers["Strict-Transport-Security"] = (
            "max-age=31536000; includeSubDomains"
        )

    return response
