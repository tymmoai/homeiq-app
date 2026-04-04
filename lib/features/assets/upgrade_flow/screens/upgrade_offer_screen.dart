import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class UpgradeOfferScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const UpgradeOfferScreen({super.key, required this.asset});

  @override
  State<UpgradeOfferScreen> createState() => _UpgradeOfferScreenState();
}

class _UpgradeOfferScreenState extends State<UpgradeOfferScreen> {
  Map<String, dynamic> get asset => widget.asset;

  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.background;

  int _calculateTradeInValue() {
    final currentYear = DateTime.now().year;
    final raw = asset['purchaseYear'];
    int purchaseYear;
    if (raw is int) {
      purchaseYear = raw;
    } else if (raw is String) {
      purchaseYear = int.tryParse(raw) ?? currentYear;
    } else {
      purchaseYear = currentYear;
    }
    final ageYears = currentYear - purchaseYear;
    const baseValue = 500;
    final ageDepreciation = (baseValue - (ageYears * 50)).clamp(0, baseValue);
    final healthScore = (asset['healthScore'] as num?)?.toDouble() ?? 7.0;
    final healthMultiplier = healthScore / 10.0;
    final pastRepairs = asset['pastRepairs'] as int? ?? 0;
    final repairPenalty = pastRepairs * 30;
    final value = (ageDepreciation * healthMultiplier) - repairPenalty;
    return value.clamp(50, baseValue).round();
  }

  /// Check if the asset's warranty is currently active
  bool _isWarrantyActive() {
    final warranty = asset['warranty']?.toString().toLowerCase() ?? '';
    if (warranty == 'expired') return false;
    final endDateStr = asset['warrantyEndDate']?.toString();
    if (endDateStr != null) {
      final endDate = DateTime.tryParse(endDateStr);
      if (endDate != null && endDate.isBefore(DateTime.now())) return false;
    }
    return warranty == 'active';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final assetName = asset['name'] as String? ?? 'Asset';
    final tradeInValue = _calculateTradeInValue();
    final hasActiveWarranty = _isWarrantyActive();

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        leadingWidth: 40,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_outlined, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: false,
        title: Text(
          'Upgrade Your $assetName',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: responsive.padding(all: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary Cards - Past Repairs & Trade-in Value
            _buildSummaryCards(responsive, tradeInValue),
            responsive.heightBox(20.0),

            // 1ï¸âƒ£ Trade-in Banner - First Section
            _buildTradeInBanner(responsive, assetName, tradeInValue),
            responsive.heightBox(24.0),

            // 2ï¸âƒ£ Choose Your Path - Second Section
            Text(
              'Choose Your Upgrade Path',
              style: TextStyle(
                fontSize: responsive.fontSize(20.0),
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            responsive.heightBox(6.0),
            Text(
              'Select the option that works best for you',
              style: TextStyle(
                fontSize: responsive.fontSize(14.0),
                color: _textSecondary,
              ),
            ),
            responsive.heightBox(20.0),
            // Only show 'Replace Under Warranty' when warranty is actually active
            if (hasActiveWarranty) ...[
              _buildUpgradeOptionCard(
                context,
                responsive,
                title: 'Replace Under Warranty',
                badgeText: 'FASTEST OPTION',
                icon: Icons.autorenew_outlined,
                description:
                    'Your warranty is active â€” get a quick replacement with minimal hassle and paperwork',
                benefits: [
                  'Quick approval process (24-48 hours)',
                  'Same or upgraded model',
                  'No upfront cost',
                  'Free installation included',
                ],
                isReplace: true,
              ),
              responsive.heightBox(16.0),
            ],
            _buildUpgradeOptionCard(
              context,
              responsive,
              title: 'Buy New Asset',
              badgeText: '\$$tradeInValue Trade-in Credit',
              icon: Icons.shopping_cart_outlined,
              description:
                  'Trade in your old asset and upgrade to the latest models with special financing and discounts',
              benefits: [
                'Get \$$tradeInValue instant credit',
                '0% APR financing for 12 months',
                'Latest technology & features',
                'Free delivery & installation',
              ],
              isReplace: false,
            ),
            responsive.heightBox(24.0),

            // 3ï¸âƒ£ Why Upgrade Section - Third Section
            _buildBenefitsSection(responsive),
          ],
        ),
      ),
    );
  }

  /// Build Summary Cards Row
  Widget _buildSummaryCards(ResponsiveUtils responsive, int tradeInValue) {
    final pastRepairs = asset['pastRepairs'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryTile(
            responsive: responsive,
            icon: Icons.build_outlined,
            iconColor: _headerColor,
            label: 'PAST REPAIRS',
            value: pastRepairs.toString(),
            subtitle: 'Service calls',
            valueColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
          ),
        ),
        responsive.widthBox(10.0),
        Expanded(
          child: _buildSummaryTile(
            responsive: responsive,
            icon: Icons.payments_outlined,
            iconColor: _headerColor,
            label: 'TRADE-IN VALUE',
            value: '\$$tradeInValue',
            subtitle: 'Instant credit',
            valueColor: AppColors.textPrimary,
            backgroundColor: AppColors.surface,
          ),
        ),
      ],
    );
  }

  /// Build individual summary tile
  Widget _buildSummaryTile({
    required ResponsiveUtils responsive,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtitle,
    required Color valueColor,
    required Color backgroundColor,
  }) {
    return Container(
      padding: responsive.padding(all: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(responsive.borderRadius(16.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: responsive.iconSize(44.0),
            height: responsive.iconSize(44.0),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: responsive.iconSize(24.0),
              color: iconColor,
            ),
          ),
          responsive.widthBox(14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(10.0),
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                responsive.heightBox(6.0),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.fontSize(26.0),
                    fontWeight: FontWeight.bold,
                    color: valueColor,
                    height: 1.0,
                  ),
                ),
                responsive.heightBox(4.0),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: responsive.fontSize(11.0),
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build Trade-in Banner
  Widget _buildTradeInBanner(
    ResponsiveUtils responsive,
    String assetName,
    int tradeInValue,
  ) {
    return Container(
      padding: responsive.padding(all: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: responsive.spacing(8.0),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon
          Row(
            children: [
              Container(
                width: responsive.fontSize(50.0),
                height: responsive.fontSize(50.0),
                decoration: BoxDecoration(
                  color: _headerColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(12.0),
                  ),
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  color: _headerColor,
                  size: responsive.fontSize(28.0),
                ),
              ),
              responsive.widthBox(14.0),
              Expanded(
                child: Text(
                  'Get Up to \$$tradeInValue Trade-in Value',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18.0),
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ),
            ],
          ),
          responsive.heightBox(14.0),
          Text(
            "We'll buy your old $assetName and give you instant credit towards your new purchase. Calculated based on age, condition, and brand.",
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: _textSecondary,
              height: 1.5,
            ),
          ),
          responsive.heightBox(16.0),
          // Benefits checkmarks
          _buildBenefitRow(responsive, 'Free pickup & evaluation'),
          responsive.heightBox(10.0),
          _buildBenefitRow(responsive, 'Same-day swap available'),
          responsive.heightBox(10.0),
          _buildBenefitRow(responsive, 'Eco-friendly recycling'),
        ],
      ),
    );
  }

  /// Benefit row with checkmark
  Widget _buildBenefitRow(ResponsiveUtils responsive, String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline_outlined,
          size: responsive.fontSize(20.0),
          color: _headerColor,
        ),
        responsive.widthBox(10.0),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              fontWeight: FontWeight.w500,
              color: _textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  /// Build Upgrade Option Card with benefits list
  Widget _buildUpgradeOptionCard(
    BuildContext context,
    ResponsiveUtils responsive, {
    required String title,
    required String badgeText,
    required IconData icon,
    required String description,
    required List<String> benefits,
    required bool isReplace,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: responsive.spacing(8.0),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with gray background
          Container(
            width: double.infinity,
            padding: responsive.padding(all: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(responsive.borderRadius(12.0)),
                topRight: Radius.circular(responsive.borderRadius(12.0)),
              ),
              border: Border(
                bottom: BorderSide(color: AppColors.gray200, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: responsive.fontSize(48.0),
                      height: responsive.fontSize(48.0),
                      decoration: BoxDecoration(
                        color: _headerColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          responsive.borderRadius(12.0),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: _headerColor,
                        size: responsive.fontSize(26.0),
                      ),
                    ),
                    responsive.widthBox(12.0),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: responsive.fontSize(17.0),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ),
                          responsive.widthBox(8.0),
                          Container(
                            padding: responsive.padding(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _headerColor,
                              borderRadius: BorderRadius.circular(
                                responsive.borderRadius(5.0),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: responsive.fontSize(11.0),
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                responsive.heightBox(12.0),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14.0),
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // Benefits section
          Padding(
            padding: responsive.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < benefits.length; i++) ...[
                  _buildBenefitItem(responsive, benefits[i]),
                  if (i < benefits.length - 1) responsive.heightBox(12.0),
                ],
              ],
            ),
          ),
          // Button section
          Padding(
            padding: responsive.padding(all: 16),
            child: SizedBox(
              width: double.infinity,
              height: responsive.buttonHeight(48.0),
              child: ElevatedButton(
                onPressed: () {
                  if (isReplace) {
                    context.push('/upgrade-offer/replace', extra: asset);
                  } else {
                    context.push(
                      '/upgrade-offer/buy-new',
                      extra: {
                        'asset': asset,
                        'tradeInValue': _calculateTradeInValue(),
                      },
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: responsive.padding(vertical: 14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      size: responsive.fontSize(20.0),
                      color: Colors.white,
                    ),
                    responsive.widthBox(8.0),
                    Text(
                      isReplace
                          ? 'Start Replacement Process'
                          : 'Browse New Products',
                      style: TextStyle(
                        fontSize: responsive.fontSize(15.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build individual benefit item
  Widget _buildBenefitItem(ResponsiveUtils responsive, String benefit) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.check_circle,
          size: responsive.fontSize(20.0),
          color: _headerColor,
        ),
        responsive.widthBox(10.0),
        Expanded(
          child: Text(
            benefit,
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  /// Build Benefits/Why Upgrade Section
  Widget _buildBenefitsSection(ResponsiveUtils responsive) {
    final benefits = [
      {
        'icon': Icons.flash_on_outlined,
        'title': 'Save on Energy Bills',
        'description':
            'New models are up to 40% more energy efficient, saving you money every month',
        'bgColor': AppColors.surface,
        'iconColor': _headerColor,
      },
      {
        'icon': Icons.shield_outlined,
        'title': 'Better Warranty Coverage',
        'description':
            'New products come with extended warranties and comprehensive protection plans',
        'bgColor': AppColors.surface,
        'iconColor': _headerColor,
      },
      {
        'icon': Icons.stars_outlined,
        'title': 'Latest Smart Features',
        'description':
            'Get WiFi connectivity, app control, and AI-powered features for modern living',
        'bgColor': AppColors.surface,
        'iconColor': _headerColor,
      },
    ];

    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: responsive.spacing(8.0),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why Upgrade Now?',
            style: TextStyle(
              fontSize: responsive.fontSize(18.0),
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          responsive.heightBox(14.0),
          Column(
            children: [
              for (int i = 0; i < benefits.length; i++) ...[
                _buildWhyUpgradeCard(responsive, benefits[i]),
                if (i < benefits.length - 1) ...[
                  responsive.heightBox(1.0),
                  Divider(
                    color: AppColors.gray400.withValues(alpha: 0.15),
                    thickness: 1,
                  ),
                  responsive.heightBox(1.0),
                ],
              ],
            ],
          ),
        ],
      ),
    );
  }

  /// Build individual why upgrade card
  Widget _buildWhyUpgradeCard(
    ResponsiveUtils responsive,
    Map<String, dynamic> benefit,
  ) {
    return Container(
      padding: responsive.padding(all: 12),
      decoration: BoxDecoration(
        color: benefit['bgColor'] as Color,
        borderRadius: BorderRadius.circular(responsive.borderRadius(10.0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            benefit['icon'] as IconData,
            size: responsive.fontSize(32.0),
            color: benefit['iconColor'] as Color,
          ),
          responsive.widthBox(12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  benefit['title'] as String,
                  style: TextStyle(
                    fontSize: responsive.fontSize(15.0),
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                responsive.heightBox(4.0),
                Text(
                  benefit['description'] as String,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13.0),
                    color: _textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
