/// Intake log model for water logging
class IntakeLog {
  final String id;
  final String userId;
  final int volumeMl;
  final String liquidType;
  final double hydrationFactor;
  final int effectiveVolumeMl;
  final int xpEarned;
  final int bonusXp;
  final DateTime loggedAt;
  final DateTime createdAt;
  final String? temperature;
  final String? location;
  final String? moodBefore;
  final String? moodAfter;
  final String source;
  final String? deviceInfo;
  final bool isValidated;
  final double? confidenceScore;

  const IntakeLog({
    required this.id,
    required this.userId,
    required this.volumeMl,
    required this.liquidType,
    required this.hydrationFactor,
    required this.effectiveVolumeMl,
    required this.xpEarned,
    required this.bonusXp,
    required this.loggedAt,
    required this.createdAt,
    this.temperature,
    this.location,
    this.moodBefore,
    this.moodAfter,
    required this.source,
    this.deviceInfo,
    required this.isValidated,
    this.confidenceScore,
  });

  /// Create IntakeLog from JSON
  factory IntakeLog.fromJson(Map<String, dynamic> json) {
    return IntakeLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      volumeMl: json['volume_ml'] as int,
      liquidType: json['liquid_type'] as String,
      hydrationFactor: (json['hydration_factor'] as num).toDouble(),
      effectiveVolumeMl: json['effective_volume_ml'] as int,
      xpEarned: json['xp_earned'] as int,
      bonusXp: json['bonus_xp'] as int,
      loggedAt: DateTime.parse(json['logged_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      temperature: json['temperature'] as String?,
      location: json['location'] as String?,
      moodBefore: json['mood_before'] as String?,
      moodAfter: json['mood_after'] as String?,
      source: json['source'] as String,
      deviceInfo: json['device_info'] as String?,
      isValidated: json['is_validated'] as bool,
      confidenceScore: json['confidence_score'] != null
          ? (json['confidence_score'] as num).toDouble()
          : null,
    );
  }

  /// Convert IntakeLog to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'volume_ml': volumeMl,
      'liquid_type': liquidType,
      'hydration_factor': hydrationFactor,
      'effective_volume_ml': effectiveVolumeMl,
      'xp_earned': xpEarned,
      'bonus_xp': bonusXp,
      'logged_at': loggedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'temperature': temperature,
      'location': location,
      'mood_before': moodBefore,
      'mood_after': moodAfter,
      'source': source,
      'device_info': deviceInfo,
      'is_validated': isValidated,
      'confidence_score': confidenceScore,
    };
  }

  /// Get total XP (base + bonus)
  int get totalXp => xpEarned + bonusXp;

  /// Get localized liquid type name
  String get localizedLiquidType {
    switch (liquidType) {
      case 'water':
        return 'Nước lọc';
      case 'tea':
        return 'Trà';
      case 'coffee':
        return 'Cà phê';
      case 'juice':
        return 'Nước trái cây';
      case 'sports_drink':
        return 'Nước thể thao';
      case 'other':
        return 'Khác';
      default:
        return liquidType;
    }
  }

  /// Get localized temperature
  String? get localizedTemperature {
    if (temperature == null) return null;

    switch (temperature!) {
      case 'cold':
        return 'Lạnh';
      case 'room':
        return 'Thường';
      case 'warm':
        return 'Ấm';
      case 'hot':
        return 'Nóng';
      default:
        return temperature;
    }
  }

  /// Create copy with updated fields
  IntakeLog copyWith({
    String? id,
    String? userId,
    int? volumeMl,
    String? liquidType,
    double? hydrationFactor,
    int? effectiveVolumeMl,
    int? xpEarned,
    int? bonusXp,
    DateTime? loggedAt,
    DateTime? createdAt,
    String? temperature,
    String? location,
    String? moodBefore,
    String? moodAfter,
    String? source,
    String? deviceInfo,
    bool? isValidated,
    double? confidenceScore,
  }) {
    return IntakeLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      volumeMl: volumeMl ?? this.volumeMl,
      liquidType: liquidType ?? this.liquidType,
      hydrationFactor: hydrationFactor ?? this.hydrationFactor,
      effectiveVolumeMl: effectiveVolumeMl ?? this.effectiveVolumeMl,
      xpEarned: xpEarned ?? this.xpEarned,
      bonusXp: bonusXp ?? this.bonusXp,
      loggedAt: loggedAt ?? this.loggedAt,
      createdAt: createdAt ?? this.createdAt,
      temperature: temperature ?? this.temperature,
      location: location ?? this.location,
      moodBefore: moodBefore ?? this.moodBefore,
      moodAfter: moodAfter ?? this.moodAfter,
      source: source ?? this.source,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      isValidated: isValidated ?? this.isValidated,
      confidenceScore: confidenceScore ?? this.confidenceScore,
    );
  }

  @override
  String toString() =>
      'IntakeLog(id: $id, volume: ${volumeMl}ml, type: $liquidType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntakeLog && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Intake log creation request model
class IntakeLogCreateRequest {
  final int volumeMl;
  final String liquidType;
  final String? temperature;
  final String? location;
  final String? moodBefore;
  final String source;

  const IntakeLogCreateRequest({
    required this.volumeMl,
    required this.liquidType,
    this.temperature,
    this.location,
    this.moodBefore,
    required this.source,
  });

  Map<String, dynamic> toJson() {
    return {
      'volume_ml': volumeMl,
      'liquid_type': liquidType,
      if (temperature != null) 'temperature': temperature,
      if (location != null) 'location': location,
      if (moodBefore != null) 'mood_before': moodBefore,
      'source': source,
    };
  }
}

/// Intake log update request model
class IntakeLogUpdateRequest {
  final int? volumeMl;
  final String? liquidType;
  final String? temperature;
  final String? location;
  final String? moodAfter;

  const IntakeLogUpdateRequest({
    this.volumeMl,
    this.liquidType,
    this.temperature,
    this.location,
    this.moodAfter,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (volumeMl != null) json['volume_ml'] = volumeMl;
    if (liquidType != null) json['liquid_type'] = liquidType;
    if (temperature != null) json['temperature'] = temperature;
    if (location != null) json['location'] = location;
    if (moodAfter != null) json['mood_after'] = moodAfter;

    return json;
  }
}

/// Daily summary response model
class DailySummaryResponse {
  final DateTime date;
  final int logCount;
  final int totalVolumeMl;
  final int totalEffectiveMl;
  final int totalXpEarned;

  const DailySummaryResponse({
    required this.date,
    required this.logCount,
    required this.totalVolumeMl,
    required this.totalEffectiveMl,
    required this.totalXpEarned,
  });

  factory DailySummaryResponse.fromJson(Map<String, dynamic> json) {
    return DailySummaryResponse(
      date: DateTime.parse(json['date'] as String),
      logCount: json['log_count'] as int,
      totalVolumeMl: json['total_volume_ml'] as int,
      totalEffectiveMl: json['total_effective_ml'] as int,
      totalXpEarned: json['total_xp_earned'] as int,
    );
  }
}
