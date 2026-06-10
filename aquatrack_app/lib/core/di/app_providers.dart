import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../network/api_client.dart';
import '../network/network_client.dart' as network;
import '../storage/secure_storage.dart';
import '../storage/storage_service.dart';

/// Core dependency injection providers for AquaTrack app
///
/// This file contains all the fundamental providers that other features depend on.
/// Organized by layer: Network → Storage → Core Services

// ═══════════════════════════════════════════════════════════════════════════════════
// NETWORK LAYER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Provides the low-level HTTP client (Dio wrapper)
final networkClientProvider = Provider<network.NetworkClient>((ref) {
  return network.NetworkClient(
    baseUrl: AppConfig.fullApiUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
    enableLogging: AppConfig.enableNetworkLogs,
  );
});

/// Provides the high-level API client for making authenticated requests
final apiClientProvider = Provider<ApiClient>((ref) {
  final networkClient = ref.watch(networkClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);

  return ApiClientImpl(
    networkClient: networkClient,
    tokenStorage: secureStorage,
  );
});

// ═══════════════════════════════════════════════════════════════════════════════════
// STORAGE LAYER PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Provides secure storage for sensitive data (tokens, credentials)
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorageImpl();
});

/// Provides general storage service for app data (preferences, cache)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageServiceImpl();
});

// ═══════════════════════════════════════════════════════════════════════════════════
// CORE SERVICE PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Application initialization provider
/// Call this to ensure all core services are properly initialized
final appInitializationProvider = FutureProvider<void>((ref) async {
  // Initialize storage services
  final secureStorage = ref.read(secureStorageProvider);
  final storageService = ref.read(storageServiceProvider);

  await Future.wait([
    secureStorage.initialize(),
    storageService.initialize(),
  ]);

  // Initialize network client
  final networkClient = ref.read(networkClientProvider);
  await networkClient.initialize();

  // Setup API client with initial configuration
  final apiClient = ref.read(apiClientProvider);
  await apiClient.initialize();
});

// ═══════════════════════════════════════════════════════════════════════════════════
// UTILITY PROVIDERS
// ═══════════════════════════════════════════════════════════════════════════════════

/// Provider for checking if the app is properly initialized
final isAppInitializedProvider = Provider<bool>((ref) {
  final initAsync = ref.watch(appInitializationProvider);
  return initAsync.when(
    data: (_) => true,
    loading: () => false,
    error: (_, __) => false,
  );
});
