import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/scan_history_model.dart';
import '../../../core/services/vision_service.dart';

part 'scan_history_provider.g.dart';

/// Scan history provider for tracking Smart Scan usage and accuracy
@riverpod
class ScanHistoryNotifier extends _$ScanHistoryNotifier {
  static const String _storageKey = 'smart_scan_history';
  static const int _maxStoredRecords = 100; // Limit storage size

  @override
  Future<List<ScanHistoryRecord>> build() async {
    return await _loadHistory();
  }

  /// Load scan history from SharedPreferences
  Future<List<ScanHistoryRecord>> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString == null) return [];

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => ScanHistoryRecord.fromMap(json))
          .toList()
          .reversed // Most recent first
          .toList();
    } catch (e) {
      // If loading fails, return empty list
      return [];
    }
  }

  /// Save scan history to SharedPreferences
  Future<void> _saveHistory(List<ScanHistoryRecord> records) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Limit stored records to prevent excessive storage usage
      final limitedRecords = records.take(_maxStoredRecords).toList();

      final jsonList = limitedRecords.map((record) => record.toMap()).toList();
      final jsonString = jsonEncode(jsonList);

      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      // Silently fail - scan history is not critical
    }
  }

  /// Add new scan record
  Future<void> addScanRecord({
    required String imagePath,
    required VisionResult aiResult,
    int? userConfirmedVolume,
    String? userFeedback,
  }) async {
    final currentHistory = await future;

    // Calculate accuracy if user confirmed a volume
    double accuracyScore = 0.0;
    if (userConfirmedVolume != null) {
      accuracyScore = ScanHistoryRecord.calculateAccuracy(
        aiResult.estimatedVolumeMl,
        userConfirmedVolume,
      );
    }

    final newRecord = ScanHistoryRecord(
      id: const Uuid().v4(),
      timestamp: DateTime.now(),
      imagePath: imagePath,
      aiResult: aiResult,
      userConfirmedVolume: userConfirmedVolume,
      userFeedback: userFeedback,
      accuracyScore: accuracyScore,
    );

    final updatedHistory = [newRecord, ...currentHistory];
    await _saveHistory(updatedHistory);

    // Update state
    state = AsyncData(updatedHistory);
  }

  /// Update scan record with user confirmation
  Future<void> updateScanRecord({
    required String recordId,
    int? userConfirmedVolume,
    String? userFeedback,
  }) async {
    final currentHistory = await future;

    final updatedHistory = currentHistory.map((record) {
      if (record.id == recordId) {
        double accuracyScore = record.accuracyScore;
        if (userConfirmedVolume != null) {
          accuracyScore = ScanHistoryRecord.calculateAccuracy(
            record.aiResult.estimatedVolumeMl,
            userConfirmedVolume,
          );
        }

        return record.copyWith(
          userConfirmedVolume: userConfirmedVolume,
          userFeedback: userFeedback,
          accuracyScore: accuracyScore,
        );
      }
      return record;
    }).toList();

    await _saveHistory(updatedHistory);
    state = AsyncData(updatedHistory);
  }

  /// Clear all scan history
  Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    state = const AsyncData([]);
  }

  /// Get scan history statistics
  ScanHistoryStats getStats(List<ScanHistoryRecord> records) {
    if (records.isEmpty) {
      return const ScanHistoryStats(
        totalScans: 0,
        confirmedScans: 0,
        averageAccuracy: 0.0,
        averageConfidence: 0.0,
        containerTypeCount: {},
        liquidTypeCount: {},
        recentScans: [],
      );
    }

    final confirmedRecords =
        records.where((r) => r.userConfirmedVolume != null).toList();

    final averageAccuracy = confirmedRecords.isEmpty
        ? 0.0
        : confirmedRecords.map((r) => r.accuracyScore).reduce((a, b) => a + b) /
            confirmedRecords.length;

    final averageConfidence =
        records.map((r) => r.aiResult.confidence).reduce((a, b) => a + b) /
            records.length;

    // Container type distribution
    final containerCount = <String, int>{};
    for (final record in records) {
      final type = record.aiResult.containerClass;
      containerCount[type] = (containerCount[type] ?? 0) + 1;
    }

    // Liquid type distribution
    final liquidCount = <String, int>{};
    for (final record in records) {
      final type = record.aiResult.liquidType;
      liquidCount[type] = (liquidCount[type] ?? 0) + 1;
    }

    return ScanHistoryStats(
      totalScans: records.length,
      confirmedScans: confirmedRecords.length,
      averageAccuracy: averageAccuracy,
      averageConfidence: averageConfidence,
      containerTypeCount: containerCount,
      liquidTypeCount: liquidCount,
      recentScans: records.take(10).toList(),
    );
  }
}

/// Provider for scan history statistics
@riverpod
ScanHistoryStats scanHistoryStats(Ref ref) {
  final historyAsync = ref.watch(scanHistoryNotifierProvider);

  return historyAsync.when(
    data: (records) =>
        ref.read(scanHistoryNotifierProvider.notifier).getStats(records),
    loading: () => const ScanHistoryStats(
      totalScans: 0,
      confirmedScans: 0,
      averageAccuracy: 0.0,
      averageConfidence: 0.0,
      containerTypeCount: {},
      liquidTypeCount: {},
      recentScans: [],
    ),
    error: (_, __) => const ScanHistoryStats(
      totalScans: 0,
      confirmedScans: 0,
      averageAccuracy: 0.0,
      averageConfidence: 0.0,
      containerTypeCount: {},
      liquidTypeCount: {},
      recentScans: [],
    ),
  );
}
