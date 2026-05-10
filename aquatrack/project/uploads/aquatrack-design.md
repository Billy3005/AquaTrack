# AquaTrack — Design Specification

> "A hydration experience, not just a tracking app."
> Kết hợp Emotional Design · AI Coach · Gamification · Context-Aware UI

---

## 1. Design Philosophy

AquaTrack biến hành động uống nước thành một trải nghiệm sống — người dùng không "nhập số liệu" mà "nuôi" một sinh thể nước. Mọi quyết định thiết kế đều phục vụ 3 mục tiêu:

- **Reduce friction** — log nước trong 1 tap, không cần mở app đầy đủ
- **Build emotion** — giọt nước sống động, cơ thể như hệ sinh thái
- **Drive retention** — streak, XP, AI insights cá nhân hóa

---

## 2. Visual Identity

### Color System

| Token | Hex | Dùng cho |
|---|---|---|
| `--aqua-primary` | `#0EA5E9` | CTA, progress fill, active state |
| `--aqua-glow` | `#38BDF8` | XP bar, AI chat bubble, level badge |
| `--aqua-deep` | `#0284C7` | Header gradient deep |
| `--night-base` | `#0B1120` | Dark mode background |
| `--night-surface` | `#0F1A2E` | Card surface dark |
| `--night-card` | `#1E293B` | Secondary card dark |
| `--eco-green` | `#059669` | Ecosystem healthy state |
| `--xp-purple` | `#818CF8` | Gamification / level card |
| `--warning-amber` | `#F59E0B` | Hot weather alert, context-aware |

### Typography

```
Display / Hero numbers:  SF Pro Display  |  28–32px  |  weight 500
Section titles:          SF Pro Display  |  16–18px  |  weight 500
Body / Labels:           SF Pro Text     |  12–14px  |  weight 400
Micro labels:            SF Pro Text     |  9–11px   |  weight 400
XP / Badge text:         SF Pro Rounded  |  9–12px   |  weight 500
```

### Border Radius

```
Phone frame:    22px
Cards:          12–16px
Chips / pills:  20px (full round)
Quick-tap btn:  10px
Badges:         20px
```

---

## 3. Screen Specifications

### 3.1 Home Screen — "Living Drop"

**Layout:** Full-bleed hero (top 55%) + scroll content (bottom 45%)

**Hero section** (`background: #0C4A80`):
- Animated water drop SVG ở trung tâm
  - Drop fill theo % hoàn thành (0–100%)
  - Trạng thái màu:
    - 0–30%: fill `#1E3A5F` (gần trống, tối)
    - 31–69%: fill `#0EA5E9` (đang đầy, xanh)
    - 70–100%: fill `#38BDF8` + subtle pulse animation (đủ nước, sáng)
  - Số % hiển thị trong lòng giọt nước
  - ml hiện tại / tổng mục tiêu phía dưới drop
- XP bar ngay dưới hero text — không cần vào tab riêng
- Streak badge: `🔥 Streak X ngày`

**Content section:**
- Quick tap row: `[100ml] [250ml] [500ml] [+ tùy chọn]`
  - Chip đang active: `background #0C3F6A`, border `#38BDF8`
  - Hold gesture → pour animation (Rive/Lottie)
- Today's log: 3 item gần nhất, icon loại đồ uống, timestamp, ml

**States:**
- Đủ nước (≥80%): hero bg sáng hơn, drop phát sáng, confetti nhỏ
- Thiếu nước (<30%): hero bg tối, drop có crack texture overlay
- Đêm khuya (sau 10pm): dark mode tự động, giảm brightness hero

---

### 3.2 AI Coach Screen

**Layout:** Chat interface + pinned progress bar ở top

**Pinned bar** (luôn hiển thị):
```
[Drop icon] 1,450 / 2,500ml ████░░░░ 58%
```

**Chat bubbles:**
- AI bubble: `background #1E3A5F`, text `#BAE6FD`, border-radius `4px 12px 12px 12px`
- User bubble: `background #0EA5E9`, text `#FFFFFF`, border-radius `12px 4px 12px 12px`
- AI avatar: circle với aqua dot ở center, label "Aqua AI · online"

**Context-aware triggers AI gợi ý:**

| Trigger | AI Message |
|---|---|
| Vừa log cà phê | "Cà phê có tính lợi tiểu — cần thêm +250ml để bù lại ☕" |
| Nhiệt độ > 32°C | "Trời HCMC đang {temp}°C — uống thêm +300ml so với bình thường 🌡️" |
| Sau workout | "Bạn vừa tập — cần bù +500ml điện giải ngay 💪" |
| 2pm chưa đạt 50% | "Đã 2 giờ chiều mà mới đạt 40%. Uống 300ml ngay để theo kịp nhé!" |
| Streak sắp đứt | "Chỉ còn 200ml nữa là giữ streak 12 ngày! Uống ngay nhé 🔥" |

**Quick reply chips** (3 chips gợi ý theo context):
- "Uống 250ml ngay"
- "Xem tiến độ hôm nay"
- "Đặt nhắc nhở"

---

### 3.3 Ecosystem Screen — "Body as World"

**Concept:** Cơ thể người = hệ sinh thái. Nước = nguồn sống.

**Visual map** (SVG illustration, 320×180px):
- Trung tâm: silhouette cơ thể người (simplified, flat)
- 4 organ nodes kết nối vào cơ thể:
  - **Não** (top-left): màu `#064E3B` → `#059669` khi đủ nước
  - **Thận** (top-right): màu `#0C3A5E` → `#0EA5E9` khi cần nước
  - **Tim** (center): màu `#4A1B0C` → `#D85A30` khi dehydrated
  - **Da** (bottom): màu `#1C1040` → `#818CF8` 
- Environment badge (top): nhiệt độ thực tế, kéo vào cơ thể bằng dashed line
- Màu sắc node tự động thay đổi theo % hydration hiện tại
- Caption: "Uống đủ nước → hệ sinh thái phát triển"

**Dehydration mode** (< 40%):
- Nền map chuyển sang màu cát / sa mạc `#78350F`
- Các đường kết nối trở thành màu đỏ nhạt
- Crack texture overlay trên silhouette

**Full hydration mode** (≥ 90%):
- Nền xanh ocean
- Các organ nodes phát sáng nhẹ
- Particle effect: bong bóng nước nhỏ nổi lên

---

### 3.4 Stats Screen

**Header:** "Tuần này" / "Tháng này" toggle

**Wave Chart** (thay bar chart):
- SVG animated wave, trục X = ngày trong tuần
- Fill area dưới đường sóng = `#0C3A5E`
- Đường sóng = `stroke #38BDF8`, 1.5px
- Dashed line ngang = mục tiêu daily
- Ngày đạt mục tiêu: crest wave cao hơn line
- Ngày không đạt: crest thấp hơn, fill màu `#7F1D1D` opacity 30%

**Metric row (3 items):**
```
[84% goal met]  [12 day streak]  [14.7L this week]
```
Background `#1E293B`, border-radius 8px

**AI Insights cards** (2–3 cards):
- Border-left 2px accent màu theo loại insight
  - 🔵 `#38BDF8` — hydration tip
  - 🟣 `#818CF8` — pattern recognition
  - 🟡 `#F59E0B` — weather/activity
- Ví dụ content:
  - "Bạn thường uống ít nhất vào buổi chiều (2–5pm)"
  - "Thứ 2 & Thứ 4 bạn đạt 100%, Thứ 6 chỉ đạt 67%"
  - "Sau mỗi buổi tập gym, bạn uống nhiều hơn 40%"

---

### 3.5 Gamification Screen

**Level Card:**
- Background: `#1A1040`, border: `1px solid #4F46E5`
- Level badge (top right): `background #4F46E5`, text `#C7D2FE`
- Level name progression:
  ```
  Lv 1  Thirsty Beginner
  Lv 3  Hydration Starter
  Lv 5  Water Warrior
  Lv 7  Aqua Warrior       ← current example
  Lv 10 Ocean Master
  Lv 15 Hydration Legend
  ```
- XP bar: `background #312E81` track, `#818CF8` fill

**Achievement Grid** (2×2 per row):
| Icon | Name | Unlock condition | Reward |
|---|---|---|---|
| ✅ Streak badge | 7 ngày liên tiếp | 7-day streak | +50 XP |
| ⭐ Star | Đủ nước 5 lần | 5× daily goal | Theme unlock |
| 🌊 Wave | 2,000ml × 7 ngày | Weekly challenge | Avatar frame |
| 🏆 Trophy | Top 10% tuần | Leaderboard | Special badge |

**Unlock rewards:**
- **Avatar**: 5 avatar nước (droplet, wave, ocean, glacier, cloud)
- **Theme**: Default Blue → Ocean Night → Desert Sunset → Forest Rain
- **Animation**: Thêm loại pour animation khi log nước

---

### 3.6 Log Drink Screen

**Drink type chips** (wrap row):
- `💧 Nước lọc` — selected: `background #0C4A6E`, border `#38BDF8`
- `🍵 Trà` — unselected: `background #1E293B`
- `☕ Cà phê`
- `🧃 Nước trái cây`
- `🥤 Sinh tố`
- `+ Thêm loại`

**Amount selector:**
- Quick pick: `[100ml] [250ml] [500ml] [750ml]`
- Custom stepper: `[−] 250 ml [+]`
- Slider (optional, swipe): 0–1000ml, step 50ml

**Preview after log:**
```
Sau khi log:  1,700ml / 2,500ml  ██████░░ 68%
```

**Submit:** Full-width button `"Log drink"` — `background #0EA5E9`
- Tap → XP popup animation: `+20 XP` nổi lên và fade out
- Drop fill animation trong hero screen cập nhật real-time

---

### 3.7 Reminder / Notification

**Notification style:** Soft, supportive — không gây áp lực

| Time | Tone | Message example |
|---|---|---|
| Sáng 8am | Energetic | "Chào buổi sáng! Uống 250ml ngay để khởi động ngày mới 🌅" |
| Trưa 12pm | Friendly | "Đã uống đủ chưa? Còn 1,200ml nữa nhé 💙" |
| Chiều 3pm | Gentle | "Buổi chiều dễ quên uống nước — nhớ bổ sung nhé" |
| Tối 8pm | Calm | "Hôm nay đạt 80% rồi, chỉ còn 500ml nữa thôi 🌙" |
| Streak sắp đứt | Urgent | "Streak 12 ngày sắp đứt! Uống 200ml ngay để giữ nhé 🔥" |

---

### 3.8 Widget & Lock Screen

**Home screen widget (small 2×2):**
- Drop icon fill theo %
- Số ml hiện tại / goal
- `[+250ml]` quick-action button
- XP level badge

**Home screen widget (medium 4×2):**
- Tất cả small widget +
- Progress bar ngang
- Streak count
- AI micro-tip (1 dòng)

**Lock screen widget:**
- Drop SVG (32×40px)
- Số % lớn
- ml / goal nhỏ hơn

---

## 4. Motion & Animation

### Key animations (Rive / Lottie)

| Interaction | Animation | Duration |
|---|---|---|
| Log water | Drop fill animation | 600ms ease-out |
| Goal reached | Confetti burst + drop overflow | 1200ms |
| XP gain | "+XP" text float up + fade | 800ms |
| Level up | Full screen celebration | 2000ms |
| Ecosystem update | Organ nodes color transition | 1000ms |
| Streak broken | Drop crack animation | 500ms |
| Hold to pour | Continuous pour stream | While holding |

### Micro-interactions
- Quick tap button: scale 0.95 → 1.0 on press (50ms)
- Chip selection: border appear với spring animation (200ms)
- Chat bubble appear: slide up + fade (300ms)
- Wave chart: draw animation on screen enter (800ms)

---

## 5. Context-Aware UI Rules

| Context | UI change |
|---|---|
| Nhiệt độ > 32°C | Hero bg warm tint `#1A0A00`, warning card `amber` |
| Sau 10pm | Auto dark mode, giảm notification frequency |
| Sáng sớm (6–9am) | Hero bg sáng hơn, energetic tone |
| Workout detected | Special log screen "Post-workout hydration" |
| Ngày mưa / mát | Goal giảm nhẹ, UI tone cool blue |

---

## 6. Accessibility

- Minimum touch target: 44×44px cho tất cả interactive elements
- Color không phải cách duy nhất truyền tải trạng thái (luôn có icon/text kèm)
- Font size tối thiểu: 11px
- VoiceOver support cho progress % và log actions
- Reduce motion mode: tắt particle effects, giữ functional animations

---

## 7. Tech Stack Recommendation

| Layer | Tech |
|---|---|
| Mobile framework | React Native / Flutter |
| Animations | Rive (interactive) + Lottie (one-shot) |
| Data viz | D3.js (wave chart) / Recharts |
| AI backend | Anthropic Claude API (context-aware suggestions) |
| State management | Zustand / Riverpod |
| Local storage | SQLite (offline-first) |

---

## 8. Screen Flow

```
Onboarding (weight, goal, schedule)
    ↓
Home (Living Drop + Quick Tap)
    ├── Log Drink → XP animation → Home
    ├── AI Coach (chat + context tips)
    ├── Ecosystem (body map)
    ├── Stats (wave chart + insights)
    └── Gamification (level + achievements)
         ↓
Widget / Lock Screen (1-tap log, no app open)
```

---

## 9. Design Deliverables Checklist

- [ ] Onboarding flow (5 steps)
- [ ] Home screen — 3 states (normal / dehydrated / goal reached)
- [ ] AI Coach chat screen
- [ ] Ecosystem body map (hydrated vs dehydrated)
- [ ] Log drink screen
- [ ] Stats screen (wave chart)
- [ ] Gamification / Level screen
- [ ] Notification templates (5 tones)
- [ ] Widget designs (small / medium / lock screen)
- [ ] Dark mode variants cho tất cả screens
- [ ] Component library (buttons, chips, cards, XP bar, drop SVG)
- [ ] Motion spec document

---

*AquaTrack Design Spec v1.0 — generated for claude.ai design tooling*
