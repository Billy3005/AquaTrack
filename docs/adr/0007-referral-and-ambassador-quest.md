# ADR-0007: Referral System & Ambassador Quest

## Status
Accepted (un-defers the referral piece noted in ADR-0002)

## Context
"Đại Sứ Hydration" was the one Weekly Quest deferred in `quests_spec.md` / ADR-0002
because no referral infrastructure existed, holding the Weekly Completion Bonus at
3/3. AquaTrack already has full *in-app friend requests* (search username → request
→ accept), so "mời bạn bè" here means something different: bringing a **new person**
onto the app, not connecting two existing users. We needed a referral model that
counts toward a quest, resists fake-account farming, and fits the existing
derived-on-read quest architecture.

## Decision
Add a **Referral** concept distinct from Friend Request (see CONTEXT.md → Social &
Referral):

- **Per-user permanent Referral Code** stored on the user. One stable code, reusable
  indefinitely. Captured **only at registration** (optional field on the register
  screen, prefilled from a deep link when present); never attachable to an existing
  account, never self-applicable.
- **`referrals` table**: `(referrer_id, referred_id, created_at, validated_at)`.
  A row is created at the invited user's sign-up (pending); `validated_at` is stamped
  on the **Validation Moment = the referred user's first water log** (first
  `intake_logs` row).
- **Two-sided reward, granted once on validation**: the referred user receives a
  one-time **+50 Coin** welcome bonus; the referrer gets quest credit.
- **Ambassador Quest** (`hydration_ambassador`) becomes the 4th Weekly Quest:
  weekly, **target 1 Validated Referral** in the current week, reward **75 XP + 40
  Coin**. Quest progress stays **derived on read** — count `referrals` rows for the
  user where `validated_at` falls in the current weekly window. Because
  `weekly_bonus.target = len(WEEKLY_QUESTS)`, appending this quest raises the Weekly
  Completion Bonus from 3/3 to 4/4 automatically.

## Consequences

### Positive
- Stays inside the derived-on-read model (ADR-0002): the quest is one date-bounded
  `COUNT` over `referrals.validated_at`; no counters, no endpoint instrumentation
  beyond stamping `validated_at` at first log.
- Validating on first water log (not on sign-up) makes a referral mean a real,
  active user — farming empty accounts earns nothing.
- The Referral / Friend Request split keeps the glossary honest: two different verbs
  for two different actions.

### Negative / trade-offs
- The first-log hook (`intake` create path) gains a small responsibility: stamp
  `validated_at` and grant the welcome bonus once. This is the only write-path touch.
- A referral validated long after the code was shared counts in the week it
  *validates*, not the week it was sent — intentional, but worth knowing when reading
  weekly numbers.
- Weekly target 1 (not the spec's "⭐⭐⭐⭐ hardest" framing) was chosen so the
  Lucky Chest stays realistically reachable; pulling even one real new user per week
  is already a strong bar.

## Alternatives Considered
- **Validate at sign-up.** Simplest, but trivially farmable with throwaway accounts —
  rejected for a rewarded quest.
- **One-time invite codes per invite.** More control, but needs per-code lifecycle
  and generation UI; rejected in favour of one stable code per user.
- **Lifetime referral milestone outside the chest (target 3).** Better fit for slow
  referral behaviour, but would leave the Weekly Bonus permanently at 3/3 and miss
  the spec's intent of a 4th weekly quest — rejected.
- **Retroactive code entry (any time before first log).** More forgiving, but adds
  in-app "attach code later" UI and a second capture path; rejected for v1.
