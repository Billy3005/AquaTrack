import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Bottom Navigation Wrapper với 6 tabs
class BottomNavigationWrapper extends StatelessWidget {
  final Widget child;

  const BottomNavigationWrapper({super.key, required this.child});

  static const tabs = [
    (icon: Icons.water_drop, label: 'Nước', route: '/'),
    (icon: Icons.chat_bubble, label: 'Chat', route: '/coach'),
    (icon: Icons.track_changes, label: 'Nhiệm vụ', route: '/missions'),
    (icon: Icons.show_chart, label: 'Thống kê', route: '/stats'),
    (icon: Icons.people, label: 'Bạn bè', route: '/friends'),
    (icon: Icons.emoji_events, label: 'Cấp độ', route: '/level'),
    (icon: Icons.person, label: 'Hồ sơ', route: '/profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    int selectedIndex = 0;

    // Determine selected tab index
    for (int i = 0; i < tabs.length; i++) {
      if (location == tabs[i].route) {
        selectedIndex = i;
        break;
      }
    }

    // The Chat tab has its own bottom input row; the Smart Scan FAB would
    // overlap the send area, so hide it there.
    final showScanFab = location != '/coach';

    return Scaffold(
      body: child,

      // FAB for Smart Scan (floating camera button)
      floatingActionButton: showScanFab
          ? FloatingActionButton(
              heroTag: "smart_scan_fab", // Unique hero tag to prevent conflicts
              onPressed: () => context.push('/smart-scan'),
              backgroundColor: AppColors.cyan,
              foregroundColor: AppColors.textPrimary,
              child: const Icon(Icons.camera_alt_outlined, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

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
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (index) {
                final tab = tabs[index];
                final isSelected = selectedIndex == index;

                return _NavItem(
                  icon: tab.icon,
                  label: tab.label,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(tab.route);
                  },
                );
              }),
            ),
          ),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.cyan : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: isSelected ? AppColors.cyan : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
