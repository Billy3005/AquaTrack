import 'package:aquatrack_app/core/services/insight_engine.dart';
import 'package:aquatrack_app/core/services/weather_repository.dart';
import 'package:aquatrack_app/core/services/location_service.dart';

/// Input data from app for context building
class StatsData {
  final double weeklyAverage;
  final List<double> dailyPatterns;
  final List<int> hourlyPatterns;
  final int currentStreak;
  final double todayProgress;
  final double dailyGoalMl;
  final int age;
  final String activityLevel;
  final List<String> preferences;

  const StatsData({
    required this.weeklyAverage,
    required this.dailyPatterns,
    required this.hourlyPatterns,
    required this.currentStreak,
    required this.todayProgress,
    required this.dailyGoalMl,
    required this.age,
    required this.activityLevel,
    required this.preferences,
  });
}

/// Abstract context builder interface
abstract class ContextBuilder {
  /// Build normalized InsightContext from raw inputs
  Future<InsightContext> buildContext({
    required LocationData? location,
    required StatsData statsData,
  });
}

/// Default implementation of context builder
class DefaultContextBuilder implements ContextBuilder {
  // Time of day boundaries
  static const int _morningStart = 5;
  static const int _morningEnd = 12;
  static const int _afternoonStart = 12;
  static const int _afternoonEnd = 17;
  static const int _eveningStart = 17;
  static const int _eveningEnd = 21;

  // Fallback confidence levels
  static const double _unavailableConfidence = 0.1;
  static const double _fallbackConfidence = 0.0;

  final WeatherRepository _weatherRepository;

  DefaultContextBuilder({WeatherRepository? weatherRepository})
      : _weatherRepository = weatherRepository ?? OpenMeteoWeatherRepository();

  @override
  Future<InsightContext> buildContext({
    required LocationData? location,
    required StatsData statsData,
  }) async {
    try {
      // TDD: Build WeatherState from location
      final weatherState = await _buildWeatherState(location);

      // TDD: Convert StatsData to StatsPattern
      final statsPattern = _buildStatsPattern(statsData);

      // TDD: Build current TimeContext
      final timeContext = _buildTimeContext();

      // TDD: Extract UserProfile from StatsData
      final userProfile = _buildUserProfile(statsData);

      return InsightContext(
        weatherState: weatherState,
        statsPattern: statsPattern,
        timeContext: timeContext,
        userProfile: userProfile,
      );
    } catch (e) {
      // Handle any errors gracefully with fallback context
      return _buildFallbackContext(statsData);
    }
  }

  /// Build weather state from location data
  Future<WeatherState> _buildWeatherState(LocationData? location) async {
    if (location == null) {
      // No location available - return unavailable weather state
      return WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: null,
        confidence: _unavailableConfidence,
      );
    }

    try {
      // Get current weather for location
      final weatherState = await _weatherRepository.getCurrentWeather(location);
      return weatherState;
    } catch (e) {
      // Weather API failed - return unavailable state
      return WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: location.city,
        confidence: _unavailableConfidence,
      );
    }
  }

  /// Convert StatsData to StatsPattern
  StatsPattern _buildStatsPattern(StatsData statsData) {
    return StatsPattern(
      weeklyAverage: statsData.weeklyAverage,
      dailyPatterns: statsData.dailyPatterns,
      hourlyPatterns: statsData.hourlyPatterns,
      currentStreak: statsData.currentStreak,
      todayProgress: statsData.todayProgress,
    );
  }

  /// Build current time context
  TimeContext _buildTimeContext() {
    final now = DateTime.now();
    final hour = now.hour;
    final dayOfWeek = now.weekday; // 1-7 (Monday = 1)

    // Determine time of day using constants
    String timeOfDay;
    if (hour >= _morningStart && hour < _morningEnd) {
      timeOfDay = 'morning';
    } else if (hour >= _afternoonStart && hour < _afternoonEnd) {
      timeOfDay = 'afternoon';
    } else if (hour >= _eveningStart && hour < _eveningEnd) {
      timeOfDay = 'evening';
    } else {
      timeOfDay = 'night';
    }

    return TimeContext(
      hour: hour,
      dayOfWeek: dayOfWeek,
      timeOfDay: timeOfDay,
    );
  }

  /// Extract user profile from stats data
  UserProfile _buildUserProfile(StatsData statsData) {
    return UserProfile(
      dailyGoalMl: statsData.dailyGoalMl,
      age: statsData.age,
      activityLevel: statsData.activityLevel,
      preferences: statsData.preferences,
    );
  }

  /// Build fallback context when errors occur
  InsightContext _buildFallbackContext(StatsData statsData) {
    return InsightContext(
      weatherState: WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: null,
        confidence: _fallbackConfidence,
      ),
      statsPattern: _buildStatsPattern(statsData),
      timeContext: _buildTimeContext(),
      userProfile: _buildUserProfile(statsData),
    );
  }
}
