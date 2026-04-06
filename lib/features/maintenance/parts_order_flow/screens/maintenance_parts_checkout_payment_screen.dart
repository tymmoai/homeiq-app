// Maintenance Parts Checkout Payment Screen - same payment UI, flow header (no blue)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../profile/payment_methods/widgets/unified_payment_content.dart';
import '../../../shared/models/maintenance_models.dart';

class MaintenancePartsCheckoutPaymentScreen extends StatelessWidget {
  final Reminder reminder;
  final List<dynamic> parts;
  final List<bool> selectedParts;
  final int subtotal;
  final Map<String, int> providerTotals;
  final Map<String, String> address;

  const MaintenancePartsCheckoutPaymentScreen({
    super.key,
    required this.reminder,
    required this.parts,
    required this.selectedParts,
    required this.subtotal,
    required this.providerTotals,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    const shipping = 9.99;
    final tax = subtotal * 0.08;
    final totalAmount = subtotal + shipping + tax;

    final orderSummaryItems = [
      OrderSummaryItem(label: 'Parts Subtotal', amount: subtotal.toDouble()),
      const OrderSummaryItem(label: 'Shipping', amount: shipping),
      OrderSummaryItem(label: 'Sales Tax (8%)', amount: tax),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildFlowAppBar(context, responsive),
      body: UnifiedPaymentContent(
        amount: totalAmount.toDouble(),
        serviceName: 'Parts Order',
        bookingId: null,
        orderSummaryItems: orderSummaryItems,
        onPaymentComplete: (result) {
          if (result != null && result.success) {
            final trackingId =
                'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
            final expectedDelivery = DateTime.now().add(
              const Duration(days: 6),
            );

            context.push(
              '/maintenance/parts-order-confirmation',
              extra: {
                'reminder': reminder,
                'parts': parts,
                'selectedParts': selectedParts,
                'subtotal': subtotal,
                'providerTotals': providerTotals,
                'address': address,
                'trackingId': trackingId,
                'expectedDelivery': expectedDelivery.toIso8601String(),
              },
            );
          } else if (result != null && !result.success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Payment failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      ),
    );
  }

  PreferredSizeWidget _buildFlowAppBar(
    BuildContext context,
    dynamic responsive,
  ) {
    return AppBar(
      backgroundColor: AppColors.white,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Payment',
        style: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w700,
          fontSize: responsive.fontSize(18.0),
        ),
      ),
    );
  }
}
