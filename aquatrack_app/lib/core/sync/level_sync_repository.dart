import 'package:uuid/uuid.dart';

import '../utils/logger.dart';
import '../models/user.dart';
import 'sync_models.dart';
import 'sync_service.dart';
import 'conflict_resolver.dart';

/// Repository for syncing level system data (user level, achievements) incrementally
class LevelSyncRepository {
  static const String _tag = 'LevelSyncRepository';

  final SyncService _syncService;
  final ConflictResolver _conflictResolver;
  final Uuid _uuid = const Uuid();

  LevelSyncRepository({
    required SyncService syncService,
    required ConflictResolver conflictResolver,
  }) : _syncService = syncService,
       _conflictResolver = conflictResolver;

  /// Sync user level and XP incrementally
  Future<LevelSyncResult> syncUserLevel({DateTime? since}) async {
    AppLogger.info(_tag, 'Starting user level sync');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Step 1: Upload local user level changes
      final hasLocalChanges = await _checkForLocalUserLevelChanges(
        since: since,
      );
      if (hasLocalChanges) {
        try {
          await _uploadUserLevel();
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload user level: $e');
          AppLogger.error(_tag, 'Failed to upload user level', e);
        }
      }

      // Step 2: Download remote user level changes
      final remoteUserData = await _downloadRemoteUserLevel(since: since);
      if (remoteUserData != null) {
        try {
          await _processRemoteUserLevel(remoteUserData);
          downloadedCount++;
        } catch (e) {
          errors.add('Failed to process remote user level: $e');
          AppLogger.error(_tag, 'Failed to process remote user level', e);
        }
      }

      final duration = stopwatch.elapsed;
      AppLogger.info(
        _tag,
        'User level sync completed in ${duration.inMilliseconds}ms',
      );

      return LevelSyncResult.success(
        dataType: SyncDataType.userLevel,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: duration,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error(_tag, 'User level sync failed', e);
      return LevelSyncResult.error(
        dataType: SyncDataType.userLevel,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sync achievements incrementally
  Future<LevelSyncResult> syncAchievements({DateTime? since}) async {
    AppLogger.info(_tag, 'Starting achievements sync');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Step 1: Upload local achievement changes
      final localChanges = await _getLocalAchievementChanges(since: since);
      AppLogger.info(
        _tag,
        'Found ${localChanges.length} local achievement changes',
      );

      for (final achievement in localChanges) {
        try {
          await _uploadAchievement(achievement);
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload achievement ${achievement['id']}: $e');
          AppLogger.error(_tag, 'Failed to upload achievement', e);
        }
      }

      // Step 2: Download remote achievement changes
      final remoteChanges = await _downloadRemoteAchievements(since: since);
      AppLogger.info(
        _tag,
        'Found ${remoteChanges.length} remote achievement changes',
      );

      for (final remoteAchievement in remoteChanges) {
        try {
          await _processRemoteAchievement(remoteAchievement);
          downloadedCount++;
        } catch (e) {
          errors.add(
            'Failed to process remote achievement ${remoteAchievement['id']}: $e',
          );
          AppLogger.error(_tag, 'Failed to process remote achievement', e);
        }
      }

      final duration = stopwatch.elapsed;
      AppLogger.info(
        _tag,
        'Achievements sync completed: $uploadedCount uploaded, $downloadedCount downloaded in ${duration.inMilliseconds}ms',
      );

      return LevelSyncResult.success(
        dataType: SyncDataType.achievement,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: duration,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error(_tag, 'Achievements sync failed', e);
      return LevelSyncResult.error(
        dataType: SyncDataType.achievement,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Check if there are local user level changes
  Future<bool> _checkForLocalUserLevelChanges({DateTime? since}) async {
    // TODO: Implement actual check for local user level changes
    // For now, return false as placeholder
    AppLogger.debug(
      _tag,
      'Checking for local user level changes since: $since',
    );
    return false;
  }

  /// Get local achievement changes since last sync
  Future<List<Map<String, dynamic>>> _getLocalAchievementChanges({
    DateTime? since,
  }) async {
    // TODO: Implement local achievement storage access
    // For now, return empty list as placeholder
    AppLogger.debug(_tag, 'Getting local achievement changes since: $since');
    return [];
  }

  /// Upload user level to server
  Future<void> _uploadUserLevel() async {
    AppLogger.debug(_tag, 'Uploading user level');

    // TODO: Get current user level and XP from local storage
    final currentUser = await _getCurrentUser();

    if (currentUser != null) {
      await _syncService.addSyncChange(
        dataType: SyncDataType.userLevel,
        operation: SyncOperation.update,
        localId: currentUser.id,
        remoteId: currentUser.id, // User ID is same for local and remote
        payload: {
          'level': currentUser.level,
          'total_xp': currentUser.totalXp,
          'daily_goal_ml': currentUser.dailyGoalMl,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  /// Upload achievement to server
  Future<void> _uploadAchievement(Map<String, dynamic> achievement) async {
    final achievementId = achievement['id'] as String;
    AppLogger.debug(_tag, 'Uploading achievement $achievementId');

    await _syncService.addSyncChange(
      dataType: SyncDataType.achievement,
      operation: achievement['is_new'] == true
          ? SyncOperation.create
          : SyncOperation.update,
      localId: achievementId,
      remoteId: achievement['remote_id'],
      payload: {
        'achievement_id': achievement['achievement_id'],
        'title': achievement['title'],
        'description': achievement['description'],
        'type': achievement['type'],
        'rarity': achievement['rarity'],
        'required_value': achievement['required_value'],
        'current_value': achievement['current_value'],
        'xp_reward': achievement['xp_reward'],
        'is_unlocked': achievement['is_unlocked'],
        'is_claimed': achievement['is_claimed'],
        'unlocked_at': achievement['unlocked_at'],
        'claimed_at': achievement['claimed_at'],
        'progress_percentage': achievement['progress_percentage'],
      },
    );
  }

  /// Download remote user level changes
  Future<Map<String, dynamic>?> _downloadRemoteUserLevel({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call to fetch remote user level
    AppLogger.debug(
      _tag,
      'Downloading remote user level changes since: $since',
    );

    // Mock API response
    await Future.delayed(const Duration(milliseconds: 200));
    return null; // No changes for now
  }

  /// Download remote achievement changes
  Future<List<Map<String, dynamic>>> _downloadRemoteAchievements({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call to fetch remote achievements
    AppLogger.debug(
      _tag,
      'Downloading remote achievement changes since: $since',
    );

    // Mock API response
    await Future.delayed(const Duration(milliseconds: 300));
    return [];
  }

  /// Process remote user level change
  Future<void> _processRemoteUserLevel(Map<String, dynamic> remoteData) async {
    AppLogger.debug(_tag, 'Processing remote user level update');

    try {
      // Get current local user
      final currentUser = await _getCurrentUser();

      if (currentUser != null) {
        // Check for conflicts
        final localData = {
          'level': currentUser.level,
          'total_xp': currentUser.totalXp,
          'daily_goal_ml': currentUser.dailyGoalMl,
          'updated_at': currentUser.lastActiveAt?.toIso8601String(),
        };

        if (_conflictResolver.hasConflict(localData, remoteData)) {
          // Handle conflict - for user level, usually take the higher values
          await _handleUserLevelConflict(currentUser, remoteData);
        } else {
          // No conflict, apply remote changes
          await _applyRemoteUserLevelUpdate(remoteData);
        }
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process remote user level', e);
      rethrow;
    }
  }

  /// Process remote achievement change
  Future<void> _processRemoteAchievement(
    Map<String, dynamic> remoteData,
  ) async {
    final achievementId = remoteData['id'] as String;
    AppLogger.debug(_tag, 'Processing remote achievement $achievementId');

    try {
      // Check if we have this achievement locally
      final existingAchievement = await _getLocalAchievementById(achievementId);

      if (existingAchievement != null) {
        // Update existing achievement, check for conflicts
        if (_conflictResolver.hasConflict(existingAchievement, remoteData)) {
          // Handle conflict
          await _handleAchievementConflict(existingAchievement, remoteData);
        } else {
          // No conflict, apply remote changes
          await _applyRemoteAchievementUpdate(existingAchievement, remoteData);
        }
      } else {
        // New remote achievement, create locally
        await _createLocalAchievementFromRemote(remoteData);
      }
    } catch (e) {
      AppLogger.error(
        _tag,
        'Failed to process remote achievement $achievementId',
        e,
      );
      rethrow;
    }
  }

  /// Handle user level conflict
  Future<void> _handleUserLevelConflict(
    User localUser,
    Map<String, dynamic> remoteData,
  ) async {
    AppLogger.info(_tag, 'Handling user level conflict for ${localUser.id}');

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.userLevel,
      localId: localUser.id,
      remoteId: localUser.id,
      localData: {
        'level': localUser.level,
        'total_xp': localUser.totalXp,
        'daily_goal_ml': localUser.dailyGoalMl,
        'updated_at': localUser.lastActiveAt?.toIso8601String(),
      },
      remoteData: remoteData,
      createdAt: DateTime.now(),
      suggestedStrategy:
          ConflictResolutionStrategy.merge, // Merge for user level is good
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedUserLevelData(resolution.resolvedData!);
      AppLogger.info(
        _tag,
        'User level conflict resolved: ${resolution.message}',
      );
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve user level conflict: ${resolution.message}',
      );
    }
  }

  /// Handle achievement conflict
  Future<void> _handleAchievementConflict(
    Map<String, dynamic> localAchievement,
    Map<String, dynamic> remoteData,
  ) async {
    final achievementId = localAchievement['id'] as String;
    AppLogger.info(_tag, 'Handling achievement conflict for $achievementId');

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.achievement,
      localId: achievementId,
      remoteId: remoteData['id'] as String,
      localData: localAchievement,
      remoteData: remoteData,
      createdAt: DateTime.now(),
      suggestedStrategy:
          ConflictResolutionStrategy.serverWins, // Server wins for achievements
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedAchievementData(
        achievementId,
        resolution.resolvedData!,
      );
      AppLogger.info(
        _tag,
        'Achievement conflict resolved: ${resolution.message}',
      );
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve achievement conflict: ${resolution.message}',
      );
    }
  }

  /// Get current user from local storage
  Future<User?> _getCurrentUser() async {
    // TODO: Implement actual local user storage access
    AppLogger.debug(_tag, 'Getting current user from local storage');
    return null; // Placeholder
  }

  /// Get local achievement by ID
  Future<Map<String, dynamic>?> _getLocalAchievementById(
    String achievementId,
  ) async {
    // TODO: Implement local achievement lookup
    AppLogger.debug(_tag, 'Getting local achievement $achievementId');
    return null; // Placeholder
  }

  /// Apply remote user level update without conflict
  Future<void> _applyRemoteUserLevelUpdate(
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Update local user with remote data
    AppLogger.debug(_tag, 'Applying remote user level update');
  }

  /// Apply remote achievement update without conflict
  Future<void> _applyRemoteAchievementUpdate(
    Map<String, dynamic> localAchievement,
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Update local achievement with remote data
    AppLogger.debug(_tag, 'Applying remote achievement update');
  }

  /// Create local achievement from remote data
  Future<void> _createLocalAchievementFromRemote(
    Map<String, dynamic> remoteData,
  ) async {
    // TODO: Create new achievement from remote data
    AppLogger.debug(_tag, 'Creating local achievement from remote data');
  }

  /// Apply resolved conflict data to user level
  Future<void> _applyResolvedUserLevelData(
    Map<String, dynamic> resolvedData,
  ) async {
    // TODO: Apply resolved conflict data to local user
    AppLogger.debug(_tag, 'Applying resolved user level data');
  }

  /// Apply resolved conflict data to achievement
  Future<void> _applyResolvedAchievementData(
    String achievementId,
    Map<String, dynamic> resolvedData,
  ) async {
    // TODO: Apply resolved conflict data to local achievement
    AppLogger.debug(
      _tag,
      'Applying resolved achievement data for $achievementId',
    );
  }

  /// Get sync statistics for level system
  Future<Map<String, dynamic>> getLevelSyncStats() async {
    final userLevelStats = await _syncService.getSyncStats(
      dataType: SyncDataType.userLevel,
    );
    final achievementStats = await _syncService.getSyncStats(
      dataType: SyncDataType.achievement,
    );

    return {
      'user_level': userLevelStats,
      'achievements': achievementStats,
      'combined_success_rate': _calculateCombinedSuccessRate([
        userLevelStats,
        achievementStats,
      ]),
    };
  }

  /// Calculate combined success rate
  double _calculateCombinedSuccessRate(List<Map<String, dynamic>> statsList) {
    int totalSyncs = 0;
    int totalSuccessful = 0;

    for (final stats in statsList) {
      totalSyncs += stats['total_syncs'] as int? ?? 0;
      totalSuccessful += stats['successful_syncs'] as int? ?? 0;
    }

    return totalSyncs > 0 ? (totalSuccessful / totalSyncs) * 100 : 0.0;
  }
}

/// Result of a level system sync operation
class LevelSyncResult {
  final bool success;
  final SyncDataType dataType;
  final int uploadedCount;
  final int downloadedCount;
  final Duration duration;
  final List<String> errors;
  final String? error;

  const LevelSyncResult._({
    required this.success,
    required this.dataType,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    required this.duration,
    this.errors = const [],
    this.error,
  });

  factory LevelSyncResult.success({
    required SyncDataType dataType,
    int uploadedCount = 0,
    int downloadedCount = 0,
    required Duration duration,
    List<String> errors = const [],
  }) {
    return LevelSyncResult._(
      success: true,
      dataType: dataType,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      duration: duration,
      errors: errors,
    );
  }

  factory LevelSyncResult.error({
    required SyncDataType dataType,
    required String error,
    required Duration duration,
  }) {
    return LevelSyncResult._(
      success: false,
      dataType: dataType,
      duration: duration,
      error: error,
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  int get totalProcessed => uploadedCount + downloadedCount;
}
