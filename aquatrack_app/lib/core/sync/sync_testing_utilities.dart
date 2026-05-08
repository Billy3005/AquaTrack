import 'dart:async';
import 'dart:math';

import '../utils/logger.dart';
import 'sync_service.dart';
import 'sync_models.dart';
import 'sync_database.dart';
import 'sync_retry_manager.dart';
import 'conflict_resolver.dart';

/// Testing utilities for offline/online sync behavior verification
class SyncTestingUtilities {
  static const String _tag = 'SyncTestingUtilities';

  final SyncService _syncService; // TODO: Use for integration testing
  final SyncDatabase _syncDatabase;
  final SyncRetryManager _retryManager;
  final ConflictResolver _conflictResolver;

  SyncTestingUtilities({
    required SyncService syncService,
    required SyncDatabase syncDatabase,
    required SyncRetryManager retryManager,
    required ConflictResolver conflictResolver,
  }) : _syncService = syncService,
       _syncDatabase = syncDatabase,
       _retryManager = retryManager,
       _conflictResolver = conflictResolver;

  /// Simulate offline/online transition testing
  Future<OfflineTestResult> simulateOfflineOnlineTransition({
    Duration offlineDuration = const Duration(minutes: 2),
    int messagesWhileOffline = 10,
    int dataChangesWhileOffline = 5,
  }) async {
    AppLogger.info(_tag, 'Starting offline/online transition simulation');

    final testResult = OfflineTestResult(startTime: DateTime.now());
    final stopwatch = Stopwatch()..start();

    try {
      // Phase 1: Generate data while "online"
      AppLogger.info(_tag, 'Phase 1: Generating baseline data while online');
      final baselineChanges = await _generateTestData(count: 5);
      testResult.baselineDataCount = baselineChanges.length;

      // Simulate initial sync
      await _simulateSync(baselineChanges, success: true);

      // Phase 2: Go "offline" and generate more data
      AppLogger.info(
        _tag,
        'Phase 2: Simulating offline state for ${offlineDuration.inMinutes} minutes',
      );

      final offlineChanges = await _generateTestDataOffline(
        messageCount: messagesWhileOffline,
        dataCount: dataChangesWhileOffline,
      );
      testResult.offlineDataCount = offlineChanges.length;

      // Simulate failed sync attempts while offline
      await _simulateOfflineSync(offlineChanges);

      // Wait for offline duration
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Simulate offline time

      // Phase 3: Come back "online" and test sync
      AppLogger.info(_tag, 'Phase 3: Simulating return to online state');

      // Test sync recovery
      final syncResult = await _simulateOnlineRecovery(offlineChanges);
      testResult.syncSuccessCount = syncResult.successCount;
      testResult.syncFailureCount = syncResult.failureCount;
      testResult.conflictCount = syncResult.conflictCount;

      // Phase 4: Test conflict resolution
      AppLogger.info(_tag, 'Phase 4: Testing conflict resolution');
      final conflictResolution = await _testConflictResolution();
      testResult.conflictResolutionSuccessCount =
          conflictResolution.resolvedCount;

      // Phase 5: Verify data integrity
      AppLogger.info(_tag, 'Phase 5: Verifying data integrity');
      final integrityResult = await _verifyDataIntegrity();
      testResult.dataIntegrityPassed = integrityResult.passed;
      testResult.integrityIssues.addAll(integrityResult.issues);

      testResult.endTime = DateTime.now();
      testResult.totalDuration = stopwatch.elapsed;
      testResult.success = true;

      AppLogger.info(_tag, 'Offline/online simulation completed successfully');
    } catch (e) {
      testResult.success = false;
      testResult.error = e.toString();
      AppLogger.error(_tag, 'Offline/online simulation failed', e);
    } finally {
      stopwatch.stop();
    }

    return testResult;
  }

  /// Test sync performance under load
  Future<SyncPerformanceResult> testSyncPerformance({
    int totalChanges = 100,
    int concurrentOperations = 5,
    List<SyncDataType> dataTypes = const [
      SyncDataType.intakeLog,
      SyncDataType.conversation,
      SyncDataType.achievement,
    ],
  }) async {
    AppLogger.info(
      _tag,
      'Starting sync performance test with $totalChanges changes',
    );

    final result = SyncPerformanceResult(startTime: DateTime.now());
    final stopwatch = Stopwatch()..start();

    try {
      // Generate test data for each type
      final testChanges = <SyncMetadata>[];
      for (final dataType in dataTypes) {
        final changes = await _generateTestDataByType(
          dataType,
          totalChanges ~/ dataTypes.length,
        );
        testChanges.addAll(changes);
      }

      // Execute sync operations with concurrency
      final futures = <Future>[];
      final changeChunks = _chunkList(testChanges, concurrentOperations);

      for (final chunk in changeChunks) {
        futures.add(_processSyncChunk(chunk));
      }

      final chunkResults = await Future.wait(futures);

      // Aggregate results
      for (final chunkResult in chunkResults) {
        result.totalOperations += (chunkResult.operations as num).toInt();
        result.successfulOperations += (chunkResult.successes as num).toInt();
        result.failedOperations += (chunkResult.failures as num).toInt();
        result.averageLatency += chunkResult.avgLatency;
      }

      result.averageLatency /= chunkResults.length.toDouble();
      result.totalDuration = stopwatch.elapsed;
      result.throughputOpsPerSecond =
          result.totalOperations.toDouble() /
          result.totalDuration.inSeconds.toDouble();
      result.successRate = result.totalOperations > 0
          ? (result.successfulOperations / result.totalOperations) * 100
          : 0.0;

      AppLogger.info(
        _tag,
        'Performance test completed: ${result.throughputOpsPerSecond.toStringAsFixed(2)} ops/sec',
      );
    } catch (e) {
      result.error = e.toString();
      AppLogger.error(_tag, 'Performance test failed', e);
    } finally {
      stopwatch.stop();
    }

    return result;
  }

  /// Test circuit breaker behavior
  Future<CircuitBreakerTestResult> testCircuitBreakerBehavior({
    SyncDataType dataType = SyncDataType.intakeLog,
    int failureCount = 5,
  }) async {
    AppLogger.info(_tag, 'Testing circuit breaker for $dataType');

    final result = CircuitBreakerTestResult(
      dataType: dataType,
      startTime: DateTime.now(),
    );

    try {
      // Generate failures to trigger circuit breaker
      for (int i = 0; i < failureCount; i++) {
        final testChange = await _generateSingleTestChange(dataType);
        await _simulateSync(
          [testChange],
          success: false,
          error: 'Test failure $i',
        );
      }

      // Check if circuit breaker opened
      result.circuitBreakerTriggered = _retryManager.isCircuitBreakerOpen(
        dataType,
      );

      if (result.circuitBreakerTriggered) {
        AppLogger.info(
          _tag,
          'Circuit breaker opened after $failureCount failures',
        );

        // Test that requests are blocked
        final blockedChange = await _generateSingleTestChange(dataType);
        final shouldBlock = !_retryManager.shouldRetry(
          blockedChange,
          Exception('Test error'),
        );
        result.requestsBlockedWhenOpen = shouldBlock;

        // Reset and test recovery
        _retryManager.resetCircuitBreaker(dataType);

        // Test successful request after reset
        final recoveryChange = await _generateSingleTestChange(dataType);
        await _simulateSync([recoveryChange], success: true);

        result.recoveryAfterReset = !_retryManager.isCircuitBreakerOpen(
          dataType,
        );
      }

      result.success = true;
      AppLogger.info(_tag, 'Circuit breaker test completed successfully');
    } catch (e) {
      result.error = e.toString();
      AppLogger.error(_tag, 'Circuit breaker test failed', e);
    }

    return result;
  }

  /// Generate test data for sync operations
  Future<List<SyncMetadata>> _generateTestData({required int count}) async {
    final changes = <SyncMetadata>[];
    final random = Random();

    for (int i = 0; i < count; i++) {
      final dataType =
          SyncDataType.values[random.nextInt(SyncDataType.values.length)];
      final change = await _generateSingleTestChange(dataType);
      changes.add(change);
    }

    AppLogger.debug(_tag, 'Generated $count test data changes');
    return changes;
  }

  /// Generate test data while simulating offline state
  Future<List<SyncMetadata>> _generateTestDataOffline({
    required int messageCount,
    required int dataCount,
  }) async {
    final changes = <SyncMetadata>[];

    // Generate conversation messages
    for (int i = 0; i < messageCount; i++) {
      final change = await _generateSingleTestChange(SyncDataType.conversation);
      changes.add(change);
    }

    // Generate other data changes
    for (int i = 0; i < dataCount; i++) {
      final dataType = [
        SyncDataType.intakeLog,
        SyncDataType.achievement,
        SyncDataType.bodyMapData,
      ][Random().nextInt(3)];

      final change = await _generateSingleTestChange(dataType);
      changes.add(change);
    }

    AppLogger.debug(_tag, 'Generated ${changes.length} offline changes');
    return changes;
  }

  /// Generate test data by specific type
  Future<List<SyncMetadata>> _generateTestDataByType(
    SyncDataType dataType,
    int count,
  ) async {
    final changes = <SyncMetadata>[];

    for (int i = 0; i < count; i++) {
      final change = await _generateSingleTestChange(dataType);
      changes.add(change);
    }

    return changes;
  }

  /// Generate single test change
  Future<SyncMetadata> _generateSingleTestChange(SyncDataType dataType) async {
    final now = DateTime.now();
    final id =
        'test_${dataType.name}_${now.millisecondsSinceEpoch}_${Random().nextInt(1000)}';

    return SyncMetadata(
      id: id,
      dataType: dataType,
      operation: SyncOperation.create,
      localId: 'local_$id',
      payload: _generateTestPayload(dataType),
      createdAt: now,
    );
  }

  /// Generate test payload for data type
  Map<String, dynamic> _generateTestPayload(SyncDataType dataType) {
    final random = Random();

    switch (dataType) {
      case SyncDataType.intakeLog:
        return {
          'volume_ml': 200 + random.nextInt(300),
          'liquid_type': ['water', 'juice', 'tea'][random.nextInt(3)],
          'logged_at': DateTime.now().toIso8601String(),
          'source': 'manual',
        };

      case SyncDataType.conversation:
        return {
          'message_id': 'msg_${random.nextInt(10000)}',
          'content': 'Test message ${random.nextInt(100)}',
          'message_type': random.nextBool() ? 'user' : 'ai',
          'session_id': 'session_${random.nextInt(10)}',
        };

      case SyncDataType.achievement:
        return {
          'achievement_id': 'achievement_${random.nextInt(50)}',
          'progress': random.nextInt(100),
          'is_unlocked': random.nextBool(),
          'xp_reward': random.nextInt(500),
        };

      case SyncDataType.bodyMapData:
        return {
          'overall_hydration': random.nextDouble(),
          'critical_organs': random.nextInt(3),
          'health_score': 50 + random.nextInt(50),
        };

      default:
        return {'test_data': 'value_${random.nextInt(1000)}'};
    }
  }

  /// Simulate sync operations
  Future<void> _simulateSync(
    List<SyncMetadata> changes, {
    required bool success,
    String? error,
  }) async {
    for (final change in changes) {
      await _syncDatabase.upsertSyncMetadata(change);

      if (success) {
        await _syncDatabase.updateSyncMetadataStatus(
          change.id,
          SyncStatus.success,
        );
        await _syncDatabase.deleteSyncMetadata(
          change.id,
        ); // Remove after success
      } else {
        await _syncDatabase.updateSyncMetadataStatus(
          change.id,
          SyncStatus.failed,
          error: error ?? 'Simulated failure',
        );
      }
    }
  }

  /// Simulate offline sync attempts
  Future<void> _simulateOfflineSync(List<SyncMetadata> changes) async {
    for (final change in changes) {
      await _syncDatabase.upsertSyncMetadata(change);
      // Leave as pending (will be retried when online)
    }
  }

  /// Simulate online recovery
  Future<SyncRecoveryResult> _simulateOnlineRecovery(
    List<SyncMetadata> offlineChanges,
  ) async {
    final result = SyncRecoveryResult();
    final random = Random();

    for (final change in offlineChanges) {
      // Simulate sync with some failures and conflicts
      if (random.nextDouble() < 0.1) {
        // 10% failure rate
        await _syncDatabase.updateSyncMetadataStatus(
          change.id,
          SyncStatus.failed,
        );
        result.failureCount++;
      } else if (random.nextDouble() < 0.05) {
        // 5% conflict rate
        // Create a mock conflict
        await _createMockConflict(change);
        result.conflictCount++;
      } else {
        await _syncDatabase.updateSyncMetadataStatus(
          change.id,
          SyncStatus.success,
        );
        await _syncDatabase.deleteSyncMetadata(change.id);
        result.successCount++;
      }
    }

    return result;
  }

  /// Test conflict resolution
  Future<ConflictResolutionTestResult> _testConflictResolution() async {
    final result = ConflictResolutionTestResult();
    final conflicts = await _syncDatabase.getSyncConflicts();

    for (final conflict in conflicts) {
      try {
        final resolution = await _conflictResolver.resolveConflict(
          conflict: conflict,
        );
        if (resolution.success) {
          result.resolvedCount++;
        } else {
          result.failedCount++;
        }
      } catch (e) {
        result.failedCount++;
      }
    }

    return result;
  }

  /// Verify data integrity
  Future<DataIntegrityResult> _verifyDataIntegrity() async {
    final result = DataIntegrityResult();
    final issues = <String>[];

    try {
      // Check for orphaned sync metadata
      final pendingChanges = await _syncDatabase.getPendingSyncMetadata();
      final oldChanges = pendingChanges.where(
        (c) => DateTime.now().difference(c.createdAt).inHours > 24,
      );

      if (oldChanges.isNotEmpty) {
        issues.add('Found ${oldChanges.length} changes older than 24 hours');
      }

      // Check for conflicts without resolution
      final unresolvedConflicts = await _syncDatabase.getSyncConflicts();
      if (unresolvedConflicts.isNotEmpty) {
        issues.add('Found ${unresolvedConflicts.length} unresolved conflicts');
      }

      // Check sync statistics consistency
      final stats = await _syncDatabase.getSyncStats();
      final successRate = stats['success_rate'] as double? ?? 0.0;
      if (successRate < 50.0) {
        issues.add('Low success rate: ${successRate.toStringAsFixed(1)}%');
      }

      result.passed = issues.isEmpty;
      result.issues.addAll(issues);
    } catch (e) {
      result.passed = false;
      result.issues.add('Integrity check failed: $e');
    }

    return result;
  }

  /// Create mock conflict for testing
  Future<void> _createMockConflict(SyncMetadata change) async {
    final conflict = SyncConflict(
      id: 'conflict_${change.id}',
      dataType: change.dataType,
      localId: change.localId,
      remoteId: 'remote_${change.localId}',
      localData: change.payload,
      remoteData: {...change.payload, 'remote_modified': true},
      createdAt: DateTime.now(),
    );

    await _syncDatabase.insertSyncConflict(conflict);
  }

  /// Process sync chunk for performance testing
  Future<ChunkResult> _processSyncChunk(List<SyncMetadata> chunk) async {
    final result = ChunkResult();
    final stopwatch = Stopwatch()..start();

    for (final change in chunk) {
      try {
        await _syncDatabase.upsertSyncMetadata(change);
        await Future.delayed(
          const Duration(milliseconds: 10),
        ); // Simulate processing time
        await _syncDatabase.updateSyncMetadataStatus(
          change.id,
          SyncStatus.success,
        );
        result.successes++;
      } catch (e) {
        result.failures++;
      }
      result.operations++;
    }

    result.avgLatency = stopwatch.elapsedMilliseconds / chunk.length;
    return result;
  }

  /// Chunk list into smaller lists
  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    final chunks = <List<T>>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, min(i + chunkSize, list.length)));
    }
    return chunks;
  }

  /// Get comprehensive test summary
  Future<Map<String, dynamic>> getTestSummary() async {
    final retryStats = await _retryManager.getRetryStatistics();
    final syncStats = await _syncDatabase.getSyncStats();

    return {
      'retry_statistics': retryStats,
      'sync_statistics': syncStats,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}

// Test result classes
class OfflineTestResult {
  DateTime startTime;
  DateTime? endTime;
  Duration? totalDuration;
  bool success = false;
  String? error;

  int baselineDataCount = 0;
  int offlineDataCount = 0;
  int syncSuccessCount = 0;
  int syncFailureCount = 0;
  int conflictCount = 0;
  int conflictResolutionSuccessCount = 0;
  bool dataIntegrityPassed = false;
  List<String> integrityIssues = [];

  OfflineTestResult({required this.startTime});
}

class SyncPerformanceResult {
  DateTime startTime;
  Duration totalDuration = Duration.zero;
  int totalOperations = 0;
  int successfulOperations = 0;
  int failedOperations = 0;
  double averageLatency = 0.0;
  double throughputOpsPerSecond = 0.0;
  double successRate = 0.0;
  String? error;

  SyncPerformanceResult({required this.startTime});
}

class CircuitBreakerTestResult {
  final SyncDataType dataType;
  final DateTime startTime;
  bool success = false;
  bool circuitBreakerTriggered = false;
  bool requestsBlockedWhenOpen = false;
  bool recoveryAfterReset = false;
  String? error;

  CircuitBreakerTestResult({required this.dataType, required this.startTime});
}

class SyncRecoveryResult {
  int successCount = 0;
  int failureCount = 0;
  int conflictCount = 0;
}

class ConflictResolutionTestResult {
  int resolvedCount = 0;
  int failedCount = 0;
}

class DataIntegrityResult {
  bool passed = true;
  List<String> issues = [];
}

class ChunkResult {
  int operations = 0;
  int successes = 0;
  int failures = 0;
  double avgLatency = 0.0;
}
