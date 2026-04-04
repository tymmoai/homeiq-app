import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';

class InstallmentOptionsScreen extends StatefulWidget {
  final double totalAmount;

  const InstallmentOptionsScreen({super.key, required this.totalAmount});

  @override
  State<InstallmentOptionsScreen> createState() => _InstallmentOptionsScreenState();
}

class _InstallmentOptionsScreenState extends State<InstallmentOptionsScreen> {
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.background;

  String? _selectedPlanId;

  // Installment plans with different tenures
  List<Map<String, dynamic>> get _installmentPlans => [
    {
      'id': 'installment_3',
      'months': 3,
      'interestRate': 0.0,
      'monthlyAmount': widget.totalAmount / 3.0,
      'totalAmount': widget.totalAmount,
      'processingFee': 0.0,
      'description': '0% Interest \u2014 No Extra Cost',
    },
    {
      'id': 'installment_6',
      'months': 6,
      'interestRate': 12.0,
      'monthlyAmount': _calculateInstallment(widget.totalAmount, 12.0, 6),
      'totalAmount':
          _calculateInstallment(widget.totalAmount, 12.0, 6) * 6.0 + 99.0, // with fee
      'processingFee': 99.0,
      'description': '12% annual interest',
    },
    {
      'id': 'installment_9',
      'months': 9,
      'interestRate': 13.0,
      'monthlyAmount': _calculateInstallment(widget.totalAmount, 13.0, 9),
      'totalAmount':
          _calculateInstallment(widget.totalAmount, 13.0, 9) * 9.0 + 149.0, // with fee
      'processingFee': 149.0,
      'description': '13% annual interest',
    },
    {
      'id': 'installment_12',
      'months': 12,
      'interestRate': 15.0,
      'monthlyAmount': _calculateInstallment(widget.totalAmount, 15.0, 12),
      'totalAmount':
          _calculateInstallment(widget.totalAmount, 15.0, 12) * 12.0 + 199.0, // with fee
      'processingFee': 199.0,
      'description': '15% annual interest',
    },
  ];

  // Calculate installment using reducing balance method
  double _calculateInstallment(double principal, double annualRate, int months) {
    if (annualRate == 0) return principal / months;

    final monthlyRate = annualRate / (12 * 100);
    final compoundFactor = pow(1 + monthlyRate, months);
    final installmentAmount =
        (principal * monthlyRate * compoundFactor) /
        (compoundFactor - 1);
    return installmentAmount;
  }

  void _confirmInstallmentPlan() {
    if (_selectedPlanId == null) return;

    final selectedPlan = _installmentPlans.firstWhere(
      (plan) => plan['id'] == _selectedPlanId,
      orElse: () => _installmentPlans.first,
    );

    // Return the selected installment plan to checkout screen
    context.pop(selectedPlan);
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: _headerColor,
            size: responsive.iconSize(24.0),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Installment Plans',
          style: TextStyle(
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.w600,
            color: _textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: responsive.padding(all: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Total Amount Card
                  Container(
                    padding: responsive.padding(all: 16),
                    decoration: BoxDecoration(
                      color: _headerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(12.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14.0),
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        Text(
                          '\$${widget.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(18.0),
                            fontWeight: FontWeight.bold,
                            color: _headerColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  responsive.heightBox(24.0),

                  // Installment Plans Title
                  Text(
                    'Select Installment Plan',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  responsive.heightBox(12.0),

                  // Installment Plans List
                  ..._installmentPlans.map(
                    (plan) =>
                        _buildInstallmentPlanTile(responsive: responsive, plan: plan),
                  ),

                  // Info Card
                  responsive.heightBox(16.0),
                  Container(
                    padding: responsive.padding(all: 16),
                    decoration: BoxDecoration(
                      color: AppColors.infoBackground,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(12.0),
                      ),
                      border: Border.all(color: AppColors.infoBorder),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: responsive.iconSize(20.0),
                          color: AppColors.infoDark,
                        ),
                        responsive.widthBox(12.0),
                        Expanded(
                          child: Text(
                            'Monthly installments will be charged to your credit or debit card. You can pay off the remaining balance at any time.',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12.0),
                              color: AppColors.infoDarkest,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  responsive.heightBox(100.0), // Bottom padding
                ],
              ),
            ),
          ),

          // Confirm Button
          Container(
            padding: responsive.padding(all: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedPlanId != null
                      ? _confirmInstallmentPlan
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerColor,
                    foregroundColor: Colors.white,
                    padding: responsive.padding(vertical: 16),
                    elevation: 0,
                  ),
                  child: Text(
                    'Confirm Installment Plan',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallmentPlanTile({
    required ResponsiveUtils responsive,
    required Map<String, dynamic> plan,
  }) {
    final isSelected = _selectedPlanId == plan['id'];
    final months = plan['months'] as int;
    final monthlyAmount = plan['monthlyAmount'] as double;
    final totalAmount = plan['totalAmount'] as double;
    final interestRate = plan['interestRate'] as double;
    final processingFee = plan['processingFee'] as double;
    final description = plan['description'] as String;
    final isNoCost = interestRate == 0;

    return Padding(
      padding: responsive.padding(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() => _selectedPlanId = plan['id'] as String);
        },
        child: Container(
          padding: responsive.padding(all: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
            border: Border.all(
              color: isSelected ? _headerColor : AppColors.gray300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Radio Button
                  Container(
                    width: responsive.iconSize(20.0),
                    height: responsive.iconSize(20.0),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? _headerColor : AppColors.gray400,
                        width: 2,
                      ),
                      color: isSelected ? _headerColor : Colors.transparent,
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            size: responsive.iconSize(14.0),
                            color: Colors.white,
                          )
                        : null,
                  ),
                  responsive.widthBox(12.0),

                  // Tenure
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$months Months',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16.0),
                                fontWeight: FontWeight.bold,
                                color: _textPrimary,
                              ),
                            ),
                            if (isNoCost) ...[
                              responsive.widthBox(8.0),
                              Container(
                                padding: responsive.padding(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.successSoft,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusBadge,
                                  ),
                                  border: Border.all(
                                    color: AppColors.successBorder,
                                  ),
                                ),
                                child: Text(
                                  'NO COST',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(10.0),
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.successMaterialDark,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        responsive.heightBox(4.0),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12.0),
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              responsive.heightBox(12.0),
              Divider(color: AppColors.gray200),
              responsive.heightBox(12.0),

              // Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Monthly Payment',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12.0),
                          color: _textSecondary,
                        ),
                      ),
                      responsive.heightBox(4.0),
                      Text(
                        '\$${monthlyAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(18.0),
                          fontWeight: FontWeight.bold,
                          color: _headerColor,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Total Amount',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12.0),
                          color: _textSecondary,
                        ),
                      ),
                      responsive.heightBox(4.0),
                      Text(
                        '\$${totalAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Processing Fee
              if (processingFee > 0) ...[
                responsive.heightBox(8.0),
                Text(
                  'Includes processing fee of \$${processingFee.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(11.0),
                    color: _textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
