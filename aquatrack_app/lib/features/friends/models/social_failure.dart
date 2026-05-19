import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/services/api_service.dart';

part 'social_failure.freezed.dart';

/// Social feature specific failures
@freezed
class SocialFailure with _$SocialFailure {
  const SocialFailure._();
  const factory SocialFailure.network({
    required String message,
    Exception? originalException,
  }) = _NetworkFailure;

  const factory SocialFailure.authentication({
    required String message,
    @Default(401) int statusCode,
  }) = _AuthenticationFailure;

  const factory SocialFailure.authorization({
    required String message,
    @Default(403) int statusCode,
  }) = _AuthorizationFailure;

  const factory SocialFailure.validation({
    required String message,
    required Map<String, dynamic> errors,
    @Default(400) int statusCode,
  }) = _ValidationFailure;

  const factory SocialFailure.notFound({
    required String message,
    @Default(404) int statusCode,
  }) = _NotFoundFailure;

  const factory SocialFailure.server({
    required String message,
    @Default(500) int statusCode,
    String? details,
  }) = _ServerFailure;

  const factory SocialFailure.timeout({required String message}) =
      _TimeoutFailure;

  const factory SocialFailure.unknown({
    required String message,
    Exception? originalException,
  }) = _UnknownFailure;

  /// Create SocialFailure from ApiException
  static SocialFailure fromApiException(ApiException apiException) {
    final statusCode = apiException.statusCode;
    final message = apiException.message;

    switch (statusCode) {
      case 400:
        return SocialFailure.validation(
          message: message,
          errors: apiException.originalError is Map<String, dynamic>
              ? apiException.originalError as Map<String, dynamic>
              : {},
          statusCode: statusCode,
        );
      case 401:
        return SocialFailure.authentication(
          message: message,
          statusCode: statusCode,
        );
      case 403:
        return SocialFailure.authorization(
          message: message,
          statusCode: statusCode,
        );
      case 404:
        return SocialFailure.notFound(message: message, statusCode: statusCode);
      case >= 500:
        return SocialFailure.server(
          message: message,
          statusCode: statusCode,
          details: apiException.originalError?.toString(),
        );
      default:
        return SocialFailure.unknown(
          message: message,
          originalException: apiException,
        );
    }
  }

  /// User-friendly error messages in Vietnamese
  String get userMessage {
    return when(
      network: (message, _) => 'Lỗi kết nối mạng. Vui lòng kiểm tra internet.',
      authentication: (message, _) =>
          'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      authorization: (message, _) =>
          'Bạn không có quyền thực hiện thao tác này.',
      validation: (message, errors, _) =>
          'Thông tin không hợp lệ. Vui lòng kiểm tra lại.',
      notFound: (message, _) => 'Không tìm thấy thông tin yêu cầu.',
      server: (message, _, details) => 'Lỗi máy chủ. Vui lòng thử lại sau.',
      timeout: (message) => 'Kết nối quá chậm. Vui lòng thử lại.',
      unknown: (message, _) => 'Có lỗi xảy ra. Vui lòng thử lại.',
    );
  }

  /// Whether this error can be retried
  bool get canRetry {
    return when(
      network: (_, __) => true,
      authentication: (_, __) => false, // Need re-login
      authorization: (_, __) => false, // Permission issue
      validation: (_, __, ___) => false, // Bad data
      notFound: (_, __) => false, // Resource doesn't exist
      server: (_, __, ___) => true, // Temporary server issue
      timeout: (_) => true, // Can retry
      unknown: (_, __) => true, // Unknown, worth trying
    );
  }

  /// Whether this is a temporary error
  bool get isTemporary {
    return when(
      network: (_, __) => true,
      authentication: (_, __) => false,
      authorization: (_, __) => false,
      validation: (_, __, ___) => false,
      notFound: (_, __) => false,
      server: (_, __, ___) => true,
      timeout: (_) => true,
      unknown: (_, __) => false,
    );
  }
}
