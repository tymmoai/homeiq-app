import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../shared/summary_tile.dart';

class AssetsSummary extends StatelessWidget {
  final List<Map<String, dynamic>> allAssets;

  const AssetsSummary({super.key, required this.allAssets});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final avgHealthScore =
        allAssets.fold<double>(
          0,
          (sum, asset) =>
              sum + ((asset['healthScore'] as num?) ?? 8.0).toDouble(),
        ) /
        (allAssets.isEmpty ? 1 : allAssets.length);
    final goodStatus = allAssets.where((a) {
      final hs = ((a['healthScore'] as num?) ?? 8.0).toDouble();
      return hs >= 8.0;
    }).length;
    final needAttention = allAssets.where((a) {
      final hs = ((a['healthScore'] as num?) ?? 8.0).toDouble();
      return hs >= 6.0 && hs < 8.0;
    }).length;
    final critical = allAssets.where((a) {
      final hs = ((a['healthScore'] as num?) ?? 8.0).toDouble();
      return hs < 6.0;
    }).length;

    final headerColor = AppColors.primary;

    return Padding(
      padding: EdgeInsets.only(
        left: responsive.spacing(20.0),
        right: responsive.spacing(20.0),
        top: 10.0,
      ),
      child: Column(
        children: [
          // First Row: Health Score & Good Status
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.health_and_safety_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: headerColor,
                  label: 'HEALTH SCORE',
                  value: avgHealthScore.toStringAsFixed(1),
                  valueSuffix: '/10',
                  valueColor: AppColors.textPrimary,
                ),
              ),
              SizedBox(width: responsive.spacing(10.0)),
              Expanded(
                child: SummaryTile(
                  icon: Icons.check_circle_outline,
                  iconBgColor: AppColors.transparent,
                  iconColor: headerColor,
                  label: 'GOOD',
                  value: goodStatus.toString(),
                  valueColor: AppColors.successDark,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(10.0)),
          // Second Row: Attention & Critical
          Row(
            children: [
              Expanded(
                child: SummaryTile(
                  icon: Icons.warning_amber_outlined,
                  iconBgColor: AppColors.transparent,
                  iconColor: headerColor,
                  label: 'ATTENTION',
                  value: needAttention.toString(),
                  valueColor: AppColors.warningOrange,
                ),
              ),
              SizedBox(width: responsive.spacing(10.0)),
              Expanded(
                child: SummaryTile(
                  icon: Icons.error_outline,
                  iconBgColor: AppColors.transparent,
                  iconColor: headerColor,
                  label: 'CRITICAL',
                  value: critical.toString(),
                  valueColor: AppColors.errorDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
