import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/friends_provider.dart';
import '../services/social_service.dart';

/// Bottom sheet that shows the user's permanent referral code with copy + share
/// (ADR-0007). Inviting a friend who starts using the app earns the Đại Sứ
/// weekly quest; the new friend gets a one-time welcome coin bonus.
Future<void> showInviteFriendsSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _InviteFriendsSheet(),
  );
}

String _inviteMessage(String code) =>
    'Mình đang dùng AquaTrack để uống nước đều mỗi ngày 💧\n'
    'Tải app và nhập mã giới thiệu "$code" để nhận 50 xu chào mừng nhé!';

class _InviteFriendsSheet extends ConsumerStatefulWidget {
  const _InviteFriendsSheet();

  @override
  ConsumerState<_InviteFriendsSheet> createState() =>
      _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<_InviteFriendsSheet> {
  late Future<ReferralInfo> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(socialServiceProvider).getReferral();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: AppColors.nightSurface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.25),
          ),
        ),
        child: FutureBuilder<ReferralInfo>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              );
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildError();
            }
            return _buildContent(snapshot.data!);
          },
        ),
      ),
    );
  }

  Widget _buildError() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 12),
        Icon(Icons.error_outline, color: const Color(0xFFF97316), size: 36),
        const SizedBox(height: 10),
        Text(
          'Không tải được mã mời. Thử lại sau!',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildContent(ReferralInfo info) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Mời bạn bè',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Bạn mới nhập mã sẽ nhận 50 xu chào mừng, còn bạn hoàn thành '
          'nhiệm vụ "Đại Sứ Hydration" mỗi tuần.',
          style: TextStyle(
            fontSize: 12.5,
            height: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 18),

        // Code box with copy
        GestureDetector(
          onTap: () => _copyCode(info.code),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.10),
              border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35),
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    info.code,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                Icon(Icons.copy, size: 18, color: AppColors.textBright),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Share button
        GestureDetector(
          onTap: () => _share(info.code),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0EA5E9).withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.ios_share, color: Colors.white, size: 18),
                SizedBox(width: 8),
                Text(
                  'Chia sẻ lời mời',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),

        Center(
          child: Text(
            info.invitedCount == 0
                ? 'Bạn chưa mời ai. Bắt đầu thôi!'
                : 'Đã mời ${info.invitedCount} người · '
                    '${info.validatedCount} đang dùng',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã sao chép mã mời'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _share(String code) {
    HapticFeedback.lightImpact();
    Share.share(_inviteMessage(code), subject: 'Cùng uống nước với AquaTrack');
  }
}
