import 'package:flutter/material.dart';

/// Centralized color constants for the app.
/// ─────────────────────────────────────────────────────────────────────────────
/// **Single source of truth** – every screen must import this file instead of
/// using hard-coded Color(…) / Colors.* values.
///
/// To re-theme the entire app, change ONLY the values below.
/// ─────────────────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ══════════════════════════════════════════════════════════════════════════
  //  DYNAMIC PRIMARY BRAND PALETTE
  //  Updated at runtime when the user selects a different theme.
  // ══════════════════════════════════════════════════════════════════════════

  // Default brand values (used until a theme preset overrides them)
  static const Color _defaultPrimary = Color.fromARGB(255, 25, 41, 82);
  static const Color _defaultPrimaryLight = Color(0xFF2C4480);
  static const Color _defaultPrimaryDark = Color(0xFF0F1F45);
  static const Color _defaultAccent = Color.fromARGB(255, 201, 86, 63);
  static const Color _defaultAccentDark = Color(0xFFD4554A);
  static const Color _defaultAccentLight = Color(0xFFFDE8E4);

  /// Main brand color (header, buttons, accents)
  static Color primary = _defaultPrimary;
  static Color primaryLight = _defaultPrimaryLight;
  static Color primaryDark = _defaultPrimaryDark;

  /// Accent / CTA color (upgrade buttons, highlights)
  static Color accent = _defaultAccent;
  static Color accentDark = _defaultAccentDark;
  static Color accentLight = _defaultAccentLight;

  // Header-specific colors
  /// Background color for the app header (may differ from primary).
  static Color headerBackground = _defaultPrimary;
  /// Foreground (text/icons) color for the app header.
  static Color headerForeground = Colors.white;
  /// Search bar color that sits on the header background.
  static Color headerSearchBarColor = Colors.white;

  // Primary with opacity variants — derived from current primary
  static Color get primary05 => primary.withValues(alpha: 0.05);
  static Color get primary10 => primary.withValues(alpha: 0.10);
  static Color get primary20 => primary.withValues(alpha: 0.20);
  static Color get primary30 => primary.withValues(alpha: 0.30);
  static Color get primary50 => primary.withValues(alpha: 0.50);

  /// Call this whenever the theme preset changes to keep AppColors in sync.
  static void updateFromPreset({
    required Color newPrimary,
    required Color newPrimaryLight,
    required Color newPrimaryDark,
    required Color newAccent,
    required Color newAccentDark,
    required Color newAccentLight,
    required Brightness brightness,
  }) {
    primary = newPrimary;
    primaryLight = newPrimaryLight;
    primaryDark = newPrimaryDark;
    accent = newAccent;
    accentDark = newAccentDark;
    accentLight = newAccentLight;

    // Update header colors to match primary
    headerBackground = newPrimary;
    headerForeground = newPrimary.computeLuminance() > 0.5 ? const Color(0xFF1A1A2E) : Colors.white;

    final bool isDark = brightness == Brightness.dark;

    // Surfaces & Backgrounds
    background = isDark ? const Color(0xFF121212) : const Color(0xFFF3F6F9);
    surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    surfaceVariant = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA);
    surfaceLight = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F7FA);
    popupBackground = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8ECF4);
    backgroundSlate50 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF8FAFC);
    backgroundSlate100 = isDark ? const Color(0xFF252525) : const Color(0xFFF1F5F9);
    backgroundGray50 = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF9FAFB);
    backgroundGray100 = isDark ? const Color(0xFF252525) : const Color(0xFFF3F4F6);
    backgroundGray200 = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    backgroundWarm = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F8FA);

    // Text
    textPrimary = isDark ? Colors.white : const Color(0xFF1B3066);
    textSecondary = isDark ? const Color(0xFFB0BCC8) : const Color(0xFF4E5969);
    textTertiary = isDark ? const Color(0xFFCCD3DC) : const Color(0xFF2F3847);
    textQuaternary = isDark ? const Color(0xFF8C97A8) : const Color(0xFF6B7789);
    textHint = isDark ? const Color(0xFF6B7789) : const Color(0xFF8C97A8);
    textPlaceholder = isDark ? const Color(0xFF6B7789) : const Color(0xFF8C97A8);
    textLight = isDark ? const Color(0xFF8C97A8) : const Color(0xFF6B7789);
    textDark = isDark ? Colors.white : const Color(0xFF1B3066);
    textDisabled = isDark ? const Color(0xFF555555) : const Color(0xFFB0BCC8);

    // Borders
    border = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE4E9ED);
    borderLight = isDark ? const Color(0xFF333333) : const Color(0xFFF0F3F6);
    borderMedium = isDark ? const Color(0xFF444444) : const Color(0xFFD5DCE3);
    divider = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE4E9ED);

    // Icons
    iconPrimary = isDark ? Colors.white : const Color(0xFF1B3066);
    iconSecondary = isDark ? const Color(0xFF8C97A8) : const Color(0xFF4E5969);

    // Cards
    cardBackground = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    cardHover = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF9FAFB);

    // Buttons
    buttonPrimary = isDark ? newPrimary : const Color(0xFF1B3066);
    buttonSecondary = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF3F6F9);
    buttonDisabled = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD5DCE3);

    // Grays (adjusted for dark mode)
    lightGray = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF5F5F5);
    gray100 = isDark ? const Color(0xFF252525) : const Color(0xFFF3F4F6);
    gray200 = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    gray300 = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFD1D5DB);
    chipBackground = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF0F3F6);
    disabled = isDark ? const Color(0xFF333333) : const Color(0xFFF0F3F6);

    // Shadows
    shadow = isDark
        ? Colors.black.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.063);
    shadowLight = isDark
        ? Colors.black.withValues(alpha: 0.15)
        : Colors.black.withValues(alpha: 0.03);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  SURFACES & BACKGROUNDS
  // ══════════════════════════════════════════════════════════════════════════

  static Color background = const Color(0xFFF3F6F9);
  static Color surface = Colors.white;
  static Color surfaceVariant = const Color(0xFFF5F7FA);
  static Color surfaceLight = const Color(0xFFF5F7FA);
  static const Color surfaceDark = Color(0xFF1B3066);

  /// Popup/dialog background — very light tint of primary
  static Color popupBackground = const Color(0xFFE8ECF4);

  /// Very light tinted backgrounds used in cards, chips, etc.
  static Color backgroundSlate50 = const Color(0xFFF8FAFC);
  static Color backgroundSlate100 = const Color(0xFFF1F5F9);
  static Color backgroundGray50 = const Color(0xFFF9FAFB);
  static Color backgroundGray100 = const Color(0xFFF3F4F6);
  static Color backgroundGray200 = const Color(0xFFF5F5F5);
  static Color backgroundWarm = const Color(0xFFF7F8FA);

  // ══════════════════════════════════════════════════════════════════════════
  //  TEXT  (Navy-based, NOT pure black)
  // ══════════════════════════════════════════════════════════════════════════

  static Color textPrimary = const Color(0xFF1B3066);
  static Color textSecondary = const Color(0xFF4E5969);
  static Color textTertiary = const Color(0xFF2F3847);
  static Color textQuaternary = const Color(0xFF6B7789);
  static Color textHint = const Color(0xFF8C97A8);
  static Color textPlaceholder = const Color(0xFF8C97A8);
  static Color textLight = const Color(0xFF6B7789);
  static Color textDark = const Color(0xFF1B3066);
  static Color textDisabled = const Color(0xFFB0BCC8);
  static const Color textOnPrimary = Colors.white;

  // Slate text palette
  static const Color slate400 = Color(0xFF8C97A8);
  static const Color slate500 = Color(0xFF6B7789);
  static const Color slate600 = Color(0xFF4E5969);
  static const Color slate700 = Color(0xFF2F3847);
  static const Color slate800 = Color(0xFF1A2540);
  static const Color slate900 = Color(0xFF1B3066);

  // ══════════════════════════════════════════════════════════════════════════
  //  STATUS / SEMANTIC COLORS
  // ══════════════════════════════════════════════════════════════════════════

  // Success
  static const Color success = Color(0xFF10B981);
  static const Color successDark = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color successBackground = Color(0xFFD1FAE5);
  static const Color successSoft = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successMaterial = Color(0xFF4CAF50);
  static const Color successMaterialDark = Color(0xFF2E7D32);
  static const Color successMaterialAccent = Color(0xFF43A047);
  static const Color successMaterialLight = Color(0xFF22C55E);

  // Warning
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFFF3E0);
  static const Color warningBackground = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFE65100);
  static const Color warningAmber = Color(0xFFFBBF24);
  static const Color warningOrange = Color(0xFFF57C00);
  static const Color warningOrangeLight = Color(0xFFFFB74D);
  static const Color warningBrown = Color(0xFF92400E);
  static const Color warningBrownDark = Color(0xFF78350F);
  static const Color warningYellowBg = Color(0xFFFFFBEB);
  static const Color warningYellowBorder = Color(0xFFFDE68A);
  static const Color warningYellowLight = Color(0xFFFFF9C4);
  static const Color warningGold = Color(0xFFFFB800);
  static const Color warningAmberDark = Color(0xFFD97706);
  static const Color warningMaterial = Color(0xFFFFC107);
  static const Color warningMaterialDark = Color(0xFFF57F17);

  // Error
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFC62828);
  static const Color errorSoft = Color(0xFFFEF2F2);
  static const Color errorBorder = Color(0xFFFECACA);
  static const Color errorMild = Color(0xFFF87171);
  static const Color errorMaterialDark = Color.fromARGB(255, 214, 71, 52);
  static const Color errorMaterialAccent = Color.fromARGB(255, 207, 78, 58);
  static const Color errorFee = Color(0xFFFEE2E2);

  // Info
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1D4ED8);
  static const Color infoAccent = Color(0xFF2563EB);
  static const Color infoBackground = Color(0xFFEFF6FF);
  static const Color infoBorder = Color(0xFFBFDBFE);
  static const Color infoDarkest = Color(0xFF0D47A1);

  // Amber
  static const Color amber = Color(0xFFFBBF24);

  // ══════════════════════════════════════════════════════════════════════════
  //  SECONDARY
  // ══════════════════════════════════════════════════════════════════════════

  static const Color secondary = Color(0xFFEC7766);

  // ══════════════════════════════════════════════════════════════════════════
  //  BORDERS & DIVIDERS
  // ══════════════════════════════════════════════════════════════════════════

  static Color border = const Color(0xFFE4E9ED);
  static Color borderLight = const Color(0xFFF0F3F6);
  static Color borderMedium = const Color(0xFFD5DCE3);
  static Color divider = const Color(0xFFE4E9ED);

  // ══════════════════════════════════════════════════════════════════════════
  //  GRAYS
  // ══════════════════════════════════════════════════════════════════════════

  static Color lightGray = const Color(0xFFF5F5F5);
  static Color gray100 = const Color(0xFFF3F4F6);
  static Color gray200 = const Color(0xFFE5E7EB);
  static Color gray300 = const Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);
  static const Color grayMedium = Color(0xFF9E9E9E);
  static const Color slateLabel = Color(0xFF64748B);
  static const Color purpleBadge = Color(0xFF8B5CF6);

  // ══════════════════════════════════════════════════════════════════════════
  //  ICONS
  // ══════════════════════════════════════════════════════════════════════════

  static Color iconPrimary = const Color(0xFF1B3066);
  static Color iconSecondary = const Color(0xFF4E5969);
  static const Color iconDisabled = Color(0xFFB0BCC8);
  static const Color iconOnPrimary = Colors.white;

  // ══════════════════════════════════════════════════════════════════════════
  //  BUTTONS
  // ══════════════════════════════════════════════════════════════════════════

  static Color buttonPrimary = const Color(0xFF1B3066);
  static Color buttonSecondary = const Color(0xFFF3F6F9);
  static Color buttonDisabled = const Color(0xFFD5DCE3);

  // ══════════════════════════════════════════════════════════════════════════
  //  CARDS
  // ══════════════════════════════════════════════════════════════════════════

  static Color cardBackground = Colors.white;
  static const Color cardSelected = Color(0xFF1B3066);
  static Color cardHover = const Color(0xFFF9FAFB);

  // ══════════════════════════════════════════════════════════════════════════
  //  SHADOWS & OVERLAYS
  // ══════════════════════════════════════════════════════════════════════════

  static Color shadow = Colors.black.withValues(alpha: 0.063);
  static Color shadowLight = Colors.black.withValues(alpha: 0.03);
  static final Color shadowMedium = Colors.black.withValues(alpha: 0.05);
  static final Color shadowDark = Colors.black.withValues(alpha: 0.08);
  static final Color shadowHeavy = Colors.black.withValues(alpha: 0.12);
  static final Color overlay = Colors.black.withValues(alpha: 0.5);
  static final Color overlayLight = Colors.black.withValues(alpha: 0.12);
  static const Color transparent = Colors.transparent;
  static const Color white = Colors.white;
  static const Color black = Colors.black;

  // ══════════════════════════════════════════════════════════════════════════
  //  GRADIENTS
  // ══════════════════════════════════════════════════════════════════════════

  static const List<Color> primaryGradient = [
    Color(0xFF1B3066),
    Color(0xFF2C4480),
  ];

  /// Primary → Accent gradient for hero / splash areas
  static const List<Color> heroGradient = [
    Color(0xFF1B3066),
    Color(0xFFEC7766),
  ];

  // ══════════════════════════════════════════════════════════════════════════
  //  SERVICE / ASSET CATEGORY COLORS
  // ══════════════════════════════════════════════════════════════════════════

  static const Color appliances = Color(0xFF4A90E2);
  static const Color plumbing = Color(0xFF50C878);
  static const Color electrical = Color(0xFFF5A623);
  static const Color hvac = Color(0xFFE74C3C);
  static const Color structural = Color(0xFF9B59B6);
  static const Color exterior = Color(0xFF3498DB);
  static const Color safety = Color(0xFFE67E22);
  static const Color other = Color(0xFF95A5A6);

  // ══════════════════════════════════════════════════════════════════════════
  //  SPECIAL / MISC
  // ══════════════════════════════════════════════════════════════════════════

  static Color disabled = const Color(0xFFF0F3F6);
  static const Color disabledText = Color(0xFF8C97A8);

  /// Purple accents (feature icons, badges)
  static const Color purple = Color(0xFFC265FC);
  static const Color purpleLight = Color(0xFFF3E5F5);
  static const Color purpleDark = Color(0xFF9B45E0);

  /// Pink accent
  static const Color pink = Color(0xFFE91E63);

  /// Teal / Cyan
  static const Color teal = Color(0xFF00BCD4);

  /// Star / Rating gold
  static const Color ratingGold = Color(0xFFFFB800);

  /// Chip / Tag backgrounds
  static Color chipBackground = const Color(0xFFF0F3F6);

  /// Dark navy (splash, branding)
  static const Color navy = Color(0xFF1B3066);
  static const Color navyLight = Color(0xFF2C4480);

  /// Brown shade (warranty)
  static const Color brown = Color(0xFF795548);

  /// Input dark text
  static const Color inputDark = Color(0xFF2F3847);
  static const Color inputIcon = Color(0xFF4E5969);
}
