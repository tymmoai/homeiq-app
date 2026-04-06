import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../maintenance/widgets/reminder_card.dart';
import '../../../shared/models/maintenance_models.dart';

/// An expandable / collapsible section for overdue or upcoming maintenance
/// reminders on the Maintenance tab.
class MaintenanceSection extends StatelessWidget {
  /// Unique key identifying this section (e.g. `'overdue'`, `'upcoming'`).
  final String sectionKey;

  /// Display title shown in the section header.
  final String title;

  /// Icon shown next to the title.
  final IconData icon;

  /// Total reminder count shown in the badge circle.
  final int count;

  /// The list of reminders to show when expanded.
  final List<Reminder> reminders;

  /// The key of the currently expanded section, or `null` if none.
  final String? expandedSection;

  /// Called when the user taps the header to expand/collapse.
  final ValueChanged<String?> onToggle;

  /// Called when the user marks a reminder as done.
  final ValueChanged<String> onMarkDone;

  /// Called when the user snoozes a reminder.
  final void Function(String id, DateTime until) onSnooze;

  /// Called when the user skips a reminder.
  final void Function(String id, SkipReason reason) onSkip;

  /// Called when the user requests DIY help for a reminder.
  final ValueChanged<Reminder> onGetHelp;

  /// Called when the user wants to order parts for a reminder.
  final ValueChanged<Reminder> onOrderParts;

  const MaintenanceSection({
    super.key,
    required this.sectionKey,
    required this.title,
    required this.icon,
    required this.count,
    required this.reminders,
    required this.expandedSection,
    required this.onToggle,
    required this.onMarkDone,
    required this.onSnooze,
    required this.onSkip,
    required this.onGetHelp,
    required this.onOrderParts,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = AppColors.primary;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    final filtered = reminders;
    final isExpanded = expandedSection == sectionKey;
    final responsive = ResponsiveUtils(context);

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(12.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              onToggle(isExpanded ? null : sectionKey);
            },
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(16.0)),
              child: Row(
                children: [
                  Container(
                    width: responsive.iconSize(40.0),
                    height: responsive.iconSize(40.0),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: responsive.iconSize(20.0),
                      color: headerColor,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16.0)),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: responsive.iconSize(28.0),
                    height: responsive.iconSize(28.0),
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12.0)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: textSecondary,
                      size: responsive.iconSize(20.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 1, color: AppColors.gray200),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (filtered.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'No ${title.toLowerCase()} tasks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...filtered.map(
                                (reminder) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: ReminderCard(
                                    reminder: reminder,
                                    onMarkDone: () => onMarkDone(reminder.id),
                                    onSnooze: (id, until) =>
                                        onSnooze(id, until),
                                    onSkip: (id, reason) => onSkip(id, reason),
                                    onGetHelp: () => onGetHelp(reminder),
                                    onOrderParts: () => onOrderParts(reminder),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

/// An expandable / collapsible section for completed maintenance reminders
/// on the Maintenance tab.
class MaintenanceCompletedSection extends StatelessWidget {
  /// The list of completed reminders to show when expanded.
  final List<Reminder> completedReminders;

  /// The key of the currently expanded section, or `null` if none.
  final String? expandedSection;

  /// Called when the user taps the header to expand/collapse.
  final ValueChanged<String?> onToggle;

  const MaintenanceCompletedSection({
    super.key,
    required this.completedReminders,
    required this.expandedSection,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final headerColor = AppColors.primary;
    final textPrimary = AppColors.textPrimary;
    final textSecondary = AppColors.textSecondary;

    final responsive = ResponsiveUtils(context);
    final displayReminders = completedReminders;
    final isExpanded = expandedSection == 'completed';

    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(12.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () {
              onToggle(isExpanded ? null : 'completed');
            },
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(16.0)),
              child: Row(
                children: [
                  Container(
                    width: responsive.iconSize(40.0),
                    height: responsive.iconSize(40.0),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      size: responsive.iconSize(20.0),
                      color: headerColor,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16.0)),
                  Expanded(
                    child: Text(
                      'Completed Maintenance',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Container(
                    width: responsive.iconSize(28.0),
                    height: responsive.iconSize(28.0),
                    decoration: BoxDecoration(
                      color: headerColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        displayReminders.length.toString(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12.0)),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: Icon(
                      Icons.keyboard_arrow_down_outlined,
                      color: textSecondary,
                      size: responsive.iconSize(20.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: isExpanded
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 1, color: AppColors.gray200),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (displayReminders.isEmpty)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Center(
                                  child: Text(
                                    'No completed maintenance tasks',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: textSecondary,
                                    ),
                                  ),
                                ),
                              )
                            else
                              ...displayReminders.map(
                                (reminder) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: AppColors.gray300,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.05,
                                        ),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              reminder.taskName,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${reminder.assetName} • ${reminder.assetLocation ?? 'Home'}',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: textSecondary,
                                              ),
                                            ),
                                            if (reminder.completedDate !=
                                                null) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                'Completed on ${reminder.completedDate!.month}/${reminder.completedDate!.day}/${reminder.completedDate!.year}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.check_circle_outline,
                                        size: 24,
                                        color: headerColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
