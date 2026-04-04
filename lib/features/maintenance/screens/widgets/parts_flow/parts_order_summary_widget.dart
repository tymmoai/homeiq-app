import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../ai_fix_models.dart';
import 'order_detail_row_widget.dart';

class PartsOrderSummaryWidget extends StatelessWidget {
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final String? trackingId;
  final String? expectedDelivery;
  final double subtotal;
  final VoidCallback onBackToHome;

  const PartsOrderSummaryWidget({
    super.key,
    required this.parts,
    required this.selectedPartsIndexes,
    required this.trackingId,
    required this.expectedDelivery,
    required this.subtotal,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    const shipping = 9.99;
    final tax = subtotal * 0.08;
    final total = subtotal + shipping + tax;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20), vertical: responsive.spacing(32)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: responsive.spacing(20)),
          // Success Icon - larger and more prominent
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success, // Green background
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.check, size: responsive.iconSize(48), color: Colors.white),
          ),
          SizedBox(height: responsive.spacing(24)),
          // Title - larger and bolder
          Text(
            'Order Confirmed!',
            style: TextStyle(
              fontSize: responsive.fontSize(28),
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: responsive.spacing(32)),
          // Order Details Card - clean and professional
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Details with proper formatting
                OrderDetailRowWidget(
                  label: 'Part Order:',
                  value: selectedPartsIndexes
                      .map((i) => parts[i].name)
                      .join(' + '),
                  showDivider: true,
                ),
                OrderDetailRowWidget(
                  label: 'Tracking ID:',
                  value: trackingId ?? '-',
                  showDivider: true,
                ),
                OrderDetailRowWidget(
                  label: 'Order Total:',
                  value: '\$${total.toStringAsFixed(2)}',
                  showDivider: true,
                ),
                OrderDetailRowWidget(
                  label: 'Expected Delivery:',
                  value: expectedDelivery ?? 'TBD',
                  showDivider: false,
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(48)),
          // Back to Home Button - capsule format
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBackToHome,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                elevation: 2,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
              child: Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPrimary,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(12)),
          // View My Orders Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/orders'),
              icon: Icon(Icons.receipt_long, size: responsive.iconSize(18)),
              label: Text(
                'View My Orders',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(20)),
        ],
      ),
    );
  }
}