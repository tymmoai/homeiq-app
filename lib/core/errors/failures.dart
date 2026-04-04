
abstract class Failure {
  final String message;
  final Exception? exception;

  const Failure(this.message, [this.exception]);

  @override
  String toString() => message;
}

/// Failure when server returns an error
class ServerFailure extends Failure {
  final int? statusCode;

  const ServerFailure(super.message, [this.statusCode, super.exception]);

  @override
  String toString() => 'Server Error: $message${statusCode != null ? " (Status: $statusCode)" : ""}';
}

/// Failure when there's no internet connection
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection', super.exception]);

  @override
  String toString() => 'Network Error: $message';
}

/// Failure when cache operations fail
class CacheFailure extends Failure {
  const CacheFailure([super.message = 'Cache error', super.exception]);

  @override
  String toString() => 'Cache Error: $message';
}

/// Failure when data parsing fails
class ParseFailure extends Failure {
  const ParseFailure([super.message = 'Failed to parse data', super.exception]);

  @override
  String toString() => 'Parse Error: $message';
}

/// Failure when authentication fails
class AuthenticationFailure extends Failure {
  const AuthenticationFailure([super.message = 'Authentication failed', super.exception]);

  @override
  String toString() => 'Authentication Error: $message';
}

/// Failure when user is not authorized
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Unauthorized access', super.exception]);

  @override
  String toString() => 'Unauthorized: $message';
}

/// Failure when validation fails
class ValidationFailure extends Failure {
  final Map<String, String>? errors;

  const ValidationFailure(super.message, [this.errors, super.exception]);

  @override
  String toString() {
    if (errors != null && errors!.isNotEmpty) {
      final errorList = errors!.entries.map((e) => '${e.key}: ${e.value}').join(', ');
      return 'Validation Error: $message ($errorList)';
    }
    return 'Validation Error: $message';
  }
}

/// Failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'An unexpected error occurred', super.exception]);

  @override
  String toString() => 'Unexpected Error: $message';
}
