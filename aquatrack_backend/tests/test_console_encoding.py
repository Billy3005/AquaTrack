"""Tests for _force_utf8_console: a log line must never be able to fail a request.

On Windows the console defaults to cp1252, which cannot encode the emoji this
codebase logs freely. On 2026-08-17 that turned a *successful* registration
into a bare 500: the user was committed, then `print("✅ User created …")`
raised UnicodeEncodeError, and the except block's traceback print — containing
the same character — raised a second time. Linux/Railway is UTF-8 and never saw
it, so nothing caught it before real testers did.
"""

import io
import sys

from app.main import _force_utf8_console

# The exact character that took registration down, plus a few the services log.
EMOJI = "✅ 🔥 💧 📧 —"


def _cp1252_stream() -> io.TextIOWrapper:
    """A stream that behaves like a default Windows console."""
    return io.TextIOWrapper(io.BytesIO(), encoding="cp1252", errors="strict")


def test_cp1252_stream_really_does_reject_emoji():
    """Guards the premise — if this ever stops raising, the rest is vacuous."""
    stream = _cp1252_stream()
    try:
        stream.write(EMOJI)
        stream.flush()
    except UnicodeEncodeError:
        return
    raise AssertionError("cp1252 accepted emoji; this test no longer proves anything")


def test_emoji_is_printable_after_reconfigure(monkeypatch):
    monkeypatch.setattr(sys, "stdout", _cp1252_stream())
    monkeypatch.setattr(sys, "stderr", _cp1252_stream())

    _force_utf8_console()

    # The failure mode is an exception, not wrong output.
    print(EMOJI)
    print(EMOJI, file=sys.stderr)
    sys.stdout.flush()
    sys.stderr.flush()


def test_survives_streams_that_cannot_be_reconfigured(monkeypatch):
    """Under pytest/gunicorn stdout may be a plain object with no reconfigure."""

    class Bare(io.StringIO):
        reconfigure = None

    monkeypatch.setattr(sys, "stdout", Bare())
    monkeypatch.setattr(sys, "stderr", Bare())

    _force_utf8_console()  # must not raise


def test_survives_reconfigure_raising(monkeypatch):
    """Setting up logging must never be the thing that stops the app booting."""

    class Hostile(io.StringIO):
        def reconfigure(self, **kwargs):
            raise ValueError("underlying stream is detached")

    monkeypatch.setattr(sys, "stdout", Hostile())
    monkeypatch.setattr(sys, "stderr", Hostile())

    _force_utf8_console()  # must not raise
