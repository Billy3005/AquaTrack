import 'dart:async';
import 'dart:math';

import '../utils/logger.dart';
import 'sync_models.dart';
import 'sync_database.dart';

/// Manager for handling sync retries with exponential backoff and circuit breaker patterns
class SyncRetryManager {
  static const String _tag = 'SyncRetryManager';

  final SyncDatabase _syncDatabase;
  final Map<String, Timer> _activeRetryTimers = {};
  final Map<SyncDataType, CircuitBreakerState> _circuitBreakers = {};

  // Retry configuration
  static const int _maxRetries = 5;
  static const Duration _baseRetryDelay = Duration(seconds: 2);
  static const Duration _maxRetryDelay = Duration(minutes: 10);
  static const double _jitterFactor = 0.1; // 10% jitter
  static const Duration _circuitBreakerTimeout = Duration(minutes: 5);
  static const int _circuitBreakerFailureThreshold = 3;

  SyncRetryManager({required SyncDatabase syncDatabase})
      : _syncDatabase = syncDatabase;

  /// Calculate exponential backoff delay with jitter
  Duration calculateRetryDelay(int retryCount) {
    // Exponential backoff: base * 2^retry_count
    final exponentialDelay =
        _baseRetryDelay.inMilliseconds * pow(2, retryCount).toInt();
    final cappedDelay = min(exponentialDelay, _maxRetryDelay.inMilliseconds);

    // Add jitter to prevent thundering herd
    final jitter = cappedDelay * _jitterFactor * (Random().nextDouble() - 0.5);
    final finalDelay = cappedDelay + jitter.toInt();

    return Duration(
      milliseconds: max(finalDelay.toInt(), _baseRetryDelay.inMilliseconds),
    );
  }

  /// Check if a sync change should be retried
  bool shouldRetry(SyncMetadata syncChange, Exception error) {
    // Don't retry if max retries exceeded
    if (syncChange.retryCount >= _maxRetries) {
      AppLogger.info(_tag, 'Max retries exceeded for ${syncChange.id}');
      return false;
    }

    // Check circuit breaker state
    final circuitBreaker = _getCircuitBreakerState(syncChange.dataType);
    if (circuitBreaker.state == CircuitState.open) {
      AppLogger.warning(
        _tag,
        'Circuit breaker open for ${syncChange.dataType}, skipping retry',
      );
      return false;
    }

    // Check if error is retryable
    if (!_isRetryableError(error)) {
      AppLogger.info(_tag, 'Non-retryable error for ${syncChange.id}: $error');
      return false;
    }

    return true;
  }

  /// Schedule a retry for a failed sync change
  Future<void> scheduleRetry({
    required SyncMetadata syncChange,
    required Exception error,
    required Future<void> Function() retryFunction,
  }) async {
    if (!shouldRetry(syncChange, error)) {
      await _markAsFailedPermanently(syncChange, error);
      return;
    }

    final retryDelay = calculateRetryDelay(syncChange.retryCount);
    final retryTimerId = '${syncChange.dataType.name}_${syncChange.id}';

    AppLogger.info(
      _tag,
      'Scheduling retry for ${syncChange.id} in ${retryDelay.inSeconds}s (attempt ${syncChange.retryCount + 1})',
    );

    // Cancel existing retry timer if any
    _activeRetryTimers[retryTimerId]?.cancel();

    // Update retry metadata in database
    await _syncDatabase.updateSyncMetadataStatus(
      syncChange.id,
      SyncStatus.idle, // Reset to idle for retry
      error: error.toString(),
    );

    // Schedule retry
    _activeRetryTimers[retryTimerId] = Timer(retryDelay, () async {
      _activeRetryTimers.remove(retryTimerId);

      try {
        AppLogger.info(
          _tag,
          'Executing retry for ${syncChange.id} (attempt ${syncChange.retryCount + 1})',
        );

        // Update circuit breaker
        await _updateCircuitBreakerOnAttempt(syncChange.dataType);

        // Execute retry function
        await retryFunction();

        // Success - reset circuit breaker
        await _updateCircuitBreakerOnSuccess(syncChange.dataType);

        AppLogger.info(_tag, 'Retry successful for ${syncChange.id}');
      } catch (e) {
        AppLogger.error(_tag, 'Retry failed for ${syncChange.id}', e);

        // Update circuit breaker on failure
        await _updateCircuitBreakerOnFailure(syncChange.dataType);

        // Get updated sync metadata and schedule another retry if appropriate
        final updatedMetadata = await _getUpdatedSyncMetadata(syncChange.id);
        if (updatedMetadata != null) {
          await scheduleRetry(
            syncChange: updatedMetadata,
            error: e is Exception ? e : Exception(e.toString()),
            retryFunction: retryFunction,
          );
        }
      }
    });
  }

  /// Cancel all active retry timers
  void cancelAllRetries() {
    AppLogger.info(
      _tag,
      'Cancelling ${_activeRetryTimers.length} active retry timers',
    );

    for (final timer in _activeRetryTimers.values) {
      timer.cancel();
    }
    _activeRetryTimers.clear();
  }

  /// Cancel retry for specific sync change
  void cancelRetry(String syncChangeId, SyncDataType dataType) {
    final retryTimerId = '${dataType.name}_$syncChangeId';
    final timer = _activeRetryTimers.remove(retryTimerId);

    if (timer != null) {
      timer.cancel();
      AppLogger.debug(_tag, 'Cancelled retry for $syncChangeId');
    }
  }

  /// Get current retry statistics
  Future<Map<String, dynamic>> getRetryStatistics() async {
    final stats = <String, dynamic>{
      'active_retries': _activeRetryTimers.length,
      'circuit_breakers': {},
      'retry_queue_by_type': {},
    };

    // Circuit breaker states
    for (final entry in _circuitBreakers.entries) {
      stats['circuit_breakers'][entry.key.name] = {
        'state': entry.value.state.name,
        'failure_count': entry.value.failureCount,
        'last_failure_time': entry.value.lastFailureTime?.toIso8601String(),
        'next_attempt_time': entry.value.nextAttemptTime?.toIso8601String(),
      };
    }

    // Retry queue by data type
    for (final dataType in SyncDataType.values) {
      final pendingRetries = await _syncDatabase.getPendingSyncMetadata(
        dataType: dataType,
      );
      final retriesCount = pendingRetries.where((m) => m.retryCount > 0).length;
      stats['retry_queue_by_type'][dataType.name] = retriesCount;
    }

    return stats;
  }

  /// Check if error is retryable (network errors, timeouts, server errors)
  bool _isRetryableError(Exception error) {
    final errorMessage = error.toString().toLowerCase();

    // Retryable error patterns
    final retryablePatterns = [
      'network',
      'timeout',
      'connection',
      'socket',
      'http 5', // 5xx server errors
      'http 429', // Too many requests
      'http 502', // Bad gateway
      'http 503', // Service unavailable
      'http 504', // Gateway timeout
      'dio error', // Dio network errors
      'no internet',
      'offline',
    ];

    // Non-retryable error patterns
    final nonRetryablePatterns = [
      'http 4', // 4xx client errors (except 429)
      'unauthorized',
      'forbidden',
      'not found',
      'bad request',
      'validation',
      'invalid',
    ];

    // Check non-retryable first
    for (final pattern in nonRetryablePatterns) {
      if (errorMessage.contains(pattern) && !errorMessage.contains('429')) {
        return false;
      }
    }

    // Check retryable patterns
    for (final pattern in retryablePatterns) {
      if (errorMessage.contains(pattern)) {
        return true;
      }
    }

    // Default to retryable for unknown errors (conservative approach)
    return true;
  }

  /// Get circuit breaker state for data type
  CircuitBreakerState _getCircuitBreakerState(SyncDataType dataType) {
    return _circuitBreakers[dataType] ?? CircuitBreakerState.closed();
  }

  /// Update circuit breaker on sync attempt
  Future<void> _updateCircuitBreakerOnAttempt(SyncDataType dataType) async {
    final state = _getCircuitBreakerState(dataType);

    if (state.state == CircuitState.halfOpen) {
      // Already attempting in half-open state
      return;
    }

    if (state.state == CircuitState.open) {
      // Check if timeout has passed
      if (state.nextAttemptTime != null &&
          DateTime.now().isAfter(state.nextAttemptTime!)) {
        // Transition to half-open
        _circuitBreakers[dataType] = CircuitBreakerState.halfOpen(
          failureCount: state.failureCount,
          lastFailureTime: state.lastFailureTime,
        );
        AppLogger.info(
          _tag,
          'Circuit breaker for $dataType transitioned to half-open',
        );
      }
    }
  }

  /// Update circuit breaker on successful sync
  Future<void> _updateCircuitBreakerOnSuccess(SyncDataType dataType) async {
    final state = _getCircuitBreakerState(dataType);

    if (state.state != CircuitState.closed) {
      // Reset to closed state
      _circuitBreakers[dataType] = CircuitBreakerState.closed();
      AppLogger.info(
        _tag,
        'Circuit breaker for $dataType reset to closed after success',
      );
    }
  }

  /// Update circuit breaker on failed sync
  Future<void> _updateCircuitBreakerOnFailure(SyncDataType dataType) async {
    final state = _getCircuitBreakerState(dataType);
    final newFailureCount = state.failureCount + 1;
    final now = DateTime.now();

    if (newFailureCount >= _circuitBreakerFailureThreshold) {
      // Open the circuit breaker
      _circuitBreakers[dataType] = CircuitBreakerState.open(
        failureCount: newFailureCount,
        lastFailureTime: now,
        nextAttemptTime: now.add(_circuitBreakerTimeout),
      );
      AppLogger.warning(
        _tag,
        'Circuit breaker for $dataType opened after $newFailureCount failures',
      );
    } else {
      // Increment failure count but keep closed
      _circuitBreakers[dataType] = CircuitBreakerState.closed(
        failureCount: newFailureCount,
        lastFailureTime: now,
      );
    }
  }

  /// Mark sync change as permanently failed
  Future<void> _markAsFailedPermanently(
    SyncMetadata syncChange,
    Exception error,
  ) async {
    AppLogger.info(
      _tag,
      'Marking ${syncChange.id} as permanently failed: $error',
    );

    await _syncDatabase.updateSyncMetadataStatus(
      syncChange.id,
      SyncStatus.failed,
      error: 'Max retries exceeded: ${error.toString()}',
    );

    // Record failure in sync stats
    await _syncDatabase.recordSyncStats(
      dataType: syncChange.dataType,
      operation: syncChange.operation,
      status: SyncStatus.failed,
      duration: Duration.zero,
      error: error.toString(),
    );
  }

  /// Get updated sync metadata from database
  Future<SyncMetadata?> _getUpdatedSyncMetadata(String syncChangeId) async {
    final pendingChanges = await _syncDatabase.getPendingSyncMetadata(
      limit: 1000,
    );
    return pendingChanges.where((m) => m.id == syncChangeId).firstOrNull;
  }

  /// Get active retry count by data type
  int getActiveRetryCount(SyncDataType dataType) {
    return _activeRetryTimers.keys
        .where((key) => key.startsWith('${dataType.name}_'))
        .length;
  }

  /// Check if circuit breaker is open for data type
  bool isCircuitBreakerOpen(SyncDataType dataType) {
    return _getCircuitBreakerState(dataType).state == CircuitState.open;
  }

  /// Force reset circuit breaker for data type
  void resetCircuitBreaker(SyncDataType dataType) {
    _circuitBreakers[dataType] = CircuitBreakerState.closed();
    AppLogger.info(_tag, 'Circuit breaker for $dataType manually reset');
  }

  /// Dispose resources
  void dispose() {
    cancelAllRetries();
    _circuitBreakers.clear();
    AppLogger.info(_tag, 'SyncRetryManager disposed');
  }
}

/// Circuit breaker state for preventing cascade failures
class CircuitBreakerState {
  final CircuitState state;
  final int failureCount;
  final DateTime? lastFailureTime;
  final DateTime? nextAttemptTime;

  const CircuitBreakerState._({
    required this.state,
    this.failureCount = 0,
    this.lastFailureTime,
    this.nextAttemptTime,
  });

  factory CircuitBreakerState.closed({
    int failureCount = 0,
    DateTime? lastFailureTime,
  }) {
    return CircuitBreakerState._(
      state: CircuitState.closed,
      failureCount: failureCount,
      lastFailureTime: lastFailureTime,
    );
  }

  factory CircuitBreakerState.open({
    required int failureCount,
    required DateTime lastFailureTime,
    required DateTime nextAttemptTime,
  }) {
    return CircuitBreakerState._(
      state: CircuitState.open,
      failureCount: failureCount,
      lastFailureTime: lastFailureTime,
      nextAttemptTime: nextAttemptTime,
    );
  }

  factory CircuitBreakerState.halfOpen({
    required int failureCount,
    DateTime? lastFailureTime,
  }) {
    return CircuitBreakerState._(
      state: CircuitState.halfOpen,
      failureCount: failureCount,
      lastFailureTime: lastFailureTime,
    );
  }
}

/// Circuit breaker states
enum CircuitState {
  closed, // Normal operation
  open, // Blocking all requests
  halfOpen, // Testing if service is back
}

/// Extension for null safety
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
