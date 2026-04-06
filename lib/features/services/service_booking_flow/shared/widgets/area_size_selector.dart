import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Area size selector for Outdoor & Painting service flows.
///
/// Matches web's area/size selection step:
/// - Small, Medium, Large, Extra Large options
/// - With approximate sq ft ranges
class AreaSizeSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final String title;
  final String subtitle;
  final List<Map<String, dynamic>>? customSizes;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const AreaSizeSelector({
    super.key,
    required this.formData,
    this.title = 'Area Size',
    this.subtitle = 'How large is the area?',
    this.customSizes,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  /// Default outdoor area sizes
  static const defaultOutdoorSizes = [
    {
      'name': 'Small',
      'range': 'Up to 500 sq ft',
      'icon': Icons.crop_square_rounded,
      'multiplier': 1.0,
    },
    {
      'name': 'Medium',
      'range': '500-1,500 sq ft',
      'icon': Icons.crop_din_rounded,
      'multiplier': 1.3,
    },
    {
      'name': 'Large',
      'range': '1,500-3,000 sq ft',
      'icon': Icons.crop_free_rounded,
      'multiplier': 1.6,
    },
    {
      'name': 'Extra Large',
      'range': '3,000+ sq ft',
      'icon': Icons.zoom_out_map_rounded,
      'multiplier': 2.0,
    },
  ];

  /// Default painting area sizes
  static const defaultPaintingSizes = [
    {
      'name': 'Small Room',
      'range': 'Up to 120 sq ft',
      'icon': Icons.crop_square_rounded,
      'multiplier': 1.0,
    },
    {
      'name': 'Medium Room',
      'range': '120-200 sq ft',
      'icon': Icons.crop_din_rounded,
      'multiplier': 1.3,
    },
    {
      'name': 'Large Room',
      'range': '200-350 sq ft',
      'icon': Icons.crop_free_rounded,
      'multiplier': 1.5,
    },
    {
      'name': 'Extra Large',
      'range': '350+ sq ft',
      'icon': Icons.zoom_out_map_rounded,
      'multiplier': 1.8,
    },
  ];

  @override
  State<AreaSizeSelector> createState() => _AreaSizeSelectorState();
}

class _AreaSizeSelectorState extends State<AreaSizeSelector> {
  List<Map<String, dynamic>> get _sizes =>
      widget.customSizes ?? AreaSizeSelector.defaultOutdoorSizes;

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selected = widget.formData.propertySize;

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

                ...List.generate(_sizes.length, (i) {
                  final size = _sizes[i];
                  final isSelected = selected == size['name'];
                  final multiplier =
                      (size['multiplier'] as num?)?.toDouble() ?? 1.0;

                  return Padding(
                    padding: responsive.padding(bottom: 12),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.propertySize = size['name'] as String;
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
                                size['icon'] as IconData,
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
                                  Text(
                                    size['name'] as String,
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
                                    size['range'] as String,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  if (multiplier > 1.0) ...[
                                    SizedBox(height: responsive.hp(0.3)),
                                    Text(
                                      '${multiplier}x base price',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(11),
                                        fontWeight: FontWeight.w500,
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
          isValid: selected != null,
          onPressed: widget.onNext,
        ),
      ],
    );
  }
}
