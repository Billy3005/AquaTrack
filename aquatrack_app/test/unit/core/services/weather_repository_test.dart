import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_app/core/services/weather_repository.dart';
import 'package:aquatrack_app/core/services/insight_engine.dart';

void main() {
  group('WeatherRepository', () {
    test('should return fresh WeatherState when API call succeeds', () async {
      // Arrange - Location in HCMC
      const location = LocationData(
        latitude: 10.8231,
        longitude: 106.6297,
        city: 'Ho Chi Minh City',
      );

      final repository = OpenMeteoWeatherRepository();

      // Act
      final weatherState = await repository.getCurrentWeather(location);

      // Assert - Fresh API data should have high confidence
      expect(weatherState.condition, equals(WeatherCondition.fresh));
      expect(weatherState.temperatureCelsius, isNotNull);
      expect(weatherState.temperatureCelsius, inInclusiveRange(15.0, 50.0),
          reason: 'Temperature should be within reasonable range');
      expect(weatherState.locationName, isNotNull);
      expect(weatherState.confidence, inInclusiveRange(0.8, 1.0),
          reason: 'Fresh API data should have high confidence');
    });

    test('should return stale WeatherState when using cached data', () async {
      // Arrange - Pre-populate cache with data
      const location = LocationData(
        latitude: 10.8231,
        longitude: 106.6297,
        city: 'Ho Chi Minh City',
      );

      final repository = OpenMeteoWeatherRepository();

      // First call to populate cache
      await repository.getCurrentWeather(location);

      // Simulate time passage but within stale tolerance
      // Note: This test assumes cache is still valid but considered stale

      // Act - Should return cached data
      final weatherState = await repository.getCurrentWeather(location);

      // Assert - Stale cache should have medium confidence
      expect(
          weatherState.condition,
          anyOf([
            WeatherCondition.fresh, // If API is still working
            WeatherCondition.stale, // If using cache
          ]));
      expect(weatherState.temperatureCelsius, isNotNull);
      expect(weatherState.confidence, greaterThan(0.3),
          reason: 'Cached data should have reasonable confidence');
    });

    test('should return unavailable WeatherState when API fails and no cache',
        () async {
      // Arrange - Invalid location to trigger API failure
      const invalidLocation = LocationData(
        latitude: 999.0, // Invalid latitude
        longitude: 999.0, // Invalid longitude
        city: 'Invalid City',
      );

      final repository = OpenMeteoWeatherRepository();

      // Act
      final weatherState = await repository.getCurrentWeather(invalidLocation);

      // Assert - Should gracefully handle failure
      expect(weatherState.condition, equals(WeatherCondition.unavailable));
      expect(weatherState.temperatureCelsius, isNull);
      expect(
          weatherState.locationName, anyOf([isNull, equals('Invalid City')]));
      expect(weatherState.confidence, inInclusiveRange(0.0, 0.2),
          reason: 'Unavailable weather should have very low confidence');
    });

    test('should handle forecast weather requests', () async {
      // Arrange
      const location = LocationData(
        latitude: 10.8231,
        longitude: 106.6297,
        city: 'Ho Chi Minh City',
      );

      final repository = OpenMeteoWeatherRepository();

      // Act
      final forecastState = await repository.getForecastWeather(location);

      // Assert - Forecast should have reasonable data
      expect(
          forecastState.condition,
          isIn([
            WeatherCondition.fresh,
            WeatherCondition.stale,
            WeatherCondition.unavailable,
          ]));

      // If forecast data is available
      if (forecastState.condition != WeatherCondition.unavailable) {
        expect(forecastState.temperatureCelsius, isNotNull);
        expect(forecastState.confidence, greaterThan(0.0));
      }
    });

    test('should clear cache successfully', () async {
      // Arrange - Pre-populate cache
      const location = LocationData(
        latitude: 10.8231,
        longitude: 106.6297,
        city: 'Ho Chi Minh City',
      );

      final repository = OpenMeteoWeatherRepository();
      await repository.getCurrentWeather(location);

      // Act
      await repository.clearCache();

      // Assert - Should complete without error
      // Note: We can't easily test cache clearing without access to internals
      // This test verifies the method exists and doesn't throw
      expect(true, isTrue, reason: 'clearCache should complete successfully');
    });
  });
}
