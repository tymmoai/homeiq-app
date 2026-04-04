// Reminder Card Widget for Maintenance

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../shared/models/maintenance_models.dart';

class ReminderCard extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onMarkDone;
  final Function(String, DateTime) onSnooze;
  final Function(String, SkipReason) onSkip;
  final VoidCallback onGetHelp;
  final VoidCallback onOrderParts;

  const ReminderCard({
    super.key,
    required this.reminder,
    required this.onMarkDone,
    required this.onSnooze,
    required this.onSkip,
    required this.onGetHelp,
    required this.onOrderParts,
  });

  @override
  State<ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<ReminderCard> {

  bool get isOverdue => widget.reminder.status == ReminderStatus.overdue;
  
  int get daysUntilDue {
    final now = DateTime.now();
    final due = widget.reminder.dueDate;
    return (due.difference(now).inDays);
  }

  // App theme colors
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textSecondary = AppColors.textSecondary;
  static const Color _buttonTextColor = AppColors.inputIcon;
  static final Color _buttonBorderColor = AppColors.divider;
  
  Color _getRiskColor() {
    // Use only app theme colors - gray shades for risk
    return _textSecondary;
  }

  Color _getVerticalBarColor() {
    // Use header color for all statuses (app theme)
    return _headerColor;
  }

  @override
  Widget build(BuildContext context) {
    final isDueToday = daysUntilDue <= 0 && !isOverdue;
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Colored vertical bar
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: _getVerticalBarColor(),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
              // Card content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row with Title and Risk/Days
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        widget.reminder.taskName,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (isOverdue)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _headerColor,
                                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                        ),
                                        child: const Text(
                                          'OVERDUE',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.white,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.reminder.assetName}${widget.reminder.assetLocation != null ? ' Ã¢â‚¬Â¢ ${widget.reminder.assetLocation}' : ''}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.reminder.whyItMatters,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'RISK: ${widget.reminder.riskLevel}/10',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _getRiskColor(),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOverdue
                                    ? '${daysUntilDue.abs()}D OVERDUE'
                                    : isDueToday
                                        ? 'DUE TODAY'
                                        : '${daysUntilDue}D',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Estimated time row
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 14, color: AppColors.gray600),
                          const SizedBox(width: 4),
                          Text(
                            widget.reminder.estimatedEffort,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                          if (widget.reminder.safetyNote != null) ...[
                            const SizedBox(width: 12),
                            Icon(Icons.warning_amber_rounded,
                                size: 14, color: _textSecondary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.reminder.safetyNote!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Action Buttons - First Row (Done / Snooze / Skip) - white normal buttons with gray text
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onMarkDone(),
                              icon: const Icon(Icons.check_circle, size: 16),
                              label: const Text('Done'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: _buttonTextColor,
                                elevation: 0,
                                side: BorderSide(color: _buttonBorderColor),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showSnoozeBottomSheet();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: _buttonTextColor,
                                elevation: 0,
                                side: BorderSide(color: _buttonBorderColor),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Snooze'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                _showSkipBottomSheet();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.white,
                                foregroundColor: _buttonTextColor,
                                elevation: 0,
                                side: BorderSide(color: _buttonBorderColor),
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: const Text('Skip'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action Buttons - Second Row (Order Parts / DIY) - primary normal buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onOrderParts(),
                              icon: const Icon(Icons.shopping_cart, size: 16),
                              label: const Text('Order Parts'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _headerColor,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => widget.onGetHelp(),
                              icon: const Icon(Icons.build, size: 16),
                              label: const Text('DIY'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _headerColor,
                                foregroundColor: AppColors.white,
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Dialogs are now shown as bottom sheets
      ],
    );
  }

  void _showSnoozeBottomSheet() {
    String selectedSnoozeOption = '1-week';
    DateTime? customSnoozeDate;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Snooze Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'When would you like to be reminded again?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: selectedSnoozeOption,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                filled: true,
                fillColor: AppColors.white,
              ),
              items: const [
                DropdownMenuItem(value: '1-week', child: Text('1 Week')),
                DropdownMenuItem(value: '1-month', child: Text('1 Month')),
                DropdownMenuItem(value: 'custom', child: Text('Custom Date')),
              ],
              onChanged: (value) {
                setBottomSheetState(() {
                  selectedSnoozeOption = value ?? '1-week';
                });
                if (value == 'custom' && customSnoozeDate == null) {
                  // Show date picker when custom is selected
                  _selectCustomDateInSheet(setBottomSheetState, (date) {
                    customSnoozeDate = date;
                  });
                }
              },
            ),
            if (selectedSnoozeOption == 'custom') ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: () => _selectCustomDateInSheet(setBottomSheetState, (date) {
                  customSnoozeDate = date;
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                    border: Border.all(color: AppColors.gray300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          customSnoozeDate != null
                              ? 'Selected: ${customSnoozeDate!.year}-${customSnoozeDate!.month.toString().padLeft(2, '0')}-${customSnoozeDate!.day.toString().padLeft(2, '0')}'
                              : 'Select Date',
                          style: TextStyle(
                            fontSize: 14,
                            color: customSnoozeDate != null
                                ? AppColors.textPrimary
                                : AppColors.gray600,
                            fontWeight: customSnoozeDate != null
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.calendar_today,
                        size: 18,
                        color: customSnoozeDate != null
                            ? AppColors.primary
                            : AppColors.gray600,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.gray700),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: (selectedSnoozeOption == 'custom' && customSnoozeDate == null)
                      ? null
                      : () {
                          // Calculate snooze date based on selection
                          final now = DateTime.now();
                          DateTime snoozeDate;
                          switch (selectedSnoozeOption) {
                            case '1-week':
                              snoozeDate = now.add(const Duration(days: 7));
                              break;
                            case '1-month':
                              snoozeDate = DateTime(now.year, now.month + 1, now.day);
                              break;
                            case 'custom':
                              snoozeDate = customSnoozeDate ?? now.add(const Duration(days: 14));
                              break;
                            default:
                              snoozeDate = now.add(const Duration(days: 14));
                          }
                          widget.onSnooze(widget.reminder.id, snoozeDate);
                          Navigator.pop(context);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.gray300,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Snooze'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      ),
    );
  }

  Future<void> _selectCustomDateInSheet(StateSetter setBottomSheetState, Function(DateTime) onDateSelected) async {
    final now = DateTime.now();
    final firstDate = now;
    final lastDate = now.add(const Duration(days: 365));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 7)),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setBottomSheetState(() {
        onDateSelected(pickedDate);
      });
    }
  }

  void _showSkipBottomSheet() {
    SkipReason? selectedSkipReason;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (context, setBottomSheetState) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Skip Reminder',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Why are you skipping this maintenance?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray600,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<SkipReason>(
              initialValue: selectedSkipReason,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  borderSide: BorderSide(color: AppColors.gray300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  borderSide: BorderSide(color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 14),
                filled: true,
                fillColor: AppColors.white,
                hintText: 'Select a reason',
              ),
              items: const [
                DropdownMenuItem(
                    value: SkipReason.dontKnowHow,
                    child: Text("Don't know how")),
                DropdownMenuItem(
                    value: SkipReason.notNeeded, child: Text('Not needed')),
                DropdownMenuItem(
                    value: SkipReason.willDoLater,
                    child: Text('Will do later')),
              ],
              onChanged: (value) {
                setBottomSheetState(() {
                  selectedSkipReason = value;
                });
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: AppColors.gray700),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: selectedSkipReason != null ? () {
                    widget.onSkip(widget.reminder.id, selectedSkipReason!);
                    Navigator.pop(context);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: AppColors.gray300,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Skip'),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      ),
    );
  }
}

