import 'package:flutter/material.dart';

/// A named color preset that drives the entire app theme.
class AppThemePreset {
  final String id;
  final String name;
  final String emoji;
  final Color primary;
  final Color primaryLight;
  final Color primaryDark;
  final Color accent;
  final Color accentDark;
  final Color accentLight;
  final Brightness brightness;

  const AppThemePreset({
    required this.id,
    required this.name,
    required this.emoji,
    required this.primary,
    required this.primaryLight,
    required this.primaryDark,
    required this.accent,
    required this.accentDark,
    required this.accentLight,
    this.brightness = Brightness.light,
  });

  // ── Derived colors ──────────────────────────────────────────────────────

  Color get background =>
      brightness == Brightness.light ? const Color(0xFFF3F6F9) : const Color(0xFF121212);

  Color get surface =>
      brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);

  Color get surfaceVariant =>
      brightness == Brightness.light ? const Color(0xFFF5F7FA) : const Color(0xFF2C2C2C);

  Color get textPrimary =>
      brightness == Brightness.light ? primary : Colors.white;

  Color get textSecondary =>
      brightness == Brightness.light ? const Color(0xFF4E5969) : const Color(0xFFB0BCC8);

  Color get textOnPrimary => Colors.white;

  Color get border =>
      brightness == Brightness.light ? const Color(0xFFE4E9ED) : const Color(0xFF3A3A3A);

  Color get divider =>
      brightness == Brightness.light ? const Color(0xFFE4E9ED) : const Color(0xFF3A3A3A);

  Color get cardBackground =>
      brightness == Brightness.light ? Colors.white : const Color(0xFF1E1E1E);

  Color get iconPrimary =>
      brightness == Brightness.light ? primary : Colors.white;

  Color get iconSecondary =>
      brightness == Brightness.light ? const Color(0xFF4E5969) : const Color(0xFF8C97A8);

  Color get buttonPrimary => primary;

  Color get shadow =>
      brightness == Brightness.light
          ? Colors.black.withValues(alpha: 0.063)
          : Colors.black.withValues(alpha: 0.3);
}

/// All available theme presets.
class AppThemePresets {
  AppThemePresets._();

  static const defaultNavy = AppThemePreset(
    id: 'default',
    name: 'Navy Blue',
    emoji: '🔵',
    primary: Color.fromARGB(255, 25, 41, 82),
    primaryLight: Color(0xFF2C4480),
    primaryDark: Color(0xFF0F1F45),
    accent: Color.fromARGB(255, 201, 86, 63),
    accentDark: Color(0xFFD4554A),
    accentLight: Color(0xFFFDE8E4),
  );

  static const oceanBlue = AppThemePreset(
    id: 'ocean',
    name: 'Ocean Blue',
    emoji: '🌊',
    primary: Color(0xFF0277BD),
    primaryLight: Color(0xFF039BE5),
    primaryDark: Color(0xFF01579B),
    accent: Color(0xFF00BCD4),
    accentDark: Color(0xFF00838F),
    accentLight: Color(0xFFE0F7FA),
  );

  static const forestGreen = AppThemePreset(
    id: 'forest',
    name: 'Forest Green',
    emoji: '🌿',
    primary: Color(0xFF2E7D32),
    primaryLight: Color(0xFF43A047),
    primaryDark: Color(0xFF1B5E20),
    accent: Color(0xFFFF8F00),
    accentDark: Color(0xFFE65100),
    accentLight: Color(0xFFFFF3E0),
  );

  static const royalPurple = AppThemePreset(
    id: 'purple',
    name: 'Royal Purple',
    emoji: '💜',
    primary: Color(0xFF6A1B9A),
    primaryLight: Color(0xFF8E24AA),
    primaryDark: Color(0xFF4A148C),
    accent: Color(0xFFE91E63),
    accentDark: Color(0xFFC2185B),
    accentLight: Color(0xFFFCE4EC),
  );

  static const sunsetOrange = AppThemePreset(
    id: 'sunset',
    name: 'Sunset Orange',
    emoji: '🌅',
    primary: Color(0xFFE65100),
    primaryLight: Color(0xFFF4511E),
    primaryDark: Color(0xFFBF360C),
    accent: Color(0xFFFFC107),
    accentDark: Color(0xFFF57F17),
    accentLight: Color(0xFFFFF8E1),
  );

  static const crimsonRed = AppThemePreset(
    id: 'crimson',
    name: 'Crimson Red',
    emoji: '❤️',
    primary: Color(0xFFC62828),
    primaryLight: Color(0xFFE53935),
    primaryDark: Color(0xFF8E0000),
    accent: Color(0xFF42A5F5),
    accentDark: Color(0xFF1976D2),
    accentLight: Color(0xFFE3F2FD),
  );

  static const tealCyan = AppThemePreset(
    id: 'teal',
    name: 'Teal',
    emoji: '🩵',
    primary: Color(0xFF00796B),
    primaryLight: Color(0xFF009688),
    primaryDark: Color(0xFF004D40),
    accent: Color(0xFFFF7043),
    accentDark: Color(0xFFE64A19),
    accentLight: Color(0xFFFBE9E7),
  );

  static const rosePink = AppThemePreset(
    id: 'rose',
    name: 'Rose Pink',
    emoji: '🌸',
    primary: Color(0xFFAD1457),
    primaryLight: Color(0xFFD81B60),
    primaryDark: Color(0xFF880E4F),
    accent: Color(0xFF26A69A),
    accentDark: Color(0xFF00897B),
    accentLight: Color(0xFFE0F2F1),
  );

  static const darkMode = AppThemePreset(
    id: 'dark',
    name: 'Dark Mode',
    emoji: '🌙',
    primary: Color(0xFF90CAF9),
    primaryLight: Color(0xFFBBDEFB),
    primaryDark: Color(0xFF42A5F5),
    accent: Color(0xFFFF8A65),
    accentDark: Color(0xFFFF7043),
    accentLight: Color(0xFF3E2723),
    brightness: Brightness.dark,
  );

  static const charcoal = AppThemePreset(
    id: 'charcoal',
    name: 'Charcoal',
    emoji: '🖤',
    primary: Color(0xFF37474F),
    primaryLight: Color(0xFF546E7A),
    primaryDark: Color(0xFF263238),
    accent: Color(0xFFFFAB40),
    accentDark: Color(0xFFFF9100),
    accentLight: Color(0xFFFFF8E1),
  );

  /// All presets in display order.
  static const List<AppThemePreset> all = [
    defaultNavy,
    oceanBlue,
    forestGreen,
    royalPurple,
    sunsetOrange,
    crimsonRed,
    tealCyan,
    rosePink,
    charcoal,
  ];

  /// Look up a preset by its [id]. Falls back to [oceanBlue].
  static AppThemePreset getById(String id) {
    return all.firstWhere((p) => p.id == id, orElse: () => oceanBlue);
  }

  /// Create a custom preset from a user-chosen primary [color].
  static AppThemePreset fromCustomColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final lighter = hsl.withLightness((hsl.lightness + 0.15).clamp(0.0, 1.0)).toColor();
    final darker = hsl.withLightness((hsl.lightness - 0.15).clamp(0.0, 1.0)).toColor();
    // Generate a complementary accent by rotating hue 180°
    final accentHsl = hsl.withHue((hsl.hue + 180.0) % 360.0);
    final accent = accentHsl.toColor();
    final accentDark = accentHsl.withLightness((accentHsl.lightness - 0.1).clamp(0.0, 1.0)).toColor();
    final accentLight = accentHsl.withLightness(0.92).toColor();

    return AppThemePreset(
      id: 'custom',
      name: 'Custom',
      emoji: '🎨',
      primary: color,
      primaryLight: lighter,
      primaryDark: darker,
      accent: accent,
      accentDark: accentDark,
      accentLight: accentLight,
    );
  }
}
