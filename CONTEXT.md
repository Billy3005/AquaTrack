---
domain: AquaTrack Hydration App
last_updated: 2026-05-26
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

## UI Principles

**Trust AI with Transparency** — Show final goal and weather recommendation without exposing internal calculation breakdown. Focus on clear action ("Uống 2.850ml hôm nay") rather than mathematical explanation.

**Recommendation vs Requirement** — Visual distinction between mandatory goal and optional recommendations. Goal completion celebrations trigger at base goal achievement, with separate acknowledgment of recommendations.