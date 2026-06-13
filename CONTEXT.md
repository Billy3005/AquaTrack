---
domain: AquaTrack Hydration App
last_updated: 2026-06-13
---

# AquaTrack Domain Glossary

## Core Concepts

**Daily Goal** — The computed water intake target in ml/day, calculated exclusively from Water Formula using user's body/lifestyle/health/diet data. User cannot edit manually. Stored as `calculated_daily_goal_ml` in backend User model.

**Water Formula** — Scientific calculation system with 5 steps (B1: Body, B2: Lifestyle, B3: Health, B4: Diet, B5: Review) that determines base daily water requirement. Based on IOM standards. Only recalculates when user profile data changes.

**Temperature Recommendation** — Additional water suggestion (in ml) based on daily weather forecast. Displayed separately from Daily Goal, not included in goal completion calculation. Example: "+300ml vì thời tiết nóng".

**Profile Data** — User information used in Water Formula: gender, age, height, weight, activity level, job type, health conditions, diet habits. Stored in backend, synced to frontend. Changes trigger goal recalculation.

**Goal Completion** — Achievement when user reaches their Daily Goal (base calculation only). Temperature recommendations do not affect completion status, but user receives notification about additional recommendations when goal is achieved.

## Data Flow

**Backend-First Sync** — Profile screen data sourced from backend User model, not local Hive storage. Background sync on app start with Hive fallback for offline experience.

**Optimistic Updates** — User profile changes update UI immediately, sync to backend in background, with rollback on API failure.

**Computed vs Editable** — Daily Goal is computed field (read-only), while preferences (theme, notifications, avatar) remain user-editable.

## AI Insights & Intelligence

**Weather State** — Normalized weather data condition with confidence levels: fresh (recent API data), stale (cached within tolerance), fallbackCity (manual location), unavailable (offline fallback).

**Insight Context** — Processed data structure combining StatsPattern, WeatherState, TimeContext, and UserProfile for AI insight generation. Normalized by Context Builder to abstract away API complexities.

**AI Insights Layer** — Recommendation system that generates personalized hydration suggestions based on user patterns and environmental factors. Operates separately from Daily Goal calculation, providing supplementary advice without affecting goal completion status.

> **Wiring status (2026-06-05):** The Stats screen sources its insights from the **backend** `/stats/insights` endpoint (rule-based, computed from real logs). The Flutter-side intelligence layer below (Insight Context, Weather State, Context Builder) is **not currently wired into Stats** — it remains in the codebase as a parked/planned capability for weather-aware insights, but does not feed the Stats screen. Do not treat its glossary terms as describing live Stats behaviour.

## Quests & Rewards

**Quest** (Nhiệm vụ) — A goal the user completes to earn rewards within a fixed time period. Canonical set of quests is defined in `quests_spec.md` (the spec, not the frontend sample data, is the source of truth).

**Daily Quest** — A Quest whose Reset Period is one local calendar day (resets 00:00 in the user's timezone).

**Weekly Quest** — A Quest whose Reset Period is one local calendar week (resets 00:00 Monday in the user's timezone).

**Reset Period** — The window during which a Quest's progress accumulates. When a new period begins, the Quest becomes available again. A Quest's progress is always measured against the activity within its current period.

**Done** — A Quest whose progress has reached its target. Distinct from Claimed.

**Claim** (Nhận) — The user action of collecting a Done Quest's reward. A reward is granted exactly once per Quest per Reset Period. Progress that later drops below target does not revoke a Claim already made for that period.

**Completion Bonus** — An extra reward unlocked when every base Quest in a period is Done. Becomes claimable on the Done condition (not on every base Quest being individually Claimed).

**Lucky Chest** (Rương may mắn) — The Weekly Completion Bonus. Grants a random Coin amount (50–150). Item rewards are a planned future addition.

**XP** — Experience points. Earned from two kinds of source: **Repeatable XP** (renewable, keeps long-term users levelling — daily-goal completion and Quests) and **Milestone XP** (one-time, granted by an Achievement unlock). All XP feeds the single Total XP pool; XP is not a spendable currency.

**Total XP** — The cumulative, monotonic (never-decreasing) sum of all XP a user has earned. The user's Level is derived from Total XP through one canonical XP curve; the curve lives in exactly one place so Quests, Achievements, and the Level screen can never disagree.

**Coin** — A spendable in-app currency, separate from XP, earned from Quests and spent in the Shop.

**Reminder (Friend Nudge)** — A hydration nudge one user sends to a *friend*. Counts toward the "Hội Bạn Cùng Uống" Quest. Distinct from a **Reminder Slot** (a user's self-reminder — see Hydration Reminders).

## Social & Referral

**Friend Request** (Kết bạn) — Connecting two people who *both already use AquaTrack*: one searches the other by username, sends a request, the other accepts. Produces a Friend relationship. Distinct from a **Referral**, which brings a person who is *not yet a user* onto the app.

**Referral** (Mời bạn) — Bringing a brand-new person to install and register AquaTrack via the inviter's **Referral Code**. A Referral is one-directional (Referrer → Referred) and exists only for a person whose account is created with a Referral Code attached at sign-up. It does **not** create a Friend relationship by itself.

**Referral Code** — A permanent, stable code unique to each user (one code per user, reusable indefinitely). The inviter shares it; a new user attaches it at registration. A code can never be self-applied, and is captured only at sign-up — never added to an existing account afterwards.

**Validated Referral** — A Referral that has reached its **Validation Moment**: the Referred user's **first water log**. Until then a Referral is *pending* and counts for nothing. Only Validated Referrals grant rewards or count toward the Ambassador Quest. Validation is one-time and irreversible.

**Two-Sided Reward** — On validation, *both* parties are rewarded once: the Referrer gets credit toward the Ambassador Quest, and the Referred user gets a one-time welcome Coin bonus. The welcome bonus is granted exactly once per Referred user.

**Ambassador Quest** (Đại Sứ Hydration) — The fourth **Weekly Quest**: become Done by achieving one Validated Referral within the current week (the week is measured by the Referral's Validation Moment, not when the code was shared). Completing it (alongside the other weekly quests) is what raises the Weekly Completion Bonus condition from 3/3 to 4/4 — it is the quest that was Deferred in `quests_spec.md` until referral infrastructure existed.

## Levels & Achievements

**Level** — A progression tier derived purely from Total XP via the canonical XP curve. Never stored as an editable value; recomputed from Total XP. A Level may carry a display name (the canonical tier names live in one place, not duplicated per screen).

**Achievement** (Thành tựu) — A one-time milestone the user unlocks by reaching a threshold (a streak length, total volume, level, log count, …). Unlike a Quest, it does not reset. The canonical Achievement catalog lives in exactly one place (one definition shared by backend and the Level screen — never two competing sets). Each Achievement carries a Tier (rarity) and a Milestone XP reward — **and nothing else**. Achievements do **not** unlock Avatars; Avatar ownership stays purely on the level/coin/streak/mission rails defined under Avatars & Collection. (A streak Achievement and a streak-gated Avatar may share the same milestone, but the Avatar comes from the streak rail, the XP from the Claim — never a double grant.)

**Done / Claim (Achievement)** — An Achievement reuses the Quest **Done** and **Claim** semantics: reaching the threshold makes it **Done**; the user must **Claim** it to actually receive its Milestone XP (and any Avatar unlock). XP is credited only on Claim, never silently on unlock.

**Tier (Achievement rarity)** — An Achievement's rarity band: Common / Rare / Epic / Legendary. Sets the badge palette and signals how hard it was. (Distinct from **Tier (Bậc hiếm)** for Avatars, though both use the same four bands.)

**Achievement Domain** — The behaviour an Achievement ladder measures. Beyond the hydration core (streak, total volume, level, daily-goal, log frequency), the catalog spans: **Quest** (lifetime Quests Claimed), **Coach** (lifetime AI Coach conversations), **Scan** (lifetime Smart Scans), and **Social** (current friend count). Each Domain has its own laddered thresholds and counting source (below).

**Conversation (Coach Achievement unit)** — One AI Coach **session** (a `ConversationSession`), not one message. The Coach ladder (Cuộc Trò Chuyện Đầu Tiên → Tri Kỷ at 500) counts sessions. A session is created when the user genuinely starts a conversation, not on merely opening the Coach tab.

**Quests Claimed (Quest Achievement unit)** — The lifetime count of Quest rewards **Claimed** (`QuestClaim` rows), not Quests merely Done-but-unclaimed. Drives the Tân Binh (10) / Chiến Binh (100) / Huyền Thoại (1000) ladder.

**Locked Teaser** — An Achievement whose Domain depends on a feature not yet shipped (Smart Scan, Social) is still shown in the catalog as a locked badge at 0 progress, so users can see the roadmap. It becomes earnable once its counting source goes live; it is never hidden just because the feature is pending.

## Avatars & Collection

**Avatar** (Hình hài) — A water-spirit form the user displays as their identity. The canonical set is 12 forms (Giọt Nước → Thủy Đế) defined in the Avatar Catalog (`avatar_catalog`, mirrored on backend and Flutter — the catalog is the source of truth, not sample data). Each form is rendered parametrically from a spec (body gradient, face, features, aura), not a static image.

**Tier** (Bậc hiếm) — An Avatar's rarity band: Common (Thường), Rare (Hiếm), Epic (Sử thi), Legendary (Huyền thoại). Tier sets the ring/glow palette and groups Avatars in the Collection.

**Owned** (Đã mở) — The user is entitled to equip this Avatar. Ownership is permanent and comes from one of: meeting a level/streak threshold (derived, never stored — recomputed from current_level/longest_streak), or a Coin purchase (stored in `owned_avatars`). Distinct from Equipped.

**Equipped** (Đang dùng) — The single Owned Avatar currently shown as the user's identity. Stored as `avatar_id`. A user may equip any Owned Avatar for free; equipping an un-owned Avatar is rejected.

**Locked** — An Avatar the user does not yet own. The Collection shows it as a silhouette with its Unlock Condition.

**Unlock Condition** — How a Locked Avatar becomes Owned. Types: `level` (auto on reaching a level), `coin` (buy with Coins), `streak` (auto on reaching a longest-streak), `mission` (complete a Quest chain — planned, shown as "Sắp ra mắt"). Some Avatars offer two paths (e.g. "Cấp 10 hoặc 280 xu") — meeting either grants ownership.

**Collection** (Bộ sưu tập) — The screen listing all Avatars grouped by Tier, with owned/total progress and a detail sheet for equipping. Shows every Avatar regardless of unlock path (level/streak/mission/coin). Buying a coin-Avatar is the **Shop**'s job, not the Collection's — the Collection is the trophy cabinet (browse + equip). Theme and Khung (frame) tabs are placeholders ("Sắp ra mắt").

**Shop** (Cửa hàng) — The coin storefront: the canonical place to **spend Coins**. The coin badge everywhere in the app routes here. Today the Shop sells the coin-purchasable Avatars (those whose Unlock Condition includes a `coin` price) plus the **Streak Freeze** consumable; Theme and Khung are shown as "Sắp ra mắt". The Shop never sells XP or coin multipliers — XP stays monotonic from real sources and Coins are the only spendable currency. Distinct from the **Collection**, which displays *all* Avatars and handles equipping.

**Streak Freeze** (Đóng băng chuỗi) — A one-time consumable bought with Coins that bridges a single fully-missed day so the user's Streak does not reset. Inventory is binary — a user owns at most one Freeze at a time. **Duolingo semantics ("dùng là mất")**: the Freeze burns at the midnight of the first fully-passed missed day it protects — whether or not the streak ultimately survives — and the Shop resets to repurchasable. A bridged day preserves continuity but does **not** add to streak length (the user did not hit goal that day). The burn is decided at the missed midnight and *recorded* lazily on the next read (`reconcile_freeze`); a Freeze never covers days missed before its purchase date (`freeze_purchased_on`), so buying one cannot resurrect a dead run. Multiple consecutive missed days break the streak — one Freeze covers one day only (burned on the first miss).

## Smart Scan

**Smart Scan** — Tính năng chụp ảnh vật chứa đồ uống để ước lượng lượng nước, thay cho nhập tay. Kết quả scan luôn đi qua bước người dùng xác nhận trước khi trở thành một log; Smart Scan không bao giờ tự log.

**Container Capacity** — Dung tích ước lượng của vật chứa, là một giá trị liên tục tính bằng ml (ví dụ 650ml), không phải một lớp phân loại rời rạc. Loại vật chứa (chai/ly/cốc) chỉ dùng để hiển thị, không tham gia tính thể tích.

**Fill Level** — Tỷ lệ đầy của vật chứa (0.0–1.0) tại thời điểm chụp.

**Estimated Volume** — Thể tích vật lý của chất lỏng trong vật chứa: Container Capacity × Fill Level. Đây là con số người dùng xác nhận hoặc chỉnh sửa, vì nó là thứ họ nhìn thấy được.

**Effective Volume** — Lượng hydration thực tính: Estimated Volume × Hydration Coefficient của loại đồ uống. Luôn được suy ra ở **một nơi duy nhất** (bước log), không bao giờ tính trước rồi truyền đi — tránh áp hệ số hai lần.

**Hydration Coefficient** — Hệ số quy đổi theo loại đồ uống (nước 1.0, trà 0.9, cà phê 0.8, …) phản ánh mức đóng góp hydration thực.

**Scan Confidence** — Độ tin cậy của một lần scan (0.0–1.0). Từ **0.85** trở lên kết quả được tự động điền và xác nhận là hành động chính; dưới ngưỡng này kết quả vẫn hiện như một gợi ý kèm cảnh báo, việc chỉnh sửa được làm nổi bật. Confidence thấp không bao giờ ép người dùng chụp lại — chụp lại chỉ là lựa chọn phụ.

**Correction** — Hành động người dùng sửa Estimated Volume mà scan đề xuất trước khi log. **Correction Rate** (tỷ lệ scan bị sửa, mục tiêu <25%) và **sai số thể tích trung bình** (mục tiêu <15%) là hai KPI chất lượng của Smart Scan. Mỗi Correction đồng thời là một điểm dữ liệu huấn luyện cho giai đoạn hybrid sau này.

## Hydration Reminders

**Hydration Schedule** (Lịch nhắc nhở) — A user's personal set of daily local notifications nudging *themselves* to drink water. Distinct from a **Reminder (Friend Nudge)**. Stored on-device only (Hive); notifications fire locally via `flutter_local_notifications`, with no backend involvement.

**Reminder Slot** (Mốc nhắc) — One entry in the Hydration Schedule: a daily clock time + on/off state + Tone. Repeats every day. The display label is derived from time-of-day (sáng/trưa/chiều/tối), not user-entered.

**Tone** (Giọng nhắc) — The voice/style of a Reminder Slot's notification copy (e.g. Năng động, Thân thiện, Nhẹ nhàng, Bình yên). Selects which message template fires; does not affect timing.

**Schedule Suggestion** (Gợi ý lịch) — A generated Hydration Schedule spread evenly (~every 2h) across the user's waking window (wake time → sleep time). Exists to reduce setup friction; the user can then edit, add, or remove Slots manually. Regenerating replaces the current Slots.

## Authentication

**Social Sign-In** (Đăng nhập liên kết) — Signing in via an external identity provider. AquaTrack supports exactly one: **Google**. Apple and Facebook are deliberately absent (not "coming soon" — see honest UI in ADR 0004): Apple Sign-In only becomes relevant (and then *mandatory*, per App Store rules) if an iOS release ships; Facebook is dropped. The backend remains the only identity authority — a social sign-in ends in the same AquaTrack session tokens as a password login.

**Account Linking** (Liên kết tài khoản) — When a Google sign-in carries a verified email that matches an existing password account, the sign-in **auto-links** into that account (one person, one account, two doors). Linking into an account whose email was never verified disables its password (it must be reset to be used again) — this closes the pre-registration takeover hole. Google identity is keyed by Google's permanent subject ID, never by email.

**Passwordless Account** (Tài khoản không mật khẩu) — An account created via Google sign-in has no password. A password login attempt against it is answered honestly ("this account signs in with Google") rather than with a generic wrong-password error.

**Password Reset** (Đặt lại mật khẩu) — Recovery via a short-lived 6-digit code emailed to the account address; entering the code lets the user set a new password. The same flow re-arms a password disabled by Account Linking, and lets a Passwordless Account add a password later. Email verification at registration is deliberately **not** enforced yet (sign-up friction beats spam risk at this stage — revisit with Production Readiness).

## Statistics & History

**Stats Period** — The time window the History/Stats screen aggregates over: `week` (last 7 days) or `month` (last 30 days). Selected via the period toggle; the selection drives both the wave chart density and the metric labels. Week renders 7 day-points with weekday labels (T2–CN); Month renders 30 day-points with day labels hidden.

**Day Progress** — One day's hydration outcome used to plot the wave chart: effective ml vs that day's Daily Goal, with a goal-achieved flag. Sourced from the backend `/stats/goals/progress` endpoint, which carries the **real** per-day Daily Goal (not a hardcoded constant). This is the canonical chart source — the `/stats/trends/daily` endpoint is *not* used for the chart because it lacks per-day goal context.

**Liquid Breakdown** — The share of each drink type (Nước lọc, Trà, Cà phê, …) over the Stats Period, by volume / effective volume / frequency. Sourced from `/stats/liquid-types`. Distinct from a single "top liquid" value; the screen shows the full breakdown.

## UI Principles

**Trust AI with Transparency** — Show final goal and weather recommendation without exposing internal calculation breakdown. Focus on clear action ("Uống 2.850ml hôm nay") rather than mathematical explanation.

**Recommendation vs Requirement** — Visual distinction between mandatory goal and optional recommendations. Goal completion celebrations trigger at base goal achievement, with separate acknowledgment of recommendations.

**Graceful Intelligence** — AI insights fallback through cache → static → generic tips to ensure consistent user experience. No "AI" branding, using natural language like "dựa trên thói quen của bạn".