// Warranty & Protection Details Screen
// Matches the provided HTML/Tailwind design

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../utils/responsive_utils.dart';

class WarrantyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const WarrantyDetailScreen({super.key, required this.asset});

  @override
  State<WarrantyDetailScreen> createState() => _WarrantyDetailScreenState();
}

class _WarrantyDetailScreenState extends State<WarrantyDetailScreen> {
  bool _isFinancialDetailsExpanded = false;
  bool _isWhatsCoveredExpanded = false;
  bool _isExclusionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    // Extract asset warranty data
    final assetName = widget.asset['name']?.toString() ?? 'Asset';
    final brand = widget.asset['brand']?.toString() ?? 'Unknown';
    final warranty = widget.asset['warranty']?.toString() ?? 'Unknown';
    final warrantyEndDate = widget.asset['warrantyEndDate']?.toString();
    final purchaseDate = widget.asset['purchaseDate']?.toString();
    final purchaseYear = widget.asset['purchaseYear'];

    // Use enriched warranty details from ChatGPT/barcode when available
    final warrantyDetailsMap = widget.asset['warrantyDetails'] as Map<String, dynamic>?;

    final isExpired =
        warranty.toLowerCase() == 'expired' || _isDateExpired(warrantyEndDate);

    // Derive warranty data — prefer enriched data over hardcoded guesses
    final enrichedType = warrantyDetailsMap?['type']?.toString() ?? '';
    final enrichedDuration = warrantyDetailsMap?['duration']?.toString() ?? '';
    final enrichedCoverage = warrantyDetailsMap?['coverage']?.toString() ?? '';
    final warrantyType = enrichedType.isNotEmpty
        ? (enrichedDuration.isNotEmpty ? '$enrichedType ($enrichedDuration)' : enrichedType)
        : _getWarrantyType(assetName, brand);
    final warrantyNumber = _getWarrantyNumber(brand, purchaseYear);
    final startDate = _getStartDate(purchaseDate, purchaseYear);
    final endDate = warrantyEndDate ?? 'N/A';
    final partsUntil = endDate;
    final laborUntil = _getLaborUntil(startDate, endDate);
    final provider = _getWarrantyProvider(brand);
    final coveredItems = enrichedCoverage.isNotEmpty
        ? [enrichedCoverage, ..._getCoveredItems(assetName).skip(1)]
        : _getCoveredItems(assetName);
    final exclusions = _getExclusions(assetName);

    return Scaffold(
      backgroundColor: AppColors.backgroundGray100,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: AppColors.primary,
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(16.0),
                vertical: responsive.spacing(12.0),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back, color: AppColors.white),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Text(
                      'Warranty & Protection Details',
                      style: TextStyle(
                        fontSize: responsive.fontSize(18),
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(10),
                      vertical: responsive.spacing(6),
                    ),
                    decoration: BoxDecoration(
                      color: isExpired ? AppColors.errorFee : AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      isExpired ? 'Inactive' : 'Active',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        fontWeight: FontWeight.w600,
                        color: isExpired
                            ? AppColors.error
                            : AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.spacing(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warranty Information Card
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Card Header with FTC Badge
                          Padding(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Warranty Information',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(16),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: responsive.spacing(8),
                                    vertical: responsive.spacing(4),
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.infoBackground,
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                    border: Border.all(
                                      color: AppColors.infoLight,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.verified_user,
                                        size: responsive.fontSize(12),
                                        color: AppColors.infoAccent,
                                      ),
                                      SizedBox(width: responsive.spacing(4)),
                                      Text(
                                        'FTC COMPLIANT',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(9),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.infoDark,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Divider(height: 1, color: AppColors.border),
                          Padding(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Warranty Type
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.description_outlined,
                                      size: 14,
                                      color: AppColors.slate400,
                                    ),
                                    SizedBox(width: responsive.spacing(6)),
                                    Text(
                                      'WARRANTY TYPE',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(10),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.spacing(6)),
                                Text(
                                  warrantyType,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(15),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                // Warranty Number
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.tag,
                                      size: 14,
                                      color: AppColors.slate400,
                                    ),
                                    SizedBox(width: responsive.spacing(6)),
                                    Text(
                                      'WARRANTY NUMBER',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(10),
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slate500,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.spacing(6)),
                                Text(
                                  warrantyNumber,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slate800,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                Divider(
                                  height: 1,
                                  color: AppColors.backgroundSlate100,
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                // Start Date & End Date
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.calendar_today,
                                                size: 14,
                                                color: AppColors.slate400,
                                              ),
                                              SizedBox(
                                                width: responsive.spacing(6),
                                              ),
                                              Text(
                                                'START DATE',
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize(
                                                    10,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.slateLabel,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: responsive.spacing(4),
                                          ),
                                          Text(
                                            startDate,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(13),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: responsive.spacing(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.event_busy,
                                                size: 14,
                                                color: AppColors.slate400,
                                              ),
                                              SizedBox(
                                                width: responsive.spacing(6),
                                              ),
                                              Text(
                                                'END DATE',
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize(
                                                    10,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.slateLabel,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: responsive.spacing(4),
                                          ),
                                          Text(
                                            endDate,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(13),
                                              fontWeight: FontWeight.w600,
                                              color: isExpired
                                                  ? AppColors.error
                                                  : AppColors.slate800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                // Parts Until & Labor Until
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.build,
                                                size: 14,
                                                color: AppColors.slate400,
                                              ),
                                              SizedBox(
                                                width: responsive.spacing(6),
                                              ),
                                              Text(
                                                'PARTS UNTIL',
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize(
                                                    10,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.slateLabel,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: responsive.spacing(4),
                                          ),
                                          Text(
                                            partsUntil,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(13),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: responsive.spacing(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.engineering,
                                                size: 14,
                                                color: AppColors.slate400,
                                              ),
                                              SizedBox(
                                                width: responsive.spacing(6),
                                              ),
                                              Text(
                                                'LABOR UNTIL',
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize(
                                                    10,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.slateLabel,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: responsive.spacing(4),
                                          ),
                                          Text(
                                            laborUntil,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(13),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.slate800,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),

                    // Financial Details Accordion
                    _buildAccordionSection(
                      responsive,
                      title: 'FINANCIAL DETAILS',
                      isExpanded: _isFinancialDetailsExpanded,
                      onTap: () {
                        setState(() {
                          _isFinancialDetailsExpanded =
                              !_isFinancialDetailsExpanded;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: responsive.spacing(16),
                          right: responsive.spacing(16),
                          bottom: responsive.spacing(16),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDateCard(
                                    responsive,
                                    icon: Icons.attach_money,
                                    label: 'DEDUCTIBLE',
                                    value: '\$0',
                                    valueColor: AppColors.successDark,
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(12)),
                                Expanded(
                                  child: _buildDateCard(
                                    responsive,
                                    icon: Icons.local_activity,
                                    label: 'SERVICE CALL',
                                    value: '\$0',
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: responsive.spacing(12)),
                            // Claims & Transferable
                            Container(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.shadowMedium,
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  _buildDetailRow(
                                    responsive,
                                    'Claims Remaining',
                                    isExpired ? 'N/A - Expired' : 'Unlimited',
                                    isItalic: isExpired,
                                  ),
                                  Divider(
                                    height: 1,
                                    color: AppColors.border,
                                  ),
                                  _buildDetailRow(
                                    responsive,
                                    'Transferable',
                                    'No',
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),

                    // What's Covered Accordion
                    _buildAccordionSection(
                      responsive,
                      title: "WHAT'S COVERED",
                      isExpanded: _isWhatsCoveredExpanded,
                      onTap: () {
                        setState(() {
                          _isWhatsCoveredExpanded = !_isWhatsCoveredExpanded;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: responsive.spacing(16),
                          right: responsive.spacing(16),
                          bottom: responsive.spacing(16),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(responsive.spacing(16)),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSlate50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: coveredItems
                                .map(
                                  (item) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: responsive.spacing(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.check_circle,
                                          size: 18,
                                          color: AppColors.successMaterialLight,
                                        ),
                                        SizedBox(width: responsive.spacing(12)),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(14),
                                              color: AppColors.slate700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(12)),

                    // Exclusions Accordion
                    _buildAccordionSection(
                      responsive,
                      title: 'EXCLUSIONS',
                      isExpanded: _isExclusionsExpanded,
                      onTap: () {
                        setState(() {
                          _isExclusionsExpanded = !_isExclusionsExpanded;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: responsive.spacing(16),
                          right: responsive.spacing(16),
                          bottom: responsive.spacing(16),
                        ),
                        child: Container(
                          padding: EdgeInsets.all(responsive.spacing(16)),
                          decoration: BoxDecoration(
                            color: AppColors.backgroundSlate50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: exclusions
                                .map(
                                  (item) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: responsive.spacing(12),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.cancel,
                                          size: 18,
                                          color: AppColors.errorMild,
                                        ),
                                        SizedBox(width: responsive.spacing(12)),
                                        Expanded(
                                          child: Text(
                                            item,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(14),
                                              color: AppColors.slate600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),

                    // Expired banner + Get Extended Protection (after accordions)
                    if (isExpired) ...[
                      Container(
                        padding: EdgeInsets.all(responsive.spacing(16)),
                        decoration: BoxDecoration(
                          color: AppColors.infoBackground,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.infoLight),
                        ),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.infoBorder,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.shield,
                                    size: 18,
                                    color: AppColors.infoAccent,
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(12)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Your warranty has expired',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(14),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.slate900,
                                        ),
                                      ),
                                      SizedBox(height: responsive.spacing(2)),
                                      Text(
                                        'Get extended protection with zero deductibles and full coverage.',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(11),
                                          color: AppColors.slate600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: responsive.spacing(12)),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  context.push(
                                    '/warranties',
                                    extra: widget.asset,
                                  );
                                },
                                icon: const Icon(Icons.shield, size: 16),
                                label: const Text('Get Extended Protection'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: AppColors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(
                                    vertical: responsive.spacing(14),
                                  ),
                                  textStyle: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.spacing(20)),
                    ],

                    // Warranty Provider
                    _buildSectionLabel(responsive, 'WARRANTY PROVIDER'),
                    SizedBox(height: responsive.spacing(12)),
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(20)),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSlate50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider['name'] as String,
                            style: TextStyle(
                              fontSize: responsive.fontSize(16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(16)),
                          _buildProviderRow(
                            responsive,
                            Icons.location_on_outlined,
                            provider['address'] as String,
                          ),
                          SizedBox(height: responsive.spacing(16)),
                          GestureDetector(
                            onTap: () =>
                                _launchPhone(provider['phone'] as String),
                            child: _buildProviderRow(
                              responsive,
                              Icons.phone,
                              provider['phone'] as String,
                              isLink: true,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(16)),
                          GestureDetector(
                            onTap: () =>
                                _launchUrl(provider['website'] as String),
                            child: _buildProviderRow(
                              responsive,
                              Icons.open_in_new,
                              provider['websiteDisplay'] as String,
                              isLink: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),

                    // US Consumer Rights
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      decoration: BoxDecoration(
                        color: AppColors.warningYellowBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.warningYellowBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.gavel,
                                size: 18,
                                color: AppColors.warningBrown,
                              ),
                              SizedBox(width: responsive.spacing(8)),
                              Text(
                                'US CONSUMER RIGHTS',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.warningBrown,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.spacing(12)),
                          _buildRightsItem(
                            responsive,
                            'Magnuson-Moss Warranty Act: State court protections',
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          _buildRightsItem(
                            responsive,
                            'State Protections: Implied warranties enforced per state UCC law',
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          _buildRightsItem(
                            responsive,
                            'FTC Compliance: Complies with disclosure rules (16 CFR Part 701)',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(32)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ───

  Widget _buildDateCard(
    ResponsiveUtils responsive, {
    required IconData icon,
    required String label,
    required String value,
    bool isExpired = false,
    Color? valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AppColors.slate500),
              SizedBox(width: responsive.spacing(6)),
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize(10),
                  fontWeight: FontWeight.w700,
                  color: AppColors.slate500,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(4)),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w600,
              color:
                  valueColor ??
                  (isExpired
                      ? AppColors.error
                      : AppColors.slate900),
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
    bool isItalic = false,
  }) {
    return Padding(
      padding: EdgeInsets.all(responsive.spacing(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w500,
              color: AppColors.slate500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w700,
              color: isItalic
                  ? AppColors.slate400
                  : AppColors.slate900,
              fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(ResponsiveUtils responsive, String label) {
    return Padding(
      padding: EdgeInsets.only(left: responsive.spacing(4)),
      child: Text(
        label,
        style: TextStyle(
          fontSize: responsive.fontSize(11),
          fontWeight: FontWeight.w700,
          color: AppColors.slate500,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildProviderRow(
    ResponsiveUtils responsive,
    IconData icon,
    String text, {
    bool isLink = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.slate400),
        SizedBox(width: responsive.spacing(12)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: isLink ? FontWeight.w500 : FontWeight.w400,
              color: isLink ? AppColors.primary : AppColors.slate600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightsItem(ResponsiveUtils responsive, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: responsive.spacing(2)),
          child: Icon(
            Icons.verified,
            size: 14,
            color: AppColors.warningBrown.withValues(alpha: 0.7),
          ),
        ),
        SizedBox(width: responsive.spacing(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              color: AppColors.warningBrownDark.withValues(alpha: 0.7),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Data Helpers ───

  bool _isDateExpired(String? dateStr) {
    if (dateStr == null) return false;
    try {
      return DateTime.parse(dateStr).isBefore(DateTime.now());
    } on Object catch (_) {
      return false;
    }
  }

  String _getWarrantyType(String assetName, String brand) {
    final type = assetName.toLowerCase();
    if (type.contains('refrigerator') || type.contains('fridge')) {
      return 'Limited Warranty (Parts & Labor)';
    } else if (type.contains('tv')) {
      return 'Limited 1-Year Warranty';
    } else if (type.contains('washer') || type.contains('washing')) {
      return 'Full Parts & Labor Warranty';
    } else if (type.contains('dishwasher')) {
      return 'Limited 2-Year Warranty';
    } else if (type.contains('dryer')) {
      return 'Limited Parts Warranty';
    } else if (type.contains('ac') || type.contains('air conditioner')) {
      return 'Limited 5-Year Warranty';
    } else if (type.contains('water heater') || type.contains('heater')) {
      return '6-Year Limited Warranty';
    } else if (type.contains('microwave') || type.contains('oven')) {
      return 'Limited Lifetime Warranty';
    } else if (type.contains('fan') || type.contains('ceiling')) {
      return 'Limited Lifetime Warranty';
    }
    return 'Standard Manufacturer Warranty';
  }

  String _getWarrantyNumber(String brand, dynamic purchaseYear) {
    final yr = purchaseYear?.toString() ?? '2020';
    final prefix = brand.substring(0, 3).toUpperCase();
    return '$prefix-WR-$yr-${34501 + (brand.hashCode % 1000).abs()}';
  }

  String _getStartDate(String? purchaseDate, dynamic purchaseYear) {
    if (purchaseDate != null && purchaseDate.isNotEmpty) {
      // Try to parse "Jan 2019" style
      final parts = purchaseDate.split(' ');
      if (parts.length == 2) {
        final monthMap = {
          'Jan': '01',
          'Feb': '02',
          'Mar': '03',
          'Apr': '04',
          'May': '05',
          'Jun': '06',
          'Jul': '07',
          'Aug': '08',
          'Sep': '09',
          'Oct': '10',
          'Nov': '11',
          'Dec': '12',
        };
        final month = monthMap[parts[0]] ?? '01';
        return '${parts[1]}-$month-10';
      }
    }
    return '${purchaseYear ?? 2020}-01-10';
  }

  String _getLaborUntil(String startDate, String endDate) {
    // Labor coverage is typically 1 year less than parts
    try {
      final end = DateTime.parse(endDate);
      final labor = end.subtract(const Duration(days: 365));
      return '${labor.year}-${labor.month.toString().padLeft(2, '0')}-${labor.day.toString().padLeft(2, '0')}';
    } on Object catch (_) {
      return endDate;
    }
  }

  Map<String, String> _getWarrantyProvider(String brand) {
    final providers = <String, Map<String, String>>{
      'Samsung': {
        'name': 'Samsung Electronics America',
        'address': '85 Challenger Road, Ridgefield Park, NJ 07660',
        'phone': '1-800-726-7864',
        'website': 'https://samsung.com/support',
        'websiteDisplay': 'samsung.com/support',
      },
      'LG': {
        'name': 'LG Electronics USA',
        'address': '1000 Sylvan Ave, Englewood Cliffs, NJ 07632',
        'phone': '1-800-243-0000',
        'website': 'https://lg.com/support',
        'websiteDisplay': 'lg.com/support',
      },
      'Whirlpool': {
        'name': 'Whirlpool Corporation',
        'address': '2000 North M-63, Benton Harbor, MI 49022',
        'phone': '1-866-698-2538',
        'website': 'https://whirlpool.com/support',
        'websiteDisplay': 'whirlpool.com/support',
      },
      'Sony': {
        'name': 'Sony Electronics Inc.',
        'address': '16535 Via Esprillo, San Diego, CA 92127',
        'phone': '1-800-222-7669',
        'website': 'https://sony.com/support',
        'websiteDisplay': 'sony.com/support',
      },
      'GE': {
        'name': 'GE Appliances',
        'address': 'Appliance Park, Louisville, KY 40225',
        'phone': '1-800-626-2005',
        'website': 'https://geappliances.com/support',
        'websiteDisplay': 'geappliances.com/support',
      },
    };

    return providers[brand] ??
        {
          'name': '$brand Customer Support',
          'address': 'Contact $brand for address details',
          'phone': '1-800-000-0000',
          'website': 'https://${brand.toLowerCase()}.com/support',
          'websiteDisplay': '${brand.toLowerCase()}.com/support',
        };
  }

  List<String> _getCoveredItems(String assetName) {
    final type = assetName.toLowerCase();
    if (type.contains('refrigerator') || type.contains('fridge')) {
      return [
        'Compressor (10-year limited)',
        'Sealed refrigeration system',
        'Electrical components',
        'Ice maker mechanism',
        'Temperature controls & thermostats',
      ];
    } else if (type.contains('washer') || type.contains('washing')) {
      return [
        'Motor & drive system',
        'Drum & bearing assembly',
        'Electronic control board',
        'Water pump & valve',
        'Door lock mechanism',
      ];
    } else if (type.contains('dishwasher')) {
      return [
        'Wash motor & pump',
        'Electronic control board',
        'Spray arms & water inlet',
        'Door latch mechanism',
        'Heating element',
      ];
    } else if (type.contains('tv')) {
      return [
        'Display panel',
        'Main board & processor',
        'Power supply board',
        'Backlight/LED array',
        'Remote control (1 year)',
      ];
    } else if (type.contains('ac') || type.contains('air conditioner')) {
      return [
        'Compressor (5-year limited)',
        'Evaporator & condenser coils',
        'Fan motor & blower',
        'Thermostat & controls',
        'Refrigerant system (sealed)',
      ];
    } else if (type.contains('water heater') || type.contains('heater')) {
      return [
        'Tank & inner lining (6 years)',
        'Heating elements',
        'Thermostat & controls',
        'Anode rod',
        'Pressure relief valve',
      ];
    } else if (type.contains('microwave') || type.contains('oven')) {
      return [
        'Magnetron (lifetime limited)',
        'Electrical components',
        'Turntable motor & plate',
        'Door seal & latch',
        'Control panel & keypad',
      ];
    }
    return [
      'Mechanical components',
      'Electrical system',
      'Control board',
      'Motor & drive',
      'Structural integrity',
    ];
  }

  List<String> _getExclusions(String assetName) {
    final type = assetName.toLowerCase();
    if (type.contains('refrigerator') || type.contains('fridge')) {
      return [
        'Cosmetic damage (dents, scratches)',
        'Light bulbs & filters',
        'Improper installation damage',
        'Power surge damage (without surge protector)',
      ];
    } else if (type.contains('washer') || type.contains('washing')) {
      return [
        'Hoses & external connections',
        'Cosmetic damage',
        'Damage from overloading',
        'Use with non-approved detergents',
      ];
    } else if (type.contains('tv')) {
      return [
        'Screen burn-in / image retention',
        'Cosmetic damage (scratches, cracks)',
        'Wall mount hardware & installation',
        'Damage from power surges',
      ];
    }
    return [
      'Cosmetic damage (dents, scratches)',
      'Accessories & consumables',
      'Improper installation damage',
      'Use outside specifications',
    ];
  }

  Future<void> _launchPhone(String phone) async {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('tel:$digits');
    try {
      await launchUrl(uri);
    } on Object catch (_) {}
  }

  Future<void> _launchUrl(String url) async {
    var normalizedUrl = url.trim();
    if (!normalizedUrl.startsWith('http://') &&
        !normalizedUrl.startsWith('https://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Object catch (_) {}
  }

  Widget _buildAccordionSection(
    ResponsiveUtils responsive, {
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(responsive.spacing(16)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate500,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.slate500,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) child,
        ],
      ),
    );
  }
}