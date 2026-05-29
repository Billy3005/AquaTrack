import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_app/core/services/context_builder.dart';
import 'package:aquatrack_app/core/services/insight_engine.dart';
import 'package:aquatrack_app/core/services/weather_repository.dart';
import 'package:aquatrack_app/core/services/location_service.dart';

void main() {
  group('ContextBuilder', () {
    test('should build complete InsightContext when all data is available',
        () async {
      // Arrange - Valid location and stats data
      const location = LocationData(
        latitude: 10.8231,
        longitude: 106.6297,
        city: 'Ho Chi Minh City',
      );

      final mockStatsData = StatsData(
        weeklyAverage: 1850.0,
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
          2,
          1,
          1,
          1,
          1,
          2,
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
        currentStreak: 5,
        todayProgress: 0.75,
        dailyGoalMl: 2000.0,
        age: 25,
        activityLevel: 'moderate',
        preferences: ['water', 'tea'],
      );

      final contextBuilder = DefaultContextBuilder();

      // Act
      final context = await contextBuilder.buildContext(
        location: location,
        statsData: mockStatsData,
      );

      // Assert - Should build complete context with all components
      expect(context, isA<InsightContext>());

      // Weather state should be populated
      expect(context.weatherState, isNotNull);
      expect(
          context.weatherState.condition,
          isIn([
            WeatherCondition.fresh,
            WeatherCondition.stale,
            WeatherCondition.unavailable,
          ]));

      // Stats pattern should be derived from input data
      expect(context.statsPattern.weeklyAverage, equals(1850.0));
      expect(context.statsPattern.dailyPatterns, hasLength(7));
      expect(context.statsPattern.hourlyPatterns, hasLength(24));
      expect(context.statsPattern.todayProgress, equals(0.75));

      // Time context should reflect current time
      expect(context.timeContext.hour, inInclusiveRange(0, 23));
      expect(context.timeContext.dayOfWeek, inInclusiveRange(1, 7));
      expect(context.timeContext.timeOfDay,
          isIn(['morning', 'afternoon', 'evening', 'night']));

      // User profile should be extracted from stats data
      expect(context.userProfile.dailyGoalMl, equals(2000.0));
      expect(context.userProfile.age, equals(25));
      expect(context.userProfile.activityLevel, equals('moderate'));
      expect(context.userProfile.preferences, equals(['water', 'tea']));
    });

    test('should handle missing location gracefully with fallback weather',
        () async {
      // Arrange - No location data available
      final mockStatsData = StatsData(
        weeklyAverage: 1600.0,
        dailyPatterns: [0.7, 0.8, 0.6, 0.7, 0.5, 0.6, 0.8],
        hourlyPatterns: [
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          1,
          2,
          1,
          1,
          0,
          1,
          1,
          0,
          1,
          1,
          1,
          2,
          1,
          0,
          0,
          0,
          0
        ],
        currentStreak: 3,
        todayProgress: 0.45,
        dailyGoalMl: 1800.0,
        age: 30,
        activityLevel: 'low',
        preferences: ['water'],
      );

      final contextBuilder = DefaultContextBuilder();

      // Act - No location provided
      final context = await contextBuilder.buildContext(
        location: null,
        statsData: mockStatsData,
      );

      // Assert - Should handle gracefully with fallback weather
      expect(context, isA<InsightContext>());

      // Weather should be unavailable when no location
      expect(
          context.weatherState.condition, equals(WeatherCondition.unavailable));
      expect(context.weatherState.temperatureCelsius, isNull);
      expect(context.weatherState.confidence, lessThanOrEqualTo(0.2));

      // Other components should still work
      expect(context.statsPattern.weeklyAverage, equals(1600.0));
      expect(context.statsPattern.todayProgress, equals(0.45));
      expect(context.userProfile.dailyGoalMl, equals(1800.0));
    });

    test('should handle weather API failure gracefully', () async {
      // Arrange - Invalid location that will cause weather API failure
      const invalidLocation = LocationData(
        latitude: 999.0, // Invalid coordinates
        longitude: 999.0,
        city: 'Invalid Location',
      );

      final mockStatsData = StatsData(
        weeklyAverage: 2000.0,
        dailyPatterns: [0.9, 0.8, 0.8, 0.7, 0.6, 0.8, 0.9],
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
          2,
          1,
          1,
          1,
          2,
          3,
          2,
          0,
          0,
          0,
          0
        ],
        currentStreak: 7,
        todayProgress: 0.85,
        dailyGoalMl: 2200.0,
        age: 28,
        activityLevel: 'high',
        preferences: ['water', 'sports_drink'],
      );

      final contextBuilder = DefaultContextBuilder();

      // Act
      final context = await contextBuilder.buildContext(
        location: invalidLocation,
        statsData: mockStatsData,
      );

      // Assert - Should handle API failure gracefully
      expect(context, isA<InsightContext>());

      // Weather should be unavailable due to API failure
      expect(
          context.weatherState.condition, equals(WeatherCondition.unavailable));
      expect(context.weatherState.confidence, lessThanOrEqualTo(0.2));

      // Stats and user data should still be processed correctly
      expect(context.statsPattern.weeklyAverage, equals(2000.0));
      expect(context.statsPattern.currentStreak, equals(7));
      expect(context.userProfile.activityLevel, equals('high'));
    });

    test('should normalize time context correctly for different times of day',
        () async {
      // Arrange
      const location = LocationData(
        latitude: 10.8231,
        longitude: 106.6297,
        city: 'Ho Chi Minh City',
      );

      final mockStatsData = StatsData(
        weeklyAverage: 1800.0,
        dailyPatterns: [0.8, 0.8, 0.7, 0.7, 0.6, 0.7, 0.8],
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
          1,
          1,
          1,
          1,
          1,
          2,
          1,
          0,
          0,
          0,
          0
        ],
        currentStreak: 4,
        todayProgress: 0.65,
        dailyGoalMl: 2000.0,
        age: 26,
        activityLevel: 'moderate',
        preferences: ['water'],
      );

      final contextBuilder = DefaultContextBuilder();

      // Act
      final context = await contextBuilder.buildContext(
        location: location,
        statsData: mockStatsData,
      );

      // Assert - Time context should be properly normalized
      expect(context.timeContext, isA<TimeContext>());

      // Validate time of day categorization logic
      final hour = context.timeContext.hour;
      final timeOfDay = context.timeContext.timeOfDay;

      if (hour >= 5 && hour < 12) {
        expect(timeOfDay, equals('morning'));
      } else if (hour >= 12 && hour < 17) {
        expect(timeOfDay, equals('afternoon'));
      } else if (hour >= 17 && hour < 21) {
        expect(timeOfDay, equals('evening'));
      } else {
        expect(timeOfDay, equals('night'));
      }

      // Day of week should be valid
      expect(context.timeContext.dayOfWeek, inInclusiveRange(1, 7));
    });

    test('should handle minimal stats data without crashing', () async {
      // Arrange - Minimal/empty stats data
      final minimalStatsData = StatsData(
        weeklyAverage: 0.0,
        dailyPatterns: [],
        hourlyPatterns: [],
        currentStreak: 0,
        todayProgress: 0.0,
        dailyGoalMl: 2000.0, // Only required field
        age: 20,
        activityLevel: '',
        preferences: [],
      );

      final contextBuilder = DefaultContextBuilder();

      // Act
      final context = await contextBuilder.buildContext(
        location: null,
        statsData: minimalStatsData,
      );

      // Assert - Should handle minimal data gracefully
      expect(context, isA<InsightContext>());

      // Stats pattern should handle empty data
      expect(context.statsPattern.weeklyAverage, equals(0.0));
      expect(context.statsPattern.dailyPatterns, isEmpty);
      expect(context.statsPattern.hourlyPatterns, isEmpty);
      expect(context.statsPattern.currentStreak, equals(0));

      // User profile should still be created
      expect(context.userProfile.dailyGoalMl, equals(2000.0));
      expect(context.userProfile.age, equals(20));
      expect(context.userProfile.activityLevel, isEmpty);
      expect(context.userProfile.preferences, isEmpty);
    });
  });
}
