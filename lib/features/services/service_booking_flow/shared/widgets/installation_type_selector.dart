import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Installation type selector for Security / Smart Home service flow.
///
/// Matches web's SmartHomeFlow installation type step:
/// - New Installation (1.0x)
/// - Replace Existing (1.2x)
/// - Need Recommendation (1.1x)
class InstallationTypeSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const InstallationTypeSelector({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<InstallationTypeSelector> createState() =>
      _InstallationTypeSelectorState();
}

class _InstallationTypeSelectorState extends State<InstallationTypeSelector> {
  static const _installTypes = [
    {
      'name': 'New Installation',
      'desc': 'First-time setup — no existing system',
      'icon': Icons.add_circle_outline_rounded,
      'multiplier': 1.0,
      'color': AppColors.success,
      'tag': '',
    },
    {
      'name': 'Replace Existing',
      'desc': 'Upgrade or replace current device/system',
      'icon': Icons.swap_horiz_rounded,
      'multiplier': 1.2,
      'color': AppColors.warningOrange,
      'tag': '+20%',
    },
    {
      'name': 'Need Recommendation',
      'desc': 'Not sure — technician will assess & recommend',
      'icon': Icons.help_outline_rounded,
      'multiplier': 1.1,
      'color': AppColors.info,
      'tag': 'Includes consultation',
    },
  ];

  String? _selectedType;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.formData.existingSystem;
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
                  'Installation Type',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'What type of installation do you need?',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(24),

                ...List.generate(_installTypes.length, (i) {
                  final type = _installTypes[i];
                  final isSelected = _selectedType == type['name'];
                  final typeColor = type['color'] as Color;
                  final tag = type['tag'] as String;

                  return Padding(
                    padding: responsive.padding(bottom: 14),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = type['name'] as String;
                      }),
                      child: BookingShadowCard(
                        isSelected: isSelected,
                        child: Row(
                          children: [
                            Container(
                              width: responsive.wp(13),
                              height: responsive.wp(13),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? typeColor.withValues(alpha: 0.1)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(
                                  responsive.borderRadius(14),
                                ),
                              ),
                              child: Icon(
                                type['icon'] as IconData,
                                color: isSelected
                                    ? typeColor
                                    : AppColors.gray600,
                                size: responsive.iconSize(26),
                              ),
                            ),
                            SizedBox(width: responsive.wp(3)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type['name'] as String,
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
                                    type['desc'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (tag.isNotEmpty) ...[
                                    SizedBox(height: responsive.hp(0.5)),
                                    Container(
                                      padding: responsive.padding(
                                        horizontal: 8,
                                        vertical: 3,
                                      ),
                                      decoration: BoxDecoration(
                                        color: typeColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(
                                          AppDimensions.radiusBadge,
                                        ),
                                      ),
                                      child: Text(
                                        tag,
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(11),
                                          fontWeight: FontWeight.w600,
                                          color: typeColor,
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
          isValid: _selectedType != null,
          onPressed: () {
            widget.formData.existingSystem = _selectedType;
            widget.onNext();
          },
        ),
      ],
    );
  }
}
