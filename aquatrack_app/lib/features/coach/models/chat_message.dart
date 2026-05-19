import 'dart:math';

/// Types of chat messages in coach conversation
enum MessageType { text, suggestion, achievement, reminder, welcomeCard }

/// Quick reply option for user responses
class QuickReply {
  final String id;
  final String text;
  final String? action;

  const QuickReply({required this.id, required this.text, this.action});

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'action': action};
  }

  factory QuickReply.fromJson(Map<String, dynamic> json) {
    return QuickReply(
      id: json['id'] as String,
      text: json['text'] as String,
      action: json['action'] as String?,
    );
  }
}

/// Chat message model for AQUA AI Coach conversations
class ChatMessage {
  static final _random = Random();

  /// Generate unique ID for messages
  static String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = _random.nextInt(9999);
    return '${timestamp}_$randomSuffix';
  }

  final String id;
  final String content;
  final bool isFromUser;
  final DateTime timestamp;
  final MessageType type;
  final List<QuickReply> quickReplies;
  final bool isTyping;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isFromUser,
    required this.timestamp,
    this.type = MessageType.text,
    this.quickReplies = const [],
    this.isTyping = false,
  });

  /// Create user message
  factory ChatMessage.user({required String content, DateTime? timestamp}) {
    return ChatMessage(
      id: _generateId(),
      content: content,
      isFromUser: true,
      timestamp: timestamp ?? DateTime.now(),
      type: MessageType.text,
    );
  }

  /// Create AI message
  factory ChatMessage.ai({
    required String content,
    MessageType type = MessageType.text,
    List<QuickReply> quickReplies = const [],
    DateTime? timestamp,
  }) {
    return ChatMessage(
      id: _generateId(),
      content: content,
      isFromUser: false,
      timestamp: timestamp ?? DateTime.now(),
      type: type,
      quickReplies: quickReplies,
    );
  }

  /// Create typing indicator
  factory ChatMessage.typing() {
    return ChatMessage(
      id: 'typing',
      content: '',
      isFromUser: false,
      timestamp: DateTime.now(),
      isTyping: true,
    );
  }

  /// Copy with modifications
  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isFromUser,
    DateTime? timestamp,
    MessageType? type,
    List<QuickReply>? quickReplies,
    bool? isTyping,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isFromUser: isFromUser ?? this.isFromUser,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      quickReplies: quickReplies ?? this.quickReplies,
      isTyping: isTyping ?? this.isTyping,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isFromUser': isFromUser,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'quickReplies': quickReplies.map((qr) => qr.toJson()).toList(),
      'isTyping': isTyping,
    };
  }

  /// Create from JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isFromUser: json['isFromUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      quickReplies:
          (json['quickReplies'] as List<dynamic>?)
              ?.map((qr) => QuickReply.fromJson(qr as Map<String, dynamic>))
              .toList() ??
          [],
      isTyping: json['isTyping'] as bool? ?? false,
    );
  }

  /// Check if message is from today
  bool get isFromToday {
    final now = DateTime.now();
    return timestamp.year == now.year &&
        timestamp.month == now.month &&
        timestamp.day == now.day;
  }

  /// Get time display string
  String get timeDisplay {
    return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }
}

/// Conversation state model
class ConversationState {
  final List<ChatMessage> messages;
  final bool isAiTyping;
  final String? contextData;
  final DateTime lastUpdated;

  const ConversationState({
    this.messages = const [],
    this.isAiTyping = false,
    this.contextData,
    required this.lastUpdated,
  });

  ConversationState copyWith({
    List<ChatMessage>? messages,
    bool? isAiTyping,
    String? contextData,
    DateTime? lastUpdated,
  }) {
    return ConversationState(
      messages: messages ?? this.messages,
      isAiTyping: isAiTyping ?? this.isAiTyping,
      contextData: contextData ?? this.contextData,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// Add new message to conversation
  ConversationState addMessage(ChatMessage message) {
    final updatedMessages = [...messages];

    // Remove typing indicator if exists
    updatedMessages.removeWhere((msg) => msg.isTyping);

    // Add new message
    updatedMessages.add(message);

    return copyWith(messages: updatedMessages, lastUpdated: DateTime.now());
  }

  /// Start AI typing indicator
  ConversationState startTyping() {
    if (isAiTyping) return this;

    return copyWith(
      messages: [...messages, ChatMessage.typing()],
      isAiTyping: true,
    );
  }

  /// Stop AI typing indicator
  ConversationState stopTyping() {
    final updatedMessages = messages.where((msg) => !msg.isTyping).toList();

    return copyWith(messages: updatedMessages, isAiTyping: false);
  }

  /// Get messages from today
  List<ChatMessage> get todaysMessages {
    return messages.where((msg) => msg.isFromToday).toList();
  }

  /// Get last user message
  ChatMessage? get lastUserMessage {
    try {
      return messages.lastWhere((msg) => msg.isFromUser);
    } catch (e) {
      return null;
    }
  }

  /// Get last AI message
  ChatMessage? get lastAiMessage {
    try {
      return messages.lastWhere((msg) => !msg.isFromUser && !msg.isTyping);
    } catch (e) {
      return null;
    }
  }
}
