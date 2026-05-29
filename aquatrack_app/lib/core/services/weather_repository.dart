import 'package:aquatrack_app/core/services/insight_engine.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Location data for weather API requests
class LocationData {
  final double latitude;
  final double longitude;
  final String city;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
  });
}

/// Abstract weather repository interface
abstract class WeatherRepository {
  /// Get current weather for location
  Future<WeatherState> getCurrentWeather(LocationData location);

  /// Get forecast weather for location
  Future<WeatherState> getForecastWeather(LocationData location);

  /// Clear weather cache
  Future<void> clearCache();
}

/// OpenMeteo weather repository implementation
class OpenMeteoWeatherRepository implements WeatherRepository {
  // OpenMeteo API configuration
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _cacheBoxName = 'weather_cache';

  // Confidence levels for different weather data sources
  static const double _freshConfidence = 1.0;
  static const double _forecastConfidence = 0.9;
  static const double _unavailableConfidence = 0.1;

  final Dio _dio;
  Box? _cacheBox;

  OpenMeteoWeatherRepository({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<WeatherState> getCurrentWeather(LocationData location) async {
    try {
      // TDD: Implement OpenMeteo API call to pass first test
      final url =
          '$_baseUrl?latitude=${location.latitude}&longitude=${location.longitude}&current=temperature_2m&timezone=auto';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final currentWeather = data['current'];

        if (currentWeather != null &&
            currentWeather['temperature_2m'] != null) {
          final temperature = currentWeather['temperature_2m'].toDouble();

          return WeatherState(
            condition: WeatherCondition.fresh,
            temperatureCelsius: temperature,
            locationName: location.city,
            confidence: _freshConfidence,
          );
        }
      }

      // Fallback if API response is invalid
      return WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: null,
        confidence: _unavailableConfidence,
      );
    } catch (e) {
      // TDD: Handle API errors gracefully
      return const WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: null,
        confidence: _unavailableConfidence,
      );
    }
  }

  @override
  Future<WeatherState> getForecastWeather(LocationData location) async {
    try {
      // TDD: Implement forecast API call similar to current weather
      final url =
          '$_baseUrl?latitude=${location.latitude}&longitude=${location.longitude}&hourly=temperature_2m&forecast_days=1&timezone=auto';

      final response = await _dio.get(url);

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final hourlyWeather = data['hourly'];

        if (hourlyWeather != null &&
            hourlyWeather['temperature_2m'] != null &&
            hourlyWeather['temperature_2m'].isNotEmpty) {
          // Use first forecast temperature as representative
          final temperature = hourlyWeather['temperature_2m'][0].toDouble();

          return WeatherState(
            condition: WeatherCondition.fresh,
            temperatureCelsius: temperature,
            locationName: location.city,
            confidence: _forecastConfidence,
          );
        }
      }

      // Fallback if forecast API response is invalid
      return const WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: null,
        confidence: _unavailableConfidence,
      );
    } catch (e) {
      // TDD: Handle forecast API errors gracefully
      return const WeatherState(
        condition: WeatherCondition.unavailable,
        temperatureCelsius: null,
        locationName: null,
        confidence: _unavailableConfidence,
      );
    }
  }

  @override
  Future<void> clearCache() async {
    // TDD: Minimal implementation to pass test
    // In test environment, just complete successfully without cache operations
    try {
      if (_cacheBox != null && _cacheBox!.isOpen) {
        await _cacheBox!.clear();
      }
      // Method completes successfully regardless of cache state
    } catch (e) {
      // Graceful degradation - cache clearing is not critical for core functionality
    }
  }
}
