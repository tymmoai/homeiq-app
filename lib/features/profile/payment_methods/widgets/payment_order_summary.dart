import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import 'payment_types.dart';

/// Displays the order summary card with line items and total.
class PaymentOrderSummary extends StatelessWidget {
  final List<OrderSummaryItem> orderSummaryItems;
  final double total;

  const PaymentOrderSummary({
    super.key,
    required this.orderSummaryItems,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: responsive.spacing(10.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.receipt_outlined,
                size: responsive.iconSize(20.0),
                color: AppColors.textSecondary,
              ),
              responsive.widthBox(8.0),
              Text(
                'Order Summary',
                style: TextStyle(
                  fontSize: responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          responsive.heightBox(16.0),
          ...orderSummaryItems.asMap().entries.expand((entry) {
            final item = entry.value;
            final isLast = entry.key == orderSummaryItems.length - 1;
            return [
              _buildOrderItem(
                responsive,
                item.label,
                item.amount,
                isDiscount: item.isDiscount,
              ),
              if (!isLast) responsive.heightBox(10.0),
            ];
          }),
          responsive.heightBox(16.0),
          Divider(height: 1, color: AppColors.divider),
          responsive.heightBox(16.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: responsive.fontSize(18.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: responsive.fontSize(22.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(
    ResponsiveUtils responsive,
    String name,
    double price, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: isDiscount ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          '${price < 0 ? '-' : ''}\$${price.abs().toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            color: isDiscount ? AppColors.success : AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
