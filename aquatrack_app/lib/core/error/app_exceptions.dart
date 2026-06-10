/// Base class cho tất cả application exceptions
///
/// Provides consistent error handling patterns across the app.
/// All custom exceptions should extend từ AppException.
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Network-related exceptions
class NetworkException extends AppException {
  final int? statusCode;

  const NetworkException(
    super.message, {
    this.statusCode,
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'NetworkException($statusCode): $message';
}

/// Authentication-related exceptions
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'AuthException($code): $message';
}

/// Data validation exceptions
class ValidationException extends AppException {
  final Map<String, List<String>>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalError,
  });

  @override
  String toString() {
    if (fieldErrors != null && fieldErrors!.isNotEmpty) {
      final errors = fieldErrors!.entries
          .map((e) => '${e.key}: ${e.value.join(', ')}')
          .join(', ');
      return 'ValidationException($code): $message - Fields: $errors';
    }
    return 'ValidationException($code): $message';
  }
}

/// Storage-related exceptions
class StorageException extends AppException {
  const StorageException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'StorageException($code): $message';
}

/// Business logic exceptions
class BusinessLogicException extends AppException {
  const BusinessLogicException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'BusinessLogicException($code): $message';
}

/// Cache-related exceptions
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'CacheException($code): $message';
}

/// File operation exceptions
class FileException extends AppException {
  final String? filePath;

  const FileException(
    super.message, {
    this.filePath,
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'FileException($code): $message${filePath != null ? ' (File: $filePath)' : ''}';
}

/// Permission-related exceptions
class PermissionException extends AppException {
  final String permissionType;

  const PermissionException(
    super.message,
    this.permissionType, {
    super.code,
    super.originalError,
  });

  @override
  String toString() =>
      'PermissionException($code): $message (Permission: $permissionType)';
}

/// Unknown/Unexpected exceptions wrapper
class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.code,
    super.originalError,
  });

  @override
  String toString() => 'UnknownException($code): $message';
}
