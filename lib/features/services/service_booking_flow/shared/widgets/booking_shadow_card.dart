import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

/// Shared shadow card container used across all booking steps.
///
/// Provides the standard card styling with no border and shadow effect
/// matching the app theme.
class BookingShadowCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;

  const BookingShadowCard({
    super.key,
    required this.child,
    this.padding,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? context.responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary05 : AppColors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(12.0),
        ),
        border: isSelected
            ? Border.all(color: AppColors.primary, width: 2)
            : null,
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}
