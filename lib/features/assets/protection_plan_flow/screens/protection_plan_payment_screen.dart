// Protection Plan Payment Screen - same payment UI as service tab, with flow header (no blue)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../profile/payment_methods/widgets/unified_payment_content.dart';

class ProtectionPlanPaymentScreen extends StatelessWidget {
  final Map<String, dynamic> plan;
  final Map<String, dynamic> asset;
  final Map<String, dynamic> selectedPaymentOption;

  const ProtectionPlanPaymentScreen({
    super.key,
    required this.plan,
    required this.asset,
    required this.selectedPaymentOption,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final planName = plan['name'] as String? ?? AppStrings.protectionPlan;
    final assetName = asset['name'] as String? ?? 'Asset';

    // Get total from selectedPaymentOption (includes tax calculation from checkout)
    final total =
        (selectedPaymentOption['total'] as num?)?.toDouble() ??
        (selectedPaymentOption['value'] as num?)?.toDouble() ??
        0.0;
    final subtotal =
        (selectedPaymentOption['subtotal'] as num?)?.toDouble() ?? total;
    final tax = (selectedPaymentOption['tax'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildFlowAppBar(context, responsive),
      body: UnifiedPaymentContent(
        amount: total,
        serviceName: '$planName for $assetName',
        bookingId: null,
        orderSummaryItems: [
          OrderSummaryItem(label: 'Plan Cost', amount: subtotal),
          if (tax > 0) OrderSummaryItem(label: 'Tax (8%)', amount: tax),
        ],
        onPaymentComplete: (result) {
          if (result != null && result.success) {
            context.pushReplacementNamed(
              'protection-plan-confirmation',
              extra: {
                'plan': plan,
                'asset': asset,
                'selectedPaymentOption': selectedPaymentOption,
              },
            );
          } else if (result != null && !result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  result.errorMessage ??
                      'Payment was not completed. Please try again or use a different payment method.',
                ),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  /// Matches Review Plan screen header: blue (primary), white back icon and title.
  PreferredSizeWidget _buildFlowAppBar(
    BuildContext context,
    dynamic responsive,
  ) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      centerTitle: false,
      leadingWidth: 40,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        'Payment',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: responsive.fontSize(18.0),
        ),
      ),
    );
  }
}
