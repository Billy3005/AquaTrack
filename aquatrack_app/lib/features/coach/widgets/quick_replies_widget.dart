import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../models/chat_message.dart';

/// Quick replies widget for AI suggestions
class QuickRepliesWidget extends StatelessWidget {
  final List<QuickReply> quickReplies;
  final Function(QuickReply)? onTap;

  const QuickRepliesWidget({
    super.key,
    required this.quickReplies,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (quickReplies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'Trả lời nhanh:',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Quick reply buttons
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: quickReplies
              .asMap()
              .entries
              .map((entry) => _buildQuickReplyButton(
                    entry.value,
                    entry.key,
                  ))
              .toList(),
        ),
      ],
    );
  }

  /// Build individual quick reply button
  Widget _buildQuickReplyButton(QuickReply quickReply, int index) {
    return GestureDetector(
      onTap: () => onTap?.call(quickReply),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Extract emoji if present
            if (_hasEmoji(quickReply.text))
              Text(
                _extractEmoji(quickReply.text),
                style: const TextStyle(fontSize: 14),
              ),
            if (_hasEmoji(quickReply.text)) const SizedBox(width: 4),

            // Button text
            Text(
              _getTextWithoutEmoji(quickReply.text),
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.cyan,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: 200 + (index * 100)))
        .fadeIn(duration: 300.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          curve: Curves.elasticOut,
        );
  }

  /// Check if text contains emoji (simplified)
  bool _hasEmoji(String text) {
    // Simple check for common emojis in our use case
    return text.contains('💧') ||
        text.contains('🎯') ||
        text.contains('🏆') ||
        text.contains('⏰') ||
        text.contains('💡') ||
        text.contains('🗺️') ||
        text.contains('📈') ||
        text.contains('📅') ||
        text.contains('🩺') ||
        text.contains('❓') ||
        text.contains('⚙️');
  }

  /// Extract emoji from text (simplified)
  String _extractEmoji(String text) {
    final emojis = [
      '💧',
      '🎯',
      '🏆',
      '⏰',
      '💡',
      '🗺️',
      '📈',
      '📅',
      '🩺',
      '❓',
      '⚙️'
    ];
    for (final emoji in emojis) {
      if (text.contains(emoji)) return emoji;
    }
    return '';
  }

  /// Get text without emoji (simplified)
  String _getTextWithoutEmoji(String text) {
    final emojis = [
      '💧',
      '🎯',
      '🏆',
      '⏰',
      '💡',
      '🗺️',
      '📈',
      '📅',
      '🩺',
      '❓',
      '⚙️'
    ];
    String result = text;
    for (final emoji in emojis) {
      result = result.replaceAll(emoji, '');
    }
    return result.trim();
  }
}
