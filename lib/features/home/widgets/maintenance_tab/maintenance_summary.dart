import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../shared/summary_tile.dart';

class MaintenanceSummary extends StatelessWidget {
  final Map<String, int> stats;

  const MaintenanceSummary({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Padding(
      padding: EdgeInsets.only(
        left: responsive.spacing(20.0),
        right: responsive.spacing(20.0),
        top: 10.0,
      ),
      child: Column(
        children: [
          // First Row: Upcoming & Overdue
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.calendar_today_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'UPCOMING',
                  value: stats['upcoming']!.toString(),
                  valueColor: AppColors.infoDark,
                ),
              ),
              SizedBox(width: responsive.spacing(10.0)),
              Expanded(
                child: SummaryTile(
                  icon: Icons.warning_amber_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'OVERDUE',
                  value: stats['overdue']!.toString(),
                  valueColor: AppColors.errorDark,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(10.0)),
          // Second Row: Completed & Total Tasks
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.check_circle_outline,
                  iconBgColor: AppColors.transparent,
                  iconColor: AppColors.primary,
                  label: 'COMPLETED',
                  value: stats['completed']!.toString(),
                  valueColor: AppColors.successDark,
                ),
              ),
              SizedBox(width: responsive.spacing(10.0)),
              Expanded(
                child: SummaryTile(
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
}
