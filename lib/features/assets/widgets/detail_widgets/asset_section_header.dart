import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../utils/responsive_utils.dart';

/// Section header widget used throughout asset detail screens
/// Provides consistent styling for section titles
class AssetSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  const AssetSectionHeader({
    super.key,
    required this.title,
    this.trailing,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Padding(
      padding: padding ??
          responsive.padding(
            horizontal: AppDimensions.screenPaddingHorizontal,
            vertical: AppDimensions.paddingSmall,
          ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTextStyles.h5.copyWith(
              fontSize: responsive.fontSize(16.0),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
