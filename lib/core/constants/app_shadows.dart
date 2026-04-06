import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Centralized shadow constants for the SquareTrade / Allstate Protection Plans app
/// SquareTrade uses very subtle, barely-there shadows (CSS: rgba(0,0,0,0.063))
class AppShadows {
  AppShadows._(); // Private constructor to prevent instantiation

  // Standard shadow used throughout the app (matching asset tab cards)
  static final List<BoxShadow> standard = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  // Light shadow for subtle elevation
  static final List<BoxShadow> light = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  // Medium shadow for cards and buttons
  static final List<BoxShadow> medium = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.1),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Heavy shadow for modals and dialogs
  static final List<BoxShadow> heavy = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.15),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  // Bottom shadow for app bar
  static final List<BoxShadow> appBar = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];

  // No shadow (for flat surfaces)
  static const List<BoxShadow> none = [];
}
