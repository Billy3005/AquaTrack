import 'package:hive/hive.dart';

part 'intake_log.g.dart';

/// Single intake log entry model
@HiveType(typeId: 0)
class IntakeLog {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int volumeMl;

  @HiveField(2)
  final int effectiveVolumeMl;

  @HiveField(3)
  final String liquidType;

  @HiveField(4)
  final DateTime loggedAt;

  @HiveField(5)
  final String source; // 'quick_log', 'manual', 'smart_scan'

  @HiveField(6)
  final int xpEarned;

  const IntakeLog({
    required this.id,
    required this.volumeMl,
    required this.effectiveVolumeMl,
    required this.liquidType,
    required this.loggedAt,
    required this.source,
    required this.xpEarned,
  });

  IntakeLog copyWith({
    String? id,
    int? volumeMl,
    int? effectiveVolumeMl,
    String? liquidType,
    DateTime? loggedAt,
    String? source,
    int? xpEarned,
  }) {
    return IntakeLog(
      id: id ?? this.id,
      volumeMl: volumeMl ?? this.volumeMl,
      effectiveVolumeMl: effectiveVolumeMl ?? this.effectiveVolumeMl,
      liquidType: liquidType ?? this.liquidType,
      loggedAt: loggedAt ?? this.loggedAt,
      source: source ?? this.source,
      xpEarned: xpEarned ?? this.xpEarned,
    );
  }

  /// Create intake log from quick log action
  factory IntakeLog.fromQuickLog({
    required int volumeMl,
    required String liquidType,
    required double hydrationCoeff,
  }) {
    return IntakeLog(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      volumeMl: volumeMl,
      effectiveVolumeMl: (volumeMl * hydrationCoeff).round(),
      liquidType: liquidType,
      loggedAt: DateTime.now(),
      source: 'quick_log',
      xpEarned: 20, // Matches backend: 20 XP flat per log
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'volumeMl': volumeMl,
      'effectiveVolumeMl': effectiveVolumeMl,
      'liquidType': liquidType,
      'loggedAt': loggedAt.toIso8601String(),
      'source': source,
      'xpEarned': xpEarned,
    };
  }

  factory IntakeLog.fromMap(Map<String, dynamic> map) {
    return IntakeLog(
      id: map['id'] as String,
      volumeMl: map['volumeMl'] as int,
      effectiveVolumeMl: map['effectiveVolumeMl'] as int,
      liquidType: map['liquidType'] as String,
      loggedAt: DateTime.parse(map['loggedAt'] as String),
      source: map['source'] as String,
      xpEarned: map['xpEarned'] as int,
    );
  }
}
