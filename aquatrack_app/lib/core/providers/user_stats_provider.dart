import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/user_repository.dart';
import '../models/user.dart';
import 'auth_state_provider.dart';

/// Provider for refreshing user stats - increment to refresh
final userStatsRefreshProvider = StateProvider<int>((ref) => 0);

/// Provider for user stats (coins, streak, level, etc)
final userStatsProvider = FutureProvider<UserStatsData>((ref) async {
  // Watch auth state to refresh on login/logout
  final authState = ref.watch(authStateProvider);

  // Don't fetch if not authenticated
  if (!authState.isAuthenticated) {
    throw Exception('User not authenticated');
  }

  // Watch refresh trigger to invalidate cache
  ref.watch(userStatsRefreshProvider);

  final userRepository = UserRepository();
  return _loadUserStats(userRepository);
});

/// Load user stats from backend
Future<UserStatsData> _loadUserStats(UserRepository userRepository) async {
  try {
    // Get user profile first (contains basic info)
    final user = await userRepository.getProfile();

    // Get detailed stats
    final stats = await userRepository.getUserStats();

    return UserStatsData(
      // From user profile
      currentLevel: user.level,
      totalXp: user.totalXp,
      dailyGoalMl: user.dailyGoalMl,

      // From user stats
      currentStreak: stats.currentStreak,
      longestStreak: stats.longestStreak,
      totalLogsCount: stats.totalLogsCount,
      totalVolumeMl: stats.totalVolumeMl,
      totalVolumeLiters: stats.totalVolumeLiters,

      // Real spendable coin balance from backend
      coins: user.coins,
      levelName: _getLevelName(user.level),
    );
  } catch (e) {
    throw Exception('Failed to load user stats: $e');
  }
}

/// Get level name based on current level
String _getLevelName(int level) {
  if (level >= 50) return 'Thần nước';
  if (level >= 40) return 'Chuyên gia hydration';
  if (level >= 30) return 'Bậc thầy nước';
  if (level >= 20) return 'Ninja hydration';
  if (level >= 10) return 'Chiến binh nước';
  if (level >= 5) return 'Người uống nước';
  return 'Tân binh';
}

/// Data class for user stats
class UserStatsData {
  final int currentLevel;
  final int totalXp;
  final int dailyGoalMl;
  final int currentStreak;
  final int longestStreak;
  final int totalLogsCount;
  final int totalVolumeMl;
  final double totalVolumeLiters;
  final int coins;
  final String levelName;

  const UserStatsData({
    required this.currentLevel,
    required this.totalXp,
    required this.dailyGoalMl,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalLogsCount,
    required this.totalVolumeMl,
    required this.totalVolumeLiters,
    required this.coins,
    required this.levelName,
  });

  UserStatsData copyWith({
    int? currentLevel,
    int? totalXp,
    int? dailyGoalMl,
    int? currentStreak,
    int? longestStreak,
    int? totalLogsCount,
    int? totalVolumeMl,
    double? totalVolumeLiters,
    int? coins,
    String? levelName,
  }) {
    return UserStatsData(
      currentLevel: currentLevel ?? this.currentLevel,
      totalXp: totalXp ?? this.totalXp,
      dailyGoalMl: dailyGoalMl ?? this.dailyGoalMl,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      totalLogsCount: totalLogsCount ?? this.totalLogsCount,
      totalVolumeMl: totalVolumeMl ?? this.totalVolumeMl,
      totalVolumeLiters: totalVolumeLiters ?? this.totalVolumeLiters,
      coins: coins ?? this.coins,
      levelName: levelName ?? this.levelName,
    );
  }
}
