"""Seed today's water logs for the demo user, so the video shows healthy
progress instead of an almost-empty day.

Logs a realistic morning-to-afternoon set of drinks for TODAY via the AquaTrack
REST API, using the same auth as the agent. Run it right before recording.

PowerShell:
    $env:AQUATRACK_API_BASE_URL="https://<your-railway-url>"
    $env:AQUATRACK_USER_TOKEN="<jwt access token>"
    python scripts/seed_demo.py

Notes:
- Uses only the Python standard library, so it runs without installing anything.
- Re-running ADDS more logs (it does not reset). Tune the DRINKS list below to
  hit the total you want shown on camera.
"""

import json
import os
import sys
import urllib.error
import urllib.request

BASE = os.environ.get("AQUATRACK_API_BASE_URL", "http://localhost:8000").rstrip("/")
TOKEN = os.environ.get("AQUATRACK_USER_TOKEN", "").strip()

# (volume_ml, liquid_type) — a believable day, ~1300 ml of intake.
# Leaves room so the live "log 300 ml" moment in the demo pushes you near goal.
DRINKS = [
    (250, "water"),
    (200, "coffee"),
    (300, "water"),
    (250, "tea"),
    (300, "water"),
]


def _request(method: str, path: str, payload: dict | None = None) -> dict:
    headers = {"Authorization": f"Bearer {TOKEN}"}
    data = None
    if payload is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(payload).encode()
    req = urllib.request.Request(
        f"{BASE}/api/v1{path}", data=data, headers=headers, method=method
    )
    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        sys.exit(f"API error {exc.code} on {method} {path}: {exc.read().decode()[:200]}")
    except urllib.error.URLError as exc:
        sys.exit(f"Could not reach API at {BASE}: {exc}")


def main() -> None:
    if not TOKEN:
        sys.exit("Set AQUATRACK_USER_TOKEN first (see the agent README).")

    print(f"Seeding {len(DRINKS)} drinks for today via {BASE} ...")
    for volume_ml, liquid_type in DRINKS:
        _request(
            "POST",
            "/intake/",
            {"volume_ml": volume_ml, "liquid_type": liquid_type, "source": "seed"},
        )
        print(f"  + {volume_ml} ml {liquid_type}")

    summary = _request("GET", "/intake/summary/today")
    print(
        f"\nToday: {summary['total_volume_ml']} ml logged "
        f"({summary['total_effective_ml']} ml effective), "
        f"{summary['log_count']} entries."
    )
    print("Run the agent now — 'hôm nay đủ chưa?' will show real progress.")


if __name__ == "__main__":
    main()
