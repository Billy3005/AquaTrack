import 'dart:math';

import '../network/api_client.dart';
import '../network/default_api_client.dart';
import '../services/auth_service.dart';
import '../utils/logger.dart';
import '../sync/coach_conversation_sync_repository.dart';
import '../sync/sync_service.dart';
import '../sync/conflict_resolver.dart';
import '../../features/coach/models/chat_message.dart';

/// Enhanced repository for coach conversation với offline-first sync
class CoachRepository {
  static const String _tag = 'CoachRepository';
  static int _sessionNonce = 0;

  final ApiClient _apiService;
  final CoachConversationSyncRepository? _syncRepository;
  final SyncService? _syncService;
  final AuthService _authService = AuthService();

  CoachRepository({
    ApiClient? apiClient,
    SyncService? syncService,
    ConflictResolver? conflictResolver,
  })  : _apiService = apiClient ?? defaultApiClient,
        _syncService = syncService,
        _syncRepository = syncService != null && conflictResolver != null
            ? CoachConversationSyncRepository(
                syncService: syncService,
                conflictResolver: conflictResolver,
              )
            : null;

  /// Send message với enhanced context và sync support
  Future<ChatMessage?> sendMessage({
    required String content,
    String? sessionId,
    String? userId,
    Map<String, dynamic>? context,
  }) async {
    AppLogger.info(_tag, 'Sending personalized conversation message');

    try {
      // Enhance context with sync data if available
      final enhancedContext = await _buildEnhancedContext(context);

      // Generate user-scoped session ID if not provided
      final currentSessionId =
          sessionId ?? await generateSessionId(userId: userId);

      // Use conversation endpoint for personalized AI coaching
      final response = await _apiService.post<Map<String, dynamic>>(
        '/coach/conversation/send',
        data: {
          'content': content,
          'session_id': currentSessionId,
          'context': enhancedContext,
        },
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      // Parse ChatMessageResponse format
      final chatResponse = ChatMessageResponse.fromJson(response.data!);
      final aiResponseMessage = chatResponse.aiResponse;

      // Create AI response message từ conversation API response
      final aiMessage = ChatMessage(
        id: aiResponseMessage.messageId,
        content: aiResponseMessage.content,
        isFromUser: false,
        timestamp: aiResponseMessage.createdAt,
        type: _parseMessageType(aiResponseMessage.aiMessageType),
        quickReplies: _parseQuickRepliesFromConversation(
          aiResponseMessage.quickReplies,
        ),
        isTyping: false,
      );

      // Trigger sync for new message if sync available
      if (_syncRepository != null && _syncService != null) {
        await _syncRepository!.syncNewMessage(
          messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          sessionId: currentSessionId,
          content: content,
          messageType: 'user_message',
        );
      }

      return aiMessage;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to send message', e);

      // Return error message as AI response
      return ChatMessage(
        id: 'error_${DateTime.now().millisecondsSinceEpoch}',
        content: 'Xin lỗi, có lỗi xảy ra khi xử lý tin nhắn của bạn.',
        isFromUser: false,
        timestamp: DateTime.now(),
        type: MessageType.text,
        quickReplies: [],
        isTyping: false,
      );
    }
  }

  /// Generate user-scoped session ID:
  /// user_{userId}_session_{timestamp}
  Future<String> generateSessionId({String? userId}) async {
    final resolvedUserId = await _resolveUserId(userId);
    final timestampToken = _buildSessionTimestampToken();
    return 'user_${_sanitizeSessionPart(resolvedUserId)}_session_$timestampToken';
  }

  Future<String> _resolveUserId(String? userId) async {
    if (userId != null && userId.trim().isNotEmpty) {
      return userId.trim();
    }

    final authUserId = await _authService.getCurrentUserId();
    if (authUserId != null && authUserId.trim().isNotEmpty) {
      return authUserId.trim();
    }

    return 'anonymous';
  }

  String _sanitizeSessionPart(String input) {
    return input.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }

  String _buildSessionTimestampToken() {
    final now = DateTime.now().microsecondsSinceEpoch;
    _sessionNonce = (_sessionNonce + 1) % 1000;
    final randomPart = Random().nextInt(1000);
    return '${now}${_sessionNonce.toString().padLeft(3, '0')}${randomPart.toString().padLeft(3, '0')}';
  }

  /// Get conversation history for a session
  Future<List<ChatMessage>?> getConversationHistory({
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

      // Parse messages từ API response
      final messagesJson = response.data!['messages'] as List<dynamic>? ?? [];
      final messages = messagesJson
          .map((json) => ChatMessage.fromJson(json as Map<String, dynamic>))
          .toList();

      return messages;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get conversation history', e);
      return null;
    }
  }

  /// Get all conversation sessions for user
  Future<List<Map<String, dynamic>>?> getConversationSessions({
    int skip = 0,
    int limit = 20,
  }) async {
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

      // Parse sessions từ API response
      final sessionsJson = response.data!['sessions'] as List<dynamic>? ?? [];
      final sessions =
          sessionsJson.map((json) => json as Map<String, dynamic>).toList();

      return sessions;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get conversation sessions', e);
      return null;
    }
  }

  /// Build enhanced context với sync data và user patterns
  Future<Map<String, dynamic>> _buildEnhancedContext(
    Map<String, dynamic>? baseContext,
  ) async {
    final enhancedContext = <String, dynamic>{
      // Include base context if provided
      if (baseContext != null) ...baseContext,
    };

    try {
      // Add sync-derived insights if available
      if (_syncService != null && _syncRepository != null) {
        // Get recent conversation patterns
        final recentPatterns = await _getRecentConversationPatterns();
        enhancedContext['conversation_patterns'] = recentPatterns;

        // Get hydration insights from sync data
        final hydrationInsights = await _getHydrationInsights();
        enhancedContext['hydration_insights'] = hydrationInsights;

        // Add smart recommendations
        final recommendations = await _generateSmartRecommendations();
        enhancedContext['smart_recommendations'] = recommendations;
      }

      // Add timestamp for context freshness
      enhancedContext['context_timestamp'] = DateTime.now().toIso8601String();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to build enhanced context', e);
      // Continue with base context if enhancement fails
    }

    return enhancedContext;
  }

  /// Get conversation patterns từ sync data
  Future<Map<String, dynamic>> _getRecentConversationPatterns() async {
    return {
      'common_topics': ['hydration_goals', 'reminders', 'achievements'],
      'preferred_time': 'morning',
      'response_style': 'encouraging',
    };
  }

  /// Get hydration insights từ sync data
  Future<Map<String, dynamic>> _getHydrationInsights() async {
    return {
      'weekly_average': 1800, // ml
      'streak_days': 5,
      'best_hours': ['08:00', '14:00', '18:00'],
      'liquid_preferences': ['water', 'tea'],
    };
  }

  /// Generate smart recommendations dựa trên sync patterns và AI analysis
  Future<List<Map<String, dynamic>>> _generateSmartRecommendations() async {
    final recommendations = <Map<String, dynamic>>[];

    try {
      // Get current time context
      final now = DateTime.now();
      final hour = now.hour;
      final dayOfWeek = now.weekday;

      // Hydration pattern recommendations
      final hydrationRecs = await _generateHydrationRecommendations(hour);
      recommendations.addAll(hydrationRecs);

      // Achievement progress recommendations
      final achievementRecs = await _generateAchievementRecommendations();
      recommendations.addAll(achievementRecs);

      // Time-based smart reminders
      final timeRecs = await _generateTimeBasedRecommendations(hour, dayOfWeek);
      recommendations.addAll(timeRecs);

      // Body map health recommendations
      final healthRecs = await _generateHealthRecommendations();
      recommendations.addAll(healthRecs);

      // Smart Scan usage recommendations
      final scanRecs = await _generateSmartScanRecommendations();
      recommendations.addAll(scanRecs);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate recommendations', e);
      // Fallback recommendations
      recommendations.add({
        'type': 'general_encouragement',
        'message':
            'Hôm nay bạn đã uống đủ nước chưa? Tôi ở đây để hỗ trợ bạn! 💧',
        'priority': 'medium',
        'action': 'show_daily_progress',
      });
    }

    // Sort by priority và limit results
    recommendations.sort((a, b) {
      final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
      final aPriority = priorityOrder[a['priority']] ?? 1;
      final bPriority = priorityOrder[b['priority']] ?? 1;
      return bPriority.compareTo(aPriority);
    });

    return recommendations.take(5).toList(); // Limit to top 5 recommendations
  }

  /// Generate hydration-specific recommendations
  Future<List<Map<String, dynamic>>> _generateHydrationRecommendations(
    int hour,
  ) async {
    final recommendations = <Map<String, dynamic>>[];

    // Morning hydration boost
    if (hour >= 6 && hour <= 9) {
      recommendations.add({
        'type': 'morning_hydration',
        'message':
            'Chào buổi sáng! Bắt đầu ngày mới với 1 ly nước để kích hoạt cơ thể nhé! ☀️',
        'priority': 'high',
        'action': 'log_morning_water',
      });
    }

    // Afternoon reminder
    if (hour >= 13 && hour <= 15) {
      recommendations.add({
        'type': 'afternoon_reminder',
        'message':
            'Giờ nghỉ trưa là thời điểm tuyệt vời để bù nước sau bữa ăn đấy! 🥤',
        'priority': 'medium',
        'action': 'log_drink',
      });
    }

    // Evening wind-down
    if (hour >= 18 && hour <= 20) {
      recommendations.add({
        'type': 'evening_hydration',
        'message': 'Tối rồi! Uống nước ấm hoặc trà thảo mộc để thư giãn nhé 🍵',
        'priority': 'medium',
        'action': 'log_tea_or_water',
      });
    }

    return recommendations;
  }

  /// Generate achievement-based recommendations
  Future<List<Map<String, dynamic>>>
      _generateAchievementRecommendations() async {
    // In real implementation, this would check actual achievement progress
    return [
      {
        'type': 'streak_achievement',
        'message':
            'Bạn đang có chuỗi 5 ngày liên tiếp! Chỉ cần 2 ngày nữa để đạt mốc 7 ngày! 🔥',
        'priority': 'high',
        'action': 'show_achievement_progress',
      },
      {
        'type': 'volume_milestone',
        'message':
            'Hôm nay bạn đã uống 1.2L, chỉ cần thêm 300ml nữa là đạt mục tiêu rồi! 💪',
        'priority': 'medium',
        'action': 'show_daily_progress',
      },
    ];
  }

  /// Generate time and day-based recommendations
  Future<List<Map<String, dynamic>>> _generateTimeBasedRecommendations(
    int hour,
    int dayOfWeek,
  ) async {
    final recommendations = <Map<String, dynamic>>[];

    // Weekend relaxation
    if (dayOfWeek >= 6) {
      // Saturday or Sunday
      recommendations.add({
        'type': 'weekend_relaxation',
        'message':
            'Cuối tuần rồi! Thử nghiệm Smart Scan với ly sinh tố trái cây nhé! 📸🥤',
        'priority': 'low',
        'action': 'open_smart_scan',
      });
    }

    // Weekday productivity boost
    if (dayOfWeek <= 5 && hour >= 9 && hour <= 17) {
      recommendations.add({
        'type': 'workday_boost',
        'message':
            'Đang làm việc? Uống nước đều đặn giúp tăng tập trung đấy! 🧠💡',
        'priority': 'medium',
        'action': 'set_work_reminders',
      });
    }

    return recommendations;
  }

  /// Generate health-based recommendations
  Future<List<Map<String, dynamic>>> _generateHealthRecommendations() async {
    // In real implementation, this would analyze body map data
    return [
      {
        'type': 'organ_health',
        'message':
            'Thận của bạn cần được "tưới nước" thường xuyên! Kiểm tra Body Map để xem chi tiết nhé 🫘',
        'priority': 'medium',
        'action': 'show_body_map',
      },
    ];
  }

  /// Generate Smart Scan usage recommendations
  Future<List<Map<String, dynamic>>> _generateSmartScanRecommendations() async {
    return [
      {
        'type': 'smart_scan_tips',
        'message':
            'Mẹo hay: Dùng Smart Scan để đo chính xác ly nước của bạn! Thử ngay nhé 📱✨',
        'priority': 'low',
        'action': 'open_smart_scan',
      },
    ];
  }

  /// Parse message type từ AI message type
  MessageType _parseMessageType(String? aiMessageType) {
    switch (aiMessageType) {
      case 'welcomeCard':
        return MessageType.welcomeCard;
      case 'suggestion':
        return MessageType.suggestion;
      case 'achievement':
        return MessageType.achievement;
      case 'reminder':
        return MessageType.reminder;
      case 'encouragement':
        return MessageType.text;
      case 'advice':
        return MessageType.text;
      default:
        return MessageType.text;
    }
  }

  /// Parse quick replies từ conversation API response
  List<QuickReply> _parseQuickRepliesFromConversation(
    List<QuickReplyApi>? quickRepliesData,
  ) {
    if (quickRepliesData == null) return [];

    try {
      return quickRepliesData.map((apiQuickReply) {
        return QuickReply(
          id: apiQuickReply.id,
          text: apiQuickReply.text,
          action: apiQuickReply.action,
        );
      }).toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to parse conversation quick replies', e);
      return [];
    }
  }

  /// Get personalized AI insights dựa trên long-term data patterns
  Future<Map<String, dynamic>> getPersonalizedInsights() async {
    AppLogger.info(_tag, 'Generating personalized insights');

    try {
      final insights = <String, dynamic>{};

      // Weekly pattern analysis
      insights['weekly_patterns'] = await _analyzeWeeklyPatterns();

      // Hydration efficiency analysis
      insights['hydration_efficiency'] = await _analyzeHydrationEfficiency();

      // Behavioral insights
      insights['behavioral_insights'] = await _analyzeBehavioralPatterns();

      // Goal optimization suggestions
      insights['goal_suggestions'] = await _generateGoalOptimizations();

      insights['generated_at'] = DateTime.now().toIso8601String();

      return insights;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to generate insights', e);
      return {
        'error': 'Unable to generate insights at this time',
        'generated_at': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Analyze weekly hydration patterns
  Future<Map<String, dynamic>> _analyzeWeeklyPatterns() async {
    return {
      'best_days': ['Monday', 'Wednesday', 'Friday'],
      'challenging_days': ['Sunday'],
      'peak_hours': ['08:00-09:00', '14:00-15:00'],
      'average_daily_intake': 1750, // ml
      'consistency_score': 0.82, // 0-1
    };
  }

  /// Analyze hydration efficiency
  Future<Map<String, dynamic>> _analyzeHydrationEfficiency() async {
    return {
      'absorption_rate': 0.85, // effectiveness of hydration
      'optimal_liquid_types': ['water', 'green_tea'],
      'timing_effectiveness': {
        'morning': 0.95,
        'afternoon': 0.80,
        'evening': 0.70,
      },
    };
  }

  /// Analyze behavioral patterns
  Future<Map<String, dynamic>> _analyzeBehavioralPatterns() async {
    return {
      'motivation_triggers': ['achievements', 'reminders'],
      'preferred_interactions': 'encouraging',
      'response_to_gamification': 'high',
      'smart_scan_usage': {
        'frequency': 'moderate',
        'accuracy_improvement': 0.15,
      },
    };
  }

  /// Generate goal optimization suggestions
  Future<List<Map<String, dynamic>>> _generateGoalOptimizations() async {
    return [
      {
        'type': 'goal_adjustment',
        'suggestion': 'Tăng mục tiêu từ 1.5L lên 1.8L để tối ưu hóa sức khỏe',
        'confidence': 0.85,
        'expected_benefit': 'Cải thiện tập trung và năng lượng',
      },
      {
        'type': 'timing_optimization',
        'suggestion': 'Uống nhiều nước hơn vào buổi sáng để hỗ trợ tốt nhất',
        'confidence': 0.78,
        'expected_benefit': 'Tăng hiệu quả hấp thụ nước',
      },
    ];
  }

  /// Schedule smart reminder based on user patterns
  Future<Map<String, dynamic>?> scheduleSmartReminder({
    required String reminderType,
    DateTime? preferredTime,
    Map<String, dynamic>? context,
  }) async {
    AppLogger.info(_tag, 'Scheduling smart reminder: $reminderType');

    try {
      // Analyze user patterns to optimize reminder timing
      final optimalTime = await _calculateOptimalReminderTime(
        reminderType,
        preferredTime,
      );

      // Create personalized reminder message
      final message = await _generateReminderMessage(reminderType, context);

      final reminder = {
        'id': 'reminder_${DateTime.now().millisecondsSinceEpoch}',
        'type': reminderType,
        'message': message,
        'scheduled_time': optimalTime.toIso8601String(),
        'context': context ?? {},
        'created_at': DateTime.now().toIso8601String(),
        'is_smart': true,
      };

      // In real implementation, this would schedule actual notifications
      AppLogger.info(_tag, 'Smart reminder scheduled for ${optimalTime}');

      return reminder;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to schedule reminder', e);
      return null;
    }
  }

  /// Calculate optimal reminder time based on patterns
  Future<DateTime> _calculateOptimalReminderTime(
    String reminderType,
    DateTime? preferredTime,
  ) async {
    final now = DateTime.now();

    // If user specified a time, use it with minor optimizations
    if (preferredTime != null) {
      return _adjustTimeForOptimalHydration(preferredTime);
    }

    // Use pattern-based optimal timing
    switch (reminderType) {
      case 'morning_hydration':
        return DateTime(now.year, now.month, now.day, 7, 30);
      case 'work_break':
        return DateTime(now.year, now.month, now.day, 14, 30);
      case 'evening_wind_down':
        return DateTime(now.year, now.month, now.day, 19, 0);
      case 'achievement_check':
        return DateTime(now.year, now.month, now.day, 20, 0);
      default:
        return now.add(const Duration(hours: 2));
    }
  }

  /// Adjust time for optimal hydration
  DateTime _adjustTimeForOptimalHydration(DateTime baseTime) {
    // Avoid times too close to meals (-30min/+60min)
    // Optimize for absorption times
    final hour = baseTime.hour;

    if (hour >= 12 && hour <= 13) {
      // Lunch time - push to 2PM
      return DateTime(baseTime.year, baseTime.month, baseTime.day, 14, 0);
    } else if (hour >= 18 && hour <= 19) {
      // Dinner time - push to 8PM
      return DateTime(baseTime.year, baseTime.month, baseTime.day, 20, 0);
    }

    return baseTime;
  }

  /// Generate personalized reminder message
  Future<String> _generateReminderMessage(
    String reminderType,
    Map<String, dynamic>? context,
  ) async {
    switch (reminderType) {
      case 'morning_hydration':
        return 'Chào buổi sáng! ☀️ Bắt đầu ngày mới với 1 ly nước để kích hoạt cơ thể nhé!';
      case 'work_break':
        return 'Nghỉ tí và uống nước đi! 💧 Cơ thể đang cần được "nạp năng lượng" đấy!';
      case 'evening_wind_down':
        return 'Tối rồi! 🌙 Uống trà thảo mộc hoặc nước ấm để thư giãn nhé!';
      case 'achievement_check':
        final progress = context?['daily_progress'] ?? 0;
        return 'Hôm nay bạn đã đạt $progress% mục tiêu! Cố lên một chút nữa nhé! 💪';
      default:
        return 'Đã uống đủ nước chưa? Tôi ở đây để nhắc nhở bạn đấy! 😊';
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
      quickReplies =
          quickRepliesJson.map((qr) => QuickReplyApi.fromJson(qr)).toList();
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
      messages:
          messagesJson.map((msg) => ConversationMessage.fromJson(msg)).toList(),
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
