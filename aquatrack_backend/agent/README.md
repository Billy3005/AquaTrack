# AquaTrack Coach Agent

A personal **hydration concierge**: it reasons over the user's data and *takes
actions* on their behalf — log a drink, check progress, adjust the daily goal,
read the weather, run a Smart Scan — instead of being a passive chatbot.

It is the **Agent** piece of the capstone, and it consumes the **MCP Server**
piece, so the two compose:

```
  You ── "hôm nay uống đủ chưa?" ──►  Coach Agent (Claude, tool-use loop)
                                              │ launches + drives via MCP (stdio)
                                              ▼
                                      AquaTrack MCP Server
                                              │ HTTP + JWT
                                              ▼
                                      AquaTrack REST API (Railway)
```

The agent connects to `../mcp_server/server.py` as an MCP client, lists its
tools, and runs a tool-use loop with Claude: Claude picks tools, results flow
back, repeat until it has an answer or has completed an action.

## Setup

One venv runs both the agent and the MCP server it spawns. Keep it separate from
the backend venv:

```bash
cd aquatrack_backend/agent
python -m venv .venv && . .venv/Scripts/activate   # Windows
# source .venv/bin/activate                        # macOS/Linux
pip install -r requirements.txt
```

## Configuration

```bash
export ANTHROPIC_API_KEY="sk-ant-..."
export AQUATRACK_API_BASE_URL="https://<your-app>.up.railway.app"
export AQUATRACK_USER_TOKEN="<JWT access token from /auth/login>"
# optional:
export AQUATRACK_AGENT_MODEL="claude-sonnet-4-6"   # default
```

(Get `AQUATRACK_USER_TOKEN` by logging in — see `../mcp_server/README.md`.)

## Run

One-shot:

```bash
cd aquatrack_backend
python -m agent.coach_agent "Hôm nay mình uống đủ chưa?"
```

Interactive chat:

```bash
python -m agent.coach_agent
```

Tool calls are printed inline (`[tool] log_water({'volume_ml': 250, ...})`) so you
can watch the agent reason and act — useful for the demo video.

## Demo scenarios

- **"Hôm nay mình uống đủ chưa?"** → `get_today_hydration`, summarises progress.
- **"Mình vừa uống 1 ly nước 300ml"** → `log_water(300, water)`, confirms new total.
- **"Trời Hà Nội nóng không, mình có cần uống thêm?"** → `get_weather(...)` →
  advises, may propose a higher goal (asks before `update_daily_goal`).
- **"Tuần này mình thế nào?"** → `get_weekly_stats`, points out trends.

## Security (Concierge track)

- Every tool call is scoped to one user via their JWT; the agent never sees the
  credential (it lives in the MCP server's env).
- The agent **confirms before data-changing actions** (`log_water`,
  `update_daily_goal`) per the system prompt — it won't log hypotheticals or
  change goals without agreement.
- No secrets in code: all keys/tokens come from the environment.
