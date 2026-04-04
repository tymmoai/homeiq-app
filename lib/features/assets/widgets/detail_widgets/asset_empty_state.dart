import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../utils/responsive_utils.dart';

/// Empty state widget for asset detail screen
/// Shows message when no data is available
class AssetEmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;

  const AssetEmptyState({
    super.key,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Center(
      child: Padding(
        padding: responsive.padding(all: AppDimensions.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: responsive.iconSize(64.0),
              color: AppColors.iconSecondary,
            ),
            responsive.heightBox(AppDimensions.spacing16),
            Text(
              message,
              style: AppTextStyles.bodyLarge.copyWith(
                fontSize: responsive.fontSize(14.0),
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionText != null && onAction != null) ...[
              responsive.heightBox(AppDimensions.spacing24),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: responsive.padding(
                    horizontal: AppDimensions.paddingLarge,
                    vertical: AppDimensions.paddingMedium,
                  ),
                ),
                child: Text(
                  actionText!,
                  style: AppTextStyles.button.copyWith(
                    fontSize: responsive.fontSize(14.0),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
