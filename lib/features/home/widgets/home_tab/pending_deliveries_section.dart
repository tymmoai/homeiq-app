import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../services/order_service.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/home_models.dart';

/// The "Pending Deliveries" section on the Home tab.
///
/// Shows up to 3 delivery cards with a "View All" link. Supports
/// search-query filtering via [homeSearchQuery].
class PendingDeliveriesSection extends StatefulWidget {
  /// Current search query to filter delivery cards.
  final String homeSearchQuery;

  /// The currently selected home ID for filtering.
  final String? selectedHomeId;

  const PendingDeliveriesSection({
    super.key,
    required this.homeSearchQuery,
    this.selectedHomeId,
  });

  @override
  State<PendingDeliveriesSection> createState() =>
      _PendingDeliveriesSectionState();
}

class _PendingDeliveriesSectionState extends State<PendingDeliveriesSection> {
  List<PendingDelivery> _deliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  @override
  void didUpdateWidget(PendingDeliveriesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedHomeId != widget.selectedHomeId) {
      _loadDeliveries();
    }
  }

  Future<void> _loadDeliveries() async {
    final deliveries = await OrderService.getPendingDeliveries(
      homeId: widget.selectedHomeId,
    );
    if (mounted) {
      setState(() {
        _deliveries = deliveries;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    if (_isLoading) return const SizedBox.shrink();

    var deliveries = _deliveries;

    // Filter by search query
    if (widget.homeSearchQuery.isNotEmpty) {
      deliveries = deliveries.where((delivery) {
        final productName = delivery.productName.toLowerCase();
        final status = delivery.statusLabel.toLowerCase();
        return productName.contains(widget.homeSearchQuery) ||
            status.contains(widget.homeSearchQuery);
      }).toList();
    }

    if (deliveries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pending Deliveries',
                    style: TextStyle(
                      fontSize: responsive.fontSize(20),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Track your orders and replacements',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                context.push(
                  '/pending-deliveries?homeId=${widget.selectedHomeId}',
                );
              },
              child: Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(4)),
                  Icon(
                    Icons.chevron_right,
                    size: responsive.iconSize(18),
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16)),
        ...deliveries
            .take(3)
            .map(
              (delivery) => Padding(
                padding: EdgeInsets.only(bottom: responsive.spacing(12)),
                child: DeliveryCard(delivery: delivery),
              ),
            ),
      ],
    );
  }
}

/// A single pending-delivery card used inside [PendingDeliveriesSection].
class DeliveryCard extends StatelessWidget {
  /// The delivery data to display.
  final PendingDelivery delivery;

  const DeliveryCard({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final imgSize = responsive.isSmallMobile ? 48.0 : 56.0;
    return GestureDetector(
      onTap: () {
        context.push('/orders/${delivery.id}');
      },
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(14)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: responsive.spacing(8),
              offset: Offset(0, responsive.spacing(2)),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: imgSize,
              height: imgSize,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(10),
                ),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(10),
                ),
                child: Image.asset(
                  delivery.productImage,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.inventory_2,
                      size: responsive.iconSize(28),
                      color: AppColors.textLight,
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product title
                  Text(
                    delivery.productName,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (delivery.isMaintenancePart &&
                      delivery.maintenanceTaskName != null) ...[
                    SizedBox(height: responsive.spacing(2)),
                    Row(
                      children: [
                        Icon(
                          Icons.build,
                          size: responsive.iconSize(12),
                          color: AppColors.primary,
                        ),
                        SizedBox(width: responsive.spacing(4)),
                        Expanded(
                          child: Text(
                            'For: ${delivery.maintenanceTaskName}${delivery.forAssetName != null ? ' • ${delivery.forAssetName}' : ''}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(11),
                              fontWeight: FontWeight.w500,
                              color: AppColors.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: responsive.spacing(8)),
                  // Status badge and ETA directly below title
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(6),
                          vertical: responsive.spacing(3),
                        ),
                        decoration: BoxDecoration(
                          color: delivery.statusBackgroundColor,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Text(
                          delivery.statusLabel,
                          style: TextStyle(
                            fontSize: responsive.fontSize(10),
                            fontWeight: FontWeight.w600,
                            color: delivery.statusColor,
                          ),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(10)),
                      Icon(
                        Icons.local_shipping,
                        size: responsive.iconSize(14),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Text(
                        'ETA: ${delivery.getFormattedETA()}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: responsive.iconSize(20),
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}
