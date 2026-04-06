import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

/// Card displaying the price breakdown (subtotal, add-ons, service fee, total).
class BookingReviewPriceCard extends StatelessWidget {
  final double itemsTotal;
  final double addonsTotal;
  final double serviceFee;

  const BookingReviewPriceCard({
    super.key,
    required this.itemsTotal,
    required this.addonsTotal,
    required this.serviceFee,
  });

  double get _total => itemsTotal + addonsTotal + serviceFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow(
            context,
            'Subtotal',
            '\$${itemsTotal.toStringAsFixed(0)}',
          ),
          if (addonsTotal > 0) ...[
            context.responsive.heightBox(10.0),
            _buildPriceRow(
              context,
              'Add-ons',
              '\$${addonsTotal.toStringAsFixed(0)}',
            ),
          ],
          context.responsive.heightBox(10.0),
          _buildPriceRow(
            context,
            'Service Fee',
            '\$${serviceFee.toStringAsFixed(0)}',
          ),
          Padding(
            padding: context.responsive.padding(vertical: 12),
            child: Divider(
              height: 1,
              color: AppColors.white.withValues(alpha: 0.2),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(18.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(24.0),
                  fontWeight: FontWeight.bold,
                  color: AppColors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive.fontSize(14.0),
            color: AppColors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive.fontSize(14.0),
            fontWeight: FontWeight.w500,
            color: AppColors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}
