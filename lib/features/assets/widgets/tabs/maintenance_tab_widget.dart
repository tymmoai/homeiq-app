import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../services/asset_api_service.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../maintenance/services/maintenance_service.dart';
import '../../../shared/models/maintenance_models.dart';

class MaintenanceTabWidget extends StatefulWidget {
  final BuildContext parentContext;
  final Map<String, dynamic> asset;
  final ScrollController maintenanceScrollController;
  final List<Map<String, dynamic>>? cachedMaintenanceRecords;
  final Map<String, DateTime> completedTaskMap;
  final Map<String, SkipReason> skippedTaskMap;
  final List<MaintenanceRecord> maintenanceHistory;
  final Function(String) onTabMaintenanceDone;
  final Function(String) onTabMaintenanceSnooze;
  final Function(String) onTabMaintenanceSkip;
  final Function(String) onTabOrderParts;
  final Function(String) onTabDiy;
  final Widget Function({
    required String taskName,
    required String assetName,
    DateTime? scheduledDate,
    DateTime? completedDate,
    required bool isCompleted,
    bool isSkipped,
    bool isSnoozed,
    VoidCallback? onDone,
    VoidCallback? onSnooze,
    VoidCallback? onSkip,
    VoidCallback? onOrderParts,
    VoidCallback? onDiy,
  })
  buildMaintenanceHistoryCard;
  final Function(List<Map<String, dynamic>>?) onMaintenanceRecordsUpdated;

  const MaintenanceTabWidget({
    super.key,
    required this.parentContext,
    required this.asset,
    required this.maintenanceScrollController,
    required this.cachedMaintenanceRecords,
    required this.completedTaskMap,
    required this.skippedTaskMap,
    required this.maintenanceHistory,
    required this.onTabMaintenanceDone,
    required this.onTabMaintenanceSnooze,
    required this.onTabMaintenanceSkip,
    required this.onTabOrderParts,
    required this.onTabDiy,
    required this.buildMaintenanceHistoryCard,
    required this.onMaintenanceRecordsUpdated,
  });

  @override
  State<MaintenanceTabWidget> createState() => _MaintenanceTabWidgetState();
}

class _MaintenanceTabWidgetState extends State<MaintenanceTabWidget> {
  @override
  void initState() {
    super.initState();
    // Load data if not cached
    if (widget.cachedMaintenanceRecords == null) {
      _loadMaintenanceDataAsync();
    }
  }

  @override
  void didUpdateWidget(MaintenanceTabWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the asset has changed, reload maintenance data
    if (oldWidget.asset['id'] != widget.asset['id']) {
      _loadMaintenanceDataAsync();
    }
  }

  void _loadMaintenanceDataAsync() async {
    final data = await _loadMaintenanceData();
    if (mounted) {
      final records =
          (data['maintenanceRecords'] as List?)?.cast<Map<String, dynamic>>() ??
          [];
      widget.onMaintenanceRecordsUpdated(records);
    }
  }

  Future<Map<String, dynamic>> _loadMaintenanceData() async {
    try {
      final assetId = widget.asset['id']?.toString() ?? '';

      // ── 1. Fetch real service history from backend ─────────────────────
      List<Map<String, dynamic>> backendHistory = [];
      try {
        final raw = await AssetApiService.instance.getServiceHistory(assetId);
        backendHistory =
            raw.map((r) {
              final status = r['status']?.toString() ?? 'completed';
              final performedAt = DateTime.tryParse(
                r['performedAt']?.toString() ?? '',
              );
              final nextDueAt = DateTime.tryParse(
                r['nextDueAt']?.toString() ?? '',
              );
              final scheduledDate = performedAt ?? nextDueAt ?? DateTime.now();
              return {
                'taskName': r['title'] ?? 'Service Record',
                'status': status,
                'scheduledDate': scheduledDate,
                'completedDate': status == 'completed' ? performedAt : null,
              };
            }).toList()..sort((a, b) {
              final aDate =
                  (a['completedDate'] as DateTime?) ??
                  (a['scheduledDate'] as DateTime);
              final bDate =
                  (b['completedDate'] as DateTime?) ??
                  (b['scheduledDate'] as DateTime);
              return bDate.compareTo(aDate);
            });
      } on Object catch (_) {
        // Non-fatal: fall through to local records
      }

      // ── 2. Fetch local records from SharedPreferences ──────────────────
      var records = await MaintenanceService.getAssetMaintenanceRecords(
        assetId,
      );

      // ── 3. If both backend and local are empty, show empty state
      //       No fake/sample data — only real records from the database.

      // Add local maintenance history (for new tasks added via Done)
      records.addAll(widget.maintenanceHistory);

      // Sort local records by date (most recent first)
      records.sort((a, b) {
        final aDate = a.completedDate ?? a.scheduledDate;
        final bDate = b.completedDate ?? b.scheduledDate;
        return bDate.compareTo(aDate);
      });

      // Convert local records to map format
      final localMaps = records.map((record) {
        String statusStr;
        if (record.status == MaintenanceStatus.completed) {
          statusStr = 'completed';
        } else if (record.status == MaintenanceStatus.snoozed) {
          statusStr = 'snoozed';
        } else if (record.status == MaintenanceStatus.skipped) {
          statusStr = 'skipped';
        } else {
          statusStr = 'pending';
        }
        return {
          'taskName': record.taskName,
          'status': statusStr,
          'scheduledDate': record.scheduledDate,
          'completedDate': record.completedDate,
        };
      }).toList();

      // Backend history (real completed records) shown first, then local tasks
      return {
        'maintenanceRecords': [...backendHistory, ...localMaps],
      };
    } on Object catch (_) {
      // Include local maintenance history even if service fails
      final localRecords = widget.maintenanceHistory.map((record) {
        return {
          'taskName': record.taskName,
          'status': 'completed',
          'scheduledDate': record.scheduledDate,
          'completedDate': record.completedDate,
        };
      }).toList();
      return {'maintenanceRecords': localRecords};
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    // Load data if not cached
    if (widget.cachedMaintenanceRecords == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final maintenanceRecords = widget.cachedMaintenanceRecords!;

    // Apply completed and skipped status updates from maps
    final updatedRecords = maintenanceRecords.map((record) {
      final taskName = record['taskName'] as String;
      final isMarkedDone = widget.completedTaskMap.containsKey(taskName);
      final isMarkedSkipped = widget.skippedTaskMap.containsKey(taskName);
      if (isMarkedDone) {
        return {
          ...record,
          'status': 'completed',
          'completedDate': widget.completedTaskMap[taskName],
        };
      }
      if (isMarkedSkipped) {
        return {
          ...record,
          'status': 'skipped',
          'skipReason': widget.skippedTaskMap[taskName],
        };
      }
      return record;
    }).toList();

    // Combine all tasks in one list (pending first, then completed)
    final allTasks = [
      ...updatedRecords.where(
        (record) => (record['status'] as String) != 'completed',
      ),
      ...updatedRecords.where(
        (record) => (record['status'] as String) == 'completed',
      ),
    ];

    return Container(
      color: AppColors.backgroundGray50,
      child: SingleChildScrollView(
        controller: widget.maintenanceScrollController,
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(20.0),
          vertical: responsive.spacing(12.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // All tasks in one container
            if (allTasks.isNotEmpty)
              ...allTasks.map((record) {
                final status = record['status'] as String;
                final isCompleted = status == 'completed';
                final isSkipped = status == 'skipped';
                final isSnoozed = status == 'snoozed';
                final taskName = record['taskName'] ?? 'Maintenance Task';
                return Padding(
                  padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                  child: widget.buildMaintenanceHistoryCard(
                    taskName: taskName,
                    assetName: widget.asset['name'] ?? 'Asset',
                    scheduledDate: record['scheduledDate'] as DateTime?,
                    completedDate: record['completedDate'] as DateTime?,
                    isCompleted: isCompleted,
                    isSkipped: isSkipped,
                    isSnoozed: isSnoozed,
                    onDone: () => widget.onTabMaintenanceDone(taskName),
                    onSnooze: () => widget.onTabMaintenanceSnooze(taskName),
                    onSkip: () => widget.onTabMaintenanceSkip(taskName),
                    onOrderParts: () => widget.onTabOrderParts(taskName),
                    onDiy: () => widget.onTabDiy(taskName),
                  ),
                );
              }),

            // Empty State
            if (maintenanceRecords.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(responsive.spacing(48.0)),
                  child: Text(
                    'No maintenance history available',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
