import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../utils/responsive_utils.dart';

/// Info item widget for displaying asset details
/// Shows label and value with consistent styling
class AssetInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? valueColor;
  final bool showBorder;

  const AssetInfoItem({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.valueColor,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      padding: responsive.padding(all: AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(
          responsive.borderRadius(AppDimensions.radiusMedium),
        ),
        border: showBorder
            ? Border.all(color: AppColors.border, width: 1)
            : null,
        boxShadow: !showBorder ? AppShadows.light : null,
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: responsive.iconSize(20.0),
              color: AppColors.iconSecondary,
            ),
            responsive.widthBox(AppDimensions.spacing12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontSize: responsive.fontSize(12.0),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(AppDimensions.spacing4),
                Text(
                  value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontSize: responsive.fontSize(14.0),
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid info item for displaying info in a compact grid layout
class AssetGridInfoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const AssetGridInfoItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            fontSize: responsive.fontSize(12.0),
            color: AppColors.textSecondary,
          ),
        ),
        responsive.heightBox(AppDimensions.spacing4),
        Text(
          value,
          style: AppTextStyles.bodyMedium.copyWith(
            fontSize: responsive.fontSize(14.0),
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
