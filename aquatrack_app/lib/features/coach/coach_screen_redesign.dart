import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../shared/models/daily_summary.dart';
import '../home/providers/home_provider.dart';
import 'models/chat_message.dart';
import 'providers/coach_chat_provider.dart';

/// Coach Screen - Complete redesign matching aquatrack/project/components/coach.jsx
class CoachScreenRedesign extends ConsumerStatefulWidget {
  const CoachScreenRedesign({super.key});

  @override
  ConsumerState<CoachScreenRedesign> createState() =>
      _CoachScreenRedesignState();
}

class _CoachScreenRedesignState extends ConsumerState<CoachScreenRedesign>
    with TickerProviderStateMixin {
  late TextEditingController _textController;
  late ScrollController _scrollController;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  // Messages are now handled by provider

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _scrollController = ScrollController();
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _typingAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );

    _typingController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Send message via provider
    await ref.read(coachChatNotifierProvider.notifier).sendMessage(text);

    _scrollToBottom();
  }

  Future<void> _handleQuickReply(String reply) async {
    // Handle special actions
    if (reply == 'Uống 250ml ngay') {
      // Log water
      await ref.read(homeNotifierProvider.notifier).quickLog(250);
    }

    // Send as message via provider
    await ref.read(coachChatNotifierProvider.notifier).sendMessage(reply);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Build empty state when no messages
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyanAccent.withValues(alpha: 0.2),
                  AppColors.cyanAccent.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(
                color: AppColors.cyanAccent.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 32,
              color: AppColors.cyanAccent,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AQUA AI Coach sẵn sàng hỗ trợ bạn!',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final homeSummaryAsync = ref.watch(homeNotifierProvider);
    final conversationState = ref.watch(coachChatNotifierProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: AppColors.nightBase,
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(homeSummaryAsync),

              // Messages
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
                  child: Column(
                    children: [
                      // Day separator
                      _buildDaySeparator(),
                      const SizedBox(height: 14),

                      // Message list
                      Expanded(
                        child: conversationState.messages.isEmpty
                            ? _buildEmptyState()
                            : ListView.builder(
                                controller: _scrollController,
                                itemCount: conversationState.messages.length,
                                itemBuilder: (context, index) {
                                  final message =
                                      conversationState.messages[index];
                                  return message.isTyping
                                      ? _buildThinkingIndicator()
                                      : _buildMessageBubble(message);
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),

              // Input composer
              _buildComposer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<DailySummary> homeSummaryAsync) {
    return homeSummaryAsync.when(
      data: (summary) {
        final current = summary.totalEffectiveMl;
        final goal = summary.dailyGoalMl;
        final percent = ((current / goal) * 100).clamp(0, 100).round();

        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A2545), AppColors.nightBase],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(16, 50, 16, 14),
          child: Column(
            children: [
              // Top row with AI info and close button
              Row(
                children: [
                  // AI Avatar
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: const RadialGradient(
                        center: Alignment(0.3, 0.3),
                        colors: [Color(0xFF7DD3FC), Color(0xFF0EA5E9)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0x9938BDF8,
                          ), // rgba(56,189,248,0.6)
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Aqua AI',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFF10B981),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'online · context-aware',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF86EFAC),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Close button
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Đóng',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Progress bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                decoration: BoxDecoration(
                  color: const Color(0x99081E38), // rgba(8,30,56,0.6)
                  border: Border.all(
                    color: const Color(0x3338BDF8), // rgba(56,189,248,0.2)
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.water_drop,
                      color: Color(0xFF38BDF8),
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          // Progress text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${current.toString()} / ${goal.toString()}ml',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Text',
                                ),
                              ),
                              Text(
                                '$percent%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.glow,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'SF Pro Rounded',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Progress bar
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: percent / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF0EA5E9),
                                      Color(0xFF38BDF8),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0x9938BDF8,
                                      ), // rgba(56,189,248,0.6)
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => _buildHeaderLoading(),
      error: (error, stack) => _buildHeaderError(),
    );
  }

  Widget _buildHeaderLoading() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A2545), AppColors.nightBase],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 14),
      child: const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildHeaderError() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A2545), AppColors.nightBase],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 14),
      child: const Text(
        'Error loading data',
        style: TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildDaySeparator() {
    return Text(
      'HÔM NAY',
      style: TextStyle(
        fontSize: 10,
        color: AppColors.textMuted,
        fontFamily: 'SF Pro Text',
        letterSpacing: 0.1,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Build thinking indicator with animation
  Widget _buildThinkingIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Đang suy nghĩ',
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.45,
                    fontFamily: 'SF Pro Text',
                    color: Color(0xFFBAE6FD),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (context, child) {
                    return Row(
                      children: List.generate(3, (index) {
                        double delay = index * 0.3;
                        double opacity =
                            ((_typingAnimation.value + delay) % 1.0);
                        if (opacity > 0.5) opacity = 1.0 - opacity;
                        opacity = opacity * 2; // Make it more visible

                        return Container(
                          margin: EdgeInsets.only(
                            left: index > 0 ? 3 : 0,
                          ),
                          child: Opacity(
                            opacity: opacity.clamp(0.3, 1.0),
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: const BoxDecoration(
                                color: Color(0xFF38BDF8),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ],
            ),
          ),

          // Time
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isAi = !message.isFromUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment:
            isAi ? CrossAxisAlignment.start : CrossAxisAlignment.end,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            decoration: BoxDecoration(
              color: isAi ? const Color(0xFF1E3A5F) : null,
              gradient: isAi
                  ? null
                  : const LinearGradient(
                      begin: Alignment(-1.35, -1.35),
                      end: Alignment(1.35, 1.35),
                      colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
                    ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isAi ? 4 : 14),
                topRight: Radius.circular(isAi ? 14 : 4),
                bottomLeft: const Radius.circular(14),
                bottomRight: const Radius.circular(14),
              ),
              boxShadow: isAi
                  ? null
                  : [
                      BoxShadow(
                        color: const Color(0x400EA5E9), // rgba(14,165,233,0.25)
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                fontFamily: 'SF Pro Text',
                color: isAi ? const Color(0xFFBAE6FD) : Colors.white,
              ),
            ),
          ),

          // Quick replies
          if (message.quickReplies.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.85,
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: message.quickReplies.map((reply) {
                  return GestureDetector(
                    onTap: () => _handleQuickReply(reply.text),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
                      decoration: BoxDecoration(
                        color: const Color(0x1F38BDF8), // rgba(56,189,248,0.12)
                        border: Border.all(
                          color: const Color(
                            0x4D38BDF8,
                          ), // rgba(56,189,248,0.3)
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        reply.text,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'SF Pro Text',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFFBAE6FD),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // Time
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              message.timeDisplay,
              style: TextStyle(
                fontSize: 9.5,
                color: AppColors.textMuted,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 28),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0x1438BDF8), // rgba(56,189,248,0.08)
          ),
        ),
        color: const Color(0x990F1A2E), // rgba(15,26,46,0.6)
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.05),
            BlendMode.lighten,
          ),
          child: Row(
            children: [
              // Text input
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  decoration: BoxDecoration(
                    color: AppColors.nightCard,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                            fontFamily: 'SF Pro Text',
                          ),
                          decoration: InputDecoration(
                            hintText: 'Hỏi Aqua AI bất cứ điều gì...',
                            hintStyle: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onSubmitted: _sendMessage,
                          textInputAction: TextInputAction.send,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Send button
              GestureDetector(
                onTap: () => _sendMessage(_textController.text),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    gradient: _textController.text.trim().isNotEmpty
                        ? const LinearGradient(
                            begin: Alignment(-1.35, -1.35),
                            end: Alignment(1.35, 1.35),
                            colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
                          )
                        : null,
                    color: _textController.text.trim().isEmpty
                        ? const Color(0x3338BDF8) // rgba(56,189,248,0.2)
                        : null,
                    shape: BoxShape.circle,
                    boxShadow: _textController.text.trim().isNotEmpty
                        ? [
                            BoxShadow(
                              color: const Color(
                                0x660EA5E9,
                              ), // rgba(14,165,233,0.4)
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Message model
// Local classes removed - using models/chat_message.dart instead
