import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for common lookups.
///
/// These reduce boilerplate without adding any behavioral changes.
///
/// **Note:** Screen-size utilities such as `isTablet`, `screenWidth`, and
/// responsive sizing helpers live in `ResponsiveUtils` and are accessed
/// via `context.responsive` (see `lib/utils/responsive_utils.dart`).
extension ContextExtensions on BuildContext {
  // ---------------------------------------------------------------------------
  // Theme shortcuts
  // ---------------------------------------------------------------------------

  /// Shortcut for `Theme.of(context)`.
  ThemeData get theme => Theme.of(this);

  /// Shortcut for `Theme.of(context).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shortcut for `Theme.of(context).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ---------------------------------------------------------------------------
  // Media query shortcuts
  // ---------------------------------------------------------------------------

  /// The current [MediaQueryData].
  MediaQueryData get mediaQuery => MediaQuery.of(this);

  /// The full screen size from [MediaQuery].
  Size get screenSize => MediaQuery.sizeOf(this);

  /// The view padding (notch / system UI).
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  /// Current screen brightness (light or dark).
  Brightness get platformBrightness => MediaQuery.platformBrightnessOf(this);

  // ---------------------------------------------------------------------------
  // Snack bar helpers
  // ---------------------------------------------------------------------------

  /// Show a standard [SnackBar] with [message].
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an error-styled [SnackBar] with [message].
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a success-styled [SnackBar] with [message].
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason> showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(this);
    messenger.hideCurrentSnackBar();
    return messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation helpers
  // ---------------------------------------------------------------------------

  /// Shortcut for `Navigator.of(context).pop()`.
  void pop<R>([R? result]) => Navigator.of(this).pop(result);

  /// Whether the navigator can pop the current route.
  bool get canPop => Navigator.of(this).canPop();

  // ---------------------------------------------------------------------------
  // Focus helpers
  // ---------------------------------------------------------------------------

  /// Dismiss the keyboard by unfocusing the current focus node.
  void dismissKeyboard() => FocusScope.of(this).unfocus();
}
