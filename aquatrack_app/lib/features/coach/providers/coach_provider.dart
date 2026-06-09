import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/repositories/coach_repository.dart';
import '../../../features/auth/presentation/providers/auth_providers.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../../home/providers/home_provider.dart';
import '../../level/providers/level_provider.dart';
import '../../body_map/providers/body_map_provider.dart';
import '../models/chat_message.dart';

part 'coach_provider.g.dart';

/// Provider for CoachRepository dependency injection
@riverpod
CoachRepository coachRepository(ref) {
  return CoachRepository();
}

/// Context data for AI responses
class CoachContext {
  final double hydrationLevel;
  final int currentLevel;
  final int streak;
  final int todayIntake;
  final int dailyGoal;
  final List<String> recentAchievements;
  final String overallHealthStatus;

  const CoachContext({
    required this.hydrationLevel,
    required this.currentLevel,
    required this.streak,
    required this.todayIntake,
    required this.dailyGoal,
    required this.recentAchievements,
    required this.overallHealthStatus,
  });

  /// Get completion percentage
  double get completionPercentage {
    return dailyGoal > 0 ? (todayIntake / dailyGoal).clamp(0.0, 1.0) : 0.0;
  }

  /// Check if goal is reached
  bool get isGoalReached => completionPercentage >= 1.0;

  /// Get hydration status
  String get hydrationStatus {
    if (hydrationLevel >= 0.8) return 'excellent';
    if (hydrationLevel >= 0.6) return 'good';
    if (hydrationLevel >= 0.4) return 'fair';
    if (hydrationLevel >= 0.2) return 'poor';
    return 'critical';
  }
}

/// Coach notifier với AI conversation management từ backend
@riverpod
class CoachNotifier extends _$CoachNotifier {
  late Timer? _autoSuggestionTimer;
  late final CoachRepository _coachRepository;
  String? _currentSessionId;
  String? _sessionOwnerUserId;

  @override
  Future<ConversationState> build() async {
    // Initialize repository via dependency injection
    _coachRepository = ref.read(coachRepositoryProvider);

    // Listen to auth state changes để reset conversation khi user switch
    ref.listen<AuthState>(authStateProvider, (previous, current) {
      if (previous?.currentUser?.id != current.currentUser?.id) {
        // User changed - reset conversation for new user
        _resetForNewUser();
      }
    });

    // Cancel timer when provider is disposed
    ref.onDispose(() {
      _autoSuggestionTimer?.cancel();
    });

    return _loadConversationFromApi();
  }

  /// Load conversation từ backend API với fallback
  Future<ConversationState> _loadConversationFromApi() async {
    try {
      final currentUserId = _getCurrentUserId();
      _sessionOwnerUserId = currentUserId;

      // Only load if we have a valid user ID
      if (currentUserId == null) {
        debugPrint('⚠️ No current user ID, creating welcome conversation');
        return _createWelcomeConversation();
      }

      // Try to get recent conversation session for current user
      final sessions = await _coachRepository.getConversationSessions(limit: 1);

      if (sessions == null) {
        throw Exception('Failed to load sessions');
      }

      if (sessions.isNotEmpty) {
        final recentSession = sessions.first;
        final sessionUserId = recentSession['user_id'] as String?;

        // Double-check session belongs to current user
        if (sessionUserId == currentUserId) {
          _currentSessionId = recentSession['session_id'];

          // Load conversation history for this session
          final messages = await _coachRepository.getConversationHistory(
            sessionId: recentSession['session_id'],
          );

          if (messages != null && messages.isNotEmpty) {
            debugPrint(
                '✅ Loaded ${messages.length} messages for user $currentUserId');
            return ConversationState(
              messages: messages,
              lastUpdated: DateTime.now(),
            );
          }
        } else {
          debugPrint(
              '⚠️ Session belongs to different user, creating new conversation');
        }
      }

      // No existing conversation for current user, create welcome conversation
      debugPrint(
          '📝 Creating new welcome conversation for user $currentUserId');
      return _createWelcomeConversation();
    } catch (e) {
      debugPrint('❌ Failed to load conversation from API: $e');

      // Only fallback to local storage for genuine connectivity issues
      final isConnectivityError = e.toString().contains('SocketException') ||
          e.toString().contains('HttpException') ||
          e.toString().contains('TimeoutException') ||
          e.toString().contains('Connection refused') ||
          e.toString().contains('No route to host');

      if (isConnectivityError) {
        debugPrint(
          '🌐 Network connectivity issue detected, falling back to local storage',
        );
        return _loadConversationFromLocal();
      } else {
        // For API errors, create a fresh welcome conversation
        debugPrint('🚨 API error, creating new conversation: $e');
        return _createWelcomeConversation();
      }
    }
  }

  /// Convert API message to local ChatMessage format
  ChatMessage _convertApiMessageToChatMessage(ConversationMessage apiMessage) {
    // Convert quick replies if present
    List<QuickReply>? quickReplies;
    if (apiMessage.quickReplies != null) {
      quickReplies = apiMessage.quickReplies!.map((qr) {
        return QuickReply(id: qr.id, text: qr.text, action: qr.action);
      }).toList();
    }

    // Determine message type
    MessageType messageType = MessageType.text;
    if (apiMessage.aiMessageType != null) {
      switch (apiMessage.aiMessageType!) {
        case 'welcomeCard':
          messageType = MessageType.welcomeCard;
          break;
        case 'suggestion':
          messageType = MessageType.suggestion;
          break;
        case 'achievement':
          messageType = MessageType.achievement;
          break;
        case 'reminder':
          messageType = MessageType.reminder;
          break;
        default:
          messageType = MessageType.text;
      }
    }

    if (apiMessage.messageType == 'user') {
      return ChatMessage.user(
        content: apiMessage.content,
        timestamp: apiMessage.createdAt,
      );
    } else {
      return ChatMessage.ai(
        content: apiMessage.content,
        type: messageType,
        quickReplies: quickReplies ?? [],
        timestamp: apiMessage.createdAt,
      );
    }
  }

  /// Fallback to local storage if API fails
  ConversationState _loadConversationFromLocal() {
    return _loadConversation();
  }

  /// Load conversation from storage or create welcome message
  ConversationState _loadConversation() {
    // For now, return default conversation
    // TODO: Make this async to properly load from storage

    // Create welcome conversation
    return _createWelcomeConversation();
  }

  /// Create initial welcome conversation
  ConversationState _createWelcomeConversation() {
    final context = _getContext();
    final welcomeMessage = _generateWelcomeMessage(context);

    return ConversationState(
      messages: [welcomeMessage],
      lastUpdated: DateTime.now(),
    );
  }

  /// Get current user context for AI responses
  CoachContext _getContext() {
    final homeState = ref.read(homeNotifierProvider);
    final levelState = ref.read(levelNotifierProvider);

    // Access AsyncValue properly
    final todaysSummary = homeState.when(
      data: (summary) => summary,
      loading: () => null,
      error: (_, __) => null,
    );

    // Get recent achievements from level state AsyncValue
    final recentAchievements = levelState.when(
      data: (level) => level.achievements
          .where((achievement) => achievement.isUnlocked)
          .take(3)
          .map((achievement) => achievement.title)
          .toList(),
      loading: () => <String>[],
      error: (_, __) => <String>[],
    );

    // Get level data from AsyncValue
    final currentLevel = levelState.when(
      data: (level) => level.currentLevel,
      loading: () => 1,
      error: (_, __) => 1,
    );

    final currentStreak = levelState.when(
      data: (level) => level.currentStreak,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return CoachContext(
      hydrationLevel: todaysSummary?.progress ?? 0.0,
      currentLevel: currentLevel,
      streak: currentStreak,
      todayIntake: todaysSummary?.totalEffectiveMl ?? 0,
      dailyGoal: todaysSummary?.dailyGoalMl ?? 2000,
      recentAchievements: recentAchievements,
      overallHealthStatus:
          ref.read(bodyMapNotifierProvider.notifier).overallHealthMessage,
    );
  }

  /// Send user message and get AI response from backend
  Future<void> sendMessage(String content) async {
    state.whenData((currentState) async {
      final userMessage = ChatMessage.user(content: content);

      // Add user message and start typing
      state = AsyncValue.data(
        currentState.addMessage(userMessage).startTyping(),
      );

      try {
        final currentUserId = _getCurrentUserId();
        if (_sessionOwnerUserId != currentUserId) {
          _currentSessionId = null;
          _sessionOwnerUserId = currentUserId;
        }

        // Create one user-scoped session and persist for subsequent messages.
        _currentSessionId ??= await _coachRepository.generateSessionId(
          userId: currentUserId,
        );

        // Get context for API call
        final context = _getContext();
        final contextMap = {
          'hydration_level': context.hydrationLevel,
          'current_level': context.currentLevel,
          'streak': context.streak,
          'today_intake': context.todayIntake,
          'daily_goal': context.dailyGoal,
          'recent_achievements': context.recentAchievements,
          'overall_health_status': context.overallHealthStatus,
        };

        // Send message to backend
        final aiMessage = await _coachRepository.sendMessage(
          content: content,
          sessionId: _currentSessionId,
          userId: currentUserId,
          context: contextMap,
        );

        if (aiMessage == null) {
          throw Exception('Failed to send message');
        }

        // Update state with AI response
        state.whenData((stateAfterSend) {
          state = AsyncValue.data(
            stateAfterSend.stopTyping().addMessage(aiMessage),
          );
        });

        // Schedule next auto suggestion if needed
        _scheduleAutoSuggestion();
      } catch (e) {
        debugPrint('❌ Failed to send message to backend: $e');

        // On error, fall back to local AI generation
        await _handleSendMessageFallback(content);
      }
    });
  }

  String? _getCurrentUserId() {
    final authState = ref.read(authStateProvider);
    final userId = authState.currentUser?.id.trim();
    if (userId == null || userId.isEmpty) {
      return null;
    }
    return userId;
  }

  /// Fallback to local AI generation if backend fails
  Future<void> _handleSendMessageFallback(String content) async {
    try {
      // Generate AI response with delay for natural feel
      await Future.delayed(const Duration(milliseconds: 1500));

      // Get context and generate response locally
      final context = _getContext();
      final aiResponse = _generateAIResponse(content, context);

      // Stop typing and add AI response
      state.whenData((currentState) {
        state = AsyncValue.data(
          currentState.stopTyping().addMessage(aiResponse),
        );
      });

      // Save conversation locally
      await _saveConversationLocal();
    } catch (e) {
      // If everything fails, at least stop the typing indicator
      state.whenData((currentState) {
        state = AsyncValue.data(currentState.stopTyping());
      });
    }
  }

  /// Save conversation to local storage (fallback)
  Future<void> _saveConversationLocal() async {
    state.whenData((currentState) async {
      final storage = HiveStorageService.instance;
      final messagesJson =
          currentState.messages.map((msg) => msg.toJson()).toList();
      await storage.saveCoachConversation(messagesJson);
    });
  }

  /// Send quick reply
  Future<void> sendQuickReply(QuickReply quickReply) async {
    // If we have a session ID, send via backend
    if (_currentSessionId != null) {
      try {
        final response = await _coachRepository.handleQuickReply(
          quickReplyId: quickReply.id,
          sessionId: _currentSessionId!,
        );

        if (response.isSuccess) {
          // Add the AI response to conversation
          final aiMessage = ChatMessage.ai(
            content: response.data!.aiResponse,
            type: MessageType.text,
          );

          state.whenData((currentState) {
            state = AsyncValue.data(currentState.addMessage(aiMessage));
          });
        } else {
          // Fallback to sending the text message
          await sendMessage(quickReply.text);
        }
      } catch (e) {
        debugPrint('Failed to handle quick reply via backend: $e');
        await sendMessage(quickReply.text);
      }
    } else {
      await sendMessage(quickReply.text);
    }

    // Handle special actions
    if (quickReply.action != null) {
      _handleQuickReplyAction(quickReply.action!);
    }
  }

  /// Handle quick reply actions
  void _handleQuickReplyAction(String action) {
    switch (action) {
      case 'log_water':
        // Navigate to log screen (handled by UI)
        break;
      case 'check_stats':
        // Navigate to stats screen (handled by UI)
        break;
      case 'view_achievements':
        // Navigate to level screen (handled by UI)
        break;
      default:
        break;
    }
  }

  /// Generate welcome message based on current context
  ChatMessage _generateWelcomeMessage(CoachContext context) {
    String content;
    List<QuickReply> quickReplies = [];

    final timeOfDay = DateTime.now().hour;

    // Time-based greeting
    String greeting;
    if (timeOfDay < 12) {
      greeting = 'Chào buổi sáng! ☀️';
    } else if (timeOfDay < 18) {
      greeting = 'Chào buổi chiều! 🌤️';
    } else {
      greeting = 'Chào buổi tối! 🌙';
    }

    if (context.isGoalReached) {
      content =
          '$greeting Tuyệt vời! Bạn đã hoàn thành mục tiêu ngày hôm nay rồi! 🎉 Hãy duy trì thói quen tốt này nhé!';
      quickReplies = [
        const QuickReply(
          id: 'check_achievements',
          text: '🏆 Xem thành tích',
          action: 'view_achievements',
        ),
        const QuickReply(id: 'tomorrow_goal', text: '📅 Mục tiêu ngày mai'),
      ];
    } else if (context.completionPercentage >= 0.7) {
      content =
          '$greeting Bạn đang làm rất tốt! Chỉ còn ${context.dailyGoal - context.todayIntake}ml nữa là đạt mục tiêu rồi! 💪';
      quickReplies = [
        const QuickReply(
          id: 'log_final',
          text: '💧 Uống thêm nước',
          action: 'log_water',
        ),
        const QuickReply(id: 'hydration_tips', text: '💡 Gợi ý hydration'),
      ];
    } else if (context.completionPercentage >= 0.3) {
      content =
          '$greeting Bạn đã uống ${context.todayIntake}ml hôm nay. Hãy tiếp tục để đạt mục tiêu ${context.dailyGoal}ml nhé! 🚰';
      quickReplies = [
        const QuickReply(
          id: 'log_water',
          text: '💧 Ghi nhận nước',
          action: 'log_water',
        ),
        const QuickReply(id: 'set_reminder', text: '⏰ Nhắc nhở'),
      ];
    } else {
      content =
          '$greeting Hôm nay bạn mới uống ${context.todayIntake}ml thôi. Hãy bắt đầu bù nước ngay nhé! 💦';
      quickReplies = [
        const QuickReply(
          id: 'log_water',
          text: '💧 Bắt đầu uống',
          action: 'log_water',
        ),
        const QuickReply(id: 'why_important', text: '❓ Tại sao quan trọng?'),
      ];
    }

    return ChatMessage.ai(
      content: content,
      type: MessageType.welcomeCard,
      quickReplies: quickReplies,
    );
  }

  /// Generate AI response based on user input and context
  ChatMessage _generateAIResponse(String userInput, CoachContext context) {
    final input = userInput.toLowerCase();

    // Intent detection and response generation
    if (input.contains('uống') ||
        input.contains('nước') ||
        input.contains('thêm')) {
      return _generateHydrationResponse(context);
    } else if (input.contains('mệt') ||
        input.contains('không khỏe') ||
        input.contains('đau đầu')) {
      return _generateHealthConcernResponse(context);
    } else if (input.contains('mục tiêu') || input.contains('goal')) {
      return _generateGoalResponse(context);
    } else if (input.contains('thành tích') ||
        input.contains('level') ||
        input.contains('xp')) {
      return _generateAchievementResponse(context);
    } else if (input.contains('cơ thể') ||
        input.contains('sức khỏe') ||
        input.contains('organ')) {
      return _generateBodyHealthResponse(context);
    } else if (input.contains('thống kê') ||
        input.contains('stats') ||
        input.contains('báo cáo')) {
      return _generateStatsResponse(context);
    } else if (input.contains('cảm ơn') || input.contains('thank')) {
      return _generateGratitudeResponse(context);
    } else {
      return _generateGeneralResponse(userInput, context);
    }
  }

  /// Generate hydration-focused response
  ChatMessage _generateHydrationResponse(CoachContext context) {
    List<QuickReply> quickReplies = [
      const QuickReply(
        id: 'log_water',
        text: '💧 Ghi nhận ngay',
        action: 'log_water',
      ),
    ];

    if (context.hydrationStatus == 'critical' ||
        context.hydrationStatus == 'poor') {
      return ChatMessage.ai(
        content:
            'Cơ thể bạn đang rất thiếu nước! Hãy uống từ từ 2-3 ly nước trong 30 phút tới để tránh shock. 🚨',
        type: MessageType.suggestion,
        quickReplies: quickReplies,
      );
    } else if (context.hydrationStatus == 'fair') {
      return ChatMessage.ai(
        content:
            'Tốt lắm! Hãy duy trì việc uống nước đều đặn. Mỗi 1-2 tiếng uống 1 ly nước nhé! 💪',
        quickReplies: quickReplies,
      );
    } else {
      return ChatMessage.ai(
        content:
            'Bạn đang hydrate rất tốt! Tiếp tục duy trì thói quen này để cơ thể luôn khỏe mạnh! ✨',
        quickReplies: [
          const QuickReply(
            id: 'body_map',
            text: '🗺️ Xem cơ thể',
            action: 'check_body',
          ),
        ],
      );
    }
  }

  /// Generate health concern response
  ChatMessage _generateHealthConcernResponse(CoachContext context) {
    String content;
    List<QuickReply> quickReplies = [
      const QuickReply(
        id: 'log_water',
        text: '💧 Uống nước ngay',
        action: 'log_water',
      ),
    ];

    if (context.hydrationLevel < 0.4) {
      content =
          'Triệu chứng này có thể do thiếu nước! Cơ thể bạn chỉ đạt ${(context.hydrationLevel * 100).round()}% hydration. Hãy uống nước ngay và nghỉ ngơi! 🏥';
      quickReplies.add(
        const QuickReply(id: 'health_tips', text: '💡 Lời khuyên sức khỏe'),
      );
    } else {
      content =
          'Nghe có vẻ bạn cần nghỉ ngơi. Hãy uống thêm nước và thư giãn một chút nhé! Hydration tốt sẽ giúp bạn cảm thấy khỏe hơn! 😌';
    }

    return ChatMessage.ai(
      content: content,
      type: MessageType.suggestion,
      quickReplies: quickReplies,
    );
  }

  /// Generate goal-related response
  ChatMessage _generateGoalResponse(CoachContext context) {
    final remaining = context.dailyGoal - context.todayIntake;

    if (context.isGoalReached) {
      return ChatMessage.ai(
        content:
            'Bạn đã hoàn thành mục tiêu ${context.dailyGoal}ml hôm nay! 🎯 Tuyệt vời! Ngày mai chúng ta sẽ tiếp tục nhé!',
        type: MessageType.achievement,
        quickReplies: [
          const QuickReply(
            id: 'tomorrow_planning',
            text: '📅 Lên kế hoạch ngày mai',
          ),
        ],
      );
    } else {
      return ChatMessage.ai(
        content:
            'Bạn còn ${remaining}ml nữa để đạt mục tiêu ${context.dailyGoal}ml. Đó là khoảng ${(remaining / 250).ceil()} ly nước nữa thôi! 💪',
        quickReplies: [
          const QuickReply(
            id: 'log_water',
            text: '💧 Tiếp tục uống',
            action: 'log_water',
          ),
          const QuickReply(id: 'adjust_goal', text: '⚙️ Điều chỉnh mục tiêu'),
        ],
      );
    }
  }

  /// Generate achievement response
  ChatMessage _generateAchievementResponse(CoachContext context) {
    String content = 'Bạn đang ở Level ${context.currentLevel}';

    if (context.streak > 0) {
      content += ' với streak ${context.streak} ngày! 🔥';
    } else {
      content += '. Hãy bắt đầu xây dựng streak mới nhé! 🚀';
    }

    if (context.recentAchievements.isNotEmpty) {
      content +=
          '\n\nThành tích gần đây: ${context.recentAchievements.join(', ')} 🏆';
    }

    return ChatMessage.ai(
      content: content,
      type: MessageType.achievement,
      quickReplies: [
        const QuickReply(
          id: 'view_level',
          text: '🎯 Xem Level',
          action: 'view_achievements',
        ),
        const QuickReply(id: 'next_milestone', text: '🎯 Mục tiêu tiếp theo'),
      ],
    );
  }

  /// Generate body health response
  ChatMessage _generateBodyHealthResponse(CoachContext context) {
    return ChatMessage.ai(
      content: context.overallHealthStatus,
      type: MessageType.suggestion,
      quickReplies: [
        const QuickReply(
          id: 'check_body_map',
          text: '🗺️ Xem bản đồ cơ thể',
          action: 'check_body',
        ),
        const QuickReply(id: 'health_tips', text: '💡 Lời khuyên sức khỏe'),
      ],
    );
  }

  /// Generate stats response
  ChatMessage _generateStatsResponse(CoachContext context) {
    return ChatMessage.ai(
      content:
          'Hôm nay bạn đã uống ${context.todayIntake}ml (${(context.completionPercentage * 100).round()}% mục tiêu). Streak hiện tại: ${context.streak} ngày! 📊',
      quickReplies: [
        const QuickReply(
          id: 'detailed_stats',
          text: '📈 Chi tiết thống kê',
          action: 'check_stats',
        ),
        const QuickReply(id: 'weekly_summary', text: '📅 Tóm tắt tuần'),
      ],
    );
  }

  /// Generate gratitude response
  ChatMessage _generateGratitudeResponse(CoachContext context) {
    return ChatMessage.ai(
      content:
          'Không có gì! Tôi luôn ở đây để hỗ trợ bạn duy trì thói quen hydration tốt! Hãy cùng giữ sức khỏe nhé! 🤗',
      quickReplies: [const QuickReply(id: 'daily_tip', text: '💡 Tip hôm nay')],
    );
  }

  /// Generate general response
  ChatMessage _generateGeneralResponse(String userInput, CoachContext context) {
    final responses = [
      'Tôi hiểu bạn đang quan tâm về hydration! Hãy cho tôi biết tôi có thể giúp gì cho bạn? 💧',
      'AQUA AI luôn sẵn sàng hỗ trợ bạn! Bạn muốn tôi giúp gì về việc uống nước hôm nay? 🤖',
      'Cảm ơn bạn đã chia sẻ! Tôi có thể giúp bạn theo dõi hydration hoặc đưa ra lời khuyên sức khỏe nhé! ✨',
    ];

    return ChatMessage.ai(
      content: responses[DateTime.now().millisecond % responses.length],
      quickReplies: [
        const QuickReply(
          id: 'log_water',
          text: '💧 Ghi nhận nước',
          action: 'log_water',
        ),
        const QuickReply(id: 'health_check', text: '🩺 Kiểm tra sức khỏe'),
        const QuickReply(id: 'daily_tips', text: '💡 Lời khuyên hôm nay'),
      ],
    );
  }

  /// Schedule automatic suggestion based on hydration level
  void _scheduleAutoSuggestion() {
    _autoSuggestionTimer?.cancel();

    final context = _getContext();

    // Schedule reminder if hydration is low
    if (context.hydrationLevel < 0.6 && !context.isGoalReached) {
      _autoSuggestionTimer = Timer(const Duration(hours: 2), () {
        _sendAutoSuggestion();
      });
    }
  }

  /// Send automatic suggestion
  void _sendAutoSuggestion() {
    final context = _getContext();
    final suggestion = _generateAutoSuggestion(context);

    state.whenData((currentState) {
      state = AsyncValue.data(currentState.addMessage(suggestion));
      _saveConversation();
    });
  }

  /// Generate automatic suggestion message
  ChatMessage _generateAutoSuggestion(CoachContext context) {
    final timeOfDay = DateTime.now().hour;
    String content;

    if (timeOfDay >= 6 && timeOfDay < 10) {
      content = 'Chào buổi sáng! Hãy bắt đầu ngày mới bằng 1-2 ly nước nhé! ☀️';
    } else if (timeOfDay >= 10 && timeOfDay < 14) {
      content =
          'Đã 2 tiếng rồi! Đừng quên uống nước để duy trì năng lượng nhé! 💪';
    } else if (timeOfDay >= 14 && timeOfDay < 18) {
      content =
          'Buổi chiều rồi! Hãy uống thêm nước để tập trung làm việc tốt hơn! 🌤️';
    } else {
      content =
          'Tối rồi! Uống ít nước ấm để thư giãn và chuẩn bị ngủ ngon nhé! 🌙';
    }

    return ChatMessage.ai(
      content: content,
      type: MessageType.reminder,
      quickReplies: [
        const QuickReply(
          id: 'log_water',
          text: '💧 Đã uống rồi!',
          action: 'log_water',
        ),
        const QuickReply(id: 'remind_later', text: '⏰ Nhắc lại sau'),
      ],
    );
  }

  /// Save conversation to storage
  Future<void> _saveConversation() async {
    state.whenData((currentState) async {
      final storage = HiveStorageService.instance;
      final messagesJson =
          currentState.messages.map((msg) => msg.toJson()).toList();
      await storage.saveCoachConversation(messagesJson);
    });
  }

  /// Reset conversation for new user (called on auth state change)
  void _resetForNewUser() async {
    debugPrint('🔄 Resetting conversation for new user');

    // Cancel any ongoing timers
    _autoSuggestionTimer?.cancel();

    // Reset session state
    _currentSessionId = null;
    _sessionOwnerUserId = null;

    // Reset provider state and load fresh conversation for new user
    state = const AsyncValue.loading();

    try {
      final newConversation = await _loadConversationFromApi();
      state = AsyncValue.data(newConversation);
    } catch (e) {
      // Fallback to welcome conversation if API fails
      state = AsyncValue.data(_createWelcomeConversation());
    }
  }

  /// Clear conversation
  Future<void> clearConversation() async {
    // Archive current session if it exists
    if (_currentSessionId != null) {
      try {
        await _coachRepository.archiveConversationSession(_currentSessionId!);
      } catch (e) {
        debugPrint('Failed to archive session: $e');
      }
    }

    // Reset session ID and create new welcome conversation
    _currentSessionId = null;
    _sessionOwnerUserId = _getCurrentUserId();
    state = AsyncValue.data(_createWelcomeConversation());
    await _saveConversation();
  }

  /// Refresh conversation with updated context
  void refreshContext() {
    // Update conversation context if we have a session
    if (_currentSessionId != null) {
      final context = _getContext();
      final contextMap = {
        'hydration_level': context.hydrationLevel,
        'current_level': context.currentLevel,
        'streak': context.streak,
        'today_intake': context.todayIntake,
        'daily_goal': context.dailyGoal,
        'recent_achievements': context.recentAchievements,
        'overall_health_status': context.overallHealthStatus,
      };

      _coachRepository.updateConversationContext(
        sessionId: _currentSessionId!,
        context: contextMap,
      );
    }

    // Just trigger rebuild with current messages
    state.whenData((currentState) {
      state = AsyncValue.data(
        currentState.copyWith(lastUpdated: DateTime.now()),
      );
    });
  }
}
