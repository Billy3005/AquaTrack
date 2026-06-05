import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../profile/providers/profile_provider.dart';
import 'data/avatar_catalog.dart';
import 'widgets/aqua_avatar.dart';

/// Bộ sưu tập avatar — lists all water-spirit forms grouped by tier, with the
/// equipped hero, owned/total progress, and a detail sheet for equipping or
/// buying. Mirrors the design's `collection-screen.jsx`.
class AvatarCollectionScreen extends ConsumerWidget {
  const AvatarCollectionScreen({super.key});

  static const _base = Color(0xFF0B1120);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);
    final equipped = avatarSpecOrDefault(profile.selectedAvatar);

    AvatarOwnership stateOf(AquaAvatarSpec spec) => avatarOwnership(
          spec,
          level: profile.currentLevel,
          longestStreak: profile.longestStreak,
          ownedAvatars: profile.ownedAvatars,
          equippedId: profile.selectedAvatar,
        );

    final ownedCount = kAvatarCatalog
        .where((a) => stateOf(a) != AvatarOwnership.locked)
        .length;

    return Scaffold(
      backgroundColor: _base,
      body: Column(
        children: [
          _Header(
            equipped: equipped,
            coins: profile.coins,
            ownedCount: ownedCount,
            total: kAvatarCatalog.length,
          ),
          const _SegmentedTabs(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                for (final tier in kTierOrder)
                  _TierSection(
                    tier: tier,
                    stateOf: stateOf,
                    onTap: (spec) => _showDetail(context, ref, spec),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, WidgetRef ref, AquaAvatarSpec spec) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AvatarDetailSheet(spec: spec),
    );
  }
}

class _Header extends StatelessWidget {
  final AquaAvatarSpec equipped;
  final int coins;
  final int ownedCount;
  final int total;

  const _Header({
    required this.equipped,
    required this.coins,
    required this.ownedCount,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : ownedCount / total;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 54, 18, 16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF15234A), Color(0xFF0B1120)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _circleButton(
                icon: Icons.chevron_left,
                onTap: () => Navigator.of(context).maybePop(),
              ),
              const Spacer(),
              const Column(
                children: [
                  Text(
                    'TỦ AVATAR',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFFC4B5FD),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Bộ sưu tập',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              _coinBadge(coins),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              AvatarBubble(spec: equipped, size: 88),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      equipped.name,
                      style: const TextStyle(
                        fontSize: 21,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _RarityTag(tier: equipped.tier),
                        const SizedBox(width: 8),
                        const Text(
                          'Đang dùng',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF7DD3FC),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 7,
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF818CF8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Đã mở $ownedCount / $total hình hài',
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _coinBadge(int coins) {
    return Container(
      padding: const EdgeInsets.fromLTRB(7, 5, 10, 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x2EFBBF24), Color(0x10F59E0B)],
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x73FBBF24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.monetization_on, color: Color(0xFFFCD34D), size: 15),
          const SizedBox(width: 5),
          Text(
            '$coins',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFDE68A),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs();

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool active) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? const Color(0x2E818CF8)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? const Color(0x73818CF8)
                  : Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFFC4B5FD) : const Color(0xFF94A3B8),
            ),
          ),
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      child: Row(
        children: [
          tab('Avatar', true),
          const SizedBox(width: 8),
          Opacity(opacity: 0.6, child: tab('Theme · sắp ra mắt', false)),
          const SizedBox(width: 8),
          Opacity(opacity: 0.6, child: tab('Khung', false)),
        ],
      ),
    );
  }
}

class _TierSection extends StatelessWidget {
  final AquaTier tier;
  final AvatarOwnership Function(AquaAvatarSpec) stateOf;
  final void Function(AquaAvatarSpec) onTap;

  const _TierSection({
    required this.tier,
    required this.stateOf,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final list = kAvatarCatalog.where((a) => a.tier == tier).toList();
    final style = kAquaTiers[tier]!;
    final got = list.where((a) => stateOf(a) != AvatarOwnership.locked).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Row(
          children: [
            Transform.rotate(
              angle: 0.785,
              child: Container(width: 7, height: 7, color: style.color),
            ),
            const SizedBox(width: 8),
            Text(
              style.name,
              style: const TextStyle(
                fontSize: 12.5,
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$got/${list.length}',
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 9,
          crossAxisSpacing: 9,
          childAspectRatio: 0.82,
          children: [
            for (final spec in list)
              _AvatarTile(
                spec: spec,
                state: stateOf(spec),
                onTap: () => onTap(spec),
              ),
          ],
        ),
      ],
    );
  }
}

class _AvatarTile extends StatelessWidget {
  final AquaAvatarSpec spec;
  final AvatarOwnership state;
  final VoidCallback onTap;

  const _AvatarTile({
    required this.spec,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locked = state == AvatarOwnership.locked;
    final equipped = state == AvatarOwnership.equipped;
    final tier = spec.tierStyle;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 11),
        decoration: BoxDecoration(
          color: equipped
              ? tier.color.withValues(alpha: 0.12)
              : locked
                  ? Colors.white.withValues(alpha: 0.03)
                  : const Color(0xFF131F38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: equipped
                ? tier.color
                : locked
                    ? Colors.white.withValues(alpha: 0.06)
                    : tier.color.withValues(alpha: 0.18),
            width: equipped ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.topRight,
              children: [
                Center(
                  child: AquaAvatar(spec: spec, size: 70, silhouette: locked),
                ),
                if (locked)
                  const Icon(Icons.lock, color: Color(0xFF475569), size: 13)
                else if (equipped)
                  const Icon(Icons.check_circle,
                      color: Color(0xFF7DD3FC), size: 14),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              spec.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: locked ? const Color(0xFF94A3B8) : Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            _tileChip(locked, equipped, tier),
          ],
        ),
      ),
    );
  }

  Widget _tileChip(bool locked, bool equipped, AquaTierStyle tier) {
    if (equipped) {
      return Text(
        'Đang dùng',
        style: TextStyle(
            fontSize: 9.5, color: tier.color, fontWeight: FontWeight.w700),
      );
    }
    if (!locked) {
      return const Text(
        'Đã mở',
        style: TextStyle(
            fontSize: 9.5,
            color: Color(0xFF86EFAC),
            fontWeight: FontWeight.w700),
      );
    }
    return Text(
      spec.unlock.label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B)),
    );
  }
}

class _RarityTag extends StatelessWidget {
  final AquaTier tier;
  const _RarityTag({required this.tier});

  @override
  Widget build(BuildContext context) {
    final style = kAquaTiers[tier]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: style.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.color.withValues(alpha: 0.45)),
      ),
      child: Text(
        style.name,
        style: TextStyle(
          fontSize: 9.5,
          color: style.color,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

/// Bottom sheet: large hero, lore, unlock note, and the context action
/// (Trang bị / Mua · xu / Cần đạt … / Sắp ra mắt).
class _AvatarDetailSheet extends ConsumerWidget {
  final AquaAvatarSpec spec;
  const _AvatarDetailSheet({required this.spec});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileNotifierProvider);
    final state = avatarOwnership(
      spec,
      level: profile.currentLevel,
      longestStreak: profile.longestStreak,
      ownedAvatars: profile.ownedAvatars,
      equippedId: profile.selectedAvatar,
    );
    final tier = spec.tierStyle;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF10203C), Color(0xFF0B1120)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: tier.color.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 34),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 14),
          AvatarBubble(spec: spec, size: 150),
          const SizedBox(height: 12),
          Text(
            spec.name,
            style: const TextStyle(
              fontSize: 25,
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _RarityTag(tier: spec.tier),
              const SizedBox(width: 8),
              Text(
                spec.meaning,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            spec.desc,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_unlockIcon(), size: 15, color: tier.color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '${spec.unlock.label} · ${spec.unlock.sub}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _ActionButton(spec: spec, state: state),
        ],
      ),
    );
  }

  IconData _unlockIcon() {
    switch (spec.unlock.type) {
      case UnlockType.coin:
        return Icons.monetization_on;
      case UnlockType.streak:
        return Icons.local_fire_department;
      case UnlockType.mission:
        return Icons.flag;
      case UnlockType.level:
        return Icons.military_tech;
    }
  }
}

class _ActionButton extends ConsumerStatefulWidget {
  final AquaAvatarSpec spec;
  final AvatarOwnership state;
  const _ActionButton({required this.spec, required this.state});

  @override
  ConsumerState<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends ConsumerState<_ActionButton> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final spec = widget.spec;
    final state = widget.state;
    final profile = ref.watch(profileNotifierProvider);
    final unlock = spec.unlock;

    String label;
    Color bg;
    Color fg;
    VoidCallback? onTap;

    if (state == AvatarOwnership.equipped) {
      label = 'Đang trang bị';
      bg = const Color(0x1F38BDF8);
      fg = const Color(0xFF7DD3FC);
    } else if (state == AvatarOwnership.owned) {
      label = 'Trang bị';
      bg = const Color(0xFF0EA5E9);
      fg = Colors.white;
      onTap = () => _equip();
    } else if (unlock.type == UnlockType.mission) {
      label = 'Sắp ra mắt';
      bg = Colors.white.withValues(alpha: 0.05);
      fg = const Color(0xFF94A3B8);
    } else if (unlock.coinPrice != null) {
      final affordable = profile.coins >= unlock.coinPrice!;
      label =
          affordable ? 'Mua · ${unlock.label}' : 'Cần ${unlock.coinPrice} xu';
      bg = affordable
          ? const Color(0xFFF59E0B)
          : Colors.white.withValues(alpha: 0.05);
      fg = affordable ? const Color(0xFF451A03) : const Color(0xFF94A3B8);
      if (affordable) onTap = () => _purchase();
    } else if (unlock.streakReq != null) {
      label = unlock.label;
      bg = Colors.white.withValues(alpha: 0.05);
      fg = const Color(0xFF94A3B8);
    } else {
      label = 'Cần đạt ${unlock.label}';
      bg = Colors.white.withValues(alpha: 0.05);
      fg = const Color(0xFF94A3B8);
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _busy ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _busy
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }

  Future<void> _equip() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateAvatar(widget.spec.id);
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      _toast('Không thể trang bị: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _purchase() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .purchaseAvatar(widget.spec.id);
      _toast('Đã mở khoá ${widget.spec.name}!');
    } catch (e) {
      _toast(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }
}
