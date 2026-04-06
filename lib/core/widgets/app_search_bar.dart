import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/responsive_utils.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// A customizable search bar widget
class AppSearchBar extends StatefulWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final Widget? leading;
  final List<Widget>? actions;
  final bool autofocus;
  final bool enabled;
  final Color? backgroundColor;
  final double? height;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  const AppSearchBar({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.leading,
    this.actions,
    this.autofocus = false,
    this.enabled = true,
    this.backgroundColor,
    this.height,
    this.padding,
    this.borderRadius,
    this.keyboardType,
    this.inputFormatters,
    this.focusNode,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = widget.focusNode ?? FocusNode();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    }
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
    widget.onChanged?.call('');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      height: widget.height ?? responsive.spacing(AppDimensions.inputHeight),
      padding:
          widget.padding ??
          responsive.padding(
            horizontal: AppDimensions.paddingMedium,
            vertical: AppDimensions.paddingSmall,
          ),
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? AppColors.surfaceLight,
        borderRadius:
            widget.borderRadius ??
            BorderRadius.circular(
              responsive.borderRadius(AppDimensions.radiusMedium),
            ),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          widget.leading ??
              Icon(
                Icons.search,
                color: AppColors.textSecondary,
                size: responsive.iconSize(AppDimensions.iconSizeMedium),
              ),
          SizedBox(width: responsive.spacing(AppDimensions.spacing12)),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              enabled: widget.enabled,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              style: TextStyle(
                fontSize: responsive.fontSize(AppDimensions.fontS),
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: widget.hintText ?? 'Search...',
                hintStyle: TextStyle(
                  fontSize: responsive.fontSize(AppDimensions.fontS),
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
            ),
          ),
          if (_hasText) ...[
            SizedBox(width: responsive.spacing(AppDimensions.spacing8)),
            GestureDetector(
              onTap: _clearText,
              child: Icon(
                Icons.close,
                color: AppColors.textSecondary,
                size: responsive.iconSize(AppDimensions.iconSizeSmall),
              ),
            ),
          ],
          if (widget.actions != null) ...[
            SizedBox(width: responsive.spacing(AppDimensions.spacing8)),
            ...widget.actions!,
          ],
        ],
      ),
    );
  }
}

/// A search bar with filter button
class AppSearchBarWithFilter extends StatelessWidget {
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onFilterTap;
  final bool hasActiveFilters;

  const AppSearchBarWithFilter({
    super.key,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppSearchBar(
      hintText: hintText,
      controller: controller,
      onChanged: onChanged,
      actions: [
        GestureDetector(
          onTap: onFilterTap,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.tune,
                color: AppColors.textSecondary,
                size: AppDimensions.iconSizeMedium,
              ),
              if (hasActiveFilters)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    width: AppDimensions.spacing8,
                    height: AppDimensions.spacing8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
