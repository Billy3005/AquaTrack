# CLAUDE.md — AquaTrack

## Project
```
App     : AquaTrack — hydration app that feels alive
Tagline : Chụp ảnh ly nước → AI đếm ml → Sống khoẻ hơn mỗi ngày
Stage   : Flutter UI Complete (8 screens) → Backend Expansion Phase
Stack   : Flutter (Riverpod) · FastAPI (Python 3.11) · SQLite · TFLite (planned)
Solo    : 1 dev + researcher (sinh viên)
Repo    : monorepo → aquatrack_app/ · aquatrack_backend/ · aquatrack_ml/
```

## Progress Status (Hiện tại)
```
✅ COMPLETE:
- Flutter UI: 8 screens với sophisticated design system
- Authentication: Register + Login + JWT tokens + Navigation
- Core Backend: FastAPI foundation + User management + Basic API
- Integration: Flutter ↔ Backend authentication flow working

🔄 IN PROGRESS:
- Backend Expansion: Following 8-phase implementation plan
- Current Phase: Phase 1 - Smart Scan ML Service setup

📋 PLANNED:
- Phase 1: Smart Scan ML Service (Vision API)
- Phase 2: Social Features (Friends + Leaderboards) 
- Phase 3: Advanced AI Coach (Context-aware responses)
- Phase 4: Production Readiness (Rate limiting + Email verification)
```

## Backend API Status
```
✅ Working Endpoints:
- POST /auth/register   → Create user + auto-login + JWT
- POST /auth/login      → Login + JWT tokens
- GET /auth/me         → Get current user info
- Basic CORS + middleware setup

🔄 Missing (Per Plan):
- POST /vision/estimate-volume     → Smart Scan ML
- GET/POST /friends/*              → Social features
- GET /friends/leaderboard/weekly  → Weekly rankings  
- Enhanced /coach/* endpoints      → Context-aware AI
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

## Screens Status
```
✅ COMPLETE UI + INTEGRATION:
01 Login/Register          : Full auth flow with backend integration
02 Home — Living Drop      : Breathing drop, quick log, streak (needs backend)
03 Log Drink               : Drink type chips, amount stepper, backend integration ✅
04 Profile                 : Avatar, stats, themes, daily goal

✅ COMPLETE UI (needs backend):
05 AI Coach                : Chat UI, context-aware nudges, quick replies  
06 Stats — Wave Chart      : Weekly wave chart, AI insights cards
07 Level & Achievements    : XP bar, avatar collection, milestone badges
08 Smart Scan              : Camera + TFLite, scanning overlay, result card

🔄 NEEDS BACKEND INTEGRATION:
- AI Coach → Requires /coach/* API endpoints (Phase 3)
- Smart Scan → Requires /vision/* API endpoints (Phase 1) 
- Stats → Requires advanced analytics APIs (Phase 3)
- Social features → Requires /friends/* APIs (Phase 2)
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

## Current Work — Backend Expansion Plan
```
📍 FOCUS: Phase 1 - Smart Scan ML Service (Week 1-2)
Priority: Critical - Flutter app expects /vision/estimate-volume endpoint

IMPLEMENTATION TARGET:
- POST /vision/estimate-volume → Accept image uploads
- ML integration: TensorFlow Lite / Claude Vision API  
- Return format: {containerClass, fillLevelPercent, liquidType, confidence, estimatedVolumeMl}
- Database: scan_history table for tracking

FILES TO CREATE:
- aquatrack_backend/app/api/v1/endpoints/vision.py
- aquatrack_backend/app/services/vision_service.py  
- aquatrack_backend/app/schemas/vision.py
- aquatrack_backend/app/models/scan_history.py
```

## Reference Links
```
📋 Full Plan: ~/.claude/plans/starry-doodling-cocke.md
🎯 Current Phase: Phase 1 - Smart Scan ML Service
🗂️ Memory: ~/.claude/projects/.../memory/MEMORY.md
```

## Checklist — paste đầu mỗi chat
```
- Đang làm: [ Backend Phase 1: Smart Scan | Flutter Integration | Testing ]
- Feature: Smart Scan ML Service (/vision/estimate-volume)
- Block ở: ___
- Code liên quan: [paste nếu có]
```
