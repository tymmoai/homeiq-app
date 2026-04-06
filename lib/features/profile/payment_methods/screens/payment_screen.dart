import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../services/payment_service.dart';
import '../widgets/unified_payment_content.dart';

/// A full-screen payment page for processing payments.
/// Uses [UnifiedPaymentContent] so all flows share the same payment UI.
/// Optional [customAppBar]: use for asset tab flows (flow header). When null, shows blue header (service tab).
/// Optional [orderSummaryItems]: when null, uses default placeholder items and [amount] as total.
class PaymentScreen extends StatelessWidget {
  final double amount;
  final String serviceName;
  final String? bookingId;
  final PreferredSizeWidget? customAppBar;
  final List<OrderSummaryItem>? orderSummaryItems;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.serviceName,
    this.bookingId,
    this.customAppBar,
    this.orderSummaryItems,
  });

  /// Navigate to payment screen (service tab: blue header, default order summary)
  static Future<PaymentResult?> show({
    required BuildContext context,
    required double amount,
    required String serviceName,
    String? bookingId,
    List<OrderSummaryItem>? orderSummaryItems,
  }) async {
    return await Navigator.of(context).push<PaymentResult>(
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          amount: amount,
          serviceName: serviceName,
          bookingId: bookingId,
          orderSummaryItems: orderSummaryItems,
        ),
      ),
    );
  }

  static List<OrderSummaryItem> _defaultOrderSummary(double amount) {
    return [OrderSummaryItem(label: 'Service', amount: amount)];
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final items = orderSummaryItems ?? _defaultOrderSummary(amount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: customAppBar ?? _buildDefaultBlueAppBar(context, responsive),
      body: UnifiedPaymentContent(
        amount: amount,
        serviceName: serviceName,
        bookingId: bookingId,
        orderSummaryItems: items,
        onPaymentComplete: (result) {
          Navigator.of(context).pop(result);
        },
      ),
    );
  }

  PreferredSizeWidget _buildDefaultBlueAppBar(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    return AppBar(
      backgroundColor: AppColors.primary,
      elevation: 0,
      centerTitle: false,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: AppColors.white,
          size: responsive.iconSize(24.0),
        ),
        onPressed: () => Navigator.of(context).pop(null),
      ),
      title: Text(
        'Payment',
        style: TextStyle(
          fontSize: responsive.fontSize(18.0),
          fontWeight: FontWeight.w700,
          color: AppColors.white,
        ),
      ),
    );
  }
}
