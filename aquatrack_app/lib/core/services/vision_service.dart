import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

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

  static const String _modelPath = 'assets/models/aquatrack_v1.tflite';
  static const int _inputSize = 224;

  Interpreter? _interpreter;
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

  /// Initialize TFLite model
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load model from assets
      _interpreter = await Interpreter.fromAsset(_modelPath);
      _isInitialized = true;
      debugPrint('✅ VisionService initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize VisionService: $e');
      // For development - create mock service if model doesn't exist
      _isInitialized = true;
      debugPrint('⚠️ Running in mock mode without TFLite model');
    }
  }

  /// Process image and estimate volume
  Future<VisionResult> estimateVolume(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }

    // If no actual model, return mock result
    if (_interpreter == null) {
      return _createMockResult();
    }

    try {
      // Preprocess image
      final inputData = await _preprocessImage(imageFile);

      // Run inference
      final outputs = _runInference(inputData);

      // Parse results
      return _parseResults(outputs);
    } catch (e) {
      debugPrint('❌ Vision inference error: $e');
      return _createMockResult();
    }
  }

  /// Preprocess image to model input format
  Future<Float32List> _preprocessImage(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Failed to decode image');

    // Resize to model input size
    final resized =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    // Convert to Float32List and normalize [0, 1]
    final inputData = Float32List(_inputSize * _inputSize * 3);
    int index = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final pixel = resized.getPixel(x, y);
        inputData[index++] = pixel.r / 255.0; // R
        inputData[index++] = pixel.g / 255.0; // G
        inputData[index++] = pixel.b / 255.0; // B
      }
    }

    return inputData;
  }

  /// Run TFLite inference
  Map<String, Float32List> _runInference(Float32List inputData) {
    // Prepare input tensor
    final input = inputData.reshape([1, _inputSize, _inputSize, 3]);

    // Prepare output tensors
    final containerOutput = Float32List(_containerClasses.length)
        .reshape([1, _containerClasses.length]);
    final fillLevelOutput = Float32List(1).reshape([1, 1]);
    final liquidTypeOutput =
        Float32List(_liquidTypes.length).reshape([1, _liquidTypes.length]);

    // Run inference
    _interpreter!.runForMultipleInputs(
      [input],
      {
        0: containerOutput, // Container classification head
        1: fillLevelOutput, // Fill level regression head
        2: liquidTypeOutput, // Liquid type classification head
      },
    );

    return {
      'container': Float32List.fromList(containerOutput[0]),
      'fillLevel': Float32List.fromList(fillLevelOutput[0]),
      'liquidType': Float32List.fromList(liquidTypeOutput[0]),
    };
  }

  /// Parse inference results
  VisionResult _parseResults(Map<String, Float32List> outputs) {
    // Parse container classification (softmax)
    final containerProbs = outputs['container']!;
    int containerIndex = 0;
    double maxProb = containerProbs[0];
    for (int i = 1; i < containerProbs.length; i++) {
      if (containerProbs[i] > maxProb) {
        maxProb = containerProbs[i];
        containerIndex = i;
      }
    }
    final containerClass = _containerClasses[containerIndex];
    final containerConfidence = maxProb;

    // Parse fill level (sigmoid)
    final fillLevel = outputs['fillLevel']![0].clamp(0.0, 1.0);

    // Parse liquid type (softmax)
    final liquidProbs = outputs['liquidType']!;
    int liquidIndex = 0;
    double maxLiquidProb = liquidProbs[0];
    for (int i = 1; i < liquidProbs.length; i++) {
      if (liquidProbs[i] > maxLiquidProb) {
        maxLiquidProb = liquidProbs[i];
        liquidIndex = i;
      }
    }
    final liquidType = _liquidTypes[liquidIndex];

    // Calculate volumes
    final containerSize = _containerSizes[containerClass] ?? 300;
    final estimatedVolume = (containerSize * fillLevel).round();
    final hydrationCoeff = _hydrationCoeff[liquidType] ?? 1.0;
    final effectiveVolume = (estimatedVolume * hydrationCoeff).round();

    // Overall confidence (geometric mean)
    final confidence = (containerConfidence * maxLiquidProb).clamp(0.0, 1.0);

    return VisionResult(
      containerClass: containerClass,
      fillLevelPercent: fillLevel,
      liquidType: liquidType,
      confidence: confidence,
      estimatedVolumeMl: estimatedVolume,
      effectiveVolumeMl: effectiveVolume,
    );
  }

  /// Create mock result for development
  VisionResult _createMockResult() {
    // Mock realistic result for development
    return const VisionResult(
      containerClass: 'glass_large',
      fillLevelPercent: 0.75,
      liquidType: 'water',
      confidence: 0.85,
      estimatedVolumeMl: 263, // 350ml * 0.75
      effectiveVolumeMl: 263, // water coefficient = 1.0
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
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
