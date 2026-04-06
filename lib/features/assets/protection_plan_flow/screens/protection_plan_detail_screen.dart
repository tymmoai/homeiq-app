// Protection Plan Detail Screen - Payment selection flow
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../utils/responsive_utils.dart';

class ProtectionPlanDetailScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final String? billingPeriod; // 'monthly' or 'yearly' from previous screen

  const ProtectionPlanDetailScreen({
    super.key,
    required this.plan,
    required this.asset,
    this.billingPeriod,
  });

  @override
  State<ProtectionPlanDetailScreen> createState() =>
      _ProtectionPlanDetailScreenState();
}

class _ProtectionPlanDetailScreenState
    extends State<ProtectionPlanDetailScreen> {
  // App theme colors
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _borderColor = AppColors.divider;
  static const Color _accentGreen = AppColors.success;

  int _selectedPaymentIndex = 0;
  bool _showWhatsCovered = false; // Closed by default
  bool _showFeatures = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final pricing = plan['pricing'] as Map<String, dynamic>;
    final features = plan['features'] as List<dynamic>;
    final coverage = plan['coverage'] as List<dynamic>?;

    // Build payment options from pricing map
    final paymentOptions = <_PaymentOption>[];
    final yearly = pricing['yearly'] as num?;
    final monthly = pricing['monthly'] as num?;
    final oneTime = pricing['oneTime'] as num?;

    num? yearlySavings;
    if (yearly != null && monthly != null) {
      yearlySavings = (monthly * 12) - yearly;
      if (yearlySavings <= 0) yearlySavings = null;
    }

    // If billing period is specified from previous screen, only show that option
    final showOnlySelectedPeriod = widget.billingPeriod != null;

    if (yearly != null &&
        (!showOnlySelectedPeriod || widget.billingPeriod == 'yearly')) {
      paymentOptions.add(
        _PaymentOption(
          label: '\$${yearly.toStringAsFixed(0)}/year',
          subtitle: yearlySavings != null
              ? 'Save \$${yearlySavings.toStringAsFixed(2)}/year'
              : 'Billed annually',
          isBest: true,
          value: yearly.toDouble(),
        ),
      );
    }
    if (monthly != null &&
        (!showOnlySelectedPeriod || widget.billingPeriod == 'monthly')) {
      paymentOptions.add(
        _PaymentOption(
          label: '\$${monthly.toStringAsFixed(2)}/mo',
          subtitle: 'Billed monthly',
          isBest: false,
          value: monthly.toDouble(),
        ),
      );
    }
    if (oneTime != null && !showOnlySelectedPeriod) {
      paymentOptions.add(
        _PaymentOption(
          label: '\$${oneTime.toStringAsFixed(0)}',
          subtitle: '1â€‘year coverage',
          isBest: false,
          value: oneTime.toDouble(),
        ),
      );
    }

    // Currently selected option for bottom bar
    _PaymentOption? selectedOption;
    if (paymentOptions.isNotEmpty) {
      var idx = _selectedPaymentIndex;
      if (idx < 0) idx = 0;
      if (idx >= paymentOptions.length) idx = paymentOptions.length - 1;
      selectedOption = paymentOptions[idx];
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 40,
        titleSpacing: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          AppStrings.protectionPlans,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Builder(
        builder: (context) {
          final responsive = ResponsiveUtils(context);
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan Header Card - Enhanced corporate styling with responsive design
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.all(responsive.spacing(16.0)),
                        padding: EdgeInsets.all(responsive.spacing(14.0)),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(20.0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: responsive.iconSize(48.0),
                                  height: responsive.iconSize(48.0),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        _headerColor.withValues(alpha: 0.1),
                                        _headerColor.withValues(alpha: 0.05),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      responsive.borderRadius(16.0),
                                    ),
                                    border: Border.all(
                                      color: _headerColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.star_rate,
                                    color: _headerColor,
                                    size: responsive.iconSize(26.0),
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(12.0)),
                                Expanded(
                                  child: Text(
                                    plan['name'] as String? ??
                                        AppStrings.protectionPlan,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(18.0),
                                      fontWeight: FontWeight.w700,
                                      color: _textPrimary,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (plan['badge'] != null)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsive.spacing(12.0),
                                      vertical: responsive.spacing(6.0),
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          _headerColor,
                                          _headerColor.withValues(alpha: 0.85),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        responsive.borderRadius(16.0),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _headerColor.withValues(
                                            alpha: 0.3,
                                          ),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      (plan['badge'] as String).toUpperCase(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: responsive.fontSize(10.0),
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: responsive.spacing(8.0)),
                            Text(
                              plan['description'] as String? ?? '',
                              style: TextStyle(
                                fontSize: responsive.fontSize(13.0),
                                color: _textSecondary,
                                height: 1.4,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(12.0)),
                            Wrap(
                              spacing: responsive.spacing(12.0),
                              runSpacing: responsive.spacing(8.0),
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: responsive.iconSize(16.0),
                                      color: _accentGreen,
                                    ),
                                    SizedBox(width: responsive.spacing(6.0)),
                                    Text(
                                      '1-year coverage',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(12.0),
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: responsive.iconSize(16.0),
                                      color: _accentGreen,
                                    ),
                                    SizedBox(width: responsive.spacing(6.0)),
                                    Text(
                                      '30-day money-back guarantee',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(12.0),
                                        color: _textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Choose Payment Plan section
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(16.0),
                          vertical: responsive.spacing(4.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CHOOSE YOUR PAYMENT PLAN',
                              style: TextStyle(
                                fontSize: responsive.fontSize(11.0),
                                letterSpacing: 0.8,
                                fontWeight: FontWeight.w700,
                                color: _textSecondary,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(12.0)),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(16.0),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < paymentOptions.length; i++)
                              _buildPaymentOptionTile(
                                responsive: responsive,
                                option: paymentOptions[i],
                                isSelected: _selectedPaymentIndex == i,
                                onTap: () {
                                  setState(() {
                                    _selectedPaymentIndex = i;
                                  });
                                },
                              ),
                          ],
                        ),
                      ),

                      SizedBox(height: responsive.spacing(16.0)),

                      // What's Covered accordion
                      if (coverage != null && coverage.isNotEmpty)
                        _buildAccordion(
                          responsive: responsive,
                          title: "What's Covered",
                          isExpanded: _showWhatsCovered,
                          onToggle: () {
                            setState(() {
                              _showWhatsCovered = !_showWhatsCovered;
                            });
                          },
                          children: coverage
                              .map(
                                (item) => Padding(
                                  padding: EdgeInsets.only(
                                    left: responsive.spacing(4.0),
                                    right: responsive.spacing(4.0),
                                    bottom: responsive.spacing(8.0),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: responsive.iconSize(18.0),
                                        color: _headerColor,
                                      ),
                                      SizedBox(width: responsive.spacing(8.0)),
                                      Expanded(
                                        child: Text(
                                          item as String,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12.0),
                                            color: _textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                      SizedBox(height: responsive.spacing(8.0)),

                      // Plan Features accordion
                      _buildAccordion(
                        responsive: responsive,
                        title: 'Plan Features',
                        isExpanded: _showFeatures,
                        onToggle: () {
                          setState(() {
                            _showFeatures = !_showFeatures;
                          });
                        },
                        children: features
                            .map(
                              (feature) => Padding(
                                padding: EdgeInsets.only(
                                  left: responsive.spacing(4.0),
                                  right: responsive.spacing(4.0),
                                  bottom: responsive.spacing(8.0),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: responsive.iconSize(18.0),
                                      color: _accentGreen,
                                    ),
                                    SizedBox(width: responsive.spacing(8.0)),
                                    Expanded(
                                      child: Text(
                                        feature as String,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12.0),
                                          color: _textPrimary,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),

                      SizedBox(height: responsive.spacing(16.0)),

                      // Help card - Enhanced styling with responsive design
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(16.0),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(responsive.spacing(16.0)),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                _headerColor.withValues(alpha: 0.03),
                                _headerColor.withValues(alpha: 0.01),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(14.0),
                            ),
                            border: Border.all(
                              color: _headerColor.withValues(alpha: 0.1),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: responsive.iconSize(20.0),
                                color: _textSecondary,
                              ),
                              SizedBox(width: responsive.spacing(12.0)),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Need help choosing?',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        fontWeight: FontWeight.w700,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: responsive.spacing(4.0)),
                                    Text(
                                      'Our experts are available 24/7 to help you select the perfect plan for your appliances.',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(12.0),
                                        color: _textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: responsive.spacing(24.0)),
                    ],
                  ),
                ),
              ),

              // Bottom sticky bar with responsive design
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(16.0),
                    vertical: responsive.spacing(12.0),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: _borderColor, width: 1),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (selectedOption != null) ...[
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SELECTED PLAN',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(10.0),
                                    letterSpacing: 0.8,
                                    fontWeight: FontWeight.w600,
                                    color: _textSecondary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(2.0)),
                                Text(
                                  selectedOption.label,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(16.0),
                                    fontWeight: FontWeight.w700,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (selectedOption.subtitle.isNotEmpty)
                              Flexible(
                                child: Text(
                                  selectedOption.subtitle,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(12.0),
                                    fontWeight: FontWeight.w500,
                                    color: selectedOption.isBest
                                        ? _accentGreen
                                        : _textSecondary,
                                  ),
                                  textAlign: TextAlign.right,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(12.0)),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedOption != null) {
                              // Navigate to deductible selection screen
                              try {
                                context.pushNamed(
                                  'deductible-selection',
                                  extra: {
                                    'plan': plan,
                                    'asset': widget.asset,
                                    'billingPeriod':
                                        widget.billingPeriod ?? 'yearly',
                                    'basePrice': selectedOption.value,
                                  },
                                );
                              } on Object catch (_) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      'Navigation error. Please restart the app.',
                                    ),
                                    backgroundColor: _headerColor,
                                  ),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _headerColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: responsive.buttonHeight(14.0),
                            ),
                          ),
                          child: Text(
                            'Select This Plan',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14.0),
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
          );
        },
      ),
    );
  }

  Widget _buildPaymentOptionTile({
    required ResponsiveUtils responsive,
    required _PaymentOption option,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(10.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        border: isSelected ? Border.all(color: _headerColor, width: 2) : null,
        borderRadius: BorderRadius.circular(responsive.borderRadius(14.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(responsive.borderRadius(14.0)),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(14.0),
            vertical: responsive.spacing(12.0),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: responsive.fontSize(15.0),
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(4.0)),
                    Text(
                      option.subtitle,
                      style: TextStyle(
                        fontSize: responsive.fontSize(12.0),
                        fontWeight: option.isBest
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: option.isBest ? _accentGreen : _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: responsive.iconSize(22.0),
                height: responsive.iconSize(22.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? _headerColor : _borderColor,
                    width: 2,
                  ),
                  color: isSelected ? _headerColor : Colors.white,
                ),
                child: isSelected
                    ? Icon(
                        Icons.check,
                        size: responsive.iconSize(13.0),
                        color: Colors.white,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAccordion({
    required ResponsiveUtils responsive,
    required String title,
    required bool isExpanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16.0)),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(14.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(
                responsive.borderRadius(14.0),
              ),
              onTap: onToggle,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(14.0),
                  vertical: responsive.spacing(12.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: _textSecondary,
                      size: responsive.iconSize(22.0),
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              Divider(height: 1, color: _borderColor),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(14.0),
                  vertical: responsive.spacing(12.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentOption {
  final String label;
  final String subtitle;
  final bool isBest;
  final double value;

  _PaymentOption({
    required this.label,
    required this.subtitle,
    required this.isBest,
    required this.value,
  });
}

// _BottomIconLabel class removed (design no longer uses these labels)
