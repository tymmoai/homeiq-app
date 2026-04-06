import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// A customizable avatar widget for user profiles, assets, or entities
class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? name;
  final double size;
  final Color? backgroundColor;
  final Color? textColor;
  final Widget? badge;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;
  final bool showBorder;
  final Color? borderColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
    this.badge,
    this.borderRadius,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  });

  const AppAvatar.circle({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
    this.badge,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  }) : borderRadius = null;

  const AppAvatar.square({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.backgroundColor,
    this.textColor,
    this.badge,
    double? radius,
    this.onTap,
    this.showBorder = false,
    this.borderColor,
    this.borderWidth = 2,
  }) : borderRadius = null;

  @override
  Widget build(BuildContext context) {
    final isCircle = borderRadius == null;
    final effectiveBorderRadius = isCircle
        ? BorderRadius.circular(size / 2)
        : (borderRadius ?? BorderRadius.circular(AppDimensions.radiusSmall));

    Widget avatarWidget = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? _generateColorFromName(name),
        borderRadius: effectiveBorderRadius,
        border: showBorder
            ? Border.all(
                color: borderColor ?? AppColors.white,
                width: borderWidth,
              )
            : null,
        image: imageUrl != null && imageUrl!.isNotEmpty
            ? DecorationImage(image: NetworkImage(imageUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: imageUrl == null || imageUrl!.isEmpty
          ? Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  color: textColor ?? AppColors.white,
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : null,
    );

    if (badge != null) {
      avatarWidget = Stack(
        clipBehavior: Clip.none,
        children: [
          avatarWidget,
          Positioned(right: -2, bottom: -2, child: badge!),
        ],
      );
    }

    if (onTap != null) {
      avatarWidget = InkWell(
        onTap: onTap,
        borderRadius: effectiveBorderRadius,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
  }

  Color _generateColorFromName(String? name) {
    if (name == null || name.isEmpty) return AppColors.primary;

    final colors = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      AppColors.info,
      AppColors.purple,
      AppColors.pink,
      AppColors.teal,
    ];

    final hash = name.hashCode;
    return colors[hash.abs() % colors.length];
  }
}

/// Avatar group for displaying multiple avatars
class AppAvatarGroup extends StatelessWidget {
  final List<String?> imageUrls;
  final List<String?> names;
  final double size;
  final int maxVisible;
  final double overlap;

  const AppAvatarGroup({
    super.key,
    this.imageUrls = const [],
    this.names = const [],
    this.size = 32,
    this.maxVisible = 3,
    this.overlap = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    final total = imageUrls.length > names.length
        ? imageUrls.length
        : names.length;
    final visible = total > maxVisible ? maxVisible : total;
    final remaining = total - visible;

    return SizedBox(
      height: size,
      width:
          size +
          (visible - 1) * size * (1 - overlap) +
          (remaining > 0 ? size : 0),
      child: Stack(
        children: [
          for (var i = 0; i < visible; i++)
            Positioned(
              left: i * size * (1 - overlap),
              child: AppAvatar.circle(
                imageUrl: i < imageUrls.length ? imageUrls[i] : null,
                name: i < names.length ? names[i] : null,
                size: size,
                showBorder: true,
                borderWidth: 2,
              ),
            ),
          if (remaining > 0)
            Positioned(
              left: visible * size * (1 - overlap),
              child: Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.white, width: 2),
                ),
                child: Center(
                  child: Text(
                    '+$remaining',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
