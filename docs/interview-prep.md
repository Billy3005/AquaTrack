# Wafubi — Interview Prep: Security & Auth Architecture

The full version of the case-study "Security" section. Every claim here is
grep-verifiable against the code — this doc exists so I can defend the design in
an interview instead of reciting marketing lines.

## The auth model in one sentence

Wafubi's agent is a **single-user, one-process-per-user** design (the standard
Claude-Desktop MCP model): the MCP server runs locally over stdio and carries the
acting user's JWT in its environment.

## How a request flows

```
Coach Agent (Claude tool-use loop)
  └─ launches mcp_server/server.py as a subprocess over stdio
       env passes AQUATRACK_USER_TOKEN + AQUATRACK_API_BASE_URL down
  └─ MCP server reads AQUATRACK_USER_TOKEN once, at process level
       sends `Authorization: Bearer <jwt>` on every REST call
  └─ FastAPI resolves the user via Depends(get_current_user_id) — from the JWT
       queries filter on that user_id; ownership enforced server-side
```

Code anchors:
- `agent/coach_agent.py` — `StdioServerParameters(..., env=dict(os.environ))`, launched via `stdio_client`.
- `mcp_server/server.py:47-55` — reads `AQUATRACK_USER_TOKEN`, attaches `Bearer` header.
- `app/api/deps.py` / `app/core/security.py:get_current_user_id` — JWT → user_id.

## Four properties I can defend

1. **Single-user by design.** One process = one user. This is deliberate, not an
   oversight — it matches how MCP servers run on a desktop today.

2. **The token never enters the model's context.** The agent *process* holds the
   JWT in its env (it must, to pass it to the subprocess), but the token never
   appears in a tool argument or in any message sent to Claude. The LLM reasons
   over tool names and results only. This is the property most people miss.

3. **Ownership is enforced server-side, not trusted from the client.** Every
   data endpoint derives identity from `Depends(get_current_user_id)` (JWT).
   **No endpoint accepts `user_id` from a path/query/body parameter** — verified:

   ```bash
   # 0 hits = no client-supplied user_id (the usual IDOR source)
   rg -n 'user_id.*(Query|Body|Path)\(|\{user_id\}' app/api/v1/endpoints/
   ```

4. **No secrets in code.** All keys/tokens come from the environment; `.env` is
   gitignored. The agent never handles credentials as data.

## Known limit & the honest next step

This design is **single-user**: 100 users would mean 100 processes, each with its
own token in env. That's fine for a desktop agent; it does not scale to a hosted
multi-tenant service.

To go multi-user I would:
- move the JWT from a process-level env var to a **per-request** credential,
- put a **session layer** in front of the agent to bind each request to a user,
- and run the agent server-side (or, as planned, embed it in the Flutter client
  so each device carries its own session).

That is exactly why the roadmap's next step is "move the agent into the Flutter
client" — it is the architectural unlock for multi-user, not just a UI nicety.

## Cleanup done for this claim to be true

`POST /coach/chat` previously had its auth dependency commented out
(`# Temporarily bypass auth`) and returned dummy data with debug `print()`s — a
leftover from an earlier phase, off the agent path. Before making the blanket
ownership claim, auth was re-enabled: it now uses `Depends(get_current_user_id)`
+ `get_db` and reads real per-user stats via `intake_log_crud.get_daily_stats`.
No endpoint in `app/api/v1/endpoints/` bypasses auth anymore.

## Anticipated interview questions

- *"100 users, 100 processes?"* → Yes, by design; single-user MCP model. Multi-user
  is a per-request-JWT + session-layer change (see above).
- *"How do you know there's no IDOR?"* → The grep above: no endpoint takes `user_id`
  from the client; identity always comes from the verified JWT.
- *"Where does the model see the token?"* → It doesn't. Token lives in the MCP
  server's env; the model context only holds tool names + results.
