import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Condition selector for Cleaning & Outdoor service flows.
///
/// Matches web's condition step with multipliers:
/// - Regular Maintenance (1.0x)
/// - Deep Cleaning / Moderate Buildup (1.3-1.5x)
/// - Post-Renovation / Heavy/Overgrown (1.6-2.0x)
class ConditionSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>> conditions;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const ConditionSelector({
    super.key,
    required this.formData,
    required this.title,
    required this.subtitle,
    required this.conditions,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  /// Cleaning condition options
  static List<Map<String, dynamic>> cleaningConditions = [
    {
      'name': 'Regular Cleaning',
      'desc': 'Standard cleaning for well-maintained spaces',
      'icon': Icons.cleaning_services_rounded,
      'multiplier': 1.0,
      'color': AppColors.success,
    },
    {
      'name': 'Deep Cleaning',
      'desc': 'Thorough cleaning for spaces that need extra attention',
      'icon': Icons.auto_fix_high_rounded,
      'multiplier': 1.5,
      'color': AppColors.warningOrange,
    },
    {
      'name': 'Post-Renovation',
      'desc': 'Heavy-duty cleaning after construction or renovation',
      'icon': Icons.construction_rounded,
      'multiplier': 2.0,
      'color': AppColors.error,
    },
  ];

  /// Outdoor condition options
  static List<Map<String, dynamic>> outdoorConditions = [
    {
      'name': 'Regular Maintenance',
      'desc': 'Routine upkeep, well-maintained area',
      'icon': Icons.eco_rounded,
      'multiplier': 1.0,
      'color': AppColors.success,
    },
    {
      'name': 'Moderate Buildup',
      'desc': '1-2 months without maintenance',
      'icon': Icons.grass_rounded,
      'multiplier': 1.3,
      'color': AppColors.warningOrange,
    },
    {
      'name': 'Heavy / Overgrown',
      'desc': '3+ months without maintenance',
      'icon': Icons.forest_rounded,
      'multiplier': 1.6,
      'color': AppColors.error,
    },
  ];

  @override
  State<ConditionSelector> createState() => _ConditionSelectorState();
}

class _ConditionSelectorState extends State<ConditionSelector> {
  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selected = widget.formData.condition;

    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: responsive.padding(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                responsive.heightBox(8),
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(20),

                ...List.generate(widget.conditions.length, (i) {
                  final cond = widget.conditions[i];
                  final isSelected = selected == cond['name'];
                  final multiplier = cond['multiplier'] as double;
                  final condColor = cond['color'] as Color;

                  return Padding(
                    padding: responsive.padding(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.condition = cond['name'] as String;
                      }),
                      child: BookingShadowCard(
                        isSelected: isSelected,
                        child: Row(
                          children: [
                            Container(
                              width: responsive.wp(12),
                              height: responsive.wp(12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? condColor.withValues(alpha: 0.1)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(
                                  responsive.borderRadius(12),
                                ),
                              ),
                              child: Icon(
                                cond['icon'] as IconData,
                                color: isSelected
                                    ? condColor
                                    : AppColors.gray600,
                                size: responsive.iconSize(24),
                              ),
                            ),
                            SizedBox(width: responsive.wp(3)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    cond['name'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(15),
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: responsive.hp(0.3)),
                                  Text(
                                    cond['desc'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (multiplier > 1.0) ...[
                                    SizedBox(height: responsive.hp(0.5)),
                                    Container(
                                      padding: responsive.padding(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: condColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusBadge,
                                        ),
                                      ),
                                      child: Text(
                                        '${multiplier}x pricing',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(11),
                                          fontWeight: FontWeight.w600,
                                          color: condColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                                size: responsive.iconSize(22),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                responsive.heightBox(20),
              ],
            ),
          ),
        ),
        BookingContinueButton(
          isValid: selected != null,
          onPressed: widget.onNext,
        ),
      ],
    );
  }
}
