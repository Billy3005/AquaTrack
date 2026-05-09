import 'package:uuid/uuid.dart';

import '../utils/logger.dart';
import 'sync_models.dart';
import 'sync_service.dart';
import 'conflict_resolver.dart';

/// Repository for syncing AI coach conversation data incrementally
class CoachConversationSyncRepository {
  static const String _tag = 'CoachConversationSyncRepository';

  final SyncService _syncService;
  final ConflictResolver _conflictResolver;
  final Uuid _uuid = const Uuid();

  CoachConversationSyncRepository({
    required SyncService syncService,
    required ConflictResolver conflictResolver,
  })  : _syncService = syncService,
        _conflictResolver = conflictResolver;

  /// Sync all conversation data (messages and sessions)
  Future<ConversationSyncResult> syncConversationData({DateTime? since}) async {
    AppLogger.info(_tag, 'Starting conversation sync');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Step 1: Sync conversation sessions
      final sessionsResult = await _syncConversationSessions(since: since);
      uploadedCount += sessionsResult.uploadedCount;
      downloadedCount += sessionsResult.downloadedCount;
      errors.addAll(sessionsResult.errors);

      // Step 2: Sync conversation messages
      final messagesResult = await _syncConversationMessages(since: since);
      uploadedCount += messagesResult.uploadedCount;
      downloadedCount += messagesResult.downloadedCount;
      errors.addAll(messagesResult.errors);

      // Step 3: Sync conversation context data
      final contextResult = await _syncConversationContext(since: since);
      uploadedCount += contextResult.uploadedCount;
      downloadedCount += contextResult.downloadedCount;
      errors.addAll(contextResult.errors);

      final duration = stopwatch.elapsed;
      AppLogger.info(
        _tag,
        'Conversation sync completed: $uploadedCount uploaded, $downloadedCount downloaded in ${duration.inMilliseconds}ms',
      );

      return ConversationSyncResult.success(
        dataType: SyncDataType.conversation,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: duration,
        errors: errors,
      );
    } catch (e) {
      AppLogger.error(_tag, 'Conversation sync failed', e);
      return ConversationSyncResult.error(
        dataType: SyncDataType.conversation,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sync conversation sessions (chat history organization)
  Future<ConversationSyncResult> _syncConversationSessions({
    DateTime? since,
  }) async {
    AppLogger.debug(_tag, 'Syncing conversation sessions');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Upload local session changes
      final localSessions = await _getLocalConversationSessionChanges(
        since: since,
      );
      for (final session in localSessions) {
        try {
          await _uploadConversationSession(session);
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload session ${session['session_id']}: $e');
          AppLogger.error(_tag, 'Failed to upload session', e);
        }
      }

      // Download remote session changes
      final remoteSessions = await _downloadRemoteConversationSessions(
        since: since,
      );
      for (final remoteSession in remoteSessions) {
        try {
          await _processRemoteConversationSession(remoteSession);
          downloadedCount++;
        } catch (e) {
          errors.add(
            'Failed to process remote session ${remoteSession['session_id']}: $e',
          );
          AppLogger.error(_tag, 'Failed to process remote session', e);
        }
      }

      return ConversationSyncResult.success(
        dataType: SyncDataType.conversationSession,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: stopwatch.elapsed,
        errors: errors,
      );
    } catch (e) {
      return ConversationSyncResult.error(
        dataType: SyncDataType.conversationSession,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sync conversation messages (user and AI messages)
  Future<ConversationSyncResult> _syncConversationMessages({
    DateTime? since,
  }) async {
    AppLogger.debug(_tag, 'Syncing conversation messages');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Upload local message changes
      final localMessages = await _getLocalConversationMessageChanges(
        since: since,
      );
      for (final message in localMessages) {
        try {
          await _uploadConversationMessage(message);
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload message ${message['id']}: $e');
          AppLogger.error(_tag, 'Failed to upload message', e);
        }
      }

      // Download remote message changes
      final remoteMessages = await _downloadRemoteConversationMessages(
        since: since,
      );
      for (final remoteMessage in remoteMessages) {
        try {
          await _processRemoteConversationMessage(remoteMessage);
          downloadedCount++;
        } catch (e) {
          errors.add(
            'Failed to process remote message ${remoteMessage['message_id']}: $e',
          );
          AppLogger.error(_tag, 'Failed to process remote message', e);
        }
      }

      return ConversationSyncResult.success(
        dataType: SyncDataType.conversation,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: stopwatch.elapsed,
        errors: errors,
      );
    } catch (e) {
      return ConversationSyncResult.error(
        dataType: SyncDataType.conversation,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Sync conversation context and quick replies
  Future<ConversationSyncResult> _syncConversationContext({
    DateTime? since,
  }) async {
    AppLogger.debug(_tag, 'Syncing conversation context');

    final stopwatch = Stopwatch()..start();
    int uploadedCount = 0;
    int downloadedCount = 0;
    final errors = <String>[];

    try {
      // Upload local context changes
      final localContexts = await _getLocalConversationContextChanges(
        since: since,
      );
      for (final context in localContexts) {
        try {
          await _uploadConversationContext(context);
          uploadedCount++;
        } catch (e) {
          errors.add('Failed to upload context ${context['id']}: $e');
          AppLogger.error(_tag, 'Failed to upload context', e);
        }
      }

      // Download remote context changes
      final remoteContexts = await _downloadRemoteConversationContexts(
        since: since,
      );
      for (final remoteContext in remoteContexts) {
        try {
          await _processRemoteConversationContext(remoteContext);
          downloadedCount++;
        } catch (e) {
          errors.add(
            'Failed to process remote context ${remoteContext['id']}: $e',
          );
          AppLogger.error(_tag, 'Failed to process remote context', e);
        }
      }

      return ConversationSyncResult.success(
        dataType: SyncDataType.conversation,
        uploadedCount: uploadedCount,
        downloadedCount: downloadedCount,
        duration: stopwatch.elapsed,
        errors: errors,
      );
    } catch (e) {
      return ConversationSyncResult.error(
        dataType: SyncDataType.conversation,
        error: e.toString(),
        duration: stopwatch.elapsed,
      );
    }
  }

  /// Get local conversation session changes
  Future<List<Map<String, dynamic>>> _getLocalConversationSessionChanges({
    DateTime? since,
  }) async {
    // TODO: Implement local session storage access
    AppLogger.debug(
      _tag,
      'Getting local conversation session changes since: $since',
    );
    return []; // Placeholder
  }

  /// Get local conversation message changes
  Future<List<Map<String, dynamic>>> _getLocalConversationMessageChanges({
    DateTime? since,
  }) async {
    // TODO: Implement local message storage access
    AppLogger.debug(
      _tag,
      'Getting local conversation message changes since: $since',
    );
    return []; // Placeholder
  }

  /// Get local conversation context changes
  Future<List<Map<String, dynamic>>> _getLocalConversationContextChanges({
    DateTime? since,
  }) async {
    // TODO: Implement local context storage access
    AppLogger.debug(
      _tag,
      'Getting local conversation context changes since: $since',
    );
    return []; // Placeholder
  }

  /// Upload conversation session to server
  Future<void> _uploadConversationSession(Map<String, dynamic> session) async {
    final sessionId = session['session_id'] as String;
    AppLogger.debug(_tag, 'Uploading conversation session $sessionId');

    await _syncService.addSyncChange(
      dataType: SyncDataType.conversationSession,
      operation: session['is_new'] == true
          ? SyncOperation.create
          : SyncOperation.update,
      localId: sessionId,
      remoteId: session['remote_id'],
      payload: {
        'session_id': sessionId,
        'title': session['title'],
        'total_messages': session['total_messages'],
        'last_message_at': session['last_message_at'],
        'is_active': session['is_active'],
        'is_archived': session['is_archived'],
        'created_at': session['created_at'],
        'updated_at': session['updated_at'],
      },
    );
  }

  /// Upload conversation message to server
  Future<void> _uploadConversationMessage(Map<String, dynamic> message) async {
    final messageId = message['id'] as String;
    AppLogger.debug(_tag, 'Uploading conversation message $messageId');

    await _syncService.addSyncChange(
      dataType: SyncDataType.conversation,
      operation: message['is_new'] == true
          ? SyncOperation.create
          : SyncOperation.update,
      localId: messageId,
      remoteId: message['remote_id'],
      payload: {
        'message_id': message['message_id'],
        'session_id': message['session_id'],
        'content': message['content'],
        'message_type': message['message_type'],
        'ai_message_type': message['ai_message_type'],
        'quick_replies': message['quick_replies'],
        'context_data': message['context_data'],
        'created_at': message['created_at'],
        'updated_at': message['updated_at'],
      },
    );
  }

  /// Upload conversation context to server
  Future<void> _uploadConversationContext(Map<String, dynamic> context) async {
    final contextId = context['id'] as String;
    AppLogger.debug(_tag, 'Uploading conversation context $contextId');

    await _syncService.addSyncChange(
      dataType: SyncDataType.conversation,
      operation: SyncOperation.update,
      localId: contextId,
      remoteId: context['remote_id'],
      payload: {
        'session_id': context['session_id'],
        'context_data': context['context_data'],
        'hydration_level': context['hydration_level'],
        'current_streak': context['current_streak'],
        'daily_progress': context['daily_progress'],
        'recent_achievements': context['recent_achievements'],
        'updated_at': context['updated_at'],
      },
    );
  }

  /// Download remote conversation sessions
  Future<List<Map<String, dynamic>>> _downloadRemoteConversationSessions({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call using CoachRepository
    AppLogger.debug(
      _tag,
      'Downloading remote conversation sessions since: $since',
    );

    await Future.delayed(const Duration(milliseconds: 300));
    return []; // Placeholder
  }

  /// Download remote conversation messages
  Future<List<Map<String, dynamic>>> _downloadRemoteConversationMessages({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call using CoachRepository
    AppLogger.debug(
      _tag,
      'Downloading remote conversation messages since: $since',
    );

    await Future.delayed(const Duration(milliseconds: 400));
    return []; // Placeholder
  }

  /// Download remote conversation contexts
  Future<List<Map<String, dynamic>>> _downloadRemoteConversationContexts({
    DateTime? since,
  }) async {
    // TODO: Implement actual API call for context data
    AppLogger.debug(
      _tag,
      'Downloading remote conversation contexts since: $since',
    );

    await Future.delayed(const Duration(milliseconds: 200));
    return []; // Placeholder
  }

  /// Process remote conversation session
  Future<void> _processRemoteConversationSession(
    Map<String, dynamic> remoteSession,
  ) async {
    final sessionId = remoteSession['session_id'] as String;
    AppLogger.debug(_tag, 'Processing remote conversation session $sessionId');

    try {
      // Check if we have this session locally
      final existingSession = await _getLocalSessionById(sessionId);

      if (existingSession != null) {
        // Update existing session, check for conflicts
        if (_conflictResolver.hasConflict(existingSession, remoteSession)) {
          await _handleSessionConflict(existingSession, remoteSession);
        } else {
          await _applyRemoteSessionUpdate(existingSession, remoteSession);
        }
      } else {
        // New remote session, create locally
        await _createLocalSessionFromRemote(remoteSession);
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process remote session $sessionId', e);
      rethrow;
    }
  }

  /// Process remote conversation message
  Future<void> _processRemoteConversationMessage(
    Map<String, dynamic> remoteMessage,
  ) async {
    final messageId = remoteMessage['message_id'] as String;
    AppLogger.debug(_tag, 'Processing remote conversation message $messageId');

    try {
      // Check if we have this message locally
      final existingMessage = await _getLocalMessageById(messageId);

      if (existingMessage != null) {
        // Update existing message, check for conflicts
        if (_conflictResolver.hasConflict(existingMessage, remoteMessage)) {
          await _handleMessageConflict(existingMessage, remoteMessage);
        } else {
          await _applyRemoteMessageUpdate(existingMessage, remoteMessage);
        }
      } else {
        // New remote message, create locally
        await _createLocalMessageFromRemote(remoteMessage);
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process remote message $messageId', e);
      rethrow;
    }
  }

  /// Process remote conversation context
  Future<void> _processRemoteConversationContext(
    Map<String, dynamic> remoteContext,
  ) async {
    final contextId = remoteContext['id'] as String;
    AppLogger.debug(_tag, 'Processing remote conversation context $contextId');

    try {
      // Check if we have this context locally
      final existingContext = await _getLocalContextById(contextId);

      if (existingContext != null) {
        // Update existing context, check for conflicts
        if (_conflictResolver.hasConflict(existingContext, remoteContext)) {
          await _handleContextConflict(existingContext, remoteContext);
        } else {
          await _applyRemoteContextUpdate(existingContext, remoteContext);
        }
      } else {
        // New remote context, create locally
        await _createLocalContextFromRemote(remoteContext);
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to process remote context $contextId', e);
      rethrow;
    }
  }

  /// Handle conversation session conflict
  Future<void> _handleSessionConflict(
    Map<String, dynamic> localSession,
    Map<String, dynamic> remoteSession,
  ) async {
    final sessionId = localSession['session_id'] as String;
    AppLogger.info(_tag, 'Handling session conflict for $sessionId');

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.conversationSession,
      localId: sessionId,
      remoteId: remoteSession['id'] as String,
      localData: localSession,
      remoteData: remoteSession,
      createdAt: DateTime.now(),
      suggestedStrategy: ConflictResolutionStrategy
          .lastWriteWins, // Last write wins for sessions
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedSessionData(sessionId, resolution.resolvedData!);
      AppLogger.info(_tag, 'Session conflict resolved: ${resolution.message}');
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve session conflict: ${resolution.message}',
      );
    }
  }

  /// Handle conversation message conflict
  Future<void> _handleMessageConflict(
    Map<String, dynamic> localMessage,
    Map<String, dynamic> remoteMessage,
  ) async {
    final messageId = localMessage['message_id'] as String;
    AppLogger.info(_tag, 'Handling message conflict for $messageId');

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.conversation,
      localId: messageId,
      remoteId: remoteMessage['id'] as String,
      localData: localMessage,
      remoteData: remoteMessage,
      createdAt: DateTime.now(),
      suggestedStrategy:
          ConflictResolutionStrategy.clientWins, // Client wins for messages
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedMessageData(messageId, resolution.resolvedData!);
      AppLogger.info(_tag, 'Message conflict resolved: ${resolution.message}');
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve message conflict: ${resolution.message}',
      );
    }
  }

  /// Handle conversation context conflict
  Future<void> _handleContextConflict(
    Map<String, dynamic> localContext,
    Map<String, dynamic> remoteContext,
  ) async {
    final contextId = localContext['id'] as String;
    AppLogger.info(_tag, 'Handling context conflict for $contextId');

    final conflict = SyncConflict(
      id: _uuid.v4(),
      dataType: SyncDataType.conversation,
      localId: contextId,
      remoteId: remoteContext['id'] as String,
      localData: localContext,
      remoteData: remoteContext,
      createdAt: DateTime.now(),
      suggestedStrategy:
          ConflictResolutionStrategy.merge, // Merge for context data
    );

    final resolution = await _conflictResolver.resolveConflict(
      conflict: conflict,
    );

    if (resolution.success && resolution.resolvedData != null) {
      await _applyResolvedContextData(contextId, resolution.resolvedData!);
      AppLogger.info(_tag, 'Context conflict resolved: ${resolution.message}');
    } else {
      AppLogger.warning(
        _tag,
        'Could not resolve context conflict: ${resolution.message}',
      );
    }
  }

  // Placeholder methods for local storage operations
  Future<Map<String, dynamic>?> _getLocalSessionById(String sessionId) async {
    // TODO: Implement local session lookup
    return null;
  }

  Future<Map<String, dynamic>?> _getLocalMessageById(String messageId) async {
    // TODO: Implement local message lookup
    return null;
  }

  Future<Map<String, dynamic>?> _getLocalContextById(String contextId) async {
    // TODO: Implement local context lookup
    return null;
  }

  Future<void> _applyRemoteSessionUpdate(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) async {
    // TODO: Update local session with remote data
    AppLogger.debug(_tag, 'Applying remote session update');
  }

  Future<void> _applyRemoteMessageUpdate(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) async {
    // TODO: Update local message with remote data
    AppLogger.debug(_tag, 'Applying remote message update');
  }

  Future<void> _applyRemoteContextUpdate(
    Map<String, dynamic> local,
    Map<String, dynamic> remote,
  ) async {
    // TODO: Update local context with remote data
    AppLogger.debug(_tag, 'Applying remote context update');
  }

  Future<void> _createLocalSessionFromRemote(
    Map<String, dynamic> remote,
  ) async {
    // TODO: Create local session from remote data
    AppLogger.debug(_tag, 'Creating local session from remote data');
  }

  Future<void> _createLocalMessageFromRemote(
    Map<String, dynamic> remote,
  ) async {
    // TODO: Create local message from remote data
    AppLogger.debug(_tag, 'Creating local message from remote data');
  }

  Future<void> _createLocalContextFromRemote(
    Map<String, dynamic> remote,
  ) async {
    // TODO: Create local context from remote data
    AppLogger.debug(_tag, 'Creating local context from remote data');
  }

  Future<void> _applyResolvedSessionData(
    String sessionId,
    Map<String, dynamic> resolved,
  ) async {
    // TODO: Apply resolved session data
    AppLogger.debug(_tag, 'Applying resolved session data for $sessionId');
  }

  Future<void> _applyResolvedMessageData(
    String messageId,
    Map<String, dynamic> resolved,
  ) async {
    // TODO: Apply resolved message data
    AppLogger.debug(_tag, 'Applying resolved message data for $messageId');
  }

  Future<void> _applyResolvedContextData(
    String contextId,
    Map<String, dynamic> resolved,
  ) async {
    // TODO: Apply resolved context data
    AppLogger.debug(_tag, 'Applying resolved context data for $contextId');
  }

  /// Immediately sync a new message (for real-time chat experience)
  Future<void> syncNewMessage({
    required String messageId,
    required String sessionId,
    required String content,
    required String messageType,
    Map<String, dynamic>? contextData,
  }) async {
    AppLogger.debug(_tag, 'Syncing new message immediately: $messageId');

    try {
      await _syncService.addSyncChange(
        dataType: SyncDataType.conversation,
        operation: SyncOperation.create,
        localId: messageId,
        remoteId: null,
        payload: {
          'message_id': messageId,
          'session_id': sessionId,
          'content': content,
          'message_type': messageType,
          'context_data': contextData,
          'created_at': DateTime.now().toIso8601String(),
        },
      );

      AppLogger.debug(_tag, 'New message queued for immediate sync');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to queue new message for sync', e);
      rethrow;
    }
  }

  /// Get conversation sync statistics
  Future<Map<String, dynamic>> getConversationSyncStats() async {
    final messageStats = await _syncService.getSyncStats(
      dataType: SyncDataType.conversation,
    );
    final sessionStats = await _syncService.getSyncStats(
      dataType: SyncDataType.conversationSession,
    );

    return {
      'messages': messageStats,
      'sessions': sessionStats,
      'combined_success_rate': _calculateCombinedSuccessRate([
        messageStats,
        sessionStats,
      ]),
      'real_time_sync_enabled': true,
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

/// Result of a conversation sync operation
class ConversationSyncResult {
  final bool success;
  final SyncDataType dataType;
  final int uploadedCount;
  final int downloadedCount;
  final Duration duration;
  final List<String> errors;
  final String? error;

  const ConversationSyncResult._({
    required this.success,
    required this.dataType,
    this.uploadedCount = 0,
    this.downloadedCount = 0,
    required this.duration,
    this.errors = const [],
    this.error,
  });

  factory ConversationSyncResult.success({
    required SyncDataType dataType,
    int uploadedCount = 0,
    int downloadedCount = 0,
    required Duration duration,
    List<String> errors = const [],
  }) {
    return ConversationSyncResult._(
      success: true,
      dataType: dataType,
      uploadedCount: uploadedCount,
      downloadedCount: downloadedCount,
      duration: duration,
      errors: errors,
    );
  }

  factory ConversationSyncResult.error({
    required SyncDataType dataType,
    required String error,
    required Duration duration,
  }) {
    return ConversationSyncResult._(
      success: false,
      dataType: dataType,
      duration: duration,
      error: error,
    );
  }

  bool get hasErrors => errors.isNotEmpty;
  int get totalProcessed => uploadedCount + downloadedCount;
}
