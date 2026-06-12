/// Result from backend vision estimation (/vision/estimate-volume)
///
/// Carries the physical volume only (ADR-0005). The hydration coefficient
/// is applied exactly once at the log step — never here.
class VisionResult {
  /// Display-only container description, e.g. "Chai nhựa 650ml"
  final String containerLabel;

  /// Estimated full capacity of the container (continuous, ml)
  final int containerCapacityMl;

  /// Fill level as decimal (0.0 - 1.0)
  final double fillLevelPercent;

  /// Detected liquid type (matches AppConstants.hydrationCoeff keys)
  final String liquidType;

  /// AI confidence score (0.0 - 1.0)
  final double confidence;

  /// Physical volume: capacity x fill level
  final int estimatedVolumeMl;

  /// Backend scan history ID (null when not saved, e.g. fallback results)
  final String? scanId;

  final int? processingTimeMs;

  const VisionResult({
    required this.containerLabel,
    required this.containerCapacityMl,
    required this.fillLevelPercent,
    required this.liquidType,
    required this.confidence,
    required this.estimatedVolumeMl,
    this.scanId,
    this.processingTimeMs,
  });

  /// Threshold above which the result is auto-filled as the primary action
  static const double autoFillConfidence = 0.85;

  /// Whether confidence is high enough to present confirm as primary CTA
  bool get isHighConfidence => confidence >= autoFillConfidence;

  factory VisionResult.fromJson(Map<String, dynamic> json) {
    return VisionResult(
      containerLabel: json['container_label'] as String,
      containerCapacityMl: (json['container_capacity_ml'] as num).toInt(),
      fillLevelPercent: (json['fill_level_percent'] as num).toDouble(),
      liquidType: json['liquid_type'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      estimatedVolumeMl: (json['estimated_volume_ml'] as num).toInt(),
      scanId: json['scan_id'] as String?,
      processingTimeMs: (json['processing_time_ms'] as num?)?.toInt(),
    );
  }

  @override
  String toString() {
    return 'VisionResult('
        'container: $containerLabel (${containerCapacityMl}ml), '
        'fill: ${(fillLevelPercent * 100).toStringAsFixed(1)}%, '
        'liquid: $liquidType, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'volume: ${estimatedVolumeMl}ml'
        ')';
  }
}
