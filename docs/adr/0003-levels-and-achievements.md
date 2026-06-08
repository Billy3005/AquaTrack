# 0003 — Levels & Achievements: one engine, one catalog, claim-to-earn

- Status: Accepted
- Date: 2026-06-07

## Context

The Level screen (`LevelScreenRedesign`) shipped its UI before the progression
domain was coherent. Exploration found **three competing systems** behind it:

**Three XP curves that disagree.**
- `app/core/leveling.py` — `lvl*100 + (lvl-1)*50`, self-described as the "single
  source of truth"; Quests already use it.
- `app/services/achievement_service.py` — a different exponential curve
  (`base_xp * multiplier^(level-1)`) driven by settings.
- `level_provider.dart` `_calculateNextLevelXP` — a third curve, `100*level*1.5`.

**Two parallel achievement subsystems with different schemas.**
- The `Achievement` model + `/levels/*` endpoints: 8 default achievements keyed by
  `achievement_id`, with `rarity`, per-achievement `xp_reward`, `is_unlocked`,
  `is_claimed`, and a `/claim` endpoint. This is what the Level screen reads.
  **But `Achievement.claim_rewards()` never credits XP** — it only flips
  `is_claimed`. So the XP rewards shown on screen were cosmetic.
- `achievement_service.py`: a separate 24-achievement catalog keyed by
  `achievement_key` (a field the model does not have), wired into the intake
  endpoint, which **does** grant XP by adding to `user.total_xp` on unlock.

  The two never reconcile.

**A third, client-side catalog.** `DefaultAchievements.getAll()` in Flutter defines
yet another 10 achievements computed locally.

**Three avatar id systems, with a dead reward link.** The canonical Avatar Catalog
(`avatar_catalog.dart`) uses ids like `giot_nuoc`/`hai_vuong` with unlock rails
level/coin/streak/mission. Achievements carry `unlock_avatar_id = "avatar_2".."avatar_8"`
— ids absent from the catalog, so `avatarSpecOrDefault()` silently resolves every
achievement avatar to the default drop. The Level screen's reward grid renders a
*fourth* set (emoji + `water_drop`/`wave`/`ocean`) hardcoded in the screen.

**UI presenting fabricated data.** The header showed `CoinBadge(amount: currentXP)`
("use XP as coins for now") despite Coin and XP being distinct in CONTEXT.md; each
achievement card showed `+${requiredValue ~/ 10} XP` (invented, dropping the real
`xp_reward`); the Themes section was four hardcoded fake themes; level names came
from a hardcoded `_getLevelName` ladder that disagreed with the backend's own
`/levels/rewards/preview` names.

The user's goal was an achievement/level system that sustains a **long-term** user —
which the above cannot do (the 8/24 catalogs cap out in ~2–3 months, and XP only
flowed from one-time unlocks in one of the two systems).

## Decision

1. **Two XP sources, one curve.** XP has **Repeatable** sources (daily-goal
   completion + Quests — these keep long-term users levelling) and **Milestone**
   sources (one-time Achievement claims). All feed one monotonic Total XP. The
   canonical curve is `app/core/leveling.py`; the exponential curve in
   `achievement_service.py` and the `*1.5` curve in `level_provider.dart` are
   removed. (Repeatable XP already exists in practice: `/levels/current` sums
   `IntakeLog.xp_earned + bonus_xp` plus quest XP on `user.total_xp`.)

2. **Claim-to-earn achievements.** Achievements reuse the Quest **Done → Claim**
   model: reaching the threshold makes one Done; XP is credited only when the user
   **Claims** it. `Achievement.claim_rewards()` is fixed to actually add `xp_reward`
   to the user's Total XP (it previously did not). The Claim button is wired in the
   Level screen (infra — `/claim`, `is_claimed`, `claimAchievement()` — already
   existed, just unused).

3. **One canonical catalog, derived-on-read.** The catalog is a single registry
   (`achievement_service.CATALOG`, mirrored for humans in `achievements_spec.md`):
   id, domain, tier, threshold, `xp_reward`. Following ADR 0002 (quests), progress
   is **derived on read** from source tables — never stored per row — and only
   Claims are persisted in `achievement_claims` (mirrors `quest_claims`, but
   lifetime: unique on `(user_id, achievement_id)`, no period). **Flutter renders
   only from `/levels/achievements`.** The old `achievement_service` catalog +
   XP-by-type map and Flutter's `DefaultAchievements` are deleted; the legacy
   per-user `Achievement` table is no longer read by the Level flow. `reward_xp`
   is derived per-tier (Common 50 / Rare 150 / Epic 400 / Legendary 1000).

4. **Eight domains, deep ladders, honest teasers.** Beyond the hydration core
   (streak, total volume, level, daily-goal, frequency), the catalog adds **Quest**,
   **Coach**, **Scan**, **Social** domains. Counting units are fixed and queryable:
   - Coach = one `ConversationSession` (not per message): 1 / 10 / 100 / 500.
   - Quest = lifetime `QuestClaim` rows (Claimed, not just Done): 10 / 100 / 1000.
   - Scan = `ScanHistory` rows: 1 / 50 / 500.
   - Social = current friend count: 1 / 5 / 20 / 50.
   Hydration ladders extend deep enough to outlast a one-year daily user (streak to
   365, volume to 1000 L, level to 50). Scan and Social depend on features not yet
   shipped (Phase 1/2); their achievements appear immediately as **Locked Teasers**
   (0 progress) rather than being hidden.

5. **Achievements give XP only — never avatars.** `unlock_avatar_id` is dropped from
   the achievement reward. Avatar ownership stays purely on the catalog's
   level/coin/streak/mission rails (`avatarOwnership()`), which the Collection screen
   already renders. A streak Achievement and a streak-gated Avatar may share a
   milestone, but the Avatar comes from the streak rail and the XP from the Claim —
   no double grant. The Level screen's reward section shows avatars unlocked by the
   user's current journey via the real `AquaAvatar` parametric widget, tapping
   through to the existing Collection screen; the emoji `_getAvatarColor` /
   `DefaultAvatars` path is deleted.

6. **No fabricated UI.** Header Coin comes from the real wallet
   (`userStatsProvider.coins`). The Themes section becomes an honest "Sắp ra mắt"
   placeholder (consistent with the Collection screen). Level names and per-level
   rewards come from `/levels/rewards/preview` (one place); `_getLevelName` and the
   arbitrary `+3/+8` ladder math are removed.

## Consequences

- One XP curve, one achievement catalog, one avatar id space — the three-way drift
  is gone, and the "single source of truth" claim in `leveling.py` becomes true.
- Achievements meaningfully reward XP for the first time (claim actually credits).
- The Level screen reflects real data end to end; nothing on it is fabricated.
- Long-term users always have locked achievements ahead, across eight behaviours.
- The catalog spans nine domains (the five hydration ones plus `quest`, `coach`,
  `scan`, `social`) as registry entries — no `AchievementType` enum change is
  needed, because progress is derived on read rather than stored per `Achievement`
  row. A new `achievement_claims` table is added (claims only).
- `achievement_service.py` is replaced wholesale: the XP-granting intake hook
  (`process_intake_log_achievements`), the parallel 24-item catalog, and the
  duplicate exponential XP math are gone. The dead `create_with_achievements`
  intake path and the legacy `Achievement` DB catalog are no longer used by the
  Level flow (the table remains only to avoid a destructive migration).
- Scan/Social achievements sit at 0 until those features ship — intended.

## When to revisit

- If avatars should ever be unlocked by achievements directly, that adds a fifth
  `UnlockType` and overlaps the streak/level rails — revisit decision 5 and the
  Avatar glossary together.
- If a repeatable (resetting) achievement is wanted, that blurs the
  Achievement/Quest line — prefer adding a Quest instead, or revisit decision 2.
- If Coach "conversation" needs a stricter definition (e.g. minimum messages per
  session to count), revisit the unit in decision 4 and CONTEXT.md.
