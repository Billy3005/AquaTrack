import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_app/core/services/insight_engine.dart';

void main() {
  group('InsightEngine', () {
    test('should return exactly 3 insights for valid context', () {
      // Arrange - Create minimal valid context
      final context = InsightContext(
        weatherState: const WeatherState(
          condition: WeatherCondition.fresh,
          temperatureCelsius: 25.0,
          locationName: 'Test City',
          confidence: 1.0,
        ),
        statsPattern: const StatsPattern(
          weeklyAverage: 1800.0,
          dailyPatterns: [0.8, 0.9, 0.7, 0.8, 0.6, 0.7, 0.9],
          hourlyPatterns: [
            0,
            0,
            0,
            0,
            0,
            0,
            1,
            2,
            1,
            1,
            1,
            1,
            1,
            2,
            3,
            2,
            1,
            1,
            1,
            1,
            0,
            0,
            0,
            0
          ],
          currentStreak: 5,
          todayProgress: 0.7,
        ),
        timeContext: const TimeContext(
          hour: 14,
          dayOfWeek: 3, // Wednesday
          timeOfDay: 'afternoon',
        ),
        userProfile: const UserProfile(
          dailyGoalMl: 2000.0,
          age: 25,
          activityLevel: 'moderate',
          preferences: ['water', 'tea'],
        ),
      );

      // Act
      final insights = InsightEngine.generateStatsInsights(context);

      // Assert - TDD: Test behavior through public interface
      expect(insights, hasLength(3),
          reason: 'Should always return exactly 3 insights');

      for (final insight in insights) {
        expect(insight.title.trim(), isNotEmpty,
            reason: 'Insight title should not be empty');
        expect(insight.message.trim(), isNotEmpty,
            reason: 'Insight message should not be empty');
        expect(insight.confidence, inInclusiveRange(0.0, 1.0),
            reason: 'Confidence should be 0.0-1.0');
      }
    });

    test('should generate hot weather insight when temperature > 34°C', () {
      // Arrange - Hot weather context
      final hotWeatherContext = InsightContext(
        weatherState: const WeatherState(
          condition: WeatherCondition.fresh,
          temperatureCelsius: 36.0, // Hot weather
          locationName: 'HCMC',
          confidence: 1.0, // Fresh data
        ),
        statsPattern: const StatsPattern(
          weeklyAverage: 1800.0,
          dailyPatterns: [0.8, 0.9, 0.7, 0.8, 0.6, 0.7, 0.9],
          hourlyPatterns: [
            0,
            0,
            0,
            0,
            0,
            0,
            1,
            2,
            1,
            1,
            1,
            1,
            1,
            2,
            3,
            2,
            1,
            1,
            1,
            1,
            0,
            0,
            0,
            0
          ],
          currentStreak: 5,
          todayProgress: 0.7,
        ),
        timeContext: const TimeContext(
          hour: 14,
          dayOfWeek: 3,
          timeOfDay: 'afternoon',
        ),
        userProfile: const UserProfile(
          dailyGoalMl: 2000.0,
          age: 25,
          activityLevel: 'moderate',
          preferences: ['water', 'tea'],
        ),
      );

      // Act
      final insights = InsightEngine.generateStatsInsights(hotWeatherContext);

      // Assert - Should contain weather-based insight
      expect(insights, hasLength(3));

      // Should have at least one weather-type insight
      final weatherInsights =
          insights.where((insight) => insight.type == InsightType.weather);
      expect(weatherInsights, isNotEmpty,
          reason: 'Should contain weather-based insight');

      // Weather insight should reference temperature/heat
      final weatherInsight = weatherInsights.first;
      final contentLower =
          '${weatherInsight.title} ${weatherInsight.message}'.toLowerCase();
      expect(
          contentLower,
          anyOf([
            contains('nóng'),
            contains('nhiệt độ'),
            contains('36'),
            contains('hôm nay'),
            contains('thời tiết')
          ]),
          reason: 'Weather insight should reference temperature or heat');

      // Hot weather should increase confidence (fresh data)
      expect(weatherInsight.confidence, greaterThan(0.8),
          reason: 'Fresh hot weather data should have high confidence');
    });

    test('should generate pattern-based insight for afternoon weakness', () {
      // Arrange - Pattern showing low afternoon performance
      final afternoonWeaknessContext = InsightContext(
        weatherState: const WeatherState(
          condition: WeatherCondition.fresh,
          temperatureCelsius: 28.0,
          locationName: 'Test City',
          confidence: 1.0,
        ),
        statsPattern: const StatsPattern(
          weeklyAverage: 1800.0,
          // Pattern: Strong mornings (0.9), weak afternoons (0.3-0.4), good evenings (0.8)
          dailyPatterns: [0.9, 0.8, 0.3, 0.4, 0.9, 0.8, 0.7],
          // Hourly pattern: High at 8-9am (3), low 14-17h (1), high 19-20h (2)
          hourlyPatterns: [
            0,
            0,
            0,
            0,
            0,
            0,
            2,
            3,
            2,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            1,
            2,
            2,
            1,
            0,
            0,
            0,
            0
          ],
          currentStreak: 3,
          todayProgress: 0.4, // Low progress showing the afternoon issue
        ),
        timeContext: const TimeContext(
          hour: 15, // 3 PM - peak afternoon weakness time
          dayOfWeek: 3, // Wednesday
          timeOfDay: 'afternoon',
        ),
        userProfile: const UserProfile(
          dailyGoalMl: 2000.0,
          age: 28,
          activityLevel: 'moderate',
          preferences: ['water', 'coffee'],
        ),
      );

      // Act
      final insights =
          InsightEngine.generateStatsInsights(afternoonWeaknessContext);

      // Assert
      expect(insights, hasLength(3));

      // Should contain at least one pattern-based insight
      final patternInsights =
          insights.where((i) => i.type == InsightType.pattern);
      expect(patternInsights, isNotEmpty,
          reason: 'Should contain pattern-based insight');

      // Pattern insight should reference afternoon/timing issues
      final patternInsight = patternInsights.first;
      final contentLower =
          '${patternInsight.title} ${patternInsight.message}'.toLowerCase();
      expect(
          contentLower,
          anyOf([
            contains('buổi chiều'),
            contains('afternoon'),
            contains('14'),
            contains('15'),
            contains('17'),
            contains('điểm yếu'),
            contains('thấp nhất'),
          ]),
          reason: 'Pattern insight should reference afternoon weakness');

      // Pattern analysis should have good confidence based on clear data pattern
      expect(patternInsight.confidence, greaterThan(0.7),
          reason:
              'Clear afternoon weakness pattern should have good confidence');
    });

    test('should apply safety guards to prevent invalid outputs', () {
      // Arrange - Extreme/edge case context that might generate bad outputs
      final extremeContext = InsightContext(
        weatherState: const WeatherState(
          condition: WeatherCondition.unavailable, // No weather data
          temperatureCelsius: null, // Null temperature
          locationName: null,
          confidence: 0.0, // Zero confidence
        ),
        statsPattern: const StatsPattern(
          weeklyAverage: 0.0, // No hydration data
          dailyPatterns: [], // Empty patterns
          hourlyPatterns: [], // Empty patterns
          currentStreak: -1, // Invalid streak
          todayProgress: -0.5, // Invalid progress
        ),
        timeContext: const TimeContext(
          hour: 25, // Invalid hour
          dayOfWeek: 8, // Invalid day
          timeOfDay: '',
        ),
        userProfile: const UserProfile(
          dailyGoalMl: -1000.0, // Invalid goal
          age: -5, // Invalid age
          activityLevel: '', // Empty activity
          preferences: [], // No preferences
        ),
      );

      // Act
      final insights = InsightEngine.generateStatsInsights(extremeContext);

      // Assert - Safety guards should prevent invalid outputs
      expect(insights, hasLength(3),
          reason: 'Should always return exactly 3 insights');

      for (final insight in insights) {
        // Content safety guards
        expect(insight.title.trim(), isNotEmpty,
            reason: 'Title should never be empty');
        expect(insight.message.trim(), isNotEmpty,
            reason: 'Message should never be empty');

        // Confidence bounds
        expect(insight.confidence, inInclusiveRange(0.0, 1.0),
            reason: 'Confidence must be between 0.0 and 1.0');
        expect(insight.confidence, greaterThan(0.0),
            reason: 'Confidence should never be exactly 0.0');

        // Volume recommendation safety (if present)
        if (insight.actionSuggestion != null &&
            insight.actionSuggestion!.toLowerCase().contains('ml')) {
          final mlMatch =
              RegExp(r'(\d+)ml').firstMatch(insight.actionSuggestion!);
          if (mlMatch != null) {
            final volume = int.parse(mlMatch.group(1)!);
            expect(volume, inInclusiveRange(50, 1000),
                reason: 'Volume recommendations should be 50-1000ml');
          }
        }

        // Content quality guards
        final content = '${insight.title} ${insight.message}'.toLowerCase();
        expect(content, isNot(contains('error')),
            reason: 'Should not expose errors');
        expect(content, isNot(contains('null')),
            reason: 'Should not contain "null"');
        expect(content, isNot(contains('undefined')),
            reason: 'Should not contain "undefined"');

        // Reasonable Vietnamese text (not garbled)
        expect(insight.title.length, lessThanOrEqualTo(100),
            reason: 'Title should be reasonably short');
        expect(insight.message.length, lessThanOrEqualTo(300),
            reason: 'Message should be reasonably short');
      }
    });
  });
}
