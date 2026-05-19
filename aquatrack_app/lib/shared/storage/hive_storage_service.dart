import 'package:hive_flutter/hive_flutter.dart';

import '../models/daily_summary.dart';
import '../models/intake_log.dart';

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

  /// Save daily summary
  Future<void> saveDailySummary(DailySummary summary) async {
    final today = _getTodayKey();
    await _dailySummaryBox.put(today, summary);
  }

  /// Load today's summary
  DailySummary? loadTodaysSummary() {
    final today = _getTodayKey();
    return _dailySummaryBox.get(today);
  }

  /// Save intake log
  Future<void> saveIntakeLog(IntakeLog log) async {
    await _intakeLogsBox.put(log.id, log);
  }

  /// Load today's intake logs
  List<IntakeLog> loadTodaysLogs() {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    return _intakeLogsBox.values
        .where(
          (log) =>
              log.loggedAt.isAfter(todayStart) &&
              log.loggedAt.isBefore(todayEnd),
        )
        .toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
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

  /// Load all intake logs (for analytics and stats)
  List<IntakeLog> loadAllIntakeLogs() {
    return _intakeLogsBox.values.toList()
      ..sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
  }

  /// Delete old logs (older than 30 days) to save space
  Future<void> cleanupOldLogs({int daysToKeep = 30}) async {
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
    await _appSettingsBox.put(key, value);
  }

  /// Load app setting
  T? loadSetting<T>(String key) {
    return _appSettingsBox.get(key) as T?;
  }

  /// Save coach conversation messages
  Future<void> saveCoachConversation(
    List<Map<String, dynamic>> messages,
  ) async {
    await _appSettingsBox.put('coach_conversation', messages);
  }

  /// Load coach conversation messages
  List<Map<String, dynamic>>? loadCoachConversation() {
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
  String _getTodayKey() {
    final today = DateTime.now();
    return '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  }
}
