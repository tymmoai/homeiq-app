import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../errors/failures.dart';
import '../utils/logger.dart';
import '../utils/result.dart';
import 'base_state.dart';

/// A base [StateNotifier] that provides common patterns for managing
/// asynchronous state with loading, data, and error handling.
///
/// Extend this class when creating feature-specific notifiers to get:
/// - Automatic loading state management
/// - Standardized error handling via [Result]
/// - Dispose cleanup for subscriptions and timers
/// - A consistent API for async operations
///
/// Usage:
/// ```dart
/// class ProductsNotifier extends BaseNotifier<List<Product>> {
///   final ProductRepository _repo;
///
///   ProductsNotifier(this._repo) {
///     loadProducts();
///   }
///
///   Future<void> loadProducts() => run(() => _repo.getProducts());
/// }
/// ```
abstract class BaseNotifier<T> extends StateNotifier<AsyncState<T>> {
  BaseNotifier() : super(const AsyncState.loading());

  /// Subscriptions to cancel on dispose.
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Timers to cancel on dispose.
  final List<Timer> _timers = [];

  // ---------------------------------------------------------------------------
  // State helpers
  // ---------------------------------------------------------------------------

  /// Whether the current state is loading.
  bool get isLoading => state.isLoading;

  /// Convenience getter for the current data (nullable).
  T? get data => state.dataOrNull;

  /// Set state to loading.
  void setLoading() => state = const AsyncState.loading();

  /// Set state to data.
  void setData(T data) => state = AsyncState.data(data);

  /// Set state to error.
  void setError(String message, [Object? error]) =>
      state = AsyncState.error(message, error);

  // ---------------------------------------------------------------------------
  // Async operation helpers
  // ---------------------------------------------------------------------------

  /// Runs an async operation that returns `T` directly.
  ///
  /// Sets loading state before the operation and data/error state after.
  /// Set [showLoading] to `false` to keep the previous state while loading
  /// (useful for pull-to-refresh or silent reloads).
  Future<void> run(
    Future<T> Function() operation, {
    bool showLoading = true,
  }) async {
    if (showLoading) setLoading();
    try {
      final result = await operation();
      if (mounted) setData(result);
    } on Object catch (e, st) {
      AppLogger.error(
        '$runtimeType: operation failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) setError(_errorMessage(e), e);
    }
  }

  /// Runs an async operation that returns a [Result<T>].
  ///
  /// Automatically maps [Success] and [Failed] to the correct state.
  Future<void> runResult(
    Future<Result<T>> Function() operation, {
    bool showLoading = true,
  }) async {
    if (showLoading) setLoading();
    try {
      final result = await operation();
      if (!mounted) return;
      result.when(
        success: (data) => setData(data),
        failure: (f) => setError(f.message),
      );
    } on Object catch (e, st) {
      AppLogger.error(
        '$runtimeType: operation failed',
        error: e,
        stackTrace: st,
      );
      if (mounted) setError(_errorMessage(e), e);
    }
  }

  /// Runs an async side-effect (e.g. delete, update) that does not change
  /// the primary state type.
  ///
  /// Returns `true` if the operation succeeded.
  Future<bool> runAction(Future<void> Function() action) async {
    try {
      await action();
      return true;
    } on Object catch (e, st) {
      AppLogger.error('$runtimeType: action failed', error: e, stackTrace: st);
      if (mounted) setError(_errorMessage(e), e);
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Subscription / Timer management
  // ---------------------------------------------------------------------------

  /// Register a [StreamSubscription] so it is automatically cancelled on
  /// dispose.
  void addSubscription(StreamSubscription<dynamic> subscription) {
    _subscriptions.add(subscription);
  }

  /// Register a [Timer] so it is automatically cancelled on dispose.
  void addTimer(Timer timer) {
    _timers.add(timer);
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();

    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _errorMessage(Object error) {
    if (error is Failure) return error.message;
    if (error is Exception) return error.toString();
    return 'An unexpected error occurred';
  }
}
