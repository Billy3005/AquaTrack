import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../utils/logger.dart';
import 'app_exceptions.dart';

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
    AppLogger.error('AppErrorHandler', 'Global error: $context', error);
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

/// Centralized error handling service
///
/// Converts các types of errors thành user-friendly messages và
/// appropriate AppException types. Handles logging và reporting.
class ErrorHandler {
  static const String _tag = 'ErrorHandler';

  /// Convert any error thành appropriate AppException
  static AppException handleError(dynamic error, [StackTrace? stackTrace]) {
    AppLogger.error(_tag, 'Handling error: ${error.runtimeType}', error);

    if (error is AppException) {
      return error;
    }

    if (error is DioException) {
      return _handleDioError(error);
    }

    if (error is SocketException) {
      return NetworkException(
        'Không có kết nối internet. Vui lòng kiểm tra kết nối mạng.',
        code: 'NETWORK_ERROR',
        originalError: error,
      );
    }

    if (error is FormatException) {
      return ValidationException(
        'Dữ liệu không hợp lệ. Vui lòng thử lại.',
        code: 'FORMAT_ERROR',
        originalError: error,
      );
    }

    if (error is FileSystemException) {
      return FileException(
        'Lỗi truy cập file: ${error.message}',
        filePath: error.path,
        code: 'FILE_ERROR',
        originalError: error,
      );
    }

    // Default fallback
    return UnknownException(
      'Có lỗi không mong muốn xảy ra. Vui lòng thử lại.',
      code: 'UNKNOWN_ERROR',
      originalError: error,
    );
  }

  /// Handle Dio-specific errors
  static NetworkException _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    String message;
    String code;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Kết nối bị timeout. Vui lòng kiểm tra mạng và thử lại.';
        code = 'CONNECTION_TIMEOUT';
        break;

      case DioExceptionType.sendTimeout:
        message = 'Gửi dữ liệu bị timeout. Vui lòng thử lại.';
        code = 'SEND_TIMEOUT';
        break;

      case DioExceptionType.receiveTimeout:
        message = 'Nhận dữ liệu bị timeout. Vui lòng thử lại.';
        code = 'RECEIVE_TIMEOUT';
        break;

      case DioExceptionType.connectionError:
        message = 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.';
        code = 'CONNECTION_ERROR';
        break;

      case DioExceptionType.badResponse:
        final exception = _handleBadResponseError(error);
        return exception is NetworkException ? exception : NetworkException(
          exception.message,
          statusCode: error.response?.statusCode,
          code: exception.code,
          originalError: error,
        );

      case DioExceptionType.cancel:
        message = 'Yêu cầu đã bị hủy.';
        code = 'REQUEST_CANCELLED';
        break;

      case DioExceptionType.unknown:
      default:
        message = 'Lỗi mạng không xác định. Vui lòng thử lại.';
        code = 'UNKNOWN_NETWORK_ERROR';
        break;
    }

    return NetworkException(
      message,
      statusCode: statusCode,
      code: code,
      originalError: error,
    );
  }

  /// Handle bad HTTP response errors
  static AppException _handleBadResponseError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;
    final responseData = error.response?.data;

    String message;
    String code;

    switch (statusCode) {
      case 400:
        message = _extractErrorMessage(responseData) ?? 'Yêu cầu không hợp lệ.';
        code = 'BAD_REQUEST';
        break;

      case 401:
        message = 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
        code = 'UNAUTHORIZED';
        return AuthException(message, code: code, originalError: error);

      case 403:
        message = 'Bạn không có quyền thực hiện thao tác này.';
        code = 'FORBIDDEN';
        return AuthException(message, code: code, originalError: error);

      case 404:
        message = 'Không tìm thấy dữ liệu yêu cầu.';
        code = 'NOT_FOUND';
        break;

      case 422:
        message = _extractErrorMessage(responseData) ?? 'Dữ liệu không hợp lệ.';
        code = 'VALIDATION_ERROR';
        final fieldErrors = _extractFieldErrors(responseData);
        return ValidationException(
          message,
          fieldErrors: fieldErrors,
          code: code,
          originalError: error,
        );

      case 429:
        message = 'Quá nhiều yêu cầu. Vui lòng thử lại sau.';
        code = 'RATE_LIMIT_EXCEEDED';
        break;

      case 500:
        message = 'Lỗi máy chủ. Vui lòng thử lại sau.';
        code = 'INTERNAL_SERVER_ERROR';
        break;

      case 502:
        message = 'Máy chủ không phản hồi. Vui lòng thử lại sau.';
        code = 'BAD_GATEWAY';
        break;

      case 503:
        message = 'Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau.';
        code = 'SERVICE_UNAVAILABLE';
        break;

      default:
        message = _extractErrorMessage(responseData) ?? 'Lỗi máy chủ ($statusCode).';
        code = 'HTTP_ERROR_$statusCode';
        break;
    }

    return NetworkException(
      message,
      statusCode: statusCode,
      code: code,
      originalError: error,
    );
  }

  /// Extract error message từ API response
  static String? _extractErrorMessage(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // FastAPI error format
      if (responseData.containsKey('detail')) {
        final detail = responseData['detail'];
        if (detail is String) {
          return detail;
        }
        if (detail is List && detail.isNotEmpty) {
          return detail.map((e) => e.toString()).join(', ');
        }
      }

      // Generic message fields
      for (final key in ['message', 'error', 'msg']) {
        if (responseData.containsKey(key)) {
          final value = responseData[key];
          if (value is String && value.isNotEmpty) {
            return value;
          }
        }
      }
    }

    return null;
  }

  /// Extract field validation errors từ API response
  static Map<String, List<String>>? _extractFieldErrors(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // FastAPI validation error format
      if (responseData.containsKey('detail')) {
        final detail = responseData['detail'];
        if (detail is List) {
          final fieldErrors = <String, List<String>>{};

          for (final error in detail) {
            if (error is Map<String, dynamic>) {
              final loc = error['loc'];
              final msg = error['msg'];

              if (loc is List && loc.isNotEmpty && msg is String) {
                final field = loc.last.toString();
                fieldErrors.putIfAbsent(field, () => []).add(msg);
              }
            }
          }

          return fieldErrors.isNotEmpty ? fieldErrors : null;
        }
      }

      // Generic field errors format
      if (responseData.containsKey('errors')) {
        final errors = responseData['errors'];
        if (errors is Map<String, dynamic>) {
          final fieldErrors = <String, List<String>>{};

          errors.forEach((field, fieldError) {
            if (fieldError is String) {
              fieldErrors[field] = [fieldError];
            } else if (fieldError is List) {
              fieldErrors[field] = fieldError.map((e) => e.toString()).toList();
            }
          });

          return fieldErrors.isNotEmpty ? fieldErrors : null;
        }
      }
    }

    return null;
  }

  /// Get user-friendly error message từ AppException
  static String getDisplayMessage(AppException exception) {
    switch (exception.runtimeType) {
      case AuthException:
        return exception.message;
      case ValidationException:
        final validationError = exception as ValidationException;
        if (validationError.fieldErrors != null) {
          return 'Dữ liệu không hợp lệ:\n${_formatFieldErrors(validationError.fieldErrors!)}';
        }
        return exception.message;
      case NetworkException:
        return exception.message;
      case StorageException:
        return 'Lỗi lưu trữ dữ liệu. Vui lòng thử lại.';
      case PermissionException:
        return exception.message;
      case FileException:
        return exception.message;
      default:
        return 'Có lỗi xảy ra. Vui lòng thử lại.';
    }
  }

  /// Format field errors for display
  static String _formatFieldErrors(Map<String, List<String>> fieldErrors) {
    return fieldErrors.entries
        .map((entry) => '• ${entry.key}: ${entry.value.join(', ')}')
        .join('\n');
  }

  /// Check if error requires authentication
  static bool isAuthError(AppException exception) {
    return exception is AuthException ||
        (exception is NetworkException &&
         (exception.statusCode == 401 || exception.statusCode == 403));
  }

  /// Check if error is retryable
  static bool isRetryable(AppException exception) {
    if (exception is NetworkException) {
      final statusCode = exception.statusCode;
      return statusCode == null || // Connection errors
             statusCode >= 500 || // Server errors
             statusCode == 429; // Rate limit
    }
    return exception is StorageException || exception is UnknownException;
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
