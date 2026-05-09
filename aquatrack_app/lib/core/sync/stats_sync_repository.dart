import 'package:uuid/uuid.dart';

import '../utils/logger.dart';
import '../repositories/stats_repository.dart';
import '../../shared/models/intake_log.dart';
import '../../shared/models/daily_summary.dart';
import 'sync_models.dart';
import 'sync_service.dart';
import 'conflict_resolver.dart';

/// Repository for syncing stats data (IntakeLog, DailySummary) incrementally
class StatsSyncRepository {
  static const String _tag = 'StatsSyncRepository';

  final StatsRepository
      _statsRepository; // TODO: Use when implementing local storage access
  final SyncService _syncService;
  final ConflictResolver _conflictResolver;
  final Uuid _uuid = const Uuid();

  StatsSyncRepository({
    required StatsRepository statsRepository,
    required SyncService syncService,
    required ConflictResolver conflictResolver,
  })  : _statsRepository = statsRepository,
        _syncService = syncService,
        _conflictResolver = conflictResolver;

  /// Sync intake logs incrementally
  Future<SyncResult> syncIntakeLogs({DateTime? since}) async {
    AppLogger.info(_tag, 'Starting incremental intake logs sync');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Step 1: Upload new/modified local logs
      final localChanges = await _getLocalIntakeLogChanges(since: since);
      AppLogger.info(
        _tag,
        'Found ${localChanges.length} local intake log changes',
      );

      for (final log in localChanges) {
        try {
          await _uploadIntakeLog(log);
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload log ${log.id}: $e');
          AppLogger.error(_tag, 'Failed to upload intake log ${log.id}', e);
        }
      }

      // Step 2: Download remote changes
      final remoteChanges = await _downloadRemoteIntakeLogChanges(since: since);
      AppLogger.info(
        _tag,
        'Found ${remoteChanges.length} remote intake log changes',
      );

      for (final remoteLog in remoteChanges) {
        try {
          await _processRemoteIntakeLog(remoteLog);
          downloadedCount++;
        } catch (e) {
          errors.add('Failed to process remote log ${remoteLog['id']}: $e');
          AppLogger.error(_tag, 'Failed to process remote intake log', e);
        }
      }

      final duration = stopwatch.elapsed;
      AppLogger.info(
        _tag,
        'Intake logs sync completed: $uploadedCount uploaded, $downloadedCount downloaded in ${duration.inMilliseconds}ms',
      );

      return SyncResult.success(
        dataType: SyncDataType.intakeLog,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: duration,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error(_tag, 'Intake logs sync failed', e);
      return SyncResult.error(
        dataType: SyncDataType.intakeLog,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sync daily summaries incrementally
  Future<SyncResult> syncDailySummaries({DateTime? since}) async {
    AppLogger.info(_tag, 'Starting incremental daily summaries sync');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Step 1: Upload new/modified local summaries
      final localChanges = await _getLocalDailySummaryChanges(since: since);
      AppLogger.info(
        _tag,
        'Found ${localChanges.length} local daily summary changes',
      );

      for (final summary in localChanges) {
        try {
          await _uploadDailySummary(summary);
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload summary: $e');
          AppLogger.error(
            _tag,
            'Failed to upload daily summary',
            e,
          );
        }
      }

      // Step 2: Download remote changes
      final remoteChanges = await _downloadRemoteDailySummaryChanges(
        since: since,
      );
      AppLogger.info(
        _tag,
        'Found ${remoteChanges.length} remote daily summary changes',
      );

      for (final remoteSummary in remoteChanges) {
        try {
          await _processRemoteDailySummary(remoteSummary);
          downloadedCount++;
        } catch (e) {
          errors.add(
            'Failed to process remote summary ${remoteSummary['date']}: $e',
          );
          AppLogger.error(_tag, 'Failed to process remote daily summary', e);
        }
      }

      final duration = stopwatch.elapsed;
      AppLogger.info(
        _tag,
        'Daily summaries sync completed: $uploadedCount uploaded, $downloadedCount downloaded in ${duration.inMilliseconds}ms',
      );

      return SyncResult.success(
        dataType: SyncDataType.dailySummary,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: duration,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error(_tag, 'Daily summaries sync failed', e);
      return SyncResult.error(
        dataType: SyncDataType.dailySummary,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Get local intake log changes since last sync
  Future<List<IntakeLog>> _getLocalIntakeLogChanges({DateTime? since}) async {
    // TODO: Implement local storage access for intake logs
    // For now, return empty list as placeholder
    AppLogger.debug(_tag, 'Getting local intake log changes since: $since');
    return [];
  }

  /// Get local daily summary changes since last sync
  Future<List<DailySummary>> _getLocalDailySummaryChanges({
    DateTime? since,
  }) async {
    // TODO: Implement local storage access for daily summaries
    // For now, return empty list as placeholder
    AppLogger.debug(_tag, 'Getting local daily summary changes since: $since');
    return [];
  }

  /// Upload intake log to server
  Future<void> _uploadIntakeLog(IntakeLog log) async {
    AppLogger.debug(_tag, 'Uploading intake log ${log.id}');

    // Add to sync queue
    await _syncService.addSyncChange(
      dataType: SyncDataType.intakeLog,
      operation:
          SyncOperation.create, // Always create since no remoteId tracking
      localId: log.id,
      remoteId: null, // No remote ID tracking in current model
      payload: {
        'volume_ml': log.volumeMl,
        'effective_volume_ml': log.effectiveVolumeMl,
        'liquid_type': log.liquidType,
        'logged_at': log.loggedAt.toIso8601String(),
        'source': log.source,
        'xp_earned': log.xpEarned,
      },
    );
  }

  /// Upload daily summary to server
  Future<void> _uploadDailySummary(DailySummary summary) async {
    AppLogger.debug(_tag, 'Uploading daily summary');

    // Use current date as ID since DailySummary doesn't have date field
    final todayId = DateTime.now().toIso8601String().split('T')[0];

    // Add to sync queue
    await _syncService.addSyncChange(
      dataType: SyncDataType.dailySummary,
      operation:
          SyncOperation.create, // Always create since no remoteId tracking
      localId: todayId,
      remoteId: null, // No remote ID tracking in current model
      payload: {
        'daily_goal_ml': summary.dailyGoalMl,
        'total_effective_ml': summary.totalEffectiveMl,
        'log_count': summary.logCount,
        'progress': summary.progress,
        'remaining_ml': summary.remainingMl,
        'streak_days': summary.streakDays,
        'xp_today': summary.xpToday,
        'current_level': summary.currentLevel,
      },
    );
  }

  /// Download remote intake log changes
  Future<List<Map<String, dynamic>>> _downloadRemoteIntakeLogChanges({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call to fetch remote changes
    // For now, return empty list as placeholder
    AppLogger.debug(
      _tag,
      'Downloading remote intake log changes since: $since',
    );

    // Mock API response
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      // Example remote data structure
      // {
      //   'id': 'remote-id-123',
      //   'amount': 250.0,
      //   'liquid_type': 'water',
      //   'timestamp': '2024-01-01T10:00:00Z',
      //   'note': 'Morning hydration',
      //   'effectiveness_multiplier': 1.0,
      //   'updated_at': '2024-01-01T10:05:00Z',
      // }
    ];
  }

  /// Download remote daily summary changes
  Future<List<Map<String, dynamic>>> _downloadRemoteDailySummaryChanges({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call to fetch remote changes
    AppLogger.debug(
      _tag,
      'Downloading remote daily summary changes since: $since',
    );

    // Mock API response
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  /// Process remote intake log change
  Future<void> _processRemoteIntakeLog(Map<String, dynamic> remoteData) async {
    final remoteId = remoteData['id'] as String;
    AppLogger.debug(_tag, 'Processing remote intake log $remoteId');

    try {
      // TODO: Implement actual local lookup and conflict handling
      // For now, just create new local log
      await _createLocalIntakeLogFromRemote(remoteData);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process remote intake log $remoteId', e);
      rethrow;
    }
  }

  /// Process remote daily summary change
  Future<void> _processRemoteDailySummary(
    Map<String, dynamic> remoteData,
  ) async {
    final remoteId = remoteData['id'] as String;

    AppLogger.debug(_tag, 'Processing remote daily summary $remoteId');

    try {
      // TODO: Implement actual local lookup and conflict handling
      // For now, just create/update local summary
      await _createOrUpdateLocalDailySummaryFromRemote(remoteData);
    } catch (e) {
      AppLogger.error(
        _tag,
        'Failed to process remote daily summary $remoteId',
        e,
      );
      rethrow;
    }
  }

  /// Handle intake log conflict
  Future<void> _handleIntakeLogConflict(
    IntakeLog localLog,
    Map<String, dynamic> remoteData,
  ) async {
    AppLogger.info(_tag, 'Handling intake log conflict for ${localLog.id}');

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.intakeLog,
      localId: localLog.id,
      remoteId: remoteData['id'] as String,
      localData: {
        'volume_ml': localLog.volumeMl,
        'effective_volume_ml': localLog.effectiveVolumeMl,
        'liquid_type': localLog.liquidType,
        'logged_at': localLog.loggedAt.toIso8601String(),
        'source': localLog.source,
        'xp_earned': localLog.xpEarned,
      },
      remoteData: remoteData,
      createdAt: DateTime.now(),
      suggestedStrategy: ConflictResolutionStrategy.lastWriteWins,
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedIntakeLogData(localLog, resolution.resolvedData!);
      AppLogger.info(
        _tag,
        'Intake log conflict resolved: ${resolution.message}',
      );
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve intake log conflict: ${resolution.message}',
      );
    }
  }

  /// Handle daily summary conflict
  Future<void> _handleDailySummaryConflict(
    DailySummary localSummary,
    Map<String, dynamic> remoteData,
  ) async {
    AppLogger.info(
      _tag,
      'Handling daily summary conflict',
    );

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.dailySummary,
      localId: 'daily_summary', // TODO: Add date-based ID
      remoteId: remoteData['id'] as String,
      localData: {
        'daily_goal_ml': localSummary.dailyGoalMl,
        'total_effective_ml': localSummary.totalEffectiveMl,
        'log_count': localSummary.logCount,
        'progress': localSummary.progress,
        'remaining_ml': localSummary.remainingMl,
        'streak_days': localSummary.streakDays,
        'xp_today': localSummary.xpToday,
        'current_level': localSummary.currentLevel,
      },
      remoteData: remoteData,
      createdAt: DateTime.now(),
      suggestedStrategy:
          ConflictResolutionStrategy.merge, // Merge is good for summaries
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedDailySummaryData(
        localSummary,
        resolution.resolvedData!,
      );
      AppLogger.info(
        _tag,
        'Daily summary conflict resolved: ${resolution.message}',
      );
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve daily summary conflict: ${resolution.message}',
      );
    }
  }

  /// Apply remote intake log update without conflict
  Future<void> _applyRemoteIntakeLogUpdate(
    IntakeLog localLog,
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Update local log with remote data
    AppLogger.debug(
      _tag,
      'Applying remote update to intake log ${localLog.id}',
    );
  }

  /// Apply remote daily summary update without conflict
  Future<void> _applyRemoteDailySummaryUpdate(
    DailySummary localSummary,
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Update local summary with remote data
    AppLogger.debug(
      _tag,
      'Applying remote update to daily summary ${localSummary.lastUpdated}',
    );
  }

  /// Create local intake log from remote data
  Future<void> _createLocalIntakeLogFromRemote(
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Create new intake log from remote data
    AppLogger.debug(_tag, 'Creating local intake log from remote data');
  }

  /// Create or update local daily summary from remote data
  Future<void> _createOrUpdateLocalDailySummaryFromRemote(
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Create or update daily summary from remote data
    AppLogger.debug(
      _tag,
      'Creating/updating local daily summary from remote data',
    );
  }

  /// Apply resolved conflict data to intake log
  Future<void> _applyResolvedIntakeLogData(
    IntakeLog localLog,
    Map<String, dynamic> resolvedData,
  ) async {
    // TODO: Apply resolved conflict data to local intake log
    AppLogger.debug(
      _tag,
      'Applying resolved conflict data to intake log ${localLog.id}',
    );
  }

  /// Apply resolved conflict data to daily summary
  Future<void> _applyResolvedDailySummaryData(
    DailySummary localSummary,
    Map<String, dynamic> resolvedData,
  ) async {
    // TODO: Apply resolved conflict data to local daily summary
    AppLogger.debug(
      _tag,
      'Applying resolved conflict data to daily summary ${localSummary.lastUpdated}',
    );
  }
}

/// Result of a sync operation
class SyncResult {
  final bool success;
  final SyncDataType dataType;
  final int uploadedCount;
  final int downloadedCount;
  final Duration duration;
  final List<String> errors;
  final String? error;

  const SyncResult._({
    required this.success,
    required this.dataType,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    required this.duration,
    this.errors = const [],
    this.error,
  });

  factory SyncResult.success({
    required SyncDataType dataType,
    int uploadedCount = 0,
    int downloadedCount = 0,
    required Duration duration,
    List<String> errors = const [],
  }) {
    return SyncResult._(
      success: true,
      dataType: dataType,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      duration: duration,
      errors: errors,
    );
  }

  factory SyncResult.error({
    required SyncDataType dataType,
    required String error,
    required Duration duration,
  }) {
    return SyncResult._(
      success: false,
      dataType: dataType,
      duration: duration,
      error: error,
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  int get totalProcessed => uploadedCount + downloadedCount;
}
