import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  Timer? _connectivityTimer;

  /// Initialize connectivity monitoring
  void initialize() {
    _startMonitoring();
    _checkConnectivity(); // Initial check
  }

  /// Start periodic connectivity monitoring
  void _startMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _checkConnectivity(),
    );
  }

  /// Check internet connectivity
  Future<void> _checkConnectivity() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      final isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      _updateConnectionStatus(isConnected);
    } catch (e) {
      _updateConnectionStatus(false);
    }
  }

  /// Update connection status and notify listeners
  void _updateConnectionStatus(bool connected) {
    if (_isConnected != connected) {
      _isConnected = connected;
      _connectionController.add(_isConnected);
      debugPrint('📶 Connectivity: ${connected ? 'Online' : 'Offline'}');
    }
  }

  /// Check connectivity on demand
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isConnected;
  }

  /// Force connectivity check for API calls
  Future<bool> ensureConnectivity() async {
    if (!_isConnected) {
      await _checkConnectivity();
    }
    return _isConnected;
  }

  /// Dispose resources
  void dispose() {
    _connectivityTimer?.cancel();
    _connectionController.close();
  }
}

/// Mixin for widgets that need connectivity awareness
mixin ConnectivityAware {
  late StreamSubscription<bool> _connectivitySubscription;

  void initializeConnectivity({
    required void Function(bool isConnected) onConnectivityChanged,
  }) {
    _connectivitySubscription = ConnectivityService().connectionStream.listen(
          onConnectivityChanged,
        );
  }

  void disposeConnectivity() {
    _connectivitySubscription.cancel();
  }
}
