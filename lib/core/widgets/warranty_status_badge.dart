import 'package:flutter/material.dart';

import '../../providers/warranty_status_provider.dart';
import '../constants/app_colors.dart';

/// Central, reusable warranty status badge.
///
/// Colours are **the single source of truth** for all warranty status displays:
///   Active         → Green  background + text
///   Expiring Soon  → Orange background + text
///   Expired        → Red    background + text
///   Not Purchased  → Grey   background + text
///
/// Usage:
///   WarrantyStatusBadge(status: WarrantyStatus.active)
///   WarrantyStatusBadge.fromAsset(asset: assetMap)
class WarrantyStatusBadge extends StatelessWidget {
  final WarrantyStatus status;
  final bool compact;

  const WarrantyStatusBadge({
    super.key,
    required this.status,
    this.compact = false,
  });

  /// Convenience constructor — derives status from the legacy asset map.
  factory WarrantyStatusBadge.fromAsset({
    Key? key,
    required Map<String, dynamic> asset,
    bool compact = false,
  }) {
    return WarrantyStatusBadge(
      key: key,
      status: computeWarrantyStatus(asset),
      compact: compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _resolveColors();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 10,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: compact ? 10 : 12, color: fg),
          SizedBox(width: compact ? 3 : 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  (Color bg, Color fg, IconData icon) _resolveColors() {
    switch (status) {
      case WarrantyStatus.active:
        return (
          AppColors.successLight,
          AppColors.successMaterialDark,
          Icons.shield_rounded,
        );
      case WarrantyStatus.expiringSoon:
        return (
          AppColors.warningLight,
          AppColors.warningOrange,
          Icons.schedule_rounded,
        );
      case WarrantyStatus.expired:
        return (
          AppColors.errorLight,
          AppColors.errorDark,
          Icons.shield_outlined,
        );
      case WarrantyStatus.notPurchased:
        return (
          const Color(0xFFF5F5F5),
          const Color(0xFF9E9E9E),
          Icons.shield_outlined,
        );
    }
  }
}
