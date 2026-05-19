import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';

/// Result from vision inference
class VisionResult {
  final String containerClass;
  final double fillLevelPercent;
  final String liquidType;
  final double confidence;
  final int estimatedVolumeMl;
  final int effectiveVolumeMl;

  const VisionResult({
    required this.containerClass,
    required this.fillLevelPercent,
    required this.liquidType,
    required this.confidence,
    required this.estimatedVolumeMl,
    required this.effectiveVolumeMl,
  });

  @override
  String toString() {
    return 'VisionResult('
        'container: $containerClass, '
        'fill: ${(fillLevelPercent * 100).toStringAsFixed(1)}%, '
        'liquid: $liquidType, '
        'confidence: ${(confidence * 100).toStringAsFixed(1)}%, '
        'volume: ${estimatedVolumeMl}ml → ${effectiveVolumeMl}ml'
        ')';
  }
}

/// Service for ML-based volume estimation from images
class VisionService {
  static final VisionService _instance = VisionService._internal();
  factory VisionService() => _instance;
  VisionService._internal();

  bool _isInitialized = false;

  /// Container size mapping (ml)
  static const Map<String, int> _containerSizes = {
    'glass_small': 200,
    'glass_large': 350,
    'cup_plastic': 500,
    'bottle_500': 500,
    'bottle_750': 750,
    'bottle_1000': 1000,
    'bottle_1500': 1500,
    'mug': 300,
    'can_330': 330,
    'other': 300,
  };

  /// Hydration coefficients by liquid type
  static const Map<String, double> _hydrationCoeff = {
    'water': 1.00,
    'tea': 0.90,
    'coffee': 0.80,
    'juice': 0.85,
    'smoothie': 0.90,
  };

  /// Container class labels
  static const List<String> _containerClasses = [
    'glass_small',
    'glass_large',
    'cup_plastic',
    'bottle_500',
    'bottle_750',
    'bottle_1000',
    'bottle_1500',
    'mug',
    'can_330',
    'other',
  ];

  /// Liquid type labels
  static const List<String> _liquidTypes = [
    'water',
    'tea',
    'coffee',
    'juice',
    'smoothie',
  ];

  /// Initialize service (mock mode for desktop/development)
  Future<void> initialize() async {
    if (_isInitialized) return;

    _isInitialized = true;
    debugPrint('✅ VisionService initialized (Mock Mode)');
  }

  /// Process image and estimate volume (mock implementation)
  Future<VisionResult> estimateVolume(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    // Simulate processing delay
    await Future.delayed(const Duration(milliseconds: 1500));

    debugPrint('🔍 Processing image: ${imageFile.path}');

    // Return mock result with some randomization for realism
    return _createMockResult();
  }

  /// Create mock result for development/desktop
  VisionResult _createMockResult() {
    final random = math.Random();

    // Randomize container type
    final containerClass =
        _containerClasses[random.nextInt(_containerClasses.length)];

    // Randomize fill level (60% - 95%)
    final fillLevel = 0.6 + (random.nextDouble() * 0.35);

    // Randomize liquid type
    final liquidType = _liquidTypes[random.nextInt(_liquidTypes.length)];

    // Randomize confidence (70% - 95%)
    final confidence = 0.7 + (random.nextDouble() * 0.25);

    // Calculate volumes
    final containerSize = _containerSizes[containerClass] ?? 300;
    final estimatedVolume = (containerSize * fillLevel).round();
    final hydrationCoeff = _hydrationCoeff[liquidType] ?? 1.0;
    final effectiveVolume = (estimatedVolume * hydrationCoeff).round();

    debugPrint(
      '🧠 Mock AI Result: $containerClass, ${(fillLevel * 100).toStringAsFixed(1)}% full, $liquidType, ${(confidence * 100).toStringAsFixed(1)}% confidence',
    );

    return VisionResult(
      containerClass: containerClass,
      fillLevelPercent: fillLevel,
      liquidType: liquidType,
      confidence: confidence,
      estimatedVolumeMl: estimatedVolume,
      effectiveVolumeMl: effectiveVolume,
    );
  }

  /// Get confidence category for UI
  String getConfidenceCategory(double confidence) {
    if (confidence >= 0.80) return 'high';
    if (confidence >= 0.60) return 'medium';
    return 'low';
  }

  /// Dispose resources
  void dispose() {
    _isInitialized = false;
  }
}
