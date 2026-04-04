import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_text_styles.dart';
import '../../utils/responsive_utils.dart';

/// Loading indicator widget
class AppLoadingIndicator extends StatelessWidget {
  final String? message;
  final double? size;

  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size ?? responsive.iconSize(AppDimensions.iconSizeLarge),
            height: size ?? responsive.iconSize(AppDimensions.iconSizeLarge),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: responsive.spacing(AppDimensions.spacing16)),
            Text(
              message!,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: responsive.fontSize(AppDimensions.fontS),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Error display widget
class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(AppDimensions.spacing24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: responsive.iconSize(AppDimensions.iconSizeXLarge),
              color: AppColors.error,
            ),
            SizedBox(height: responsive.spacing(AppDimensions.spacing16)),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: responsive.fontSize(AppDimensions.fontS),
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: responsive.spacing(AppDimensions.spacing24)),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state widget
class AppEmptyState extends StatelessWidget {
  final String message;
  final IconData? icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const AppEmptyState({
    super.key,
    required this.message,
    this.icon,
    this.onAction,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(AppDimensions.spacing24)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.inbox_outlined,
              size: responsive.iconSize(AppDimensions.iconSizeXLarge),
              color: AppColors.textHint,
            ),
            SizedBox(height: responsive.spacing(AppDimensions.spacing16)),
            Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                fontSize: responsive.fontSize(AppDimensions.fontS),
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (onAction != null && actionLabel != null) ...[
              SizedBox(height: responsive.spacing(AppDimensions.spacing24)),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}






