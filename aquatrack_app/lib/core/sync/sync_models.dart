/// Sync status for tracking synchronization state
enum SyncStatus { idle, syncing, success, failed, conflict }

/// Sync operation type
enum SyncOperation { create, update, delete }

/// Data type being synced
enum SyncDataType {
  intakeLog,
  dailySummary,
  achievement,
  userLevel,
  bodyMapData,
  conversation,
  conversationSession,
}

/// Sync metadata for tracking synchronization
class SyncMetadata {
  final String id;
  final SyncDataType dataType;
  final SyncOperation operation;
  final String localId;
  final String? remoteId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final DateTime? lastSyncAttempt;
  final int retryCount;
  final SyncStatus status;
  final String? error;

  const SyncMetadata({
    required this.id,
    required this.dataType,
    required this.operation,
    required this.localId,
    this.remoteId,
    required this.payload,
    required this.createdAt,
    this.lastSyncAttempt,
    this.retryCount = 0,
    this.status = SyncStatus.idle,
    this.error,
  });

  SyncMetadata copyWith({
    String? id,
    SyncDataType? dataType,
    SyncOperation? operation,
    String? localId,
    String? remoteId,
    Map<String, dynamic>? payload,
    DateTime? createdAt,
    DateTime? lastSyncAttempt,
    int? retryCount,
    SyncStatus? status,
    String? error,
  }) {
    return SyncMetadata(
      id: id ?? this.id,
      dataType: dataType ?? this.dataType,
      operation: operation ?? this.operation,
      localId: localId ?? this.localId,
      remoteId: remoteId ?? this.remoteId,
      payload: payload ?? this.payload,
      createdAt: createdAt ?? this.createdAt,
      lastSyncAttempt: lastSyncAttempt ?? this.lastSyncAttempt,
      retryCount: retryCount ?? this.retryCount,
      status: status ?? this.status,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data_type': dataType.name,
      'operation': operation.name,
      'local_id': localId,
      'remote_id': remoteId,
      'payload': payload,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_sync_attempt': lastSyncAttempt?.millisecondsSinceEpoch,
      'retry_count': retryCount,
      'status': status.name,
      'error': error,
    };
  }

  factory SyncMetadata.fromJson(Map<String, dynamic> json) {
    return SyncMetadata(
      id: json['id'] ?? '',
      dataType: SyncDataType.values.firstWhere(
        (e) => e.name == json['data_type'],
        orElse: () => SyncDataType.intakeLog,
      ),
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == json['operation'],
        orElse: () => SyncOperation.create,
      ),
      localId: json['local_id'] ?? '',
      remoteId: json['remote_id'],
      payload: Map<String, dynamic>.from(json['payload'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      lastSyncAttempt: json['last_sync_attempt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['last_sync_attempt'])
          : null,
      retryCount: json['retry_count'] ?? 0,
      status: SyncStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => SyncStatus.idle,
      ),
      error: json['error'],
    );
  }
}

/// Sync configuration per data type
class SyncConfig {
  final SyncDataType dataType;
  final Duration syncInterval;
  final int maxRetries;
  final Duration retryBackoffBase;
  final bool enableConflictResolution;
  final ConflictResolutionStrategy conflictStrategy;

  const SyncConfig({
    required this.dataType,
    this.syncInterval = const Duration(minutes: 5),
    this.maxRetries = 3,
    this.retryBackoffBase = const Duration(seconds: 2),
    this.enableConflictResolution = true,
    this.conflictStrategy = ConflictResolutionStrategy.clientWins,
  });
}

/// Conflict resolution strategies
enum ConflictResolutionStrategy {
  clientWins, // Local data takes precedence
  serverWins, // Remote data takes precedence
  lastWriteWins, // Most recent timestamp wins
  merge, // Attempt to merge changes
  manual, // Require manual resolution
}

/// Conflict data for manual resolution
class SyncConflict {
  final String id;
  final SyncDataType dataType;
  final String localId;
  final String remoteId;
  final Map<String, dynamic> localData;
  final Map<String, dynamic> remoteData;
  final DateTime createdAt;
  final ConflictResolutionStrategy suggestedStrategy;

  const SyncConflict({
    required this.id,
    required this.dataType,
    required this.localId,
    required this.remoteId,
    required this.localData,
    required this.remoteData,
    required this.createdAt,
    this.suggestedStrategy = ConflictResolutionStrategy.lastWriteWins,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'data_type': dataType.name,
      'local_id': localId,
      'remote_id': remoteId,
      'local_data': localData,
      'remote_data': remoteData,
      'created_at': createdAt.millisecondsSinceEpoch,
      'suggested_strategy': suggestedStrategy.name,
    };
  }

  factory SyncConflict.fromJson(Map<String, dynamic> json) {
    return SyncConflict(
      id: json['id'] ?? '',
      dataType: SyncDataType.values.firstWhere(
        (e) => e.name == json['data_type'],
        orElse: () => SyncDataType.intakeLog,
      ),
      localId: json['local_id'] ?? '',
      remoteId: json['remote_id'] ?? '',
      localData: Map<String, dynamic>.from(json['local_data'] ?? {}),
      remoteData: Map<String, dynamic>.from(json['remote_data'] ?? {}),
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['created_at'] ?? 0),
      suggestedStrategy: ConflictResolutionStrategy.values.firstWhere(
        (e) => e.name == json['suggested_strategy'],
        orElse: () => ConflictResolutionStrategy.lastWriteWins,
      ),
    );
  }
}

/// Global sync state
class SyncState {
  final SyncStatus status;
  final DateTime? lastSyncTime;
  final int pendingChanges;
  final int conflictCount;
  final Map<SyncDataType, DateTime> lastSyncByType;
  final String? currentError;

  const SyncState({
    this.status = SyncStatus.idle,
    this.lastSyncTime,
    this.pendingChanges = 0,
    this.conflictCount = 0,
    this.lastSyncByType = const {},
    this.currentError,
  });

  SyncState copyWith({
    SyncStatus? status,
    DateTime? lastSyncTime,
    int? pendingChanges,
    int? conflictCount,
    Map<SyncDataType, DateTime>? lastSyncByType,
    String? currentError,
  }) {
    return SyncState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingChanges: pendingChanges ?? this.pendingChanges,
      conflictCount: conflictCount ?? this.conflictCount,
      lastSyncByType: lastSyncByType ?? this.lastSyncByType,
      currentError: currentError ?? this.currentError,
    );
  }
}
