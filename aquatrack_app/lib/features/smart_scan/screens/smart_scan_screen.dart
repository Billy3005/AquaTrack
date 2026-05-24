import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/services/vision_service.dart';
import '../../log_drink/screens/log_drink_screen.dart';
import '../../log_drink/providers/log_drink_provider.dart';
import '../providers/scan_history_provider.dart';
import '../widgets/scan_overlay.dart';
import '../widgets/scan_controls.dart';
import '../widgets/scan_result_sheet.dart';

/// Smart Scan screen for automatic volume detection
class SmartScanScreen extends ConsumerStatefulWidget {
  const SmartScanScreen({super.key});

  @override
  ConsumerState<SmartScanScreen> createState() => _SmartScanScreenState();
}

class _SmartScanScreenState extends ConsumerState<SmartScanScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isInitialized = false;
  bool _isScanning = false;
  String? _errorMessage;
  String? _currentScanId; // Track current scan for history

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

      // TODO: Process image with VisionService
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
      // Process image with VisionService
      final visionService = VisionService();
      final result = await visionService.estimateVolume(imageFile);

      debugPrint('Vision result: $result');

      // Record scan in history
      final scanHistoryNotifier = ref.read(
        scanHistoryNotifierProvider.notifier,
      );
      await scanHistoryNotifier.addScanRecord(
        imagePath: imageFile.path,
        aiResult: result,
      );

      // Get the most recent scan ID for tracking user confirmation
      final historyState = ref.read(scanHistoryNotifierProvider);
      historyState.whenData((records) {
        if (records.isNotEmpty) {
          _currentScanId = records.first.id;
        }
      });

      // Show result bottom sheet
      _showResultSheet(result);
    } catch (e) {
      debugPrint('Error processing image: $e');
      // Show error message
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
        // Navigate to Log Drink screen with pre-filled volume
        _navigateToLogDrink(confirmedVolume, result.liquidType);
      }
    });
  }

  /// Navigate to Log Drink screen with pre-filled volume and liquid type
  void _navigateToLogDrink(int volumeMl, String liquidType) async {
    // Record user confirmation in scan history
    if (_currentScanId != null) {
      final scanHistoryNotifier = ref.read(
        scanHistoryNotifierProvider.notifier,
      );
      await scanHistoryNotifier.updateScanRecord(
        recordId: _currentScanId!,
        userConfirmedVolume: volumeMl,
        userFeedback: 'confirmed',
      );
    }

    if (!mounted) return;

    // Pre-set the amount and liquid type in the provider
    ref.read(logDrinkNotifierProvider.notifier).setAmount(volumeMl);
    ref.read(logDrinkNotifierProvider.notifier).selectDrinkType(liquidType);

    // Navigate to Log Drink screen
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
