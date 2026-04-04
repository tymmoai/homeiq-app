import 'package:flutter/material.dart';

/// Centralized animation constants for the SquareTrade app
/// All screens should use these constants for consistent animations
class AppAnimations {
  AppAnimations._(); // Private constructor to prevent instantiation

  // Animation Durations
  static const Duration instant = Duration(milliseconds: 0);
  static const Duration veryFast = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Specific Use Case Durations
  static const Duration buttonPress = fast;
  static const Duration dialogFade = medium;
  static const Duration pageTransition = medium;
  static const Duration cardExpand = medium;
  static const Duration shimmerPeriod = Duration(milliseconds: 1500);
  static const Duration loadingIndicator = Duration(milliseconds: 1000);

  // Animation Curves
  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve emphasizedCurve = Curves.fastOutSlowIn;
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve bouncy = Curves.elasticOut;
  static const Curve sharp = Curves.easeInOutCubic;
  static const Curve smooth = Curves.easeInOutQuad;
  static const Curve decelerate = Curves.decelerate;

  // Page Transition Settings
  static const Duration pageTransitionDuration = medium;
  static const Curve pageTransitionCurve = defaultCurve;

  // Opacity Animations
  static const Duration fadeIn = fast;
  static const Duration fadeOut = fast;
  static const Curve fadeCurve = easeOut;

  // Scale Animations
  static const double scaleMin = 0.95;
  static const double scaleMax = 1.05;
  static const Duration scaleDuration = fast;

  // Slide Animations
  static const Duration slideDuration = medium;
  static const Curve slideCurve = defaultCurve;

  // Rotation Animations
  static const Duration rotationDuration = medium;
  static const Curve rotationCurve = defaultCurve;
}
