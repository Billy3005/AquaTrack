---
domain: AquaTrack Hydration App
last_updated: 2026-05-30
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

## Quests & Rewards

**Quest** (Nhiệm vụ) — A goal the user completes to earn rewards within a fixed time period. Canonical set of quests is defined in `quests_spec.md` (the spec, not the frontend sample data, is the source of truth).

**Daily Quest** — A Quest whose Reset Period is one local calendar day (resets 00:00 in the user's timezone).

**Weekly Quest** — A Quest whose Reset Period is one local calendar week (resets 00:00 Monday in the user's timezone).

**Reset Period** — The window during which a Quest's progress accumulates. When a new period begins, the Quest becomes available again. A Quest's progress is always measured against the activity within its current period.

**Done** — A Quest whose progress has reached its target. Distinct from Claimed.

**Claim** (Nhận) — The user action of collecting a Done Quest's reward. A reward is granted exactly once per Quest per Reset Period. Progress that later drops below target does not revoke a Claim already made for that period.

**Completion Bonus** — An extra reward unlocked when every base Quest in a period is Done. Becomes claimable on the Done condition (not on every base Quest being individually Claimed).

**Lucky Chest** (Rương may mắn) — The Weekly Completion Bonus. Grants a random Coin amount (50–150). Item rewards are a planned future addition.

**XP** — Experience points. Quest XP rewards feed the existing total_xp and level system; they are not a separate currency.

**Coin** — A spendable in-app currency, separate from XP, earned from Quests and spent in the Shop.

**Reminder** — A hydration nudge one user sends to a friend. Counts toward the "Hội Bạn Cùng Uống" Quest.

## UI Principles

**Trust AI with Transparency** — Show final goal and weather recommendation without exposing internal calculation breakdown. Focus on clear action ("Uống 2.850ml hôm nay") rather than mathematical explanation.

**Recommendation vs Requirement** — Visual distinction between mandatory goal and optional recommendations. Goal completion celebrations trigger at base goal achievement, with separate acknowledgment of recommendations.

**Graceful Intelligence** — AI insights fallback through cache → static → generic tips to ensure consistent user experience. No "AI" branding, using natural language like "dựa trên thói quen của bạn".