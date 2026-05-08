import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Global error handler for production app
class AppErrorHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        // In debug mode, show detailed error
        FlutterError.presentError(details);
      } else {
        // In production, log error and continue
        _logError(details.exception, details.stack, details.context);
      }
    };

    // Handle errors outside Flutter framework
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kDebugMode) {
        print('Platform Error: $error\nStack: $stack');
      } else {
        _logError(error, stack, 'Platform Error');
      }
      return true; // Return true to prevent crash
    };
  }

  static void _logError(Object error, StackTrace? stack, Object? context) {
    // TODO: Integrate with crash reporting service (Firebase Crashlytics, Sentry)
    debugPrint('ERROR: $error');
    debugPrint('STACK: $stack');
    debugPrint('CONTEXT: $context');

    // For now, just log locally
    // In production, send to crash reporting service
  }

  /// Handle and log errors in providers/services
  static void handleProviderError(
    String provider,
    Object error,
    StackTrace? stack,
  ) {
    _logError(error, stack, 'Provider: $provider');
  }

  /// Handle and log API errors
  static void handleApiError(String endpoint, Object error, StackTrace? stack) {
    _logError(error, stack, 'API Endpoint: $endpoint');
  }

  /// Show user-friendly error dialog
  static void showUserError(
    BuildContext context,
    String message, {
    String? action,
  }) {
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đã có lỗi xảy ra'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
          if (action != null)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Implement retry logic based on action
              },
              child: Text(action),
            ),
        ],
      ),
    );
  }
}

/// Error widget cho production builds
class ProductionErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const ProductionErrorWidget(this.errorDetails, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ứng dụng gặp lỗi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng khởi động lại ứng dụng',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement app restart logic
              },
              child: const Text('Khởi động lại'),
            ),
          ],
        ),
      ),
    );
  }
}
