# AquaTrack: An AI Hydration Concierge

### Subtitle: A personal agent that reasons over your hydration, reads the weather and your photos, and takes action so you don't have to.

**Track: Concierge Agents**

---

## The problem

Hydration is the smallest of daily habits with one of the largest payoffs —
energy, focus, skin, mood, long-term health. And yet almost every hydration app
fails the same way: it is a **counter**, not an assistant. It pushes all the work
onto the user. You have to estimate how much is in every glass, tap to log it,
remember what your goal even is, and somehow know that a 34 °C afternoon means you
should be drinking more than usual. That friction — many tiny decisions, repeated
all day — is exactly why people install these apps and abandon them within a week.

The interesting problem is not "count millilitres." It is "remove the decisions."
A good hydration assistant should already know your numbers, understand your
context, and do the boring parts for you — so the habit costs you almost nothing.

## Why an agent

This is a textbook case for an **agent** rather than a feature, because the useful
actions are inherently *multi-step and context-dependent*:

- To answer *"have I drunk enough today?"* the assistant must read your goal and
  your intake and compare them.
- To answer *"it's hot, should I drink more?"* it must fetch the weather, reason
  about heat, and possibly propose a new goal — then change it only if you agree.
- To handle *"I just had a 300 ml glass"* it must log the drink **and** report
  your updated standing.
- To handle a photo of a bottle it must run vision, show the estimate, and log it
  on confirmation.

None of these is a single prompt-and-response. Each requires the model to choose
the right tools, in the right order, based on what you actually said, and to take
an action with real consequences. That is what an agentic tool-use loop does well,
and what makes the difference between a chatbot that *talks about* hydration and a
concierge that *manages* it.

## The solution

AquaTrack is a hydration app whose centrepiece is the **Coach Agent**. You speak
to it in natural language and it orchestrates everything else:

> **You:** *"Mình vừa uống 1 ly 300ml, Hà Nội đang nóng — hôm nay mình ổn không?"*
> **Coach:** *(checks weather → logs the drink → reads progress)* "Đã log 300ml.
> Hà Nội 34°C nên cơ thể mất nước nhanh; bạn đang ở 1.1/2.5L (44%). Mình đề xuất
> nâng goal hôm nay lên 2.8L — đồng ý không?"

The agent decided, on its own, to call three tools and to *ask* before changing
the goal — because changing a goal is an action with consequences, and a
concierge that quietly rewrites your targets is not one you trust. That trust
boundary is central to the Concierge track, and it is enforced in the agent's
system prompt: read-only tools are used freely; data-changing tools
(`log_water`, `update_daily_goal`) require that the action reflects what the user
actually wants.

## Architecture

The system is three composable layers, each a separate process with a clean
boundary:

```
You ──►  Coach Agent (Claude tool-use loop)
              │ Model Context Protocol (stdio)
              ▼
        AquaTrack MCP Server  ──HTTP + JWT──►  AquaTrack REST API (FastAPI, Railway)
              │                                       │
              └─► Open-Meteo (weather)         Postgres · Cloudflare R2 · Claude Vision
```

**1. REST API (FastAPI).** The existing AquaTrack backend holds all business
logic: hydration factors per drink type, XP and streaks, daily-goal resolution,
JWT authentication, and Smart Scan (Claude Vision with structured outputs that
estimates a container's capacity and fill level, then computes volume
server-side). It persists to managed Postgres and stores scan images in
Cloudflare R2.

**2. MCP Server.** A thin **Model Context Protocol** server that exposes the API's
capabilities as agent tools. Crucially, it is a *bridge*, not a reimplementation:
each tool makes an HTTP call to the REST API with the user's JWT, so hydration
factors, XP and goal logic stay in exactly one place. It ships six tools —
`get_today_hydration`, `get_weekly_stats`, `log_water`, `update_daily_goal`,
`get_weather` (via key-less Open-Meteo), and `analyze_drink_photo` (Smart Scan).

**3. Coach Agent.** A Claude tool-use loop that launches the MCP server as a
client (stdio), lists its tools, and runs the agentic loop: Claude picks tools,
the MCP server executes them against the live API, results return, and the loop
continues until the user's request is answered or an action is complete.

### Why this decomposition

The cleanest decision in the build was making the MCP server a **dependency-light
HTTP bridge** instead of importing the backend's code. The MCP SDK pulls a newer
Starlette than FastAPI pins, so importing the app into the MCP process caused a
hard dependency conflict. Bridging over HTTP instead removed the conflict
entirely, kept the MCP process tiny (`mcp` + `httpx`), and — as a bonus —
strengthened the **Deployability** story: the agent talks to the *already-deployed*
production API on Railway, exactly as a real client would. It also keeps the
boundary honest: the agent layer cannot accidentally bypass the API's auth or
validation, because HTTP + JWT is the only way in.

## The build

The capstone work layered an agent on top of a real, deployed app:

- **Smart Scan, made reliable.** The vision feature called Claude with structured
  outputs (`output_config`), but the deployed SDK was pinned to a version that
  predated that parameter — so every scan silently failed into a zero-confidence
  fallback. Diagnosing this (the fallback *looked* like a valid result) and
  bumping the SDK turned Smart Scan from broken to working in production.
- **Durable storage.** Railway's container disk is ephemeral, so collected scan
  images — the future training set — were being wiped on every redeploy. Adding a
  small S3-compatible storage service routed images to Cloudflare R2 (zero egress,
  ideal for an ML dataset), with a local-disk fallback for dev.
- **MCP server.** Six tools wrapping the REST API, each scoped to one user via
  their JWT, with clean `{error: ...}` results so a failure never crashes the
  agent loop. Verified with the MCP Inspector.
- **Coach Agent.** A Claude tool-use loop consuming the MCP server, with a
  concierge system prompt (reply in Vietnamese, be concise, confirm before
  acting, use weather for context). One-shot and interactive modes; tool calls
  are printed inline so the reasoning is visible.

**Technologies:** Claude (Anthropic) for the agent loop and for Smart
Scan; the Model Context Protocol (`mcp`) for tools; FastAPI + SQLAlchemy +
Postgres for the API; Cloudflare R2 for images; Open-Meteo for weather; Flutter +
Riverpod for the app.

## Demo

The five-minute video walks through:

1. **The agent reasoning live** — *"Mình vừa uống 1 ly 300ml, hôm nay đủ chưa?"* →
   the terminal shows `[tool] log_water(...)` then `[tool] get_today_hydration(...)`
   then a Vietnamese answer with the updated progress.
2. **Context-aware advice** — a weather question triggers `get_weather`, and the
   agent proposes a higher goal and waits for consent before `update_daily_goal`.
3. **Smart Scan in the loop** — a drink photo is estimated by `analyze_drink_photo`
   and, on confirmation, logged via `log_water`.
4. **The MCP Inspector** — showing the six tools the agent has, proving the agent
   and MCP-server layers really compose.

## Security & deployability

Because this is a **Concierge** agent handling personal data, both were
first-class, not afterthoughts:

- **Per-user isolation:** every tool call carries the user's JWT; the API enforces
  ownership of all data and actions.
- **The agent never sees credentials:** the JWT lives in the MCP server's
  environment, never in tool arguments or the model's context.
- **Confirm before acting:** data-changing tools require user agreement, enforced
  by the system prompt.
- **No secrets in code:** every key and token comes from the environment; `.env`
  is gitignored, and the repository was scanned (working tree + git history)
  before being made public.
- **Deployed and reproducible:** the backend runs on Railway with managed
  Postgres and Cloudflare R2; the same `.env.example` reproduces it anywhere, with
  SQLite + local-disk fallbacks for development.

## What I learned

The biggest lesson was that **the hard part of an agent is the boundaries, not the
prompt.** Deciding where business logic lives (the API, never the agent), how the
agent reaches it (HTTP + JWT, so it can't bypass auth), and when it is allowed to
act (confirm-before-write) shaped the whole design — and those decisions are what
make the agent trustworthy enough to hand real actions to. The dependency conflict
that pushed the MCP server toward an HTTP bridge turned out to be a gift: it
produced a cleaner, more honest architecture than importing the code would have.

The second lesson was about **silent failure**. The Smart Scan bug returned a
plausible-looking fallback on every call, so nothing *looked* broken — the cost of
swallowing errors is that they become invisible. Surfacing failures (clean tool
errors, real logs) is what lets an agent be debugged at all.

## Course concepts applied

| Concept | Where |
|---|---|
| **MCP Server** | `aquatrack_backend/mcp_server/` — six tools bridging the REST API |
| **Agent / multi-step tool use** | `aquatrack_backend/agent/coach_agent.py` |
| **Deployability** | Railway + managed Postgres + Cloudflare R2, reproducible from `.env.example` |
| **Security features** | JWT per-user isolation, confirm-before-action, no secrets in code |

AquaTrack turns a habit-tracking chore into a conversation with an assistant that
already knows your numbers — and, more importantly, is allowed to act on them
safely. That is the difference between an app that counts water and a concierge
that keeps you hydrated.
