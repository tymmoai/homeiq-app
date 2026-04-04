import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../ai_fix_models.dart';
import 'booking_detail_section_widget.dart';

class TechnicianBookingConfirmationWidget extends StatelessWidget {
  final TechnicianOption? selectedTechnician;
  final String? bookingId;
  final String? dispatchId;
  final Map<String, String> deliveryAddress;
  final String? selectedSlot;
  final VoidCallback onBackToAsset;

  const TechnicianBookingConfirmationWidget({
    super.key,
    required this.selectedTechnician,
    required this.bookingId,
    required this.dispatchId,
    required this.deliveryAddress,
    required this.selectedSlot,
    required this.onBackToAsset,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final tech = selectedTechnician;
    if (tech == null) {
      return const SizedBox.shrink();
    }

    final techFee = tech.fee;
    final techTax = techFee * 0.08;
    final total = techFee + techTax;

    String visitDate = 'TBD';
    String visitTime = '';
    if (selectedSlot != null) {
      final parts = selectedSlot!.split(' at ');
      if (parts.length == 2) {
        visitDate = parts[0];
        visitTime = parts[1];
      }
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(2), vertical: responsive.spacing(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success,
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
          SizedBox(height: responsive.spacing(16)),
          Text(
            'Booking Confirmed!',
            style: TextStyle(
              fontSize: responsive.fontSize(28),
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: responsive.spacing(6)),
          Text(
            'Booking ID: ${bookingId ?? '-'}',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textQuaternary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: responsive.spacing(20)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(18)),
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
                BookingDetailSectionWidget(
                  icon: Icons.person_outline,
                  label: 'TECHNICIAN',
                  value: tech.name,
                  additionalInfo: tech.rating.toStringAsFixed(1),
                  showRating: true,
                ),
                SizedBox(height: responsive.spacing(16)),
                BookingDetailSectionWidget(
                  icon: Icons.calendar_today,
                  label: 'VISIT DATE',
                  value: visitDate,
                  additionalInfo: visitTime.isNotEmpty ? visitTime : null,
                ),
                SizedBox(height: responsive.spacing(16)),
                BookingDetailSectionWidget(
                  icon: Icons.location_on,
                  label: 'SERVICE ADDRESS',
                  value:
                      '${deliveryAddress['street']}, ${deliveryAddress['city']}, ${deliveryAddress['state']} ${deliveryAddress['zip']}',
                ),
                SizedBox(height: responsive.spacing(16)),
                BookingDetailSectionWidget(
                  icon: Icons.phone,
                  label: 'CONTACT',
                  value: deliveryAddress['name'] ?? '',
                  additionalInfo: deliveryAddress['phone'] ?? '',
                ),
                SizedBox(height: responsive.spacing(18)),
                Divider(height: 1, thickness: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Technician Fee',
                      style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textDark),
                    ),
                    Text(
                      '\$${techFee.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(10)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tax (8%)',
                      style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textDark),
                    ),
                    Text(
                      '\$${techTax.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(12)),
                Divider(height: 1, thickness: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(12)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      '\$${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(32)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBackToAsset,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(16)),
                elevation: 0,
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
          // View Active Services Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/active-services'),
              icon: Icon(Icons.home_repair_service, size: responsive.iconSize(18)),
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
        ],
      ),
    );
  }
}