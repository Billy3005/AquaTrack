# ADR-0002: Derived-on-Read Quest Progress

## Status
Accepted

## Context
The Quests feature (`quests_spec.md`) needs to track per-user progress on daily and weekly goals — water intake, Smart Scans, friend reminders, AI Coach chats, streaks — then let users claim XP and Coin rewards once per Reset Period. The activity that drives most quests is *already persisted* in existing tables (`intake_logs`, `daily_summaries`, `scan_history`, `conversations`, `users.current_streak`). The open question was how to represent quest progress: compute it on demand from those source tables, or maintain dedicated progress counters updated on every relevant action.

## Decision
Quest progress is **derived on read**. When the client requests quests, the backend queries the existing source tables for the current Reset Period and computes each quest's progress on the fly. No progress counters are stored.

The only persisted quest state is the **Claim**: a `quest_claims` row keyed by `(user_id, quest_id, period_key)`. The unique key both enforces single-claim-per-period and makes "reset" implicit — when a new `period_key` begins, no claim exists and the quest is available again. No cron/scheduler is required for resets.

`period_key` is computed in the user's local timezone (`users.timezone`): daily as the local calendar date, weekly as the local ISO week.

Two gaps are handled outside this pattern:
- **Friend reminders** are not currently persisted in a queryable form (they overwrite `users.push_token`), so a small `reminder_log` table is added purely to make the "Hội Bạn Cùng Uống" quest countable.
- **Referral** ("Đại Sứ Hydration") has no backing system and is **deferred**, dropping the weekly set to 3 quests and the weekly Completion Bonus condition to 3/3.

## Consequences

### Positive
- No counter drift: progress always reflects the true source data, even if a scan or log is later deleted.
- No instrumentation of `intake`, `vision`, or `coach` endpoints — those stay untouched.
- Resets are free and timezone-correct; no scheduled jobs to operate or recover.
- New quest types over the same source data are cheap to add (a new query, not new write paths).

### Negative
- Read cost: each quests request runs several aggregate queries instead of reading precomputed counters.
- Source tables become an implicit contract — changing their schema can break quest derivation.
- One inconsistency in the model: `reminder_log` exists only as a derivation source, not as a general counter.

### Mitigations
- Quest reads are infrequent (one screen) and queries are per-user, date-bounded, and indexed.
- A Claim is permanent for its period regardless of later source-data changes, so claimed rewards are never revoked.

## Alternatives Considered
- **Counter table + endpoint instrumentation**: a `quest_progress` row per quest/user/period, incremented from each action endpoint. Rejected — requires touching every source endpoint, introduces drift between counters and reality, and needs explicit reset logic.
- **Pure spec-vs-frontend reconciliation deferred to client**: let the frontend keep computing from local data. Rejected — quests must be server-authoritative (anti-cheat: streak and scan counts are validated server-side per spec).
