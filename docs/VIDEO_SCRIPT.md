# AquaTrack — 5-minute demo video script

**Target: ≤ 5:00, published to YouTube. Track: Concierge Agents.**

Narration is written in English for international judges; the app and agent
reply in Vietnamese on screen (authentic) — optionally do a Vietnamese voiceover
with English subtitles. Each block lists **[SCREEN]** (what to show) and
**[VO]** (what to say). Keep it tight — aim to land under 5:00.

---

### 0:00–0:30 · Hook + problem

**[SCREEN]** Open on the AquaTrack app home (the living water drop). Quick cuts of
a person tapping repeatedly to log water, squinting at a glass to guess ml.

**[VO]** "Drinking enough water is a tiny habit with a huge payoff — but every
hydration app makes *you* do the work: guess every volume, tap to log, remember
your goal, figure out if today's heat means drink more. That friction is why
people quit. AquaTrack fixes it with an agent that does the work for you."

### 0:30–1:00 · Why an agent

**[SCREEN]** Simple text/animation: a question → multiple tool icons (progress,
weather, photo, log) → an answer.

**[VO]** "Why an *agent* and not a feature? Because the useful actions are
multi-step: to answer 'should I drink more today?' you read the goal, read
intake, check the weather, then decide — and maybe change the goal, but only with
permission. That's reasoning across tools, in an order that depends on what the
user said. That's what an agent does."

### 1:00–1:45 · Architecture

**[SCREEN]** Show the architecture diagram from the README (Agent → MCP Server →
REST API → Postgres/R2/Claude Vision). Highlight each box as you name it.

**[VO]** "Three layers. A FastAPI backend holds all the logic and runs on
Railway. An MCP server exposes that backend as agent tools over the Model Context
Protocol — it's a bridge, not a rewrite, so logic lives in one place. And the
Coach Agent is a Claude tool-use loop that calls those tools to reason and act.
The agent talks to the *deployed* production API, with the user's token — it can
never bypass auth."

### 1:45–3:45 · Demo (the core — show the agent working)

**[SCREEN]** Terminal running `python -m agent.coach_agent`. Type each message;
let the inline `[tool] ...` lines show the agent calling tools, then its reply.

**Scenario 1 — log + status (≈40s)**
> You: *"Mình vừa uống 1 ly 300ml, hôm nay đủ chưa?"*
**[SCREEN]** Show `[tool] log_water(...)` → `[tool] get_today_hydration(...)` →
Vietnamese answer with updated progress.
**[VO]** "I tell it I drank 300 ml. It *logs* the drink, reads my progress, and
tells me where I stand — one sentence, in Vietnamese."

**Scenario 2 — weather-aware, confirm before acting (≈40s)**
> You: *"Hà Nội đang nóng, mình có cần uống thêm không?"*
**[SCREEN]** `[tool] get_weather(...)` → agent proposes a higher goal and asks.
Then: *"Ừ, nâng goal đi"* → `[tool] update_daily_goal(...)`.
**[VO]** "It checks the real weather, factors in the heat, and *proposes* a higher
goal — then waits for my yes before changing anything. A concierge that quietly
rewrites your targets isn't one you'd trust."

**Scenario 3 — Smart Scan in the loop (≈40s)**
> You: *"Đây là ảnh ly nước của mình"* (provide a photo path)
**[SCREEN]** `[tool] analyze_drink_photo(...)` → estimate shown → on confirm,
`[tool] log_water(...)`.
**[VO]** "It runs an AI Smart Scan on a photo, shows the estimate, and logs it
once I confirm. Same agent, more tools — no extra UI."

**[SCREEN]** (Optional 10s) Cut to the MCP Inspector showing the six tools.
**[VO]** "Those tools are a real MCP server — here they are in the Inspector."

### 3:45–4:30 · The build

**[SCREEN]** Quick scroll through the repo: `mcp_server/`, `agent/`, the README.

**[VO]** "Built with Claude for the agent and for Smart Scan, the Model Context
Protocol for tools, FastAPI plus Postgres for the API, and Cloudflare R2 for
durable image storage. The cleanest decision: make the MCP server a lightweight
HTTP bridge instead of importing the backend — it dodged a dependency conflict
and meant the agent talks to the real deployed API."

### 4:30–5:00 · Security, deployability, close

**[SCREEN]** Show the README's Security section; the Railway dashboard (deployed);
the architecture diagram once more.

**[VO]** "Because it's a concierge handling personal data: every action is scoped
to the user by JWT, the agent never sees the credential, and it confirms before
changing anything. It's deployed and reproducible. AquaTrack turns counting water
into a conversation with an assistant that already knows your numbers — and is
allowed to act on them, safely."

**[SCREEN]** End card: app name + "Concierge Agents" + repo URL.

---

## Recording tips

- Pre-set the three terminal messages so you can paste them quickly and stay
  under time.
- Use a seeded demo user with a few logs already, so progress numbers look real.
- Set `AQUATRACK_AGENT_MODEL=claude-sonnet-4-6` (or opus) for crisp reasoning.
- Record the terminal at a readable font size; the inline `[tool]` lines are the
  star — make sure they're legible.
- If a tool call is slow, cut the dead air in editing; keep the pace up.
