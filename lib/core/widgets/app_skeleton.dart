import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Skeleton loader for displaying loading states
class AppSkeleton extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final bool animate;

  const AppSkeleton({
    super.key,
    this.width,
    this.height = AppDimensions.spacing16,
    this.borderRadius,
    this.baseColor,
    this.highlightColor,
    this.animate = true,
  });

  const AppSkeleton.circle({
    super.key,
    required double size,
    this.baseColor,
    this.highlightColor,
    this.animate = true,
  }) : width = size,
       height = size,
       borderRadius = null;

  const AppSkeleton.text({
    super.key,
    this.width,
    double? fontSize,
    this.baseColor,
    this.highlightColor,
    this.animate = true,
  }) : height = fontSize ?? AppDimensions.fontS,
       borderRadius = null;

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.animate) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.baseColor ?? AppColors.surfaceLight;
    final highlightColor =
        widget.highlightColor ?? AppColors.white.withValues(alpha: 0.6);

    final isCircle =
        widget.borderRadius == null && widget.width == widget.height;
    final effectiveBorderRadius = isCircle
      ? BorderRadius.circular((widget.width ?? widget.height ?? AppDimensions.spacing16) / 2)
      : (widget.borderRadius ?? BorderRadius.circular(AppDimensions.radiusSmall));

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: effectiveBorderRadius,
            gradient: widget.animate
                ? LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [baseColor, highlightColor, baseColor],
                    stops: [
                      _animation.value - 0.3,
                      _animation.value,
                      _animation.value + 0.3,
                    ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
                  )
                : null,
            color: widget.animate ? null : baseColor,
          ),
        );
      },
    );
  }
}

/// Predefined skeleton layouts
class AppSkeletonCard extends StatelessWidget {
  final bool hasAvatar;
  final int lineCount;

  const AppSkeletonCard({super.key, this.hasAvatar = true, this.lineCount = 3});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (hasAvatar) ...[
                const AppSkeleton.circle(size: AppDimensions.spacing40),
                const SizedBox(width: AppDimensions.spacing12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSkeleton.text(width: hasAvatar ? 120 : double.infinity),
                    const SizedBox(height: AppDimensions.spacing8),
                    const AppSkeleton.text(width: 80, fontSize: AppDimensions.fontXs),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.spacing16),
          for (var i = 0; i < lineCount; i++) ...[
            AppSkeleton.text(width: i == lineCount - 1 ? 200 : double.infinity),
            if (i < lineCount - 1) const SizedBox(height: AppDimensions.spacing8),
          ],
        ],
      ),
    );
  }
}

class AppSkeletonListTile extends StatelessWidget {
  final bool hasLeading;
  final bool hasTrailing;

  const AppSkeletonListTile({
    super.key,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppDimensions.spacing8,
        horizontal: AppDimensions.spacing16,
      ),
      child: Row(
        children: [
          if (hasLeading) ...[
            const AppSkeleton.circle(size: AppDimensions.spacing48),
            const SizedBox(width: AppDimensions.spacing12),
          ],
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSkeleton.text(width: 150),
                SizedBox(height: AppDimensions.spacing8),
                AppSkeleton.text(width: 100, fontSize: AppDimensions.fontXs),
              ],
            ),
          ),
          if (hasTrailing) ...[
            const SizedBox(width: AppDimensions.spacing12),
            const AppSkeleton(width: 60, height: AppDimensions.spacing20),
          ],
        ],
      ),
    );
  }
}

class AppSkeletonList extends StatelessWidget {
  final int itemCount;
  final bool hasLeading;
  final bool hasTrailing;

  const AppSkeletonList({
    super.key,
    this.itemCount = 5,
    this.hasLeading = true,
    this.hasTrailing = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) =>
          AppSkeletonListTile(hasLeading: hasLeading, hasTrailing: hasTrailing),
    );
  }
}
