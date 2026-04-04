/// Custom exceptions for the app
/// These are thrown from the data layer
library;

/// Exception thrown when there's a server error
class ServerException implements Exception {
  final String message;
  final int? statusCode;

  const ServerException(this.message, [this.statusCode]);

  @override
  String toString() => 'ServerException: $message (Status: $statusCode)';
}

/// Exception thrown when there's a network connectivity issue
class NetworkException implements Exception {
  final String message;

  const NetworkException([this.message = 'No internet connection']);

  @override
  String toString() => 'NetworkException: $message';
}

/// Exception thrown when cache operations fail
class CacheException implements Exception {
  final String message;

  const CacheException([this.message = 'Cache error']);

  @override
  String toString() => 'CacheException: $message';
}

/// Exception thrown when data parsing fails
class ParseException implements Exception {
  final String message;
  final dynamic data;

  const ParseException(this.message, [this.data]);

  @override
  String toString() => 'ParseException: $message';
}

/// Exception thrown when authentication fails
class AuthenticationException implements Exception {
  final String message;

  const AuthenticationException([this.message = 'Authentication failed']);

  @override
  String toString() => 'AuthenticationException: $message';
}

/// Exception thrown when user is not authorized
class UnauthorizedException implements Exception {
  final String message;

  const UnauthorizedException([this.message = 'Unauthorized access']);

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Exception thrown when validation fails
class ValidationException implements Exception {
  final String message;
  final Map<String, String>? errors;

  const ValidationException(this.message, [this.errors]);

  @override
  String toString() => 'ValidationException: $message';
}
