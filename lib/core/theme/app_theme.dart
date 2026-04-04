import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../providers/button_layout_provider.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';
import 'app_theme_presets.dart';

/// Centralized theme configuration for the SquareTrade / Allstate Protection Plans app
class AppTheme {
  AppTheme._(); // Private constructor to prevent instantiation

  /// Current button layout mode — updated from [main.dart] on every rebuild.
  static ButtonLayoutMode _buttonLayout = ButtonLayoutMode.capsule;

  /// Expose button radius so widgets that don't use the theme directly
  /// (e.g. custom painters, manual Container decorations) can query it.
  static double get buttonRadius => _buttonLayout.buttonRadius;
  static double get badgeRadius => _buttonLayout.badgeRadius;

  /// Build a [ThemeData] from an [AppThemePreset].
  /// This is the primary entry point used by [main.dart].
  static ThemeData fromPreset(AppThemePreset preset,
      {ButtonLayoutMode layout = ButtonLayoutMode.capsule}) {
    _buttonLayout = layout;
    final bool isDark = preset.brightness == Brightness.dark;

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: preset.primary,
            secondary: preset.accent,
            surface: preset.surface,
            error: AppColors.error,
            onPrimary: const Color(0xFF121212),
            onSecondary: Colors.white,
            onSurface: Colors.white,
            onError: Colors.white,
          )
        : ColorScheme.light(
            primary: preset.primary,
            secondary: preset.accent,
            surface: preset.surface,
            error: AppColors.error,
            onPrimary: preset.textOnPrimary,
            onSecondary: preset.textOnPrimary,
            onSurface: preset.textPrimary,
            onError: Colors.white,
          );

    return _buildTheme(preset, colorScheme, isDark, _buttonLayout);
  }

  /// Legacy getter — kept so existing code that references
  /// [AppTheme.lightTheme] keeps compiling. Uses the default navy preset.
  static ThemeData get lightTheme => fromPreset(AppThemePresets.defaultNavy);

  // ────────────────────────────────────────────────────────────────────────
  // Private builder
  // ────────────────────────────────────────────────────────────────────────

  static ThemeData _buildTheme(
    AppThemePreset p,
    ColorScheme colorScheme,
    bool isDark,
    ButtonLayoutMode layout,
  ) {
    final double btnRadius = layout.buttonRadius;
    return ThemeData(
      // Font Family
      fontFamily: AppTextStyles.fontFamily,
      brightness: p.brightness,

      // Primary Colors
      primaryColor: p.primary,
      scaffoldBackgroundColor: p.background,
      canvasColor: p.surface,
      
      // Color Scheme
      colorScheme: colorScheme,

      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: AppDimensions.appBarElevation,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: p.iconPrimary,
          size: AppDimensions.iconSizeMedium,
        ),
        titleTextStyle: AppTextStyles.h4.copyWith(color: p.textPrimary),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: p.primary,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.light,
          statusBarBrightness: isDark ? Brightness.light : Brightness.dark,
        ),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: p.cardBackground,
        elevation: AppDimensions.cardElevation,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.cardRadius)),
        ),
        margin: const EdgeInsets.all(0),
      ),

      // Button Themes — shape adapts to ButtonLayoutMode
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.buttonPrimary,
          foregroundColor: p.textOnPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontal,
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.primary,
          side: BorderSide(color: p.primary, width: 1.5),
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.buttonPaddingHorizontal,
            vertical: AppDimensions.paddingMedium,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnRadius),
          ),
          textStyle: AppTextStyles.button.copyWith(color: p.primary),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(btnRadius),
          ),
          textStyle: AppTextStyles.button.copyWith(color: p.primary),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.all(AppDimensions.inputPadding),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: BorderSide(color: p.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: BorderSide(color: p.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.inputRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        hintStyle: AppTextStyles.hint,
        labelStyle: AppTextStyles.label,
        errorStyle: AppTextStyles.error,
      ),

      // Icon Theme
      iconTheme: IconThemeData(
        color: p.iconPrimary,
        size: AppDimensions.iconSizeMedium,
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: p.divider,
        thickness: AppDimensions.dividerThickness,
        indent: AppDimensions.dividerIndent,
        endIndent: AppDimensions.dividerIndent,
      ),

      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.surface,
        selectedItemColor: p.primary,
        unselectedItemColor: p.iconSecondary,
        selectedLabelStyle: AppTextStyles.captionBold,
        unselectedLabelStyle: AppTextStyles.caption,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        elevation: 8,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusLarge)),
        ),
        titleTextStyle: AppTextStyles.h4.copyWith(color: p.textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: p.textSecondary),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: p.primary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(
          color: p.textOnPrimary,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceVariant,
        disabledColor: AppColors.buttonDisabled,
        selectedColor: p.primary,
        secondarySelectedColor: p.primaryLight,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.paddingSmall,
          vertical: AppDimensions.spacing4,
        ),
        labelStyle: AppTextStyles.bodySmall,
        secondaryLabelStyle: AppTextStyles.bodySmall.copyWith(
          color: p.textOnPrimary,
        ),
        brightness: p.brightness,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layout.badgeRadius),
        ),
      ),

      // Text Theme
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1.copyWith(color: p.textPrimary),
        displayMedium: AppTextStyles.h2.copyWith(color: p.textPrimary),
        displaySmall: AppTextStyles.h3.copyWith(color: p.textPrimary),
        headlineMedium: AppTextStyles.h4.copyWith(color: p.textPrimary),
        headlineSmall: AppTextStyles.h5.copyWith(color: p.textPrimary),
        titleLarge: AppTextStyles.h5.copyWith(color: p.textPrimary),
        titleMedium: AppTextStyles.h6.copyWith(color: p.textPrimary),
        titleSmall: AppTextStyles.label.copyWith(color: p.textSecondary),
        bodyLarge: AppTextStyles.bodyLarge.copyWith(color: p.textPrimary),
        bodyMedium: AppTextStyles.bodyMedium.copyWith(color: p.textSecondary),
        bodySmall: AppTextStyles.bodySmall.copyWith(color: p.textSecondary),
        labelLarge: AppTextStyles.button,
        labelMedium: AppTextStyles.label.copyWith(color: p.textSecondary),
        labelSmall: AppTextStyles.labelSmall.copyWith(color: p.textSecondary),
      ),

      // Tooltip Theme
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: p.primaryDark,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        textStyle: AppTextStyles.bodySmall.copyWith(
          color: p.textOnPrimary,
        ),
      ),

      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.primary,
      ),

      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.accent;
          }
          return isDark ? const Color(0xFF555555) : AppColors.borderLight;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.accentLight;
          }
          return p.border;
        }),
      ),

      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary;
          }
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(p.textOnPrimary),
        side: BorderSide(color: p.border, width: 2),
      ),

      // Radio Theme
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return p.primary;
          }
          return p.border;
        }),
      ),

      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: p.primary,
        inactiveTrackColor: p.border,
        thumbColor: p.primary,
        overlayColor: p.primary.withValues(alpha: 0.3),
      ),
    );
  }
}
