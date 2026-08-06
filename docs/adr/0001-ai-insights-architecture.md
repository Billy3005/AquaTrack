# ADR-0001: AI Insights Architecture for Stats Screen

## Status
Accepted — partially implemented (xem "Implementation status", cập nhật 2026-08-06)

## Implementation status

Hai trong bốn component đã chạy thật; hai component còn lại viết xong, có test,
nhưng chưa được nối vào UI.

| # | Component | Trạng thái |
|---|---|---|
| 1 | `WeatherRepository` (`core/services/weather_repository.dart`) | ✅ Đang chạy — `homeWeatherProvider` hiển thị nhiệt độ ở Home |
| 2 | `LocationService` (`core/services/location_service.dart`) | ✅ Đang chạy — GPS + fallback TP.HCM |
| 3 | `ContextBuilder` (`core/services/context_builder.dart`) | ⚠️ Có code + test, **không nơi nào import** |
| 4 | `InsightEngine` (`core/services/insight_engine.dart`) | ⚠️ Class có code + test, **chưa từng được khởi tạo**; chỉ các type `WeatherState`/`WeatherCondition` trong file này là đang dùng |

Vấn đề trong phần Context bên dưới ("hardcoded insight cards") **đã được xử lý
theo hướng khác**: `features/stats/widgets/insights_cards.dart` tự sinh nhận xét
từ `statsData` thật (`goalCompletionRate`, `period`, …) bằng logic nội tại của
widget, không đi qua `InsightEngine`. Nghĩa là insight hiện đã cá nhân hoá theo
hành vi người dùng, nhưng **chưa tính tới yếu tố thời tiết** — đúng phần mà
component 3 + 4 sinh ra để giải quyết.

Lưu ý khi nối tiếp: `context_builder.dart` khai báo một class `StatsData` trùng
tên với `StatsData` trong `features/stats/providers/stats_provider.dart` (cái mà
`InsightsCards` đang nhận). Hai class này khác nhau — cần thống nhất trước khi
wire, nếu không sẽ import nhầm.

## Context
Stats screen currently uses hardcoded AI insight cards that don't reflect user's actual hydration patterns or environmental factors. Users see static suggestions like "Buổi chiều là điểm yếu của bạn" regardless of their real behavior or current weather conditions.

## Decision
Implement an intelligence layer architecture with four components:

1. **WeatherRepository** - OpenMeteo API integration with Hive cache (2hr current, 8hr forecast)
2. **LocationService** - Geolocator with opt-in permissions and manual city fallback
3. **Context Builder** - Normalizes raw inputs into InsightContext (WeatherState, StatsPattern, TimeContext)
4. **InsightEngine** - Pure function generating personalized insights from normalized context

## Consequences

### Positive
- Insights become truly personalized based on user patterns and environmental factors
- Clean separation between domain logic (insights) and infrastructure concerns (APIs, cache)
- Robust fallback strategy maintains consistent UX even when external services fail
- Testable architecture with normalized context eliminates complex async testing scenarios

### Negative
- Increased complexity from 3 hardcoded cards to full intelligence infrastructure
- 3-4 week implementation timeline vs simple dynamic text replacement
- External dependency on OpenMeteo API with potential rate limiting
- Multiple failure modes requiring comprehensive fallback handling

### Mitigations
- Cache-first strategy reduces API dependency and improves offline experience
- Graceful degradation through cached → static → generic insights fallback chain
- Rule validation and safety guards prevent AI hallucination or invalid outputs
- Phased rollout (static → hybrid → full AI) minimizes user confusion

## Alternatives Considered
- **Simple dynamic text**: Replace hardcoded strings with template-based generation (rejected: insufficient personalization)
- **Local-only insights**: Generate insights from stats data without weather integration (rejected: misses environmental factors)
- **Third-party weather services**: AccuWeather, WeatherAPI (rejected: require API keys, less reliable than OpenMeteo)