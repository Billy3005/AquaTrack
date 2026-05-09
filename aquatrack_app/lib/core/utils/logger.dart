import 'dart:developer' as developer;
import '../config/app_config.dart';

/// Application logger for consistent logging across the app
class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  /// Debug level logging
  static void debug(String tag, String message, [dynamic error]) {
    if (!AppConfig.enableDebugLogging) return;

    final formattedMessage = _formatMessage(tag, message);
    developer.log(
      formattedMessage,
      name: 'DEBUG',
      error: error,
      level: 500, // Debug level
    );
  }

  /// Info level logging
  static void info(String tag, String message, [dynamic error]) {
    if (!AppConfig.enableLogging) return;

    final formattedMessage = _formatMessage(tag, message);
    developer.log(
      formattedMessage,
      name: 'INFO',
      error: error,
      level: 800, // Info level
    );
  }

  /// Warning level logging
  static void warning(String tag, String message, [dynamic error]) {
    final formattedMessage = _formatMessage(tag, message);
    developer.log(
      formattedMessage,
      name: 'WARNING',
      error: error,
      level: 900, // Warning level
    );
  }

  /// Error level logging
  static void error(String tag, String message, [dynamic error]) {
    final formattedMessage = _formatMessage(tag, message);
    developer.log(
      formattedMessage,
      name: 'ERROR',
      error: error,
      level: 1000, // Error level
    );
  }

  /// Network logging for API calls
  static void network(
    String method,
    String url, {
    int? statusCode,
    Duration? duration,
    dynamic error,
  }) {
    if (!AppConfig.enableNetworkLogs) return;

    final buffer = StringBuffer();
    buffer.write('$method $url');

    if (statusCode != null) {
      buffer.write(' → $statusCode');
    }

    if (duration != null) {
      buffer.write(' (${duration.inMilliseconds}ms)');
    }

    final level = _getNetworkLogLevel(statusCode, error);

    developer.log(
      buffer.toString(),
      name: 'NETWORK',
      error: error,
      level: level,
    );
  }

  /// Format message with timestamp and tag
  static String _formatMessage(String tag, String message) {
    final timestamp = DateTime.now().toIso8601String();
    return '[$timestamp][$tag] $message';
  }

  /// Get appropriate log level for network calls
  static int _getNetworkLogLevel(int? statusCode, dynamic error) {
    if (error != null) return 1000; // Error
    if (statusCode == null) return 500; // Debug
    if (statusCode >= 400) return 900; // Warning
    return 800; // Info
  }

  /// Log app lifecycle events
  static void lifecycle(String event, [Map<String, dynamic>? data]) {
    final message = data != null ? '$event: ${data.toString()}' : event;

    info('Lifecycle', message);
  }

  /// Log user actions for analytics
  static void userAction(String action, [Map<String, dynamic>? properties]) {
    if (!AppConfig.enableAnalytics) return;

    final message =
        properties != null ? '$action: ${properties.toString()}' : action;

    info('UserAction', message);
  }

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, [
    Map<String, dynamic>? metadata,
  ]) {
    final message = metadata != null
        ? '$operation took ${duration.inMilliseconds}ms: ${metadata.toString()}'
        : '$operation took ${duration.inMilliseconds}ms';

    debug('Performance', message);
  }
}
