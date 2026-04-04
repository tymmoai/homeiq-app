import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_shadow_card.dart';

/// Recurring service toggle widget for Cleaning & Outdoor service flows.
///
/// Matches web's recurring option:
/// - One-time vs Recurring toggle
/// - Frequency selection (Weekly, Bi-weekly, Monthly, Quarterly)
/// - Discount display per frequency
///
/// This is an EMBEDDED widget, not a standalone step.
/// It is placed inside BookingScheduleStep via `extraContent` callback.
class RecurringToggle extends StatefulWidget {
  final ServiceBookingFormData formData;
  final Map<String, double> discounts;

  const RecurringToggle({
    super.key,
    required this.formData,
    required this.discounts,
  });

  /// Cleaning recurring discounts
  static const cleaningDiscounts = {
    'Weekly': 0.15,
    'Bi-weekly': 0.12,
    'Monthly': 0.10,
    'Quarterly': 0.08,
  };

  /// Outdoor recurring discounts
  static const outdoorDiscounts = {
    'Weekly': 0.15,
    'Bi-weekly': 0.12,
    'Monthly': 0.10,
  };

  @override
  State<RecurringToggle> createState() => _RecurringToggleState();
}

class _RecurringToggleState extends State<RecurringToggle> {
  bool _isRecurring = false;

  @override
  void initState() {
    super.initState();
    _isRecurring = widget.formData.cleaningFrequency != null;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        responsive.heightBox(24),
        // Toggle
        BookingShadowCard(
          child: Row(
            children: [
              Container(
                padding: responsive.padding(all: 8),
                decoration: BoxDecoration(
                  color: _isRecurring
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
                ),
                child: Icon(
                  Icons.repeat_rounded,
                  color: _isRecurring ? AppColors.primary : AppColors.gray600,
                  size: responsive.iconSize(20),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recurring Service',
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Save with regular service schedules',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isRecurring,
                onChanged: (val) {
                  setState(() {
                    _isRecurring = val;
                    if (!val) widget.formData.cleaningFrequency = null;
                  });
                },
                activeThumbColor: AppColors.primary,
              ),
            ],
          ),
        ),

        // Frequency options
        if (_isRecurring) ...[
          responsive.heightBox(16),
          Text(
            'Frequency',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          responsive.heightBox(10),
          ...widget.discounts.entries.map((entry) {
            final isSelected = widget.formData.cleaningFrequency == entry.key;
            final discountPercent = (entry.value * 100).round();

            return Padding(
              padding: responsive.padding(bottom: 8),
              child: GestureDetector(
                onTap: () => setState(() {
                  widget.formData.cleaningFrequency = entry.key;
                }),
                child: Container(
                  padding: responsive.padding(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary05 : Colors.white,
                    borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.gray200,
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          entry.key,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: responsive.padding(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
                        ),
                        child: Text(
                          'Save $discountPercent%',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: AppColors.successMaterialDark,
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.wp(2)),
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? AppColors.primary : AppColors.gray400,
                        size: responsive.iconSize(20),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }
}
