import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import '../utils/responsive_utils.dart';

/// Centralized configuration for all app headers
///
/// This class provides a single source of truth for header styling throughout the app.
/// To change any header property (height, color, text style, etc.), modify values here.
///
/// Special behaviors:
/// - Home tab: Starts with a tall header that shrinks on scroll
/// - Other tabs: Fixed compact headers with consistent styling
class AppHeaderConfig {
  // ============================================
  // HEADER COLORS
  // ============================================

  /// Standard header background color (used in most screens)
  /// Kept as static fallback â€” prefer [backgroundColorOf] for dynamic theming.
  static final Color backgroundColor = AppColors.primary;

  /// Dynamic background color from the current theme.
  static Color backgroundColorOf(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Header text color (white for visibility on colored background)
  static const Color foregroundColor = AppColors.white;

  /// Header icon color
  static const Color iconColor = AppColors.white;

  /// Header shadow color
  static Color shadowColor = AppColors.shadowHeavy;

  // ============================================
  // HEADER DIMENSIONS
  // ============================================

  /// Standard compact header height (for fixed headers)
  /// This is the content height WITHOUT status bar
  static const double compactHeaderHeight = 32.0;

  /// Header padding (top and bottom)
  static const double headerPaddingVertical = 14.0;

  /// Header padding (left and right)
  static const double headerPaddingHorizontal = 20.0;

  /// Home tab: Full expanded header content height
  static const double homeFullHeaderHeight = 140.0;

  /// Home tab: Scroll threshold (pixels to scroll before header fully collapses)
  static const double homeScrollThreshold = 120.0;

  // ============================================
  // TYPOGRAPHY
  // ============================================

  /// Standard header title text style
  static TextStyle titleStyle(ResponsiveUtils responsive) {
    return TextStyle(
      fontSize: responsive.fontSize(20.0),
      fontWeight: FontWeight.w700,
      color: foregroundColor,
      letterSpacing: -0.3,
    );
  }

  /// Compact header title text style (slightly smaller)
  static TextStyle compactTitleStyle(ResponsiveUtils responsive) {
    return TextStyle(
      fontSize: responsive.fontSize(18.0),
      fontWeight: FontWeight.w700,
      color: foregroundColor,
    );
  }

  /// Home tab: Large header title style
  static TextStyle homeLargeTitleStyle(
    ResponsiveUtils responsive,
    double screenWidth,
  ) {
    final fontSize = screenWidth < 360
        ? 16.0
        : screenWidth < 400
        ? 18.0
        : 20.0;
    return TextStyle(
      fontSize: responsive.fontSize(fontSize),
      fontWeight: FontWeight.w700,
      color: foregroundColor,
      letterSpacing: -0.3,
    );
  }

  // ============================================
  // ELEVATION & SHADOW
  // ============================================

  /// Header elevation/shadow
  static const double elevation = 4.0;

  /// Box shadow for headers
  static List<BoxShadow> get boxShadow => [
    BoxShadow(color: shadowColor, blurRadius: 8.0, offset: const Offset(0, 2)),
  ];

  // ============================================
  // ICON SIZES
  // ============================================

  /// Back button icon size
  static double backIconSize(ResponsiveUtils responsive) =>
      responsive.iconSize(24.0);

  /// Action button icon size (menu, notifications, etc.)
  static double actionIconSize(ResponsiveUtils responsive) =>
      responsive.iconSize(22.0);

  /// Profile avatar size
  static double profileAvatarSize(ResponsiveUtils responsive) =>
      responsive.iconSize(40.0);

  // ============================================
  // BUILDERS - Standard Header Components
  // ============================================

  /// Build a standard app bar (for use with Scaffold's appBar property)
  ///
  /// Example:
  /// ```dart
  /// appBar: AppHeaderConfig.buildStandardAppBar(
  ///   context: context,
  ///   title: 'Screen Title',
  /// ),
  /// ```
  static PreferredSizeWidget buildStandardAppBar({
    required BuildContext context,
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool centerTitle = false,
    SystemUiOverlayStyle? systemOverlayStyle,
  }) {
    final responsive = ResponsiveUtils(context);

    return AppBar(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      elevation: elevation,
      systemOverlayStyle: systemOverlayStyle ?? SystemUiOverlayStyle.light,
      centerTitle: centerTitle,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      title: Text(title, style: compactTitleStyle(responsive)),
      actions: actions,
    );
  }

  /// Build a custom fixed header container (for use with Stack/Positioned)
  ///
  /// Example:
  /// ```dart
  /// AppHeaderConfig.buildFixedHeader(
  ///   context: context,
  ///   child: Text('Header Content'),
  /// )
  /// ```
  static Widget buildFixedHeader({
    required BuildContext context,
    required Widget child,
    double? height,
    EdgeInsets? padding,
  }) {
    // Use an explicit height so every tab header is identical regardless of
    // child intrinsic height (e.g. PopupMenuButton enforces a 48 px minimum
    // touch-target that would otherwise make the Assets header taller than the
    // Maintenance header).
    final containerHeight =
        height ?? (compactHeaderHeight + headerPaddingVertical * 2);
    return Material(
      elevation: elevation,
      color: AppColors.transparent,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: containerHeight,
          decoration: BoxDecoration(
            color: backgroundColorOf(context),
            boxShadow: boxShadow,
          ),
          padding:
              padding ??
              const EdgeInsets.symmetric(
                horizontal: headerPaddingHorizontal,
                vertical: headerPaddingVertical,
              ),
          child: child,
        ),
      ),
    );
  }

  /// Build a back button widget
  static Widget buildBackButton(
    BuildContext context, {
    VoidCallback? onPressed,
  }) {
    final responsive = ResponsiveUtils(context);

    return GestureDetector(
      onTap:
          onPressed ??
          () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
      child: Icon(
        Icons.arrow_back,
        color: iconColor,
        size: backIconSize(responsive),
      ),
    );
  }

  /// Calculate total header height including status bar and padding
  static double getTotalHeaderHeight(
    BuildContext context, {
    double? contentHeight,
  }) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final content = contentHeight ?? compactHeaderHeight;
    return statusBarHeight + headerPaddingVertical * 2 + content;
  }

  /// Calculate status bar height
  static double getStatusBarHeight(BuildContext context) {
    return MediaQuery.of(context).padding.top;
  }

  // ============================================
  // HOME TAB SPECIFIC - Dynamic Header Behavior
  // ============================================

  /// Calculate home tab header height based on scroll offset
  ///
  /// Returns the interpolated height between full and compact based on scroll progress
  static double calculateHomeHeaderHeight(
    BuildContext context,
    double scrollOffset,
  ) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final scrollProgress = (scrollOffset / homeScrollThreshold).clamp(0.0, 1.0);

    final currentContentHeight =
        homeFullHeaderHeight * (1 - scrollProgress) +
        compactHeaderHeight * scrollProgress;

    return statusBarHeight + currentContentHeight;
  }

  /// Get scroll progress (0.0 to 1.0) for home tab header transition
  static double getHomeScrollProgress(double scrollOffset) {
    return (scrollOffset / homeScrollThreshold).clamp(0.0, 1.0);
  }

  /// Build home tab animated header container
  ///
  /// This creates the special home tab header that shrinks on scroll
  static Widget buildHomeTabHeader({
    required BuildContext context,
    required double scrollOffset,
    required Widget fullHeader,
    required Widget compactHeader,
  }) {
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final scrollProgress = getHomeScrollProgress(scrollOffset);
    final currentHeaderHeight = calculateHomeHeaderHeight(
      context,
      scrollOffset,
    );

    return Material(
      elevation: elevation,
      color: AppColors.transparent,
      child: SafeArea(
        bottom: false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          height: currentHeaderHeight - statusBarHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            boxShadow: boxShadow,
          ),
          padding: const EdgeInsets.fromLTRB(
            headerPaddingHorizontal,
            headerPaddingVertical - 2,
            headerPaddingHorizontal,
            headerPaddingVertical - 2,
          ),
          child: ClipRect(
            clipBehavior: Clip.hardEdge,
            child: _buildHeaderTransition(
              scrollProgress: scrollProgress,
              fullHeader: fullHeader,
              compactHeader: compactHeader,
            ),
          ),
        ),
      ),
    );
  }

  /// Internal: Build the crossfade transition between full and compact headers
  static Widget _buildHeaderTransition({
    required double scrollProgress,
    required Widget fullHeader,
    required Widget compactHeader,
  }) {
    final transitionCurve = Curves.easeInOutCubic.transform(scrollProgress);

    // Show full header when scroll is minimal
    if (scrollProgress < 0.05) {
      return fullHeader;
    }

    // Show compact header when scroll is near complete
    if (scrollProgress > 0.95) {
      return compactHeader;
    }

    // During transition, crossfade between the two
    return Stack(
      clipBehavior: Clip.hardEdge,
      fit: StackFit.expand,
      children: [
        // Full header - fades out
        Positioned.fill(
          child: Opacity(
            opacity: (1 - transitionCurve).clamp(0.0, 1.0),
            child: IgnorePointer(
              ignoring: transitionCurve > 0.3,
              child: fullHeader,
            ),
          ),
        ),
        // Compact header - fades in
        Positioned.fill(
          child: Opacity(
            opacity: transitionCurve.clamp(0.0, 1.0),
            child: IgnorePointer(
              ignoring: transitionCurve < 0.7,
              child: compactHeader,
            ),
          ),
        ),
      ],
    );
  }
}
