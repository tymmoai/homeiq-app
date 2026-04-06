import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_shadows.dart';
import '../../utils/responsive_utils.dart';

/// Reusable card widget with consistent styling (SquareTrade: 16px rounded)
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final VoidCallback? onTap;
  final double? borderRadius;
  final List<BoxShadow>? shadows;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.onTap,
    this.borderRadius,
    this.shadows,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    final content = Container(
      padding:
          padding ??
          EdgeInsets.all(responsive.spacing(AppDimensions.cardPadding)),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.cardBackground,
        borderRadius: BorderRadius.circular(
          borderRadius ?? responsive.spacing(AppDimensions.cardRadius),
        ),
        boxShadow: shadows ?? AppShadows.standard,
        border: border,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          borderRadius ?? responsive.spacing(AppDimensions.cardRadius),
        ),
        child: content,
      );
    }

    return content;
  }
}

/// Selection card widget (like in service selection)
class SelectionCard extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;
  final Widget? child;
  final double? height;
  final double? width;

  const SelectionCard({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
    this.child,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
      child: Container(
        height: height,
        width: width,
        padding: EdgeInsets.all(responsive.spacing(12)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardSelected : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(responsive.spacing(12)),
          boxShadow: AppShadows.standard,
        ),
        child:
            child ??
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(
                    icon,
                    size: responsive.iconSize(32),
                    color: isSelected
                        ? AppColors.iconOnPrimary
                        : AppColors.iconPrimary,
                  ),
                if (icon != null) SizedBox(height: responsive.spacing(8)),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? AppColors.textOnPrimary
                        : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
      ),
    );
  }
}
