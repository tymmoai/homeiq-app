import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_step_header.dart';

/// Shared step widget for selecting optional add-ons.
///
/// Displays a list of toggle-able addon cards with price.
/// This step is always valid (user can skip without selecting any addon).
class AddonsSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final List<ServiceAddon> addons;
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const AddonsSelector({
    super.key,
    required this.formData,
    required this.addons,
    this.title = 'Any add-ons?',
    this.subtitle = 'Select optional add-on services',
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<AddonsSelector> createState() => _AddonsSelectorState();
}

class _AddonsSelectorState extends State<AddonsSelector> {
  double get _addonsTotal {
    return widget.formData.calculateAddonsTotal(widget.addons);
  }

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
                    'Available Add-ons',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(16.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(12.0),
                  ...widget.addons.map((addon) => _buildAddonCard(addon)),
                  context.responsive.heightBox(24.0),
                ],
              ),
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildAddonCard(ServiceAddon addon) {
    final isSelected = widget.formData.selectedAddons.contains(addon.name);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            widget.formData.selectedAddons.remove(addon.name);
          } else {
            widget.formData.selectedAddons.add(addon.name);
          }
        });
      },
      child: Container(
        margin: EdgeInsets.only(bottom: context.responsive.spacing(12.0)),
        padding: context.responsive.padding(all: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary05 : Colors.white,
          borderRadius: BorderRadius.circular(
            context.responsive.borderRadius(12.0),
          ),
          border: isSelected
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: isSelected
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Addon Icon
            Container(
              width: context.responsive.spacing(48.0),
              height: context.responsive.spacing(48.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : AppColors.gray100,
                borderRadius: BorderRadius.circular(
                  context.responsive.borderRadius(10.0),
                ),
              ),
              child: Icon(
                addon.icon,
                color: isSelected ? AppColors.primary : AppColors.gray600,
                size: context.responsive.iconSize(24.0),
              ),
            ),
            context.responsive.widthBox(16.0),
            // Addon Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    addon.name,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(15.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (addon.description != null) ...[
                    context.responsive.heightBox(2.0),
                    Text(
                      addon.description!,
                      style: TextStyle(
                        fontSize: context.responsive.fontSize(12.0),
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  context.responsive.heightBox(4.0),
                  Text(
                    '+\$${addon.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            // Checkbox
            Container(
              width: context.responsive.spacing(24.0),
              height: context.responsive.spacing(24.0),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(
                  context.responsive.borderRadius(6.0),
                ),
                border: isSelected
                    ? null
                    : Border.all(color: AppColors.gray400, width: 1.5),
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: Colors.white,
                      size: context.responsive.iconSize(16.0),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Addons Summary
          if (widget.formData.selectedAddons.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.formData.selectedAddons.length} add-on${widget.formData.selectedAddons.length != 1 ? 's' : ''} selected',
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(14.0),
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '+\$${_addonsTotal.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(16.0),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            context.responsive.heightBox(16.0),
          ],
          // Continue Button (always valid - addons are optional)
          SizedBox(
            width: double.infinity,
            height: context.responsive.buttonHeight(50.0),
            child: ElevatedButton(
              onPressed: widget.onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 2,
                shadowColor: AppColors.primary.withValues(alpha: 0.3),
              ),
              child: Text(
                widget.formData.selectedAddons.isEmpty
                    ? 'Skip Add-ons'
                    : 'Continue',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
