import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_step_header.dart';

/// Shared step widget for selecting a service type (sub-category).
///
/// Displays a grid of service type cards. When a card is tapped,
/// it updates [formData.selectedService] and clears previous item selections.
class ServiceTypeSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final List<ServiceCategory> categories;
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const ServiceTypeSelector({
    super.key,
    required this.formData,
    required this.categories,
    this.title = 'What service do you need?',
    this.subtitle = 'Choose the type of service',
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<ServiceTypeSelector> createState() => _ServiceTypeSelectorState();
}

class _ServiceTypeSelectorState extends State<ServiceTypeSelector> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: context.responsive.padding(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(24.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(8.0),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  context.responsive.heightBox(29.0),
                  Text(
                    'Service Type',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(16.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(12.0),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: context.responsive.spacing(16.0),
                      crossAxisSpacing: context.responsive.spacing(12.0),
                      childAspectRatio: 0.85,
                    ),
                    itemCount: widget.categories.length,
                    itemBuilder: (context, index) {
                      final category = widget.categories[index];
                      final isSelected =
                          widget.formData.selectedService == category.name;
                      return _buildServiceCard(category, isSelected);
                    },
                  ),
                  context.responsive.heightBox(24.0),
                ],
              ),
            ),
          ),
        ),
        BookingContinueButton(
          isValid: widget.formData.selectedService != null,
          onPressed: widget.onNext,
        ),
      ],
    );
  }

  Widget _buildServiceCard(ServiceCategory category, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.formData.selectedService = category.name;
          widget.formData.serviceIcon = category.icon.toString();
          widget.formData.selectedItems.clear();
          widget.formData.selectedAddons.clear();
        });
      },
      child: Container(
        height: context.responsive.spacing(100.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary05 : Colors.white,
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : Border.all(color: AppColors.border, width: 1),
          borderRadius: BorderRadius.circular(
            context.responsive.borderRadius(12.0),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category.icon,
              size: context.responsive.iconSize(28.0),
              color: isSelected ? AppColors.primary : AppColors.textPrimary,
            ),
            context.responsive.heightBox(8.0),
            Padding(
              padding: context.responsive.padding(horizontal: 4),
              child: Text(
                category.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.responsive.fontSize(11.0),
                  fontWeight: FontWeight.w500,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
