import '../../../core/services/vision_service.dart';

/// Scan history record for tracking Smart Scan accuracy and usage
class ScanHistoryRecord {
  final String id;
  final DateTime timestamp;
  final String imagePath; // Path to captured image
  final VisionResult aiResult; // Original AI prediction
  final int?
      userConfirmedVolume; // Volume user actually confirmed (null if cancelled)
  final String? userFeedback; // 'accurate', 'adjusted', 'wrong'
  final double accuracyScore; // How close AI was to user's final choice

  const ScanHistoryRecord({
    required this.id,
    required this.timestamp,
    required this.imagePath,
    required this.aiResult,
    this.userConfirmedVolume,
    this.userFeedback,
    required this.accuracyScore,
  });

  /// Calculate accuracy score based on AI prediction vs user confirmation
  static double calculateAccuracy(int aiVolume, int userVolume) {
    if (aiVolume == 0) return 0.0;
    final diff = (aiVolume - userVolume).abs();
    final avgVolume = (aiVolume + userVolume) / 2;
    final errorRate = diff / avgVolume;
    return (1.0 - errorRate).clamp(0.0, 1.0);
  }

  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'imagePath': imagePath,
      'aiResult': {
        'containerClass': aiResult.containerClass,
        'fillLevelPercent': aiResult.fillLevelPercent,
        'liquidType': aiResult.liquidType,
        'confidence': aiResult.confidence,
        'estimatedVolumeMl': aiResult.estimatedVolumeMl,
        'effectiveVolumeMl': aiResult.effectiveVolumeMl,
      },
      'userConfirmedVolume': userConfirmedVolume,
      'userFeedback': userFeedback,
      'accuracyScore': accuracyScore,
    };
  }

  /// Create from map
  factory ScanHistoryRecord.fromMap(Map<String, dynamic> map) {
    final aiResultMap = map['aiResult'] as Map<String, dynamic>;
    return ScanHistoryRecord(
      id: map['id'],
      timestamp: DateTime.parse(map['timestamp']),
      imagePath: map['imagePath'],
      aiResult: VisionResult(
        containerClass: aiResultMap['containerClass'],
        fillLevelPercent: aiResultMap['fillLevelPercent'],
        liquidType: aiResultMap['liquidType'],
        confidence: aiResultMap['confidence'],
        estimatedVolumeMl: aiResultMap['estimatedVolumeMl'],
        effectiveVolumeMl: aiResultMap['effectiveVolumeMl'],
      ),
      userConfirmedVolume: map['userConfirmedVolume'],
      userFeedback: map['userFeedback'],
      accuracyScore: map['accuracyScore'],
    );
  }

  /// Copy with updates
  ScanHistoryRecord copyWith({
    String? id,
    DateTime? timestamp,
    String? imagePath,
    VisionResult? aiResult,
    int? userConfirmedVolume,
    String? userFeedback,
    double? accuracyScore,
  }) {
    return ScanHistoryRecord(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      imagePath: imagePath ?? this.imagePath,
      aiResult: aiResult ?? this.aiResult,
      userConfirmedVolume: userConfirmedVolume ?? this.userConfirmedVolume,
      userFeedback: userFeedback ?? this.userFeedback,
      accuracyScore: accuracyScore ?? this.accuracyScore,
    );
  }
}

/// Scan history statistics
class ScanHistoryStats {
  final int totalScans;
  final int confirmedScans;
  final double averageAccuracy;
  final double averageConfidence;
  final Map<String, int> containerTypeCount;
  final Map<String, int> liquidTypeCount;
  final List<ScanHistoryRecord> recentScans;

  const ScanHistoryStats({
    required this.totalScans,
    required this.confirmedScans,
    required this.averageAccuracy,
    required this.averageConfidence,
    required this.containerTypeCount,
    required this.liquidTypeCount,
    required this.recentScans,
  });

  double get confirmationRate =>
      totalScans > 0 ? confirmedScans / totalScans : 0.0;

  String get accuracyGrade {
    if (averageAccuracy >= 0.9) return 'Excellent';
    if (averageAccuracy >= 0.8) return 'Very Good';
    if (averageAccuracy >= 0.7) return 'Good';
    if (averageAccuracy >= 0.6) return 'Fair';
    return 'Needs Improvement';
  }
}
