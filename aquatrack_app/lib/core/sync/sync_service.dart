import 'dart:async';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:uuid/uuid.dart';

import '../utils/logger.dart';
import 'sync_models.dart';
import 'sync_database.dart';
import 'sync_storage.dart';
// import 'sync_retry_manager.dart'; // TODO: Integrate retry manager in future iterations

/// Main sync service for coordinating offline-first synchronization
class SyncService {
  static const String _tag = 'SyncService';

  final SyncDatabase _syncDatabase;
  final SyncStorage _syncStorage;
  final Uuid _uuid = const Uuid();

  // Sync configuration
  static const Duration _defaultSyncInterval = Duration(minutes: 5);
  static const int _maxRetries = 3;

  // State management
  final StreamController<SyncState> _syncStateController =
      StreamController<SyncState>.broadcast();
  Timer? _periodicSyncTimer;
  Timer? _retryTimer;
  bool _isDisposed = false;
  bool _isSyncing = false;

  // Connectivity monitoring
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;
  bool _hasConnectivity = false;

  // Sync configurations by data type (TODO: Use in future iterations)
  // final Map<SyncDataType, SyncConfig> _syncConfigs = {
  //   SyncDataType.intakeLog: const SyncConfig(
  //     dataType: SyncDataType.intakeLog,
  //     syncInterval: Duration(minutes: 3),
  //     conflictStrategy: ConflictResolutionStrategy.clientWins,
  //   ),
  //   SyncDataType.dailySummary: const SyncConfig(
  //     dataType: SyncDataType.dailySummary,
  //     syncInterval: Duration(minutes: 5),
  //     conflictStrategy: ConflictResolutionStrategy.lastWriteWins,
  //   ),
  //   SyncDataType.achievement: const SyncConfig(
  //     dataType: SyncDataType.achievement,
  //     syncInterval: Duration(minutes: 10),
  //     conflictStrategy: ConflictResolutionStrategy.serverWins,
  //   ),
  //   SyncDataType.userLevel: const SyncConfig(
  //     dataType: SyncDataType.userLevel,
  //     syncInterval: Duration(minutes: 10),
  //     conflictStrategy: ConflictResolutionStrategy.merge,
  //   ),
  //   SyncDataType.bodyMapData: const SyncConfig(
  //     dataType: SyncDataType.bodyMapData,
  //     syncInterval: Duration(minutes: 5),
  //     conflictStrategy: ConflictResolutionStrategy.lastWriteWins,
  //   ),
  //   SyncDataType.conversation: const SyncConfig(
  //     dataType: SyncDataType.conversation,
  //     syncInterval: Duration(minutes: 2),
  //     conflictStrategy: ConflictResolutionStrategy.clientWins,
  //   ),
  // };

  SyncService({
    required SyncDatabase syncDatabase,
    required SyncStorage syncStorage,
  }) : _syncDatabase = syncDatabase,
       _syncStorage = syncStorage;

  /// Stream of sync state changes
  Stream<SyncState> get syncStateStream => _syncStateController.stream;

  /// Current sync state
  Future<SyncState> get currentSyncState => _syncStorage.getSyncState();

  /// Initialize the sync service
  Future<void> initialize() async {
    AppLogger.info(_tag, 'Initializing sync service');

    try {
      // Check initial connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _hasConnectivity = _isConnected(connectivityResult);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
        _handleConnectivityChange,
      );

      // Load current sync state
      final currentState = await _syncStorage.getSyncState();
      _syncStateController.add(currentState);

      // Start periodic sync if we have connectivity
      if (_hasConnectivity) {
        _startPeriodicSync();
      }

      // Process any pending changes from previous sessions
      await _processPendingChanges();

      AppLogger.info(_tag, 'Sync service initialized successfully');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize sync service', e);
      _updateSyncState(status: SyncStatus.failed, error: e.toString());
    }
  }

  /// Add a change to sync queue
  Future<void> addSyncChange({
    required SyncDataType dataType,
    required SyncOperation operation,
    required String localId,
    String? remoteId,
    required Map<String, dynamic> payload,
  }) async {
    if (_isDisposed) return;

    try {
      AppLogger.debug(
        _tag,
        'Adding sync change: $dataType $operation for $localId',
      );

      final metadata = SyncMetadata(
        id: _uuid.v4(),
        dataType: dataType,
        operation: operation,
        localId: localId,
        remoteId: remoteId,
        payload: payload,
        createdAt: DateTime.now(),
      );

      await _syncDatabase.upsertSyncMetadata(metadata);

      // Update pending changes count
      await _updatePendingChangesCount();

      // Trigger immediate sync if connected
      if (_hasConnectivity && !_isSyncing) {
        _scheduleSyncAttempt(immediate: true);
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to add sync change', e);
    }
  }

  /// Manually trigger sync
  Future<void> triggerSync({SyncDataType? dataType}) async {
    if (_isDisposed || _isSyncing) return;

    AppLogger.info(
      _tag,
      'Manual sync triggered${dataType != null ? ' for $dataType' : ''}',
    );

    if (!_hasConnectivity) {
      AppLogger.warning(_tag, 'No connectivity available for sync');
      _updateSyncState(
        status: SyncStatus.failed,
        error: 'No internet connection',
      );
      return;
    }

    await _executeSyncOperation(dataType: dataType);
  }

  /// Handle connectivity changes
  void _handleConnectivityChange(ConnectivityResult result) {
    final wasConnected = _hasConnectivity;
    _hasConnectivity = _isConnected(result);

    AppLogger.info(
      _tag,
      'Connectivity changed: $result (connected: $_hasConnectivity)',
    );

    if (_hasConnectivity && !wasConnected) {
      // Connection restored
      AppLogger.info(_tag, 'Connection restored, starting sync');
      _startPeriodicSync();
      _scheduleSyncAttempt(immediate: true);
    } else if (!_hasConnectivity && wasConnected) {
      // Connection lost
      AppLogger.info(_tag, 'Connection lost, stopping periodic sync');
      _stopPeriodicSync();
    }
  }

  /// Start periodic background sync
  void _startPeriodicSync() {
    _stopPeriodicSync();

    if (_hasConnectivity) {
      _periodicSyncTimer = Timer.periodic(_defaultSyncInterval, (_) {
        if (!_isSyncing) {
          _scheduleSyncAttempt();
        }
      });

      AppLogger.info(
        _tag,
        'Periodic sync started with interval: $_defaultSyncInterval',
      );
    }
  }

  /// Stop periodic sync
  void _stopPeriodicSync() {
    _periodicSyncTimer?.cancel();
    _periodicSyncTimer = null;
  }

  /// Schedule a sync attempt
  void _scheduleSyncAttempt({bool immediate = false}) {
    if (_isDisposed || _isSyncing) return;

    final delay = immediate ? Duration.zero : const Duration(seconds: 1);

    _retryTimer?.cancel();
    _retryTimer = Timer(delay, () {
      if (!_isDisposed && _hasConnectivity) {
        _executeSyncOperation();
      }
    });
  }

  /// Execute sync operation
  Future<void> _executeSyncOperation({SyncDataType? dataType}) async {
    if (_isSyncing || !_hasConnectivity) return;

    _isSyncing = true;
    _updateSyncState(status: SyncStatus.syncing);

    final stopwatch = Stopwatch()..start();
    int totalSynced = 0;
    String? lastError;

    try {
      AppLogger.info(
        _tag,
        'Starting sync operation${dataType != null ? ' for $dataType' : ''}',
      );

      // Get pending changes
      final pendingChanges = await _syncDatabase.getPendingSyncMetadata(
        dataType: dataType,
        limit: 50, // Process in batches
      );

      if (pendingChanges.isEmpty) {
        AppLogger.debug(_tag, 'No pending changes to sync');
        _updateSyncState(status: SyncStatus.success);
        return;
      }

      AppLogger.info(
        _tag,
        'Processing ${pendingChanges.length} pending changes',
      );

      // Process changes by data type
      for (final change in pendingChanges) {
        if (!_hasConnectivity || _isDisposed) break;

        try {
          await _processSyncChange(change);
          totalSynced++;

          // Small delay between operations to avoid overwhelming the server
          await Future.delayed(const Duration(milliseconds: 100));
        } catch (e) {
          lastError = e.toString();
          AppLogger.error(_tag, 'Failed to sync change ${change.id}', e);

          // Update failed change
          await _syncDatabase.updateSyncMetadataStatus(
            change.id,
            change.retryCount >= _maxRetries
                ? SyncStatus.failed
                : SyncStatus.idle,
            error: e.toString(),
          );
        }
      }

      // Record sync stats
      await _syncDatabase.recordSyncStats(
        dataType:
            dataType ?? SyncDataType.intakeLog, // Default type for mixed syncs
        operation: SyncOperation.update,
        status: lastError == null ? SyncStatus.success : SyncStatus.failed,
        duration: stopwatch.elapsed,
        recordsSynced: totalSynced,
        error: lastError,
      );

      final finalStatus = lastError == null
          ? SyncStatus.success
          : SyncStatus.failed;
      _updateSyncState(status: finalStatus, error: lastError);

      AppLogger.info(
        _tag,
        'Sync completed: $totalSynced/${pendingChanges.length} synced in ${stopwatch.elapsedMilliseconds}ms',
      );
    } catch (e) {
      AppLogger.error(_tag, 'Sync operation failed', e);
      _updateSyncState(status: SyncStatus.failed, error: e.toString());
    } finally {
      _isSyncing = false;
      stopwatch.stop();
      await _updatePendingChangesCount();
    }
  }

  /// Process individual sync change
  Future<void> _processSyncChange(SyncMetadata change) async {
    AppLogger.debug(
      _tag,
      'Processing sync change: ${change.dataType} ${change.operation} ${change.localId}',
    );

    // Update retry attempt
    await _syncDatabase.updateSyncMetadataStatus(change.id, SyncStatus.syncing);

    // Here you would implement the actual API calls based on data type
    // For now, simulate sync operation
    await Future.delayed(Duration(milliseconds: 100 + Random().nextInt(200)));

    // Simulate occasional failures for testing
    if (Random().nextDouble() < 0.1) {
      // 10% failure rate
      throw Exception('Simulated sync failure for testing');
    }

    // Mark as successful
    await _syncDatabase.updateSyncMetadataStatus(
      change.id,
      SyncStatus.success,
      remoteId: _uuid.v4(), // Simulated remote ID
    );

    // Remove from pending queue
    await _syncDatabase.deleteSyncMetadata(change.id);
  }

  /// Process pending changes from previous sessions
  Future<void> _processPendingChanges() async {
    final pendingCount = (await _syncDatabase.getPendingSyncMetadata()).length;
    if (pendingCount > 0) {
      AppLogger.info(
        _tag,
        'Found $pendingCount pending changes from previous session',
      );
      if (_hasConnectivity) {
        _scheduleSyncAttempt(immediate: true);
      }
    }
  }

  /// Update sync state and notify listeners
  void _updateSyncState({SyncStatus? status, String? error}) {
    final currentTime = DateTime.now();

    _syncStorage.getSyncState().then((currentState) {
      final newState = currentState.copyWith(
        status: status ?? currentState.status,
        lastSyncTime: status == SyncStatus.success
            ? currentTime
            : currentState.lastSyncTime,
        currentError: error,
      );

      _syncStorage.setSyncState(newState);
      _syncStateController.add(newState);
    });
  }

  /// Update pending changes count
  Future<void> _updatePendingChangesCount() async {
    final pendingChanges = await _syncDatabase.getPendingSyncMetadata();
    final conflicts = await _syncDatabase.getSyncConflicts();

    final currentState = await _syncStorage.getSyncState();
    final newState = currentState.copyWith(
      pendingChanges: pendingChanges.length,
      conflictCount: conflicts.length,
    );

    await _syncStorage.setSyncState(newState);
    _syncStateController.add(newState);
  }

  /// Check if connectivity result indicates connection
  bool _isConnected(ConnectivityResult result) {
    return result != ConnectivityResult.none;
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats({
    SyncDataType? dataType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    return await _syncDatabase.getSyncStats(
      dataType: dataType,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// Clear old sync data for cleanup
  Future<void> cleanup({Duration? olderThan}) async {
    final cutoffDate = DateTime.now().subtract(
      olderThan ?? const Duration(days: 30),
    );

    await _syncDatabase.clearOldSyncStats(cutoffDate);
    AppLogger.info(_tag, 'Cleaned sync data older than $cutoffDate');
  }

  /// Dispose resources
  Future<void> dispose() async {
    _isDisposed = true;

    _stopPeriodicSync();
    _retryTimer?.cancel();

    await _connectivitySubscription.cancel();
    await _syncStateController.close();
    await _syncDatabase.close();

    AppLogger.info(_tag, 'Sync service disposed');
  }
}
