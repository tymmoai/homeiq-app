import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../services/order_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../shared/models/home_models.dart';

class PendingDeliveriesScreen extends StatefulWidget {
  final String? homeId;

  const PendingDeliveriesScreen({super.key, this.homeId});

  @override
  State<PendingDeliveriesScreen> createState() =>
      _PendingDeliveriesScreenState();
}

class _PendingDeliveriesScreenState extends State<PendingDeliveriesScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  String _searchQuery = '';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  List<PendingDelivery> _allDeliveries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDeliveries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDeliveries() async {
    final deliveries = await OrderService.getPendingDeliveries(
      homeId: widget.homeId,
    );
    if (mounted) {
      setState(() {
        _allDeliveries = deliveries;
        _isLoading = false;
      });
    }
  }

  List<PendingDelivery> _getFilteredDeliveries() {
    var deliveries = _allDeliveries;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      deliveries = deliveries.where((delivery) {
        final searchLower = _searchQuery.toLowerCase();
        return delivery.productName.toLowerCase().contains(searchLower) ||
            delivery.orderId.toLowerCase().contains(searchLower) ||
            (delivery.trackingNumber?.toLowerCase().contains(searchLower) ??
                false);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatusFilter != 'All') {
      deliveries = deliveries
          .where(
            (d) =>
                d.status.toLowerCase() ==
                _selectedStatusFilter.toLowerCase().replaceAll(' ', '-'),
          )
          .toList();
    }

    // Show all deliveries for the selected home (same as home tab)
    return deliveries;
  }

  @override
  Widget build(BuildContext context) {
    final deliveries = _isLoading
        ? <PendingDelivery>[]
        : _getFilteredDeliveries();

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
        titleSpacing: 0,
        title: Text(
          'Pending Deliveries',
          style: TextStyle(
            color: AppColors.headerForeground,
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Material(
                color: AppColors.headerForeground.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                  onTap: () {
                    context.push('/orders');
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                      border: Border.all(
                        color: AppColors.headerForeground.withValues(
                          alpha: 0.4,
                        ),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          color: AppColors.headerForeground,
                          size: responsive.iconSize(15),
                        ),
                        SizedBox(width: responsive.spacing(6)),
                        Text(
                          'All Orders',
                          style: TextStyle(
                            color: AppColors.headerForeground,
                            fontSize: responsive.fontSize(13),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar and Filter Button Row
          Padding(
            padding: EdgeInsets.all(responsive.spacing(10)),
            child: Row(
              children: [
                // Search Bar
                Expanded(
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
                      vertical: MediaQuery.of(context).size.height < 700
                          ? 10
                          : 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.mic,
                          color: AppColors.textSecondary,
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
                              hintText: 'Search Deliveries...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                              hintStyle: TextStyle(
                                fontSize: responsive.fontSize(16),
                                color: AppColors.textSecondary,
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
                            // Handle send action if needed
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
                SizedBox(width: responsive.spacing(8)),
                // Filter Button
                GestureDetector(
                  onTap: _showFilterDrawer,
                  child: Container(
                    width: 52,
                    height: 52,
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
                    child: Icon(
                      Icons.tune,
                      color: AppColors.primary,
                      size: responsive.iconSize(24),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Deliveries List
          Expanded(
            child: deliveries.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 16,
                    ),
                    itemCount: deliveries.length,
                    itemBuilder: (context, index) {
                      return _buildDeliveryCard(context, deliveries[index]);
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
            Icons.local_shipping_outlined,
            size: responsive.iconSize(80),
            color: AppColors.gray300,
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'No Pending Deliveries',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'All your orders have been delivered',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, PendingDelivery delivery) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: InkWell(
        onTap: () {
          context.push('/orders/${delivery.id}');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(16)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order ID and status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Order #${delivery.orderId}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
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
                        fontSize: responsive.fontSize(12),
                        fontWeight: FontWeight.w600,
                        color: delivery.statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12)),
              // Product image and details
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        delivery.productImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.inventory_2,
                            size: responsive.iconSize(32),
                            color: AppColors.gray400,
                          );
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          delivery.productName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (delivery.isMaintenancePart &&
                            delivery.maintenanceTaskName != null) ...[
                          SizedBox(height: responsive.spacing(4)),
                          Row(
                            children: [
                              Icon(
                                Icons.build,
                                size: responsive.iconSize(13),
                                color: AppColors.primary,
                              ),
                              SizedBox(width: responsive.spacing(4)),
                              Expanded(
                                child: Text(
                                  'For: ${delivery.maintenanceTaskName}${delivery.forAssetName != null ? ' â€¢ ${delivery.forAssetName}' : ''}',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(12),
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
                        SizedBox(height: responsive.spacing(6)),
                        Text(
                          '\$${delivery.totalAmount.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: responsive.iconSize(24),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12)),
              const Divider(height: 1),
              SizedBox(height: responsive.spacing(12)),
              // ETA
              Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    size: responsive.iconSize(20),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Text(
                    'Est. Delivery: ${delivery.getFormattedETA()}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (delivery.isUrgent) ...[
                    SizedBox(width: responsive.spacing(8)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.errorLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.error),
                      ),
                      child: Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: responsive.fontSize(10),
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (delivery.trackingNumber != null) ...[
                SizedBox(height: responsive.spacing(8)),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: responsive.iconSize(16),
                      color: AppColors.textSecondary,
                    ),
                    SizedBox(width: responsive.spacing(6)),
                    Text(
                      'Tracking: ${delivery.trackingNumber}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              padding: EdgeInsets.all(responsive.spacing(20)),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter Deliveries',
                        style: TextStyle(
                          fontSize: responsive.fontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(20)),
                  // Status Filter
                  Text(
                    'Status',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFilterChip(
                        'All',
                        _selectedStatusFilter == 'All',
                        () {
                          setState(() {
                            _selectedStatusFilter = 'All';
                          });
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChip(
                        'Processing',
                        _selectedStatusFilter == 'Processing',
                        () {
                          setState(() {
                            _selectedStatusFilter = 'Processing';
                          });
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChip(
                        'Shipped',
                        _selectedStatusFilter == 'Shipped',
                        () {
                          setState(() {
                            _selectedStatusFilter = 'Shipped';
                          });
                          setModalState(() {});
                        },
                      ),
                      _buildFilterChip(
                        'Out for Delivery',
                        _selectedStatusFilter == 'Out for Delivery',
                        () {
                          setState(() {
                            _selectedStatusFilter = 'Out for Delivery';
                          });
                          setModalState(() {});
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(20)),
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.spacing(14),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(16),
          vertical: responsive.spacing(10),
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.backgroundGray100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? AppColors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
