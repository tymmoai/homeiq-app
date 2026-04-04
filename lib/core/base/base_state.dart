/// Generic async state for use with StateNotifier-based state management.
///
/// Provides a sealed type representing the three fundamental states of an
/// asynchronous operation: loading, loaded (with data), and error.
///
/// Usage:
/// ```dart
/// class MyNotifier extends BaseNotifier<MyData> {
///   Future<void> fetchData() async {
///     state = const AsyncState.loading();
///     final result = await _repository.getData();
///     result.when(
///       success: (data) => state = AsyncState.data(data),
///       failure: (f) => state = AsyncState.error(f.message),
///     );
///   }
/// }
/// ```
sealed class AsyncState<T> {
  const AsyncState();

  /// The operation is in progress.
  const factory AsyncState.loading() = AsyncLoading<T>;

  /// The operation completed successfully with [data].
  const factory AsyncState.data(T data) = AsyncData<T>;

  /// The operation completed with an [error].
  const factory AsyncState.error(String message, [Object? error]) =
      AsyncError<T>;

  /// Whether this state represents a loading operation.
  bool get isLoading => this is AsyncLoading<T>;

  /// Whether this state contains data.
  bool get hasData => this is AsyncData<T>;

  /// Whether this state contains an error.
  bool get hasError => this is AsyncError<T>;

  /// Returns the data if this is [AsyncData], otherwise `null`.
  T? get dataOrNull => switch (this) {
    AsyncData<T>(:final data) => data,
    _ => null,
  };

  /// Returns the error message if this is [AsyncError], otherwise `null`.
  String? get errorOrNull => switch (this) {
    AsyncError<T>(:final message) => message,
    _ => null,
  };

  /// Pattern-match on all three states.
  R when<R>({
    required R Function() loading,
    required R Function(T data) data,
    required R Function(String message, Object? error) error,
  }) {
    return switch (this) {
      AsyncLoading<T>() => loading(),
      AsyncData<T>(data: final d) => data(d),
      AsyncError<T>(message: final m, error: final e) => error(m, e),
    };
  }

  /// Like [when], but with optional handlers and a required [orElse].
  R maybeWhen<R>({
    R Function()? loading,
    R Function(T data)? data,
    R Function(String message, Object? error)? error,
    required R Function() orElse,
  }) {
    return switch (this) {
      AsyncLoading<T>() => loading != null ? loading() : orElse(),
      AsyncData<T>(data: final d) => data != null ? data(d) : orElse(),
      AsyncError<T>(message: final m, error: final e) =>
        error != null ? error(m, e) : orElse(),
    };
  }
}

/// The loading variant of [AsyncState].
class AsyncLoading<T> extends AsyncState<T> {
  const AsyncLoading();

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AsyncLoading<T>;

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AsyncState<$T>.loading()';
}

/// The data variant of [AsyncState].
class AsyncData<T> extends AsyncState<T> {
  /// The successfully loaded data.
  final T data;

  const AsyncData(this.data);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncData<T> &&
          runtimeType == other.runtimeType &&
          data == other.data;

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'AsyncState<$T>.data($data)';
}

/// The error variant of [AsyncState].
class AsyncError<T> extends AsyncState<T> {
  /// A human-readable error message.
  final String message;

  /// The original error object, if available.
  final Object? error;

  const AsyncError(this.message, [this.error]);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AsyncError<T> &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => 'AsyncState<$T>.error($message)';
}
