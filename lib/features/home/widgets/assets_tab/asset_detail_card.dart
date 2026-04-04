import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/asset_image_widget.dart';
import '../../../../core/widgets/warranty_status_badge.dart';

class AssetDetailCard extends StatelessWidget {
  final Map<String, dynamic> asset;
  final List<Map<String, dynamic>> allAssets;

  const AssetDetailCard({
    super.key,
    required this.asset,
    required this.allAssets,
  });

  @override
  Widget build(BuildContext context) {
    final healthScore = (asset['healthScore'] as num?)?.toDouble() ?? 8.0;

    // Determine status based on health score (matching WEB logic)
    // Always calculate from health score, ignore the 'status' field in asset data
    final String status;
    if (healthScore >= 8) {
      status = 'good';
    } else if (healthScore >= 6) {
      status = 'warning';
    } else {
      status = 'critical';
    }

    // Get status badge text and color
    final String statusText;
    final Color statusBgColor;
    final Color statusTextColor;
    if (status == 'good') {
      statusText = 'Good';
      statusBgColor = AppColors.successLight; // green-50
      statusTextColor = AppColors.successMaterialDark; // green-800
    } else if (status == 'warning') {
      statusText = 'Needs Attention';
      statusBgColor = AppColors.warningYellowLight; // yellow-100
      statusTextColor = AppColors.warningMaterialDark; // yellow-800
    } else {
      statusText = 'Critical';
      statusBgColor = AppColors.errorLight; // red-50
      statusTextColor = AppColors.errorDark; // red-800
    }

    // Get health score color (consistent with asset detail screen)
    final Color healthScoreColor;
    if (healthScore >= 8) {
      healthScoreColor =
          AppColors.successMaterial; // Success green (matches asset detail)
    } else if (healthScore >= 6) {
      healthScoreColor = Colors.orange; // Warning orange (matches asset detail)
    } else {
      healthScoreColor =
          AppColors.errorMaterialAccent; // Error red (matches asset detail)
    }

    // Check for upgrade/replacement info
    final replacedAssetName = asset['replacedAssetName']?.toString();
    final replacedByAssetName = asset['replacedByAssetName']?.toString();
    final lifecycleStatus = asset['lifecycleStatus']?.toString() ?? 'active';
    final isReplaced = lifecycleStatus == 'replaced';
    
    // Format purchase date: prefer full ISO date (purchasedAt), fall back to formatted text
    final purchaseDate = _formatPurchaseDate(
      purchasedAt: asset['purchasedAt']?.toString(),
      purchaseDate: asset['purchaseDate']?.toString(),
      purchaseYear: asset['purchaseYear'],
      purchaseMonth: asset['purchaseMonth'],
    );
    final lastService = asset['lastService']?.toString() ?? 'Never';

    // Check if upgrade is available (health score < 6.6, but not for replaced assets)
    final bool upgradeAvailable = healthScore < 6.6 && !isReplaced;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Main Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Row: UPGRADED Badge, Image, Name+Model, Status Badge
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left side: UPGRADED or REPLACED Badge + Asset Image
                        Column(
                          children: [
                            // UPGRADED Badge (for assets that replaced another)
                            if (replacedAssetName != null && !isReplaced)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.purpleLight,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusBadge,
                                  ),
                                  border: Border.all(
                                    color: AppColors.purple.withValues(
                                      alpha: 0.3,
                                    ),
                                    width: 1,
                                  ),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.upgrade,
                                      size: 12,
                                      color: AppColors.purple,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Upgraded',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purple,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // REPLACED Badge (for assets that have been replaced)
                            if (isReplaced && replacedByAssetName != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusBadge,
                                  ),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Replaced',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            // Asset Image
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.backgroundGray200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _getAssetImage(
                                  asset['type']?.toString() ?? '',
                                  asset['image']?.toString() ?? '',
                                  productImageUrl: asset['productImageUrl']
                                      ?.toString(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Right side: Asset Name, Model, Health
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name and Status Badge
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      asset['name'] as String,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusBgColor,
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusBadge,
                                      ),
                                    ),
                                    child: Text(
                                      statusText.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: statusTextColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Brand Name
                              Text(
                                asset['brand'] as String? ?? 'Unknown Brand',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              // Model / Serial Number – show model if available, fall back to serial number
                              Builder(
                                builder: (context) {
                                  final model =
                                      (asset['model'] as String? ?? '').trim();
                                  final serial =
                                      (asset['serial'] as String? ?? '').trim();
                                  final display = model.isNotEmpty
                                      ? 'Model: $model'
                                      : serial.isNotEmpty
                                      ? 'SN: $serial'
                                      : null;
                                  if (display == null) {
                                    return const SizedBox.shrink();
                                  }
                                  return Text(
                                    display,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              // Location – show N/A when not defined
                              Builder(
                                builder: (context) {
                                  final loc =
                                      (asset['location'] as String? ?? '')
                                          .trim();
                                  return Text(
                                    'Location: ${loc.isEmpty ? 'N/A' : loc}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),
                              // Health Section
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'HEALTH SCORE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade600,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      Text(
                                        '${healthScore.toStringAsFixed(1)}/10',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  // Health Progress Bar
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: healthScore / 10,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        healthScoreColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bottom Info Row: Last Service, Purchase, Warranty
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'LAST SERVICE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastService,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PURCHASE',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                purchaseDate,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WARRANTY',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              WarrantyStatusBadge.fromAsset(
                                asset: asset,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Upgraded from info
                    if (replacedAssetName != null && !isReplaced) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                // Find the old asset and navigate to it
                                final replacedAssetId =
                                    asset['replacedAssetId'];
                                if (replacedAssetId != null) {
                                  final oldAsset = allAssets.firstWhere(
                                    (a) =>
                                        a['id'].toString() ==
                                        replacedAssetId.toString(),
                                    orElse: () => asset,
                                  );
                                  context.push(
                                    '/asset-detail',
                                    extra: oldAsset,
                                  );
                                }
                              },
                              child: Row(
                                children: [
                                  Text(
                                    'Upgraded from: ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      replacedAssetName,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.purple,
                                        decoration: TextDecoration.underline,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              context.push('/asset-detail', extra: asset);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Replaced by info (for replaced assets)
                    if (isReplaced && replacedByAssetName != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text(
                            'Replaced by: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Flexible(
                            child: Text(
                              replacedByAssetName,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              context.push('/asset-detail', extra: asset);
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'DETAILS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 10,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Upgrade Available Button or VIEW DETAILS Button (but not for replaced assets)
              if (!isReplaced && upgradeAvailable)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            context.push('/upgrade-offer', extra: asset);
                          },
                          icon: const Icon(
                            Icons.upgrade,
                            color: Colors.white,
                            size: 20,
                          ),
                          label: const Text(
                            'Upgrade Available',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: Colors.white,
                            elevation: 2,
                            shadowColor: AppColors.accent.withValues(
                              alpha: 0.3,
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          context.push('/asset-detail', extra: asset);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else if (!isReplaced && replacedAssetName == null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          context.push('/asset-detail', extra: asset);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'DETAILS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // (DETAILS link for replaced assets is inside the 'Replaced by' row above)
            ],
          ),
        ],
      ),
    );
  }

  Widget _getAssetImage(
    String type,
    String imageKey, {
    String? productImageUrl,
  }) {
    // Prefer the real product image from the database (BestBuy / Barcode API)
    if (productImageUrl != null &&
        productImageUrl.isNotEmpty &&
        Uri.tryParse(productImageUrl)?.hasScheme == true) {
      // Use AssetImageWidget which provides skeleton loading + proper BoxFit.contain
      return AssetImageWidget(
        imageUrl: productImageUrl,
        assetType: type,
        width: double.infinity,
        height: 80,
        fit: BoxFit.contain,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        backgroundColor: Colors.transparent,
      );
    }

    return _getLocalAssetImage(type);
  }

  Widget _getLocalAssetImage(String type) {
    // Map asset types to image paths
    String imagePath;
    switch (type.toLowerCase()) {
      case 'refrigerator':
        imagePath = 'lib/asset_img/Refrigerator.jpg';
        break;
      case 'washing machine':
        imagePath = 'lib/asset_img/Washing_Machine.jpg';
        break;
      case 'air conditioner':
        imagePath = 'lib/asset_img/AC.webp';
        break;
      case 'microwave':
        imagePath = 'lib/asset_img/Oven.jpg'; // Using Oven.jpg for microwave
        break;
      case 'dishwasher':
        imagePath = 'lib/asset_img/bosch_dishwasher.jpg';
        break;
      case 'television':
        imagePath = 'lib/asset_img/TV.jpg';
        break;
      case 'router':
        imagePath = 'lib/asset_img/Router.jpg';
        break;
      case 'water heater':
        imagePath = 'lib/asset_img/Water_Heater.jpg';
        break;
      default:
        // Fallback to icon if image not found
        return Container(
          color: AppColors.backgroundGray200,
          child: Icon(_getAssetIcon(type), size: 40, color: AppColors.primary),
        );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: AppColors.backgroundGray200,
          child: Icon(_getAssetIcon(type), size: 40, color: AppColors.primary),
        );
      },
    );
  }

  IconData _getAssetIcon(String type) {
    switch (type) {
      case 'Refrigerator':
        return Icons.kitchen;
      case 'Washing Machine':
        return Icons.local_laundry_service;
      case 'Air Conditioner':
        return Icons.ac_unit;
      case 'Microwave':
        return Icons.microwave;
      case 'Dishwasher':
        return Icons.water_drop;
      default:
        return Icons.devices;
    }
  }

  /// Format purchase date as full date (day, month, year) for display.
  /// Prefers complete ISO date string, falls back to formatted text or year/month.
  static String _formatPurchaseDate({
    String? purchasedAt,
    String? purchaseDate,
    dynamic purchaseYear,
    dynamic purchaseMonth,
  }) {
    // Priority 1: Parse full ISO date from purchasedAt
    if (purchasedAt != null && purchasedAt.isNotEmpty && purchasedAt != 'null') {
      try {
        final date = DateTime.parse(purchasedAt);
        return _formatDateFull(date);
      } on Object catch (_) {
        // Fall through to next option
      }
    }

    // Priority 2: Use pre-formatted purchase date string
    if (purchaseDate != null && purchaseDate.isNotEmpty && purchaseDate != 'null') {
      return purchaseDate;
    }

    // Priority 3: Format from year and month if available
    if (purchaseYear != null) {
      final year = int.tryParse(purchaseYear.toString());
      if (year != null) {
        final month = int.tryParse(purchaseMonth?.toString() ?? '1') ?? 1;
        try {
          final date = DateTime(year, month, 1);
          return _formatDateFull(date);
        } on Object catch (_) {
          return year.toString();
        }
      }
    }

    return '-';
  }

  /// Format DateTime as "Jan 28, 2011" (day, month, year).
  static String _formatDateFull(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}