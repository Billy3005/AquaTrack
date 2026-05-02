import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/chat_message.dart';
import 'quick_replies_widget.dart';

/// Chat bubble widget for user and AI messages
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final Function(QuickReply)? onQuickReplyTap;

  const ChatBubble({
    super.key,
    required this.message,
    this.onQuickReplyTap,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isTyping) {
      return _buildTypingIndicator();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Column(
        crossAxisAlignment: message.isFromUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          _buildMessageBubble(),
          if (message.quickReplies.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 48),
              child: QuickRepliesWidget(
                quickReplies: message.quickReplies,
                onTap: onQuickReplyTap,
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms, delay: 100.ms)
        .slideY(begin: 0.2, end: 0.0, curve: Curves.easeOutCubic);
  }

  /// Build main message bubble
  Widget _buildMessageBubble() {
    return Row(
      mainAxisAlignment:
          message.isFromUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // AI avatar
        if (!message.isFromUser) _buildAvatar(),

        // Message bubble
        Flexible(
          child: Container(
            margin: EdgeInsets.only(
              left: message.isFromUser ? 48 : 8,
              right: message.isFromUser ? 8 : 48,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: message.isFromUser
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.cyan,
                        AppColors.cyan.withValues(alpha: 0.8),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.surface.withValues(alpha: 0.9),
                        AppColors.surface.withValues(alpha: 0.7),
                      ],
                    ),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: message.isFromUser
                    ? const Radius.circular(16)
                    : const Radius.circular(4),
                bottomRight: message.isFromUser
                    ? const Radius.circular(4)
                    : const Radius.circular(16),
              ),
              border: Border.all(
                color: message.isFromUser
                    ? AppColors.cyan.withValues(alpha: 0.3)
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color:
                      (message.isFromUser ? AppColors.cyan : AppColors.surface)
                          .withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message type indicator
                if (message.type != MessageType.text)
                  _buildMessageTypeIndicator(),

                // Message content
                Text(
                  message.content,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: message.isFromUser
                        ? Colors.white
                        : AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),

                // Timestamp
                const SizedBox(height: 4),
                Text(
                  message.timeDisplay,
                  style: AppTextStyles.caption.copyWith(
                    color: message.isFromUser
                        ? Colors.white.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // User avatar (if needed)
        if (message.isFromUser) _buildUserAvatar(),
      ],
    );
  }

  /// Build AI avatar
  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.cyan,
            AppColors.xpPurple,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
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
        size: 18,
      ),
    );
  }

  /// Build user avatar
  Widget _buildUserAvatar() {
    return Container(
      width: 28,
      height: 28,
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.cyan.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.cyan,
        size: 16,
      ),
    );
  }

  /// Build message type indicator
  Widget _buildMessageTypeIndicator() {
    IconData icon;
    Color color;
    String label;

    switch (message.type) {
      case MessageType.suggestion:
        icon = Icons.lightbulb_outline;
        color = AppColors.cyan;
        label = 'Gợi ý';
        break;
      case MessageType.achievement:
        icon = Icons.emoji_events;
        color = AppColors.xpPurple;
        label = 'Thành tích';
        break;
      case MessageType.reminder:
        icon = Icons.schedule;
        color = AppColors.textSecondary;
        label = 'Nhắc nhở';
        break;
      case MessageType.welcomeCard:
        icon = Icons.waving_hand;
        color = AppColors.cyan;
        label = 'Chào mừng';
        break;
      case MessageType.text:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build typing indicator animation
  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'AQUA AI đang soạn tin',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(width: 8),
                _buildTypingDots(),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat()).shimmer(
        duration: 1500.ms, color: AppColors.cyan.withValues(alpha: 0.3));
  }

  /// Build typing dots animation
  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < 3; i++)
          Container(
            width: 4,
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 2 : 0),
            decoration: BoxDecoration(
              color: AppColors.cyan,
              borderRadius: BorderRadius.circular(2),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).scale(
                begin: const Offset(0.8, 0.8),
                end: const Offset(1.2, 1.2),
                duration: 600.ms,
                delay: Duration(milliseconds: i * 200),
              ),
      ],
    );
  }
}
