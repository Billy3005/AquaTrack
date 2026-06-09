import '../network/api_client.dart';
import '../storage/storage_service.dart';
import '../utils/logger.dart';

/// Abstract base repository interface
///
/// Defines common patterns và behaviors cho tất cả repositories trong app.
/// Provides caching, offline support, và error handling strategies.
abstract class Repository {
  /// Repository initialization
  Future<void> initialize();

  /// Clear all cached data
  Future<void> clearCache();

  /// Refresh data from remote source
  Future<void> refresh();

  /// Check if data is fresh (within cache TTL)
  bool isFresh(DateTime? lastUpdated, Duration cacheTtl);

  /// Dispose repository resources
  void dispose();
}

/// Base repository implementation với common functionality
///
/// Provides concrete implementation of common repository patterns:
/// - API communication
/// - Local caching
/// - Error handling
/// - Offline support
abstract class BaseRepository implements Repository {
  static const String _tag = 'BaseRepository';

  final ApiClient apiClient;
  final StorageService storageService;

  /// Default cache TTL - có thể override trong concrete repositories
  Duration get defaultCacheTtl => const Duration(minutes: 5);

  /// Repository name for logging và cache keys
  String get repositoryName;

  BaseRepository({
    required this.apiClient,
    required this.storageService,
  });

  @override
  Future<void> initialize() async {
    AppLogger.debug('$repositoryName$_tag', 'Repository initialized');
  }

  @override
  Future<void> clearCache() async {
    try {
      // Clear cache keys related to this repository
      final keys = await storageService.getKeys();
      final repositoryKeys = keys.where((key) => key.startsWith(_cacheKeyPrefix));

      for (final key in repositoryKeys) {
        await storageService.remove(key);
      }

      AppLogger.debug('$repositoryName$_tag', 'Cache cleared');
    } catch (e) {
      AppLogger.error('$repositoryName$_tag', 'Error clearing cache', e);
    }
  }

  @override
  Future<void> refresh() async {
    await clearCache();
    AppLogger.debug('$repositoryName$_tag', 'Cache refreshed');
  }

  @override
  bool isFresh(DateTime? lastUpdated, Duration cacheTtl) {
    if (lastUpdated == null) return false;

    final age = DateTime.now().difference(lastUpdated);
    return age <= cacheTtl;
  }

  @override
  void dispose() {
    AppLogger.debug('$repositoryName$_tag', 'Repository disposed');
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // CACHE HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Generate cache key for this repository
  String _cacheKey(String key) => '$_cacheKeyPrefix$key';

  /// Cache key prefix for this repository
  String get _cacheKeyPrefix => '${repositoryName.toLowerCase()}_';

  /// Save data to cache với timestamp
  Future<void> saveToCache<T>({
    required String key,
    required T data,
    required String Function(T) serializer,
  }) async {
    try {
      final cacheKey = _cacheKey(key);
      final timestampKey = _cacheKey('${key}_timestamp');

      await Future.wait([
        storageService.setString(cacheKey, serializer(data)),
        storageService.setString(timestampKey, DateTime.now().toIso8601String()),
      ]);

      AppLogger.debug('$repositoryName$_tag', 'Data cached for key: $key');
    } catch (e) {
      AppLogger.error('$repositoryName$_tag', 'Error caching data for key: $key', e);
    }
  }

  /// Load data from cache nếu fresh
  Future<T?> loadFromCache<T>({
    required String key,
    required T Function(String) deserializer,
    Duration? cacheTtl,
  }) async {
    try {
      final cacheKey = _cacheKey(key);
      final timestampKey = _cacheKey('${key}_timestamp');

      final [cachedData, timestampStr] = await Future.wait([
        storageService.getString(cacheKey),
        storageService.getString(timestampKey),
      ]);

      if (cachedData == null || timestampStr == null) {
        AppLogger.debug('$repositoryName$_tag', 'No cached data for key: $key');
        return null;
      }

      final timestamp = DateTime.tryParse(timestampStr);
      final ttl = cacheTtl ?? defaultCacheTtl;

      if (!isFresh(timestamp, ttl)) {
        AppLogger.debug('$repositoryName$_tag', 'Cached data stale for key: $key');
        await Future.wait([
          storageService.remove(cacheKey),
          storageService.remove(timestampKey),
        ]);
        return null;
      }

      final data = deserializer(cachedData);
      AppLogger.debug('$repositoryName$_tag', 'Loaded fresh data from cache for key: $key');
      return data;
    } catch (e) {
      AppLogger.error('$repositoryName$_tag', 'Error loading cached data for key: $key', e);
      return null;
    }
  }

  /// Remove specific data from cache
  Future<void> removeFromCache(String key) async {
    try {
      final cacheKey = _cacheKey(key);
      final timestampKey = _cacheKey('${key}_timestamp');

      await Future.wait([
        storageService.remove(cacheKey),
        storageService.remove(timestampKey),
      ]);

      AppLogger.debug('$repositoryName$_tag', 'Removed cached data for key: $key');
    } catch (e) {
      AppLogger.error('$repositoryName$_tag', 'Error removing cached data for key: $key', e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════════════
  // API HELPER METHODS
  // ═══════════════════════════════════════════════════════════════════════════════════

  /// Execute API call với error handling và retry logic
  Future<T> executeApiCall<T>(
    Future<ApiResponse<T>> Function() apiCall, {
    String? operation,
    int maxRetries = 2,
    Duration retryDelay = const Duration(seconds: 1),
  }) async {
    Exception? lastException;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        AppLogger.debug(
          '$repositoryName$_tag',
          '${operation ?? 'API call'} attempt ${attempt + 1}/${maxRetries + 1}',
        );

        final response = await apiCall();

        if (response.isSuccess) {
          AppLogger.debug(
            '$repositoryName$_tag',
            '${operation ?? 'API call'} successful',
          );
          return response.data!;
        } else {
          throw ApiException(
            response.message,
            response.statusCode,
          );
        }
      } catch (e) {
        lastException = e is Exception ? e : Exception(e.toString());
        AppLogger.warning(
          '$repositoryName$_tag',
          '${operation ?? 'API call'} attempt ${attempt + 1} failed: $e',
        );

        if (attempt < maxRetries) {
          await Future.delayed(retryDelay);
        }
      }
    }

    AppLogger.error(
      '$repositoryName$_tag',
      '${operation ?? 'API call'} failed after ${maxRetries + 1} attempts',
      lastException,
    );
    throw lastException!;
  }

  /// Execute API call với caching support
  Future<T> executeApiCallWithCache<T>({
    required String cacheKey,
    required Future<ApiResponse<T>> Function() apiCall,
    required String Function(T) serializer,
    required T Function(String) deserializer,
    Duration? cacheTtl,
    bool forceRefresh = false,
    String? operation,
  }) async {
    // Try cache first nếu không force refresh
    if (!forceRefresh) {
      final cachedData = await loadFromCache<T>(
        key: cacheKey,
        deserializer: deserializer,
        cacheTtl: cacheTtl,
      );

      if (cachedData != null) {
        return cachedData;
      }
    }

    // Fetch from API
    final data = await executeApiCall(
      apiCall,
      operation: operation,
    );

    // Cache the result
    await saveToCache(
      key: cacheKey,
      data: data,
      serializer: serializer,
    );

    return data;
  }
}