import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../utils/responsive_utils.dart';
import '../../shared/models/home_models.dart';
import '../services/home_data_service.dart';

class CriticalAlertsScreen extends StatefulWidget {
  final String? homeId;

  const CriticalAlertsScreen({super.key, this.homeId});

  @override
  State<CriticalAlertsScreen> createState() => _CriticalAlertsScreenState();
}

class _CriticalAlertsScreenState extends State<CriticalAlertsScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Asset data for navigation
  final List<Map<String, dynamic>> _allAssets = [
    {
      'id': '1',
      'name': 'Refrigerator',
      'type': 'Refrigerator',
      'location': 'Kitchen',
    },
    {
      'id': '4',
      'name': 'LG AC Living',
      'type': 'Air Conditioner',
      'location': 'Living Room',
    },
    {
      'id': '13',
      'name': 'Bosch Dishwasher',
      'type': 'Dishwasher',
      'location': 'Kitchen',
    },
    {
      'id': '11',
      'name': 'Kitchen Stove',
      'type': 'Stove',
      'location': 'Kitchen',
    },
  ];

  Map<String, dynamic> _getAssetById(String assetId) {
    return _allAssets.firstWhere(
      (a) => a['id'] == assetId,
      orElse: () => {'id': assetId, 'name': 'Asset', 'location': ''},
    );
  }

  List<CriticalAlert> _getFilteredAlerts() {
    var alerts = HomeDataService.getMockCriticalAlerts(widget.homeId);

    if (_searchQuery.isNotEmpty) {
      alerts = alerts.where((alert) {
        final searchLower = _searchQuery.toLowerCase();
        return alert.assetName.toLowerCase().contains(searchLower) ||
            alert.issue.toLowerCase().contains(searchLower) ||
            alert.category.toLowerCase().contains(searchLower);
      }).toList();
    }

    // Show all alerts for the selected home (same as home tab)
    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _getFilteredAlerts();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Critical Alerts',
          style: TextStyle(
            color: AppColors.headerForeground,
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: MediaQuery.of(context).size.height < 700 ? 10 : 16,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.mic,
                    color: AppColors.textPlaceholder,
                    size: responsive.iconSize(20),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search Alerts...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        isDense: true,
                        hintStyle: TextStyle(
                          fontSize: responsive.fontSize(16),
                          color: AppColors.textPlaceholder,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Handle send action
                    },
                    child: Icon(
                      Icons.send,
                      color: AppColors.primary,
                      size: responsive.iconSize(20),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Alerts List
          Expanded(
            child: alerts.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      bottom: 16,
                    ),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      return _buildAlertCard(context, alerts[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: responsive.iconSize(80),
            color: AppColors.gray300,
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'No Critical Alerts',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Everything is running smoothly',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, CriticalAlert alert) {
    // Get asset details for location
    final asset = _getAssetById(alert.assetId);
    final location = asset['location'] ?? '';

    return GestureDetector(
      onTap: () {
        // Card click navigates to asset detail
        context.push('/asset-detail', extra: asset);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(responsive.spacing(16)),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Asset Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                alert.iconData,
                size: responsive.iconSize(24),
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            // Asset Name, Location, Badge, and Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and Badge Row
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          alert.assetName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: alert.severity == AlertSeverity.critical
                              ? AppColors.errorLight
                              : AppColors.warningLight,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Text(
                          alert.severity == AlertSeverity.critical
                              ? 'CRITICAL'
                              : 'WARNING',
                          style: TextStyle(
                            fontSize: responsive.fontSize(10),
                            fontWeight: FontWeight.bold,
                            color: alert.severity == AlertSeverity.critical
                                ? AppColors.errorMaterialDark
                                : AppColors.warningOrange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (location.isNotEmpty) ...[
                    SizedBox(height: responsive.spacing(2)),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    alert.issue,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.gray700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.spacing(8)),
            // Action Button
            if (alert.actionLabel != null)
              SizedBox(
                width: 90,
                height: 36,
                child: ElevatedButton(
                  onPressed: () {
                    // Execute proper flow based on alert category
                    if (alert.alertCategory == AlertCategory.warranty &&
                        alert.isExpired) {
                      // Warranty expired → Go to protection plans with asset data
                      context.push('/warranties', extra: asset);
                    } else if (alert.alertCategory == AlertCategory.service ||
                        alert.alertCategory == AlertCategory.maintenance ||
                        alert.alertCategory == AlertCategory.safety) {
                      // Service/maintenance needed → Go to services screen
                      context.push('/services');
                    } else if (alert.actionRoute != null) {
                      if (alert.actionRoute == '/asset-detail') {
                        context.push('/asset-detail', extra: asset);
                      } else {
                        context.push(alert.actionRoute!);
                      }
                    } else {
                      context.push('/asset-detail', extra: asset);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    alert.actionLabel!.split(' ').first,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
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
