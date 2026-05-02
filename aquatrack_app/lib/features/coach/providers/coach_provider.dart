import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../shared/storage/hive_storage_service.dart';
import '../../home/providers/home_provider.dart';
import '../../level/providers/level_provider.dart';
import '../../body_map/providers/body_map_provider.dart';
import '../models/chat_message.dart';

part 'coach_provider.g.dart';

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

/// Coach notifier với AI conversation management
@riverpod
class CoachNotifier extends _$CoachNotifier {
  late Timer? _autoSuggestionTimer;

  @override
  ConversationState build() {
    // Cancel timer when provider is disposed
    ref.onDispose(() {
      _autoSuggestionTimer?.cancel();
    });

    return _loadConversation();
  }

  /// Load conversation from storage or create welcome message
  ConversationState _loadConversation() {
    final storage = HiveStorageService.instance;

    // Try to load existing conversation
    final savedConversation = storage.loadCoachConversation();
    if (savedConversation != null && savedConversation.isNotEmpty) {
      final messages =
          savedConversation.map((json) => ChatMessage.fromJson(json)).toList();

      return ConversationState(
        messages: messages,
        lastUpdated: DateTime.now(),
      );
    }

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

    // Get recent achievements (simplified for now)
    final recentAchievements = levelState.achievements
        .where((achievement) => achievement.isUnlocked)
        .take(3)
        .map((achievement) => achievement.title)
        .toList();

    return CoachContext(
      hydrationLevel: todaysSummary?.progress ?? 0.0,
      currentLevel: levelState.currentLevel,
      streak: levelState.currentStreak,
      todayIntake: todaysSummary?.totalEffectiveMl ?? 0,
      dailyGoal: todaysSummary?.dailyGoalMl ?? 2000,
      recentAchievements: recentAchievements,
      overallHealthStatus:
          ref.read(bodyMapNotifierProvider.notifier).overallHealthMessage,
    );
  }

  /// Send user message and get AI response
  Future<void> sendMessage(String content) async {
    final userMessage = ChatMessage.user(content: content);

    // Add user message
    state = state.addMessage(userMessage);

    // Start AI typing indicator
    state = state.startTyping();

    // Save conversation
    await _saveConversation();

    // Generate AI response with delay for natural feel
    await Future.delayed(const Duration(milliseconds: 1500));

    // Get context and generate response
    final context = _getContext();
    final aiResponse = _generateAIResponse(content, context);

    // Stop typing and add AI response
    state = state.stopTyping();
    state = state.addMessage(aiResponse);

    // Save updated conversation
    await _saveConversation();

    // Schedule next auto suggestion if needed
    _scheduleAutoSuggestion();
  }

  /// Send quick reply
  Future<void> sendQuickReply(QuickReply quickReply) async {
    await sendMessage(quickReply.text);

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
        const QuickReply(
          id: 'tomorrow_goal',
          text: '📅 Mục tiêu ngày mai',
        ),
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
        const QuickReply(
          id: 'hydration_tips',
          text: '💡 Gợi ý hydration',
        ),
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
        const QuickReply(
          id: 'set_reminder',
          text: '⏰ Nhắc nhở',
        ),
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
        const QuickReply(
          id: 'why_important',
          text: '❓ Tại sao quan trọng?',
        ),
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
      quickReplies.add(const QuickReply(
        id: 'health_tips',
        text: '💡 Lời khuyên sức khỏe',
      ));
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
          const QuickReply(
            id: 'adjust_goal',
            text: '⚙️ Điều chỉnh mục tiêu',
          ),
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
        const QuickReply(
          id: 'next_milestone',
          text: '🎯 Mục tiêu tiếp theo',
        ),
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
        const QuickReply(
          id: 'health_tips',
          text: '💡 Lời khuyên sức khỏe',
        ),
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
        const QuickReply(
          id: 'weekly_summary',
          text: '📅 Tóm tắt tuần',
        ),
      ],
    );
  }

  /// Generate gratitude response
  ChatMessage _generateGratitudeResponse(CoachContext context) {
    return ChatMessage.ai(
      content:
          'Không có gì! Tôi luôn ở đây để hỗ trợ bạn duy trì thói quen hydration tốt! Hãy cùng giữ sức khỏe nhé! 🤗',
      quickReplies: [
        const QuickReply(
          id: 'daily_tip',
          text: '💡 Tip hôm nay',
        ),
      ],
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
        const QuickReply(
          id: 'health_check',
          text: '🩺 Kiểm tra sức khỏe',
        ),
        const QuickReply(
          id: 'daily_tips',
          text: '💡 Lời khuyên hôm nay',
        ),
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

    state = state.addMessage(suggestion);
    _saveConversation();
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
        const QuickReply(
          id: 'remind_later',
          text: '⏰ Nhắc lại sau',
        ),
      ],
    );
  }

  /// Save conversation to storage
  Future<void> _saveConversation() async {
    final storage = HiveStorageService.instance;
    final messagesJson = state.messages.map((msg) => msg.toJson()).toList();
    await storage.saveCoachConversation(messagesJson);
  }

  /// Clear conversation
  Future<void> clearConversation() async {
    state = _createWelcomeConversation();
    await _saveConversation();
  }

  /// Refresh conversation with updated context
  void refreshContext() {
    // Just trigger rebuild with current messages
    state = state.copyWith(lastUpdated: DateTime.now());
  }
}
