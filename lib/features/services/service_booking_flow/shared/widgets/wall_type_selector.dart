import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Wall type selection step for Mounting service flow.
///
/// Allows user to select:
/// - Wall type (Drywall, Concrete, Brick, Wood)
/// - Whether studs are available
/// - Mounting height preference
class WallTypeSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const WallTypeSelector({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<WallTypeSelector> createState() => _WallTypeSelectorState();
}

class _WallTypeSelectorState extends State<WallTypeSelector> {
  static const _wallTypes = [
    {
      'name': 'Drywall',
      'icon': Icons.grid_4x4_rounded,
      'desc': 'Standard interior wall',
    },
    {
      'name': 'Concrete',
      'icon': Icons.square_rounded,
      'desc': 'Solid concrete or cinder block',
    },
    {
      'name': 'Brick',
      'icon': Icons.view_comfy_rounded,
      'desc': 'Exposed or covered brick',
    },
    {
      'name': 'Wood',
      'icon': Icons.park_rounded,
      'desc': 'Wooden panel or log wall',
    },
    {
      'name': 'Not Sure',
      'icon': Icons.help_outline_rounded,
      'desc': 'Technician will assess on-site',
    },
  ];

  static const _heightOptions = [
    'Standard (Eye Level)',
    'Above Fireplace',
    'High Mount (Near Ceiling)',
    'Custom Height',
  ];

  bool _hasStuds = false;

  @override
  void initState() {
    super.initState();
    _hasStuds = widget.formData.mountingHeight == 'has_studs';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selected = widget.formData.wallType;

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
                  'Wall Type',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'What type of wall are you mounting on?',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(20),

                // Wall type options
                ...List.generate(_wallTypes.length, (i) {
                  final wall = _wallTypes[i];
                  final isSelected = selected == wall['name'];
                  return Padding(
                    padding: responsive.padding(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.wallType = wall['name'] as String;
                      }),
                      child: BookingShadowCard(
                        isSelected: isSelected,
                        child: Row(
                          children: [
                            Container(
                              width: responsive.wp(11),
                              height: responsive.wp(11),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(
                                  responsive.borderRadius(10),
                                ),
                              ),
                              child: Icon(
                                wall['icon'] as IconData,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.gray600,
                                size: responsive.iconSize(22),
                              ),
                            ),
                            SizedBox(width: responsive.wp(3)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    wall['name'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(15),
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    wall['desc'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
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

                responsive.heightBox(16),

                // Studs toggle
                BookingShadowCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wall Studs Available?',
                              style: TextStyle(
                                fontSize: responsive.fontSize(15),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              'Studs provide stronger mounting support',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _hasStuds,
                        onChanged: (val) => setState(() => _hasStuds = val),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),

                responsive.heightBox(20),

                // Mounting height
                Text(
                  'Mounting Height',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                Wrap(
                  spacing: responsive.wp(2),
                  runSpacing: responsive.hp(1),
                  children: _heightOptions.map((height) {
                    final isHeightSelected =
                        widget.formData.mountingHeight == height;
                    return GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.mountingHeight = height;
                      }),
                      child: Container(
                        padding: responsive.padding(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isHeightSelected
                              ? AppColors.primary05
                              : Colors.white,
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(20),
                          ),
                          border: Border.all(
                            color: isHeightSelected
                                ? AppColors.primary
                                : AppColors.gray300,
                            width: isHeightSelected ? 1.5 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          height,
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            fontWeight: isHeightSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isHeightSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                responsive.heightBox(40),
              ],
            ),
          ),
        ),
        BookingContinueButton(
          isValid: selected != null,
          onPressed: () {
            if (_hasStuds) {
              widget.formData.specialRequirements =
                  '${widget.formData.specialRequirements ?? ''}Wall studs available. ';
            }
            widget.onNext();
          },
        ),
      ],
    );
  }
}
