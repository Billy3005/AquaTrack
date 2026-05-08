import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'sync_models.dart';

/// Local storage for sync metadata and pending changes
class SyncStorage {
  static const String _keyPrefix = 'sync_';
  static const String _pendingChangesKey = '${_keyPrefix}pending_changes';
  static const String _conflictsKey = '${_keyPrefix}conflicts';
  static const String _lastSyncKey = '${_keyPrefix}last_sync';
  static const String _syncStateKey = '${_keyPrefix}state';

  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  SyncStorage(this._prefs);

  /// Add a pending change to sync queue
  Future<void> addPendingChange({
    required SyncDataType dataType,
    required SyncOperation operation,
    required String localId,
    String? remoteId,
    required Map<String, dynamic> payload,
  }) async {
    final change = SyncMetadata(
      id: _uuid.v4(),
      dataType: dataType,
      operation: operation,
      localId: localId,
      remoteId: remoteId,
      payload: payload,
      createdAt: DateTime.now(),
    );

    final pendingChanges = await getPendingChanges();
    pendingChanges.add(change);

    final jsonList = pendingChanges.map((c) => c.toJson()).toList();
    await _prefs.setString(_pendingChangesKey, jsonEncode(jsonList));
  }

  /// Get all pending changes
  Future<List<SyncMetadata>> getPendingChanges() async {
    final jsonString = _prefs.getString(_pendingChangesKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SyncMetadata.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // If parsing fails, clear corrupted data
      await _prefs.remove(_pendingChangesKey);
      return [];
    }
  }

  /// Get pending changes by data type
  Future<List<SyncMetadata>> getPendingChangesByType(
    SyncDataType dataType,
  ) async {
    final allChanges = await getPendingChanges();
    return allChanges.where((change) => change.dataType == dataType).toList();
  }

  /// Update a pending change (e.g., after sync attempt)
  Future<void> updatePendingChange(SyncMetadata updatedChange) async {
    final pendingChanges = await getPendingChanges();
    final index = pendingChanges.indexWhere((c) => c.id == updatedChange.id);

    if (index != -1) {
      pendingChanges[index] = updatedChange;
      final jsonList = pendingChanges.map((c) => c.toJson()).toList();
      await _prefs.setString(_pendingChangesKey, jsonEncode(jsonList));
    }
  }

  /// Remove a pending change (after successful sync)
  Future<void> removePendingChange(String changeId) async {
    final pendingChanges = await getPendingChanges();
    pendingChanges.removeWhere((change) => change.id == changeId);

    final jsonList = pendingChanges.map((c) => c.toJson()).toList();
    await _prefs.setString(_pendingChangesKey, jsonEncode(jsonList));
  }

  /// Clear all pending changes (for full resync)
  Future<void> clearPendingChanges() async {
    await _prefs.remove(_pendingChangesKey);
  }

  /// Add a sync conflict
  Future<void> addConflict(SyncConflict conflict) async {
    final conflicts = await getConflicts();
    conflicts.add(conflict);

    final jsonList = conflicts.map((c) => c.toJson()).toList();
    await _prefs.setString(_conflictsKey, jsonEncode(jsonList));
  }

  /// Get all unresolved conflicts
  Future<List<SyncConflict>> getConflicts() async {
    final jsonString = _prefs.getString(_conflictsKey);
    if (jsonString == null) return [];

    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => SyncConflict.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await _prefs.remove(_conflictsKey);
      return [];
    }
  }

  /// Remove a resolved conflict
  Future<void> removeConflict(String conflictId) async {
    final conflicts = await getConflicts();
    conflicts.removeWhere((conflict) => conflict.id == conflictId);

    final jsonList = conflicts.map((c) => c.toJson()).toList();
    await _prefs.setString(_conflictsKey, jsonEncode(jsonList));
  }

  /// Set last sync time for a data type
  Future<void> setLastSyncTime(
    SyncDataType dataType,
    DateTime timestamp,
  ) async {
    final key = '${_lastSyncKey}_${dataType.name}';
    await _prefs.setInt(key, timestamp.millisecondsSinceEpoch);
  }

  /// Get last sync time for a data type
  Future<DateTime?> getLastSyncTime(SyncDataType dataType) async {
    final key = '${_lastSyncKey}_${dataType.name}';
    final timestamp = _prefs.getInt(key);
    return timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : null;
  }

  /// Set global sync state
  Future<void> setSyncState(SyncState state) async {
    final json = {
      'status': state.status.name,
      'last_sync_time': state.lastSyncTime?.millisecondsSinceEpoch,
      'pending_changes': state.pendingChanges,
      'conflict_count': state.conflictCount,
      'last_sync_by_type': state.lastSyncByType.map(
        (key, value) => MapEntry(key.name, value.millisecondsSinceEpoch),
      ),
      'current_error': state.currentError,
    };

    await _prefs.setString(_syncStateKey, jsonEncode(json));
  }

  /// Get global sync state
  Future<SyncState> getSyncState() async {
    final jsonString = _prefs.getString(_syncStateKey);
    if (jsonString == null) return const SyncState();

    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;

      final lastSyncByType = <SyncDataType, DateTime>{};
      final lastSyncByTypeJson =
          json['last_sync_by_type'] as Map<String, dynamic>?;

      if (lastSyncByTypeJson != null) {
        for (final entry in lastSyncByTypeJson.entries) {
          try {
            final dataType = SyncDataType.values.firstWhere(
              (e) => e.name == entry.key,
            );
            final timestamp = DateTime.fromMillisecondsSinceEpoch(
              entry.value as int,
            );
            lastSyncByType[dataType] = timestamp;
          } catch (e) {
            // Skip invalid entries
          }
        }
      }

      return SyncState(
        status: SyncStatus.values.firstWhere(
          (e) => e.name == json['status'],
          orElse: () => SyncStatus.idle,
        ),
        lastSyncTime: json['last_sync_time'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['last_sync_time'] as int)
            : null,
        pendingChanges: json['pending_changes'] ?? 0,
        conflictCount: json['conflict_count'] ?? 0,
        lastSyncByType: lastSyncByType,
        currentError: json['current_error'],
      );
    } catch (e) {
      // Return default state if parsing fails
      return const SyncState();
    }
  }

  /// Clear all sync data (for reset)
  Future<void> clearAll() async {
    final keys = _prefs.getKeys().where((key) => key.startsWith(_keyPrefix));
    for (final key in keys) {
      await _prefs.remove(key);
    }
  }

  /// Get storage statistics
  Future<Map<String, int>> getStorageStats() async {
    final pendingChanges = await getPendingChanges();
    final conflicts = await getConflicts();

    final statsByType = <String, int>{};
    for (final dataType in SyncDataType.values) {
      final count = pendingChanges.where((c) => c.dataType == dataType).length;
      statsByType['pending_${dataType.name}'] = count;
    }

    return {
      'total_pending': pendingChanges.length,
      'total_conflicts': conflicts.length,
      ...statsByType,
    };
  }
}
