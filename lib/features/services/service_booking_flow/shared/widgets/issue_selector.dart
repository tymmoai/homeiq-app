import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Issue selector for Home Repairs service flow.
///
/// Replaces ItemQuantitySelector for Home Repairs.
/// Matches web's HomeRepairFlow issue step:
/// - Select multiple issues from category
/// - Add description for each issue
/// - Urgency selection
class IssueSelector extends StatefulWidget {
  final ServiceBookingFormData formData;
  final List<ServiceItem> issues;
  final String title;
  final String subtitle;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const IssueSelector({
    super.key,
    required this.formData,
    required this.issues,
    required this.title,
    required this.subtitle,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<IssueSelector> createState() => _IssueSelectorState();
}

class _IssueSelectorState extends State<IssueSelector> {
  final _descController = TextEditingController();

  static const _urgencyOptions = [
    {
      'name': 'Emergency (2-4 hrs)',
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.error,
      'multiplier': 1.5,
      'fee': 75.0,
    },
    {
      'name': 'Same Day',
      'icon': Icons.today_rounded,
      'color': AppColors.warningOrange,
      'multiplier': 1.25,
      'fee': 35.0,
    },
    {
      'name': 'Flexible (1-3 days)',
      'icon': Icons.event_available_rounded,
      'color': AppColors.success,
      'multiplier': 1.0,
      'fee': 0.0,
    },
  ];

  String? _selectedUrgency;

  @override
  void initState() {
    super.initState();
    _descController.text = widget.formData.specialRequirements ?? '';
    _selectedUrgency = widget.formData.cleaningIntensity; // Reuse for urgency
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  bool get _isValid => widget.formData.selectedItems.isNotEmpty;

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

                // Issues list — multi-select
                Text(
                  'Select Issue(s)',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                ...widget.issues.map((issue) {
                  final isSelected = widget.formData.selectedItems.containsKey(
                    issue.name,
                  );
                  return Padding(
                    padding: responsive.padding(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        if (isSelected) {
                          widget.formData.selectedItems.remove(issue.name);
                        } else {
                          widget.formData.selectedItems[issue.name] = 1;
                        }
                      }),
                      child: BookingShadowCard(
                        isSelected: isSelected,
                        child: Row(
                          children: [
                            Container(
                              width: responsive.wp(10),
                              height: responsive.wp(10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary.withValues(alpha: 0.1)
                                    : AppColors.gray100,
                                borderRadius: BorderRadius.circular(
                                  responsive.borderRadius(10),
                                ),
                              ),
                              child: Icon(
                                issue.icon,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.gray600,
                                size: responsive.iconSize(20),
                              ),
                            ),
                            SizedBox(width: responsive.wp(3)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    issue.name,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (issue.description != null)
                                    Text(
                                      issue.description!,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(12),
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              '\$${issue.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: responsive.wp(2)),
                            Icon(
                              isSelected
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray400,
                              size: responsive.iconSize(22),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                responsive.heightBox(20),

                // Urgency selection
                Text(
                  'Urgency',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                ...List.generate(_urgencyOptions.length, (i) {
                  final urgency = _urgencyOptions[i];
                  final isUrgencySelected = _selectedUrgency == urgency['name'];
                  final urgColor = urgency['color'] as Color;
                  final fee = urgency['fee'] as double;

                  return Padding(
                    padding: responsive.padding(bottom: 10),
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedUrgency = urgency['name'] as String;
                      }),
                      child: BookingShadowCard(
                        isSelected: isUrgencySelected,
                        child: Row(
                          children: [
                            Icon(
                              urgency['icon'] as IconData,
                              color: isUrgencySelected
                                  ? urgColor
                                  : AppColors.gray500,
                              size: responsive.iconSize(22),
                            ),
                            SizedBox(width: responsive.wp(3)),
                            Expanded(
                              child: Text(
                                urgency['name'] as String,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: isUrgencySelected
                                      ? urgColor
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (fee > 0)
                              Text(
                                '+\$${fee.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13),
                                  fontWeight: FontWeight.w600,
                                  color: urgColor,
                                ),
                              ),
                            if (fee == 0)
                              Text(
                                'No extra fee',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: AppColors.success,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

                responsive.heightBox(20),

                // Description
                Text(
                  'Describe the Problem',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Please describe the issue in detail...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: AppColors.gray400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                responsive.heightBox(40),
              ],
            ),
          ),
        ),
        BookingContinueButton(
          isValid: _isValid,
          onPressed: () {
            widget.formData.specialRequirements = _descController.text.trim();
            widget.formData.cleaningIntensity = _selectedUrgency;
            widget.onNext();
          },
        ),
      ],
    );
  }
}
