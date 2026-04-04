import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Property size selector for Cleaning service flow.
///
/// Matches web's CleaningFlow size step:
/// - Property type selection (Apartment, House, Condo, Studio)
/// - Number of bedrooms / size details
class SizeSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const SizeSelector({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<SizeSelector> createState() => _SizeSelectorState();
}

class _SizeSelectorState extends State<SizeSelector> {
  static const _propertyTypes = [
    {'name': 'Studio', 'icon': Icons.weekend_rounded, 'size': '< 500 sq ft'},
    {'name': 'Apartment', 'icon': Icons.apartment_rounded, 'size': '500-1200 sq ft'},
    {'name': 'House', 'icon': Icons.home_rounded, 'size': '1200-3000 sq ft'},
    {'name': 'Condo', 'icon': Icons.location_city_rounded, 'size': '800-2000 sq ft'},
    {'name': 'Large Home', 'icon': Icons.villa_rounded, 'size': '3000+ sq ft'},
  ];

  static const _sizeOptions = [
    '1 Bedroom',
    '2 Bedrooms',
    '3 Bedrooms',
    '4 Bedrooms',
    '5+ Bedrooms',
  ];

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final selectedType = widget.formData.propertyType;
    final selectedSize = widget.formData.propertySize;

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
                  'Property Size',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'Tell us about the space to clean',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(20),

                // Property type
                Text(
                  'Property Type',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                ...List.generate(_propertyTypes.length, (i) {
                  final type = _propertyTypes[i];
                  final isSelected = selectedType == type['name'];
                  return Padding(
                    padding: responsive.padding(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.propertyType = type['name'] as String;
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
                                type['icon'] as IconData,
                                color: isSelected ? AppColors.primary : AppColors.gray600,
                                size: responsive.iconSize(22),
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
                                  Text(
                                    type['size'] as String,
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
                      ),
                    ),
                  );
                }),

                responsive.heightBox(20),

                // Number of bedrooms
                Text(
                  'Number of Bedrooms',
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
                  children: _sizeOptions.map((size) {
                    final isSizeSelected = selectedSize == size;
                    return GestureDetector(
                      onTap: () => setState(() {
                        widget.formData.propertySize = size;
                      }),
                      child: Container(
                        padding: responsive.padding(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSizeSelected ? AppColors.primary05 : Colors.white,
                          borderRadius: BorderRadius.circular(responsive.borderRadius(20)),
                          border: Border.all(
                            color: isSizeSelected ? AppColors.primary : AppColors.gray300,
                            width: isSizeSelected ? 1.5 : 1,
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
                          size,
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            fontWeight: isSizeSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSizeSelected ? AppColors.primary : AppColors.textPrimary,
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
          isValid: selectedType != null && selectedSize != null,
          onPressed: widget.onNext,
        ),
      ],
    );
  }
}
