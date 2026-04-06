import '../errors/failures.dart';

/// Type-safe result type for operations that can fail
/// Use this instead of throwing exceptions
sealed class Result<T> {
  const Result();

  /// Execute different code based on success or failure
  R when<R>({
    required R Function(T data) success,
    required R Function(Failure failure) failure,
  }) {
    return switch (this) {
      Success(data: final data) => success(data),
      Failed(failure: final f) => failure(f),
    };
  }

  /// Check if result is successful
  bool get isSuccess => this is Success<T>;

  /// Check if result is failed
  bool get isFailure => this is Failed<T>;

  /// Get data if successful, null otherwise
  T? get dataOrNull => switch (this) {
    Success(data: final data) => data,
    Failed() => null,
  };

  /// Get failure if failed, null otherwise
  Failure? get failureOrNull => switch (this) {
    Success() => null,
    Failed(failure: final f) => f,
  };
}

/// Successful result with data
class Success<T> extends Result<T> {
  final T data;

  const Success(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Success<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success(data: $data)';
}

/// Failed result with failure reason
class Failed<T> extends Result<T> {
  final Failure failure;

  const Failed(this.failure);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failed<T> &&
          runtimeType == other.runtimeType &&
          failure == other.failure;

  @override
  int get hashCode => failure.hashCode;

  @override
  String toString() => 'Failed(failure: $failure)';
}
