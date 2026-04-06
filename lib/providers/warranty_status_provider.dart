import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data_providers.dart';

// ─── Warranty Status Enum ─────────────────────────────────────────────────────

enum WarrantyStatus {
  active, // Green  — within warranty date OR active protection plan
  expiringSoon, // Orange — expires within 30 days
  expired, // Red    — past warranty date AND no active protection plan
  notPurchased, // Grey   — no warranty info at all
}

extension WarrantyStatusExt on WarrantyStatus {
  /// Human-readable label shown in badges throughout the app.
  String get label {
    switch (this) {
      case WarrantyStatus.active:
        return 'Active';
      case WarrantyStatus.expiringSoon:
        return 'Expiring Soon';
      case WarrantyStatus.expired:
        return 'Expired';
      case WarrantyStatus.notPurchased:
        return 'Not Purchased';
    }
  }

  /// Whether this status is considered "protected" (asset is covered).
  bool get isProtected =>
      this == WarrantyStatus.active || this == WarrantyStatus.expiringSoon;
}

// ─── Per-asset warranty status provider ──────────────────────────────────────

/// Returns the [WarrantyStatus] for a single asset map (legacy format).
///
/// Reads from:
///   1. `hasActiveProtectionPlan` — if true, status is [WarrantyStatus.active]
///   2. `warrantyEndDate` ISO string — compared against now
///   3. `warranty` string field — "active" / "expired" fallbacks
///
/// This is the single source of truth for warranty status throughout the app.
WarrantyStatus computeWarrantyStatus(Map<String, dynamic> asset) {
  // Active protection plan overrides everything
  final hasActivePlan =
      asset['hasActiveProtectionPlan'] == true ||
      asset['protectionPlanStatus']?.toString().toLowerCase() == 'active';
  if (hasActivePlan) return WarrantyStatus.active;

  // Check explicit warranty string
  final warrantyStr = (asset['warranty'] ?? '').toString().toLowerCase();
  if (warrantyStr == 'not purchased' || warrantyStr == 'none') {
    return WarrantyStatus.notPurchased;
  }

  // Check warranty end date
  final endDateStr = asset['warrantyEndDate']?.toString();
  if (endDateStr != null && endDateStr.isNotEmpty && endDateStr != 'null') {
    try {
      final endDate = DateTime.parse(endDateStr);
      final now = DateTime.now();
      final diffDays = endDate.difference(now).inDays;
      if (diffDays < 0) return WarrantyStatus.expired;
      if (diffDays <= 30) return WarrantyStatus.expiringSoon;
      return WarrantyStatus.active;
    } on Object catch (_) {
      // Fall through to string-based check
    }
  }

  // String fallback
  if (warrantyStr == 'expired') return WarrantyStatus.expired;
  if (warrantyStr == 'active') return WarrantyStatus.active;
  if (warrantyStr.isEmpty || warrantyStr == 'unknown') {
    return WarrantyStatus.notPurchased;
  }

  return WarrantyStatus.active;
}

/// Provider that returns a map of assetId → [WarrantyStatus] for all assets
/// in the currently selected home. Automatically updates when assets refresh
/// or a protection plan is purchased (invalidate [assetsProvider] to trigger).
final warrantyStatusMapProvider = Provider<Map<String, WarrantyStatus>>((ref) {
  final assets = ref.watch(assetsLegacyProvider);
  return {
    for (final a in assets)
      (a['id'] as String? ?? ''): computeWarrantyStatus(a),
  };
});

/// Convenience provider: returns [WarrantyStatus] for a single asset by ID.
/// Usage: `ref.watch(warrantyStatusForAssetProvider('asset-id'))`
final warrantyStatusForAssetProvider = Provider.family<WarrantyStatus, String>((
  ref,
  assetId,
) {
  final map = ref.watch(warrantyStatusMapProvider);
  return map[assetId] ?? WarrantyStatus.notPurchased;
});
