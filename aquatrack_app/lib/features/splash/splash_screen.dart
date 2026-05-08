import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/services/app_service.dart';
import '../../core/utils/logger.dart';

/// Splash screen with app initialization and authentication check
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _startApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _startApp() async {
    try {
      // Start animation
      _animationController.forward();

      // Wait for animation and initialization
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 2500)),
        _initializeApp(),
      ]);

      // Check authentication and navigate
      await _checkAuthenticationAndNavigate();
    } catch (e) {
      AppLogger.error('Splash', 'App startup failed', e);
      _showErrorAndRetry();
    }
  }

  Future<void> _initializeApp() async {
    try {
      // Check if app service is initialized
      if (!AppService().isInitialized) {
        await AppService().initialize();
      }
      AppLogger.info('Splash', 'App services initialized successfully');
    } catch (e) {
      AppLogger.error('Splash', 'App service initialization failed', e);
      rethrow;
    }
  }

  Future<void> _checkAuthenticationAndNavigate() async {
    try {
      // Check authentication status
      final isAuthenticated = await AppService().isUserAuthenticated();
      AppLogger.info('Splash', 'User authenticated: $isAuthenticated');

      if (!mounted) return;

      if (isAuthenticated) {
        // Navigate to main app
        context.go('/');
      } else {
        // Navigate to login
        context.go('/login');
      }
    } catch (e) {
      AppLogger.error('Splash', 'Authentication check failed', e);
      // For now, go to main app anyway for development
      if (mounted) {
        context.go('/');
      }
    }
  }

  void _showErrorAndRetry() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Khởi động thất bại'),
        content: const Text(
          'Có lỗi xảy ra khi khởi động ứng dụng. Vui lòng thử lại.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startApp(); // Retry
            },
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo (water drop)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: AppColors.primaryGradient,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.overlay,
                              blurRadius: 20,
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.water_drop,
                          size: 60,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // App name
                      Text(
                        'AquaTrack',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Chụp ảnh ly nước → AI đếm ml → Sống khoẻ hơn mỗi ngày',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 64),

                      // Loading indicator
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(
                          color: AppColors.cyanAccent,
                          strokeWidth: 2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Loading text
                      Text(
                        'Đang khởi động...',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
