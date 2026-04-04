import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../maintenance/services/maintenance_service.dart';
import '../../../shared/models/maintenance_models.dart';

/// Displays the "Pending To-Do" task list on the Home tab.
///
/// Tasks are loaded **dynamically** from [MaintenanceService] — specifically
/// all overdue and upcoming reminders. This keeps the Home tab in sync with
/// the Maintenance Dashboard and individual asset-detail maintenance tabs.
class TodaysTasksContent extends StatefulWidget {
  /// Optional search string used to filter visible tasks.
  final String searchQuery;

  const TodaysTasksContent({super.key, this.searchQuery = ''});

  @override
  State<TodaysTasksContent> createState() => _TodaysTasksContentState();
}

class _TodaysTasksContentState extends State<TodaysTasksContent> {
  List<Reminder> _tasks = [];
  final Set<String> _locallyCompleted = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final reminders = await MaintenanceService.getAllReminders();
      // Show overdue tasks first, then upcoming — limit to 4 to stay concise.
      final actionable = reminders
          .where((r) =>
              r.status == ReminderStatus.overdue ||
              r.status == ReminderStatus.upcoming)
          .toList();

      // Sort: overdue first (by due date asc), then upcoming (by due date asc)
      actionable.sort((a, b) {
        final aOverdue = a.status == ReminderStatus.overdue ? 0 : 1;
        final bOverdue = b.status == ReminderStatus.overdue ? 0 : 1;
        if (aOverdue != bOverdue) return aOverdue.compareTo(bOverdue);
        return a.dueDate.compareTo(b.dueDate);
      });

      if (mounted) {
        setState(() {
          _tasks = actionable.take(4).toList();
          _isLoading = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _toggleTask(Reminder task) async {
    if (_locallyCompleted.contains(task.id)) return;
    setState(() => _locallyCompleted.add(task.id));
    await MaintenanceService.markReminderAsCompleted(task.id);
  }

  String _priorityLabel(ReminderPriority p) {
    switch (p) {
      case ReminderPriority.high:
        return 'HIGH';
      case ReminderPriority.medium:
        return 'MEDIUM';
      case ReminderPriority.low:
        return 'LOW';
    }
  }

  Color _priorityColor(ReminderPriority p) {
    switch (p) {
      case ReminderPriority.high:
        return AppColors.error;
      case ReminderPriority.medium:
        return AppColors.warningOrange;
      case ReminderPriority.low:
        return AppColors.success;
    }
  }

  String _dueDateLabel(Reminder task) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dueDay =
        DateTime(task.dueDate.year, task.dueDate.month, task.dueDate.day);
    final diff = dueDay.difference(today).inDays;

    if (task.status == ReminderStatus.overdue) {
      return 'Overdue ${-diff}d';
    }
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    if (diff <= 7) return 'In $diff days';
    return '${task.dueDate.month}/${task.dueDate.day}';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    if (_isLoading) {
      return const SizedBox.shrink();
    }

    // Filter tasks by search query
    final filteredTasks = widget.searchQuery.isEmpty
        ? _tasks
        : _tasks.where((task) {
            final query = widget.searchQuery.toLowerCase();
            return task.taskName.toLowerCase().contains(query) ||
                task.assetName.toLowerCase().contains(query) ||
                _priorityLabel(task.priority).toLowerCase().contains(query);
          }).toList();

    if (filteredTasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final completedCount =
        _tasks.where((t) => _locallyCompleted.contains(t.id)).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pending To-Do',
              style: TextStyle(
                fontSize: responsive.fontSize(20),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '$completedCount/${_tasks.length}',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16)),
        // Task Cards
        ...List.generate(filteredTasks.length, (index) {
          final task = filteredTasks[index];
          final isCompleted = _locallyCompleted.contains(task.id);

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < filteredTasks.length - 1
                  ? responsive.spacing(12)
                  : 0,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: responsive.spacing(8),
                    offset: Offset(0, responsive.spacing(2)),
                  ),
                ],
              ),
              padding: EdgeInsets.all(responsive.spacing(16)),
              child: Row(
                children: [
                  // Checkbox
                  GestureDetector(
                    onTap: () => _toggleTask(task),
                    child: Container(
                      width: responsive.iconSize(24),
                      height: responsive.iconSize(24),
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.primary
                            : Colors.transparent,
                        border: Border.all(
                          color: isCompleted
                              ? AppColors.primary
                              : AppColors.divider,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(
                          responsive.borderRadius(4),
                        ),
                      ),
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              size: responsive.iconSize(16),
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(16)),
                  // Task Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.taskName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: isCompleted
                                ? AppColors.textLight
                                : AppColors.textPrimary,
                            decoration: isCompleted
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          task.assetName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.textLight,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Row(
                          children: [
                            Text(
                              _dueDateLabel(task),
                              style: TextStyle(
                                fontSize: responsive.fontSize(13),
                                color:
                                    task.status == ReminderStatus.overdue
                                        ? AppColors.error
                                        : AppColors.textLight,
                                fontWeight:
                                    task.status == ReminderStatus.overdue
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Text(
                              '●',
                              style: TextStyle(
                                fontSize: responsive.fontSize(8),
                                color: AppColors.textLight,
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Text(
                              _priorityLabel(task.priority),
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.bold,
                                color: isCompleted
                                    ? AppColors.textLight
                                    : _priorityColor(task.priority),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        SizedBox(height: responsive.spacing(24)),
      ],
    );
  }
}