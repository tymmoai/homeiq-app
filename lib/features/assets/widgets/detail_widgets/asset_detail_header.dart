import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../utils/responsive_utils.dart';

/// Header widget for asset detail screen
/// Shows back button, asset name, and scroll-sensitive styling
class AssetDetailHeader extends StatelessWidget {
  final String assetName;
  final bool isScrolledDown;
  final VoidCallback onBackPressed;

  const AssetDetailHeader({
    super.key,
    required this.assetName,
    required this.isScrolledDown,
    required this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: responsive.padding(
        horizontal: AppDimensions.screenPaddingHorizontal,
        vertical: AppDimensions.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: isScrolledDown ? AppColors.surface : Colors.transparent,
        boxShadow: isScrolledDown
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: onBackPressed,
            icon: Icon(
              Icons.arrow_back,
              color: AppColors.iconPrimary,
              size: responsive.iconSize(AppDimensions.iconSizeMedium),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          responsive.widthBox(AppDimensions.spacing12),

          // Asset Name
          Expanded(
            child: Text(
              assetName,
              style: AppTextStyles.h4.copyWith(
                fontSize: responsive.fontSize(isScrolledDown ? 16.0 : 18.0),
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
