# Quests Specification

## Overview

- **Daily quests**: Reset at `00:00` every day (user's local timezone)
- **Weekly quests**: Reset at `00:00` every Monday (user's local timezone)

Reset is implicit — a new `period_key` has no claim, so quests become available
automatically. No cron job is needed. See `docs/adr/0002-derived-on-read-quests.md`.

---

## Daily Quests

> Complete all 4 to receive the completion bonus.

### 1. Bứt Phá Hydration

| Field       | Value                                   |
| ----------- | --------------------------------------- |
| Quest ID    | `breakthrough_hydration`                |
| Description | Uống đủ 80% lượng nước mục tiêu hôm nay |
| Target      | 80% of `calculated_daily_goal_ml` (dynamic) |
| Source      | `daily_summaries.total_effective_ml`    |
| Reward      | 25 XP + 10 coin                         |
| Reset       | 00:00 daily                             |

---

### 2. Quét Thông Minh

| Field       | Value                                            |
| ----------- | ------------------------------------------------ |
| Quest ID    | `smart_scan`                                     |
| Description | Dùng AI Smart Scan để nhận diện lượng nước 4 lần |
| Target      | 4 scans                                          |
| Source      | `scan_history.created_at` (count per day)        |
| Reward      | 30 XP + 15 coin                                  |
| Reset       | 00:00 daily                                      |

---

### 3. Hội Bạn Cùng Uống

| Field       | Value                               |
| ----------- | ----------------------------------- |
| Quest ID    | `friend_reminder`                   |
| Description | Nhắc nhở cho bạn bè uống nước 2 lần |
| Target      | 2 reminders                         |
| Source      | `reminder_logs.created_at` (count per day) |
| Reward      | 10 XP + 5 coin                      |
| Reset       | 00:00 daily                         |

Note: A `ReminderLog` row is written each time `/friends/{id}/remind/` succeeds.

---

### 4. AI Đồng Hành

| Field       | Value                                      |
| ----------- | ------------------------------------------ |
| Quest ID    | `ai_companion`                             |
| Description | Chat với AI Coach ít nhất 1 lần trong ngày |
| Target      | 1 user message                             |
| Source      | `conversations.message_type = 'user'` (count per day) |
| Reward      | 15 XP + 5 coin                             |
| Reset       | 00:00 daily                                |

---

### 🎯 Daily Completion Bonus (4/4)

| Field     | Value                                            |
| --------- | ------------------------------------------------ |
| Quest ID  | `daily_bonus`                                    |
| Condition | All 4 base daily quests Done (not necessarily Claimed) |
| Reward    | 20 XP + 15 coin                                  |

---

## Weekly Quests

> Reset at `00:00` every Monday.

### 1. Tuần Lễ Kiên Trì

| Field       | Value                   |
| ----------- | ----------------------- |
| Quest ID    | `persistence_week`      |
| Description | Streak 7 ngày liên tiếp |
| Target      | 7 days                  |
| Source      | `users.current_streak` (server-validated, never self-reported) |
| Reward      | 100 XP + 40 coin        |
| Reset       | 00:00 Monday            |
| Difficulty  | ⭐⭐⭐⭐ Cao nhất       |

---

### 2. Chiến Binh Hydration

| Field       | Value                                         |
| ----------- | --------------------------------------------- |
| Quest ID    | `hydration_warrior`                           |
| Description | Đạt mục tiêu uống nước hàng ngày trong 5 ngày |
| Target      | 5 days                                        |
| Source      | `daily_summaries.goal_achieved = true` (count within week) |
| Reward      | 75 XP + 30 coin                               |
| Reset       | 00:00 Monday                                  |
| Difficulty  | ⭐⭐⭐ Cao                                    |

---

### 3. Nhà Khoa Học Nước

| Field       | Value                                                     |
| ----------- | --------------------------------------------------------- |
| Quest ID    | `water_scientist`                                         |
| Description | Thử 3 loại đồ uống khác nhau được AI nhận diện trong tuần |
| Target      | 3 distinct `liquid_type` values                           |
| Source      | `scan_history.liquid_type` (COUNT DISTINCT within week)   |
| Reward      | 50 XP + 25 coin                                           |
| Reset       | 00:00 Monday                                              |
| Difficulty  | ⭐⭐ Trung bình                                           |

---

### 4. Đại Sứ Hydration

| Field       | Value                                                        |
| ----------- | ------------------------------------------------------------ |
| Quest ID    | `hydration_ambassador`                                       |
| Description | Mời 1 người bạn mới dùng AquaTrack (đã uống nước lần đầu)    |
| Target      | 1 Validated Referral                                         |
| Source      | `referrals.validated_at` (count within week)                |
| Reward      | 75 XP + 40 coin                                              |
| Reset       | 00:00 Monday                                                 |
| Difficulty  | ⭐⭐⭐⭐ Cao nhất                                            |

A Referral is **validated** at the invited user's first water log (first
`intake_logs` row), not at sign-up. The week is measured by `validated_at`, so a
referral counts in the week it validates. See `docs/adr/0007-referral-and-ambassador-quest.md`.

---

### 🎯 Weekly Completion Bonus — Rương May Mắn (4/4)

| Field     | Value                                            |
| --------- | ------------------------------------------------ |
| Quest ID  | `weekly_bonus`                                   |
| Condition | All 4 base weekly quests Done                    |
| Reward    | **Random coin 50–150** (Lucky Chest)             |

The chest always grants coin only. Item rewards are planned for a future release.

---

## Implementation Notes

- Progress is **derived on read** from source tables each request. No counters.
- The only persisted quest state is a `quest_claims` row: `(user_id, quest_id, period_key)`.
  The unique constraint prevents double-claiming; a new `period_key` makes resets implicit.
- `period_key` is computed in the user's local timezone (`users.timezone`):
  daily → `"2026-05-30"`, weekly → `"2026-W22"`.
- **XP** is added to `users.total_xp`; `users.current_level` is recalculated on each claim.
- **Coin** is added to `users.coins` (separate spendable currency from XP).
- `reminder_logs` exists only to make the friend-reminder quest countable; it has no other purpose.
- `weekly_bonus` chest: `random.randint(50, 150)` coins at claim time (snapshot saved to `quest_claims.reward_coin`).
- **Referrals**: each user has a permanent `referral_code`. A `referrals` row
  `(referrer_id, referred_id, created_at, validated_at)` is created at the invited
  user's sign-up (code captured at registration only). `validated_at` is stamped on
  the referred user's first `intake_logs` row; at that moment the referred user is
  granted a one-time **+50 coin** welcome bonus. `hydration_ambassador` progress is
  derived on read: count `referrals` rows for the user with `validated_at` inside the
  weekly window. See `docs/adr/0007-referral-and-ambassador-quest.md`.
