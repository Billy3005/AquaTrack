import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/notification_models.dart';
import '../providers/friends_provider.dart';
import '../providers/notifications_provider.dart';

/// Show the notifications inbox as a compact dropdown anchored to the top-right,
/// just under the header bell — no full-screen navigation.
Future<void> showNotificationsDropdown(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Đóng thông báo',
    barrierColor: Colors.black.withValues(alpha: 0.25),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (ctx, anim, _, __) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      final topInset = MediaQuery.of(ctx).padding.top + 64;
      return Stack(
        children: [
          Positioned(
            top: topInset,
            right: 14,
            child: FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(curved),
                alignment: Alignment.topRight,
                child: const _NotificationsPanel(),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _NotificationsPanel extends ConsumerStatefulWidget {
  const _NotificationsPanel();

  @override
  ConsumerState<_NotificationsPanel> createState() =>
      _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<_NotificationsPanel> {
  bool _busy = false;

  Future<void> _refresh() async {
    ref.invalidate(notificationsProvider);
    ref.invalidate(challengesProvider);
  }

  Future<void> _respond(AppNotification n, bool accept) async {
    if (_busy || n.challengeId == null) return;
    setState(() => _busy = true);
    final service = ref.read(socialServiceProvider);
    final ok = await service.respondToChallenge(n.challengeId!, accept: accept);
    if (!mounted) return;
    setState(() => _busy = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? (accept ? 'Đã tham gia cuộc đua! 🏁' : 'Đã từ chối cuộc đua')
              : 'Không thể phản hồi. Thử lại sau!',
        ),
      ),
    );
    if (ok) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);
    final size = MediaQuery.of(context).size;
    final width = size.width - 28 < 360.0 ? size.width - 28 : 360.0;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        constraints: BoxConstraints(maxHeight: size.height * 0.6),
        decoration: BoxDecoration(
          color: AppColors.nightSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.glow.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(notificationsAsync),
            Flexible(
              child: notificationsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(color: AppColors.glow),
                ),
                error: (_, __) => _message('Không tải được thông báo'),
                data: (items) => items.isEmpty
                    ? _message('Chưa có thông báo nào')
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        itemCount: items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) => _buildCard(items[i]),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AsyncValue<List<AppNotification>> async) {
    final count = async.maybeWhen(
      data: (n) => n.length,
      orElse: () => 0,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 10, 8),
      child: Row(
        children: [
          const Icon(Icons.notifications, color: AppColors.glow, size: 18),
          const SizedBox(width: 8),
          Text(
            'Thông báo',
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.glow.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.glow,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const Spacer(),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close,
                color: AppColors.textSecondary, size: 18),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
      child: Column(
        children: [
          const Icon(Icons.notifications_none,
              size: 40, color: AppColors.textMuted),
          const SizedBox(height: 10),
          Text(
            text,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(AppNotification n) {
    final isChallenge = n.type == FriendNotificationType.challenge;
    final accent = isChallenge ? AppColors.purpleLight : AppColors.glow;
    final icon = isChallenge ? Icons.emoji_events : Icons.water_drop;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: n.isRead ? AppColors.border : accent.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                        children: [
                          TextSpan(
                            text: n.senderName,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(text: n.message),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(n.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (n.isPendingInvite) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Tham gia',
                    primary: true,
                    onTap: () => _respond(n, true),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    label: 'Từ chối',
                    primary: false,
                    onTap: () => _respond(n, false),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _busy ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: primary ? AppColors.primaryGradient : null,
          color: primary ? null : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(9),
          border: primary
              ? null
              : Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Text(
          label,
          style: AppTextStyles.buttonTextSmall.copyWith(
            color: primary ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    return '${diff.inDays} ngày trước';
  }
}
