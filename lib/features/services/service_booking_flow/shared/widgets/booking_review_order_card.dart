import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';

/// A label–value row used in booking review cards.
class BookingReviewDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const BookingReviewDetailRow({
    super.key,
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: context.responsive.padding(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(15.0),
                    color: AppColors.textQuaternary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              context.responsive.widthBox(16.0),
              Flexible(
                flex: 3,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(15.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: AppColors.gray200),
      ],
    );
  }
}

/// Card showing order details (service, date, time slot).
class BookingReviewOrderDetailsCard extends StatelessWidget {
  final ServiceBookingFormData formData;

  const BookingReviewOrderDetailsCard({super.key, required this.formData});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BookingReviewDetailRow(
            label: 'Service:',
            value: formData.selectedService ?? '',
            showDivider: true,
          ),
          BookingReviewDetailRow(
            label: 'Date:',
            value: formData.selectedDate != null
                ? DateFormat(
                    'EEEE, MMMM d, yyyy',
                  ).format(formData.selectedDate!)
                : '',
            showDivider: true,
          ),
          BookingReviewDetailRow(
            label: 'Time Slot:',
            value: formData.selectedTimeSlot ?? '',
            showDivider: false,
          ),
        ],
      ),
    );
  }
}
