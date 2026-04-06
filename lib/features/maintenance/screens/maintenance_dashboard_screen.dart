// Maintenance Dashboard Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/base/view_model_mixin.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/asset_api_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../shared/models/maintenance_models.dart';
import '../services/maintenance_service.dart';
import '../widgets/reminder_card.dart';
import 'diy_maintenance_screen.dart';

class MaintenanceDashboardScreen extends ConsumerStatefulWidget {
  const MaintenanceDashboardScreen({super.key});

  @override
  ConsumerState<MaintenanceDashboardScreen> createState() =>
      _MaintenanceDashboardScreenState();
}

class _MaintenanceDashboardScreenState
    extends ConsumerState<MaintenanceDashboardScreen>
    with ViewModelMixin {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  List<Reminder> _allReminders = [];
  List<Reminder> _completedReminders = [];
  String _filterStatus =
      'All Status'; // 'All Status', 'Upcoming', 'Overdue', 'Completed'
  String _filterPriority =
      'All Priorities'; // 'All Priorities', 'High Priority', 'Medium Priority', 'Low Priority'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final homeId = ref.read(selectedHomeIdProvider);
      List<Reminder> reminders = [];

      if (homeId != null && homeId.isNotEmpty) {
        // Fetch real maintenance records from backend
        final records = await AssetApiService.instance.getMaintenanceRecords(
          homeId: homeId,
        );
        reminders = records.map((r) {
          final status = r['status']?.toString() ?? 'completed';
          final performedAt = DateTime.tryParse(
            r['performedAt']?.toString() ?? '',
          );
          final nextDueAt = DateTime.tryParse(r['nextDueAt']?.toString() ?? '');
          final createdAt =
              DateTime.tryParse(r['createdAt']?.toString() ?? '') ??
              DateTime.now();
          final dueDate = nextDueAt ?? performedAt ?? createdAt;
          final assetData = r['asset'] as Map<String, dynamic>?;
          final assetName = assetData?['name']?.toString() ?? 'Home';

          ReminderStatus reminderStatus;
          switch (status) {
            case 'upcoming':
              reminderStatus = ReminderStatus.upcoming;
              break;
            case 'pending':
              reminderStatus = ReminderStatus.upcoming;
              break;
            case 'skipped':
              reminderStatus = ReminderStatus.skipped;
              break;
            case 'snoozed':
              reminderStatus = ReminderStatus.snoozed;
              break;
            case 'completed':
              reminderStatus = ReminderStatus.completed;
              break;
            default:
              reminderStatus = dueDate.isBefore(DateTime.now())
                  ? ReminderStatus.overdue
                  : ReminderStatus.upcoming;
          }

          return Reminder(
            id: r['id']?.toString() ?? '',
            assetId: r['assetId']?.toString() ?? '',
            assetName: assetName,
            taskId: r['id']?.toString() ?? '',
            taskName: r['title']?.toString() ?? 'Maintenance Task',
            taskDescription: r['description']?.toString() ?? '',
            whyItMatters:
                'Regular maintenance keeps your asset in peak condition',
            estimatedEffort: '15 minutes',
            dueDate: dueDate,
            status: reminderStatus,
            priority: ReminderPriority.medium,
            riskLevel: 3,
            completedDate: status == 'completed' ? performedAt : null,
          );
        }).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));
      } else {
        // Fallback to local data if no homeId
        await MaintenanceService.initializeMaintenanceData();
        reminders = await MaintenanceService.getAllReminders();
      }

      safeSetState(() {
        _allReminders = reminders
            .where(
              (r) =>
                  r.status != ReminderStatus.completed &&
                  r.status != ReminderStatus.skipped,
            )
            .toList();
        _completedReminders = reminders
            .where((r) => r.status == ReminderStatus.completed)
            .toList();
      });
    } on Object catch (_) {
      // Handle error
    } finally {
      safeSetState(() {
        _isLoading = false;
      });
    }
  }

  List<Reminder> get _filteredReminders {
    List<Reminder> filtered = [];

    if (_filterStatus == 'Completed') {
      filtered = List.from(_completedReminders);
    } else {
      filtered = List.from(_allReminders);
      if (_filterStatus == 'Upcoming') {
        filtered = filtered
            .where((r) => r.status == ReminderStatus.upcoming)
            .toList();
      } else if (_filterStatus == 'Overdue') {
        filtered = filtered
            .where((r) => r.status == ReminderStatus.overdue)
            .toList();
      }
    }

    if (_filterPriority != 'All Priorities') {
      ReminderPriority priority;
      if (_filterPriority == 'High Priority') {
        priority = ReminderPriority.high;
      } else if (_filterPriority == 'Medium Priority') {
        priority = ReminderPriority.medium;
      } else {
        priority = ReminderPriority.low;
      }
      filtered = filtered.where((r) => r.priority == priority).toList();
    }

    return filtered;
  }

  List<Reminder> get _upcomingReminders {
    return _allReminders
        .where((r) => r.status == ReminderStatus.upcoming)
        .toList();
  }

  List<Reminder> get _overdueReminders {
    return _allReminders
        .where((r) => r.status == ReminderStatus.overdue)
        .toList();
  }

  Map<String, int> get _stats {
    return {
      'upcoming': _upcomingReminders.length,
      'overdue': _overdueReminders.length,
      'completed': _completedReminders.length,
      'total': _allReminders.length,
    };
  }

  Future<void> _handleMarkDone(String reminderId) async {
    // Find the reminder
    final reminder = _allReminders.firstWhere(
      (r) => r.id == reminderId,
      orElse: () => _completedReminders.firstWhere((r) => r.id == reminderId),
    );

    // Mark as completed
    await MaintenanceService.markReminderAsCompleted(reminderId);

    // Update local state
    safeSetState(() {
      _allReminders.removeWhere((r) => r.id == reminderId);
      _completedReminders.insert(
        0,
        Reminder(
          id: reminder.id,
          assetId: reminder.assetId,
          assetName: reminder.assetName,
          assetLocation: reminder.assetLocation,
          taskId: reminder.taskId,
          taskName: reminder.taskName,
          taskDescription: reminder.taskDescription,
          whyItMatters: reminder.whyItMatters,
          estimatedEffort: reminder.estimatedEffort,
          safetyNote: reminder.safetyNote,
          dueDate: reminder.dueDate,
          status: ReminderStatus.completed,
          priority: reminder.priority,
          riskLevel: reminder.riskLevel,
          completedDate: DateTime.now(),
        ),
      );
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Maintenance marked as completed! Health score will be updated.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  Future<void> _handleSnooze(String reminderId, DateTime until) async {
    await MaintenanceService.snoozeReminderById(reminderId, until);
    await _loadReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Reminder postponed until ${until.month}/${until.day}/${until.year}',
          ),
        ),
      );
    }
  }

  Future<void> _handleSkip(String reminderId, SkipReason reason) async {
    await MaintenanceService.skipReminderById(reminderId, reason);
    await _loadReminders();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder skipped. Health score may be affected.'),
        ),
      );
    }
  }

  void _handleGetHelp(Reminder reminder) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DIYMaintenanceScreen(
          reminder: reminder,
          onMarkComplete: () => _handleMarkDone(reminder.id),
        ),
      ),
    );
  }

  void _handleOrderParts(Reminder reminder) {
    // Navigate to maintenance parts order screen
    context.push('/maintenance/order-parts', extra: reminder);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildMaintenanceTabWithFixedHeader(),
    );
  }

  Widget _buildMaintenanceTabWithFixedHeader() {
    // Calculate header height dynamically - only title in fixed header (same as asset tab)
    final statusBarHeight = MediaQuery.of(context).padding.top;
    const headerContentHeight = 48.0; // Header title row height
    const headerPadding = 16.0; // Top and bottom padding
    final totalFixedHeight =
        statusBarHeight + headerPadding + headerContentHeight + headerPadding;

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        // Scrollable content - positioned below fixed header
        Positioned(
          top: totalFixedHeight,
          left: 0,
          right: 0,
          bottom: 0,
          child: SingleChildScrollView(
            padding: EdgeInsets.zero,
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards - placed after header
                _buildMaintenanceSummary(),
                SizedBox(height: responsive.spacing(16)),
                // Dropdown Filters
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20),
                  ),
                  child: _buildMaintenanceDropdowns(),
                ),
                SizedBox(height: responsive.spacing(16)),
                // Overdue Section
                if (_overdueReminders.isNotEmpty &&
                    _filterStatus != 'Completed')
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(20),
                    ),
                    child: _buildSection(
                      title: 'Overdue Maintenance',
                      icon: Icons.warning_amber_rounded,
                      iconColor: AppColors.error,
                      count: _overdueReminders.length,
                      reminders: _overdueReminders,
                    ),
                  ),
                // Upcoming Section
                if (_upcomingReminders.isNotEmpty &&
                    _filterStatus != 'Completed' &&
                    _filterStatus != 'Overdue')
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(20),
                    ),
                    child: _buildSection(
                      title: 'Upcoming Maintenance',
                      icon: Icons.calendar_today,
                      iconColor: AppColors.info,
                      count: _upcomingReminders.length,
                      reminders: _upcomingReminders,
                    ),
                  ),
                // Completed Section
                if (_filterStatus == 'Completed' &&
                    _completedReminders.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(20),
                    ),
                    child: _buildCompletedSection(),
                  ),
                // Empty State
                if (_filteredReminders.isEmpty && _filterStatus != 'Completed')
                  Padding(
                    padding: EdgeInsets.all(responsive.spacing(48)),
                    child: _buildEmptyState(),
                  ),
                SizedBox(height: responsive.spacing(20)),
              ],
            ),
          ),
        ),
        // Fixed header at top with elevation - only title (same as asset tab)
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Material(
            elevation: 4,
            color: AppColors.transparent,
            child: SafeArea(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.slate800,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: _buildMaintenanceHeader(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Maintenance',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.white,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceSummary() {
    final stats = _stats;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20)),
      child: Column(
        children: [
          // First Row: Upcoming & Overdue
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  icon: Icons.calendar_today_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'UPCOMING',
                  value: stats['upcoming']!.toString(),
                  valueColor: AppColors.infoDark,
                ),
              ),
              SizedBox(width: responsive.spacing(10)),
              Expanded(
                child: _buildSummaryTile(
                  icon: Icons.warning_amber_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'OVERDUE',
                  value: stats['overdue']!.toString(),
                  valueColor: AppColors.errorMaterialDark,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(10)),
          // Second Row: Completed & Total Tasks
          Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  icon: Icons.check_circle_outline,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'COMPLETED',
                  value: stats['completed']!.toString(),
                  valueColor: AppColors.successDark,
                ),
              ),
              SizedBox(width: responsive.spacing(10)),
              Expanded(
                child: _buildSummaryTile(
                  icon: Icons.notifications_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'TOTAL TASKS',
                  value: stats['total']!.toString(),
                  valueColor: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTile({
    required IconData icon,
    required Color iconBgColor,
    Color? iconColor,
    required String label,
    required String value,
    String? valueSuffix,
    required Color valueColor,
  }) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(14)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              // ignore: deprecated_member_use
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: responsive.iconSize(24),
              color: iconColor ?? AppColors.primary,
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(10),
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: responsive.spacing(6)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: responsive.fontSize(26),
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                        height: 1.0,
                      ),
                    ),
                    if (valueSuffix != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 2),
                        child: Text(
                          valueSuffix,
                          style: TextStyle(
                            fontSize: responsive.fontSize(20),
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray400,
                            height: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceDropdowns() {
    return Row(
      children: [
        // Status Dropdown
        Expanded(
          child: _buildCapsuleDropdown(
            value: _filterStatus,
            items: ['All Status', 'Upcoming', 'Overdue', 'Completed'],
            onChanged: (value) {
              setState(() {
                _filterStatus = value ?? 'All Status';
              });
            },
          ),
        ),
        // Priority Dropdown
        SizedBox(width: responsive.spacing(12)),
        Expanded(
          child: _buildCapsuleDropdown(
            value: _filterPriority,
            items: [
              'All Priorities',
              'High Priority',
              'Medium Priority',
              'Low Priority',
            ],
            onChanged: (value) {
              setState(() {
                _filterPriority = value ?? 'All Priorities';
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCapsuleDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return PopupMenuButton<String>(
          initialValue: value,
          onSelected: onChanged,
          elevation: 8,
          color: AppColors.white,
          offset: const Offset(0, 8),
          constraints: BoxConstraints(
            minWidth: constraints.maxWidth,
            maxWidth: constraints.maxWidth,
          ),
          itemBuilder: (BuildContext context) {
            return items.map((item) {
              final isSelected = item == value;
              return PopupMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check,
                        size: responsive.iconSize(18),
                        color: AppColors.primary,
                      ),
                  ],
                ),
              );
            }).toList();
          },
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(16),
              vertical: responsive.spacing(12),
            ),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              border: Border.all(color: AppColors.divider, width: 1),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  size: responsive.iconSize(20),
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required int count,
    required List<Reminder> reminders,
  }) {
    final filtered = _filteredReminders
        .where((r) => reminders.any((rem) => rem.id == r.id))
        .toList();

    if (filtered.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: responsive.iconSize(20), color: iconColor),
            SizedBox(width: responsive.spacing(8)),
            Text(
              title,
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: responsive.spacing(8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(8),
                vertical: responsive.spacing(4),
              ),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16)),
        ...filtered.map(
          (reminder) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ReminderCard(
              reminder: reminder,
              onMarkDone: () => _handleMarkDone(reminder.id),
              onSnooze: (id, until) => _handleSnooze(id, until),
              onSkip: (id, reason) => _handleSkip(id, reason),
              onGetHelp: () => _handleGetHelp(reminder),
              onOrderParts: () => _handleOrderParts(reminder),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(24)),
      ],
    );
  }

  Widget _buildCompletedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle,
              size: responsive.iconSize(20),
              color: AppColors.successDark,
            ),
            SizedBox(width: responsive.spacing(8)),
            Text(
              'Completed Maintenance',
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(width: responsive.spacing(8)),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(8),
                vertical: responsive.spacing(4),
              ),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Text(
                _completedReminders.length.toString(),
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.successDark,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16)),
        ..._completedReminders.map(
          (reminder) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.successSoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.successBorder, width: 2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.taskName,
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(4)),
                      Text(
                        '${reminder.assetName} • ${reminder.assetLocation ?? 'Home'}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          color: AppColors.gray600,
                        ),
                      ),
                      if (reminder.completedDate != null) ...[
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          'Completed on ${reminder.completedDate!.month}/${reminder.completedDate!.day}/${reminder.completedDate!.year}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.check_circle,
                  size: responsive.iconSize(24),
                  color: AppColors.successDark,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.check_circle,
            size: responsive.iconSize(64),
            color: AppColors.success,
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'No Pending Maintenance',
            style: TextStyle(
              fontSize: responsive.fontSize(20),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'No maintenance reminders at this time.',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.gray600,
            ),
          ),
        ],
      ),
    );
  }
}
