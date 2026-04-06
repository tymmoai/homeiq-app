import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Packing preference selector for Moving service flow.
///
/// Matches web's MovingFlow packing step:
/// - No Packing (1.0x)
/// - Partial Packing (1.15x)
/// - Full Packing (1.3x)
class PackingSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final double baseTotal;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const PackingSelector({
    super.key,
    required this.formData,
    required this.baseTotal,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<PackingSelector> createState() => _PackingSelectorState();
}

class _PackingSelectorState extends State<PackingSelector> {
  static const _packingOptions = [
    {
      'name': 'No Packing',
      'desc': 'I\'ll pack everything myself',
      'icon': Icons.inventory_2_outlined,
      'multiplier': 1.0,
      'tag': '',
    },
    {
      'name': 'Partial Packing',
      'desc': 'Pack fragile & delicate items only',
      'icon': Icons.local_shipping_outlined,
      'multiplier': 1.15,
      'tag': 'Popular',
    },
    {
      'name': 'Full Packing',
      'desc': 'We pack everything for you',
      'icon': Icons.all_inbox_rounded,
      'multiplier': 1.3,
      'tag': 'Recommended',
    },
  ];

  String? _selectedPacking;

  @override
  void initState() {
    super.initState();
    _selectedPacking =
        widget.formData.furnitureType; // Reuse field for packing choice
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

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
                  'Packing Service',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'Do you need packing assistance?',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(20),

                ...List.generate(_packingOptions.length, (i) {
                  final option = _packingOptions[i];
                  final isSelected = _selectedPacking == option['name'];
                  final multiplier = option['multiplier'] as double;
                  final extraCost = widget.baseTotal * (multiplier - 1.0);
                  final tag = option['tag'] as String;

                  return Padding(
                    padding: responsive.padding(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedPacking = option['name'] as String;
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
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(
                                  responsive.borderRadius(12),
                                ),
                              ),
                              child: Icon(
                                option['icon'] as IconData,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.gray600,
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
                                        option['name'] as String,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(15),
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? AppColors.primary
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      if (tag.isNotEmpty) ...[
                                        SizedBox(width: responsive.wp(2)),
                                        Container(
                                          padding: responsive.padding(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tag == 'Recommended'
                                                ? AppColors.primary.withValues(
                                                    alpha: 0.1,
                                                  )
                                                : AppColors.warningLight,
                                            borderRadius: BorderRadius.circular(
                                              responsive.borderRadius(10),
                                            ),
                                          ),
                                          child: Text(
                                            tag,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(10),
                                              fontWeight: FontWeight.w600,
                                              color: tag == 'Recommended'
                                                  ? AppColors.primary
                                                  : AppColors.warningAmberDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: responsive.hp(0.3)),
                                  Text(
                                    option['desc'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (extraCost > 0) ...[
                                    SizedBox(height: responsive.hp(0.3)),
                                    Text(
                                      '+\$${extraCost.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
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
          isValid: _selectedPacking != null,
          onPressed: () {
            widget.formData.furnitureType = _selectedPacking;
            widget.onNext();
          },
        ),
      ],
    );
  }
}
