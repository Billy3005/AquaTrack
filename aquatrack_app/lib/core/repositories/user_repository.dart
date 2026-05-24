import '../models/user.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Repository for user profile management
class UserRepository {
  static const String _tag = 'UserRepository';

  final ApiService _apiService;

  UserRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  /// Get current user profile
  Future<User> getProfile() async {
    AppLogger.info(_tag, 'Fetching user profile');

    try {
      final response = await _apiService.get<User>(
        '/users/profile',
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        AppLogger.info(_tag, 'Profile fetched successfully');
        return response.data!;
      } else {
        throw Exception('Profile response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch profile', e);
      rethrow;
    }
  }

  /// Update user profile
  Future<User> updateProfile(Map<String, dynamic> profileData) async {
    AppLogger.info(_tag, 'Updating user profile');

    try {
      final response = await _apiService.put<User>(
        '/users/profile',
        data: profileData,
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        AppLogger.info(_tag, 'Profile updated successfully');
        return response.data!;
      } else {
        throw Exception('Profile update response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to update profile', e);
      rethrow;
    }
  }

  /// Submit onboarding data
  Future<User> submitOnboardingData({
    required String gender,
    required int age,
    required int height,
    required double weight,
    required String activityLevel,
    required String jobType,
    required List<String> healthConditions,
    required String veggieIntake,
    required int coffeeCupsPerDay,
    required int alcoholUnitsPerDay,
  }) async {
    AppLogger.info(_tag, 'Submitting onboarding data');

    try {
      final onboardingData = {
        'gender': gender,
        'age': age,
        'height': height,
        'weight': weight,
        'activity_level': activityLevel,
        'job_type': jobType,
        'health_conditions': healthConditions,
        'veggie_intake': veggieIntake,
        'coffee_cups_per_day': coffeeCupsPerDay,
        'alcohol_units_per_day': alcoholUnitsPerDay,
      };

      final response = await _apiService.put<User>(
        '/users/profile',
        data: onboardingData,
        fromJson: (json) => User.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        AppLogger.info(_tag, 'Onboarding data submitted successfully');
        return response.data!;
      } else {
        throw Exception('Onboarding submission response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to submit onboarding data', e);
      rethrow;
    }
  }

  /// Get user stats
  Future<UserStats> getUserStats() async {
    AppLogger.info(_tag, 'Fetching user stats');

    try {
      final response = await _apiService.get<UserStats>(
        '/users/stats',
        fromJson: (json) => UserStats.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        AppLogger.info(_tag, 'User stats fetched successfully');
        return response.data!;
      } else {
        throw Exception('User stats response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch user stats', e);
      rethrow;
    }
  }
}

/// User stats model
class UserStats {
  final int currentLevel;
  final int totalXp;
  final int currentStreak;
  final int longestStreak;
  final int totalLogsCount;
  final int totalVolumeMl;
  final double totalVolumeLiters;

  const UserStats({
    required this.currentLevel,
    required this.totalXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.totalLogsCount,
    required this.totalVolumeMl,
    required this.totalVolumeLiters,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentLevel: json['current_level'] as int,
      totalXp: json['total_xp'] as int,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      totalLogsCount: json['total_logs_count'] as int,
      totalVolumeMl: json['total_volume_ml'] as int,
      totalVolumeLiters: (json['total_volume_liters'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_level': currentLevel,
      'total_xp': totalXp,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'total_logs_count': totalLogsCount,
      'total_volume_ml': totalVolumeMl,
      'total_volume_liters': totalVolumeLiters,
    };
  }
}
