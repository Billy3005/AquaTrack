import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_text_styles.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/coin_badge.dart';
import '../avatars/data/avatar_catalog.dart';
import '../avatars/widgets/aqua_avatar.dart';
import '../profile/providers/profile_provider.dart';
import 'providers/shop_providers.dart';

/// Cửa hàng — the coin storefront (ADR 0004). Sells the coin-purchasable
/// Avatars and the one-time Streak Freeze; Theme and Khung are "Sắp ra mắt".
/// Balance, ownership and purchases are all real (no fabricated items). The
/// Collection screen remains the trophy cabinet for browsing/equipping.
class ShopScreen extends ConsumerStatefulWidget {
  const ShopScreen({super.key});

  @override
  ConsumerState<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends ConsumerState<ShopScreen> {
  String _tab = 'avatar';
  String? _busyId; // avatar id currently purchasing, or 'freeze'

  // Only avatars with a coin price are sold here (coin is an alt path to the
  // level/streak rail). Grouped by tier for display.
  static final List<AquaAvatarSpec> _coinAvatars =
      kAvatarCatalog.where((a) => a.unlock.coinPrice != null).toList();

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileNotifierProvider);

    return Scaffold(
      backgroundColor: AppColors.nightBase,
      body: Column(
        children: [
          _buildHeader(profile.coins),
          _buildTabs(),
          Expanded(child: _buildBody(profile)),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────

  Widget _buildHeader(int coins) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1040), Color(0xFF0B1120)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Column(
            children: [
              Row(
                children: [
                  _circleButton(
                    icon: Icons.arrow_back_ios_new,
                    onTap: () => context.pop(),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          'CỬA HÀNG',
                          style: AppTextStyles.caption.copyWith(
                            color: const Color(0xFFFCD34D),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'AquaShop',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 36),
                ],
              ),
              const SizedBox(height: 14),
              LargeCoinBadge(
                amount: coins,
                subtitle: 'SỐ DƯ',
                onTap: () => context.go('/missions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: IconButton(
        onPressed: onTap,
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }

  // ── Tabs ───────────────────────────────────────────────────────────────

  Widget _buildTabs() {
    const tabs = {'avatar': 'Avatar', 'theme': 'Theme', 'frame': 'Khung'};
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.nightBase,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        child: Row(
          children: tabs.entries.map((e) {
            final active = e.key == _tab;
            final comingSoon = e.key != 'avatar';
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _tab = e.key),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: active
                          ? const LinearGradient(
                              colors: [Color(0x33FBBF24), Color(0x14F59E0B)],
                            )
                          : null,
                      color: active ? null : Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: active
                            ? const Color(0x73FBBF24)
                            : Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          e.value,
                          style: AppTextStyles.caption.copyWith(
                            color: active
                                ? const Color(0xFFFDE68A)
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        if (comingSoon) ...[
                          const SizedBox(width: 5),
                          const Icon(
                            Icons.lock_clock,
                            size: 11,
                            color: Color(0xFF64748B),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Body ───────────────────────────────────────────────────────────────

  Widget _buildBody(ProfileState profile) {
    if (_tab != 'avatar') {
      return _buildComingSoon(_tab == 'theme' ? 'Theme' : 'Khung avatar');
    }

    AvatarOwnership stateOf(AquaAvatarSpec spec) => avatarOwnership(
          spec,
          level: profile.currentLevel,
          longestStreak: profile.longestStreak,
          ownedAvatars: profile.ownedAvatars,
          equippedId: profile.selectedAvatar,
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
      children: [
        _buildSectionLabel('🧊 Bảo vệ chuỗi'),
        const SizedBox(height: 10),
        _buildFreezeCard(profile.coins),
        const SizedBox(height: 20),
        _buildSectionLabel('Avatar · mua bằng xu'),
        const SizedBox(height: 4),
        Text(
          'Trang bị hình hài ở Bộ sưu tập sau khi mua.',
          style: AppTextStyles.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 10.5,
          ),
        ),
        const SizedBox(height: 12),
        for (final tier in kTierOrder)
          _buildTierGroup(tier, profile, stateOf),
      ],
    );
  }

  Widget _buildComingSoon(String what) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF64748B), size: 40),
          const SizedBox(height: 12),
          Text(
            '$what · Sắp ra mắt',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Đang được phát triển. Hãy quay lại sau nhé!',
            style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: AppTextStyles.bodyLarge.copyWith(
        color: AppColors.textBright,
        fontWeight: FontWeight.w700,
        fontSize: 13,
      ),
    );
  }

  // ── Streak Freeze card ─────────────────────────────────────────────────

  Widget _buildFreezeCard(int coins) {
    final freezeAsync = ref.watch(streakFreezeStatusProvider);
    final price =
        freezeAsync.maybeWhen(data: (s) => s.price, orElse: () => 300);
    final owned = freezeAsync.maybeWhen(data: (s) => s.owned, orElse: () => false);
    final busy = _busyId == 'freeze';
    final canAfford = coins >= price;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x2638BDF8), Color(0x0A0EA5E9)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x4D38BDF8)),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const RadialGradient(
                center: Alignment(-0.3, -0.3),
                colors: [Color(0xFF7DD3FC), Color(0xFF0284C7)],
              ),
            ),
            child: const Center(
              child: Text('🧊', style: TextStyle(fontSize: 26)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đóng băng chuỗi',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Giữ chuỗi không reset khi lỡ 1 ngày. Tự dùng khi cần.',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _freezeButton(owned, busy, canAfford, price),
        ],
      ),
    );
  }

  Widget _freezeButton(bool owned, bool busy, bool canAfford, int price) {
    if (owned) {
      return _pill(
        label: '✓ Đã có',
        bg: const Color(0x1F38BDF8),
        fg: const Color(0xFF7DD3FC),
        onTap: null,
      );
    }
    if (busy) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return _pill(
      label: canAfford ? 'Mua · $price' : 'Cần $price xu',
      bg: canAfford ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.05),
      fg: canAfford ? const Color(0xFF451A03) : AppColors.textMuted,
      onTap: canAfford ? _buyFreeze : null,
      coin: canAfford,
    );
  }

  // ── Avatar tier group ──────────────────────────────────────────────────

  Widget _buildTierGroup(
    AquaTier tier,
    ProfileState profile,
    AvatarOwnership Function(AquaAvatarSpec) stateOf,
  ) {
    final list = _coinAvatars.where((a) => a.tier == tier).toList();
    if (list.isEmpty) return const SizedBox.shrink();
    final style = kAquaTiers[tier]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Transform.rotate(
              angle: 0.785,
              child: Container(width: 7, height: 7, color: style.color),
            ),
            const SizedBox(width: 8),
            Text(
              style.name,
              style: AppTextStyles.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 0.74,
          children: [
            for (final spec in list)
              _buildAvatarCard(spec, stateOf(spec), profile.coins),
          ],
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildAvatarCard(
    AquaAvatarSpec spec,
    AvatarOwnership state,
    int coins,
  ) {
    final tier = spec.tierStyle;
    final owned = state != AvatarOwnership.locked;
    final price = spec.unlock.coinPrice!;
    final busy = _busyId == spec.id;
    final canAfford = coins >= price;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.nightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tier.color.withValues(alpha: 0.18)),
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Center(
              child: AquaAvatar(spec: spec, size: 64, silhouette: !owned),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            spec.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            spec.meaning,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textMuted,
              fontSize: 9.5,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 8),
          _avatarButton(spec, owned, busy, canAfford, price),
        ],
      ),
    );
  }

  Widget _avatarButton(
    AquaAvatarSpec spec,
    bool owned,
    bool busy,
    bool canAfford,
    int price,
  ) {
    if (owned) {
      return _wideButton(
        label: '✓ Đã sở hữu',
        bg: const Color(0x1F38BDF8),
        fg: const Color(0xFF7DD3FC),
        onTap: null,
      );
    }
    if (busy) {
      return const SizedBox(
        height: 32,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return _wideButton(
      label: canAfford ? '$price' : 'Cần $price xu',
      bg: canAfford ? const Color(0xFFF59E0B) : Colors.white.withValues(alpha: 0.05),
      fg: canAfford ? const Color(0xFF451A03) : AppColors.textMuted,
      onTap: canAfford ? () => _buyAvatar(spec) : null,
      coin: canAfford,
    );
  }

  // ── Shared button widgets ──────────────────────────────────────────────

  Widget _wideButton({
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
    bool coin = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 32,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(9),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (coin) ...[
                  Icon(Icons.monetization_on, color: fg, size: 13),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: AppTextStyles.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill({
    required String label,
    required Color bg,
    required Color fg,
    VoidCallback? onTap,
    bool coin = false,
  }) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (coin) ...[
                Icon(Icons.monetization_on, color: fg, size: 13),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ────────────────────────────────────────────────────────────

  Future<void> _buyAvatar(AquaAvatarSpec spec) async {
    setState(() => _busyId = spec.id);
    try {
      await ref.read(profileNotifierProvider.notifier).purchaseAvatar(spec.id);
      _snack('Đã mở khoá ${spec.name}!');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _buyFreeze() async {
    setState(() => _busyId = 'freeze');
    try {
      await ref.read(profileNotifierProvider.notifier).purchaseStreakFreeze();
      ref.invalidate(streakFreezeStatusProvider);
      _snack('Đã mua Đóng băng chuỗi!');
    } catch (e) {
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
