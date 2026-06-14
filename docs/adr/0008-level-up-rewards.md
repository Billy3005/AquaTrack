# 0008 — Level-Up Rewards: coins + avatar, granted once by a high-water mark

- Status: Accepted
- Date: 2026-06-14

## Context

Reaching a new Level was, until now, a non-event: Total XP crossed a threshold,
the Level number ticked up, and nothing happened. There was a designed
celebration (`levelup.jsx`) and even a half-wired Flutter widget
(`level_up_celebration.dart`), but exploration found the whole path was **dead**:

- The celebration was triggered from `LevelScreen` (`screens/level_screen.dart`),
  but the router mounts `LevelScreenRedesign` — `LevelScreen` is never shown.
- The trigger read `levelState.isLevelingUp`, a flag set **only** by
  `level_provider.addXP()` — which uses a third, wrong XP curve (`100*level*1.5`,
  killed by ADR 0003) and which we removed from the log flow when XP became
  backend-authoritative (`syncFromServer`). `syncFromServer` patches the level
  number directly and does **not** detect a Level transition.

So there was no live level-up detection at all, and the designed reward chips
(`+120 xu`, theme unlock, frame unlock) had **no backing data**: per ADR 0003 and
CONTEXT.md, Achievements grant XP only, Coins come from Quests, and Avatars come
from the level/coin/streak rails. `/levels/rewards/preview` only carries a `title`
(rank name), a dead `avatar_2..9` id, and an unused `xp_bonus`.

The user's goal: make levelling feel rewarding — a celebration **and** a concrete
reward — without re-introducing the XP-curve drift ADR 0003 just eliminated, and
without letting users farm a spendable currency by replaying the moment.

## Decision

1. **Level-Up grants Coins.** Reaching Level N grants `(N-1)×10` Coins
   (1→2: 10, 2→3: 20, 3→4: 30, …). This adds a second Coin source alongside
   Quests; CONTEXT.md's **Coin** term is updated and a **Level-Up Reward** term is
   added. Coins are the only spendable currency (XP stays monotonic and
   non-spendable, unchanged).

2. **Grant is server-side and idempotent via a high-water mark.** A new
   `users.coins_granted_up_to_level` column (monotonic, default 1) records the
   highest Level already rewarded. A single function `reconcile_level_coins(db,
   user)` computes the current Level L from Total XP; if `L > marker`, it credits
   `Σ (n-1)×10` for `n ∈ (marker, L]`, advances the marker to L, and returns
   `coins_awarded`. Because Level is derived from monotonic Total XP, re-login and
   multi-device replay recompute the same L, find `L == marker`, and grant nothing.
   This mirrors the claim-row idempotency Quests use (`QuestClaim`), but a scalar
   high-water mark fits better: Levels are contiguous, monotonic, and never reset,
   so a per-Level ledger table would be overkill.

3. **Reconcile at every XP source.** Total XP can rise from three places — an
   intake log, a Quest claim, an Achievement claim. `reconcile_level_coins` is
   called from all three, and all three return a unified `level_progress`
   (`current_level`, `current_xp`, `xp_for_next_level`, `coins_awarded`). The
   high-water mark makes calling it from multiple places safe by construction.

4. **Avatars are the second reward, but stay on the existing rail.** When a crossed
   Level lands on an Avatar's level-rail Unlock Condition (`AvatarCatalog`,
   `levelReq ∈ (before, after]`), that Avatar is shown as unlocked in the
   celebration. This grants nothing new — Avatar ownership is already derived from
   `current_level` (ADR 0003 decision 5). The celebration only *surfaces* it; there
   is no double grant and `unlock_avatar_id` stays dropped.

5. **Detection for the visual is client-side; the grant is not.** The celebration
   is presentational, so it is driven by one global `ref.listen` on
   `levelNotifierProvider` at the app shell: when `currentLevel` increases (from any
   path, since all patch via `syncFromServer`), the overlay shows. Coins displayed
   come from `lastCoinsAwarded` (threaded into `LevelState` from the server
   response); avatars from the local catalog; rank from `/levels/rewards/preview`
   with carry-forward for Levels that define no title. A single listener — not a
   per-call-site delta check — guarantees no path is silently missed.

6. **Celebration may repeat; the Reward never does.** The overlay is allowed to
   replay (it's UI). Idempotency lives entirely in decision 2, so a re-shown
   celebration cannot re-grant Coins.

7. **The dead path is deleted, not revived.** The old `LevelUpCelebration` widget,
   the unmounted `LevelScreen`, and `addXP` / `isLevelingUp` / `clearLevelUpState`
   (wrong curve, dead) are removed. The new overlay ports `levelup.jsx`
   (sunburst, ripple rings, teardrop confetti, hexagon badge) to Flutter
   `CustomPaint` / `AnimationController` using `AppColors`, and respects
   `MediaQuery.disableAnimations`.

## Consequences

- Levelling is rewarding for the first time, with a grant that survives logout and
  multi-device without farming.
- Coin now has two sources (Quest, Level-Up). Anyone auditing the Coin economy must
  account for the level-up grant; the high-water mark is the single place it flows.
- A new column is added (`coins_granted_up_to_level`); no table. The migration
  **seeds the marker to each existing user's current Level** (derived from their
  Total XP), so existing users are **not** back-granted Coins for Levels reached
  before this feature shipped — only Level-Ups from now on pay out. New users start
  at the default (1) and earn from Level 2 upward. This avoids dropping a surprise
  pile of Coins (e.g. a Level-8 account would otherwise receive 280 at once).
- The visual fires from all three XP sources; quest/achievement claim and intake
  responses must all return the unified `level_progress` shape.
- `xp_bonus` in `/levels/rewards/preview` remains unused (granting XP for gaining XP
  is circular); the preview is consumed only for rank `title`.

## When to revisit

- If Coins should ever be grantable from a fourth source, keep the high-water mark
  as the *level* ledger only and add the new source independently — do not overload
  this marker.
- If a Level reward should include something non-monotonic (a consumable, a
  time-boxed theme), the scalar high-water mark no longer suffices; move to a
  per-Level claim table (mirror `QuestClaim`) and revisit decision 2.
