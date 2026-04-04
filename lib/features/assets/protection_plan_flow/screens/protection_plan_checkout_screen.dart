// Protection Plan Checkout Screen - Review and confirm plan selection

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../utils/responsive_utils.dart';

class ProtectionPlanCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final Map<String, dynamic> selectedPaymentOption;

  const ProtectionPlanCheckoutScreen({
    super.key,
    required this.plan,
    required this.asset,
    required this.selectedPaymentOption,
  });

  @override
  State<ProtectionPlanCheckoutScreen> createState() =>
      _ProtectionPlanCheckoutScreenState();
}

class _ProtectionPlanCheckoutScreenState
    extends State<ProtectionPlanCheckoutScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  bool _showAllFeatures = false;

  Color get _headerColor => AppColors.headerBackground;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _borderColor = AppColors.divider;
  static const Color _accentGreen = AppColors.success;
  static const double _taxRate = 0.08; // 8% tax

  @override
  Widget build(BuildContext context) {
    final assetName = widget.asset['name'] as String? ?? 'Asset';
    final assetCategory = widget.asset['category'] as String? ?? '';
    final assetType = widget.asset['secondaryCategory'] as String? ?? '';
    final purchaseDate = widget.asset['purchaseDate'] as String? ?? '';
    final planName = widget.plan['name'] as String? ?? AppStrings.protectionPlan;
    final planProvider =
        widget.plan['provider'] as String? ?? AppStrings.brandProtection;
    final coverageYears = widget.plan['duration']?['years'] as int? ?? 1;
    final priceValue =
        (widget.selectedPaymentOption['value'] as num?)?.toDouble() ?? 0.0;
    final deductible =
        (widget.selectedPaymentOption['deductible'] as num?)?.toDouble() ?? 0.0;
    final billingPeriod =
        widget.selectedPaymentOption['billingPeriod'] as String? ?? 'yearly';

    // Calculate costs
    final subtotal = priceValue;
    final tax = subtotal * _taxRate;
    final total = subtotal + tax;
    final coverageStartDate = DateTime.now();
    final nextBillingDate = billingPeriod == 'yearly'
        ? DateTime(
            coverageStartDate.year + 1,
            coverageStartDate.month,
            coverageStartDate.day,
          )
        : DateTime(
            coverageStartDate.year,
            coverageStartDate.month + 1,
            coverageStartDate.day,
          );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        centerTitle: false,
        leadingWidth: 40,
        titleSpacing: 8,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          planName,
          style: TextStyle(
            color: AppColors.headerForeground,
            fontWeight: FontWeight.w600,
            fontSize: responsive.fontSize(18),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(responsive.spacing(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card 1: Asset Information
                  _buildCard(
                    title: 'Asset Information',
                    icon: Icons.inventory_2_outlined,
                    children: [
                      _buildInfoRow('Asset Name', assetName),
                      if (assetCategory.isNotEmpty) ...[
                        SizedBox(height: responsive.spacing(12)),
                        _buildInfoRow('Category', assetCategory),
                      ],
                      if (assetType.isNotEmpty) ...[
                        SizedBox(height: responsive.spacing(12)),
                        _buildInfoRow('Type', assetType),
                      ],
                      if (purchaseDate.isNotEmpty) ...[
                        SizedBox(height: responsive.spacing(12)),
                        _buildInfoRow('Purchase Date', purchaseDate),
                      ],
                    ],
                  ),

                  SizedBox(height: responsive.spacing(16)),

                  // Card 2: Plan Information
                  _buildCard(
                    title: 'Plan Details',
                    icon: Icons.shield_outlined,
                    children: [
                      _buildInfoRow('Plan Name', planName),
                      SizedBox(height: responsive.spacing(12)),
                      _buildInfoRow('Provider', planProvider),
                      SizedBox(height: responsive.spacing(12)),
                      _buildInfoRow(
                        'Coverage Duration',
                        '$coverageYears ${coverageYears == 1 ? "year" : "years"}',
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      _buildInfoRow(
                        'Coverage Starts',
                        '${coverageStartDate.month}/${coverageStartDate.day}/${coverageStartDate.year}',
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      _buildInfoRow(
                        'Payment Plan',
                        billingPeriod == 'yearly' ? 'Yearly' : 'Monthly',
                      ),
                      if (deductible > 0) ...[
                        SizedBox(height: responsive.spacing(12)),
                        _buildInfoRow(
                          'Deductible Per Claim',
                          '\$${deductible.toStringAsFixed(0)}',
                        ),
                      ],
                      // Key Features - Expandable
                      if (widget.plan['features'] != null &&
                          (widget.plan['features'] as List).isNotEmpty) ...[
                        SizedBox(height: responsive.spacing(16)),
                        Divider(height: 1, color: _borderColor),
                        SizedBox(height: responsive.spacing(16)),
                        Text(
                          'Key Features:',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(10)),
                        ...(widget.plan['features'] as List<dynamic>)
                            .take(
                              _showAllFeatures
                                  ? (widget.plan['features'] as List).length
                                  : 3,
                            )
                            .map((feature) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: responsive.iconSize(14),
                                      color: _accentGreen,
                                    ),
                                    SizedBox(width: responsive.spacing(8)),
                                    Expanded(
                                      child: Text(
                                        feature as String,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12),
                                          color: _textSecondary,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        if ((widget.plan['features'] as List).length > 3)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _showAllFeatures = !_showAllFeatures;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _showAllFeatures
                                    ? 'Show less'
                                    : '+${(widget.plan['features'] as List).length - 3} more features',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(11),
                                  color: AppColors.primary,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ],
                  ),

                  SizedBox(height: responsive.spacing(16)),

                  // Card 4: Cost Breakdown
                  _buildCard(
                    title: 'Price Breakdown',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      _buildCostRow(
                        '$planName (${billingPeriod == "yearly" ? "yearly" : "monthly"})',
                        subtotal,
                      ),
                      if (deductible > 0) ...[
                        SizedBox(height: responsive.spacing(12)),
                        _buildCostRow(
                          'Deductible (\$${deductible.toStringAsFixed(0)} per claim)',
                          0.0,
                          isInfo: true,
                        ),
                      ],
                      SizedBox(height: responsive.spacing(12)),
                      Divider(height: 1, color: _borderColor),
                      SizedBox(height: responsive.spacing(12)),
                      _buildCostRow('Subtotal', subtotal),
                      SizedBox(height: responsive.spacing(12)),
                      _buildCostRow('Sales Tax (8%)', tax),
                      SizedBox(height: responsive.spacing(16)),
                      Divider(height: 1, color: _borderColor),
                      SizedBox(height: responsive.spacing(16)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: TextStyle(
                              fontSize: responsive.fontSize(18),
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(22),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(8)),
                      Text(
                        billingPeriod == 'yearly'
                            ? 'Billed annually'
                            : 'Billed monthly',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          color: _textSecondary,
                        ),
                      ),
                      if (billingPeriod != 'onetime') ...[
                        SizedBox(height: responsive.spacing(12)),
                        Container(
                          padding: EdgeInsets.all(responsive.spacing(10)),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          ),
                          child: Text(
                            'You\'ll be charged \$${total.toStringAsFixed(2)} on ${nextBillingDate.month}/${nextBillingDate.day}/${nextBillingDate.year} every ${billingPeriod == "yearly" ? "year" : "month"}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(11),
                              color: _textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                  SizedBox(height: responsive.spacing(16)),

                  // Card 5: Important Information
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    decoration: BoxDecoration(
                      color: AppColors.primary05,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary20, width: 1),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: responsive.iconSize(20), color: AppColors.primary),
                        SizedBox(width: responsive.spacing(12)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Important Information',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(6)),
                              Text(
                                'Coverage begins immediately upon payment confirmation. You can cancel anytime within 30 days for a full refund. Terms and conditions apply.',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: _textSecondary,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: responsive.spacing(24)),
                ],
              ),
            ),
          ),

          // Bottom sticky bar
          SafeArea(
            top: false,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20), vertical: responsive.spacing(12)),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Total Amount',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(2)),
                          Text(
                            '\$${total.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(20),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        try {
                          context.pushNamed(
                            'protection-plan-payment',
                            extra: {
                              'plan': widget.plan,
                              'asset': widget.asset,
                              'selectedPaymentOption': {
                                ...widget.selectedPaymentOption,
                                'subtotal': subtotal,
                                'tax': tax,
                                'total': total,
                              },
                            },
                          );
                        } on Object catch (_) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                'Something went wrong. Please go back and try again.',
                              ),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Continue to Payment',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
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

  Widget _buildCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: responsive.iconSize(22), color: AppColors.primary),
              SizedBox(width: responsive.spacing(10)),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(17),
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(16)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: responsive.fontSize(14), color: _textSecondary),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount, {bool isInfo = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(fontSize: responsive.fontSize(14), color: _textSecondary),
          ),
        ),
        if (!isInfo)
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          )
        else
          Text(
            'Included',
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              color: _textSecondary,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }
}