import 'package:flutter/material.dart';

/// Responsive utility class for adaptive UI across different screen sizes
class ResponsiveUtils {
  final BuildContext context;
  
  ResponsiveUtils(this.context);
  
  // Screen dimensions
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  
  // Device type detection
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 900;
  bool get isDesktop => screenWidth >= 900;
  
  bool get isSmallMobile => screenWidth < 360;
  bool get isMediumMobile => screenWidth >= 360 && screenWidth < 400;
  bool get isLargeMobile => screenWidth >= 400 && screenWidth < 600;
  
  // Responsive sizing methods
  double wp(double percentage) => screenWidth * (percentage / 100);
  double hp(double percentage) => screenHeight * (percentage / 100);
  
  // Responsive spacing
  double spacing(double baseValue) {
    if (isSmallMobile) return baseValue * 0.75;
    if (isMediumMobile) return baseValue * 0.85;
    if (isLargeMobile) return baseValue;
    if (isTablet) return baseValue * 1.2;
    return baseValue * 1.5; // Desktop
  }
  
  // Responsive padding
  EdgeInsets padding({
    double? all,
    double? horizontal,
    double? vertical,
    double? left,
    double? top,
    double? right,
    double? bottom,
  }) {
    if (all != null) {
      return EdgeInsets.all(spacing(all));
    }
    return EdgeInsets.only(
      left: spacing(left ?? horizontal ?? 0),
      top: spacing(top ?? vertical ?? 0),
      right: spacing(right ?? horizontal ?? 0),
      bottom: spacing(bottom ?? vertical ?? 0),
    );
  }
  
  // Responsive font sizes
  double fontSize(double baseSize) {
    if (isSmallMobile) return baseSize * 0.85;
    if (isMediumMobile) return baseSize * 0.92;
    if (isLargeMobile) return baseSize;
    if (isTablet) return baseSize * 1.1;
    return baseSize * 1.2; // Desktop
  }
  
  // Responsive icon sizes
  double iconSize(double baseSize) {
    if (isSmallMobile) return baseSize * 0.8;
    if (isMediumMobile) return baseSize * 0.9;
    if (isLargeMobile) return baseSize;
    if (isTablet) return baseSize * 1.15;
    return baseSize * 1.3; // Desktop
  }
  
  // Responsive border radius
  double borderRadius(double baseRadius) {
    if (isSmallMobile) return baseRadius * 0.8;
    if (isMediumMobile) return baseRadius * 0.9;
    return baseRadius;
  }
  
  // Responsive button height
  double buttonHeight(double baseHeight) {
    if (isSmallMobile) return baseHeight * 0.85;
    if (isMediumMobile) return baseHeight * 0.92;
    if (isLargeMobile) return baseHeight;
    if (isTablet) return baseHeight * 1.1;
    return baseHeight * 1.2; // Desktop
  }
  
  // Responsive card dimensions
  double cardWidth({double maxWidth = 600}) {
    if (isMobile) return screenWidth - spacing(32.0);
    if (isTablet) return screenWidth * 0.7;
    return maxWidth;
  }
  
  // Grid columns based on screen size
  int gridColumns({int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (isMobile) return mobile;
    if (isTablet) return tablet;
    return desktop;
  }
  
  // Responsive image size
  double imageSize(double baseSize) {
    if (isSmallMobile) return baseSize * 0.75;
    if (isMediumMobile) return baseSize * 0.85;
    if (isLargeMobile) return baseSize;
    if (isTablet) return baseSize * 1.2;
    return baseSize * 1.5; // Desktop
  }
  
  // Get responsive text style
  TextStyle textStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    TextDecoration? decoration,
  }) {
    return TextStyle(
      fontSize: this.fontSize(fontSize),
      fontWeight: fontWeight,
      color: color,
      height: height,
      decoration: decoration,
    );
  }
  
  // Responsive SizedBox
  SizedBox heightBox(double height) => SizedBox(height: spacing(height));
  SizedBox widthBox(double width) => SizedBox(width: spacing(width));
  
  // Responsive aspect ratio for images/cards
  double aspectRatio({required String type}) {
    switch (type) {
      case 'card':
        return isMobile ? 1.5 : 2.0;
      case 'banner':
        return isMobile ? 2.5 : 3.5;
      case 'square':
        return 1.0;
      case 'portrait':
        return 0.75;
      default:
        return 1.0;
    }
  }
}

// Extension for easy access
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}

// Responsive breakpoints constants
class ScreenBreakpoints {
  static const double mobileSmall = 360;
  static const double mobileMedium = 400;
  static const double mobileLarge = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

// Responsive builder widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ResponsiveUtils responsive) builder;
  
  const ResponsiveBuilder({super.key, required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return builder(context, ResponsiveUtils(context));
  }
}

