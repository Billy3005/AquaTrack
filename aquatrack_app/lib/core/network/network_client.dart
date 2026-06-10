import 'package:dio/dio.dart';
import 'package:path/path.dart';

import '../utils/logger.dart';

/// Concrete implementation của NetworkClient sử dụng Dio
///
/// Class này wrap Dio và cung cấp consistent interface for HTTP operations.
/// Handles interceptors, error handling, và authentication headers.
class NetworkClient {
  static const String _tag = 'NetworkClient';

  final String baseUrl;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final bool enableLogging;

  /// Dio is built lazily on first access so the client works regardless of
  /// whether [initialize] was called explicitly (DI order-independent).
  late final Dio _dio = _buildDio();
  Future<String?> Function()? _tokenRefreshCallback;

  NetworkClient({
    required this.baseUrl,
    required this.connectTimeout,
    required this.receiveTimeout,
    this.enableLogging = false,
  });

  /// Build và configure the Dio instance.
  Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        sendTimeout: connectTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
    _setupInterceptors(dio);
    AppLogger.debug(_tag, 'NetworkClient Dio built with baseUrl: $baseUrl');
    return dio;
  }

  /// Initialize the client. Idempotent — Dio is built lazily, so this just
  /// ensures it exists. Kept for interface compatibility.
  Future<void> initialize() async {
    _dio; // touch to trigger lazy build
  }

  /// Setup Dio interceptors for logging và authentication
  void _setupInterceptors(Dio dio) {
    // Request/Response/Error interceptor
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Log request nếu enabled
          if (enableLogging) {
            AppLogger.network(options.method, options.uri.toString());
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Log successful response
          if (enableLogging) {
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
          // Handle token expiration với refresh logic
          if (error.response?.statusCode == 401 && _tokenRefreshCallback != null) {
            AppLogger.warning(_tag, 'Token expired, attempting refresh');

            try {
              final newToken = await _tokenRefreshCallback!();
              if (newToken != null) {
                // Retry original request với new token
                final clonedRequest = await _retryRequest(
                  error.requestOptions,
                  newToken,
                );
                return handler.resolve(clonedRequest);
              }
            } catch (e) {
              AppLogger.error(_tag, 'Token refresh failed', e);
            }
          }

          // Log error
          if (enableLogging) {
            AppLogger.network(
              error.requestOptions.method,
              error.requestOptions.uri.toString(),
              statusCode: error.response?.statusCode,
              error: error,
            );
          }

          handler.next(error);
        },
      ),
    );

    // Development logging interceptor
    if (enableLogging) {
      dio.interceptors.add(
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

  /// GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(_tag, 'GET $path failed', e);
      rethrow;
    }
  }

  /// POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await _dio.post(path, data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(_tag, 'POST $path failed', e);
      rethrow;
    }
  }

  /// PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(_tag, 'PUT $path failed', e);
      rethrow;
    }
  }

  /// DELETE request
  Future<Response> delete(String path) async {
    try {
      return await _dio.delete(path);
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(_tag, 'DELETE $path failed', e);
      rethrow;
    }
  }

  /// Upload file với progress tracking
  Future<Response> upload(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    ProgressCallback? onProgress,
  }) async {
    try {
      final fileName = basename(filePath);
      final formData = FormData.fromMap({
        if (data != null) ...data,
        fieldName: await MultipartFile.fromFile(
          filePath,
          filename: fileName,
        ),
      });

      return await _dio.post(
        path,
        data: formData,
        onSendProgress: onProgress,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(_tag, 'UPLOAD $path failed', e);
      rethrow;
    }
  }

  /// Download file với progress tracking
  Future<void> download(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onProgress,
  }) async {
    try {
      await _dio.download(
        path,
        savePath,
        queryParameters: queryParameters,
        onReceiveProgress: onProgress,
      );
    } on DioException {
      rethrow;
    } catch (e) {
      AppLogger.error(_tag, 'DOWNLOAD $path failed', e);
      rethrow;
    }
  }

  /// Set authentication header
  void setAuthHeader(String authHeader) {
    _dio.options.headers['Authorization'] = authHeader;
    AppLogger.debug(_tag, 'Auth header set');
  }

  /// Clear authentication header
  void clearAuthHeader() {
    _dio.options.headers.remove('Authorization');
    AppLogger.debug(_tag, 'Auth header cleared');
  }

  /// Set callback for token refresh
  void setTokenRefreshCallback(Future<String?> Function() callback) {
    _tokenRefreshCallback = callback;
  }

  /// Dispose Dio resources
  void dispose() {
    _dio.close();
    AppLogger.debug(_tag, 'NetworkClient disposed');
  }

  /// Retry request với fresh token
  Future<Response> _retryRequest(
    RequestOptions requestOptions,
    String newToken,
  ) async {
    // Update auth header trong cloned request
    requestOptions.headers['Authorization'] = 'Bearer $newToken';

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
}