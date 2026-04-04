import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../utils/responsive_utils.dart';

/// Health score card widget for overview tab
/// Displays asset health score with color-coded indicator
class HealthScoreCard extends StatelessWidget {
  final double healthScore;
  final VoidCallback? onTap;

  const HealthScoreCard({super.key, required this.healthScore, this.onTap});

  Color _getHealthColor(double score) {
    if (score >= 8.0) return AppColors.success;
    if (score >= 6.0) return AppColors.warning;
    return AppColors.error;
  }

  String _getHealthLabel(double score) {
    if (score >= 8.0) return 'Excellent';
    if (score >= 6.0) return 'Good';
    if (score >= 4.0) return 'Fair';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final healthColor = _getHealthColor(healthScore);
    final healthLabel = _getHealthLabel(healthScore);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: responsive.padding(all: AppDimensions.paddingMedium),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(
            responsive.borderRadius(AppDimensions.radiusLarge),
          ),
          boxShadow: AppShadows.standard,
        ),
        child: Row(
          children: [
            // Health Score Circle
            Container(
              width: responsive.spacing(60.0),
              height: responsive.spacing(60.0),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: healthColor.withValues(alpha: 0.1),
                border: Border.all(color: healthColor, width: 3),
              ),
              child: Center(
                child: Text(
                  healthScore.toStringAsFixed(1),
                  style: AppTextStyles.h3.copyWith(
                    fontSize: responsive.fontSize(20.0),
                    fontWeight: FontWeight.w700,
                    color: healthColor,
                  ),
                ),
              ),
            ),
            responsive.widthBox(AppDimensions.spacing16),

            // Health Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Health Score',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontSize: responsive.fontSize(12.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  responsive.heightBox(AppDimensions.spacing4),
                  Text(
                    healthLabel,
                    style: AppTextStyles.h5.copyWith(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  responsive.heightBox(AppDimensions.spacing4),
                  Text(
                    'Based on age, condition, and maintenance',
                    style: AppTextStyles.caption.copyWith(
                      fontSize: responsive.fontSize(11.0),
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: responsive.iconSize(16.0),
              color: AppColors.iconSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
