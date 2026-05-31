# ADR-0003: Friends feature — reshape backend to the frontend contract, derive social data on read

## Status

Accepted (2026-05-31)

## Context

The Friends feature (Bạn bè, tab #5) already has a complete, wired Flutter UI
(`friends_screen_redesign.dart` + `friends_provider.dart` + `social_service.dart` +
`friend_model.dart`). A backend also exists (`/friends/*` in `friends.py`,
`social_service.py`, `crud/friend.py`, `crud/leaderboard.py`). They were built
independently and **never connected**: every read path mismatches.

Key mismatches found during the grill:

- **Envelope shape**: FE expects `{ "friends": [...] }`, `{ "requests": [...] }`,
  `{ "leaderboard": [...] }`; BE returns bare arrays / a different object.
- **Domain model**: FE's `Friend` is hydration-centric (today's `daily_progress`,
  `status` mood, `is_online`, `current_streak`); BE's `FriendResponse` is
  relationship/leveling-centric (level, XP, friendship duration) and exposes none
  of the hydration fields the UI draws.
- **Leaderboard**: FE expects a flat weekly list; BE reads from a stored
  `LeaderboardEntry` table populated by `update_weekly_leaderboards()` — a scheduled
  task that **nothing ever calls**, so the leaderboard is always empty. Its "week"
  also differs from the ISO week the Quests feature uses.

The central questions: **who adapts to whom, and where does social data live?**

## Decision

1. **Reshape the backend to the frontend contract.** The Flutter UI is the finished,
   high-fidelity artifact; we keep it unchanged and make `/friends/*` responses match
   exactly what `social_service.dart` parses (envelopes, nested `from_user`, field
   names). The only FE change allowed is adding `@JsonKey` snake_case annotations to
   two model fields (`displayName`, leaderboard `userId`) so the backend can stay
   snake_case — this touches models, not UI.

2. **Derive per-friend hydration and the weekly leaderboard on read**, consistent
   with ADR-0002. A friend's `daily_progress`, `status`, `is_online`, and the weekly
   leaderboard are computed per-request from `daily_summaries` / `users.current_streak`
   / `users.last_login`. Nothing new is stored.

   - **Friend Status** from today's progress: ≥80% đủ nước, 40–80% hơi thấp,
     <40% đang khát, no activity today → offline.
   - **Online** = `last_login` within ~15 minutes. To make this meaningful, the
     auth layer touches `last_login` on each authenticated request (a recent-activity
     timestamp, not just a sign-in time).
   - **Day boundary**: `DailySummary.date` is written as the server **UTC** calendar
     date ([intake.py](../../aquatrack_backend/app/api/v1/endpoints/intake.py)),
     so derivation queries match on UTC date too. Choosing local-date derivation here
     would silently miss rows. The day-boundary mismatch for non-UTC users is a known
     trade-off recorded below.
   - **Weekly Leaderboard** = the user plus their friends, ranked by average
     goal-achievement % over the **ISO week** (tie-break: total ml). Same week
     definition as Weekly Quests. Computed with a **single** summary query for all
     participants (no N+1).

3. **Deprecate the stored leaderboard.** `LeaderboardEntry` (model + crud + the
   never-run scheduled task) is left dormant — not deleted, not migrated — and the
   new endpoint ignores it. Removal can happen later if it stays unused.

4. **Production hardening.** Responses use explicit Pydantic schemas (validation +
   OpenAPI docs), not bare `dict`. Reminders are rate-limited per day to stop spam
   and prevent inflating the `friend_reminder` quest. Mutual-invite collision
   (A→B pending, then B→A) **auto-accepts** into a friendship instead of erroring.
   Self-friending is rejected. Schema changes ride the existing `create_all` +
   `_ensure_*_columns` startup path (no Alembic): `reminder_logs` is auto-created;
   `users.status` / `users.is_online` already exist on the model.

Out of scope (deferred): challenge / group challenge, and the hardcoded
"Có thể bạn biết" suggestions. Those UI elements are hidden/disabled until a backend
exists.

## Consequences

**Positive**

- The polished UI ships intact; no UX regression.
- One consistent "week" and one derived-on-read model across Quests and Friends.
- Leaderboard works immediately from real data — no cron, no empty table.
- Friends' standings are always truthful (no counter/snapshot drift).

**Negative**

- Per-friend hydration is recomputed each request (N friends × today's summary);
  acceptable at current scale, cacheable later.
- A friend's daily hydration progress is visible to friends — intended for this
  social app, but it is a privacy choice worth revisiting if scope changes.
- `LeaderboardEntry` becomes dead code until explicitly removed.
- "Online" is an approximation; touching `last_login` per request adds one small
  write per authenticated call and still only approximates true presence.
- **Day boundary is UTC, not the user's timezone.** For a UTC+7 user the social
  "day" rolls over at 07:00 local. Accepted for now to stay consistent with how
  `DailySummary` is written; revisiting requires changing summary writes, not just
  derivation. (Note: this differs from Quests, which derive on the local day — the
  two will be reconciled when summary writes move to local dates.)
