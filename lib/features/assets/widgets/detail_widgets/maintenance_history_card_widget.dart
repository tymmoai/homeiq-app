import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';

/// Builds a maintenance history card with status badge and action buttons.
///
/// Used by both the Maintenance tab and Overview tab to display maintenance records.
Widget buildMaintenanceHistoryCard({
  required String taskName,
  required String assetName,
  DateTime? scheduledDate,
  DateTime? completedDate,
  required bool isCompleted,
  bool isSkipped = false,
  bool isSnoozed = false,
  VoidCallback? onDone,
  VoidCallback? onSnooze,
  VoidCallback? onSkip,
  VoidCallback? onOrderParts,
  VoidCallback? onDiy,
}) {
  String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    final months = [
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // Determine icon and status badge based on state
  IconData statusIcon;
  String statusText;
  Color badgeColor;
  Color badgeTextColor;
  // Show actions for all non-completed items (pending, skipped, snoozed)
  bool showActions = !isCompleted;

  if (isCompleted) {
    statusIcon = Icons.check;
    statusText = 'COMPLETED';
    badgeColor = Colors.green.shade100;
    badgeTextColor = Colors.green.shade700;
  } else if (isSkipped) {
    statusIcon = Icons.skip_next;
    statusText = 'SKIPPED';
    badgeColor = AppColors.accent.withValues(alpha: 0.1);
    badgeTextColor = AppColors.accent;
  } else if (isSnoozed) {
    statusIcon = Icons.snooze;
    statusText = 'SNOOZED';
    badgeColor = Colors.orange.shade100;
    badgeTextColor = Colors.orange.shade700;
  } else {
    statusIcon = Icons.access_time;
    statusText = 'TO DO';
    badgeColor = Colors.grey.shade200;
    badgeTextColor = Colors.grey.shade700;
  }

  return Container(
    padding: const EdgeInsets.all(15),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Dark blue circular icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(statusIcon, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 12),
            // Task details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    taskName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    assetName,
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCompleted
                        ? 'Scheduled: ${formatDate(scheduledDate)} Done: ${formatDate(completedDate)}'
                        : 'Scheduled: ${formatDate(scheduledDate)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            // Status badge with appropriate colors
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: badgeTextColor,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        // Action buttons for pending items
        if (showActions) ...[
          const SizedBox(height: 16),
          // First row: Done, Snooze, Skip
          Row(
            children: [
              Expanded(
                child: _buildMaintenanceActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Done',
                  onTap: onDone,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMaintenanceActionButton(
                  label: 'Snooze',
                  onTap: onSnooze,
                  isOutlined: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMaintenanceActionButton(
                  label: 'Skip',
                  onTap: onSkip,
                  isOutlined: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Second row: Order Parts, DIY
          Row(
            children: [
              Expanded(
                child: _buildMaintenanceActionButton(
                  icon: Icons.shopping_cart_outlined,
                  label: 'Order Parts',
                  onTap: onOrderParts,
                  isPrimary: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMaintenanceActionButton(
                  icon: Icons.build_outlined,
                  label: 'Do It Yourself',
                  onTap: onDiy,
                  isPrimary: true,
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );
}

Widget _buildMaintenanceActionButton({
  IconData? icon,
  required String label,
  VoidCallback? onTap,
  bool isOutlined = false,
  bool isPrimary = false,
}) {
  if (isPrimary) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        elevation: 0,
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    );
  }
  return OutlinedButton(
    onPressed: onTap,
    style: OutlinedButton.styleFrom(
      foregroundColor: Colors.grey.shade700,
      padding: const EdgeInsets.symmetric(vertical: 12),
      side: isOutlined
          ? BorderSide(color: Colors.grey.shade300, width: 1)
          : BorderSide.none,
      elevation: 0,
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
        Text(label),
      ],
    ),
  );
}
