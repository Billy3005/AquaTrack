import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/friend_model.dart';
import '../providers/friends_provider.dart';

/// Status filters widget for friends list
class StatusFilters extends ConsumerWidget {
  const StatusFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(friendsNotifierProvider);

    return friendsState.when(
      data: (state) => _buildFilters(context, ref, state),
      loading: () => _buildLoadingFilters(),
      error: (error, stack) => _buildErrorFilters(),
    );
  }

  /// Build filter chips
  Widget _buildFilters(
      BuildContext context, WidgetRef ref, FriendsState state) {
    final filters = [
      _FilterItem(
        filter: FriendStatusFilter.all,
        label: 'Tất cả',
        count: state.friends.length,
        icon: Icons.people,
      ),
      _FilterItem(
        filter: FriendStatusFilter.thirsty,
        label: 'Đang khát',
        count:
            state.friends.where((f) => f.status == FriendStatus.thirsty).length,
        icon: Icons.water_drop,
        color: AppColors.error,
      ),
      _FilterItem(
        filter: FriendStatusFilter.online,
        label: 'Online',
        count: state.friends.where((f) => f.isOnline).length,
        icon: Icons.circle,
        color: AppColors.success,
      ),
      _FilterItem(
        filter: FriendStatusFilter.stressed,
        label: 'Đang stress',
        count: state.friends
            .where((f) => f.status == FriendStatus.stressed)
            .length,
        icon: Icons.psychology,
        color: AppColors.warning,
      ),
    ];

    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final filterItem = filters[index];
          final isSelected = state.currentFilter == filterItem.filter;

          return _buildFilterChip(
            context,
            ref,
            filterItem,
            isSelected,
          );
        },
      ),
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip(
    BuildContext context,
    WidgetRef ref,
    _FilterItem filterItem,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () {
        ref.read(friendsNotifierProvider.notifier).setFilter(filterItem.filter);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.cyanAccent.withValues(alpha: 0.15)
              : AppColors.surfaceColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.cyanAccent.withValues(alpha: 0.3)
                : AppColors.borderColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              filterItem.icon,
              size: 16,
              color: isSelected
                  ? AppColors.cyanAccent
                  : (filterItem.color ?? AppColors.textSecondary),
            ),

            const SizedBox(width: 6),

            // Label
            Text(
              filterItem.label,
              style: AppTextStyles.labelSmall.copyWith(
                color:
                    isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),

            // Count badge
            if (filterItem.count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.cyanAccent
                      : AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  filterItem.count.toString(),
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.primaryBackground
                        : AppColors.surfaceColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Build loading state filters
  Widget _buildLoadingFilters() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(4, (index) {
          return Container(
            margin: EdgeInsets.only(right: index < 3 ? 12 : 0),
            width: 80 + (index * 20.0),
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surfaceColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
          );
        }),
      ),
    );
  }

  /// Build error state filters
  Widget _buildErrorFilters() {
    return Container(
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Center(
        child: Text(
          'Không thể tải bộ lọc',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ),
    );
  }
}

/// Filter item data class
class _FilterItem {
  final FriendStatusFilter filter;
  final String label;
  final int count;
  final IconData icon;
  final Color? color;

  const _FilterItem({
    required this.filter,
    required this.label,
    required this.count,
    required this.icon,
    this.color,
  });
}
