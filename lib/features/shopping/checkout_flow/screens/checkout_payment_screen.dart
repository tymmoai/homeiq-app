// Checkout Payment Screen for Asset Upgrade Flow - same payment UI, flow header (no blue)

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../profile/payment_methods/widgets/unified_payment_content.dart';

class CheckoutPaymentScreen extends StatelessWidget {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final int quantity;
  final Map<String, String> address;

  const CheckoutPaymentScreen({
    super.key,
    required this.product,
    required this.tradeInValue,
    required this.quantity,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    // Calculate totals
    final price = (product['discountPrice'] as int) * quantity;
    final subtotal = price.toDouble();
    final tradeInTotal = (tradeInValue * quantity).toDouble();
    final tax = (subtotal * 0.08).toDouble(); // 8% tax
    final totalAmount = subtotal - tradeInTotal + tax;

    final orderSummaryItems = <OrderSummaryItem>[
      OrderSummaryItem(label: 'Subtotal', amount: subtotal),
      if (tradeInTotal > 0)
        OrderSummaryItem(
          label: 'Trade-in Credit',
          amount: -tradeInTotal,
          isDiscount: true,
        ),
      OrderSummaryItem(label: 'Sales Tax (8%)', amount: tax),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildFlowAppBar(context, responsive),
      body: UnifiedPaymentContent(
        amount: totalAmount,
        serviceName: 'Upgrade Checkout',
        bookingId: null,
        orderSummaryItems: orderSummaryItems,
        onPaymentComplete: (result) {
          if (result != null && result.success) {
            final trackingId =
                'HQ${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
            final expectedDelivery = DateTime.now().add(
              const Duration(days: 6),
            );
            final confirmationExtra = {
              'product': product,
              'tradeInValue': tradeInValue,
              'quantity': quantity,
              'subtotal': subtotal,
              'tradeInTotal': tradeInTotal,
              'tax': tax,
              'totalAmount': totalAmount,
              'address': address,
              'trackingId': trackingId,
              'expectedDelivery': expectedDelivery.toIso8601String(),
            };
            // Pop payment to go to confirmation
            context.pop(confirmationExtra);
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

  /// Matches Cart screen header: blue (primary), white title and back icon.
  PreferredSizeWidget _buildFlowAppBar(
    BuildContext context,
    dynamic responsive,
  ) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
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
