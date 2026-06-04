import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/insight_engine.dart';
import '../services/location_service.dart';
import '../services/weather_repository.dart';

/// Fallback location: Ho Chi Minh City center. Used when the user denies
/// location permission, location services are off, or GPS fails.
const LocationData kDefaultLocation = LocationData(
  latitude: 10.8231,
  longitude: 106.6297,
  city: 'TP.HCM',
);

/// Current weather for the home screen. Resolves the device location (GPS via
/// [GeolocatorLocationService], HCMC fallback) then queries Open-Meteo for the
/// real temperature. Never throws — returns an `unavailable` [WeatherState] on
/// failure so the UI can degrade gracefully.
final homeWeatherProvider = FutureProvider<WeatherState>((ref) async {
  final locationService =
      GeolocatorLocationService(fallbackLocation: kDefaultLocation);
  final location =
      await locationService.getCurrentLocation() ?? kDefaultLocation;
  return OpenMeteoWeatherRepository().getCurrentWeather(location);
});
