import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../../../core/models/vision_result.dart';
import '../../../core/network/api_client.dart';
import '../../../core/repositories/vision_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../log_drink/providers/log_drink_provider.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/scan_controls.dart';
import '../widgets/scan_result_sheet.dart';

/// Smart Scan screen for automatic volume detection.
///
/// Backend is the single source of truth (ADR-0005): the image goes to
/// /vision/estimate-volume and the scan is persisted server-side. On detect,
/// the camera keeps a green "đã nhận diện" overlay and an inline result panel
/// slides up; "Log thức uống này" records the intake directly (no detour).
class SmartScanScreen extends ConsumerStatefulWidget {
  const SmartScanScreen({super.key});

  @override
  ConsumerState<SmartScanScreen> createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends ConsumerState<SmartScanScreen>
    with WidgetsBindingObserver {
  final VisionRepository _visionRepository = VisionRepository();

  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isLogging = false;
  String? _errorMessage;

  /// Non-null once a scan returns — switches the UI to the detected state.
  VisionResult? _result;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() => _errorMessage = 'Không tìm thấy camera');
        }
        return;
      }

      _controller = CameraController(
        _cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Lỗi khởi động camera: $e');
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() => _isScanning = true);

    try {
      HapticFeedback.mediumImpact();
      final XFile image = await _controller!.takePicture();
      await _processImage(File(image.path));
    } catch (e) {
      debugPrint('Lỗi chụp ảnh: $e');
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final result = await _visionRepository.estimateVolume(imageFile.path);
      if (!mounted) return;
      HapticFeedback.selectionClick();
      setState(() => _result = result);
    } on ApiException catch (e) {
      _showError('Không thể phân tích ảnh: ${e.message}');
    } catch (e) {
      _showError('Lỗi xử lý ảnh: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  /// Back to the live scanning state.
  void _rescan() => setState(() => _result = null);

  /// Record the user's decision (training data), then log the intake directly
  /// and close Smart Scan. [ml] is the PHYSICAL volume; the hydration
  /// coefficient is applied once inside the log step.
  Future<void> _logSelected(int ml) async {
    final result = _result;
    if (result == null) return;

    setState(() => _isLogging = true);
    HapticFeedback.mediumImpact();

    // Fire-and-forget validation: never block the log flow
    if (result.scanId != null) {
      final isCorrection = ml != result.estimatedVolumeMl;
      _visionRepository.submitValidation(
        scanId: result.scanId!,
        correctedVolumeMl: isCorrection ? ml : null,
      );
    }

    try {
      final notifier = ref.read(logDrinkNotifierProvider.notifier);
      notifier.selectDrinkType(result.liquidType);
      notifier.setAmount(ml);
      await notifier.submitLog(source: 'smart_scan');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã ghi $ml ml 💧  +20 XP'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isLogging = false);
        _showError('Lỗi ghi nước: $e');
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detected = _result != null;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            CameraPreview(_controller!)
          else if (_errorMessage != null)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      color: Colors.white, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyLarge.copyWith(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyanAccent),
              ),
            ),

          // Framing / detected overlay
          if (_isInitialized)
            ScanOverlay(detectedConfidence: _result?.confidence),

          // Shutter + close (scanning state only)
          if (_isInitialized && !detected)
            ScanControls(
              isScanning: _isScanning,
              onCapture: _takePicture,
              onClose: () => Navigator.of(context).pop(),
            ),

          // Close button stays reachable in the detected state too
          if (_isInitialized && detected)
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    onPressed: _isLogging
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),

          // Inline result panel
          if (detected)
            Align(
              alignment: Alignment.bottomCenter,
              child: ScanResultPanel(
                result: _result!,
                isLogging: _isLogging,
                onRescan: _rescan,
                onLog: _logSelected,
              ),
            ),

          // Analyzing overlay
          if (_isScanning)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.cyanAccent),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Đang phân tích...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
