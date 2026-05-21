import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_summary.dart';
import '../models/intake_log.dart';
import '../../core/services/auth_service.dart';

/// Hive local storage service cho offline-first approach
class HiveStorageService {
  static const String _dailySummaryBoxName = 'daily_summary';
  static const String _intakeLogsBoxName = 'intake_logs';
  static const String _appSettingsBoxName = 'app_settings';

  // Singleton pattern
  static HiveStorageService? _instance;
  static HiveStorageService get instance =>
      _instance ??= HiveStorageService._();
  HiveStorageService._();

  late Box<DailySummary> _dailySummaryBox;
  late Box<IntakeLog> _intakeLogsBox;
  late Box<dynamic> _appSettingsBox;

  /// Initialize Hive and register adapters
  static Future<void> initialize() async {
    await Hive.initFlutter();

    // Register type adapters
    Hive.registerAdapter(IntakeLogAdapter());
    Hive.registerAdapter(DailySummaryAdapter());

    final service = HiveStorageService.instance;
    await service._openBoxes();
  }

  /// Open all required boxes
  Future<void> _openBoxes() async {
    _dailySummaryBox = await Hive.openBox<DailySummary>(_dailySummaryBoxName);
    _intakeLogsBox = await Hive.openBox<IntakeLog>(_intakeLogsBoxName);
    _appSettingsBox = await Hive.openBox<dynamic>(_appSettingsBoxName);
  }

  Future<void> _ensureBoxesOpen() async {
    if (!_dailySummaryBox.isOpen ||
        !_intakeLogsBox.isOpen ||
        !_appSettingsBox.isOpen) {
      await _openBoxes();
    }
  }

  /// Save daily summary
  Future<void> saveDailySummary(DailySummary summary) async {
    await _ensureBoxesOpen();
    final today = await _getTodayKey();
    await _dailySummaryBox.put(today, summary);
  }

  /// Load today's summary
  Future<DailySummary?> loadTodaysSummary() async {
    await _ensureBoxesOpen();
    final today = await _getTodayKey();
    return _dailySummaryBox.get(today);
  }

  /// Save intake log with user-scoped key
  Future<void> saveIntakeLog(IntakeLog log) async {
    await _ensureBoxesOpen();

    try {
      final authService = AuthService();
      final userId = await authService.getCurrentUserId();

      if (userId != null && userId.isNotEmpty) {
        final userScopedKey = '$userId:${log.id}';
        await _intakeLogsBox.put(userScopedKey, log);
      } else {
        // Fallback to original key if no user ID
        await _intakeLogsBox.put('guest:${log.id}', log);
      }
    } catch (e) {
      // Fallback to original key on error
      await _intakeLogsBox.put('guest:${log.id}', log);
    }
  }

  /// Load today's intake logs for current user
  Future<List<IntakeLog>> loadTodaysLogs() async {
    await _ensureBoxesOpen();

    try {
      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();

      if (currentUserId == null || currentUserId.isEmpty) {
        return []; // Return empty if no user authenticated
      }

      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final userKeyPrefix = '$currentUserId:';

      // Filter keys by user prefix, then filter values by date
      final userLogs = <IntakeLog>[];
      for (final key in _intakeLogsBox.keys) {
        if (key.toString().startsWith(userKeyPrefix)) {
          final log = _intakeLogsBox.get(key);
          if (log != null &&
              log.loggedAt.isAfter(todayStart) &&
              log.loggedAt.isBefore(todayEnd)) {
            userLogs.add(log);
          }
        }
      }

      return userLogs..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    } catch (e) {
      return []; // Return empty on error
    }
  }

  /// Load all intake logs for a specific date range
  List<IntakeLog> loadLogsInDateRange(DateTime startDate, DateTime endDate) {
    return _intakeLogsBox.values
        .where(
          (log) =>
              log.loggedAt.isAfter(startDate) && log.loggedAt.isBefore(endDate),
        )
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  /// Load all intake logs for current user (for analytics and stats)
  Future<List<IntakeLog>> loadAllIntakeLogs() async {
    await _ensureBoxesOpen();

    try {
      final authService = AuthService();
      final currentUserId = await authService.getCurrentUserId();

      if (currentUserId == null || currentUserId.isEmpty) {
        return []; // Return empty if no user authenticated
      }

      final userKeyPrefix = '$currentUserId:';
      final userLogs = <IntakeLog>[];

      for (final key in _intakeLogsBox.keys) {
        if (key.toString().startsWith(userKeyPrefix)) {
          final log = _intakeLogsBox.get(key);
          if (log != null) {
            userLogs.add(log);
          }
        }
      }

      return userLogs..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    } catch (e) {
      return []; // Return empty on error
    }
  }

  /// Delete old logs (older than 30 days) to save space
  Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
    await _ensureBoxesOpen();
    final cutoffDate = DateTime.now().subtract(Duration(days: daysToKeep));

    final logsToDelete = _intakeLogsBox.values
        .where((log) => log.loggedAt.isBefore(cutoffDate))
        .map((log) => log.id)
        .toList();

    for (final logId in logsToDelete) {
      await _intakeLogsBox.delete(logId);
    }
  }

  /// Save app setting
  Future<void> saveSetting(String key, dynamic value) async {
    await _ensureBoxesOpen();
    await _appSettingsBox.put(key, value);
  }

  /// Load app setting
  Future<T?> loadSetting<T>(String key) async {
    await _ensureBoxesOpen();
    return _appSettingsBox.get(key) as T?;
  }

  /// Save coach conversation messages
  Future<void> saveCoachConversation(
    List<Map<String, dynamic>> messages,
  ) async {
    await _ensureBoxesOpen();
    await _appSettingsBox.put('coach_conversation', messages);
  }

  /// Load coach conversation messages
  Future<List<Map<String, dynamic>>?> loadCoachConversation() async {
    await _ensureBoxesOpen();
    final data = _appSettingsBox.get('coach_conversation');
    if (data == null) return null;

    return (data as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  /// Cache friends data
  Future<void> cacheFriends(List<dynamic> friends) async {
    await _ensureBoxesOpen();
    final friendsData = friends.map((friend) {
      if (friend is Map<String, dynamic>) {
        return friend;
      } else {
        // Assume it's a Friend object with toJson method
        return (friend as dynamic).toJson();
      }
    }).toList();

    await _appSettingsBox.put('cached_friends', friendsData);
    await _appSettingsBox.put(
      'friends_cache_time',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Load cached friends data
  List<Map<String, dynamic>> loadCachedFriends() {
    final data = _appSettingsBox.get('cached_friends');
    if (data == null) return [];

    return (data as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  /// Cache friend requests data
  Future<void> cacheFriendRequests(List<dynamic> requests) async {
    await _ensureBoxesOpen();
    final requestsData = requests.map((request) {
      if (request is Map<String, dynamic>) {
        return request;
      } else {
        return (request as dynamic).toJson();
      }
    }).toList();

    await _appSettingsBox.put('cached_friend_requests', requestsData);
  }

  /// Load cached friend requests
  List<Map<String, dynamic>> loadCachedFriendRequests() {
    final data = _appSettingsBox.get('cached_friend_requests');
    if (data == null) return [];

    return (data as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  /// Cache weekly leaderboard data
  Future<void> cacheWeeklyLeaderboard(List<dynamic> leaderboard) async {
    await _ensureBoxesOpen();
    final leaderboardData = leaderboard.map((entry) {
      if (entry is Map<String, dynamic>) {
        return entry;
      } else {
        return (entry as dynamic).toJson();
      }
    }).toList();

    await _appSettingsBox.put('cached_weekly_leaderboard', leaderboardData);
  }

  /// Load cached weekly leaderboard
  List<Map<String, dynamic>> loadCachedWeeklyLeaderboard() {
    final data = _appSettingsBox.get('cached_weekly_leaderboard');
    if (data == null) return [];

    return (data as List)
        .map<Map<String, dynamic>>(
          (item) => Map<String, dynamic>.from(item as Map),
        )
        .toList();
  }

  /// Cache social stats data
  Future<void> cacheSocialStats(Map<String, dynamic> stats) async {
    await _ensureBoxesOpen();
    await _appSettingsBox.put('cached_social_stats', stats);
  }

  /// Load cached social stats
  Map<String, dynamic>? loadCachedSocialStats() {
    final data = _appSettingsBox.get('cached_social_stats');
    if (data == null) return null;

    return Map<String, dynamic>.from(data as Map);
  }

  /// Cache timestamp for data freshness tracking
  Future<void> cacheSocialDataTimestamp(DateTime timestamp) async {
    await _ensureBoxesOpen();
    await _appSettingsBox.put(
      'social_data_timestamp',
      timestamp.millisecondsSinceEpoch,
    );
  }

  /// Load cached social data timestamp
  DateTime? loadCachedSocialDataTimestamp() {
    final timestampMs = _appSettingsBox.get('social_data_timestamp');
    if (timestampMs == null) return null;

    return DateTime.fromMillisecondsSinceEpoch(timestampMs as int);
  }

  /// Check if friends cache is expired (older than 5 minutes)
  bool isFriendsCacheExpired() {
    final cacheTime = _appSettingsBox.get('friends_cache_time');
    if (cacheTime == null) return true;

    final cacheDateTime = DateTime.fromMillisecondsSinceEpoch(cacheTime as int);
    final now = DateTime.now();

    return now.difference(cacheDateTime).inMinutes > 5;
  }

  /// Clear all data (for testing or reset functionality)
  Future<void> clearAllData() async {
    await _ensureBoxesOpen();
    await _dailySummaryBox.clear();
    await _intakeLogsBox.clear();
    await _appSettingsBox.clear();
  }

  /// Get storage statistics
  Map<String, int> getStorageStats() {
    return {
      'dailySummaries': _dailySummaryBox.length,
      'intakeLogs': _intakeLogsBox.length,
      'appSettings': _appSettingsBox.length,
    };
  }

  /// Generate today's key for daily summary storage
  Future<String> _getTodayKey() async {
    final today = DateTime.now();
    final dateKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

    try {
      final authService = AuthService();
      final userId = await authService.getCurrentUserId();

      if (userId != null && userId.isNotEmpty) {
        return '$userId:$dateKey';
      } else {
        // Fallback to date-only key if no user ID (shouldn't happen in normal flow)
        return 'guest:$dateKey';
      }
    } catch (e) {
      // Fallback if auth service fails
      return 'guest:$dateKey';
    }
  }
}
