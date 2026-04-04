import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

class UpgradeProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final Map<String, dynamic> asset;

  const UpgradeProductCard({
    super.key,
    required this.product,
    required this.tradeInValue,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final Color headerColor = Theme.of(context).colorScheme.primary;
    final discountPrice = product['discountPrice'] as int;
    final originalPrice = product['price'] as int;
    final discount = product['discount'] as int;
    final badges = ((product['badges'] as List?) ?? []).cast<String>();
    final features = ((product['features'] as List?) ?? []).cast<String>();
    final monthlyPayment = product['monthlyPayment'] as int;

    return Container(
      // Slightly taller so the asset image can appear larger
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image with badge
          Expanded(
            flex: 2,
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: const BoxDecoration(
                      // Match card background so the image area blends perfectly
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: Padding(
                        // Small padding so the image is large but not touching edges
                        padding: const EdgeInsets.all(6),
                        child: Center(
                          child: _getProductImage(
                            product['name'] as String,
                            product['type'] as String? ?? '',
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Top-left badge (Top Rated/Best Seller/Recommended/New Arrival only - NOT Save X%)
                  if (badges.isNotEmpty)
                    Builder(
                      builder: (context) {
                        // Find the first badge that is NOT a "Save X%" badge
                        final statusBadge = badges.firstWhere(
                          (badge) => !badge.toLowerCase().contains('save'),
                          orElse: () => '',
                        );
                        if (statusBadge.isNotEmpty) {
                          return Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: _getBadgeColor(context, statusBadge),
                                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              ),
                              child: Text(
                                statusBadge,
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                ],
              ),
            ),
          ),
          // Product details
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Brand with Save X% badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product['brand'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      // Save X% badge in top right (always show on right side)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: headerColor.withValues(
                            alpha: 0.6,
                          ), // Lighter than Add to Cart button
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        ),
                        child: Text(
                          badges.length > 1
                              ? badges[1]
                              : 'Save ${product['discount']}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // Product name with rating
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 12, color: headerColor),
                          const SizedBox(width: 2),
                          Text(
                            '${product['rating']}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Features (minimal - 2 features)
                  ...features
                      .take(2)
                      .map(
                        (feature) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 12,
                                color: headerColor,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  feature,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  const SizedBox(height: 6),
                  // Price section
                  Divider(height: 1, color: AppColors.gray300),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '-$discount%',
                        style: TextStyle(
                          fontSize: 10,
                          color: headerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '\$$originalPrice',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$$discountPrice',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (tradeInValue > 0) ...[
                    const SizedBox(height: 2),
                    Text(
                      'After trade-in',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 3),
                  Text(
                    'or \$$monthlyPayment/month with 0% APR',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // View Details button
                  SizedBox(
                    width: double.infinity,
                    height: 40,
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/product-detail',
                          extra: {
                            'product': product,
                            'tradeInValue': tradeInValue,
                            'asset': asset,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: headerColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.zero,
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getProductIcon(String type) {
    switch (type.toLowerCase()) {
      case 'refrigerator':
        return Icons.kitchen;
      case 'microwave':
        return Icons.microwave;
      case 'dishwasher':
        return Icons.water_drop;
      case 'washing machine':
        return Icons.local_laundry_service;
      case 'air conditioner':
        return Icons.ac_unit;
      default:
        return Icons.devices_other;
    }
  }

  Widget _getProductImage(String productName, String type) {
    // Map product names to image file names
    String? imagePath;
    final nameLower = productName.toLowerCase();
    final typeLower = type.toLowerCase();

    // Refrigerators
    if (typeLower == 'refrigerator') {
      if (nameLower.contains('samsung') &&
          nameLower.contains('4-door') &&
          nameLower.contains('flex')) {
        imagePath = 'lib/asset_img/samsung 4-door flex refrigerator.jpg';
      } else if (nameLower.contains('lg') && nameLower.contains('instaview')) {
        imagePath = 'lib/asset_img/lg instaview door-in-door refrigerator.jpg';
      } else if (nameLower.contains('ge') &&
          nameLower.contains('french door')) {
        imagePath = 'lib/asset_img/GE French door refri refrigerator.jpg';
      } else if (nameLower.contains('whirlpool') &&
          nameLower.contains('french door')) {
        imagePath = 'lib/asset_img/Whirlpool French Door Refrigerator.jpg';
      } else if (nameLower.contains('frigidaire') &&
          nameLower.contains('gallery')) {
        imagePath =
            'lib/asset_img/Frrigidaire Gallery French Door Refrigerator.jpg';
      } else if (nameLower.contains('bosch') &&
          nameLower.contains('french door')) {
        imagePath = 'lib/asset_img/Refrigerator.jpg';
      }
    }
    // Washing Machines
    else if (typeLower == 'washing machine') {
      if (nameLower.contains('lg') &&
          nameLower.contains('front load') &&
          nameLower.contains('4.5')) {
        imagePath = 'lib/asset_img/LG Front Load Washer (4.5 cu ft).jpg';
      } else if (nameLower.contains('samsung') &&
          nameLower.contains('top load') &&
          nameLower.contains('5.0')) {
        imagePath = 'lib/asset_img/Samsung top load washer(5.0 cu ft).jpg';
      }
    }
    // Air Conditioners
    else if (typeLower == 'air conditioner') {
      if (nameLower.contains('daikin') && nameLower.contains('12,000')) {
        imagePath = 'lib/asset_img/Daikin 12,000 BTU Mini Split AC.jpg';
      } else if (nameLower.contains('carrier') &&
          nameLower.contains('10,000')) {
        imagePath = 'lib/asset_img/carrier 12,000 BTU Window AC.jpg';
      }
    }
    // Dishwashers
    else if (typeLower == 'dishwasher') {
      if (nameLower.contains('bosch') && nameLower.contains('300')) {
        imagePath = 'lib/asset_img/bosch 300 series dishwasher.jpg';
      } else if (nameLower.contains('ge') &&
          nameLower.contains('profile') &&
          nameLower.contains('microban')) {
        imagePath = 'lib/asset_img/GE profile Dshwasher with Microban.jpg';
      } else if (nameLower.contains('bosch')) {
        imagePath = 'lib/asset_img/bosch_dishwasher.jpg';
      }
    }

    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        // Center the full asset image inside the image area
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: double.infinity,
            color: AppColors.background,
            child: Icon(
              _getProductIcon(type),
              size: 60,
              color: AppColors.textSecondary,
            ),
          );
        },
      );
    }

    // Fallback to icon if no image found
    return Container(
      color: AppColors.background,
      child: Icon(
        _getProductIcon(type),
        size: 60,
        color: AppColors.textSecondary,
      ),
    );
  }

  Color _getBadgeColor(BuildContext context, String badgeText) {
    final headerColor = Theme.of(context).colorScheme.primary;
    final badgeLower = badgeText.toLowerCase();
    // Use highlighted colors that complement the app's dark header theme
    // These colors work well with the dark header color (#364154)
    if (badgeLower.contains('top rated')) {
      return AppColors.warning; // Amber
    } else if (badgeLower.contains('best seller')) {
      return headerColor;
    } else if (badgeLower.contains('recommended')) {
      return AppColors.purpleBadge;
    } else if (badgeLower.contains('new arrival')) {
      return AppColors.success; // Green
    }
    return headerColor; // Default to header color
  }
}