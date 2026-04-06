import 'package:flutter/material.dart';
import '../../shared/models/home_models.dart';

class HomeDataService {
  // Mock Critical Alerts Data — only returns data when real assets exist
  static List<CriticalAlert> getMockCriticalAlerts(
    String? homeId, {
    List<Map<String, dynamic>> realAssets = const [],
  }) {
    // If user has no real assets, return empty (new user experience)
    if (realAssets.isEmpty) return [];

    final allAlerts = <CriticalAlert>[];

    // Generate alerts based on real assets
    for (final asset in realAssets) {
      final assetId = asset['id']?.toString() ?? '';
      final assetName = asset['name']?.toString() ?? 'Asset';
      final location = asset['location']?.toString() ?? '';
      final warranty = asset['warranty']?.toString() ?? '';
      final warrantyEndDate = asset['warrantyEndDate']?.toString() ?? '';
      final healthScore = (asset['healthScore'] as num?)?.toDouble() ?? 10.0;

      // Check for expired warranty
      if (warranty.toLowerCase() == 'expired') {
        allAlerts.add(
          CriticalAlert(
            id: 'alert_warranty_$assetId',
            homeId: homeId ?? 'home-1',
            assetId: assetId,
            assetName: assetName,
            category: asset['type']?.toString() ?? 'Appliance',
            location: location,
            issue: warrantyEndDate.isNotEmpty
                ? 'Warranty expired on $warrantyEndDate'
                : 'Warranty expired',
            severity: AlertSeverity.warning,
            alertCategory: AlertCategory.warranty,
            iconData: Icons.shield_outlined,
            alertDate: DateTime.now(),
            isExpired: true,
            actionLabel: 'Renew',
            actionRoute: '/warranties',
          ),
        );
      }

      // Check for low health score
      if (healthScore < 5.0) {
        allAlerts.add(
          CriticalAlert(
            id: 'alert_health_$assetId',
            homeId: homeId ?? 'home-1',
            assetId: assetId,
            assetName: assetName,
            category: asset['type']?.toString() ?? 'Appliance',
            location: location,
            issue:
                'Health score critical (${healthScore.toStringAsFixed(1)}/10) — service recommended',
            severity: AlertSeverity.critical,
            alertCategory: AlertCategory.maintenance,
            iconData: Icons.warning_amber,
            alertDate: DateTime.now().subtract(const Duration(days: 7)),
            isExpired: false,
            actionLabel: 'Book Service',
            actionRoute: '/services',
          ),
        );
      } else if (healthScore < 6.5) {
        allAlerts.add(
          CriticalAlert(
            id: 'alert_health_$assetId',
            homeId: homeId ?? 'home-1',
            assetId: assetId,
            assetName: assetName,
            category: asset['type']?.toString() ?? 'Appliance',
            location: location,
            issue:
                'Health score low (${healthScore.toStringAsFixed(1)}/10) — maintenance recommended',
            severity: AlertSeverity.warning,
            alertCategory: AlertCategory.maintenance,
            iconData: Icons.build_outlined,
            alertDate: DateTime.now(),
            isExpired: false,
            actionLabel: 'Schedule Service',
            actionRoute: '/services',
          ),
        );
      }
    }

    return allAlerts;
  }

  // Mock Active Services Data — only returns data when real assets exist
  static List<ActiveService> getMockActiveServices(
    String? homeId, {
    List<Map<String, dynamic>> realAssets = const [],
  }) {
    // If user has no real assets, return empty (new user experience)
    if (realAssets.isEmpty) return [];

    // For users with assets, return any saved bookings (handled by BookingService)
    // No hardcoded mock services
    return [];
  }

  // Mock Pending Deliveries Data — only returns data when real assets/orders exist
  static List<PendingDelivery> getMockPendingDeliveries(
    String? homeId, {
    List<Map<String, dynamic>> realAssets = const [],
  }) {
    // If user has no real assets, return empty (new user experience)
    if (realAssets.isEmpty) return [];

    // For users with assets, return empty — real deliveries come from backend
    return [];
  }

  // Get summary counts
  static Map<String, int> getHomeSummary(
    String? homeId, {
    List<Map<String, dynamic>> realAssets = const [],
  }) {
    final alerts = getMockCriticalAlerts(homeId, realAssets: realAssets);
    final services = getMockActiveServices(homeId, realAssets: realAssets);
    final deliveries = getMockPendingDeliveries(homeId, realAssets: realAssets);

    return {
      'criticalAlerts': alerts.length,
      'activeServices': services.length,
      'pendingDeliveries': deliveries.length,
      'expiredWarranties': alerts.where((a) => a.isExpired).length,
      'overdueServices': alerts.where((a) => a.isOverdue).length,
    };
  }
}
