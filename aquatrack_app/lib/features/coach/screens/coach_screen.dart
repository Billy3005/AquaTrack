import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/chat_message.dart';
import '../providers/coach_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_input.dart';

/// Screen 02 — AI Coach (Chat Interface)
/// Chat UI với AQUA AI assistant
class CoachScreen extends ConsumerStatefulWidget {
  const CoachScreen({super.key});

  @override
  ConsumerState<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends ConsumerState<CoachScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to bottom when new messages arrive
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversationAsyncState = ref.watch(coachNotifierProvider);

    // Auto scroll when messages change
    ref.listen(coachNotifierProvider, (previous, next) {
      // Simple check - scroll when state changes to data
      if (next.hasValue) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: conversationAsyncState.when(
              data: (conversationState) =>
                  _buildMessagesArea(conversationState),
              loading: () => _buildLoadingState(),
              error: (error, stack) => _buildErrorState(error),
            ),
          ),

          // Chat input
          _buildChatInput(),
        ],
      ),
    );
  }

  /// Build app bar với AQUA AI branding
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Row(
        children: [
          // AI Avatar
          Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cyan, AppColors.xpPurple],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop,
                  color: Colors.white,
                  size: 20,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(
                duration: 2000.ms,
                color: Colors.white.withValues(alpha: 0.3),
              )
              .scale(
                begin: const Offset(0.95, 0.95),
                end: const Offset(1.05, 1.05),
                duration: 1500.ms,
              ),

          const SizedBox(width: 12),

          // Title and status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AQUA AI',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                Text(
                  'Trợ lý hydration thông minh',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: false,
      actions: [
        // Menu button
        PopupMenuButton<String>(
          icon: const Icon(
            Icons.more_vert_rounded,
            color: AppColors.textSecondary,
          ),
          color: AppColors.surface,
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  const Icon(
                    Icons.clear_all_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Xóa cuộc trò chuyện',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Làm mới context',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Handle menu actions
  void _handleMenuAction(String action) {
    final notifier = ref.read(coachNotifierProvider.notifier);

    switch (action) {
      case 'clear':
        _showClearConfirmation(notifier);
        break;
      case 'refresh':
        notifier.refreshContext();
        break;
    }
  }

  /// Show clear conversation confirmation
  void _showClearConfirmation(CoachNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Xóa cuộc trò chuyện',
          style: AppTextStyles.headingMedium.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        content: Text(
          'Bạn có chắc muốn xóa toàn bộ cuộc trò chuyện với AQUA AI không?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              notifier.clearConversation();
            },
            child: Text(
              'Xóa',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  /// Build messages area
  Widget _buildMessagesArea(ConversationState conversationState) {
    if (conversationState.messages.isEmpty) {
      return _buildEmptyState();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.background,
            AppColors.surface.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: conversationState.messages.length,
        itemBuilder: (context, index) {
          final message = conversationState.messages[index];
          return ChatBubble(
            message: message,
            onQuickReplyTap: (quickReply) {
              _handleQuickReply(quickReply);
            },
          );
        },
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.cyan, AppColors.xpPurple],
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.cyan.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 2000.ms,
              ),

          const SizedBox(height: 24),

          Text(
            'Chào mừng đến với AQUA AI! 👋',
            style: AppTextStyles.headingMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tôi sẽ giúp bạn duy trì thói quen hydration tốt.\nHãy bắt đầu cuộc trò chuyện nhé!',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Quick start suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickStartChip('💧 Ghi nhận nước', '250ml nước'),
              _buildQuickStartChip('🎯 Kiểm tra mục tiêu', 'Mục tiêu hôm nay'),
              _buildQuickStartChip('📊 Xem thống kê', 'Thống kê của tôi'),
            ],
          ),
        ],
      ),
    );
  }

  /// Build quick start chip
  Widget _buildQuickStartChip(String label, String message) {
    return GestureDetector(
          onTap: () => _sendMessage(message),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.cyan.withValues(alpha: 0.1),
                  AppColors.cyan.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        )
        .animate(delay: const Duration(milliseconds: 200))
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.2, end: 0.0);
  }

  /// Build loading state
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải cuộc trò chuyện...', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          const Text(
            'Không thể tải cuộc trò chuyện',
            style: AppTextStyles.headingMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: AppTextStyles.caption,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Retry by invalidating the provider
              ref.invalidate(coachNotifierProvider);
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  /// Build chat input area
  Widget _buildChatInput() {
    final conversationAsyncState = ref.watch(coachNotifierProvider);

    return conversationAsyncState.when(
      data: (conversationState) => ChatInput(
        onSendMessage: _sendMessage,
        isEnabled: !conversationState.isAiTyping,
        hintText: conversationState.isAiTyping
            ? 'AQUA AI đang soạn tin...'
            : 'Nhắn tin với AQUA AI...',
      ),
      loading: () => ChatInput(
        onSendMessage: _sendMessage,
        isEnabled: false,
        hintText: 'Đang tải...',
      ),
      error: (error, stack) => ChatInput(
        onSendMessage: _sendMessage,
        isEnabled: false,
        hintText: 'Lỗi kết nối...',
      ),
    );
  }

  /// Send message to AI
  void _sendMessage(String message) {
    if (message.trim().isEmpty) return;

    ref.read(coachNotifierProvider.notifier).sendMessage(message);
  }

  /// Handle quick reply tap
  void _handleQuickReply(QuickReply quickReply) {
    ref.read(coachNotifierProvider.notifier).sendQuickReply(quickReply);

    // Handle navigation actions
    switch (quickReply.action) {
      case 'log_water':
        // Navigate to log screen
        Navigator.pushNamed(context, '/log');
        break;
      case 'check_stats':
        // Navigate to stats screen
        Navigator.pushNamed(context, '/stats');
        break;
      case 'view_achievements':
        // Navigate to level screen
        Navigator.pushNamed(context, '/level');
        break;
      case 'check_body':
        // Navigate to body map screen
        Navigator.pushNamed(context, '/body_map');
        break;
      default:
        // No special action needed
        break;
    }
  }
}
