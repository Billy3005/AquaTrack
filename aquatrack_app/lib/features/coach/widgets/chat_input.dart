import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Chat input widget for user messages
class ChatInput extends StatefulWidget {
  final Function(String)? onSendMessage;
  final bool isEnabled;
  final String hintText;

  const ChatInput({
    super.key,
    this.onSendMessage,
    this.isEnabled = true,
    this.hintText = 'Nhắn tin với AQUA AI...',
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _sendMessage() {
    if (!_hasText || !widget.isEnabled) return;

    final message = _controller.text.trim();
    _controller.clear();

    widget.onSendMessage?.call(message);

    // Unfocus to hide keyboard
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(
            color: AppColors.surface.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Text input field
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _focusNode.hasFocus
                        ? AppColors.cyan.withValues(alpha: 0.5)
                        : AppColors.surface,
                    width: 2,
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  enabled: widget.isEnabled,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    // Add suggestion chips if needed
                    suffixIcon: _hasText
                        ? null
                        : Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildSuggestionChip('💧 Uống nước'),
                                const SizedBox(width: 4),
                                _buildSuggestionChip('📊 Thống kê'),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Send button
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  /// Build send button
  Widget _buildSendButton() {
    final isActive = _hasText && widget.isEnabled;

    return GestureDetector(
          onTap: isActive ? _sendMessage : null,
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: isActive
                  ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.cyan, AppColors.xpPurple],
                    )
                  : null,
              color: isActive ? null : AppColors.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(24),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.cyan.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.send_rounded,
              color: isActive ? Colors.white : AppColors.textSecondary,
              size: 20,
            ),
          ),
        )
        .animate(target: isActive ? 1 : 0)
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeOutCubic,
        );
  }

  /// Build suggestion chip
  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _controller.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.cyan.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.cyan.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          text,
          style: AppTextStyles.caption.copyWith(
            color: AppColors.cyan,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}
