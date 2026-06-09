import '../network/api_client.dart';
import '../network/default_api_client.dart';
import '../utils/logger.dart';

/// Repository for level and achievement API calls
class LevelRepository {
  static const String _tag = 'LevelRepository';

  final ApiClient _apiService;

  LevelRepository({ApiClient? apiClient})
      : _apiService = apiClient ?? defaultApiClient;

  /// Get current level and XP information
  Future<LevelApiResponse<LevelInfo>> getCurrentLevel() async {
    AppLogger.info(_tag, 'Getting current level info');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/levels/current',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final levelInfo = LevelInfo.fromJson(response.data!);
      return LevelApiResponse.success(levelInfo);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get current level', e);
      return LevelApiResponse.error('Failed to load level info: $e');
    }
  }

  /// Get all achievements with progress
  Future<LevelApiResponse<List<AchievementProgress>>> getAchievements() async {
    AppLogger.info(_tag, 'Getting achievements');

    try {
      final response = await _apiService.get<List<dynamic>>(
        '/levels/achievements',
        fromJson: (json) => json as List<dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final achievements = response.data!
          .map((item) => AchievementProgress.fromJson(item))
          .toList();
      return LevelApiResponse.success(achievements);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get achievements', e);
      return LevelApiResponse.error('Failed to load achievements: $e');
    }
  }

  /// Claim achievement rewards
  Future<LevelApiResponse<ClaimRewardResponse>> claimAchievement(
    String achievementId,
  ) async {
    AppLogger.info(_tag, 'Claiming achievement: $achievementId');

    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        '/levels/achievements/$achievementId/claim',
        data: {},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final claimResponse = ClaimRewardResponse.fromJson(response.data!);
      return LevelApiResponse.success(claimResponse);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to claim achievement', e);
      return LevelApiResponse.error('Failed to claim achievement: $e');
    }
  }

  /// Get unlocked avatars
  Future<LevelApiResponse<List<String>>> getUnlockedAvatars() async {
    AppLogger.info(_tag, 'Getting unlocked avatars');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/levels/unlocked-avatars',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final avatars = List<String>.from(response.data!['unlocked_avatars']);
      return LevelApiResponse.success(avatars);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get unlocked avatars', e);
      return LevelApiResponse.error('Failed to load avatars: $e');
    }
  }

  /// Get level statistics
  Future<LevelApiResponse<LevelStats>> getLevelStats() async {
    AppLogger.info(_tag, 'Getting level stats');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/levels/stats',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final stats = LevelStats.fromJson(response.data!);
      return LevelApiResponse.success(stats);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get level stats', e);
      return LevelApiResponse.error('Failed to load level stats: $e');
    }
  }

  /// Get leaderboard
  Future<LevelApiResponse<Leaderboard>> getLeaderboard({
    String period = 'month',
    int limit = 10,
  }) async {
    AppLogger.info(_tag, 'Getting leaderboard for period: $period');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/levels/leaderboard',
        queryParams: {'period': period, 'limit': limit},
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final leaderboard = Leaderboard.fromJson(response.data!);
      return LevelApiResponse.success(leaderboard);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get leaderboard', e);
      return LevelApiResponse.error('Failed to load leaderboard: $e');
    }
  }

  /// Get level rewards preview
  Future<LevelApiResponse<List<LevelReward>>> getLevelRewards() async {
    AppLogger.info(_tag, 'Getting level rewards preview');

    try {
      final response = await _apiService.get<Map<String, dynamic>>(
        '/levels/rewards/preview',
        fromJson: (json) => json as Map<String, dynamic>,
      );

      if (response.data == null) {
        throw Exception('No data received from API');
      }

      final rewards = (response.data!['rewards'] as List<dynamic>)
          .map((item) => LevelReward.fromJson(item))
          .toList();
      return LevelApiResponse.success(rewards);
    } catch (e) {
      AppLogger.error(_tag, 'Failed to get level rewards', e);
      return LevelApiResponse.error('Failed to load level rewards: $e');
    }
  }
}

/// Generic API response wrapper for level data
class LevelApiResponse<T> {
  final bool isSuccess;
  final T? data;
  final String? error;

  const LevelApiResponse._({required this.isSuccess, this.data, this.error});

  factory LevelApiResponse.success(T data) =>
      LevelApiResponse._(isSuccess: true, data: data);

  factory LevelApiResponse.error(String error) =>
      LevelApiResponse._(isSuccess: false, error: error);
}

/// Level info API response model
class LevelInfo {
  final int currentLevel;
  final int currentXP;
  final int xpForNextLevel;
  final int xpToNextLevel;
  final double levelProgressPercentage;
  final int totalXPEarned;

  const LevelInfo({
    required this.currentLevel,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.xpToNextLevel,
    required this.levelProgressPercentage,
    required this.totalXPEarned,
  });

  factory LevelInfo.fromJson(Map<String, dynamic> json) {
    return LevelInfo(
      currentLevel: json['current_level'] ?? 1,
      currentXP: json['current_xp'] ?? 0,
      xpForNextLevel: json['xp_for_next_level'] ?? 100,
      xpToNextLevel: json['xp_to_next_level'] ?? 100,
      levelProgressPercentage:
          (json['level_progress_percentage'] ?? 0).toDouble(),
      totalXPEarned: json['total_xp_earned'] ?? 0,
    );
  }
}

/// Achievement progress API response model
class AchievementProgress {
  final String id;
  final String title;
  final String description;
  final String icon;
  final String type;
  final String rarity;
  final int currentValue;
  final int requiredValue;
  final int progressPercentage;
  final bool isUnlocked;
  final bool isClaimed;
  final int xpReward;
  final String? unlockAvatarId;

  const AchievementProgress({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
    required this.rarity,
    required this.currentValue,
    required this.requiredValue,
    required this.progressPercentage,
    required this.isUnlocked,
    required this.isClaimed,
    required this.xpReward,
    this.unlockAvatarId,
  });

  factory AchievementProgress.fromJson(Map<String, dynamic> json) {
    return AchievementProgress(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      type: json['type'] ?? '',
      rarity: json['rarity'] ?? '',
      currentValue: json['current_value'] ?? 0,
      requiredValue: json['required_value'] ?? 0,
      progressPercentage: json['progress_percentage'] ?? 0,
      isUnlocked: json['is_unlocked'] ?? false,
      isClaimed: json['is_claimed'] ?? false,
      xpReward: json['xp_reward'] ?? 0,
      unlockAvatarId: json['unlock_avatar_id'],
    );
  }
}

/// Claim achievement reward response
class ClaimRewardResponse {
  final String message;
  final int xpReward;
  final String? unlockAvatarId;
  final String? unlockBadgeId;

  const ClaimRewardResponse({
    required this.message,
    required this.xpReward,
    this.unlockAvatarId,
    this.unlockBadgeId,
  });

  factory ClaimRewardResponse.fromJson(Map<String, dynamic> json) {
    return ClaimRewardResponse(
      message: json['message'] ?? '',
      xpReward: json['xp_reward'] ?? 0,
      unlockAvatarId: json['unlock_avatar_id'],
      unlockBadgeId: json['unlock_badge_id'],
    );
  }
}

/// Level statistics response
class LevelStats {
  final int level;
  final int totalXP;
  final int xpThisWeek;
  final AchievementStats achievements;
  final NextMilestone nextMilestone;

  const LevelStats({
    required this.level,
    required this.totalXP,
    required this.xpThisWeek,
    required this.achievements,
    required this.nextMilestone,
  });

  factory LevelStats.fromJson(Map<String, dynamic> json) {
    return LevelStats(
      level: json['level'] ?? 1,
      totalXP: json['total_xp'] ?? 0,
      xpThisWeek: json['xp_this_week'] ?? 0,
      achievements: AchievementStats.fromJson(json['achievements']),
      nextMilestone: NextMilestone.fromJson(json['next_milestone']),
    );
  }
}

class AchievementStats {
  final int total;
  final int unlocked;
  final int claimed;
  final double completionPercentage;

  const AchievementStats({
    required this.total,
    required this.unlocked,
    required this.claimed,
    required this.completionPercentage,
  });

  factory AchievementStats.fromJson(Map<String, dynamic> json) {
    return AchievementStats(
      total: json['total'] ?? 0,
      unlocked: json['unlocked'] ?? 0,
      claimed: json['claimed'] ?? 0,
      completionPercentage: (json['completion_percentage'] ?? 0).toDouble(),
    );
  }
}

class NextMilestone {
  final int level;
  final int xpNeeded;
  final double progressPercentage;

  const NextMilestone({
    required this.level,
    required this.xpNeeded,
    required this.progressPercentage,
  });

  factory NextMilestone.fromJson(Map<String, dynamic> json) {
    return NextMilestone(
      level: json['level'] ?? 1,
      xpNeeded: json['xp_needed'] ?? 0,
      progressPercentage: (json['progress_percentage'] ?? 0).toDouble(),
    );
  }
}

/// Leaderboard response
class Leaderboard {
  final String period;
  final List<LeaderboardEntry> leaderboard;
  final int? currentUserRank;

  const Leaderboard({
    required this.period,
    required this.leaderboard,
    this.currentUserRank,
  });

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    return Leaderboard(
      period: json['period'] ?? 'month',
      leaderboard: (json['leaderboard'] as List<dynamic>)
          .map((item) => LeaderboardEntry.fromJson(item))
          .toList(),
      currentUserRank: json['current_user_rank'],
    );
  }
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int totalXP;
  final int level;
  final int totalLogs;
  final int totalVolumeML;
  final bool isCurrentUser;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.totalXP,
    required this.level,
    required this.totalLogs,
    required this.totalVolumeML,
    required this.isCurrentUser,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      totalXP: json['total_xp'] ?? 0,
      level: json['level'] ?? 1,
      totalLogs: json['total_logs'] ?? 0,
      totalVolumeML: json['total_volume_ml'] ?? 0,
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }
}

/// Level reward preview
class LevelReward {
  final int level;
  final String title;
  final String description;
  final String? avatarUnlock;
  final String? badgeUnlock;
  final int xpBonus;

  const LevelReward({
    required this.level,
    required this.title,
    required this.description,
    this.avatarUnlock,
    this.badgeUnlock,
    required this.xpBonus,
  });

  factory LevelReward.fromJson(Map<String, dynamic> json) {
    return LevelReward(
      level: json['level'] ?? 1,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      avatarUnlock: json['avatar_unlock'],
      badgeUnlock: json['badge_unlock'],
      xpBonus: json['xp_bonus'] ?? 0,
    );
  }
}
