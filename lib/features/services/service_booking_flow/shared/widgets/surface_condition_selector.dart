import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Surface condition selector for Painting service flow.
///
/// Matches web's PaintingFlow surface condition step:
/// - Good Condition (1.0x)
/// - Minor Damage (1.2x)
/// - Heavy Prep Needed (1.5x)
class SurfaceConditionSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const SurfaceConditionSelector({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<SurfaceConditionSelector> createState() =>
      _SurfaceConditionSelectorState();
}

class _SurfaceConditionSelectorState extends State<SurfaceConditionSelector> {
  static const _conditions = [
    {
      'name': 'Good Condition',
      'desc': 'Walls are smooth, clean, and ready for paint',
      'icon': Icons.check_circle_outline_rounded,
      'multiplier': 1.0,
      'color': AppColors.success,
      'detail': 'No prep work needed. Standard painting service.',
    },
    {
      'name': 'Minor Damage',
      'desc': 'Small cracks, holes, or peeling that need patching',
      'icon': Icons.handyman_rounded,
      'multiplier': 1.2,
      'color': AppColors.warningOrange,
      'detail': 'Light sanding, hole filling, and minor repairs included.',
    },
    {
      'name': 'Heavy Prep Needed',
      'desc': 'Major surface damage, old paint removal, or extensive repairs',
      'icon': Icons.construction_rounded,
      'multiplier': 1.5,
      'color': AppColors.error,
      'detail': 'Full surface prep: scraping, sanding, priming, and repair.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selected = widget.formData.surfaceCondition;

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
                  'Surface Condition',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'What condition are the surfaces in?',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(20),

                ...List.generate(_conditions.length, (i) {
                  final cond = _conditions[i];
                  final isSelected = selected == cond['name'];
                  final multiplier = cond['multiplier'] as double;
                  final condColor = cond['color'] as Color;

                  return Padding(
                    padding: responsive.padding(bottom: 14),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.surfaceCondition = cond['name'] as String;
                      }),
                      child: BookingShadowCard(
                        isSelected: isSelected,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
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
                                    color: isSelected ? condColor : AppColors.gray600,
                                    size: responsive.iconSize(24),
                                  ),
                                ),
                                SizedBox(width: responsive.wp(3)),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
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
                                          if (multiplier > 1.0) ...[
                                            SizedBox(width: responsive.wp(2)),
                                            Container(
                                              padding: responsive.padding(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: condColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(
                                                  AppDimensions.radiusBadge,
                                                ),
                                              ),
                                              child: Text(
                                                '+${((multiplier - 1) * 100).round()}%',
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
                                      SizedBox(height: responsive.hp(0.3)),
                                      Text(
                                        cond['desc'] as String,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12),
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(Icons.check_circle, color: AppColors.primary,
                                    size: responsive.iconSize(22)),
                              ],
                            ),
                            if (isSelected) ...[
                              SizedBox(height: responsive.hp(1)),
                              Container(
                                padding: responsive.padding(all: 12),
                                decoration: BoxDecoration(
                                  color: condColor.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(
                                    responsive.borderRadius(8),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: condColor,
                                      size: responsive.iconSize(16)),
                                    SizedBox(width: responsive.wp(2)),
                                    Expanded(
                                      child: Text(
                                        cond['detail'] as String,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(12),
                                          color: condColor,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
