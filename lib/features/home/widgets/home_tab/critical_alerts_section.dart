import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../providers/home_selection_provider.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/home_models.dart';
import '../../services/home_data_service.dart';

class CriticalAlertsSection extends ConsumerWidget {
  final List<Map<String, dynamic>> allAssets;

  const CriticalAlertsSection({super.key, required this.allAssets});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responsive = ResponsiveUtils(context);
    final homeId = ref.watch(selectedHomeIdProvider);
    final alerts = HomeDataService.getMockCriticalAlerts(homeId, realAssets: allAssets);

    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Critical Alerts',
              style: TextStyle(
                fontSize: responsive.fontSize(20.0),
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            GestureDetector(
              onTap: () => context.push('/critical-alerts?homeId=$homeId'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(2.0)),
                  Icon(
                    Icons.chevron_right,
                    size: responsive.iconSize(18.0),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16.0)),
        ...alerts
            .take(3)
            .map(
              (alert) => Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                child: _buildCriticalAlertCard(context, responsive, alert),
              ),
            ),
      ],
    );
  }

  Widget _buildCriticalAlertCard(
    BuildContext context,
    ResponsiveUtils responsive,
    CriticalAlert alert,
  ) {
    final actionLabel = alert.actionLabel ?? 'View';
    // Show full asset name for readability
    String displayName = alert.assetName;

    return Container(
      padding: EdgeInsets.all(responsive.spacing(12.0)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: responsive.iconSize(44.0),
            height: responsive.iconSize(44.0),
            decoration: BoxDecoration(
              color: alert.getSeverityBackgroundColor(),
              borderRadius: BorderRadius.circular(
                responsive.borderRadius(10.0),
              ),
            ),
            child: Icon(
              alert.iconData,
              size: responsive.iconSize(22.0),
              color: alert.getSeverityColor(),
            ),
          ),
          SizedBox(width: responsive.spacing(12.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        displayName,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(8.0)),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(8.0),
                        vertical: responsive.spacing(3.0),
                      ),
                      decoration: BoxDecoration(
                        color:
                            (alert.isExpired ||
                                alert.severity == AlertSeverity.critical)
                            ? AppColors.accent.withValues(alpha: 0.1)
                            : AppColors.warningBackground,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                      ),
                      child: Text(
                        alert.getSeverityBadge(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(10.0),
                          fontWeight: FontWeight.bold,
                          color:
                              (alert.isExpired ||
                                  alert.severity == AlertSeverity.critical)
                              ? AppColors.accent
                              : AppColors.warningAmberDark,
                        ),
                      ),
                    ),
                  ],
                ),
                if (alert.location != null && alert.location!.isNotEmpty) ...[
                  SizedBox(height: responsive.spacing(2.0)),
                  Text(
                    alert.location!,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12.0),
                      color: AppColors.textLight,
                    ),
                  ),
                ],
                SizedBox(height: responsive.spacing(2.0)),
                Text(
                  alert.issue,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12.0),
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.spacing(8.0)),
          SizedBox(
            width: responsive.isSmallMobile ? 78 : 90,
            height: responsive.isSmallMobile ? 32 : 36,
            child: ElevatedButton(
              onPressed: () {
                  // Navigate based on action type
                  final asset = allAssets.firstWhere(
                    (a) => a['id'] == alert.assetId,
                    orElse: () => {},
                  );

                  if (alert.alertCategory == AlertCategory.warranty &&
                      alert.isExpired) {
                    // Warranty expired → Go to protection plans with asset data
                    if (asset.isNotEmpty) {
                      context.push('/warranties', extra: asset);
                    }
                  } else if (alert.alertCategory == AlertCategory.maintenance) {
                    if (asset.isNotEmpty) {
                      context.push(
                        '/asset-detail',
                        extra: {'asset': asset, 'initialTab': 'Maintenance'},
                      );
                    }
                  } else if (alert.alertCategory == AlertCategory.service ||
                      alert.alertCategory == AlertCategory.safety) {
                    // For service alerts (like AC service overdue), go to maintenance tab without popup
                    if (asset.isNotEmpty) {
                      context.push(
                        '/asset-detail',
                        extra: {
                          'asset': asset,
                          'initialTab': 'Maintenance',
                          'skipPopup':
                              true, // Skip popup when coming from critical alerts
                        },
                      );
                    } else {
                      context.push('/services');
                    }
                  } else if (alert.actionRoute != null) {
                    if (alert.actionRoute!.contains('asset-detail') &&
                        asset.isNotEmpty) {
                      context.push('/asset-detail', extra: asset);
                    } else {
                      context.push(alert.actionRoute!);
                    }
                  }
                },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(8.0),
                  vertical: responsive.spacing(4.0),
                ),
                elevation: 0,
                textStyle: TextStyle(
                  fontSize: responsive.fontSize(12.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: Text(
                actionLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
