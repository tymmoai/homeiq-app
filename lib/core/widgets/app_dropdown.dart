import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Dropdown widget with consistent styling
class AppDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final String? hint;
  final String? label;
  final String? errorText;
  final bool enabled;
  final Widget? prefixIcon;

  const AppDropdown({
    super.key,
    this.value,
    required this.items,
    required this.itemLabel,
    this.onChanged,
    this.hint,
    this.label,
    this.errorText,
    this.enabled = true,
    this.prefixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: TextStyle(
              fontSize: AppDimensions.fontS,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppDimensions.spacing8),
        ],
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.disabled,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: errorText != null ? AppColors.error : AppColors.border,
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<T>(
            initialValue: value,
            items: items.map((item) {
              return DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item)),
              );
            }).toList(),
            onChanged: enabled ? onChanged : null,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: prefixIcon,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.paddingMedium,
                vertical: AppDimensions.paddingMedium,
              ),
              filled: false,
            ),
            dropdownColor: AppColors.surface,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.textSecondary,
            ),
            isExpanded: true,
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: AppDimensions.spacing4),
          Text(
            errorText!,
            style: const TextStyle(
              fontSize: AppDimensions.fontXs,
              color: AppColors.error,
            ),
          ),
        ],
      ],
    );
  }
}

/// Simple dropdown without label
class AppSimpleDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  const AppSimpleDropdown({
    super.key,
    this.value,
    required this.items,
    required this.itemLabel,
    this.onChanged,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.paddingMedium,
        vertical: AppDimensions.spacing4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButton<T>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<T>(value: item, child: Text(itemLabel(item)));
        }).toList(),
        onChanged: onChanged,
        hint: hint != null ? Text(hint!) : null,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        icon: const Icon(Icons.keyboard_arrow_down, size: 20),
      ),
    );
  }
}
