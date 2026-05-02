# agents/backend.md — Backend Agent

> Load khi làm việc trong `aquatrack_backend/`

## Stack
```
Framework : FastAPI (Python 3.11)
ORM       : SQLAlchemy 2.x + Alembic
DB        : PostgreSQL 15 (Supabase)
Auth      : Firebase Admin SDK
AI Vision : EfficientNetV2 (server) / GPT-4o Vision (giai đoạn 1)
Weather   : OpenWeatherMap
Push      : FCM
Validation: Pydantic v2
Hosting   : Railway
```

## Endpoints
```
POST   /api/v1/estimate          → Smart Scan AI vision
POST   /api/v1/intake            → Log drink (quick/manual/scan)
DELETE /api/v1/intake/{id}
GET    /api/v1/summary/today     → Home screen + Living Drop data
GET    /api/v1/summary/weekly    → Stats Wave Chart data
GET    /api/v1/coach/message     → AI Coach context-aware trigger
PUT    /api/v1/profile           → Update + recalc goal + level
GET    /api/v1/health
```

## AI Coach Trigger — GET /api/v1/coach/message

```python
# Trả về nudge message dựa trên context hiện tại
# App gọi sau mỗi lần log hoặc mỗi 30 phút

@router.get("/coach/message", response_model=CoachMessage)
async def get_coach_message(uid: str = Depends(get_current_uid), db = Depends(get_db)):
    profile  = await UserService.get(db, uid)
    today    = await SummaryService.get_today(db, uid)
    weather  = await WeatherService.get(profile.city)
    last_log = await IntakeService.get_last(db, uid)

    return await CoachService.build_message(profile, today, weather, last_log)
```

```python
# Response schema
class CoachMessage(BaseModel):
    message: str
    quick_replies: list[str]
    urgency: str  # "info" | "nudge" | "urgent"
    trigger_type: str  # "caffeine" | "hot_weather" | "behind_pace" | "streak"
```

## Summary Today — GET /api/v1/summary/today

```python
# Trả về đủ data cho Home Screen
class TodaySummary(BaseModel):
    daily_goal_ml:    int
    total_effective:  int
    progress:         float    # 0.0 → 1.0
    remaining_ml:     int
    streak_days:      int
    home_state:       str      # 'dehydrated'|'low'|'normal_cool'|'normal_hot'|'near_goal'
    weather:          WeatherInfo
    logs:             list[IntakeLogItem]
    coach_nudge:      CoachMessage | None
    xp_today:         int
    level:            int
```

## Daily Goal Calculator
```python
def calculate_daily_goal(profile, temp_celsius: float) -> int:
    base = profile.weight_kg * 35
    a = {'sedentary':1.0,'light':1.1,'moderate':1.2,'active':1.35,'athlete':1.5}.get(profile.activity_level, 1.1)
    c = 1.0 if temp_celsius < 25 else 1.1 if temp_celsius < 30 else 1.2 if temp_celsius < 35 else 1.3
    h = sum({'pregnant':300,'breastfeeding':500,'kidney_stone':500,'kidney_disease':-300,'diabetes':200}.get(x,0) for x in (profile.health_conditions or []))
    s = sum({'gymmer':200,'runner':400,'outdoor_worker':300,'athlete':500}.get(t,0) for t in (profile.user_type or []))
    return round(((base * a * c) + h + s) / 50) * 50
```

## Folder Structure
```
aquatrack_backend/
├── main.py
├── .env
├── app/
│   ├── api/v1/
│   │   ├── estimate.py   coach.py   intake.py
│   │   ├── summary.py    profile.py
│   ├── core/config.py database.py firebase.py deps.py
│   ├── models/user.py intake_log.py daily_summary.py streak.py achievement.py
│   ├── schemas/          # Pydantic models
│   └── services/
│       ├── vision_service.py  goal_service.py
│       ├── coach_service.py   weather_service.py
│       ├── xp_service.py      fcm_service.py
└── alembic/
```

## Rules
```
1. Secret đọc từ .env
2. Response dùng Pydantic schema
3. Không lưu ảnh — base64 in, result out, done
4. Mọi endpoint trừ /health qua get_current_uid
5. XP calculation trong xp_service.py — không inline
```

## Prompt Template
```
[BACKEND AGENT] [style:terse]
Endpoint: <method /path>
Task: <mô tả ngắn>

<paste code / error>
```
