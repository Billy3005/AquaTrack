import '../services/api_service.dart';
import '../utils/logger.dart';

/// Repository for coach conversation API calls
class CoachRepository {
  static const String _tag = 'CoachRepository';

  final ApiService _apiService;

  CoachRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Send message in conversation and get AI response
  Future<CoachApiResponse<ChatMessageResponse>> sendMessage({
    required String content,
    String? sessionId,
    Map<String, dynamic>? context,
  }) async {
    AppLogger.info(_tag, 'Sending conversation message');

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/coach/conversation/send',
        data: {
          'content': content,
          if (sessionId != null) 'session_id': sessionId,
          if (context != null) 'context': context,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final chatResponse = ChatMessageResponse.fromJson(response.data!);
      return CoachApiResponse.success(chatResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to send message', e);
      return CoachApiResponse.error('Failed to send message: $e');
    }
  }

  /// Get conversation history for a session
  Future<CoachApiResponse<ConversationHistoryResponse>> getConversationHistory({
    required String sessionId,
    int page = 1,
    int limit = 50,
  }) async {
    AppLogger.info(
      _tag,
      'Getting conversation history for session: $sessionId',
    );

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/coach/conversation/history',
        queryParams: {'session_id': sessionId, 'page': page, 'limit': limit},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final historyResponse = ConversationHistoryResponse.fromJson(
        response.data!,
      );
      return CoachApiResponse.success(historyResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get conversation history', e);
      return CoachApiResponse.error('Failed to load conversation history: $e');
    }
  }

  /// Get all conversation sessions for user
  Future<CoachApiResponse<ConversationSessionListResponse>>
  getConversationSessions({int skip = 0, int limit = 20}) async {
    AppLogger.info(_tag, 'Getting conversation sessions');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/coach/conversation/sessions',
        queryParams: {'skip': skip, 'limit': limit},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final sessionsResponse = ConversationSessionListResponse.fromJson(
        response.data!,
      );
      return CoachApiResponse.success(sessionsResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get conversation sessions', e);
      return CoachApiResponse.error('Failed to load conversation sessions: $e');
    }
  }

  /// Handle quick reply action
  Future<CoachApiResponse<QuickReplyActionResponse>> handleQuickReply({
    required String quickReplyId,
    required String sessionId,
    Map<String, dynamic>? context,
  }) async {
    AppLogger.info(_tag, 'Handling quick reply: $quickReplyId');

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/coach/conversation/quick-reply',
        data: {
          'quick_reply_id': quickReplyId,
          'session_id': sessionId,
          if (context != null) 'context': context,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final quickReplyResponse = QuickReplyActionResponse.fromJson(
        response.data!,
      );
      return CoachApiResponse.success(quickReplyResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to handle quick reply', e);
      return CoachApiResponse.error('Failed to process quick reply: $e');
    }
  }

  /// Update conversation context
  Future<CoachApiResponse<void>> updateConversationContext({
    required String sessionId,
    required Map<String, dynamic> context,
  }) async {
    AppLogger.info(_tag, 'Updating conversation context');

    try {
      await _apiService.post<Map<String, dynamic>>(
        '/coach/conversation/context',
        data: {'session_id': sessionId, 'context': context},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return CoachApiResponse.success(null);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to update conversation context', e);
      return CoachApiResponse.error('Failed to update context: $e');
    }
  }

  /// Archive conversation session
  Future<CoachApiResponse<void>> archiveConversationSession(
    String sessionId,
  ) async {
    AppLogger.info(_tag, 'Archiving conversation session: $sessionId');

    try {
      await _apiService.delete<Map<String, dynamic>>(
        '/coach/conversation/sessions/$sessionId',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      return CoachApiResponse.success(null);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to archive conversation session', e);
      return CoachApiResponse.error('Failed to archive session: $e');
    }
  }
}

/// Generic API response wrapper for coach data
class CoachApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  const CoachApiResponse._({required this.isSuccess, this.data, this.error});

  factory CoachApiResponse.success(T? data) =>
      CoachApiResponse._(isSuccess: true, data: data);

  factory CoachApiResponse.error(String error) =>
      CoachApiResponse._(isSuccess: false, error: error);
}

/// Chat message response model
class ChatMessageResponse {
  final String messageId;
  final String sessionId;
  final ConversationMessage userMessage;
  final ConversationMessage aiResponse;

  const ChatMessageResponse({
    required this.messageId,
    required this.sessionId,
    required this.userMessage,
    required this.aiResponse,
  });

  factory ChatMessageResponse.fromJson(Map<String, dynamic> json) {
    return ChatMessageResponse(
      messageId: json['message_id'] ?? '',
      sessionId: json['session_id'] ?? '',
      userMessage: ConversationMessage.fromJson(json['user_message'] ?? {}),
      aiResponse: ConversationMessage.fromJson(json['ai_response'] ?? {}),
    );
  }
}

/// Individual conversation message
class ConversationMessage {
  final int id;
  final String messageId;
  final String sessionId;
  final String content;
  final String messageType; // "user", "ai", "system"
  final String? aiMessageType;
  final List<QuickReplyApi>? quickReplies;
  final Map<String, dynamic>? contextData;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isDeleted;

  const ConversationMessage({
    required this.id,
    required this.messageId,
    required this.sessionId,
    required this.content,
    required this.messageType,
    this.aiMessageType,
    this.quickReplies,
    this.contextData,
    required this.createdAt,
    this.updatedAt,
    required this.isDeleted,
  });

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final quickRepliesJson = json['quick_replies'] as List<dynamic>?;
    List<QuickReplyApi>? quickReplies;

    if (quickRepliesJson != null) {
      quickReplies = quickRepliesJson
          .map((qr) => QuickReplyApi.fromJson(qr))
          .toList();
    }

    return ConversationMessage(
      id: json['id'] ?? 0,
      messageId: json['message_id'] ?? '',
      sessionId: json['session_id'] ?? '',
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'user',
      aiMessageType: json['ai_message_type'],
      quickReplies: quickReplies,
      contextData: json['context_data']?.cast<String, dynamic>(),
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isDeleted: json['is_deleted'] ?? false,
    );
  }
}

/// API Quick reply model
class QuickReplyApi {
  final String id;
  final String text;
  final String? action;

  const QuickReplyApi({required this.id, required this.text, this.action});

  factory QuickReplyApi.fromJson(Map<String, dynamic> json) {
    return QuickReplyApi(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      action: json['action'],
    );
  }
}

/// Conversation history response
class ConversationHistoryResponse {
  final String sessionId;
  final int totalMessages;
  final List<ConversationMessage> messages;
  final bool hasMore;
  final int? nextPage;

  const ConversationHistoryResponse({
    required this.sessionId,
    required this.totalMessages,
    required this.messages,
    required this.hasMore,
    this.nextPage,
  });

  factory ConversationHistoryResponse.fromJson(Map<String, dynamic> json) {
    final messagesJson = json['messages'] as List<dynamic>? ?? [];

    return ConversationHistoryResponse(
      sessionId: json['session_id'] ?? '',
      totalMessages: json['total_messages'] ?? 0,
      messages: messagesJson
          .map((msg) => ConversationMessage.fromJson(msg))
          .toList(),
      hasMore: json['has_more'] ?? false,
      nextPage: json['next_page'],
    );
  }
}

/// Conversation sessions list response
class ConversationSessionListResponse {
  final List<ConversationSessionApi> sessions;
  final int totalCount;

  const ConversationSessionListResponse({
    required this.sessions,
    required this.totalCount,
  });

  factory ConversationSessionListResponse.fromJson(Map<String, dynamic> json) {
    final sessionsJson = json['sessions'] as List<dynamic>? ?? [];

    return ConversationSessionListResponse(
      sessions: sessionsJson
          .map((session) => ConversationSessionApi.fromJson(session))
          .toList(),
      totalCount: json['total_count'] ?? 0,
    );
  }
}

/// API Conversation session model
class ConversationSessionApi {
  final int id;
  final String sessionId;
  final String userId;
  final String? title;
  final int totalMessages;
  final DateTime lastMessageAt;
  final bool isActive;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ConversationSessionApi({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.title,
    required this.totalMessages,
    required this.lastMessageAt,
    required this.isActive,
    required this.isArchived,
    required this.createdAt,
    this.updatedAt,
  });

  factory ConversationSessionApi.fromJson(Map<String, dynamic> json) {
    return ConversationSessionApi(
      id: json['id'] ?? 0,
      sessionId: json['session_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'],
      totalMessages: json['total_messages'] ?? 0,
      lastMessageAt: DateTime.parse(
        json['last_message_at'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['is_active'] ?? true,
      isArchived: json['is_archived'] ?? false,
      createdAt: DateTime.parse(
        json['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

/// Quick reply action response
class QuickReplyActionResponse {
  final String message;
  final String aiResponse;

  const QuickReplyActionResponse({
    required this.message,
    required this.aiResponse,
  });

  factory QuickReplyActionResponse.fromJson(Map<String, dynamic> json) {
    return QuickReplyActionResponse(
      message: json['message'] ?? '',
      aiResponse: json['ai_response'] ?? '',
    );
  }
}
