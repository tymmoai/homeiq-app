/// Centralized dimension constants for the SquareTrade / Allstate Protection Plans app
/// All screens should use these constants for consistent spacing and sizing
class AppDimensions {
  AppDimensions._(); // Private constructor to prevent instantiation

  // Spacing
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;

  // Padding
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Screen Padding
  static const double screenPaddingHorizontal = 16.0;
  static const double screenPaddingVertical = 16.0;

  // Border Radius  (SquareTrade: pill buttons, rounded cards, smooth inputs)
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  static const double radiusCircle = 999.0;

  /// Pill-shaped button radius (SquareTrade signature CTA style)
  static const double radiusPill = 50.0;

  /// Badge/chip/tag radius — dynamically updated by button layout selection.
  /// Capsule = 50 (pill), Normal = 8 (rounded rect).
  /// All widgets using this value automatically pick up the change.
  static double radiusBadge = 50.0;

  /// Update badge radius based on the active button layout mode.
  /// Called from main.dart on every rebuild, similar to AppColors.updateFromPreset.
  static void updateBadgeRadius(double newRadius) {
    radiusBadge = newRadius;
  }

  // Icon Sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeXLarge = 48.0;

  // Button Dimensions
  static const double buttonHeight = 48.0;
  static const double buttonHeightSmall = 36.0;
  static const double buttonHeightLarge = 56.0;
  static const double buttonPaddingHorizontal = 24.0;

  // Card Dimensions
  static const double cardElevation = 0.0; // We use shadows instead
  static const double cardPadding = 16.0;
  static const double cardRadius = 16.0; // SquareTrade: 15-20px rounded cards

  // Input Field Dimensions
  static const double inputHeight = 48.0;
  static const double inputPadding = 12.0;
  static const double inputRadius = 12.0; // Smooth rounded inputs

  // Divider
  static const double dividerThickness = 1.0;
  static const double dividerIndent = 0.0;

  // Avatar Sizes
  static const double avatarSizeSmall = 32.0;
  static const double avatarSizeMedium = 48.0;
  static const double avatarSizeLarge = 64.0;

  // Image Sizes
  static const double imageSizeSmall = 60.0;
  static const double imageSizeMedium = 100.0;
  static const double imageSizeLarge = 150.0;

  // Bottom Navigation Bar
  static const double bottomNavHeight = 60.0;
  static const double bottomNavIconSize = 24.0;

  // App Bar
  static const double appBarHeight = 56.0;
  static const double appBarElevation = 0.0;

  // List Tile
  static const double listTileHeight = 56.0;
  static const double listTilePadding = 16.0;

  // Font Sizes
  static const double fontXs = 12.0;
  static const double fontS = 14.0;
  static const double fontM = 16.0;
  static const double fontL = 18.0;
  static const double fontXl = 20.0;
}
