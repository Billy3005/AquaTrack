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
import '../../log_drink/screens/log_drink_screen.dart';
import '../../log_drink/providers/log_drink_provider.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/scan_controls.dart';
import '../widgets/scan_result_sheet.dart';

/// Smart Scan screen for automatic volume detection.
///
/// Backend is the single source of truth (ADR-0005): the image goes to
/// /vision/estimate-volume, the scan is persisted server-side, and the
/// user's confirmation/correction is sent back as training data.
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
  String? _errorMessage;

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
          setState(() {
            _errorMessage = 'Không tìm thấy camera';
          });
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
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Lỗi khởi động camera: $e';
        });
      }
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    setState(() {
      _isScanning = true;
    });

    try {
      // Haptic feedback
      HapticFeedback.mediumImpact();

      final XFile image = await _controller!.takePicture();

      await _processImage(File(image.path));
    } catch (e) {
      debugPrint('Lỗi chụp ảnh: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      final result = await _visionRepository.estimateVolume(imageFile.path);

      if (!mounted) return;
      _showResultSheet(result);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể phân tích ảnh: ${e.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý ảnh: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showResultSheet(VisionResult result) {
    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ScanResultSheet(result: result),
    ).then((confirmedVolume) {
      if (confirmedVolume != null && mounted) {
        _navigateToLogDrink(result, confirmedVolume);
      }
    });
  }

  /// Record the user's decision on the backend (training data for the
  /// hybrid phase), then continue to Log Drink with the physical volume.
  void _navigateToLogDrink(VisionResult result, int confirmedVolumeMl) {
    if (result.scanId != null) {
      final isCorrection = confirmedVolumeMl != result.estimatedVolumeMl;
      // Fire-and-forget: validation must never block the log flow
      _visionRepository.submitValidation(
        scanId: result.scanId!,
        correctedVolumeMl: isCorrection ? confirmedVolumeMl : null,
      );
    }

    // Pre-set the PHYSICAL amount; Log Drink applies the hydration
    // coefficient exactly once
    ref.read(logDrinkNotifierProvider.notifier).setAmount(confirmedVolumeMl);
    ref
        .read(logDrinkNotifierProvider.notifier)
        .selectDrinkType(result.liquidType);

    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const LogDrinkScreen()))
        .then((_) {
      // Close Smart Scan screen when returning from Log Drink
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: Colors.white,
                    ),
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

          // Scanning overlay
          if (_isInitialized) const ScanOverlay(),

          // Controls
          if (_isInitialized)
            ScanControls(
              isScanning: _isScanning,
              onCapture: _takePicture,
              onClose: () => Navigator.of(context).pop(),
            ),

          // Scanning indicator
          if (_isScanning)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.cyanAccent,
                      ),
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
