import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Main bottom navigation with 6 tabs: Drop · Coach · Body · Stats · Level · You
class MainNavigation extends StatefulWidget {
  final int initialIndex;

  const MainNavigation({
    super.key,
    this.initialIndex = 0,
  });

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// Navigation tab items
  final List<NavItem> _navItems = const [
    NavItem(
      icon: Icons.water_drop,
      label: 'Drop',
      activeColor: AppColors.cyanAccent,
    ),
    NavItem(
      icon: Icons.psychology,
      label: 'Coach',
      activeColor: AppColors.cyanLight,
    ),
    NavItem(
      icon: Icons.accessibility_new,
      label: 'Body',
      activeColor: AppColors.success,
    ),
    NavItem(
      icon: Icons.analytics,
      label: 'Stats',
      activeColor: AppColors.info,
    ),
    NavItem(
      icon: Icons.military_tech,
      label: 'Level',
      activeColor: AppColors.purpleXP,
    ),
    NavItem(
      icon: Icons.person,
      label: 'You',
      activeColor: AppColors.textSecondary,
    ),
  ];

  /// Navigation pages (placeholders for now)
  final List<Widget> _pages = const [
    _PlaceholderPage(title: 'Home', subtitle: 'Living Drop'),
    _PlaceholderPage(title: 'AI Coach', subtitle: 'Chat với AQUA AI'),
    _PlaceholderPage(title: 'Body Map', subtitle: 'SVG organs với hydration'),
    _PlaceholderPage(title: 'Stats', subtitle: 'Wave chart & insights'),
    _PlaceholderPage(title: 'Level & XP', subtitle: 'Achievements & avatar'),
    _PlaceholderPage(title: 'Profile', subtitle: 'Settings & user info'),
  ];

  /// Handle tab selection
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  /// Handle page change
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.navBarBackground, AppColors.secondaryBackground],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlay,
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 72,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: _navItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isActive = index == _currentIndex;

                return _NavTabItem(
                  item: item,
                  isActive: isActive,
                  onTap: () => _onTabSelected(index),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data
class NavItem {
  final IconData icon;
  final String label;
  final Color activeColor;

  const NavItem({
    required this.icon,
    required this.label,
    required this.activeColor,
  });
}

/// Navigation tab item widget
class _NavTabItem extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavTabItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon with animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(6),
              decoration: isActive
                  ? BoxDecoration(
                      color: item.activeColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Icon(
                item.icon,
                color: isActive ? item.activeColor : AppColors.navIconInactive,
                size: isActive ? 26 : 24,
              ),
            ),
            const SizedBox(height: 2),
            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTextStyles.navLabel.copyWith(
                color: isActive ? item.activeColor : AppColors.navIconInactive,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
              child: Text(item.label),
            ),
          ],
        ),
      ),
    );
  }
}

/// Placeholder page for development
class _PlaceholderPage extends StatelessWidget {
  final String title;
  final String subtitle;

  const _PlaceholderPage({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction,
                size: 64,
                color: AppColors.cyanAccent,
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: AppTextStyles.displaySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppTextStyles.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppColors.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderColor),
                ),
                child: Text(
                  'Page sẽ được implement trong phase tiếp theo',
                  style: AppTextStyles.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
