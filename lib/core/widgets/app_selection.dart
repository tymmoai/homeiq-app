import 'package:flutter/material.dart';

import '../../../utils/responsive_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Grid of selectable option cards
class AppOptionGrid<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedValue;
  final String Function(T) getLabel;
  final IconData Function(T)? getIcon;
  final ValueChanged<T> onSelected;
  final int crossAxisCount;
  final double childAspectRatio;

  const AppOptionGrid({
    super.key,
    required this.options,
    this.selectedValue,
    required this.getLabel,
    this.getIcon,
    required this.onSelected,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: responsive.spacing(AppDimensions.spacing16),
        mainAxisSpacing: responsive.spacing(AppDimensions.spacing16),
        childAspectRatio: childAspectRatio,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = option == selectedValue;

        return AppOptionCard(
          label: getLabel(option),
          icon: getIcon?.call(option),
          isSelected: isSelected,
          onTap: () => onSelected(option),
        );
      },
    );
  }
}

/// Single selectable option card
class AppOptionCard extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final double? height;
  final double? width;

  const AppOptionCard({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsive.spacing(AppDimensions.radiusMedium)),
      child: Container(
        height: height,
        width: width,
        padding: EdgeInsets.all(responsive.spacing(AppDimensions.paddingMedium)),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardSelected : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(responsive.spacing(AppDimensions.radiusMedium)),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: responsive.iconSize(32),
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
              SizedBox(height: responsive.spacing(AppDimensions.spacing8)),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(AppDimensions.fontS),
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// List of selectable option cards
class AppOptionList<T> extends StatelessWidget {
  final List<T> options;
  final T? selectedValue;
  final String Function(T) getLabel;
  final String? Function(T)? getSubtitle;
  final IconData Function(T)? getIcon;
  final ValueChanged<T> onSelected;

  const AppOptionList({
    super.key,
    required this.options,
    this.selectedValue,
    required this.getLabel,
    this.getSubtitle,
    this.getIcon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        final isSelected = option == selectedValue;

        return Padding(
          padding: const EdgeInsets.only(bottom: AppDimensions.spacing8),
          child: InkWell(
            onTap: () => onSelected(option),
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            child: Container(
              padding: const EdgeInsets.all(AppDimensions.paddingMedium),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.cardSelected : AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  if (getIcon != null) ...[
                    Icon(
                      getIcon!(option),
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 24,
                    ),
                    const SizedBox(width: AppDimensions.spacing16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          getLabel(option),
                          style: TextStyle(
                            fontSize: AppDimensions.fontM,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        if (getSubtitle != null && getSubtitle!(option) != null) ...[
                          const SizedBox(height: AppDimensions.spacing4),
                          Text(
                            getSubtitle!(option)!,
                            style: TextStyle(
                              fontSize: AppDimensions.fontS,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.primary,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

