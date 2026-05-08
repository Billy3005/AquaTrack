import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'sync_models.dart';

/// SQLite database for sync tracking
class SyncDatabase {
  static const String _databaseName = 'aquatrack_sync.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _syncMetadataTable = 'sync_metadata';
  static const String _syncConflictsTable = 'sync_conflicts';
  static const String _syncStatsTable = 'sync_stats';

  Database? _database;

  /// Get database instance (singleton pattern)
  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  Future<void> _onCreate(Database db, int version) async {
    // Sync metadata table for tracking pending changes
    await db.execute('''
      CREATE TABLE $_syncMetadataTable (
        id TEXT PRIMARY KEY,
        data_type TEXT NOT NULL,
        operation TEXT NOT NULL,
        local_id TEXT NOT NULL,
        remote_id TEXT,
        payload TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_sync_attempt INTEGER,
        retry_count INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'idle',
        error TEXT
      )
    ''');

    // Sync conflicts table for manual resolution
    await db.execute('''
      CREATE TABLE $_syncConflictsTable (
        id TEXT PRIMARY KEY,
        data_type TEXT NOT NULL,
        local_id TEXT NOT NULL,
        remote_id TEXT NOT NULL,
        local_data TEXT NOT NULL,
        remote_data TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        suggested_strategy TEXT NOT NULL
      )
    ''');

    // Sync statistics table for tracking sync history
    await db.execute('''
      CREATE TABLE $_syncStatsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        data_type TEXT NOT NULL,
        operation TEXT NOT NULL,
        status TEXT NOT NULL,
        sync_time INTEGER NOT NULL,
        duration_ms INTEGER,
        error TEXT,
        records_synced INTEGER DEFAULT 0
      )
    ''');

    // Create indexes for better performance
    await db.execute('''
      CREATE INDEX idx_sync_metadata_status ON $_syncMetadataTable(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_metadata_data_type ON $_syncMetadataTable(data_type)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_metadata_local_id ON $_syncMetadataTable(local_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_conflicts_data_type ON $_syncConflictsTable(data_type)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_stats_data_type ON $_syncStatsTable(data_type)
    ''');

    await db.execute('''
      CREATE INDEX idx_sync_stats_sync_time ON $_syncStatsTable(sync_time)
    ''');
  }

  /// Handle database upgrades
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database migrations here when version changes
    if (oldVersion < newVersion) {
      // Add migration logic for future versions
    }
  }

  /// Insert or update sync metadata
  Future<void> upsertSyncMetadata(SyncMetadata metadata) async {
    final db = await database;

    await db.insert(_syncMetadataTable, {
      'id': metadata.id,
      'data_type': metadata.dataType.name,
      'operation': metadata.operation.name,
      'local_id': metadata.localId,
      'remote_id': metadata.remoteId,
      'payload': metadata.payload.toString(),
      'created_at': metadata.createdAt.millisecondsSinceEpoch,
      'last_sync_attempt': metadata.lastSyncAttempt?.millisecondsSinceEpoch,
      'retry_count': metadata.retryCount,
      'status': metadata.status.name,
      'error': metadata.error,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Get pending sync metadata
  Future<List<SyncMetadata>> getPendingSyncMetadata({
    SyncDataType? dataType,
    int? limit,
  }) async {
    final db = await database;

    String whereClause = "status IN ('idle', 'failed')";
    List<dynamic> whereArgs = [];

    if (dataType != null) {
      whereClause += " AND data_type = ?";
      whereArgs.add(dataType.name);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _syncMetadataTable,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return SyncMetadata(
        id: map['id'],
        dataType: SyncDataType.values.firstWhere(
          (e) => e.name == map['data_type'],
        ),
        operation: SyncOperation.values.firstWhere(
          (e) => e.name == map['operation'],
        ),
        localId: map['local_id'],
        remoteId: map['remote_id'],
        payload: _parsePayload(map['payload']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
        lastSyncAttempt: map['last_sync_attempt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(map['last_sync_attempt'])
            : null,
        retryCount: map['retry_count'],
        status: SyncStatus.values.firstWhere((e) => e.name == map['status']),
        error: map['error'],
      );
    });
  }

  /// Update sync metadata status
  Future<void> updateSyncMetadataStatus(
    String id,
    SyncStatus status, {
    String? error,
    String? remoteId,
  }) async {
    final db = await database;

    await db.update(
      _syncMetadataTable,
      {
        'status': status.name,
        'last_sync_attempt': DateTime.now().millisecondsSinceEpoch,
        'retry_count': status == SyncStatus.failed
            ? await _getRetryCount(id) + 1
            : await _getRetryCount(id),
        if (error != null) 'error': error,
        if (remoteId != null) 'remote_id': remoteId,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete sync metadata
  Future<void> deleteSyncMetadata(String id) async {
    final db = await database;
    await db.delete(_syncMetadataTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Insert sync conflict
  Future<void> insertSyncConflict(SyncConflict conflict) async {
    final db = await database;

    await db.insert(_syncConflictsTable, {
      'id': conflict.id,
      'data_type': conflict.dataType.name,
      'local_id': conflict.localId,
      'remote_id': conflict.remoteId,
      'local_data': conflict.localData.toString(),
      'remote_data': conflict.remoteData.toString(),
      'created_at': conflict.createdAt.millisecondsSinceEpoch,
      'suggested_strategy': conflict.suggestedStrategy.name,
    });
  }

  /// Get all sync conflicts
  Future<List<SyncConflict>> getSyncConflicts({SyncDataType? dataType}) async {
    final db = await database;

    String? whereClause;
    List<dynamic>? whereArgs;

    if (dataType != null) {
      whereClause = 'data_type = ?';
      whereArgs = [dataType.name];
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _syncConflictsTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return SyncConflict(
        id: map['id'],
        dataType: SyncDataType.values.firstWhere(
          (e) => e.name == map['data_type'],
        ),
        localId: map['local_id'],
        remoteId: map['remote_id'],
        localData: _parsePayload(map['local_data']),
        remoteData: _parsePayload(map['remote_data']),
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
        suggestedStrategy: ConflictResolutionStrategy.values.firstWhere(
          (e) => e.name == map['suggested_strategy'],
        ),
      );
    });
  }

  /// Delete sync conflict
  Future<void> deleteSyncConflict(String id) async {
    final db = await database;
    await db.delete(_syncConflictsTable, where: 'id = ?', whereArgs: [id]);
  }

  /// Record sync statistics
  Future<void> recordSyncStats({
    required SyncDataType dataType,
    required SyncOperation operation,
    required SyncStatus status,
    required Duration duration,
    int recordsSynced = 0,
    String? error,
  }) async {
    final db = await database;

    await db.insert(_syncStatsTable, {
      'data_type': dataType.name,
      'operation': operation.name,
      'status': status.name,
      'sync_time': DateTime.now().millisecondsSinceEpoch,
      'duration_ms': duration.inMilliseconds,
      'error': error,
      'records_synced': recordsSynced,
    });
  }

  /// Get sync statistics
  Future<Map<String, dynamic>> getSyncStats({
    SyncDataType? dataType,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    final db = await database;

    String whereClause = '1=1';
    List<dynamic> whereArgs = [];

    if (dataType != null) {
      whereClause += ' AND data_type = ?';
      whereArgs.add(dataType.name);
    }

    if (fromDate != null) {
      whereClause += ' AND sync_time >= ?';
      whereArgs.add(fromDate.millisecondsSinceEpoch);
    }

    if (toDate != null) {
      whereClause += ' AND sync_time <= ?';
      whereArgs.add(toDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _syncStatsTable,
      where: whereClause,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
    );

    // Calculate statistics
    int totalSyncs = maps.length;
    int successfulSyncs = maps.where((m) => m['status'] == 'success').length;
    int failedSyncs = maps.where((m) => m['status'] == 'failed').length;
    int totalRecords = maps.fold(
      0,
      (sum, m) => sum + (m['records_synced'] as int),
    );

    double averageDuration = maps.isNotEmpty
        ? maps.fold(0.0, (sum, m) => sum + (m['duration_ms'] as int)) /
              maps.length
        : 0.0;

    return {
      'total_syncs': totalSyncs,
      'successful_syncs': successfulSyncs,
      'failed_syncs': failedSyncs,
      'success_rate': totalSyncs > 0
          ? (successfulSyncs / totalSyncs) * 100
          : 0.0,
      'total_records_synced': totalRecords,
      'average_duration_ms': averageDuration,
    };
  }

  /// Clear old sync statistics (cleanup)
  Future<void> clearOldSyncStats(DateTime beforeDate) async {
    final db = await database;
    await db.delete(
      _syncStatsTable,
      where: 'sync_time < ?',
      whereArgs: [beforeDate.millisecondsSinceEpoch],
    );
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  /// Helper method to get current retry count
  Future<int> _getRetryCount(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _syncMetadataTable,
      columns: ['retry_count'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    return maps.isNotEmpty ? maps.first['retry_count'] : 0;
  }

  /// Parse payload string back to Map
  Map<String, dynamic> _parsePayload(String payloadString) {
    try {
      // For now, return empty map. In production, you'd want proper JSON parsing
      return <String, dynamic>{};
    } catch (e) {
      return <String, dynamic>{};
    }
  }
}
