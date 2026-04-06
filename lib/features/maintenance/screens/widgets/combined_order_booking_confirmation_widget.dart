import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:homeiq/core/constants/app_colors.dart';

import '../../../../utils/responsive_utils.dart';
import '../ai_fix_models.dart';

class CombinedOrderBookingConfirmationWidget extends StatelessWidget {
  final TechnicianOption technician;
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final String? trackingId;
  final String? bookingId;
  final String? dispatchId;
  final String? expectedDelivery;
  final String? selectedSlot;
  final Map<String, String> deliveryAddress;
  final VoidCallback onBackToAsset;

  const CombinedOrderBookingConfirmationWidget({
    super.key,
    required this.technician,
    required this.parts,
    required this.selectedPartsIndexes,
    required this.trackingId,
    required this.bookingId,
    required this.dispatchId,
    required this.expectedDelivery,
    required this.selectedSlot,
    required this.deliveryAddress,
    required this.onBackToAsset,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final partsSubtotal = parts
        .asMap()
        .entries
        .where((entry) => selectedPartsIndexes.contains(entry.key))
        .fold<double>(
          0,
          (sum, entry) =>
              sum + (entry.value.priceEncompass * entry.value.quantity),
        );
    const shipping = 9.99;
    final partsTax = partsSubtotal * 0.08;
    final partsTotal = partsSubtotal + shipping + partsTax;
    final techFee = technician.fee;
    final techTax = techFee * 0.08;
    final techTotal = techFee + techTax;
    final combinedTotal = partsTotal + techTotal;

    // Parse the selected slot to extract date and time
    String visitDate = 'TBD';
    String visitTime = '';
    if (selectedSlot != null) {
      final parts = selectedSlot!.split(' at ');
      if (parts.length == 2) {
        visitDate = parts[0];
        visitTime = parts[1];
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(4),
        vertical: responsive.spacing(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: responsive.spacing(24)),
          // Success Icon - green circle with checkmark
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.check,
              size: responsive.iconSize(40),
              color: Colors.white,
            ),
          ),
          SizedBox(height: responsive.spacing(24)),
          // Title
          Text(
            'Order & Booking Confirmed!',
            style: TextStyle(
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: responsive.spacing(32)),
          // Part Order Details Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.backgroundSlate100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Part Order row
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Part Order:',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: AppColors.slate500,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: Text(
                          selectedPartsIndexes
                              .map((i) => parts[i].name)
                              .join(' + '),
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textDark,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                // Divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.backgroundSlate50,
                ),
                SizedBox(height: responsive.spacing(14)),
                // Tracking ID row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tracking ID:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      trackingId ?? '-',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                // Order Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Order Total:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      '\$${partsTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                // Expected Delivery row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expected Delivery:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      expectedDelivery ?? 'TBD',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(16)),
          // Booking Details Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.backgroundSlate100, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Booking ID row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Booking ID:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      bookingId ?? '-',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.backgroundSlate50,
                ),
                SizedBox(height: responsive.spacing(14)),
                // Technician row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Technician:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '${technician.name} (',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.star,
                            size: responsive.iconSize(14),
                            color: AppColors.warningGold,
                          ),
                          Text(
                            ' ${technician.rating.toStringAsFixed(1)})',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                // Visit Date row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Visit Date:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          visitDate,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        if (visitTime.isNotEmpty) ...[
                          SizedBox(height: responsive.spacing(2)),
                          Text(
                            visitTime,
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.slate400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.backgroundSlate50,
                ),
                SizedBox(height: responsive.spacing(14)),
                // Service Address row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Service Address:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Expanded(
                      child: Text(
                        '${deliveryAddress['street']}, ${deliveryAddress['city']}, ${deliveryAddress['state']} ${deliveryAddress['zip']}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                // Contact row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Contact:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        '${deliveryAddress['name']} - ${deliveryAddress['phone']}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(14)),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: AppColors.backgroundSlate100,
                ),
                SizedBox(height: responsive.spacing(14)),
                // Technician Fee row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Technician Fee:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      '\$${techFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(8)),
                // Tax row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax (8%):',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      '\$${techTax.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(8)),
                // Technician Total row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Technician Total:',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.slate500,
                      ),
                    ),
                    Text(
                      '\$${techTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                if (dispatchId != null) ...[
                  SizedBox(height: responsive.spacing(14)),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: AppColors.backgroundSlate50,
                  ),
                  SizedBox(height: responsive.spacing(14)),
                  // Dispatch ID row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Dispatch ID:',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: AppColors.slate500,
                        ),
                      ),
                      Text(
                        dispatchId!,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(16)),
          // Combined Total Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(15)),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Combined Total:',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  '\$${combinedTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(16)),
          // Info Message Card - Blue background
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: responsive.iconSize(20),
                  color: Colors.blue.shade600,
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: Text(
                    'Your part will be delivered first, and the technician will visit on the scheduled date to install it. Thank you!',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: Colors.blue.shade800,
                      fontWeight: FontWeight.w500,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(32)),
          // Back to Asset Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBackToAsset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16)),
                elevation: 4,
                shadowColor: Colors.black.withValues(alpha: 0.2),
              ),
              child: Text(
                'Back to Asset',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textOnPrimary,
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
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(12)),
          // View Active Services Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/active-services'),
              icon: Icon(
                Icons.home_repair_service,
                size: responsive.iconSize(18),
              ),
              label: Text(
                'View Active Services',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
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
