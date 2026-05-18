# CLAUDE.md — AquaTrack

## Project
```
App     : AquaTrack — hydration app that feels alive
Tagline : Chụp ảnh ly nước → AI đếm ml → Sống khoẻ hơn mỗi ngày
Stage   : Design done (Hi-Fi prototype) → bắt đầu build
Stack   : Flutter (Riverpod) · FastAPI (Python 3.11) · PostgreSQL · TFLite (custom model)
Solo    : 1 dev + researcher (sinh viên)
Repo    : monorepo → aquatrack_app/ · aquatrack_backend/ · aquatrack_ml/
```

## Design System (từ Hi-Fi Prototype)
```
Theme       : Dark navy (#0D1B2A background) · Cyan accent (#00B4D8) · Purple XP (#7B5EA7)
Typography  : Inter / SF Pro — Bold heading, Regular body
Drop widget : SVG water drop, fill level = hydration %, breathing animation
Nav         : Bottom tab 6 items — Drop · Coach · Body · Stats · Level · You
Screens     : 8 screens + 5 home states + 3 widget formats
Language    : Tiếng Việt (UI) + English (code/comment)
```

## Screens (theo prototype)
```
01 Home — Living Drop      : breathing drop, quick log, AQUA AI card, streak
02 AI Coach                : chat UI, context-aware nudges, quick replies
03 Ecosystem — Body Map    : SVG body, organs glow by hydration level
04 Stats — Wave Chart      : weekly wave chart, AI insights cards
05 Level & Achievements    : XP bar, avatar collection, milestone badges
06 Log Drink               : drink type chips, amount stepper, preview card
07 Smart Scan              : camera + TFLite, scanning overlay, result card
08 Profile                 : avatar, stats, themes, daily goal
```

## Agents
| Làm việc về | Agent |
|---|---|
| Flutter UI / animation / widget | `.claude/agents/flutter.md` |
| ML model / TFLite / Smart Scan | `.claude/agents/ml.md` |
| FastAPI / DB / AI Coach API | `.claude/agents/backend.md` |
| README / report / commit | `.claude/agents/docs.md` |

## Skills (Matt Pocock's Engineering Best Practices)
| Skill | File | Khi nào dùng |
|---|---|---|
| **TDD** | `.claude/skills/engineering/tdd.md` | Trước khi code feature mới · unit/widget testing |
| **Grill-Me** | `.claude/skills/productivity/grill-me.md` | Trước implementation lớn · design review |
| **Diagnose** | `.claude/skills/engineering/diagnose.md` | Debug issues phức tạp · performance problems |
| **Improve Architecture** | `.claude/skills/engineering/improve-architecture.md` | Code review · refactoring · tech debt cleanup |

### Workflow với Skills:
```
1. Planning → /grill-me trước khi start
2. Development → /tdd cho mỗi component
3. Debugging → /diagnose cho issues
4. Review → /improve-architecture sau features
```

## Rules — luôn áp dụng
```
NGÔN NGỮ  : Trả lời tiếng Việt
OUTPUT    : Code chạy được ngay · ít giải thích · không scaffold thừa
COMMENT   : Tiếng Anh trong code · tiếng Việt nếu cần giải thích dài
DESIGN    : Luôn dùng AppColors/AppTextStyles · không hardcode màu
KHI MƠ HỒ: Hỏi 1 câu ngắn trước · không tự đoán
```

## Conventions
```
Git branch : feature/<ten-tieng-anh>
Git commit : feat|fix|refactor|docs|chore: <mô tả ngắn>
Flutter    : Riverpod · feature-based folder · snake_case file · PascalCase class
Python     : black + isort · type hints · .env cho secrets
Test       : emulator + thiết bị thật
```

## Checklist — paste đầu mỗi chat
```
- Đang làm: [ Flutter | Python | ML ]
- Screen / feature: ___
- Block ở: ___
- Code liên quan: [paste nếu có]
```
