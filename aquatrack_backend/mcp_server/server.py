"""AquaTrack MCP Server.

Exposes the deployed AquaTrack REST API as Model Context Protocol tools so an
agent (the AquaTrack Coach) can reason over a user's hydration data and take
actions on their behalf — log a drink, check progress, adjust the daily goal —
without re-implementing any business logic.

Design: this server is a thin MCP <-> HTTP bridge. Each tool calls the existing
FastAPI backend over HTTP, so all business rules (hydration factors, XP, goal
resolution) stay in one place, and the MCP process stays dependency-light
(``mcp`` + ``httpx`` only — no FastAPI, no database driver).

Auth: every tool acts for exactly ONE user. The user's JWT access token is read
from ``AQUATRACK_USER_TOKEN`` and sent as a Bearer header on every call, so each
tool is scoped to the authenticated user and the agent never handles the
credential itself.

Environment:
    AQUATRACK_API_BASE_URL  Backend base URL (default http://localhost:8000)
    AQUATRACK_USER_TOKEN    A valid JWT access token for the acting user

Run (stdio):   python -m mcp_server.server
Inspect (UI):  mcp dev mcp_server/server.py
"""

import functools
import os
from datetime import date

import httpx
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("AquaTrack")

API_BASE = os.environ.get("AQUATRACK_API_BASE_URL", "http://localhost:8000").rstrip("/")

# Accepted drink types (matches the backend's IntakeLogCreate validator).
_LIQUID_TYPES = ("water", "tea", "coffee", "juice", "sports_drink", "other")


class ToolError(Exception):
    """A user-facing tool failure (bad input or missing auth)."""


def _client() -> httpx.Client:
    """Build an HTTP client bound to the API, authenticated as the session user."""
    token = os.environ.get("AQUATRACK_USER_TOKEN", "").strip()
    if not token:
        raise ToolError(
            "No AquaTrack user token. Set AQUATRACK_USER_TOKEN to a valid JWT "
            "access token before calling tools."
        )
    return httpx.Client(
        base_url=f"{API_BASE}/api/v1",
        headers={"Authorization": f"Bearer {token}"},
        timeout=20.0,
    )


def _today_progress(client: httpx.Client) -> dict:
    """Today's hydration progress (goal, effective intake, remaining, percent).

    Uses /stats/goals/progress?days=1 so the goal and today's totals come from
    one authoritative call.
    """
    resp = client.get("/stats/goals/progress", params={"days": 1})
    resp.raise_for_status()
    data = resp.json()
    goal = data["goal_info"]["daily_goal_ml"]
    today = data["daily_data"][-1] if data["daily_data"] else {}
    effective = today.get("total_effective_ml", 0)
    return {
        "daily_goal_ml": goal,
        "effective_intake_ml": effective,
        "remaining_ml": max(0, goal - effective),
        "percent_of_goal": round(today.get("progress_percentage", 0)),
        "log_count": today.get("log_count", 0),
        "goal_reached": bool(today.get("goal_achieved", False)),
    }


def _guard(fn):
    """Wrap a tool body so API/auth failures return a clean {error: ...} dict
    instead of crashing the agent's tool call.

    Uses functools.wraps so the wrapped function keeps its signature — FastMCP
    introspects it to build the tool's input schema.
    """

    @functools.wraps(fn)
    def wrapper(*args, **kwargs):
        try:
            return fn(*args, **kwargs)
        except ToolError as exc:
            return {"error": str(exc)}
        except httpx.HTTPStatusError as exc:
            return {
                "error": f"API error {exc.response.status_code}: "
                f"{exc.response.text[:200]}"
            }
        except httpx.HTTPError as exc:
            return {"error": f"Could not reach AquaTrack API: {exc}"}

    return wrapper


@mcp.tool()
@_guard
def get_today_hydration() -> dict:
    """Get the user's hydration progress for today.

    Returns the daily goal, the effective (hydration-adjusted) intake so far,
    how many ml remain, the percent of goal reached, and the number of logs.
    Call this to answer "have I drunk enough today?" or before deciding whether
    to nudge the user.
    """
    with _client() as client:
        return {"date": str(date.today()), **_today_progress(client)}


@mcp.tool()
@_guard
def log_water(volume_ml: int, liquid_type: str = "water") -> dict:
    """Log a drink the user just had, then return their updated daily progress.

    `volume_ml` is the physical volume in millilitres (1-2000). `liquid_type`
    is one of: water, tea, coffee, juice, sports_drink, other — the hydration
    factor is applied server-side, so pass the real volume, not an adjusted one.

    This TAKES AN ACTION on the user's behalf — only call it when the user
    actually drank something (or confirmed a Smart Scan result), never to
    answer a hypothetical question.
    """
    if liquid_type not in _LIQUID_TYPES:
        return {"error": f"liquid_type must be one of {list(_LIQUID_TYPES)}"}
    if not 1 <= volume_ml <= 2000:
        return {"error": "volume_ml must be between 1 and 2000"}

    with _client() as client:
        resp = client.post(
            "/intake/",
            json={
                "volume_ml": volume_ml,
                "liquid_type": liquid_type,
                "source": "agent",
            },
        )
        resp.raise_for_status()
        return {
            "logged": {"volume_ml": volume_ml, "liquid_type": liquid_type},
            **_today_progress(client),
        }


@mcp.tool()
@_guard
def get_weekly_stats() -> dict:
    """Get the user's hydration over the last 7 days.

    Returns each day's effective intake, percent of goal, and whether the goal
    was met, plus a summary (days achieved, achievement rate, average daily
    intake). Use this to spot trends ("you've missed your goal 3 days running")
    before giving advice.
    """
    with _client() as client:
        resp = client.get("/stats/goals/progress", params={"days": 7})
        resp.raise_for_status()
        data = resp.json()
        return {
            "daily_goal_ml": data["goal_info"]["daily_goal_ml"],
            "days_goal_achieved": data["goal_info"]["days_achieved"],
            "achievement_rate_percent": data["goal_info"][
                "achievement_rate_percentage"
            ],
            "average_daily_intake_ml": data["averages"]["average_daily_intake_ml"],
            "daily": [
                {
                    "date": d["date"],
                    "effective_ml": d["total_effective_ml"],
                    "percent_of_goal": round(d["progress_percentage"]),
                    "goal_reached": d["goal_achieved"],
                }
                for d in data["daily_data"]
            ],
        }


@mcp.tool()
@_guard
def update_daily_goal(goal_ml: int) -> dict:
    """Set the user's daily hydration goal, in millilitres (1000-5000).

    This TAKES AN ACTION — only call it when the user asks to change their goal,
    or when you proposed a new goal and they agreed. Returns the new goal and
    today's progress against it.
    """
    if not 1000 <= goal_ml <= 5000:
        return {"error": "goal_ml must be between 1000 and 5000"}
    with _client() as client:
        resp = client.put("/users/profile", json={"daily_goal_ml": goal_ml})
        resp.raise_for_status()
        return {"updated_daily_goal_ml": goal_ml, **_today_progress(client)}


@mcp.tool()
@_guard
def get_weather(latitude: float, longitude: float) -> dict:
    """Get current weather for a location (no API key — via Open-Meteo).

    Returns temperature (°C), relative humidity (%), and a hydration hint: hot
    or dry conditions mean the user should drink more. Use this for
    context-aware advice and to decide whether to suggest a higher goal.
    """
    resp = httpx.get(
        "https://api.open-meteo.com/v1/forecast",
        params={
            "latitude": latitude,
            "longitude": longitude,
            "current": "temperature_2m,relative_humidity_2m",
        },
        timeout=20.0,
    )
    resp.raise_for_status()
    current = resp.json().get("current", {})
    temp = current.get("temperature_2m")
    humidity = current.get("relative_humidity_2m")
    hint = "normal"
    if temp is not None and temp >= 32:
        hint = "hot — recommend drinking extra water"
    elif humidity is not None and humidity <= 30:
        hint = "dry air — recommend drinking extra water"
    return {
        "temperature_c": temp,
        "relative_humidity_percent": humidity,
        "hydration_hint": hint,
    }


@mcp.tool()
@_guard
def analyze_drink_photo(image_path: str) -> dict:
    """Estimate how much liquid is in a drink photo via Smart Scan (AI vision).

    `image_path` is a path to a local image file. Returns the detected
    container, estimated physical volume (ml), liquid type, and AI confidence.
    This only ESTIMATES — it does not log. After showing the user, call
    log_water with the estimated volume once they confirm.
    """
    try:
        with open(image_path, "rb") as fh:
            image_bytes = fh.read()
    except OSError as exc:
        return {"error": f"Cannot read image file: {exc}"}

    with _client() as client:
        resp = client.post(
            "/vision/estimate-volume",
            files={
                "image": (os.path.basename(image_path), image_bytes, "image/jpeg")
            },
            params={"save_to_history": True},
        )
        resp.raise_for_status()
        v = resp.json()
        return {
            "container": v.get("container_label"),
            "estimated_volume_ml": v.get("estimated_volume_ml"),
            "liquid_type": v.get("liquid_type"),
            "confidence_percent": round((v.get("confidence") or 0) * 100),
            "fill_level_percent": round((v.get("fill_level_percent") or 0) * 100),
        }


if __name__ == "__main__":
    mcp.run()
