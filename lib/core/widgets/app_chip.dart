import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// A customizable chip widget for filters, tags, and selections
class AppChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final Widget? avatar;
  final Color? backgroundColor;
  final Color? selectedBackgroundColor;
  final Color? textColor;
  final Color? selectedTextColor;
  final EdgeInsets? padding;
  final double? borderRadius;
  final BorderSide? border;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.onDelete,
    this.avatar,
    this.backgroundColor,
    this.selectedBackgroundColor,
    this.textColor,
    this.selectedTextColor,
    this.padding,
    this.borderRadius,
    this.border,
  });

  const AppChip.filter({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.avatar,
  })  : onDelete = null,
        backgroundColor = null,
        selectedBackgroundColor = null,
        textColor = null,
        selectedTextColor = null,
        padding = null,
        borderRadius = null,
        border = null;

  const AppChip.choice({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  })  : onDelete = null,
        avatar = null,
        backgroundColor = null,
        selectedBackgroundColor = null,
        textColor = null,
        selectedTextColor = null,
        padding = null,
        borderRadius = null,
        border = null;

  const AppChip.deletable({
    super.key,
    required this.label,
    required this.onDelete,
    this.avatar,
  })  : selected = false,
        onTap = null,
        backgroundColor = null,
        selectedBackgroundColor = null,
        textColor = null,
        selectedTextColor = null,
        padding = null,
        borderRadius = null,
        border = null;

  @override
  Widget build(BuildContext context) {
    final effectiveBackgroundColor = selected
        ? (selectedBackgroundColor ?? AppColors.primary)
        : (backgroundColor ?? AppColors.surfaceLight);

    final effectiveTextColor = selected
        ? (selectedTextColor ?? AppColors.white)
        : (textColor ?? AppColors.textPrimary);

    return Material(
      color: AppColors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusBadge),
        child: Container(
          padding: padding ?? const EdgeInsets.symmetric(
            horizontal: AppDimensions.spacing12,
            vertical: AppDimensions.spacing4,
          ),
          decoration: BoxDecoration(
            color: effectiveBackgroundColor,
            borderRadius: BorderRadius.circular(borderRadius ?? AppDimensions.radiusBadge),
            border: border as BoxBorder? ?? Border.all(
              color: selected ? (selectedBackgroundColor ?? AppColors.primary) : AppColors.border,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (avatar != null) ...[
                avatar!,
                const SizedBox(width: AppDimensions.spacing8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: effectiveTextColor,
                  fontSize: AppDimensions.fontS,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
              if (onDelete != null) ...[
                const SizedBox(width: AppDimensions.spacing4),
                GestureDetector(
                  onTap: onDelete,
                  child: Icon(
                    Icons.close,
                    size: AppDimensions.iconSizeSmall,
                    color: effectiveTextColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Wrap multiple chips with proper spacing
class AppChipGroup extends StatelessWidget {
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;
  final WrapCrossAlignment crossAlignment;

  const AppChipGroup({
    super.key,
    required this.children,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
    this.crossAlignment = WrapCrossAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: crossAlignment,
      children: children,
    );
  }
}
