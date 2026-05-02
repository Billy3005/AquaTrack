# 💧 AquaTrack — agent.md (Product Spec)

> **Tagline:** The hydration app that feels alive.
> **Platform:** iOS + Android (Flutter)
> **Backend:** FastAPI (Python 3.11) + PostgreSQL
> **AI Vision:** Custom TFLite (on-device) + EfficientNetV2 (server)
> **Monetization:** Hoàn toàn miễn phí
> **Design:** Hi-Fi Prototype — Dark navy theme, Living Drop metaphor

---

## 1. Design System

### Color Palette
```dart
// lib/core/constants/app_colors.dart
class AppColors {
  // Background
  static const background     = Color(0xFF0D1B2A);  // dark navy
  static const surface        = Color(0xFF112236);  // card background
  static const surfaceLight   = Color(0xFF1A3050);  // elevated card

  // Accent
  static const cyan           = Color(0xFF00B4D8);  // primary CTA, drop fill
  static const cyanLight      = Color(0xFF90E0EF);  // drop highlight
  static const cyanDark       = Color(0xFF0077B6);  // drop shadow

  // Gamification
  static const xpPurple       = Color(0xFF7B5EA7);  // XP bar, level badge
  static const xpPurpleLight  = Color(0xFFB8A0D4);

  // Streak
  static const streakOrange   = Color(0xFFFF6B35);  // streak badge

  // Status / organs
  static const organBrain     = Color(0xFF4CAF50);  // green — healthy
  static const organKidney    = Color(0xFF00B4D8);  // cyan
  static const organHeart     = Color(0xFFE53935);  // red
  static const organSkin      = Color(0xFF9C27B0);  // purple

  // Text
  static const textPrimary    = Color(0xFFFFFFFF);
  static const textSecondary  = Color(0xFF8FA8C8);
  static const textHint       = Color(0xFF4A6080);

  // Semantic
  static const success        = Color(0xFF4CAF50);
  static const warning        = Color(0xFFFF9800);
  static const error          = Color(0xFFE53935);
}
```

### Typography
```dart
// lib/core/constants/app_text_styles.dart
class AppTextStyles {
  static const displayLarge  = TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary);
  static const displayMedium = TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textPrimary);
  static const headingLarge  = TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary);
  static const headingMedium = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);
  static const bodyLarge     = TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const bodyMedium    = TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const label         = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary);
  static const caption       = TextStyle(fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.textHint);
}
```

---

## 2. Navigation

```
Bottom Tab Bar (6 items):
  Drop   → HomeScreen       (Living Drop)
  Coach  → AiCoachScreen    (Chat UI)
  Body   → BodyMapScreen    (Ecosystem)
  Stats  → StatsScreen      (Wave Chart)
  Level  → LevelScreen      (Achievements)
  You    → ProfileScreen    (Profile)

FAB (floating): camera icon → SmartScanScreen
```

---

## 3. Screens

### Screen 01 — Home (Living Drop)

**5 States theo hydration % + điều kiện:**

| State | % | Điều kiện | Drop color | Message |
|---|---|---|---|---|
| Dehydrated | 0–25% | bất kỳ | Dark navy | "Cơ thể bạn đang khát" |
| Low | 26–45% | bất kỳ | Navy-blue | "Hãy cùng giữ nhịp uống nước" |
| Normal | 46–75% | bình thường | Cyan | "Hãy cùng giữ nhịp uống nước" |
| Hot weather | 46–75% | temp ≥ 34°C | Orange tint | "Hãy cùng giữ nhịp uống nước" |
| Near goal | 76–100% | bất kỳ | Bright cyan | "Tuyệt vời, gần đủ rồi!" |

**UI Components:**
```
Header  : location pill (HCMC · 28°C) + streak badge (🔥 Streak 12 ngày)
Greeting: "CHÀO BUỔI SÁNG" label + dynamic headline
Drop    : animated SVG drop, fill = progress%, breathing pulse animation
         hiển thị: XX% + {current}/{goal} ml
XP bar  : "LV 7 · Aqua Warrior  1240 / 2000 XP"
Quick log: [100ml] [250ml] [500ml] [+ Khác] — Hold để rót dài
AQUA AI card: avatar dot + message + arrow →
Today row: "Hôm nay  5 lần · 1450ml"
FAB     : camera scan button (bottom right, cyan)
```

---

### Screen 02 — AI Coach

**Chat UI:**
```
Header: "Aqua AI" + "online · context-aware" badge + [Đóng]
Sub   : progress bar {current}/{goal}ml + %

Messages:
  AI bubble  : left-aligned, navy card, white text
  User bubble: right-aligned, cyan background
  Timestamp  : below each bubble

Quick replies (sau AI message):
  [Uống 250ml ngay]  [Xem tiến độ]  [Đặt nhắc nhở]

Context-aware triggers:
  - Log cà phê → "cà phê có tính lợi tiểu, thêm +250ml"
  - Temp ≥ 34°C → "tăng goal từ 2,500ml lên 2,800ml"
  - Chậm tiến độ → "đã 14h mà mới đạt 28%"
  - Gần streak → "chỉ còn 380ml nữa, streak 13 ngày!"
```

---

### Screen 03 — Ecosystem (Body Map)

**3 States:**
```
Dehydrated (< 40%): background màu cam/nâu khô, organs mờ
  - Não: Mệt mỏi · Thận: Quá tải · Tim: Đập nhanh · Da: Khô
  - Headline: "Hệ sinh thái khô hạn"

Recovering (40–80%): background navy, organs bình thường
  - Não: Ổn định · Thận: Bình thường · Tim: Đều · Da: Đang phục hồi
  - Headline: "Đang phục hồi"

Blooming (> 80%): background xanh đậm sáng, organs sáng rực
  - Não: Tỉnh táo · Thận: Hoạt động tốt
  - Headline: "Hệ sinh thái nở rộ"
```

**UI Components:**
```
Header: "HỆ SINH THÁI CƠ THỂ" + state headline + subtitle
Card  : body SVG (stickman outline) + 4 organ bubbles (màu theo trạng thái)
       hydration % top-right + HCMC pill
       quote: "Uống đủ nước → hệ sinh thái phát triển"
Grid  : 2×2 organ cards (icon + tên + trạng thái + progress bar)
```

---

### Screen 04 — Stats (Wave Chart)

```
Toggle: [Tuần] [Tháng]
Header: tổng tuần (14.7L) + delta (+1.2L vs tuần trước) + badge (+8.9%)

Wave chart: 7 ngày, filled area chart (fl_chart)
  - Dashed line: Goal 100%
  - Data points: % đạt goal mỗi ngày (T2 102% · T3 88%...)
  - Highlight màu đỏ: ngày không đạt (T6 67%)

Summary cards (3 tiles):
  84% goal met · 12🔥 day streak · 14.7L this week

AI Insights (expandable cards):
  HYDRATION : "Buổi chiều là điểm yếu..."
  PATTERN   : "Thứ Hai & Thứ Tư đạt 100%..."
  WEATHER   : "Hôm nay nóng — goal đã tăng"
```

---

### Screen 05 — Level & Achievements

```
Level card (purple gradient):
  "CẤP HIỆN TẠI · Aqua Warrior · Còn 760 XP để lên Lv 8"
  XP bar: 1240 / 2000
  Timeline: LV5 Water Warrior → LV7 Aqua Warrior (current) → LV10 Ocean Master → LV15 Hydration Legend

Achievement grid (2×2 cards):
  🔥 Streak 7 ngày    → +50 XP (unlocked)
  ⭐ Đủ nước 5 lần   → Theme unlock (unlocked)
  🎖 Tuần 14L        → Avatar frame (locked)
  🏆 Top 10% tuần    → Special badge (locked)

Unlocked rewards:
  Avatars section: [Drop] [Wave] [Glacier] [🔒Ocean LV10] [🔒]
```

---

### Screen 06 — Log Drink

```
Header: "← Huỷ" + "Log thức uống"

Drink type chips (icon + label, single select):
  💧 Nước lọc  🍵 Trà  ☕ Cà phê  🍊 Trái cây  🥤 Sinh tố

Amount stepper:
  [−]  250 ML  [+]
  Quick presets: [100ml] [250ml] [500ml] [750ml]

Preview card "SAU KHI LOG":
  {new_total} / {goal}ml + %
  progress bar (cyan fill)
  "+20 XP · còn {remaining}ml để đạt goal"

CTA: [Log 250ml] — full width, cyan
```

**Hydration coefficient (tự động tính):**
```dart
const hydrationCoeff = {
  'water': 1.00, 'tea': 0.90, 'coffee': 0.80,
  'juice': 0.85, 'smoothie': 0.90,
};
effective_ml = amount * hydrationCoeff[type]
```

---

### Screen 07 — Smart Scan

```
Full-screen camera preview (dark overlay)
Header: [×] + "✦ Smart Scan · AI" pill + [🔍]

Scanning state:
  Dashed oval frame (cyan animated dashes)
  Container icon renders inside frame
  Pill: "Đang quét... giữ camera ổn định"

Result state (bottom sheet):
  Container icon + "Cà phê đá · ~180ml"
  Effective: "≈ 144ml hydration (×0.8)"
  Confidence bar
  [confidence high]  → [✓ Xác nhận 180ml]
  [confidence medium]→ Slider + [✓ Xác nhận]
  [confidence low]   → "Chỉnh lại" + Slider
```

---

### Screen 08 — Profile

```
Header: avatar (cyan drop icon + LV badge) + "Minh Nguyễn"
        "Aqua Warrior · Tham gia 84 ngày"
        XP bar: LV 7 · 1240 / 2000 XP

Stats row (3 tiles):
  284L Total water · 21 ngày Longest streak · 84/90 Days active

Avatar collection (horizontal scroll):
  [Drop CUR] [Wave] [Glacier] [🔒 Ocean LV10] [🔒]

Themes (2×2 grid):
  [Ocean Night - Đang dùng] [Default Blue - Đã mở]
  [🔒 Desert Sunset LV9]   [🔒 Forest Rain LV11]

Daily Goal section (editable)
Settings gear icon (top right)
```

---

## 4. Widgets

### Small 2×2
```
Drop icon (mini) + "58%" large
"1,450 / 2,500ml" small
[+ 250ml] button (cyan, tappable)
```

### Medium 4×2
```
Drop icon + "58%" + "1,450/2,500ml"
AI insight quote (1 line)
[+100] [+250] [+500] quick log buttons
Streak badge top-right
```

### Lock Screen
```
Mini drop icon + "58%" + "1,450 / 2,500ml"
🔥 Streak 12 ngày
```

---

## 5. Gamification System

### XP Events
```dart
const xpEvents = {
  'log_drink':         10,   // mỗi lần log
  'daily_goal_met':    50,   // đạt 100% mục tiêu
  'streak_7':          100,
  'streak_30':         500,
  'total_100L':        200,
  'smart_scan_used':   5,    // dùng AI scan
};
```

### Level Thresholds
```dart
const levels = {
  1:  (0,     'Water Newbie'),
  5:  (500,   'Water Warrior'),
  7:  (1000,  'Aqua Warrior'),     // ← current in prototype
  10: (3000,  'Ocean Master'),
  15: (8000,  'Hydration Legend'),
};
```

### Achievements
```
🔥 Streak 7 ngày      → +50 XP
⭐ Đủ nước 5 lần      → Theme unlock
🎖 Tuần 14L           → Avatar frame
🏆 Top 10% tuần       → Special badge
💧 Tổng 100L          → Avatar unlock
🌡 Hot day warrior    → Đạt goal khi temp > 35°C
```

---

## 6. Home State Logic

```dart
enum HomeState { dehydrated, low, normalCool, normalHot, nearGoal }

HomeState getHomeState(double progress, double tempCelsius) {
  if (progress <= 0.25) return HomeState.dehydrated;
  if (progress <= 0.45) return HomeState.low;
  if (progress >= 0.76) return HomeState.nearGoal;
  if (tempCelsius >= 34) return HomeState.normalHot;
  return HomeState.normalCool;
}

// Drop fill color theo state
Color dropColor(HomeState state) => switch (state) {
  HomeState.dehydrated  => AppColors.surface,         // empty, dark
  HomeState.low         => const Color(0xFF1A4A7A),   // navy-blue
  HomeState.normalCool  => AppColors.cyan,            // bright cyan
  HomeState.normalHot   => const Color(0xFFFF6B35),   // orange tint
  HomeState.nearGoal    => AppColors.cyanLight,       // bright
};
```

---

## 7. AI Coach — Context Triggers

```python
# backend/services/ai_coach_service.py

TRIGGERS = [
    {
        "condition": lambda log, weather: log.liquid_type == "coffee",
        "message": "Cà phê bạn vừa log có tính lợi tiểu — cần thêm +250ml để bù lại.",
        "quick_replies": ["Uống 250ml ngay", "Xem tiến độ", "Đặt nhắc nhở"],
    },
    {
        "condition": lambda log, weather: weather.temp >= 34,
        "message": lambda goal, temp: f"HCMC đang {temp}°C. Mình đã tự động tăng goal hôm nay lên {goal+300}ml.",
        "quick_replies": ["OK, mình sẽ cố", "Xem mục tiêu mới"],
    },
    {
        "condition": lambda log, weather: log.progress < 0.3 and datetime.now().hour >= 14,
        "message": "Đã 14h mà mới đạt 28%. Uống 300ml để theo kịp nhé!",
        "quick_replies": ["Log ngay", "Đặt nhắc nhở"],
    },
    {
        "condition": lambda log, weather: log.streak >= 12 and log.remaining <= 400,
        "message": f"Bạn đang trên đà streak {log.streak+1} ngày — chỉ còn {log.remaining}ml nữa thôi!",
        "quick_replies": ["Log ngay 💪"],
    },
]
```

---

## 8. Personalization — Daily Goal Formula

```python
def calculate_daily_goal(profile, temp_celsius: float) -> int:
    base = profile.weight_kg * 35

    activity_map = {
        'sedentary': 1.00, 'light': 1.10, 'moderate': 1.20,
        'active': 1.35, 'athlete': 1.50,
    }
    a = activity_map.get(profile.activity_level, 1.10)

    c = 1.0 if temp_celsius < 25 else \
        1.1 if temp_celsius < 30 else \
        1.2 if temp_celsius < 35 else 1.3

    health_delta = {
        'pregnant': 300, 'breastfeeding': 500,
        'kidney_stone': 500, 'kidney_disease': -300, 'diabetes': 200,
    }
    h = sum(health_delta.get(x, 0) for x in (profile.health_conditions or []))

    type_bonus = {
        'gymmer': 200, 'runner': 400, 'outdoor_worker': 300, 'athlete': 500,
    }
    s = sum(type_bonus.get(t, 0) for t in (profile.user_type or []))

    return round(((base * a * c) + h + s) / 50) * 50
```

---

## 9. API Endpoints

```
POST   /api/v1/estimate          → Smart Scan AI vision
POST   /api/v1/intake            → Log drink (any method)
DELETE /api/v1/intake/{id}       → Xoá lần uống
GET    /api/v1/summary/today     → Home screen data
GET    /api/v1/summary/weekly    → Stats screen data
GET    /api/v1/coach/message     → AI Coach trigger check
PUT    /api/v1/profile           → Cập nhật + recalc goal
GET    /api/v1/health
```

---

## 10. Flutter Folder Structure

```
lib/
├── main.dart
├── app.dart                        # MaterialApp + GoRouter + BottomNav
├── core/
│   ├── constants/
│   │   ├── app_colors.dart         ← design system colors
│   │   ├── app_text_styles.dart    ← typography
│   │   └── api_endpoints.dart
│   ├── services/
│   │   ├── api_service.dart
│   │   ├── auth_service.dart
│   │   ├── storage_service.dart    # Hive offline
│   │   ├── vision_service.dart     # TFLite Smart Scan
│   │   └── notification_service.dart
│   └── utils/
│       ├── goal_calculator.dart
│       ├── xp_calculator.dart      ← gamification logic
│       └── date_helpers.dart
│
├── features/
│   ├── home/                       # Screen 01 — Living Drop
│   │   ├── screens/home_screen.dart
│   │   ├── widgets/
│   │   │   ├── living_drop.dart    ← animated SVG drop (CORE widget)
│   │   │   ├── drop_state.dart     ← 5 state logic
│   │   │   ├── quick_log_bar.dart  ← 100/250/500/Khác
│   │   │   ├── aqua_ai_card.dart   ← AI nudge card
│   │   │   └── streak_badge.dart
│   │   └── providers/home_provider.dart
│   │
│   ├── coach/                      # Screen 02 — AI Coach
│   │   ├── screens/coach_screen.dart
│   │   ├── widgets/
│   │   │   ├── chat_bubble.dart
│   │   │   └── quick_reply_chips.dart
│   │   └── providers/coach_provider.dart
│   │
│   ├── body_map/                   # Screen 03 — Ecosystem
│   │   ├── screens/body_map_screen.dart
│   │   ├── widgets/
│   │   │   ├── body_svg.dart       ← stickman SVG + organ bubbles
│   │   │   ├── organ_bubble.dart   ← màu theo hydration state
│   │   │   └── organ_card.dart     ← 2×2 status grid
│   │   └── providers/body_map_provider.dart
│   │
│   ├── stats/                      # Screen 04 — Wave Chart
│   │   ├── screens/stats_screen.dart
│   │   ├── widgets/
│   │   │   ├── wave_chart.dart     ← fl_chart filled area
│   │   │   ├── summary_tiles.dart  ← 3 stat cards
│   │   │   └── ai_insight_card.dart
│   │   └── providers/stats_provider.dart
│   │
│   ├── level/                      # Screen 05 — Level & Achievements
│   │   ├── screens/level_screen.dart
│   │   ├── widgets/
│   │   │   ├── level_card.dart     ← purple gradient + XP bar
│   │   │   ├── achievement_card.dart
│   │   │   └── avatar_collection.dart
│   │   └── providers/level_provider.dart
│   │
│   ├── log_drink/                  # Screen 06 — Log Drink
│   │   ├── screens/log_drink_screen.dart
│   │   ├── widgets/
│   │   │   ├── drink_type_chips.dart
│   │   │   ├── amount_stepper.dart
│   │   │   └── log_preview_card.dart
│   │   └── providers/log_drink_provider.dart
│   │
│   ├── smart_scan/                 # Screen 07 — Smart Scan
│   │   ├── screens/smart_scan_screen.dart
│   │   ├── widgets/
│   │   │   ├── scan_overlay.dart   ← animated dashed oval
│   │   │   ├── scan_result_sheet.dart
│   │   │   └── confidence_slider.dart
│   │   └── providers/smart_scan_provider.dart
│   │
│   ├── profile/                    # Screen 08 — Profile
│   │   ├── screens/profile_screen.dart
│   │   ├── widgets/
│   │   │   ├── profile_header.dart
│   │   │   ├── stats_row.dart
│   │   │   ├── avatar_grid.dart
│   │   │   └── theme_grid.dart
│   │   └── providers/profile_provider.dart
│   │
│   └── onboarding/                 # First-run flow
│       ├── screens/
│       │   ├── welcome_screen.dart
│       │   ├── profile_form_screen.dart
│       │   └── goal_reveal_screen.dart
│       └── providers/onboarding_provider.dart
│
└── shared/
    ├── widgets/
    │   ├── primary_button.dart
    │   ├── xp_bar.dart             ← dùng ở nhiều screen
    │   └── bottom_nav.dart         ← 6-tab nav
    └── models/
        ├── user_profile.dart
        ├── intake_log.dart
        ├── daily_summary.dart
        ├── vision_result.dart
        └── achievement.dart
```

---

## 11. Database Schema

```sql
CREATE TABLE users (
  uid               VARCHAR(128) PRIMARY KEY,
  display_name      VARCHAR(100),
  avatar_id         VARCHAR(20)  DEFAULT 'drop',
  theme_id          VARCHAR(20)  DEFAULT 'default_blue',
  gender            VARCHAR(10),
  age               SMALLINT,
  weight_kg         NUMERIC(5,1),
  height_cm         NUMERIC(5,1),
  activity_level    VARCHAR(20)  DEFAULT 'light',
  health_conditions TEXT[]       DEFAULT '{"none"}',
  user_type         TEXT[]       DEFAULT '{"office_worker"}',
  city              VARCHAR(100),
  lat               NUMERIC(9,6),
  lng               NUMERIC(9,6),
  daily_goal_ml     INT          DEFAULT 2000,
  current_xp        INT          DEFAULT 0,
  current_level     SMALLINT     DEFAULT 1,
  reminder_enabled  BOOLEAN      DEFAULT true,
  reminder_times    TEXT[]       DEFAULT '{"07:00","10:00","12:00","15:00","20:00"}',
  onboarding_done   BOOLEAN      DEFAULT false,
  created_at        TIMESTAMPTZ  DEFAULT now(),
  updated_at        TIMESTAMPTZ  DEFAULT now()
);

CREATE TABLE intake_logs (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  uid                 VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
  volume_ml           SMALLINT    NOT NULL,
  effective_volume_ml SMALLINT    NOT NULL,
  liquid_type         VARCHAR(20) DEFAULT 'water',
  logged_at           TIMESTAMPTZ NOT NULL,
  source              VARCHAR(20) CHECK (source IN ('smart_scan','quick_log','manual','ai_server')),
  container_class     VARCHAR(50),
  confidence          VARCHAR(10),
  xp_earned           SMALLINT    DEFAULT 10,
  created_at          TIMESTAMPTZ DEFAULT now()
);
CREATE INDEX idx_intake_uid_date ON intake_logs (uid, logged_at DESC);

CREATE TABLE daily_summaries (
  uid        VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
  date       DATE         NOT NULL,
  goal_ml    INT,
  total_ml   INT          DEFAULT 0,
  log_count  SMALLINT     DEFAULT 0,
  xp_earned  INT          DEFAULT 0,
  goal_met   BOOLEAN      DEFAULT false,
  PRIMARY KEY (uid, date)
);

CREATE TABLE streaks (
  uid          VARCHAR(128) PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
  current_days INT     DEFAULT 0,
  longest_days INT     DEFAULT 0,
  last_date    DATE
);

CREATE TABLE achievements (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  uid         VARCHAR(128) REFERENCES users(uid) ON DELETE CASCADE,
  type        VARCHAR(50),   -- 'streak_7', 'goal_5x', 'total_100L'...
  unlocked_at TIMESTAMPTZ DEFAULT now()
);
```

---

## 12. Build Priority

```
Tuần 1: Onboarding + Home Screen (Living Drop + Quick Log)
Tuần 2: Log Drink screen + AI Coach (basic)
Tuần 3: Smart Scan (TFLite on-device)
Tuần 4: Body Map + Stats + Level
Tuần 5: Profile + Widgets + Polish
Tuần 6: Backend API + Sync
Song song: Thu thập data ML → Train TFLite model
```

---

## 13. Key Metrics

| Metric | Target |
|---|---|
| Smart Scan accuracy (fill MAE) | < 8% |
| Scan → confirm time | < 10 giây |
| D1 / D7 / D30 retention | 60% / 40% / 20% |
| Daily log events | > 3 lần/ngày |
| Goal achievement rate | > 60% user đạt ≥ 80% |
| App Store rating | ≥ 4.5 ⭐ |

---

*AquaTrack · Flutter + FastAPI · Custom AI · Free forever*
*Hi-Fi Prototype → Production · 2026*
