import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/auth_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import 'widgets/water_profile_form.dart';

/// Enhanced Profile Screen với Water Profile Integration
class ProfileScreenWaterIntegration extends ConsumerStatefulWidget {
  const ProfileScreenWaterIntegration({super.key});

  @override
  ConsumerState<ProfileScreenWaterIntegration> createState() =>
      _ProfileScreenWaterIntegrationState();
}

class _ProfileScreenWaterIntegrationState
    extends ConsumerState<ProfileScreenWaterIntegration>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _currentUser;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserInfo();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Load current user information
  Future<void> _loadUserInfo() async {
    setState(() => _isLoading = true);

    try {
      final user = await _authService.getUserData();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      _showError('Không thể tải thông tin người dùng: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildTabBar(),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildWaterProfileTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Header với user info
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Icon(
              Icons.person,
              size: 24,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _currentUser?['full_name'] ?? 'Loading...',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _currentUser?['email'] ?? '',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Settings button
          IconButton(
            onPressed: () {
              // Navigate to settings (placeholder)
            },
            icon: const Icon(Icons.settings, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  /// Tab bar
  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(8),
        ),
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTextStyles.labelMedium,
        tabs: const [
          Tab(
            icon: Icon(Icons.dashboard, size: 20),
            text: 'Tổng quan',
          ),
          Tab(
            icon: Icon(Icons.water_drop, size: 20),
            text: 'Cấu hình nước',
          ),
        ],
      ),
    );
  }

  /// Overview tab với stats
  Widget _buildOverviewTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildSettingsSection(),
          const SizedBox(height: 24),
          _buildAccountSection(),
        ],
      ),
    );
  }

  /// Water profile tab
  Widget _buildWaterProfileTab() {
    return const WaterProfileForm();
  }

  /// Quick stats section
  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.cyanAccent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Thống kê nhanh',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatItem(
                'XP',
                '1,250',
                Icons.emoji_events,
                AppColors.purpleXP,
              ),
              _buildStatItem(
                'Streak',
                '7 ngày',
                Icons.local_fire_department,
                AppColors.juiceColor,
              ),
              _buildStatItem(
                'Tổng',
                '45.2L',
                Icons.water_drop,
                AppColors.cyanAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Individual stat item
  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Settings section
  Widget _buildSettingsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, color: AppColors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Cài đặt',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Thông báo nhắc nhở',
            'Bật',
            Icons.notifications_outlined,
            () {},
          ),
          _buildSettingItem(
            'Ngôn ngữ',
            'Tiếng Việt',
            Icons.language_outlined,
            () {},
          ),
          _buildSettingItem(
            'Chế độ tối',
            'Bật',
            Icons.dark_mode_outlined,
            () {},
          ),
          _buildSettingItem(
            'Đồng bộ dữ liệu',
            'Tự động',
            Icons.sync_outlined,
            () {},
          ),
        ],
      ),
    );
  }

  /// Account section
  Widget _buildAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_circle, color: AppColors.cyanAccent, size: 20),
              const SizedBox(width: 8),
              Text(
                'Tài khoản',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.cyanAccent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSettingItem(
            'Thay đổi mật khẩu',
            '',
            Icons.lock_outline,
            () {},
          ),
          _buildSettingItem(
            'Sao lưu dữ liệu',
            '',
            Icons.backup_outlined,
            () {},
          ),
          _buildSettingItem(
            'Xuất dữ liệu',
            '',
            Icons.download_outlined,
            () {},
          ),
          const Divider(height: 24),
          _buildSettingItem(
            'Đăng xuất',
            '',
            Icons.logout,
            _showLogoutDialog,
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  /// Individual setting item
  Widget _buildSettingItem(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: isDestructive ? Colors.red : null,
        ),
      ),
      trailing: value.isNotEmpty
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
              ],
            )
          : Icon(
              Icons.chevron_right,
              color: isDestructive ? Colors.red : AppColors.textTertiary,
              size: 20,
            ),
      onTap: onTap,
    );
  }

  /// Show logout confirmation dialog
  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceColor,
        title: Text(
          'Đăng xuất',
          style: AppTextStyles.titleLarge,
        ),
        content: Text(
          'Bạn có chắc chắn muốn đăng xuất?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _logout();
            },
            child: Text(
              'Đăng xuất',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Logout user
  Future<void> _logout() async {
    try {
      await _authService.logout();
      if (mounted) {
        // Navigate to login screen
        // Navigator.of(context).pushReplacementNamed('/login');
        _showSuccess('Đã đăng xuất thành công');
      }
    } catch (e) {
      _showError('Lỗi khi đăng xuất: ${e.toString()}');
    }
  }

  /// Show error message
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Show success message
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
