import '../utils/logger.dart';
import 'sync_models.dart';
import 'sync_database.dart';

/// Handles conflict resolution between local and remote data
class ConflictResolver {
  static const String _tag = 'ConflictResolver';

  final SyncDatabase _syncDatabase;

  ConflictResolver({required SyncDatabase syncDatabase})
      : _syncDatabase = syncDatabase;

  /// Resolve a conflict using the specified strategy
  Future<ConflictResolutionResult> resolveConflict({
    required SyncConflict conflict,
    ConflictResolutionStrategy? overrideStrategy,
    Map<String, dynamic>? manualResolution,
  }) async {
    AppLogger.info(
      _tag,
      'Resolving conflict ${conflict.id} with strategy ${overrideStrategy ?? conflict.suggestedStrategy}',
    );

    final strategy = overrideStrategy ?? conflict.suggestedStrategy;

    try {
      late Map<String, dynamic> resolvedData;
      late ConflictResolutionResult result;

      switch (strategy) {
        case ConflictResolutionStrategy.clientWins:
          resolvedData = conflict.localData;
          result = ConflictResolutionResult.success(
            resolvedData: resolvedData,
            strategy: strategy,
            message: 'Local data preserved',
          );
          break;

        case ConflictResolutionStrategy.serverWins:
          resolvedData = conflict.remoteData;
          result = ConflictResolutionResult.success(
            resolvedData: resolvedData,
            strategy: strategy,
            message: 'Remote data accepted',
          );
          break;

        case ConflictResolutionStrategy.lastWriteWins:
          result = await _resolveByTimestamp(conflict);
          break;

        case ConflictResolutionStrategy.merge:
          result = await _attemptMerge(conflict);
          break;

        case ConflictResolutionStrategy.manual:
          if (manualResolution != null) {
            result = ConflictResolutionResult.success(
              resolvedData: manualResolution,
              strategy: strategy,
              message: 'Manually resolved by user',
            );
          } else {
            result = ConflictResolutionResult.requiresManualResolution(
              conflict: conflict,
              message: 'Manual resolution required',
            );
          }
          break;
      }

      // If resolution was successful, clean up the conflict
      if (result.success) {
        await _syncDatabase.deleteSyncConflict(conflict.id);
        AppLogger.info(_tag, 'Conflict ${conflict.id} resolved successfully');
      }

      return result;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to resolve conflict ${conflict.id}', e);
      return ConflictResolutionResult.error(
        error: e.toString(),
        message: 'Error during conflict resolution',
      );
    }
  }

  /// Resolve conflict by comparing timestamps
  Future<ConflictResolutionResult> _resolveByTimestamp(
    SyncConflict conflict,
  ) async {
    try {
      final localTimestamp = _extractTimestamp(conflict.localData);
      final remoteTimestamp = _extractTimestamp(conflict.remoteData);

      if (localTimestamp == null && remoteTimestamp == null) {
        // No timestamps available, fallback to client wins
        return ConflictResolutionResult.success(
          resolvedData: conflict.localData,
          strategy: ConflictResolutionStrategy.clientWins,
          message: 'No timestamps found, defaulted to local data',
        );
      }

      if (localTimestamp == null) {
        return ConflictResolutionResult.success(
          resolvedData: conflict.remoteData,
          strategy: ConflictResolutionStrategy.serverWins,
          message: 'Local timestamp missing, used remote data',
        );
      }

      if (remoteTimestamp == null) {
        return ConflictResolutionResult.success(
          resolvedData: conflict.localData,
          strategy: ConflictResolutionStrategy.clientWins,
          message: 'Remote timestamp missing, used local data',
        );
      }

      // Compare timestamps
      if (localTimestamp.isAfter(remoteTimestamp)) {
        return ConflictResolutionResult.success(
          resolvedData: conflict.localData,
          strategy: ConflictResolutionStrategy.lastWriteWins,
          message: 'Local data is more recent',
        );
      } else {
        return ConflictResolutionResult.success(
          resolvedData: conflict.remoteData,
          strategy: ConflictResolutionStrategy.lastWriteWins,
          message: 'Remote data is more recent',
        );
      }
    } catch (e) {
      AppLogger.error(_tag, 'Error comparing timestamps', e);
      return ConflictResolutionResult.error(
        error: e.toString(),
        message: 'Failed to compare timestamps',
      );
    }
  }

  /// Attempt to merge local and remote data
  Future<ConflictResolutionResult> _attemptMerge(SyncConflict conflict) async {
    try {
      final mergedData = <String, dynamic>{};

      // Start with base data
      mergedData.addAll(conflict.remoteData);

      // Add non-conflicting local changes
      for (final entry in conflict.localData.entries) {
        final key = entry.key;
        final localValue = entry.value;
        final remoteValue = conflict.remoteData[key];

        if (remoteValue == null) {
          // Key only exists locally, add it
          mergedData[key] = localValue;
        } else if (_canMergeValues(localValue, remoteValue)) {
          // Attempt to merge values
          final mergedValue = _mergeValues(key, localValue, remoteValue);
          if (mergedValue != null) {
            mergedData[key] = mergedValue;
          }
        }
        // If values conflict and can't be merged, keep remote value
      }

      return ConflictResolutionResult.success(
        resolvedData: mergedData,
        strategy: ConflictResolutionStrategy.merge,
        message: 'Data merged successfully',
      );
    } catch (e) {
      AppLogger.error(_tag, 'Error merging data', e);

      // Fallback to last write wins if merge fails
      return await _resolveByTimestamp(conflict);
    }
  }

  /// Extract timestamp from data for comparison
  DateTime? _extractTimestamp(Map<String, dynamic> data) {
    // Try different timestamp field names
    final timestampFields = [
      'updated_at',
      'updatedAt',
      'modified_at',
      'modifiedAt',
      'timestamp',
      'created_at',
      'createdAt',
    ];

    for (final field in timestampFields) {
      if (data.containsKey(field)) {
        final value = data[field];
        try {
          if (value is String) {
            return DateTime.parse(value);
          } else if (value is int) {
            return DateTime.fromMillisecondsSinceEpoch(value);
          }
        } catch (e) {
          // Continue to next field if parsing fails
        }
      }
    }

    return null;
  }

  /// Check if two values can be merged
  bool _canMergeValues(dynamic local, dynamic remote) {
    // Only merge if both are numeric (for totals, counts, etc.)
    if (local is num && remote is num) {
      return true;
    }

    // Can merge lists by combining unique elements
    if (local is List && remote is List) {
      return true;
    }

    // Can merge maps recursively
    if (local is Map && remote is Map) {
      return true;
    }

    return false;
  }

  /// Merge two values intelligently
  dynamic _mergeValues(String key, dynamic local, dynamic remote) {
    try {
      // For numeric values, apply business logic based on field name
      if (local is num && remote is num) {
        return _mergeNumericValues(key, local, remote);
      }

      // For lists, combine and remove duplicates
      if (local is List && remote is List) {
        final merged = [...remote, ...local];
        return merged.toSet().toList(); // Remove duplicates
      }

      // For maps, merge recursively
      if (local is Map<String, dynamic> && remote is Map<String, dynamic>) {
        final merged = <String, dynamic>{};
        merged.addAll(remote);

        for (final entry in local.entries) {
          if (merged.containsKey(entry.key)) {
            if (_canMergeValues(entry.value, merged[entry.key])) {
              merged[entry.key] = _mergeValues(
                entry.key,
                entry.value,
                merged[entry.key],
              );
            }
            // Keep remote value if can't merge
          } else {
            merged[entry.key] = entry.value;
          }
        }

        return merged;
      }

      return null; // Can't merge
    } catch (e) {
      AppLogger.error(_tag, 'Error merging values for $key', e);
      return null;
    }
  }

  /// Merge numeric values based on business logic
  num _mergeNumericValues(String key, num local, num remote) {
    final lowerKey = key.toLowerCase();

    // For counts and totals, take the higher value
    if (lowerKey.contains('count') ||
        lowerKey.contains('total') ||
        lowerKey.contains('amount') ||
        lowerKey.contains('volume')) {
      return local > remote ? local : remote;
    }

    // For averages and percentages, take average
    if (lowerKey.contains('average') ||
        lowerKey.contains('avg') ||
        lowerKey.contains('percent') ||
        lowerKey.contains('rate')) {
      return (local + remote) / 2;
    }

    // For experience points and scores, take higher value
    if (lowerKey.contains('xp') ||
        lowerKey.contains('experience') ||
        lowerKey.contains('points') ||
        lowerKey.contains('score')) {
      return local > remote ? local : remote;
    }

    // Default: take the higher value for safety
    return local > remote ? local : remote;
  }

  /// Detect if there's a conflict between local and remote data
  bool hasConflict(
    Map<String, dynamic> localData,
    Map<String, dynamic> remoteData,
  ) {
    // Check if there are any differing values for the same keys
    for (final key in localData.keys) {
      if (remoteData.containsKey(key)) {
        final localValue = localData[key];
        final remoteValue = remoteData[key];

        if (!_areValuesEqual(localValue, remoteValue)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Deep equality check for values
  bool _areValuesEqual(dynamic value1, dynamic value2) {
    if (value1.runtimeType != value2.runtimeType) {
      return false;
    }

    if (value1 is Map && value2 is Map) {
      if (value1.length != value2.length) return false;

      for (final key in value1.keys) {
        if (!value2.containsKey(key)) return false;
        if (!_areValuesEqual(value1[key], value2[key])) return false;
      }
      return true;
    }

    if (value1 is List && value2 is List) {
      if (value1.length != value2.length) return false;

      for (int i = 0; i < value1.length; i++) {
        if (!_areValuesEqual(value1[i], value2[i])) return false;
      }
      return true;
    }

    return value1 == value2;
  }

  /// Get all pending conflicts
  Future<List<SyncConflict>> getPendingConflicts({
    SyncDataType? dataType,
  }) async {
    return await _syncDatabase.getSyncConflicts(dataType: dataType);
  }

  /// Batch resolve conflicts with same strategy
  Future<List<ConflictResolutionResult>> batchResolveConflicts({
    required List<SyncConflict> conflicts,
    required ConflictResolutionStrategy strategy,
  }) async {
    final results = <ConflictResolutionResult>[];

    for (final conflict in conflicts) {
      final result = await resolveConflict(
        conflict: conflict,
        overrideStrategy: strategy,
      );
      results.add(result);

      // Small delay to avoid overwhelming the system
      await Future.delayed(const Duration(milliseconds: 50));
    }

    return results;
  }
}

/// Result of conflict resolution
class ConflictResolutionResult {
  final bool success;
  final Map<String, dynamic>? resolvedData;
  final ConflictResolutionStrategy? strategy;
  final String message;
  final SyncConflict? requiresManualConflict;
  final String? error;

  const ConflictResolutionResult._({
    required this.success,
    this.resolvedData,
    this.strategy,
    required this.message,
    this.requiresManualConflict,
    this.error,
  });

  factory ConflictResolutionResult.success({
    required Map<String, dynamic> resolvedData,
    required ConflictResolutionStrategy strategy,
    required String message,
  }) {
    return ConflictResolutionResult._(
      success: true,
      resolvedData: resolvedData,
      strategy: strategy,
      message: message,
    );
  }

  factory ConflictResolutionResult.requiresManualResolution({
    required SyncConflict conflict,
    required String message,
  }) {
    return ConflictResolutionResult._(
      success: false,
      message: message,
      requiresManualConflict: conflict,
    );
  }

  factory ConflictResolutionResult.error({
    required String error,
    required String message,
  }) {
    return ConflictResolutionResult._(
      success: false,
      message: message,
      error: error,
    );
  }

  bool get requiresManualResolution => requiresManualConflict != null;
  bool get isError => error != null;
}
