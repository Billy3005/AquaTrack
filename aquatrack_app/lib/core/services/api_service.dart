import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../utils/logger.dart';
import 'auth_service.dart';

/// Core API service for AquaTrack backend communication
///
/// @deprecated This singleton ApiService will be replaced with the new
/// dependency-injected ApiClient in core/network/api_client.dart
/// TODO: Migrate all usages to use ApiClient via Riverpod providers
class ApiService {
  static const String _tag = 'ApiService';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Dio instance
  late final Dio _dio;

  // Dependencies
  final AuthService _authService = AuthService();

  /// Initialize API service with configuration
  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.fullApiUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        sendTimeout: AppConfig.apiTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors
    _setupInterceptors();

    AppLogger.debug(
      _tag,
      'API Service initialized with base URL: ${AppConfig.fullApiUrl}',
    );
  }

  /// Setup Dio interceptors for logging and authentication
  void _setupInterceptors() {
    // Request interceptor for adding auth token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add auth token if required
          if (!_isPublicEndpoint(options.path)) {
            final token = await _authService.getAccessToken();
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          // Log request if enabled
          if (AppConfig.enableNetworkLogs) {
            AppLogger.network(options.method, options.uri.toString());
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log response if enabled
          if (AppConfig.enableNetworkLogs) {
            AppLogger.network(
              response.requestOptions.method,
              response.requestOptions.uri.toString(),
              statusCode: response.statusCode,
              duration: Duration(milliseconds: response.extra['duration'] ?? 0),
            );
          }

          handler.next(response);
        },
        onError: (error, handler) async {
          // Handle token expiration
          if (error.response?.statusCode == 401) {
            AppLogger.warning(_tag, 'Token expired, attempting refresh');

            try {
              await _authService.refreshToken();
              // Retry the original request
              final clonedRequest = await _retryRequest(error.requestOptions);
              return handler.resolve(clonedRequest);
            } catch (e) {
              await _authService.logout();
              AppLogger.error(_tag, 'Token refresh failed, user logged out');
            }
          }

          // Log error
          AppLogger.network(
            error.requestOptions.method,
            error.requestOptions.uri.toString(),
            statusCode: error.response?.statusCode,
            error: error,
          );

          handler.next(error);
        },
      ),
    );

    // Logging interceptor for development
    if (AppConfig.enableNetworkLogs && AppConfig.isDebug) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
          logPrint: (log) => AppLogger.debug('DioLogger', log.toString()),
        ),
      );
    }
  }

  /// Check if endpoint is public (doesn't require authentication)
  bool _isPublicEndpoint(String path) {
    const publicPaths = [
      '/ping',
      '/auth/login',
      '/auth/register',
      '/auth/refresh',
      // Removed /coach/chat bypass - now using authenticated endpoints
    ];

    return publicPaths.any((publicPath) => path.contains(publicPath));
  }

  /// Retry request with fresh token
  Future<Response> _retryRequest(RequestOptions requestOptions) async {
    final token = await _authService.getAccessToken();
    requestOptions.headers['Authorization'] = 'Bearer $token';
    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: requestOptions.headers,
      ),
    );
  }

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.get(endpoint, queryParameters: queryParams);

      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error(_tag, 'GET $endpoint failed', e);
      rethrow;
    }
  }

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.post(endpoint, data: data);

      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error(_tag, 'POST $endpoint failed', e);
      rethrow;
    }
  }

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.put(endpoint, data: data);

      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error(_tag, 'PUT $endpoint failed', e);
      rethrow;
    }
  }

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _dio.delete(endpoint);
      return _handleResponse<T>(response, fromJson: fromJson);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      AppLogger.error(_tag, 'DELETE $endpoint failed', e);
      rethrow;
    }
  }

  /// Handle successful Dio response
  ApiResponse<T> _handleResponse<T>(
    Response response, {
    T Function(dynamic)? fromJson,
  }) {
    final statusCode = response.statusCode ?? 0;

    // Handle success responses (2xx)
    if (statusCode >= 200 && statusCode < 300) {
      T? data;
      if (fromJson != null && response.data != null) {
        try {
          data = fromJson(response.data);
        } catch (e) {
          // Try common envelope formats
          if (response.data is Map<String, dynamic>) {
            final responseMap = response.data as Map<String, dynamic>;

            // Try wrapped in 'data' field
            if (responseMap.containsKey('data')) {
              try {
                data = fromJson(responseMap['data']);
              } catch (_) {
                // Continue to try other formats
              }
            }

            // Try wrapped in 'result' field
            if (data == null && responseMap.containsKey('result')) {
              try {
                data = fromJson(responseMap['result']);
              } catch (_) {
                // Continue to try other formats
              }
            }

            // Try wrapped in 'payload' field
            if (data == null && responseMap.containsKey('payload')) {
              try {
                data = fromJson(responseMap['payload']);
              } catch (_) {
                // Continue to try other formats
              }
            }

            // Try unwrapping if it's a list
            if (data == null && responseMap.containsKey('items')) {
              try {
                data = fromJson(responseMap['items']);
              } catch (_) {
                // Failed all attempts
              }
            }
          }

          // If still failed after trying all envelope formats
          if (data == null) {
            AppLogger.error(_tag,
                'JSON parsing failed after trying all envelope formats', e);
            throw ApiException('Failed to parse response data', statusCode);
          }
        }
      } else if (response.data != null) {
        // Return raw response payload when no parser is provided.
        data = response.data as T;
      }

      return ApiResponse<T>(
        data: data,
        statusCode: statusCode,
        message: 'Success',
      );
    }

    // This shouldn't happen with Dio as errors are thrown, but just in case
    final errorMessage = _extractErrorMessage(response.data);
    throw ApiException(errorMessage, statusCode);
  }

  /// Handle Dio errors and convert to ApiException
  ApiException _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode ?? 0;

    String message;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.sendTimeout:
        message = 'Request timeout. Please try again.';
        break;
      case DioExceptionType.receiveTimeout:
        message = 'Server response timeout. Please try again.';
        break;
      case DioExceptionType.connectionError:
        message = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        message = _extractErrorMessage(error.response?.data);
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled.';
        break;
      case DioExceptionType.unknown:
      default:
        message = 'An unexpected error occurred.';
        break;
    }

    return ApiException(message, statusCode, error);
  }

  /// Extract error message from API response
  String _extractErrorMessage(dynamic data) {
    if (data is Map<String, dynamic>) {
      // FastAPI error format
      if (data.containsKey('detail')) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          return detail.map((e) => e.toString()).join(', ');
        }
      }

      // Generic message field
      if (data.containsKey('message')) {
        return data['message']?.toString() ?? 'Unknown error';
      }
    }

    return 'An unexpected error occurred';
  }

  /// Test API connection
  Future<bool> testConnection() async {
    try {
      final response = await get('/ping');
      AppLogger.info(_tag, 'API connection test successful');
      return response.isSuccess;
    } catch (e) {
      AppLogger.error(_tag, 'API connection test failed', e);
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
    AppLogger.debug(_tag, 'API Service disposed');
  }
}

/// API Response wrapper
class ApiResponse<T> {
  final T? data;
  final int statusCode;
  final String message;
  final Map<String, dynamic>? meta;

  const ApiResponse({
    this.data,
    required this.statusCode,
    required this.message,
    this.meta,
  });

  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  String toString() =>
      'ApiResponse(statusCode: $statusCode, message: $message)';
}

/// API Exception for error handling
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final dynamic originalError;

  const ApiException(this.message, this.statusCode, [this.originalError]);

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Token expiration exception
class TokenExpiredException implements Exception {
  final String message;
  const TokenExpiredException(this.message);

  @override
  String toString() => 'TokenExpiredException: $message';
}
