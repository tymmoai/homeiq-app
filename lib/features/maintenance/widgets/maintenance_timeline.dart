// Maintenance Timeline Widget
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../shared/models/maintenance_models.dart';

class MaintenanceTimeline extends StatelessWidget {
  final List<MaintenanceRecord> records;
  final String? assetName;

  const MaintenanceTimeline({super.key, required this.records, this.assetName});

  List<MaintenanceRecord> get sortedRecords {
    final sorted = List<MaintenanceRecord>.from(records);
    sorted.sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    return sorted;
  }

  IconData _getStatusIcon(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed:
        return Icons.check_circle;
      case MaintenanceStatus.pending:
        return Icons.access_time;
      case MaintenanceStatus.snoozed:
        return Icons.schedule;
      case MaintenanceStatus.skipped:
        return Icons.cancel;
    }
  }

  Color _getStatusIconColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed:
        return AppColors.success;
      case MaintenanceStatus.pending:
        return AppColors.warning;
      case MaintenanceStatus.snoozed:
        return AppColors.info;
      case MaintenanceStatus.skipped:
        return AppColors.error;
    }
  }

  Color _getStatusBgColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed:
        return AppColors.successSoft;
      case MaintenanceStatus.pending:
        return AppColors.warningYellowBg;
      case MaintenanceStatus.snoozed:
        return AppColors.infoBackground;
      case MaintenanceStatus.skipped:
        return AppColors.errorSoft;
    }
  }

  Color _getStatusBorderColor(MaintenanceStatus status) {
    switch (status) {
      case MaintenanceStatus.completed:
        return AppColors.successBorder;
      case MaintenanceStatus.pending:
        return AppColors.warningYellowBorder;
      case MaintenanceStatus.snoozed:
        return AppColors.infoBorder;
      case MaintenanceStatus.skipped:
        return AppColors.errorBorder;
    }
  }

  String _formatDate(DateTime date) {
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatStatus(MaintenanceStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    if (sortedRecords.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'No maintenance history available',
            style: TextStyle(fontSize: 14, color: AppColors.gray500),
          ),
        ),
      );
    }

    return Column(
      children: sortedRecords.map((record) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _getStatusBgColor(record.status),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getStatusBorderColor(record.status),
              width: 2,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _getStatusIcon(record.status),
                size: 20,
                color: _getStatusIconColor(record.status),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record.taskName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              if (assetName != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  assetName!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.gray600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusBgColor(record.status),
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusBadge,
                            ),
                            border: Border.all(
                              color: _getStatusBorderColor(record.status),
                            ),
                          ),
                          child: Text(
                            _formatStatus(record.status),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getStatusIconColor(record.status),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        Text(
                          'Scheduled: ${_formatDate(record.scheduledDate)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                        ),
                        if (record.completedDate != null)
                          Text(
                            'Completed: ${_formatDate(record.completedDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                        if (record.snoozedUntil != null)
                          Text(
                            'Snoozed: ${_formatDate(record.snoozedUntil!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
                            ),
                          ),
                        if (record.skipReason != null)
                          Text(
                            'Skipped: ${record.skipReason!.name.replaceAll(RegExp(r'([A-Z])'), r' $1').trim()}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.gray600,
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
      }).toList(),
    );
  }
}
