import 'package:geolocator/geolocator.dart';
import 'package:aquatrack_app/core/services/weather_repository.dart';

/// Abstract location service interface
abstract class LocationService {
  /// Get current location from GPS
  Future<LocationData?> getCurrentLocation();

  /// Check if location permission is granted
  bool hasPermission();

  /// Request location permission from user
  Future<bool> requestPermission();

  /// Get fallback location when GPS fails
  LocationData? getFallbackLocation();
}

/// Geolocator implementation of location service
class GeolocatorLocationService implements LocationService {
  // Location accuracy configuration
  static const LocationAccuracy _defaultAccuracy = LocationAccuracy.high;

  // Default placeholder city name (reverse geocoding would be needed for actual city)
  static const String _defaultCityName = 'Current Location';

  // Test simulation flags
  final bool simulatePermissionDenied;
  final bool simulateServiceDisabled;
  final LocationData? fallbackLocation;

  // Permission cache for faster subsequent checks
  LocationPermission? _lastPermission;

  GeolocatorLocationService({
    this.simulatePermissionDenied = false,
    this.simulateServiceDisabled = false,
    this.fallbackLocation,
  });

  @override
  Future<LocationData?> getCurrentLocation() async {
    try {
      // TDD: Handle test simulation flags first
      if (simulatePermissionDenied) {
        return null;
      }

      if (simulateServiceDisabled) {
        return null;
      }

      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return null;
      }

      // Check permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _lastPermission = permission;
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _lastPermission = permission;
        return null;
      }

      // Cache permission state
      _lastPermission = permission;

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: _defaultAccuracy,
      );

      // Convert to LocationData format
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        city: _defaultCityName,
      );
    } catch (e) {
      // Handle any errors gracefully
      return null;
    }
  }

  @override
  bool hasPermission() {
    // TDD: Simple permission check based on cached permission
    if (_lastPermission == null) {
      return false; // Unknown permission state
    }

    return _isPermissionGranted(_lastPermission!);
  }

  @override
  Future<bool> requestPermission() async {
    try {
      // TDD: Handle simulation flags
      if (simulatePermissionDenied) {
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      // If already granted, return true
      if (_isPermissionGranted(permission)) {
        _lastPermission = permission;
        return true;
      }

      // If denied forever, can't request again
      if (permission == LocationPermission.deniedForever) {
        _lastPermission = permission;
        return false;
      }

      // Request permission
      permission = await Geolocator.requestPermission();
      _lastPermission = permission;

      return _isPermissionGranted(permission);
    } catch (e) {
      return false;
    }
  }

  @override
  LocationData? getFallbackLocation() {
    // TDD: Return configured fallback location
    return fallbackLocation;
  }

  /// Check if permission is granted (helper method)
  bool _isPermissionGranted(LocationPermission permission) {
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }
}
