import '../models/intake_log.dart';
import '../models/intake_log_with_achievements.dart';
import '../services/api_service.dart';
import '../utils/logger.dart';

/// Repository for intake logging API calls
class IntakeRepository {
  static const String _tag = 'IntakeRepository';

  final ApiService _apiService;

  IntakeRepository({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  /// Create new intake log entry with achievements
  Future<IntakeLogWithAchievements> createIntakeLog({
    required int volumeMl,
    required String liquidType,
    String? temperature,
    String? location,
    String? moodBefore,
    String source = 'manual',
  }) async {
    AppLogger.info(_tag, 'Creating intake log: ${volumeMl}ml of $liquidType');

    try {
      final request = IntakeLogCreateRequest(
        volumeMl: volumeMl,
        liquidType: liquidType,
        temperature: temperature,
        location: location,
        moodBefore: moodBefore,
        source: source,
      );

      final response = await _apiService.post<dynamic>(
        '/intake/',
        data: request.toJson(),
        fromJson: (json) => json,
      );

      if (response.data != null) {
        final raw = response.data;
        Map<String, dynamic>? payload;

        if (raw is Map<String, dynamic>) {
          payload = raw['intake_log'] is Map<String, dynamic>
              ? raw
              : (raw['data'] is Map<String, dynamic>
                    ? raw['data'] as Map<String, dynamic>
                    : null);
        }

        if (payload == null) {
          throw Exception('Create intake log response data has invalid format');
        }

        final parsed = IntakeLogWithAchievements.fromJson(payload);
        AppLogger.info(
          _tag,
          'Intake log created successfully: ${parsed.intakeLog.id}',
        );

        // Log achievements if any
        if (parsed.hasAchievements) {
          AppLogger.info(
            _tag,
            'Unlocked ${parsed.achievements.length} achievements',
          );
        }

        return parsed;
      } else {
        throw Exception('Create intake log response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to create intake log', e);
      rethrow;
    }
  }

  /// Get today's intake logs
  Future<List<IntakeLog>> getTodayIntakeLogs() async {
    AppLogger.debug(_tag, 'Fetching today\'s intake logs');

    try {
      final response = await _apiService.get<List<IntakeLog>>(
        '/intake/today',
        fromJson: (json) => (json as List)
            .map((item) => IntakeLog.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      return response.data ?? [];
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch today\'s intake logs', e);
      rethrow;
    }
  }

  /// Get intake logs with pagination and filters
  Future<List<IntakeLog>> getIntakeLogs({
    int skip = 0,
    int limit = 100,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? liquidType,
  }) async {
    AppLogger.debug(_tag, 'Fetching intake logs with filters');

    try {
      final queryParams = <String, dynamic>{'skip': skip, 'limit': limit};

      if (dateFrom != null) {
        queryParams['date_from'] = dateFrom.toIso8601String().split('T')[0];
      }
      if (dateTo != null) {
        queryParams['date_to'] = dateTo.toIso8601String().split('T')[0];
      }
      if (liquidType != null) {
        queryParams['liquid_type'] = liquidType;
      }

      final response = await _apiService.get<List<IntakeLog>>(
        '/intake/',
        queryParams: queryParams,
        fromJson: (json) => (json as List)
            .map((item) => IntakeLog.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      return response.data ?? [];
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch intake logs', e);
      rethrow;
    }
  }

  /// Get recent intake logs
  Future<List<IntakeLog>> getRecentIntakeLogs({int limit = 10}) async {
    AppLogger.debug(_tag, 'Fetching recent intake logs');

    try {
      final response = await _apiService.get<List<IntakeLog>>(
        '/intake/recent',
        queryParams: {'limit': limit},
        fromJson: (json) => (json as List)
            .map((item) => IntakeLog.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

      return response.data ?? [];
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch recent intake logs', e);
      rethrow;
    }
  }

  /// Get specific intake log by ID
  Future<IntakeLog?> getIntakeLog(String intakeLogId) async {
    AppLogger.debug(_tag, 'Fetching intake log: $intakeLogId');

    try {
      final response = await _apiService.get<IntakeLog>(
        '/intake/$intakeLogId',
        fromJson: (json) => IntakeLog.fromJson(json as Map<String, dynamic>),
      );

      return response.data;
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch intake log: $intakeLogId', e);
      rethrow;
    }
  }

  /// Update existing intake log
  Future<IntakeLog> updateIntakeLog({
    required String intakeLogId,
    int? volumeMl,
    String? liquidType,
    String? temperature,
    String? location,
    String? moodAfter,
  }) async {
    AppLogger.info(_tag, 'Updating intake log: $intakeLogId');

    try {
      final request = IntakeLogUpdateRequest(
        volumeMl: volumeMl,
        liquidType: liquidType,
        temperature: temperature,
        location: location,
        moodAfter: moodAfter,
      );

      final response = await _apiService.put<IntakeLog>(
        '/intake/$intakeLogId',
        data: request.toJson(),
        fromJson: (json) => IntakeLog.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        AppLogger.info(_tag, 'Intake log updated successfully: $intakeLogId');
        return response.data!;
      } else {
        throw Exception('Update intake log response data is null');
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to update intake log: $intakeLogId', e);
      rethrow;
    }
  }

  /// Delete intake log
  Future<void> deleteIntakeLog(String intakeLogId) async {
    AppLogger.info(_tag, 'Deleting intake log: $intakeLogId');

    try {
      await _apiService.delete('/intake/$intakeLogId');
      AppLogger.info(_tag, 'Intake log deleted successfully: $intakeLogId');
    } catch (e) {
      AppLogger.error(_tag, 'Failed to delete intake log: $intakeLogId', e);
      rethrow;
    }
  }

  /// Get today's intake summary
  Future<DailySummaryResponse> getTodaySummary() async {
    AppLogger.debug(_tag, 'Fetching today\'s intake summary');

    try {
      final response = await _apiService.get<DailySummaryResponse>(
        '/intake/summary/today',
        fromJson: (json) =>
            DailySummaryResponse.fromJson(json as Map<String, dynamic>),
      );

      if (response.data != null) {
        return response.data!;
      } else {
        // Return empty summary if no data
        return DailySummaryResponse(
          date: DateTime.now(),
          logCount: 0,
          totalVolumeMl: 0,
          totalEffectiveMl: 0,
          totalXpEarned: 0,
        );
      }
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch today\'s summary', e);
      rethrow;
    }
  }

  /// Get liquid types statistics
  Future<List<Map<String, dynamic>>> getLiquidTypesStats({int days = 7}) async {
    AppLogger.debug(_tag, 'Fetching liquid types statistics for $days days');

    try {
      final response = await _apiService.get<List<Map<String, dynamic>>>(
        '/intake/stats/liquid-types',
        queryParams: {'days': days},
        fromJson: (json) =>
            (json as List).map((item) => item as Map<String, dynamic>).toList(),
      );

      return response.data ?? [];
    } catch (e) {
      AppLogger.error(_tag, 'Failed to fetch liquid types stats', e);
      rethrow;
    }
  }

  /// Quick log water with predefined amounts
  Future<IntakeLogWithAchievements> quickLogWater(int volumeMl) async {
    return createIntakeLog(
      volumeMl: volumeMl,
      liquidType: 'water',
      source: 'quick_log',
    );
  }

  /// Log water from smart scan
  Future<IntakeLogWithAchievements> logFromScan({
    required int volumeMl,
    required double confidenceScore,
    String? deviceInfo,
  }) async {
    AppLogger.info(
      _tag,
      'Logging water from smart scan: ${volumeMl}ml (confidence: $confidenceScore)',
    );

    // For smart scan, we need to handle confidence score and validation
    // This would be extended when smart scan features are implemented
    return createIntakeLog(
      volumeMl: volumeMl,
      liquidType: 'water',
      source: 'smart_scan',
    );
  }
}
