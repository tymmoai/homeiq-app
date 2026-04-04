import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import 'app_skeleton.dart';

/// Source codes returned by the backend image resolution endpoint.
/// Mirrors the TypeScript `ImageFetchResult` reason union.
enum ImageSource {
  /// A real product photo was found via SerpAPI.
  serpapi,

  /// SerpAPI search limit / quota was reached on our account.
  quotaExceeded,

  /// The SerpAPI key is missing or invalid.
  authError,

  /// The search completed but no matching product photo was found.
  noResults,

  /// The request to SerpAPI timed out.
  timeout,

  /// A network error prevented the request from reaching SerpAPI.
  networkError,

  /// Catch-all for unknown / legacy values.
  unknown;

  static ImageSource fromString(String? raw) {
    switch (raw) {
      case 'serpapi':
        return ImageSource.serpapi;
      case 'quota_exceeded':
        return ImageSource.quotaExceeded;
      case 'auth_error':
        return ImageSource.authError;
      case 'no_results':
        return ImageSource.noResults;
      case 'timeout':
        return ImageSource.timeout;
      case 'network_error':
        return ImageSource.networkError;
      default:
        return ImageSource.unknown;
    }
  }

  /// Returns true when the source indicates a usable image URL exists.
  bool get hasImage => this == ImageSource.serpapi;

  /// Short, US-friendly explanation shown inside the image placeholder area.
  String get userMessage {
    switch (this) {
      case ImageSource.quotaExceeded:
        return 'Product photos are temporarily unavailable.\nYou can add one later.';
      case ImageSource.authError:
        return 'Photo search is currently unavailable.\nYou can add a photo manually.';
      case ImageSource.timeout:
        return 'Photo search timed out — please check\nyour connection and try again.';
      case ImageSource.networkError:
        return 'Couldn\'t reach the photo service.\nCheck your connection and try again.';
      case ImageSource.noResults:
        return 'No product photo found.\nYou can add one manually.';
      default:
        return 'No photo available.';
    }
  }

  IconData get fallbackIcon => Icons.image_search_rounded;
}

/// Responsive asset product image with:
///   • Shimmer skeleton while loading
///   • `BoxFit.contain` so image is never distorted (product image best practice)
///   • Contextual no-image state: shows the reason (quota, no results, etc.)
///     instead of a misleading random placeholder
///   • Fallback icon when URL is null/empty or image fails to load
///   • Lazy-loading via `Image.network` with `loadingBuilder`
///
/// Usage:
///   AssetImageWidget(imageUrl: asset['productImageUrl'], assetType: 'Refrigerator')
///   AssetImageWidget(imageUrl: null, imageSource: ImageSource.fromString(formData.productImageSource))
class AssetImageWidget extends StatelessWidget {
  final String? imageUrl;
  final String? assetType;

  /// Pass the `productImageSource` from formData / asset map so the widget can
  /// explain why no photo is shown instead of displaying a blank icon.
  final ImageSource? imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;

  const AssetImageWidget({
    super.key,
    this.imageUrl,
    this.assetType,
    this.imageSource,
    this.width,
    this.height = 180,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? AppColors.surfaceLight;
    final effectiveRadius =
        borderRadius ?? BorderRadius.circular(AppDimensions.radiusMedium);

    final url = (imageUrl ?? '').trim();

    return ClipRRect(
      borderRadius: effectiveRadius,
      child: Container(
        width: width,
        height: height,
        color: effectiveBg,
        child: url.isEmpty
            ? _buildFallback()
            : Image.network(
                url,
                width: width,
                height: height,
                fit: fit,
                // Show shimmer skeleton WHILE the image bytes load
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return AppSkeleton(
                    width: width,
                    height: height,
                    borderRadius: effectiveRadius,
                  );
                },
                // Show fallback icon if network image fails
                errorBuilder: (context, error, stackTrace) => _buildFallback(),
                // Enable caching via Flutter's default image cache.
                // Guard against double.infinity — toInt() throws on Infinity/NaN.
                cacheWidth: (width != null && width!.isFinite)
                    ? (width! * 2).toInt()
                    : null,
                cacheHeight: (height != null && height!.isFinite)
                    ? (height! * 2).toInt()
                    : null,
              ),
      ),
    );
  }

  Widget _buildFallback() {
    // If we know why there's no image, show an informative message.
    final src = imageSource;
    final bool hasReason =
        src != null && !src.hasImage && src != ImageSource.unknown;

    if (hasReason) {
      return _buildNoImageState(src);
    }

    // Generic fallback: asset-type icon + label
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _iconForAssetType(assetType),
            size: (height ?? 180) * 0.35,
            color: AppColors.textSecondary.withValues(alpha: 0.4),
          ),
          if (assetType != null) ...[
            const SizedBox(height: 8),
            Text(
              assetType!,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Informative no-image state — shown when we know the reason (quota, timeout, etc.)
  Widget _buildNoImageState(ImageSource src) {
    final h = height ?? 180;
    final isCompact = h < 100;

    // Quota or auth error: use a warm amber tone to hint at a service issue
    final bool isServiceError =
        src == ImageSource.quotaExceeded ||
        src == ImageSource.authError ||
        src == ImageSource.networkError ||
        src == ImageSource.timeout;

    final Color iconColor = isServiceError
        ? const Color(0xFFF59E0B) // amber-400
        : AppColors.textSecondary.withValues(alpha: 0.45);
    final Color bgTint = isServiceError
        ? const Color(0xFFFFFBEB) // amber-50
        : AppColors.backgroundGray50;

    return Container(
      decoration: BoxDecoration(
        color: bgTint,
        borderRadius:
            borderRadius ?? BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 8 : 16,
            vertical: isCompact ? 4 : 12,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isServiceError
                    ? Icons.cloud_off_rounded
                    : Icons.image_search_rounded,
                size: h * (isCompact ? 0.28 : 0.22),
                color: iconColor,
              ),
              if (!isCompact) ...[
                const SizedBox(height: 8),
                Text(
                  src.userMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.5,
                    color: AppColors.textSecondary.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForAssetType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('refrigerator') || t.contains('fridge')) {
      return Icons.kitchen;
    }
    if (t.contains('washer') || t.contains('washing')) {
      return Icons.local_laundry_service;
    }
    if (t.contains('dryer')) {
      return Icons.local_laundry_service_outlined;
    }
    if (t.contains('dishwasher')) {
      return Icons.countertops;
    }
    if (t.contains('tv') || t.contains('television')) {
      return Icons.tv_rounded;
    }
    if (t.contains('laptop') || t.contains('computer')) {
      return Icons.laptop_mac_rounded;
    }
    if (t.contains('phone') || t.contains('mobile')) {
      return Icons.smartphone_rounded;
    }
    if (t.contains('router') || t.contains('wifi')) {
      return Icons.router_rounded;
    }
    if (t.contains('printer')) {
      return Icons.print_rounded;
    }
    if (t.contains('camera')) {
      return Icons.videocam_rounded;
    }
    if (t.contains('speaker') || t.contains('audio')) {
      return Icons.speaker_group_rounded;
    }
    if (t.contains('oven') || t.contains('microwave')) {
      return Icons.microwave_rounded;
    }
    if (t.contains('ac') || t.contains('hvac') || t.contains('air')) {
      return Icons.ac_unit_rounded;
    }
    return Icons.devices_other_rounded;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Specialised skeleton cards for different loading contexts
// ─────────────────────────────────────────────────────────────────────────────

/// Skeleton loader for the asset detail image area (Overview tab).
class AssetImageSkeleton extends StatelessWidget {
  final double height;
  final double? width;

  const AssetImageSkeleton({super.key, this.height = 180, this.width});

  @override
  Widget build(BuildContext context) {
    return AppSkeleton(
      width: width,
      height: height,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
    );
  }
}

/// Skeleton loader for AI response content (3 text lines + a label row).
class AiResponseSkeleton extends StatelessWidget {
  const AiResponseSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header chip skeleton
          AppSkeleton(
            width: 120,
            height: 28,
            borderRadius: BorderRadius.circular(20),
          ),
          const SizedBox(height: 16),
          // Label + value rows (Issue / Cause / Solution / Cost / DIY)
          for (var i = 0; i < 5; i++) ...[
            const Row(
              children: [
                AppSkeleton(width: 90, height: 12),
                SizedBox(width: 12),
                Expanded(child: AppSkeleton(height: 12)),
              ],
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          // Action buttons skeleton
          Row(
            children: [
              Expanded(
                child: AppSkeleton(
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppSkeleton(
                  height: 40,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for a full asset card (used in the assets list while loading).
class AssetCardSkeleton extends StatelessWidget {
  const AssetCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          // Image placeholder
          AppSkeleton(
            width: 56,
            height: 56,
            borderRadius: BorderRadius.circular(10),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppSkeleton(width: 140, height: 14),
                const SizedBox(height: 6),
                const AppSkeleton(width: 100, height: 11),
                const SizedBox(height: 8),
                Row(
                  children: [
                    AppSkeleton(
                      width: 60,
                      height: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    const SizedBox(width: 8),
                    AppSkeleton(
                      width: 70,
                      height: 20,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSkeleton(
            width: 32,
            height: 32,
            borderRadius: BorderRadius.circular(8),
          ),
        ],
      ),
    );
  }
}

/// Full-page skeleton for screens where all content is loading.
class PageLoadingSkeleton extends StatelessWidget {
  final int cardCount;

  const PageLoadingSkeleton({super.key, this.cardCount = 4});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cardCount,
      itemBuilder: (context, index) => const AssetCardSkeleton(),
    );
  }
}
