import 'package:flutter/material.dart';

import '../../../core/constants/app_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../utils/responsive_utils.dart';

/// Snackbar utility for showing messages
class AppSnackbar {
  AppSnackbar._();

  /// Show success message
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.success,
      icon: Icons.check_circle,
      duration: duration,
    );
  }

  /// Show error message
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.error,
      icon: Icons.error,
      duration: duration,
    );
  }

  /// Show warning message
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.warning,
      icon: Icons.warning,
      duration: duration,
    );
  }

  /// Show info message
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: AppColors.info,
      icon: Icons.info,
      duration: duration,
    );
  }

  /// Show custom message
  static void show(
    BuildContext context,
    String message, {
    Color? backgroundColor,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
  }) {
    _show(
      context,
      message: message,
      backgroundColor: backgroundColor ?? AppColors.primary,
      icon: icon,
      duration: duration,
    );
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    IconData? icon,
    required Duration duration,
  }) {
    final responsive = ResponsiveUtils(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: AppColors.textOnPrimary,
                size: responsive.iconSize(AppDimensions.iconSizeMedium),
              ),
              SizedBox(width: responsive.spacing(AppDimensions.spacing12)),
            ],
            Expanded(
              child: Text(
                message,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: responsive.fontSize(14.0),
                  color: AppColors.textOnPrimary,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            responsive.borderRadius(AppDimensions.radiusMedium),
          ),
        ),
        duration: duration,
        margin: EdgeInsets.all(responsive.spacing(AppDimensions.spacing16)),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(AppDimensions.paddingMedium),
          vertical: responsive.spacing(AppDimensions.paddingSmall),
        ),
        animation: CurvedAnimation(
          parent: kAlwaysCompleteAnimation,
          curve: AppAnimations.defaultCurve,
        ),
      ),
    );
  }
}

/// Bottom sheet utility for showing modal bottom sheets
class AppBottomSheet {
  AppBottomSheet._();

  /// Show a modal bottom sheet with custom content
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
  }) {
    final responsive = ResponsiveUtils(context);

    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor ?? AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(
            responsive.borderRadius(AppDimensions.radiusLarge),
          ),
        ),
      ),
      builder: (context) => Padding(
        padding: responsive.padding(all: AppDimensions.paddingMedium),
        child: child,
      ),
    );
  }

  /// Show a bottom sheet with a list of options
  static Future<T?> showOptions<T>({
    required BuildContext context,
    required String title,
    required List<BottomSheetOption<T>> options,
    bool showCancel = true,
  }) {
    final responsive = ResponsiveUtils(context);

    return show<T>(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Title
          Text(
            title,
            style: AppTextStyles.h5.copyWith(
              fontSize: responsive.fontSize(18.0),
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          responsive.heightBox(AppDimensions.spacing16),

          // Options
          ...options.map(
            (option) => ListTile(
              leading: option.icon != null
                  ? Icon(
                      option.icon,
                      color: option.textColor ?? AppColors.iconPrimary,
                      size: responsive.iconSize(AppDimensions.iconSizeMedium),
                    )
                  : null,
              title: Text(
                option.title,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: responsive.fontSize(16.0),
                  color: option.textColor ?? AppColors.textPrimary,
                ),
              ),
              onTap: () {
                Navigator.pop(context, option.value);
              },
            ),
          ),

          // Cancel button
          if (showCancel) ...[
            responsive.heightBox(AppDimensions.spacing8),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: responsive.padding(
                  vertical: AppDimensions.paddingMedium,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(AppDimensions.radiusMedium),
                  ),
                ),
              ),
              child: Text(
                'Cancel',
                style: AppTextStyles.button.copyWith(
                  fontSize: responsive.fontSize(16.0),
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet option model
class BottomSheetOption<T> {
  final String title;
  final T value;
  final IconData? icon;
  final Color? textColor;

  const BottomSheetOption({
    required this.title,
    required this.value,
    this.icon,
    this.textColor,
  });
}
