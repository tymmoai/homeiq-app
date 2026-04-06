import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/warranty_status_badge.dart';
import '../../../../providers/warranty_status_provider.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Overview tab widget for asset detail screen
/// Shows asset health score, details, warranty/upgrade warnings, and maintenance reminders
class OverviewTabWidget extends StatelessWidget {
  final Map<String, dynamic> asset;
  final double healthScore;
  final ScrollController? scrollController;
  final dynamic overviewMaintenanceReminder; // Can be Reminder? or any type
  final bool isOwner;
  final VoidCallback onEditAssetDetails;
  final VoidCallback onMaintenanceDone;
  final VoidCallback onMaintenanceSnooze;
  final VoidCallback onMaintenanceSkip;
  final VoidCallback onOrderParts;
  final VoidCallback onDIY;
  final Widget Function(double healthScore, int ageYears, String assetType)
  keyRiskSectionBuilder;
  final Widget Function(String label, String value, {Color? valueColor})
  gridDetailItemBuilder;
  final String Function(String assetName) getBrand;
  final String Function(String? endDateIso, String fallbackLabel)
  getWarrantyStatus;
  final String Function(String purchaseDate) getAssetAge;
  final bool hasActiveProtectionPlan;
  final Map<String, dynamic>? protectionPlanData;
  final VoidCallback? onProtectionPlanNavigate;

  const OverviewTabWidget({
    super.key,
    required this.asset,
    required this.healthScore,
    this.isOwner = true,
    required this.onEditAssetDetails,
    required this.onMaintenanceDone,
    required this.onMaintenanceSnooze,
    required this.onMaintenanceSkip,
    required this.onOrderParts,
    required this.onDIY,
    required this.keyRiskSectionBuilder,
    required this.gridDetailItemBuilder,
    required this.getBrand,
    required this.getWarrantyStatus,
    required this.getAssetAge,
    this.scrollController,
    this.overviewMaintenanceReminder,
    this.hasActiveProtectionPlan = false,
    this.protectionPlanData,
    this.onProtectionPlanNavigate,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final assetName = asset['name'] as String;

    // Match asset card status badge logic exactly
    final healthStatus = healthScore >= 8.0
        ? 'Good'
        : healthScore >= 6.0
        ? 'Needs Attention'
        : 'Critical';
    final healthColor = healthScore >= 8.0
        ? AssetDetailColors.successColor
        : healthScore >= 6.0
        ? AssetDetailColors.warningColor
        : AssetDetailColors.errorColor;

    // Get asset details from asset map
    final brand = asset['brand'] ?? getBrand(assetName);
    final model = asset['model'] ?? '';
    final serialNumber = (asset['serial'] ?? asset['serialNumber'] ?? '')
        .toString();

    // Format purchase date: prefer full ISO date (purchasedAt), fall back to formatted text or year
    final purchaseDate = _formatPurchaseDateDisplay(
      purchasedAt: asset['purchasedAt']?.toString(),
      purchaseDate: asset['purchaseDate']?.toString(),
      purchaseYear: asset['purchaseYear'],
      purchaseMonth: asset['purchaseMonth'],
    );
    final location = (asset['location'] ?? '').toString();
    final warranty = asset['warranty']?.toString() ?? 'Unknown';
    final warrantyEndDate = asset['warrantyEndDate']?.toString();
    final currentYear = DateTime.now().year;
    final rawPurchaseYear = asset['purchaseYear'];

    int purchaseYear;
    if (rawPurchaseYear is int) {
      purchaseYear = rawPurchaseYear;
    } else if (rawPurchaseYear is String) {
      purchaseYear = int.tryParse(rawPurchaseYear) ?? currentYear;
    } else {
      purchaseYear = currentYear;
    }
    final ageYears = currentYear - purchaseYear;

    // Check warranty status - match the logic from asset tab
    final warrantyStatus = getWarrantyStatus(warrantyEndDate, warranty);
    // Check warranty expiration - case-insensitive to match asset tab filter logic
    // If there's an active protection plan, warranty is NOT expired
    final bool isWarrantyExpired =
        !hasActiveProtectionPlan &&
        (warranty.toString().toLowerCase() == 'expired' ||
            warrantyStatus == 'expired');

    // Calculate upgrade eligibility - only based on health score
    // Upgrade available if: healthScore <= 6.5 (regardless of warranty status)
    // If warranty expired AND health critical, BOTH protection plan and upgrade available will show
    final bool isUpgradeEligible = healthScore <= 6.5;

    // Get additional asset data
    final replacedAssetName = asset['replacedAssetName']?.toString();
    final replacedByAssetName = asset['replacedByAssetName']?.toString();
    final lifecycleStatus = asset['lifecycleStatus']?.toString() ?? 'active';
    final isReplaced = lifecycleStatus == 'replaced';

    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.all(responsive.spacing(18.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset Score Card
            Container(
              padding: EdgeInsets.all(responsive.spacing(20.0)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: responsive.spacing(8.0),
                    offset: Offset(0, responsive.spacing(2.0)),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asset Score',
                        style: TextStyle(
                          fontSize: responsive.fontSize(18.0),
                          fontWeight: FontWeight.bold,
                          color: AssetDetailColors.textPrimary,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(8.0),
                          vertical: responsive.spacing(4.0),
                        ),
                        decoration: BoxDecoration(
                          color: healthColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Text(
                          healthStatus,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            fontWeight: FontWeight.w600,
                            color: healthColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(10.0)),
                  Text(
                    '${healthScore.toStringAsFixed(1)}/10',
                    style: TextStyle(
                      fontSize: responsive.fontSize(32.0),
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12.0)),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(4.0),
                    ),
                    child: LinearProgressIndicator(
                      value: healthScore / 10,
                      minHeight: responsive.spacing(8.0),
                      backgroundColor: AssetDetailColors.borderColor,
                      valueColor: AlwaysStoppedAnimation<Color>(healthColor),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(10.0)),

            // Asset Details
            Container(
              padding: EdgeInsets.all(responsive.spacing(20.0)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12.0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: responsive.spacing(8.0),
                    offset: Offset(0, responsive.spacing(2.0)),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Asset Details',
                        style: TextStyle(
                          fontSize: responsive.fontSize(18.0),
                          fontWeight: FontWeight.bold,
                          color: AssetDetailColors.textPrimary,
                        ),
                      ),
                      if (isOwner)
                        IconButton(
                          onPressed: onEditAssetDetails,
                          icon: const Icon(Icons.edit_outlined),
                          iconSize: responsive.iconSize(22.0),
                          color: AssetDetailColors.textSecondary,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(16.0)),

                  // Build asset detail entries — only include fields with real values
                  // (skip blanks, placeholders like 'Unknown', 'N/A', '-').
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: responsive.spacing(16.0),
                    crossAxisSpacing: responsive.spacing(12.0),
                    childAspectRatio: 4.0,
                    children: [
                      // ── Helpers ──────────────────────────────────────────
                      // hasValue: true when the string is non-empty and not a
                      // known placeholder value.
                      ...() {
                        bool hasValue(String? v) {
                          if (v == null) return false;
                          final t = v.trim().toLowerCase();
                          return t.isNotEmpty &&
                              t != 'unknown' &&
                              t != 'n/a' &&
                              t != '-' &&
                              t != 'unknown brand' &&
                              t != '0';
                        }

                        final items = <Widget>[];

                        if (hasValue(brand.toString())) {
                          items.add(
                            gridDetailItemBuilder('Brand', brand.toString()),
                          );
                        }

                        if (hasValue(model)) {
                          items.add(gridDetailItemBuilder('Model', model));
                        }

                        if (hasValue(serialNumber)) {
                          items.add(
                            gridDetailItemBuilder('Serial', serialNumber),
                          );
                        }

                        if (hasValue(location)) {
                          items.add(
                            gridDetailItemBuilder('Location', location),
                          );
                        }

                        if (hasValue(purchaseDate)) {
                          items.add(
                            gridDetailItemBuilder(
                              'Purchase Date',
                              purchaseDate,
                            ),
                          );
                        }

                        // Age: only show when purchaseYear is actually set
                        if (rawPurchaseYear != null && ageYears > 0) {
                          items.add(
                            gridDetailItemBuilder(
                              'Age',
                              getAssetAge(purchaseDate),
                              valueColor: AppColors.infoAccent,
                            ),
                          );
                        }

                        final barcode = asset['barcode']?.toString() ?? '';
                        if (hasValue(barcode)) {
                          items.add(gridDetailItemBuilder('Barcode', barcode));
                        }

                        final manufacturer =
                            asset['manufacturer']?.toString() ?? '';
                        if (hasValue(manufacturer)) {
                          items.add(
                            gridDetailItemBuilder('Manufacturer', manufacturer),
                          );
                        }

                        final color = asset['productColor']?.toString() ?? '';
                        if (hasValue(color)) {
                          items.add(gridDetailItemBuilder('Color', color));
                        }

                        return items;
                      }(),
                    ],
                  ),

                  // Upgraded from info (new feature added to original format)
                  if (replacedAssetName != null) ...[
                    SizedBox(height: responsive.spacing(12.0)),
                    GestureDetector(
                      onTap: () {
                        // Navigate to the replaced asset
                        final replacedAsset =
                            asset['_replacedAsset'] as Map<String, dynamic>?;
                        if (replacedAsset != null && replacedAsset.isNotEmpty) {
                          context.push('/asset-detail', extra: replacedAsset);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: responsive.spacing(100.0),
                            child: Text(
                              'Upgraded from',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              replacedAssetName,
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                fontWeight: FontWeight.w600,
                                color: AssetDetailColors.primaryDark,
                                decoration: TextDecoration.underline,
                                decorationColor: AssetDetailColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Replaced by info (for old assets that were replaced)
                  if (isReplaced && replacedByAssetName != null) ...[
                    SizedBox(height: responsive.spacing(12.0)),
                    GestureDetector(
                      onTap: () {
                        // Navigate to the new asset that replaced this one
                        final replacedByAsset =
                            asset['_replacedByAsset'] as Map<String, dynamic>?;
                        if (replacedByAsset != null &&
                            replacedByAsset.isNotEmpty) {
                          context.push('/asset-detail', extra: replacedByAsset);
                        }
                      },
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: responsive.spacing(100.0),
                            child: Text(
                              'Replaced by',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              replacedByAssetName,
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                fontWeight: FontWeight.w600,
                                color: AssetDetailColors.primaryDark,
                                decoration: TextDecoration.underline,
                                decorationColor: AssetDetailColors.primaryDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(10.0)),

            // Product Specs (from ChatGPT enrichment)
            if (asset['productSpecs'] != null &&
                asset['productSpecs'] is Map &&
                (asset['productSpecs'] as Map).isNotEmpty)
              _buildProductSpecsSection(responsive, asset),

            // Network Info (from WiFi discovery scan)
            if (asset['networkDevice'] != null && asset['networkDevice'] is Map)
              _buildNetworkInfoSection(
                responsive,
                asset['networkDevice'] as Map<String, dynamic>,
              ),

            // Support & Resources links
            if ((asset['supportUrl'] != null &&
                    asset['supportUrl'].toString().isNotEmpty) ||
                (asset['manualUrl'] != null &&
                    asset['manualUrl'].toString().isNotEmpty))
              _buildSupportLinksSection(responsive, asset),

            // Warranty & Protection Details section (always shown)
            _buildWarrantyProtectionSection(
              context,
              responsive,
              asset: asset,
              warranty: warranty,
              warrantyEndDate: warrantyEndDate,
              isWarrantyExpired: isWarrantyExpired,
              purchaseYear: purchaseYear,
            ),
            SizedBox(height: responsive.spacing(10.0)),

            // Upgrade Available section if eligible (healthScore <= 6.5)
            // Never shown for replaced assets (already replaced)
            if (isUpgradeEligible && !isReplaced) ...[
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(responsive.spacing(20.0)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(12.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: responsive.spacing(8.0),
                      offset: Offset(0, responsive.spacing(2.0)),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: responsive.iconSize(40.0),
                          height: responsive.iconSize(40.0),
                          decoration: BoxDecoration(
                            color: AssetDetailColors.primaryDark.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(8.0),
                            ),
                          ),
                          child: Icon(
                            Icons.card_giftcard,
                            color: AssetDetailColors.primaryDark,
                            size: responsive.iconSize(20.0),
                          ),
                        ),
                        SizedBox(width: responsive.spacing(12.0)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Upgrade Available',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(16.0),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(4.0)),
                              Text(
                                'Your asset\'s health score is low. Consider upgrading for better performance.',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(16.0)),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          context.push('/upgrade-offer', extra: asset);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.spacing(14.0),
                          ),
                          textStyle: TextStyle(
                            fontSize: responsive.fontSize(14.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('View Upgrade Options'),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.spacing(10.0)),
            ],

            // Key Risk Section
            keyRiskSectionBuilder(
              healthScore,
              ageYears,
              asset['type']?.toString() ?? '',
            ),
            SizedBox(height: responsive.spacing(10.0)),

            // Upcoming Maintenance (hidden for replaced assets)
            if (overviewMaintenanceReminder != null && !isReplaced) ...[
              SizedBox(height: responsive.spacing(10.0)),
              Text(
                'Upcoming Maintenance',
                style: TextStyle(
                  fontSize: responsive.fontSize(18.0),
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(8.0)),

              // Maintenance Card matching ReminderCard style
              Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(12.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: responsive.spacing(8.0),
                      offset: Offset(0, responsive.spacing(2.0)),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Colored vertical bar (yellow for upcoming)
                    Container(
                      width: responsive.spacing(4.0),
                      decoration: BoxDecoration(
                        color: AppColors.warningAmber,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            responsive.borderRadius(12.0),
                          ),
                          bottomLeft: Radius.circular(
                            responsive.borderRadius(12.0),
                          ),
                        ),
                      ),
                    ),

                    // Card content
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(responsive.spacing(16.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header Row with Title and Risk/Days
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        overviewMaintenanceReminder.taskName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${overviewMaintenanceReminder.assetName}${overviewMaintenanceReminder.assetLocation != null ? ' • ${overviewMaintenanceReminder.assetLocation}' : ''}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.gray500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        overviewMaintenanceReminder
                                            .whyItMatters,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.gray700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'RISK: ${overviewMaintenanceReminder.riskLevel}/10',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${overviewMaintenanceReminder.dueDate.difference(DateTime.now()).inDays}D',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.gray500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Estimated time row
                            Row(
                              children: [
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: AppColors.gray500,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  overviewMaintenanceReminder.estimatedEffort,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Action Buttons - First Row (Done, Snooze, Skip - all white capsule with gray text)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: onMaintenanceDone,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      foregroundColor: AppColors.textSecondary,
                                      side: BorderSide(
                                        color: AppColors.divider,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Done'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: onMaintenanceSnooze,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      foregroundColor: AppColors.textSecondary,
                                      side: BorderSide(
                                        color: AppColors.divider,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Snooze'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: onMaintenanceSkip,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.white,
                                      foregroundColor: AppColors.textSecondary,
                                      side: BorderSide(
                                        color: AppColors.divider,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text('Skip'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 1),

                            // Action Buttons - Second Row (Order Parts, DIY - dark capsule)
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onOrderParts,
                                    icon: const Icon(
                                      Icons.shopping_cart,
                                      size: 16,
                                    ),
                                    label: const Text('Order Parts'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AssetDetailColors.primaryDark,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: onDIY,
                                    icon: const Icon(Icons.build, size: 16),
                                    label: const Text('DIY'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          AssetDetailColors.primaryDark,
                                      foregroundColor: AppColors.white,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      minimumSize: const Size(0, 36),
                                      textStyle: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Warranty & Protection Details Section ───
  Widget _buildWarrantyProtectionSection(
    BuildContext context,
    ResponsiveUtils responsive, {
    required Map<String, dynamic> asset,
    required String warranty,
    required String? warrantyEndDate,
    required bool isWarrantyExpired,
    required int purchaseYear,
  }) {
    final assetName = asset['name']?.toString() ?? 'Asset';
    final brand = asset['brand']?.toString() ?? getBrand(assetName);

    // Derive warranty info (synced with warranty detail screen)
    // If there's an active protection plan, show its details instead
    final String warrantyType;
    final String startDate;
    final String endDate;

    // Use ChatGPT-enriched warranty details when available
    final warrantyDetailsMap =
        asset['warrantyDetails'] as Map<String, dynamic>?;

    if (hasActiveProtectionPlan && protectionPlanData != null) {
      warrantyType =
          protectionPlanData!['planName'] as String? ??
          AppStrings.protectionPlan;
      final coverageStart = protectionPlanData!['coverageStart'] as String?;
      final coverageEnd = protectionPlanData!['coverageEnd'] as String?;
      startDate = coverageStart != null
          ? _formatIsoDate(coverageStart)
          : _formatStartDate(asset['purchaseDate']?.toString(), purchaseYear);
      endDate = coverageEnd ?? warrantyEndDate ?? 'N/A';
    } else {
      // Prefer enriched warranty type from ChatGPT/barcode over hardcoded guess
      final enrichedType = warrantyDetailsMap?['type']?.toString() ?? '';
      final enrichedDuration =
          warrantyDetailsMap?['duration']?.toString() ?? '';
      warrantyType = enrichedType.isNotEmpty
          ? (enrichedDuration.isNotEmpty
                ? '$enrichedType — $enrichedDuration'
                : enrichedType)
          : _getWarrantyType(assetName);
      startDate = _formatStartDate(
        asset['purchaseDate']?.toString(),
        purchaseYear,
      );
      endDate = warrantyEndDate ?? 'N/A';
    }
    final statusColor = isWarrantyExpired
        ? AppColors.error
        : AppColors.successMaterialLight;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(20.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (non-clickable, just displays info)
          Row(
            children: [
              Container(
                width: responsive.iconSize(36.0),
                height: responsive.iconSize(36.0),
                decoration: BoxDecoration(
                  color: AssetDetailColors.primaryDark.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(8.0),
                  ),
                ),
                child: Icon(
                  Icons.security,
                  color: AssetDetailColors.primaryDark,
                  size: responsive.iconSize(18.0),
                ),
              ),
              SizedBox(width: responsive.spacing(10.0)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Warranty & Protection Details',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(1.0)),
                    Text(
                      brand,
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              WarrantyStatusBadge(status: computeWarrantyStatus(asset)),
            ],
          ),

          SizedBox(height: responsive.spacing(12.0)),

          // Detail rows with faded divider lines (only 3 important details)
          Column(
            children: [
              _buildDetailRow(responsive, 'Type', warrantyType),
              Divider(
                height: 1,
                color: AppColors.borderMedium.withValues(alpha: 0.5),
              ),
              _buildDetailRow(
                responsive,
                'Coverage',
                '$startDate — ${hasActiveProtectionPlan ? _formatIsoDate(endDate) : endDate}',
                valueColor: isWarrantyExpired ? AppColors.error : null,
              ),
              Divider(
                height: 1,
                color: AppColors.borderMedium.withValues(alpha: 0.5),
              ),
              _buildDetailRow(
                responsive,
                'Status',
                hasActiveProtectionPlan
                    ? 'Protected'
                    : (isWarrantyExpired ? 'Protection Ended' : 'Protected'),
                valueColor: statusColor,
              ),
              // Show billing period if active protection plan
              if (hasActiveProtectionPlan && protectionPlanData != null) ...[
                Divider(
                  height: 1,
                  color: AppColors.borderMedium.withValues(alpha: 0.5),
                ),
                _buildDetailRow(
                  responsive,
                  'Plan',
                  _formatBillingPeriod(
                    protectionPlanData!['billingPeriod'] as String? ?? '',
                  ),
                ),
                Divider(
                  height: 1,
                  color: AppColors.borderMedium.withValues(alpha: 0.5),
                ),
                _buildDetailRow(
                  responsive,
                  'Price',
                  protectionPlanData!['priceLabel'] as String? ?? 'N/A',
                ),
              ],
            ],
          ),

          // "Get Extended Protection" button — only shown when warranty is expired AND no active protection plan
          if (isWarrantyExpired && !hasActiveProtectionPlan) ...[
            SizedBox(height: responsive.spacing(16.0)),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  if (onProtectionPlanNavigate != null) {
                    onProtectionPlanNavigate!();
                  } else {
                    context.push('/warranties', extra: asset);
                  }
                },
                icon: const Icon(Icons.shield, size: 16),
                label: const Text('Get Extended Protection'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(14.0),
                  ),
                  textStyle: TextStyle(
                    fontSize: responsive.fontSize(14.0),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],

          // Active Protection Plan badge - shown when plan is active
          if (hasActiveProtectionPlan) ...[
            SizedBox(height: responsive.spacing(12.0)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(12.0),
                vertical: responsive.spacing(10.0),
              ),
              decoration: BoxDecoration(
                color: AppColors.successSoft,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(8.0),
                ),
                border: Border.all(color: AppColors.successBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: AppColors.successMaterialLight,
                    size: responsive.iconSize(18.0),
                  ),
                  SizedBox(width: responsive.spacing(8.0)),
                  Expanded(
                    child: Text(
                      'Extended Protection Active',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13.0),
                        fontWeight: FontWeight.w600,
                        color: AppColors.successDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Bottom right "View Details" link (always at the bottom)
          SizedBox(height: responsive.spacing(10.0)),
          GestureDetector(
            onTap: () {
              context.push('/warranty-detail', extra: asset);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: responsive.spacing(4.0)),
                Icon(
                  Icons.arrow_forward,
                  size: responsive.iconSize(16.0),
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    ResponsiveUtils responsive,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(14.0),
        vertical: responsive.spacing(11.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: responsive.fontSize(13.0),
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.slate800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getWarrantyType(String assetName) {
    final type = assetName.toLowerCase();
    if (type.contains('refrigerator') || type.contains('fridge')) {
      return 'Parts & Labor';
    } else if (type.contains('tv')) {
      return '1-Year Limited';
    } else if (type.contains('washer') || type.contains('washing')) {
      return 'Parts & Labor';
    } else if (type.contains('dishwasher')) {
      return '2-Year Limited';
    } else if (type.contains('dryer')) {
      return 'Parts Limited';
    } else if (type.contains('ac') || type.contains('air conditioner')) {
      return '5-Year Limited';
    } else if (type.contains('water heater') || type.contains('heater')) {
      return '6-Year Limited';
    } else if (type.contains('microwave') || type.contains('oven')) {
      return 'Lifetime Limited';
    } else if (type.contains('fan') || type.contains('ceiling')) {
      return 'Lifetime Limited';
    }
    return 'Standard Warranty';
  }

  String _formatStartDate(String? purchaseDate, int purchaseYear) {
    if (purchaseDate != null && purchaseDate.isNotEmpty) {
      return purchaseDate;
    }
    return 'Jan $purchaseYear';
  }

  /// Format ISO date string (e.g., "2027-02-17T00:00:00.000") to "Feb 17, 2027"
  String _formatIsoDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } on Object catch (_) {
      return isoDate;
    }
  }

  /// Format billing period for display
  String _formatBillingPeriod(String billingPeriod) {
    switch (billingPeriod.toLowerCase()) {
      case 'monthly':
        return 'Monthly';
      case 'yearly':
        return 'Yearly';
      case 'one-time':
        return 'One-Time';
      default:
        return billingPeriod;
    }
  }

  // ─── Keys already shown in other detail sections ───
  static final _duplicateSpecKeys = {
    // Asset Details grid
    'brand', 'model', 'model number', 'serial', 'serial number',
    'location', 'purchase date', 'age', 'barcode', 'upc', 'ean',
    'manufacturer', 'mfr',
    // Warranty section
    'warranty', 'warranty type', 'warranty duration', 'warranty coverage',
    'warranty info', 'coverage', 'registration url',
    // Shown separately in this section
    'color', 'colour', 'finish', 'color / finish',
    'price', 'retail price', 'estimated price', 'msrp',
    // Generic duplicates
    'product name', 'name', 'description', 'category', 'sub category',
  };

  /// Returns true if the spec key duplicates info already visible elsewhere.
  bool _isDuplicateSpecKey(String key) {
    return _duplicateSpecKeys.contains(key.toLowerCase().trim());
  }

  // ─── Network Info Section (from WiFi discovery scan) ───
  Widget _buildNetworkInfoSection(
    ResponsiveUtils responsive,
    Map<String, dynamic> nd,
  ) {
    final metadata = nd['metadata'] is Map
        ? nd['metadata'] as Map<String, dynamic>
        : <String, dynamic>{};

    final ipAddress = nd['ipAddress']?.toString() ?? '';
    final macAddress = nd['macAddress']?.toString() ?? '';
    final hostname = nd['hostname']?.toString() ?? '';
    final deviceName = nd['deviceName']?.toString() ?? '';
    final manufacturer = nd['manufacturer']?.toString() ?? '';
    final osFingerprint = nd['osFingerprint']?.toString() ?? '';
    final lastSeen = nd['lastSeen']?.toString() ?? '';
    final openPorts = nd['openPorts'];

    // Metadata fields from WiFi scan
    final firmware = metadata['firmwareVersion']?.toString() ?? '';
    final osHint = metadata['osHint']?.toString() ?? '';
    final sshBanner = metadata['sshBanner']?.toString() ?? '';
    final smbOs = metadata['smbOsVersion']?.toString() ?? '';
    final tlsCert = metadata['tlsCertSubject']?.toString() ?? '';
    final modelNumber = metadata['model']?.toString() ?? '';
    final serialNumber = metadata['serial']?.toString() ?? '';
    final confidence = metadata['confidence'];
    final discoveryMethod = metadata['discoveryMethod']?.toString() ?? '';
    final httpBanner = metadata['httpBanner']?.toString() ?? '';
    final htmlTitle = metadata['htmlTitle']?.toString() ?? '';

    bool hasValue(String v) => v.isNotEmpty && v != 'null' && v != 'Unknown';

    // Build port list
    String portStr = '';
    if (openPorts is List && openPorts.isNotEmpty) {
      portStr = openPorts.take(8).map((p) => p.toString()).join(', ');
      if (openPorts.length > 8) portStr += ' +${openPorts.length - 8}';
    }

    // Format last seen
    String lastSeenStr = '';
    if (hasValue(lastSeen)) {
      try {
        final dt = DateTime.parse(lastSeen);
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 5) {
          lastSeenStr = 'Just now';
        } else if (diff.inHours < 1) {
          lastSeenStr = '${diff.inMinutes}m ago';
        } else if (diff.inDays < 1) {
          lastSeenStr = '${diff.inHours}h ago';
        } else {
          lastSeenStr = '${diff.inDays}d ago';
        }
      } on Object catch (_) {
        lastSeenStr = lastSeen;
      }
    }

    return Column(
      children: [
        SizedBox(height: responsive.spacing(10.0)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(20.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: responsive.spacing(8.0),
                offset: Offset(0, responsive.spacing(2.0)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    size: responsive.iconSize(20.0),
                    color: AssetDetailColors.primaryDark,
                  ),
                  SizedBox(width: responsive.spacing(8.0)),
                  Text(
                    'Network Info',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18.0),
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12.0)),

              if (hasValue(ipAddress))
                _buildDetailRow(responsive, 'IP Address', ipAddress),
              if (hasValue(macAddress))
                _buildDetailRow(responsive, 'MAC Address', macAddress),
              if (hasValue(hostname))
                _buildDetailRow(responsive, 'Hostname', hostname),
              if (hasValue(deviceName))
                _buildDetailRow(responsive, 'Device Name', deviceName),
              if (hasValue(manufacturer))
                _buildDetailRow(responsive, 'Manufacturer', manufacturer),
              if (hasValue(modelNumber))
                _buildDetailRow(responsive, 'Model', modelNumber),
              if (hasValue(serialNumber))
                _buildDetailRow(responsive, 'Serial', serialNumber),
              if (hasValue(osHint))
                _buildDetailRow(responsive, 'OS / Platform', osHint),
              if (hasValue(smbOs))
                _buildDetailRow(responsive, 'OS Version', smbOs),
              if (hasValue(osFingerprint))
                _buildDetailRow(responsive, 'OS Fingerprint', osFingerprint),
              if (hasValue(firmware))
                _buildDetailRow(responsive, 'Firmware', firmware),
              if (hasValue(sshBanner))
                _buildDetailRow(responsive, 'SSH Banner', sshBanner),
              if (hasValue(tlsCert))
                _buildDetailRow(responsive, 'TLS Certificate', tlsCert),
              if (hasValue(httpBanner))
                _buildDetailRow(responsive, 'Server', httpBanner),
              if (hasValue(htmlTitle))
                _buildDetailRow(responsive, 'Page Title', htmlTitle),
              if (portStr.isNotEmpty)
                _buildDetailRow(responsive, 'Open Ports', portStr),
              if (hasValue(discoveryMethod))
                _buildDetailRow(responsive, 'Discovery', discoveryMethod),
              if (confidence != null && confidence is int)
                _buildDetailRow(
                  responsive,
                  'Confidence',
                  '$confidence%',
                  valueColor: confidence >= 75
                      ? const Color(0xFF2E7D32)
                      : confidence >= 50
                      ? const Color(0xFFE65100)
                      : const Color(0xFFC62828),
                ),
              if (hasValue(lastSeenStr))
                _buildDetailRow(
                  responsive,
                  'Last Seen',
                  lastSeenStr,
                  valueColor: lastSeenStr == 'Just now'
                      ? const Color(0xFF2E7D32)
                      : null,
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Product Specs Section (from ChatGPT enrichment) ───
  Widget _buildProductSpecsSection(
    ResponsiveUtils responsive,
    Map<String, dynamic> asset,
  ) {
    final rawSpecs = asset['productSpecs'] as Map;
    // Filter out specs already shown in Asset Details, Warranty, or other sections
    final specs = Map.fromEntries(
      rawSpecs.entries.where((e) => !_isDuplicateSpecKey(e.key.toString())),
    );
    final productColor = asset['productColor']?.toString() ?? '';
    final enrichmentSource = asset['enrichmentSource']?.toString() ?? '';

    // If all specs were duplicates, don't show the section at all
    if (specs.isEmpty && productColor.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(20.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: responsive.spacing(8.0),
                offset: Offset(0, responsive.spacing(2.0)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Product Specifications',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18.0),
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (enrichmentSource.isNotEmpty)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(8.0),
                        vertical: responsive.spacing(3.0),
                      ),
                      decoration: BoxDecoration(
                        color: enrichmentSource == 'merged'
                            ? AppColors.success.withValues(alpha: 0.1)
                            : const Color(0xFF2196F3).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        enrichmentSource == 'merged'
                            ? 'Verified + AI'
                            : enrichmentSource == 'barcode_api'
                            ? 'Verified'
                            : 'AI Identified',
                        style: TextStyle(
                          fontSize: responsive.fontSize(10.0),
                          fontWeight: FontWeight.w500,
                          color: enrichmentSource == 'merged'
                              ? AppColors.success
                              : const Color(0xFF2196F3),
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: responsive.spacing(16.0)),
              // Specs grid
              ...specs.entries.map((entry) {
                return Padding(
                  padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: responsive.spacing(120.0),
                        child: Text(
                          entry.key.toString(),
                          style: TextStyle(
                            fontSize: responsive.fontSize(13.0),
                            color: AssetDetailColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          entry.value.toString(),
                          style: TextStyle(
                            fontSize: responsive.fontSize(14.0),
                            fontWeight: FontWeight.w600,
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              // Color (if available)
              if (productColor.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                  child: Row(
                    children: [
                      SizedBox(
                        width: responsive.spacing(120.0),
                        child: Text(
                          'Color / Finish',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13.0),
                            color: AssetDetailColors.textSecondary,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          productColor,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14.0),
                            fontWeight: FontWeight.w600,
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(10.0)),
      ],
    );
  }

  // ─── Support & Resources Links Section ───
  Widget _buildSupportLinksSection(
    ResponsiveUtils responsive,
    Map<String, dynamic> asset,
  ) {
    final supportUrl = asset['supportUrl']?.toString() ?? '';
    final manualUrl = asset['manualUrl']?.toString() ?? '';

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(20.0)),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: responsive.spacing(8.0),
                offset: Offset(0, responsive.spacing(2.0)),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Support & Resources',
                style: TextStyle(
                  fontSize: responsive.fontSize(18.0),
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(16.0)),
              if (supportUrl.isNotEmpty)
                _buildLinkRow(
                  responsive,
                  icon: Icons.support_agent,
                  label: 'Product Support',
                  url: supportUrl,
                ),
              if (manualUrl.isNotEmpty) ...[
                if (supportUrl.isNotEmpty)
                  SizedBox(height: responsive.spacing(12.0)),
                _buildLinkRow(
                  responsive,
                  icon: Icons.menu_book_outlined,
                  label: 'Product Manual',
                  url: manualUrl,
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(10.0)),
      ],
    );
  }

  Widget _buildLinkRow(
    ResponsiveUtils responsive, {
    required IconData icon,
    required String label,
    required String url,
  }) {
    return InkWell(
      onTap: () async {
        // Ensure URL has scheme — ChatGPT/barcode API may return bare domains
        var normalizedUrl = url.trim();
        if (!normalizedUrl.startsWith('http://') &&
            !normalizedUrl.startsWith('https://')) {
          normalizedUrl = 'https://$normalizedUrl';
        }
        final uri = Uri.tryParse(normalizedUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(12.0),
          vertical: responsive.spacing(12.0),
        ),
        decoration: BoxDecoration(
          color: AppColors.backgroundGray50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: responsive.iconSize(20.0),
              color: AppColors.primary,
            ),
            SizedBox(width: responsive.spacing(12.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AssetDetailColors.textPrimary,
                    ),
                  ),
                  Text(
                    url,
                    style: TextStyle(
                      fontSize: responsive.fontSize(11.0),
                      color: AppColors.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.open_in_new,
              size: responsive.iconSize(16.0),
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// Format purchase date as full date (day, month, year) for display.
  /// Prefers complete ISO date string, falls back to formatted text or year/month.
  static String _formatPurchaseDateDisplay({
    String? purchasedAt,
    String? purchaseDate,
    dynamic purchaseYear,
    dynamic purchaseMonth,
  }) {
    // Priority 1: Parse full ISO date from purchasedAt
    if (purchasedAt != null &&
        purchasedAt.isNotEmpty &&
        purchasedAt != 'null') {
      try {
        final date = DateTime.parse(purchasedAt);
        return _formatDateFullDisplay(date);
      } on Object catch (_) {
        // Fall through to next option
      }
    }

    // Priority 2: Use pre-formatted purchase date string
    if (purchaseDate != null &&
        purchaseDate.isNotEmpty &&
        purchaseDate != 'null') {
      return purchaseDate;
    }

    // Priority 3: Format from year and month if available
    if (purchaseYear != null) {
      final year = int.tryParse(purchaseYear.toString());
      if (year != null) {
        final month = int.tryParse(purchaseMonth?.toString() ?? '1') ?? 1;
        try {
          final date = DateTime(year, month, 1);
          return _formatDateFullDisplay(date);
        } on Object catch (_) {
          return year.toString();
        }
      }
    }

    return '-';
  }

  /// Format DateTime as "Jan 18, 2024" (day, month, year).
  static String _formatDateFullDisplay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
