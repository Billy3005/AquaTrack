import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/repositories/coach_repository.dart';
import '../../../core/utils/logger.dart';
import '../models/chat_message.dart';

/// Provider for coach conversation management
final coachChatNotifierProvider =
    StateNotifierProvider<CoachChatNotifier, ConversationState>(
  (ref) => CoachChatNotifier(),
);

/// Coach Chat State Notifier
class CoachChatNotifier extends StateNotifier<ConversationState> {
  static const String _tag = 'CoachChatNotifier';

  final CoachRepository _coachRepository;
  String? _currentSessionId;

  CoachChatNotifier({CoachRepository? coachRepository})
      : _coachRepository = coachRepository ?? CoachRepository(),
        super(ConversationState(lastUpdated: DateTime.now())) {
    _initializeConversation();
  }

  /// Initialize conversation with welcome message
  Future<void> _initializeConversation() async {
    AppLogger.info(_tag, 'Initializing conversation');

    try {
      // Generate session ID
      _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      // Load conversation history if exists
      await _loadConversationHistory();

      // If no messages, send welcome message
      if (state.messages.isEmpty) {
        await _sendWelcomeMessage();
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to initialize conversation', e);
      _addErrorMessage('Không thể khởi tạo cuộc trò chuyện');
    }
  }

  /// Load conversation history from backend
  Future<void> _loadConversationHistory() async {
    if (_currentSessionId == null) return;

    try {
      final messages = await _coachRepository.getConversationHistory(
        sessionId: _currentSessionId!,
      );

      if (messages != null) {
        final chatMessages =
            messages.map((msg) => _convertToChatMessage(msg)).toList();
        state = state.copyWith(messages: chatMessages);
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to load conversation history', e);
    }
  }

  /// Send welcome message
  Future<void> _sendWelcomeMessage() async {
    final welcomeMessage = ChatMessage.ai(
      content:
          'Xin chào! Tôi là AQUA AI Coach 💧\n\nTôi ở đây để giúp bạn duy trì thói quen uống nước tốt. Hôm nay bạn thế nào?',
      type: MessageType.welcomeCard,
      quickReplies: [
        QuickReply(id: 'good', text: 'Tôi khỏe!'),
        QuickReply(id: 'tired', text: 'Hơi mệt mỏi'),
        QuickReply(id: 'progress', text: 'Xem tiến độ hôm nay'),
      ],
    );

    state = state.addMessage(welcomeMessage);
  }

  /// Send user message and get AI response
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;

    // Add user message immediately
    final userMessage = ChatMessage.user(content: content.trim());
    state = state.addMessage(userMessage);

    // Show typing indicator
    state = state.startTyping();

    try {
      // Get context for enhanced AI response
      final context = await _buildMessageContext();

      // Send to backend and get AI response
      final aiMessage = await _coachRepository.sendMessage(
        content: content,
        sessionId: _currentSessionId,
        context: context,
      );

      // Stop typing and add AI response
      state = state.stopTyping();

      if (aiMessage != null) {
        state = state.addMessage(aiMessage);
      } else {
        _addErrorMessage('Xin lỗi, tôi không thể phản hồi ngay bây giờ');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to send message', e);
      state = state.stopTyping();
      _addErrorMessage('Có lỗi xảy ra khi gửi tin nhắn');
    }
  }

  /// Handle quick reply selection
  Future<void> handleQuickReply(String quickReplyId, String text) async {
    AppLogger.info(_tag, 'Handling quick reply: $quickReplyId');

    // Handle special quick reply actions
    switch (quickReplyId) {
      case 'log_250ml':
        await _handleLogWaterQuickReply(250);
        break;
      case 'progress':
        await _handleProgressQuickReply();
        break;
      case 'reminder':
        await _handleReminderQuickReply();
        break;
      default:
        // Send as regular message
        await sendMessage(text);
    }
  }

  /// Handle water logging quick reply
  Future<void> _handleLogWaterQuickReply(int amount) async {
    try {
      // This would integrate with intake logging
      AppLogger.info(_tag, 'Logging ${amount}ml water via quick reply');

      // Send confirmation message
      await sendMessage('Uống ${amount}ml ngay');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to log water', e);
    }
  }

  /// Handle progress check quick reply
  Future<void> _handleProgressQuickReply() async {
    await sendMessage('Xem tiến độ hôm nay');
  }

  /// Handle reminder setup quick reply
  Future<void> _handleReminderQuickReply() async {
    await sendMessage('Đặt nhắc nhở');
  }

  /// Build message context for enhanced AI responses
  Future<Map<String, dynamic>> _buildMessageContext() async {
    final now = DateTime.now();

    return {
      'current_hour': now.hour,
      'is_weekend': now.weekday > 5,
      'total_today': 1200, // This would come from actual intake data
      'daily_goal': 2000, // This would come from user settings
      'session_id': _currentSessionId,
      'conversation_length': state.messages.length,
    };
  }

  /// Convert backend message to ChatMessage
  ChatMessage _convertToChatMessage(dynamic backendMessage) {
    // This converts from backend message format to our ChatMessage model
    final isFromUser = backendMessage.messageType == 'user';
    final content = backendMessage.content ?? '';
    final timestamp = backendMessage.createdAt ?? DateTime.now();

    if (isFromUser) {
      return ChatMessage.user(content: content, timestamp: timestamp);
    } else {
      return ChatMessage.ai(
        content: content,
        type: MessageType.text,
        quickReplies: _convertQuickReplies(backendMessage.quickReplies),
        timestamp: timestamp,
      );
    }
  }

  /// Convert backend quick replies to our format
  List<QuickReply> _convertQuickReplies(dynamic quickReplies) {
    if (quickReplies == null) return [];

    try {
      final List<dynamic> repliesJson = quickReplies as List<dynamic>? ?? [];
      return repliesJson
          .map(
            (qr) => QuickReply(
              id: qr['id'] ?? '',
              text: qr['text'] ?? '',
              action: qr['action'],
            ),
          )
          .toList();
    } catch (e) {
      AppLogger.error(_tag, 'Failed to convert quick replies', e);
      return [];
    }
  }

  /// Add error message to conversation
  void _addErrorMessage(String error) {
    final errorMessage = ChatMessage.ai(content: error, type: MessageType.text);
    state = state.addMessage(errorMessage);
  }

  /// Clear conversation
  void clearConversation() {
    state = ConversationState(lastUpdated: DateTime.now());
    _currentSessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Refresh conversation
  Future<void> refreshConversation() async {
    await _loadConversationHistory();
  }
}
