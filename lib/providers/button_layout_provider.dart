import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_dimensions.dart';
import '../main.dart';

/// The two supported button shapes across the app.
enum ButtonLayoutMode {
  /// Fully rounded pill / capsule buttons (default SquareTrade style).
  capsule,

  /// Standard rectangular buttons with medium corner radius.
  normal,
}

const _prefsKey = 'button_layout_mode';

/// Provides the current [ButtonLayoutMode] and persists changes.
final buttonLayoutProvider =
    StateNotifierProvider<ButtonLayoutNotifier, ButtonLayoutMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ButtonLayoutNotifier(prefs);
});

class ButtonLayoutNotifier extends StateNotifier<ButtonLayoutMode> {
  final SharedPreferences _prefs;

  ButtonLayoutNotifier(this._prefs) : super(_resolve(_prefs));

  static ButtonLayoutMode _resolve(SharedPreferences prefs) {
    final value = prefs.getString(_prefsKey);
    if (value == 'normal') return ButtonLayoutMode.normal;
    return ButtonLayoutMode.capsule; // default
  }

  void setLayout(ButtonLayoutMode mode) {
    state = mode;
    _prefs.setString(_prefsKey, mode.name);
  }
}

/// Helper extension to obtain the correct border radius for the active layout.
extension ButtonLayoutRadius on ButtonLayoutMode {
  /// Radius used for elevated / outlined / text buttons.
  double get buttonRadius {
    switch (this) {
      case ButtonLayoutMode.capsule:
        return AppDimensions.radiusPill; // 50
      case ButtonLayoutMode.normal:
        return AppDimensions.radiusMedium; // 12
    }
  }

  /// Radius used for small badges, chips, tags.
  double get badgeRadius {
    switch (this) {
      case ButtonLayoutMode.capsule:
        return AppDimensions.radiusPill; // 50 (fully rounded)
      case ButtonLayoutMode.normal:
        return AppDimensions.radiusSmall; // 8
    }
  }

  /// Rounded rectangle shape for buttons.
  RoundedRectangleBorder get buttonShape => RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      );
}
