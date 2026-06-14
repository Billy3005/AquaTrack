import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/providers/user_stats_provider.dart';
import '../../features/level/providers/level_data_provider.dart';
import '../../features/level/providers/level_provider.dart';
import '../../features/level/widgets/level_up_overlay.dart';

/// Bottom Navigation Wrapper.
///
/// Five primary tabs match the design's tab bar; the two lower-traffic
/// destinations (Thống kê, Bạn bè) live behind a "Thêm" sheet so the row never
/// overflows. Every tab is wrapped in [Expanded], so it divides the width
/// evenly regardless of label length — that was the source of the 51px overflow.
///
/// As the shell wrapping every authenticated screen, it also hosts the single
/// level-up listener: when levelNotifierProvider reports a level increase (from
/// a water log OR an achievement claim), it shows [LevelUpOverlay] once.
class BottomNavigationWrapper extends ConsumerStatefulWidget {
  final Widget child;

  const BottomNavigationWrapper({super.key, required this.child});

  static const tabs = [
    (icon: Icons.water_drop, label: 'Nước', route: '/'),
    (icon: Icons.chat_bubble, label: 'Chat', route: '/coach'),
    (icon: Icons.track_changes, label: 'Nhiệm vụ', route: '/missions'),
    (icon: Icons.people, label: 'Bạn bè', route: '/friends'),
    (icon: Icons.person, label: 'Hồ sơ', route: '/profile'),
  ];

  /// Destinations reachable via the "Thêm" sheet.
  static const moreRoutes = [
    (icon: Icons.show_chart, label: 'Thống kê', route: '/stats'),
    (icon: Icons.emoji_events, label: 'Cấp độ', route: '/level'),
  ];

  @override
  ConsumerState<BottomNavigationWrapper> createState() =>
      _BottomNavigationWrapperState();
}

class _BottomNavigationWrapperState
    extends ConsumerState<BottomNavigationWrapper> {
  static const tabs = BottomNavigationWrapper.tabs;
  static const moreRoutes = BottomNavigationWrapper.moreRoutes;

  @override
  Widget build(BuildContext context) {
    // Single place every XP source funnels through → one celebration trigger.
    ref.listen(levelNotifierProvider, (prev, next) {
      final event = next.valueOrNull?.pendingLevelUp;
      if (event == null) return;
      // Clear immediately so a rebuild can't double-show the same event.
      ref.read(levelNotifierProvider.notifier).clearLevelUp();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        LevelUpOverlayHost.show(
          context,
          fromLevel: event.fromLevel,
          toLevel: event.toLevel,
          currentXp: event.currentXp,
          xpForNextLevel: event.xpForNextLevel,
          coinsAwarded: event.coinsAwarded,
          rankName: event.rankName,
          // On close, re-read the persisted level from the backend so the XP
          // bar settles on the authoritative value (matches logout/login).
          onClosed: () {
            ref.read(levelNotifierProvider.notifier).reloadFromApi();
            ref.invalidate(userStatsProvider);
            ref.invalidate(levelDataProvider);
          },
        );
      });
    });

    final String location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;
    for (int i = 0; i < tabs.length; i++) {
      if (location == tabs[i].route) {
        selectedIndex = i;
        break;
      }
    }
    // Highlight "Thêm" when a sheet destination is active.
    final onMoreRoute = moreRoutes.any((t) => t.route == location);

    // No FAB here: the Home screen owns the Smart Scan FAB (matching the
    // design's home-only placement). Providing one here too stacked a second
    // camera button over the rightmost tabs.
    return Scaffold(
      body: widget.child,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background.withValues(alpha: 0.85),
          border: const Border(
            top: BorderSide(color: Color(0xFF38BDF8), width: 0.12),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 32),
            child: Row(
              children: [
                for (int index = 0; index < tabs.length; index++)
                  Expanded(
                    child: _NavItem(
                      icon: tabs[index].icon,
                      label: tabs[index].label,
                      isSelected: selectedIndex == index && !onMoreRoute,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go(tabs[index].route);
                      },
                    ),
                  ),
                // "Thêm" — opens the overflow destinations
                Expanded(
                  child: _NavItem(
                    icon: Icons.more_horiz,
                    label: 'Thêm',
                    isSelected: onMoreRoute,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _showMoreSheet(context);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet listing the secondary destinations (Thống kê, Bạn bè).
  void _showMoreSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            for (final dest in moreRoutes)
              ListTile(
                leading: Icon(dest.icon, color: AppColors.cyan),
                title: Text(
                  dest.label,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  HapticFeedback.lightImpact();
                  context.go(dest.route);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

/// Individual Navigation Item
class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.cyan : AppColors.textSecondary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              softWrap: false,
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                fontSize: 10,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
