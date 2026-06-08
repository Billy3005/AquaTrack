# 0004 — Shop: an avatar storefront, plus a one-time Streak Freeze

- Status: Accepted
- Date: 2026-06-09

## Context

The Shop screen (`shop_screen.dart`) shipped its UI before any of it was real.
Exploration found it is **entirely fabricated**:

- Balance is a hardcoded `_balance = 1240` — not `user.coins`.
- Purchases live in an in-memory `Map _purchased` — lost on screen exit; nothing
  hits the backend.
- It sells **themes, frames (khung), boosts, and stickers** — *none of which exist
  anywhere else in the app*. Themes/khung are already declared "Sắp ra mắt"
  placeholders in CONTEXT.md and the Collection screen; boosts/stickers have no
  mechanic at all.

Meanwhile the **one** thing that can genuinely be bought with Coins — an Avatar —
is **already sold elsewhere, end to end**: the backend `POST /avatars/{id}/purchase`
(`AvatarService.purchase`) deducts real coins and records `owned_avatars`, and the
**Collection screen** renders a detail sheet with a working "Mua · xu" button driven
by `profileNotifierProvider.purchaseAvatar()` and real `profile.coins`.

The product tension: every `CoinBadge` in the app routes to `/shop`
(`coin_badge.dart` → `context.push('/shop')`), so tapping your coins to "spend them"
lands on a fake shop that sells nothing real, while the actual coin sink (avatars)
is buried in Collection.

The user's goal was to **complete what already exists** rather than build a perfect
shop — sell only what's built, mark the rest "Sắp ra mắt" — with one explicit
exception: keep a **Streak Freeze** as a real, functional item.

One data inconsistency also surfaced: `AvatarService.purchase` does not enforce
`level_req`, so every coin-avatar is buyable at any level (an **OR** between the
level rail and the coin rail). Three dual-path avatars label this correctly
("Cấp 10 hoặc 280 xu"), but Thủy Đế's label read "Đỉnh cao · **cần** Cấp 40" — an
**AND** that contradicts both the backend and its three siblings (and is logically
impossible: reaching level 40 makes it `is_owned` for free, so an AND-gate could
never be paid).

## Decision

1. **Shop = the coin storefront for avatars; Collection = the trophy cabinet.**
   The Shop becomes the canonical place to **spend Coins**, wired to real
   `user.coins` and the existing `purchaseAvatar` flow (the hardcoded balance and
   in-memory purchase map are deleted). It lists exactly the coin-purchasable
   Avatars — those whose Unlock Condition includes a `coin` price (7 of 12: Dòng
   Chảy 280 · Thủy Ba 320 · Hải Lam 900 · Thủy Linh 1.100 · Lam Thần 1.400 · Hải
   Vương 2.500 · Thủy Đế 5.000). Avatars already owned via the level/streak rail
   show "Đã sở hữu". The Collection keeps showing *all* avatars and handles
   equipping; buying is the Shop's job.

2. **Sell only what exists; the rest is an honest placeholder — with the boost
   category deleted, not deferred.** Theme and Khung become "Sắp ra mắt" tabs
   (they are in the roadmap). The fake "Nổi bật tuần này / giới hạn" carousel is
   removed. Sticker and **boost** items are deleted outright — not marked "coming
   soon" — because a "+500 XP" pack would let a user **buy levels**, breaking the
   monotonic-from-real-sources Total XP guarantee of ADR 0003, and a coin
   multiplier / generic boost has no mechanic. Marking them "Sắp ra mắt" would
   promise something that contradicts our own model.

3. **Streak Freeze: a one-time consumable that bridges a single missed day.**
   The one boost we keep is reframed as a real item. A Freeze is bought with Coins
   (**300 xu**) and, when the user misses a full day, bridges that day so the
   Streak does not reset.
   - **Binary inventory.** A user owns at most one Freeze (`streak_freeze_owned`).
     Protecting a day consumes it (back to zero, must re-buy) — no stacking, so a
     coin-rich user cannot make their streak immortal.
   - **Bridges, does not extend.** A frozen day preserves continuity but adds **0**
     to streak length — the user did not hit goal that day.
   - **One day only.** Two consecutive missed days break the streak; one Freeze
     covers exactly one missed day.
   - **Consumed at log time, not on read.** Because the streak is derived on read
     (`StreakService.calculate_current_streak`), consuming the item inside the read
     path would mean merely opening Stats spends it. Instead, consumption is
     reconciled at a write point (intake log): the missed day is recorded in
     `frozen_dates` and `streak_freeze_owned` flips to false. While a Freeze is
     owned, a single missed day is treated as **provisionally protected** on read,
     so the streak never shows a false break before the next log reconciles it.

4. **Coin-avatars are an OR between rails; fix Thủy Đế's label.** Coin is an
   alternative path to the level rail, buyable at any level — matching the existing
   backend behaviour (no new gating code). Thủy Đế's catalog sub-label is corrected
   from "cần Cấp 40" to "hoặc đạt Cấp 40"; 5.000 xu is its natural gate.

## Consequences

- Tapping the coin badge now lands somewhere you can actually spend coins; the
  Shop and Collection stop competing over avatar sales (Shop sells, Collection
  collects/equips).
- Nothing on the Shop is fabricated: balance, ownership, and purchases all hit the
  real backend. The `_items`/`_balance`/`_purchased` fakes are gone.
- The Total XP integrity from ADR 0003 is preserved — the Shop sells no XP and no
  multipliers; Coins remain the only spendable currency.
- Streak Freeze touches the streak engine fixed in `f367567`. New columns
  `streak_freeze_owned` (Bool) and `frozen_dates` (JSON) are added to `User`, and
  `calculate_current_streak` gains gap-bridging logic. This is the largest piece of
  the change and the most behaviourally sensitive — covered by tests (bridge one
  gap; no length added; two-day gap still breaks; cannot buy when already owned;
  insufficient coins).
- Theme/Khung remain visible as roadmap signals without pretending to work.

## When to revisit

- If Themes or Frames ship, decision 2 reopens: they become real Shop categories
  and the "Sắp ra mắt" tabs gain content.
- If users want to stack Freezes or protect multi-day gaps, revisit decision 3 —
  but weigh it against streak meaningfulness (binary/one-day was chosen to keep the
  streak honest).
- If a background job is ever added, Freeze consumption could move from log-time
  reconciliation to a nightly pass; the `frozen_dates` storage already supports
  either trigger.
- If a coin-avatar should ever be hard-gated behind a level (true AND), decision 4
  reopens together with `AvatarService.purchase` and the Avatar glossary.
