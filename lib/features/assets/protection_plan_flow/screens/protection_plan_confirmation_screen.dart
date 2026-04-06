// Protection Plan Confirmation Screen

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/logger.dart';
import '../../../../providers/data_providers.dart';
import '../../../../services/order_service.dart';
import '../../../../services/protection_plan_service.dart';
import '../../../../utils/responsive_utils.dart';

class ProtectionPlanConfirmationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final Map<String, dynamic> selectedPaymentOption;

  const ProtectionPlanConfirmationScreen({
    super.key,
    required this.plan,
    required this.asset,
    required this.selectedPaymentOption,
  });

  @override
  ConsumerState<ProtectionPlanConfirmationScreen> createState() =>
      _ProtectionPlanConfirmationScreenState();
}

class _ProtectionPlanConfirmationScreenState
    extends ConsumerState<ProtectionPlanConfirmationScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Color get _headerColor => AppColors.primary;

  @override
  void initState() {
    super.initState();
    _saveOrder();
  }

  Future<void> _saveOrder() async {
    try {
      final planName =
          widget.plan['name'] as String? ?? AppStrings.protectionPlan;
      final assetName = widget.asset['name'] as String? ?? 'Asset';
      final assetId = widget.asset['id']?.toString() ?? '';
      final priceLabel =
          widget.selectedPaymentOption['label'] as String? ?? 'N/A';
      final price =
          widget.selectedPaymentOption['total'] ??
          widget.selectedPaymentOption['value'] ??
          0;
      final billingPeriod =
          widget.selectedPaymentOption['billingPeriod'] as String? ?? 'yearly';
      final coverageYears = widget.plan['duration']?['years'] as int? ?? 1;
      final features = (widget.plan['features'] as List?)?.cast<String>() ?? [];
      final deductible = widget.selectedPaymentOption['deductible']?.toString();
      final provider =
          widget.plan['provider'] as String? ?? AppStrings.brandProvider;

      // Calculate coverage dates
      final now = DateTime.now();
      final coverageEnd = DateTime(
        now.year + coverageYears,
        now.month,
        now.day,
      );

      // 1. Save order record via OrderService
      await OrderService.saveProtectionPlanOrder(
        planName: planName,
        assetName: assetName,
        priceLabel: priceLabel,
        totalAmount: (price is num) ? price.toDouble() : 0.0,
      );

      // 2. Save active protection plan via ProtectionPlanService
      if (assetId.isNotEmpty) {
        await ProtectionPlanService.saveActivePlan(
          assetId: assetId,
          planName: planName,
          billingPeriod: billingPeriod,
          price: (price is num) ? price.toDouble() : 0.0,
          priceLabel: priceLabel,
          coverageStart: now,
          coverageEnd: coverageEnd,
          deductible: deductible,
          provider: provider,
          features: features,
        );

        // 3. Mutate the asset map in-place so all references reflect the change
        widget.asset['warranty'] = 'Active';
        widget.asset['warrantyEndDate'] = coverageEnd.toIso8601String();
        widget.asset['protectionPlan'] = planName;
        widget.asset['protectionPlanBillingPeriod'] = billingPeriod;
        widget.asset['protectionPlanPrice'] = priceLabel;
        widget.asset['protectionPlanProvider'] = provider;
        widget.asset['hasActiveProtectionPlan'] = true;

        // 4. Invalidate assetsProvider so the list screen re-fetches and
        //    reflects the updated warranty status from the backend.
        ref.invalidate(assetsProvider);
      }
    } on Object catch (e) {
      AppLogger.error(
        'Error saving protection plan order: $e',
        tag: 'ProtectionPlan',
        error: e,
      );
      // Still allow navigation even if save fails
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetName = widget.asset['name'] as String? ?? 'Asset';
    final planName =
        widget.plan['name'] as String? ?? AppStrings.protectionPlan;
    final priceLabel =
        widget.selectedPaymentOption['label'] as String? ?? 'N/A';

    // Format dates without intl package - use plan duration when available
    final now = DateTime.now();
    final coverageYears = widget.plan['duration']?['years'] as int? ?? 1;
    final endDate = DateTime(now.year + coverageYears, now.month, now.day);
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
    final coverageStartDate =
        '${months[now.month - 1]} ${now.day.toString().padLeft(2, '0')}, ${now.year}';
    final coverageEndDate =
        '${months[endDate.month - 1]} ${endDate.day.toString().padLeft(2, '0')}, ${endDate.year}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: _headerColor),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(20)),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  color: AppColors.success,
                  size: responsive.iconSize(48),
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(24)),

            // Success Message
            Center(
              child: Text(
                AppStrings.protectionPlanActivated,
                style: TextStyle(
                  fontSize: responsive.fontSize(24),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: responsive.spacing(12)),
            Center(
              child: Text(
                'Your protection plan for $assetName is now active.',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            SizedBox(height: responsive.spacing(20)),

            // Plan Details Card
            Container(
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
                  Text(
                    'Plan Details',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildDetailRow('Plan Name', planName),
                  SizedBox(height: responsive.spacing(12)),
                  _buildDetailRow('Asset', assetName),
                  SizedBox(height: responsive.spacing(12)),
                  _buildDetailRow('Payment Plan', priceLabel),
                  SizedBox(height: responsive.spacing(12)),
                  _buildDetailRow('Coverage Start', coverageStartDate),
                  SizedBox(height: responsive.spacing(12)),
                  _buildDetailRow('Coverage End', coverageEndDate),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(20)),

            // What's Next Card
            Container(
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
                  Text(
                    'What\'s Next?',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  _buildNextStepItem(
                    'You\'ll receive a confirmation email shortly',
                  ),
                  _buildNextStepItem('Your plan is active and ready to use'),
                  _buildNextStepItem(
                    'Access your plan details anytime from the Assets tab',
                  ),
                ],
              ),
            ),

            SizedBox(height: responsive.spacing(32)),

            // View Asset Button (primary)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.go(
                    '/asset-detail',
                    extra: {'asset': widget.asset, 'skipPopup': true},
                  );
                },
                icon: Icon(
                  Icons.inventory_2_outlined,
                  size: responsive.iconSize(20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  elevation: 0,
                ),
                label: Text(
                  'View Asset',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            SizedBox(height: responsive.spacing(12)),

            // Back to Home Button (outlined)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/home');
                },
                icon: Icon(
                  Icons.home,
                  size: responsive.iconSize(20),
                  color: _headerColor,
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _headerColor,
                  side: BorderSide(color: _headerColor),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  elevation: 0,
                ),
                label: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: _headerColor,
                  ),
                ),
              ),
            ),

            SizedBox(height: responsive.spacing(24)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle,
            size: responsive.iconSize(20),
            color: AppColors.success,
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
