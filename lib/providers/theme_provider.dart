import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/theme/app_theme_presets.dart';
import '../main.dart';

/// Key used to persist the selected theme id in SharedPreferences.
const _themePrefsKey = 'selected_theme_id';
const _customColorKey = 'custom_theme_color';

/// Provides the currently-active [AppThemePreset].
final themePresetProvider =
    StateNotifierProvider<ThemePresetNotifier, AppThemePreset>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return ThemePresetNotifier(prefs);
    });

/// Notifier that manages the selected theme preset and persists it.
class ThemePresetNotifier extends StateNotifier<AppThemePreset> {
  final SharedPreferences _prefs;

  ThemePresetNotifier(this._prefs) : super(_resolveInitial(_prefs));

  static AppThemePreset _resolveInitial(SharedPreferences prefs) {
    final id = prefs.getString(_themePrefsKey) ?? 'ocean';
    if (id == 'custom') {
      final colorValue = prefs.getInt(_customColorKey);
      if (colorValue != null) {
        return AppThemePresets.fromCustomColor(Color(colorValue));
      }
    }
    return AppThemePresets.getById(id);
  }

  /// Switch to a different theme preset by [id].
  void selectTheme(String id) {
    final preset = AppThemePresets.getById(id);
    state = preset;
    _prefs.setString(_themePrefsKey, id);
  }

  /// Switch to a custom color theme.
  void selectCustomColor(Color color) {
    final preset = AppThemePresets.fromCustomColor(color);
    state = preset;
    _prefs.setString(_themePrefsKey, 'custom');
    _prefs.setInt(_customColorKey, color.toARGB32());
  }

  /// Current theme id.
  String get currentId => state.id;
}
