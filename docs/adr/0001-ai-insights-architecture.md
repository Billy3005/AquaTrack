# ADR-0001: AI Insights Architecture for Stats Screen

## Status
Accepted

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