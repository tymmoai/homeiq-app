// Deductible Selection Screen - Choose deductible amount
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../utils/responsive_utils.dart';

class DeductibleSelectionScreen extends StatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final String billingPeriod; // 'monthly' or 'yearly'
  final double basePrice; // Price selected in previous screen

  const DeductibleSelectionScreen({
    super.key,
    required this.plan,
    required this.asset,
    required this.billingPeriod,
    required this.basePrice,
  });

  @override
  State<DeductibleSelectionScreen> createState() =>
      _DeductibleSelectionScreenState();
}

class _DeductibleSelectionScreenState extends State<DeductibleSelectionScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  // App theme colors
  Color get _headerColor => AppColors.headerBackground;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _borderColor = AppColors.divider;
  static const Color _accentGreen = AppColors.success;

  int _selectedDeductibleIndex = 0;

  // Deductible options with premium discounts (American insurance standard)
  // Higher deductible = Lower monthly/yearly premium
  final List<_DeductibleOption> _deductibleOptions = [
    _DeductibleOption(
      amount: 0,
      premiumDiscount: 0,
      discountPercentage: 0,
      label: 'No Deductible',
      description: 'Full coverage with no out-of-pocket costs',
      recommended: true,
    ),
    _DeductibleOption(
      amount: 25,
      premiumDiscount: 5,
      discountPercentage: 5,
      label: '\$25 Deductible',
      description: 'Save 5% on your premium - pay \$25 when filing a claim',
    ),
    _DeductibleOption(
      amount: 50,
      premiumDiscount: 10,
      discountPercentage: 10,
      label: '\$50 Deductible',
      description: 'Save 10% on your premium - pay \$50 when filing a claim',
    ),
    _DeductibleOption(
      amount: 75,
      premiumDiscount: 15,
      discountPercentage: 15,
      label: '\$75 Deductible',
      description: 'Save 15% on your premium - pay \$75 when filing a claim',
    ),
    _DeductibleOption(
      amount: 100,
      premiumDiscount: 20,
      discountPercentage: 20,
      label: '\$100 Deductible',
      description: 'Save 20% on your premium - pay \$100 when filing a claim',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final selectedOption = _deductibleOptions[_selectedDeductibleIndex];

    // Calculate adjusted price based on percentage discount
    final discountAmount =
        widget.basePrice * (selectedOption.discountPercentage / 100);
    final adjustedPrice = widget.basePrice - discountAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.plan['name'] ?? AppStrings.protectionPlan,
          style: TextStyle(
            color: AppColors.headerForeground,
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20)),
                    child: Container(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      decoration: BoxDecoration(
                        color: AppColors.primary05,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary20,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: AppColors.primary,
                            size: responsive.iconSize(20),
                          ),
                          SizedBox(width: responsive.spacing(12)),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'What is a deductible?',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(4)),
                                Text(
                                  'The amount you pay out-of-pocket when filing a claim. Higher deductibles lower your monthly/yearly premium cost.',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(13),
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

                  SizedBox(height: responsive.spacing(24)),

                  // Section Title
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20)),
                    child: Text(
                      'Select Deductible Amount',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                  ),

                  SizedBox(height: responsive.spacing(16)),

                  // Deductible Options
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20)),
                    itemCount: _deductibleOptions.length,
                    itemBuilder: (context, index) {
                      return _buildDeductibleOption(index);
                    },
                  ),

                  SizedBox(height: responsive.spacing(20)),
                ],
              ),
            ),
          ),

          // Bottom Bar with Price and Continue Button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Price Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        widget.billingPeriod == 'yearly'
                            ? 'Billed annually'
                            : 'Billed monthly',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          color: _textSecondary,
                        ),
                      ),
                      Row(
                        children: [
                          if (selectedOption.discountPercentage > 0) ...[
                            Text(
                              '\$${widget.basePrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: _textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            SizedBox(width: responsive.spacing(6)),
                          ],
                          Text(
                            '\$${adjustedPrice.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(20),
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                          if (selectedOption.discountPercentage > 0) ...[
                            SizedBox(width: responsive.spacing(6)),
                            Text(
                              'Save ${selectedOption.discountPercentage.toInt()}%',
                              style: TextStyle(
                                fontSize: responsive.fontSize(11),
                                color: _accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),

                  SizedBox(height: responsive.spacing(12)),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 4,
                        shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      ),
                      child: Text(
                        'Continue',
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

  Widget _buildDeductibleOption(int index) {
    final option = _deductibleOptions[index];
    final isSelected = _selectedDeductibleIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _selectedDeductibleIndex = index;
            });
          },
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(12)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primary : _borderColor,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
            ),
            child: Row(
              children: [
                // Radio Button
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : _borderColor,
                      width: 2,
                    ),
                    color: isSelected ? AppColors.primary : Colors.white,
                  ),
                  child: isSelected
                      ? Icon(Icons.check, size: responsive.iconSize(14), color: AppColors.textOnPrimary)
                      : null,
                ),

                SizedBox(width: responsive.spacing(12)),

                // Option Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            option.label,
                            style: TextStyle(
                              fontSize: responsive.fontSize(16),
                              fontWeight: FontWeight.w700,
                              color: isSelected ? AppColors.primary : _textPrimary,
                            ),
                          ),
                          if (option.recommended) ...[
                            SizedBox(width: responsive.spacing(8)),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _accentGreen,
                                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                              ),
                              child: Text(
                                'RECOMMENDED',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(10),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: responsive.spacing(4)),
                      Text(
                        option.description,
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          color: _textSecondary,
                        ),
                      ),
                      if (option.discountPercentage > 0) ...[
                        SizedBox(height: responsive.spacing(6)),
                        Text(
                          'Save ${option.discountPercentage.toInt()}% on premium',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: _accentGreen,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleContinue() {
    final selectedOption = _deductibleOptions[_selectedDeductibleIndex];

    // Calculate adjusted price based on percentage discount
    final discountAmount =
        widget.basePrice * (selectedOption.discountPercentage / 100);
    final adjustedPrice = widget.basePrice - discountAmount;

    // Navigate to checkout screen with deductible info
    context.pushNamed(
      'protection-plan-checkout',
      extra: {
        'plan': widget.plan,
        'asset': widget.asset,
        'selectedPaymentOption': {
          'label': widget.billingPeriod == 'yearly'
              ? '\$${adjustedPrice.toStringAsFixed(0)}/year'
              : '\$${adjustedPrice.toStringAsFixed(2)}/mo',
          'subtitle': widget.billingPeriod == 'yearly'
              ? 'Billed annually'
              : 'Billed monthly',
          'value': adjustedPrice,
          'deductible': selectedOption.amount,
          'deductibleDiscount': selectedOption.discountPercentage,
          'billingPeriod': widget.billingPeriod,
        },
      },
    );
  }
}

class _DeductibleOption {
  final int amount;
  final double premiumDiscount;
  final double discountPercentage;
  final String label;
  final String description;
  final bool recommended;

  _DeductibleOption({
    required this.amount,
    required this.premiumDiscount,
    required this.discountPercentage,
    required this.label,
    required this.description,
    this.recommended = false,
  });
}