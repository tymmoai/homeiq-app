import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// A badge widget for displaying notifications, counts, or status indicators
class AppBadge extends StatelessWidget {
  final String? label;
  final int? count;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  final bool dot;
  final Widget? child;
  final EdgeInsets? padding;
  final BadgePosition position;

  const AppBadge({
    super.key,
    this.label,
    this.count,
    this.backgroundColor,
    this.textColor,
    this.size,
    this.dot = false,
    this.child,
    this.padding,
    this.position = BadgePosition.topRight,
  }) : assert(
         label != null || count != null || dot,
         'Either label, count, or dot must be provided',
       );

  const AppBadge.dot({
    super.key,
    this.backgroundColor,
    this.size = AppDimensions.spacing8,
    this.child,
    this.position = BadgePosition.topRight,
  }) : label = null,
       count = null,
       textColor = null,
       padding = null,
       dot = true;

  const AppBadge.count({
    super.key,
    required int this.count,
    this.backgroundColor,
    this.textColor,
    this.size,
    this.child,
    this.position = BadgePosition.topRight,
  }) : label = null,
       padding = null,
       dot = false;

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return _buildBadge();
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child!,
        Positioned(
          top: position.top,
          right: position.right,
          bottom: position.bottom,
          left: position.left,
          child: _buildBadge(),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    if (dot) {
      return Container(
        width: size ?? AppDimensions.spacing8,
        height: size ?? AppDimensions.spacing8,
        decoration: BoxDecoration(
          color: backgroundColor ?? AppColors.error,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.white, width: 1.5),
        ),
      );
    }

    final displayText =
        label ?? (count != null ? (count! > 99 ? '99+' : '$count') : '');
    final badgeSize = size ?? AppDimensions.spacing16;

    return Container(
      constraints: BoxConstraints(minWidth: badgeSize, minHeight: badgeSize),
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: badgeSize * 0.3,
            vertical: badgeSize * 0.15,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.error,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(color: AppColors.white, width: 1.5),
      ),
      child: Center(
        child: Text(
          displayText,
          style: TextStyle(
            color: textColor ?? AppColors.white,
            fontSize: badgeSize * 0.55,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Badge position configuration
class BadgePosition {
  final double? top;
  final double? right;
  final double? bottom;
  final double? left;

  const BadgePosition({this.top, this.right, this.bottom, this.left});

  static const topRight = BadgePosition(top: -4, right: -4);
  static const topLeft = BadgePosition(top: -4, left: -4);
  static const bottomRight = BadgePosition(bottom: -4, right: -4);
  static const bottomLeft = BadgePosition(bottom: -4, left: -4);
}
