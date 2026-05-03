import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Bottom Navigation Wrapper với 6 tabs
class BottomNavigationWrapper extends StatelessWidget {
  final Widget child;

  const BottomNavigationWrapper({
    super.key,
    required this.child,
  });

  static const tabs = [
    (icon: Icons.water_drop_outlined, label: 'Drop', route: '/'),
    (icon: Icons.chat_bubble_outline, label: 'Coach', route: '/coach'),
    (icon: Icons.person_outline, label: 'Body', route: '/body'),
    (icon: Icons.bar_chart_outlined, label: 'Stats', route: '/stats'),
    (icon: Icons.emoji_events_outlined, label: 'Level', route: '/level'),
    (icon: Icons.account_circle_outlined, label: 'You', route: '/profile'),
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

    return Scaffold(
      body: child,

      // FAB for Smart Scan (floating camera button)
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/smart-scan'),
        backgroundColor: AppColors.cyan,
        foregroundColor: AppColors.textPrimary,
        child: const Icon(Icons.camera_alt_outlined, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(
              color: AppColors.surfaceLight,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
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
