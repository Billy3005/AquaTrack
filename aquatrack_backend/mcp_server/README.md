# AquaTrack MCP Server

A [Model Context Protocol](https://modelcontextprotocol.io) server that exposes
AquaTrack's hydration capabilities as agent tools. It lets the **AquaTrack Coach
agent** reason over a user's data and *take actions* on their behalf — log a
drink, check progress, adjust the daily goal, read the weather, run a Smart Scan
— instead of being a passive chatbot.

## Architecture

```
Coach Agent (Claude, tool-use loop)
        │  MCP protocol (stdio / Inspector)
        ▼
AquaTrack MCP Server  ──HTTP + JWT──►  AquaTrack REST API (FastAPI, Railway)
                                              │
                                       Postgres · R2 · Claude Vision
```

The server is a thin **MCP ⇄ HTTP bridge**: every tool calls the existing
backend over HTTP, so all business logic (hydration factors, XP, goal
resolution) stays in one place and the MCP process needs only `mcp` + `httpx`
(no FastAPI, no DB driver).

## Tools

| Tool | Action? | What it does |
|---|---|---|
| `get_today_hydration` | read | Today's goal, effective intake, remaining ml, % of goal |
| `get_weekly_stats` | read | Last 7 days: per-day progress + achievement rate |
| `log_water(volume_ml, liquid_type)` | **action** | Logs a drink; returns updated progress |
| `update_daily_goal(goal_ml)` | **action** | Sets the daily goal (1000–5000 ml) |
| `get_weather(latitude, longitude)` | read | Current temp + humidity (Open-Meteo, no key) + hydration hint |
| `analyze_drink_photo(image_path)` | read | Smart Scan: estimate volume/type/confidence from a photo |

## Setup

Use a **separate virtualenv** from the backend (mcp pulls a newer Starlette that
conflicts with the backend's FastAPI pin):

```bash
cd aquatrack_backend/mcp_server
python -m venv .venv && . .venv/Scripts/activate   # Windows
# source .venv/bin/activate                        # macOS/Linux
pip install -r requirements.txt
```

## Configuration

Two environment variables scope every tool call to one authenticated user:

| Var | Default | Notes |
|---|---|---|
| `AQUATRACK_API_BASE_URL` | `http://localhost:8000` | Backend base URL (e.g. the Railway URL) |
| `AQUATRACK_USER_TOKEN` | — | A valid JWT **access token** for the acting user |

Get a token by logging in against the backend:

```bash
curl -s -X POST "$AQUATRACK_API_BASE_URL/api/v1/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"email":"you@example.com","password":"..."}' | jq -r .access_token
```

```bash
export AQUATRACK_API_BASE_URL="https://<your-app>.up.railway.app"
export AQUATRACK_USER_TOKEN="<paste access_token>"
```

## Run & test with MCP Inspector

The Inspector is a UI to call tools by hand and watch requests/responses:

```bash
# from aquatrack_backend/, with the mcp venv active
mcp dev mcp_server/server.py
```

Then in the Inspector: open **Tools**, call `get_today_hydration` (should return
your goal + progress), then `log_water` with `volume_ml=250`, and confirm the
progress increases. `get_weather` with your lat/long needs no token.

## Run as a stdio server (for the agent)

```bash
python -m mcp_server.server
```

The Coach agent (Milestone 2) launches this and drives the tool-use loop.

## Security

- **Per-user isolation** — every tool sends the user's JWT; the API enforces
  that data and actions belong to that user only.
- **The agent never handles credentials** — the token lives in the server's
  environment, not in tool arguments or the model's context.
- **No secrets in code** — tokens and URLs come from the environment.
- Failures (bad token, unreachable API, bad input) return a clean
  `{"error": ...}` instead of crashing the agent loop.
