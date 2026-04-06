import 'dart:developer' as developer;
import '../constants/app_strings.dart';

/// Logging utility for the app
class AppLogger {
  AppLogger._();

  static String get _tag => AppStrings.appName;

  /// Log debug message
  static void debug(String message, {String? tag}) {
    developer.log(message, name: tag ?? _tag, level: 500);
  }

  /// Log info message
  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? _tag, level: 800);
  }

  /// Log warning
  static void warning(String message, {String? tag, Object? error}) {
    developer.log(message, name: tag ?? _tag, level: 900, error: error);
  }

  /// Log error
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? _tag,
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log API call
  static void api(
    String method,
    String url, {
    int? statusCode,
    String? response,
  }) {
    developer.log(
      'API $method $url ${statusCode != null ? "- $statusCode" : ""}',
      name: '$_tag.API',
      level: 500,
    );

    if (response != null) {
      developer.log('Response: $response', name: '$_tag.API', level: 500);
    }
  }

  /// Log navigation
  static void navigation(String from, String to) {
    developer.log(
      'Navigation: $from → $to',
      name: '$_tag.Navigation',
      level: 500,
    );
  }

  /// Log user action
  static void userAction(String action, {Map<String, dynamic>? data}) {
    developer.log(
      'User Action: $action ${data != null ? "- $data" : ""}',
      name: '$_tag.UserAction',
      level: 500,
    );
  }
}
