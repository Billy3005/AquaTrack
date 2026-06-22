# ⚡ QUICK START — AquaTrack

## Paste vào đầu mỗi chat mới với Claude Code

```
[CLAUDE.md loaded — AquaTrack]
Stack: Flutter (Riverpod) + FastAPI + TFLite
Design: Dark navy, Living Drop, 8 screens
Đang làm: [ Screen XX | Feature | ML | Backend ]
Task: ___
```

---

## Chọn agent theo việc đang làm

| Đang làm | Prefix |
|---|---|
| Bất kỳ Flutter screen/widget | `[FLUTTER AGENT]` |
| Smart Scan / TFLite / training | `[ML AGENT]` |
| FastAPI endpoint / DB | `[BACKEND AGENT]` |
| README / commit / docs | `[DOCS AGENT]` |

---

## Prompt mẫu theo từng screen

### Screen 01 — Living Drop
```
[FLUTTER AGENT] [style:terse]
Screen: Home — Living Drop
Task: tạo LivingDrop widget — SVG drop, fill = progress%, breathing animation
      5 states: dehydrated/low/normalCool/normalHot/nearGoal
      màu fill theo AppColors từ design prototype
```

### Screen 02 — AI Coach
```
[FLUTTER AGENT] [style:terse]
Screen: AI Coach
Task: tạo CoachScreen — chat bubble UI, quick reply chips
      AI message left, user right, timestamp, cyan quick replies
```

### Screen 03 — Body Map
```
[FLUTTER AGENT] [style:terse]
Screen: Ecosystem Body Map
Task: tạo BodyMapScreen — SVG stickman + 4 organ bubbles
      3 states: dehydrated (orange bg) / recovering (navy) / blooming (cyan)
      organ cards 2×2 grid bên dưới
```

### Screen 07 — Smart Scan
```
[FLUTTER AGENT] [style:terse]
Screen: Smart Scan
Task: tạo SmartScanScreen — fullscreen camera, dashed oval overlay animation
      result bottom sheet: container + ml + hydration effective
      confidence high → 1 tap confirm / medium → slider / low → full slider
```

### Train ML model
```
[ML AGENT] [style:terse]
Task: train MobileNetV3 baseline
File: aquatrack_ml/models/mobilenet/train.py
Issue: ___
```

### Backend AI Coach
```
[BACKEND AGENT] [style:terse]
Endpoint: GET /api/v1/coach/message
Task: implement CoachService.build_message() với 4 triggers:
      caffeine, hot_weather, behind_pace, streak
```

---

## /ship khi xong feature

```bash
/ship flutter          # format + analyze + test + commit + push
/ship --no-test        # bỏ test (khi chưa có test)
```

---

## .task — track việc đang làm

```bash
echo "feature/living-drop - breathing animation" > .task
claude   # SessionStart.sh hiện task này ngay
```

---

## Files quan trọng

```
CLAUDE.md                      ← load mọi chat
docs/agent.md                  ← full product spec (8 screens, design system)
.claude/agents/flutter.md      ← Flutter rules + LivingDrop snippets
.claude/agents/ml.md           ← Smart Scan / TFLite
.claude/agents/backend.md      ← FastAPI + AI Coach
```
