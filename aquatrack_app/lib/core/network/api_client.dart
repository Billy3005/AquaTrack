import 'package:dio/dio.dart';
import 'network_client.dart' as network;

/// Abstract interface for API communication
///
/// This interface defines the contract for making HTTP requests to the backend.
/// It abstracts away the underlying HTTP client implementation (Dio) and provides
/// a clean interface that repositories can depend on.
abstract class ApiClient {
  /// Initialize the API client with configuration
  Future<void> initialize();

  /// Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  });

  /// Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  });

  /// Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  });

  /// Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  });

  /// Upload file (for images, documents, etc.)
  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    ProgressCallback? onProgress,
  });

  /// Download file
  Future<void> download(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParams,
    ProgressCallback? onProgress,
  });

  /// Test API connection
  Future<bool> testConnection();

  /// Set authentication token
  void setAuthToken(String? token);

  /// Clear authentication token
  void clearAuthToken();

  /// Dispose resources
  void dispose();
}

/// Concrete implementation of ApiClient using Dio
class ApiClientImpl implements ApiClient {
  final network.NetworkClient _networkClient;
  final TokenStorage _tokenStorage;

  // Single-flight guard: concurrent 401s share one refresh instead of each
  // firing /auth/refresh.
  Future<String?>? _refreshInFlight;

  ApiClientImpl({
    required network.NetworkClient networkClient,
    required TokenStorage tokenStorage,
  })  : _networkClient = networkClient,
        _tokenStorage = tokenStorage {
    // Auto-inject the access token per request from storage so this client is
    // authenticated even if setAuthToken/initialize were never called, and wire
    // 401 refresh here (not only in initialize) so it works even when
    // initialize() is skipped.
    _networkClient.setAuthTokenProvider(_tokenStorage.getAccessToken);
    _networkClient.setTokenRefreshCallback(_handleTokenRefresh);
  }

  @override
  Future<void> initialize() async {
    await _networkClient.initialize();
    // No token pre-loading: the constructor-wired per-request injector reads
    // the current token from storage on every request, so there is no sticky
    // Dio header to go stale. The refresh callback is also wired in the ctor.
  }

  @override
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _networkClient.get(
        endpoint,
        queryParameters: queryParams,
      );
      return _handleResponse<T>(response, fromJson: fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _networkClient.post(endpoint, data: data);
      return _handleResponse<T>(response, fromJson: fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    dynamic data,
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _networkClient.put(endpoint, data: data);
      return _handleResponse<T>(response, fromJson: fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    T Function(dynamic)? fromJson,
  }) async {
    try {
      final response = await _networkClient.delete(endpoint);
      return _handleResponse<T>(response, fromJson: fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<ApiResponse<T>> upload<T>(
    String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    T Function(dynamic)? fromJson,
    ProgressCallback? onProgress,
  }) async {
    try {
      final response = await _networkClient.upload(
        endpoint,
        filePath: filePath,
        fieldName: fieldName,
        data: data,
        onProgress: onProgress,
      );
      return _handleResponse<T>(response, fromJson: fromJson);
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<void> download(
    String endpoint,
    String savePath, {
    Map<String, dynamic>? queryParams,
    ProgressCallback? onProgress,
  }) async {
    try {
      await _networkClient.download(
        endpoint,
        savePath,
        queryParameters: queryParams,
        onProgress: onProgress,
      );
    } catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<bool> testConnection() async {
    try {
      final response = await get('/ping');
      return response.isSuccess;
    } catch (e) {
      return false;
    }
  }

  @override
  void setAuthToken(String? token) {
    // Persist only. The per-request injector reads the token from storage each
    // request, so we never set a sticky Dio default header that could go stale
    // (across token rotation, logout, or a second ApiClient instance).
    if (token != null) {
      _tokenStorage.saveAccessToken(token);
    } else {
      _tokenStorage.clearTokens();
    }
  }

  @override
  void clearAuthToken() => setAuthToken(null);

  @override
  void dispose() {
    _networkClient.dispose();
  }

  /// Handle token refresh when 401 is received. Single-flight: concurrent 401s
  /// await the same refresh instead of each hitting /auth/refresh.
  Future<String?> _handleTokenRefresh() {
    return _refreshInFlight ??=
        _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStorage.getRefreshToken();
    if (refreshToken == null) {
      // No way to recover — clear any stale token so requests stop retrying.
      await _tokenStorage.clearTokens();
      return null;
    }

    try {
      // /auth/refresh is a public endpoint, so the per-request injector skips
      // it; no need to mutate the shared auth header.
      final response = await _networkClient.post('/auth/refresh', data: {
        'refresh_token': refreshToken,
      });

      if (response.statusCode == 200) {
        final newToken = response.data['access_token'] as String?;
        if (newToken != null) {
          setAuthToken(newToken);
          return newToken;
        }
      }
    } catch (_) {
      // fall through to clear below
    }

    // Refresh failed → clear tokens so the app stops retrying and routes to login.
    await _tokenStorage.clearTokens();
    return null;
  }

  /// Handle successful responses
  ApiResponse<T> _handleResponse<T>(
    Response response, {
    T Function(dynamic)? fromJson,
  }) {
    final statusCode = response.statusCode ?? 0;

    if (statusCode >= 200 && statusCode < 300) {
      T? data;
      if (fromJson != null && response.data != null) {
        try {
          data = fromJson(response.data);
        } catch (e) {
          // Try different response envelope formats
          if (response.data is Map<String, dynamic>) {
            final responseMap = response.data as Map<String, dynamic>;

            // Try common envelope patterns
            for (final key in ['data', 'result', 'payload', 'items']) {
              if (responseMap.containsKey(key)) {
                try {
                  data = fromJson(responseMap[key]);
                  break;
                } catch (_) {
                  continue;
                }
              }
            }
          }

          if (data == null) {
            throw ApiException('Failed to parse response data', statusCode);
          }
        }
      } else if (response.data != null) {
        data = response.data as T;
      }

      return ApiResponse<T>(
        data: data,
        statusCode: statusCode,
        message: 'Success',
      );
    }

    throw ApiException('Request failed', statusCode);
  }

  /// Handle and convert errors
  ApiException _handleError(dynamic error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode ?? 0;
      String message;

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
          message =
              'Connection timeout. Please check your internet connection.';
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

    return ApiException('An unexpected error occurred', 0, error);
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
}

/// API Response wrapper class
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

/// Abstract interface for network client
abstract class NetworkClient {
  Future<void> initialize();
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters});
  Future<Response> post(String path, {dynamic data});
  Future<Response> put(String path, {dynamic data});
  Future<Response> delete(String path);
  Future<Response> upload(
    String path, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? data,
    ProgressCallback? onProgress,
  });
  Future<void> download(
    String path,
    String savePath, {
    Map<String, dynamic>? queryParameters,
    ProgressCallback? onProgress,
  });
  void setAuthHeader(String authHeader);
  void clearAuthHeader();
  void setTokenRefreshCallback(Future<String?> Function() callback);
  void dispose();
}

/// Abstract interface for token storage
abstract class TokenStorage {
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> saveAccessToken(String token);
  Future<void> saveRefreshToken(String token);
  Future<void> clearTokens();
}
