import 'package:flutter/widgets.dart';

import '../utils/logger.dart';

/// A mixin for [State] subclasses that provides safer patterns for common
/// operations without requiring a full migration away from [StatefulWidget].
///
/// Apply this mixin to any existing `State` class to incrementally improve
/// code quality:
///
/// ```dart
/// class _MyScreenState extends State<MyScreen> with ViewModelMixin {
///   String? _data;
///   
///   @override
///   void initState() {
///     super.initState();
///     runAsync(_loadData);
///   }
///
///   Future<void> _loadData() async {
///     final data = await repository.fetchData();
///     safeSetState(() => _data = data);
///   }
/// }
/// ```
mixin ViewModelMixin<T extends StatefulWidget> on State<T> {
  bool _isProcessing = false;

  /// Whether an async operation started via [runAsync] is currently running.
  bool get isProcessing => _isProcessing;

  /// A [mounted]-safe wrapper around [setState].
  ///
  /// Prevents the common "setState() called after dispose()" error that
  /// occurs when an async operation completes after the widget is removed
  /// from the tree.
  void safeSetState(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }

  /// Runs an async [operation] with automatic error handling.
  ///
  /// - Sets [isProcessing] to `true` before the operation.
  /// - Calls [onError] (or logs) if the operation throws.
  /// - Sets [isProcessing] to `false` when complete.
  /// - All state updates are guarded by [mounted].
  ///
  /// Returns the result of the operation, or `null` if it failed.
  Future<R?> runAsync<R>(
    Future<R> Function() operation, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    safeSetState(() => _isProcessing = true);
    try {
      final result = await operation();
      return result;
    } on Object catch (e, st) {
      if (onError != null) {
        onError(e, st);
      } else {
        AppLogger.error('${widget.runtimeType}: async operation failed', error: e, stackTrace: st);
      }
      return null;
    } finally {
      safeSetState(() => _isProcessing = false);
    }
  }

  /// Runs an async operation that does not return a value.
  ///
  /// Convenience wrapper around [runAsync] for void-returning futures.
  Future<void> runAsyncAction(
    Future<void> Function() action, {
    void Function(Object error, StackTrace stackTrace)? onError,
  }) async {
    await runAsync<void>(action, onError: onError);
  }

  /// Delays execution until after the current frame.
  ///
  /// Useful for operations that need to happen after the widget tree
  /// has finished building (e.g. showing a dialog in initState).
  void postFrame(VoidCallback callback) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) callback();
    });
  }
}
