import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Loading overlay that covers the screen
class AppLoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const AppLoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.overlay,
            child: Center(
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusMedium,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppDimensions.paddingLarge),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                      if (message != null) ...[
                        const SizedBox(height: AppDimensions.spacing16),
                        Text(
                          message!,
                          style: TextStyle(
                            fontSize: AppDimensions.fontS,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Simple loading indicator
class AppLoadingIndicator extends StatelessWidget {
  final double? size;
  final Color? color;

  const AppLoadingIndicator({super.key, this.size, this.color});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size ?? AppDimensions.iconSizeLarge,
        height: size ?? AppDimensions.iconSizeLarge,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.primary),
          strokeWidth: 3,
        ),
      ),
    );
  }
}

/// Inline loading indicator with message
class AppInlineLoader extends StatelessWidget {
  final String message;

  const AppInlineLoader({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppDimensions.paddingMedium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(width: AppDimensions.spacing16),
          Text(
            message,
            style: TextStyle(
              fontSize: AppDimensions.fontS,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full screen loading with message
class AppFullScreenLoader extends StatelessWidget {
  final String? message;

  const AppFullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
            if (message != null) ...[
              const SizedBox(height: AppDimensions.spacing24),
              Text(
                message!,
                style: TextStyle(
                  fontSize: AppDimensions.fontM,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Button loading state
class AppButtonLoader extends StatelessWidget {
  final Color? color;
  final double size;

  const AppButtonLoader({
    super.key,
    this.color,
    this.size = AppDimensions.iconSizeSmall,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2,
        valueColor: AlwaysStoppedAnimation<Color>(color ?? AppColors.white),
      ),
    );
  }
}

/// Shimmer loading placeholder
class AppShimmer extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius = AppDimensions.radiusSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
