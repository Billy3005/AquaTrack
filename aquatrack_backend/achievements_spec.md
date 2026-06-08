# Achievements Specification

## Overview

Achievements are **lifetime milestones** — they never reset. Progress is
**derived on read** from source tables; only **Claims** are persisted
(`achievement_claims`). XP is credited **only on Claim**, never on unlock
(Done → Claim). See `docs/adr/0003-levels-and-achievements.md`.

This document is the human-readable mirror of the canonical registry in
`app/services/achievement_service.py` (`CATALOG`). The registry is the source of
truth; keep this file in sync when the catalog changes.

### Milestone XP by Tier

| Tier      | XP    |
| --------- | ----- |
| Common    | 50    |
| Rare      | 150   |
| Epic      | 400   |
| Legendary | 1000  |

### Domains & counting sources

| Domain       | Source (lifetime, per user)                          |
| ------------ | ---------------------------------------------------- |
| `streak`     | `users.longest_streak`                               |
| `volume`     | `SUM(intake_logs.effective_volume_ml)`               |
| `level`      | level derived from Total XP (`app/core/leveling.py`) |
| `frequency`  | `COUNT(intake_logs)`                                  |
| `daily_goal` | `COUNT(daily_summaries WHERE goal_achieved)`         |
| `quest`      | `COUNT(quest_claims)` — Quests **Claimed**           |
| `coach`      | `COUNT(conversation_sessions)` — sessions, not msgs  |
| `scan`       | `COUNT(scan_history)`                                 |
| `social`     | `COUNT(friends WHERE is_active AND NOT is_blocked)`  |

> Achievements **do not** unlock avatars. Avatar ownership stays on the
> level/coin/streak/mission rails (see `avatar_service.py` / CONTEXT.md).
> `scan` and `social` depend on features not yet shipped; their achievements
> appear as **Locked Teasers** (0 progress) until those sources go live.

---

## Catalog

### Streak — `users.longest_streak`

| ID            | Name              | Tier      | Target |
| ------------- | ----------------- | --------- | ------ |
| `streak_3`    | Khởi đầu          | Common    | 3      |
| `streak_7`    | Chiến binh tuần   | Rare      | 7      |
| `streak_14`   | Nửa tháng bền bỉ  | Rare      | 14     |
| `streak_30`   | Bậc thầy tháng    | Epic      | 30     |
| `streak_60`   | Hai tháng kiên định | Epic    | 60     |
| `streak_100`  | Centurion         | Legendary | 100    |
| `streak_365`  | Trọn một năm      | Legendary | 365    |

### Volume — total effective ml

| ID            | Name                      | Tier      | Target (ml) |
| ------------- | ------------------------- | --------- | ----------- |
| `volume_1l`   | Lít đầu tiên              | Common    | 1 000       |
| `volume_10l`  | Thùng nước                | Common    | 10 000      |
| `volume_50l`  | Bể nhỏ                    | Rare      | 50 000      |
| `volume_100l` | Biển nước                 | Rare      | 100 000     |
| `volume_500l` | Đại dương                 | Epic      | 500 000     |
| `volume_1000l`| Hydrator Thiên niên kỷ    | Legendary | 1 000 000   |

### Level — derived from Total XP

| ID         | Name      | Tier      | Target |
| ---------- | --------- | --------- | ------ |
| `level_5`  | Tân binh  | Common    | 5      |
| `level_10` | Lão luyện | Rare      | 10     |
| `level_20` | Chuyên gia| Epic      | 20     |
| `level_30` | Siêu phàm | Epic      | 30     |
| `level_50` | Đỉnh cao  | Legendary | 50     |

### Frequency — lifetime log count

| ID          | Name                | Tier      | Target |
| ----------- | ------------------- | --------- | ------ |
| `log_first` | Bước đầu            | Common    | 1      |
| `log_100`   | Người uống chăm chỉ | Rare      | 100    |
| `log_500`   | Thói quen vàng      | Epic      | 500    |
| `log_1000`  | Nghìn nhịp nước     | Legendary | 1000   |

### Daily Goal — lifetime goal-achieved days

| ID           | Name                 | Tier      | Target |
| ------------ | -------------------- | --------- | ------ |
| `goal_first` | Hoàn thành đầu tiên  | Common    | 1      |
| `goal_10`    | Mười ngày vàng       | Common    | 10     |
| `goal_50`    | Năm mươi cột mốc     | Rare      | 50     |
| `goal_100`   | Trăm ngày hoàn hảo   | Epic      | 100    |
| `goal_365`   | Cả năm trọn vẹn      | Legendary | 365    |

### Quest — Quests Claimed (`quest_claims`)

| ID           | Name        | Tier      | Target |
| ------------ | ----------- | --------- | ------ |
| `quest_10`   | Tân Binh    | Common    | 10     |
| `quest_100`  | Chiến Binh  | Rare      | 100    |
| `quest_1000` | Huyền Thoại | Legendary | 1000   |

### Coach — AI Coach sessions (`conversation_sessions`)

| ID            | Name                       | Tier   | Target |
| ------------- | -------------------------- | ------ | ------ |
| `coach_first` | Cuộc Trò Chuyện Đầu Tiên   | Common | 1      |
| `coach_10`    | Học Viên                   | Common | 10     |
| `coach_100`   | Bạn Đồng Hành              | Rare   | 100    |
| `coach_500`   | Tri Kỷ                     | Epic   | 500    |

### Scan — Smart Scans (`scan_history`) · *Locked Teaser until Phase 1*

| ID           | Name           | Tier   | Target |
| ------------ | -------------- | ------ | ------ |
| `scan_first` | Scan lần đầu   | Common | 1      |
| `scan_50`    | Nhà Phân Tích  | Rare   | 50     |
| `scan_500`   | Chuyên Gia     | Epic   | 500    |

### Social — friend count (`friends`) · *Locked Teaser until Phase 2*

| ID             | Name                | Tier      | Target |
| -------------- | ------------------- | --------- | ------ |
| `social_first` | Mời bạn đầu tiên    | Common    | 1      |
| `social_5`     | Người Kết Nối       | Rare      | 5      |
| `social_20`    | Thủ Lĩnh            | Epic      | 20     |
| `social_50`    | Aqua Community Hero | Legendary | 50     |
