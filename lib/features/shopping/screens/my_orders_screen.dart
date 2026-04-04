import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/logger.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/order_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../shared/models/order_models.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen>
    with SingleTickerProviderStateMixin {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Color get _headerColor => AppColors.headerBackground;
  late TabController _tabController;
  String _searchQuery = '';
  String _orderTypeFilter = 'all'; // all, upgrade, part

  List<OrderSummary> _allOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadOrderHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadOrderHistory();
  }

  Future<void> _loadOrderHistory() async {
    try {
      AppLogger.debug('Loading order history from backend...', tag: 'MyOrders');

      final orders = await OrderService.getOrders();
      AppLogger.debug('Found ${orders.length} orders', tag: 'MyOrders');

      // Filter out invalid entries
      final validOrders = orders
          .where(
            (order) =>
                order.productName != 'Unknown Product' &&
                order.productName.isNotEmpty,
          )
          .toList();

      AppLogger.info('Valid orders: ${validOrders.length}', tag: 'MyOrders');

      if (mounted) {
        setState(() {
          _allOrders = validOrders;
          _isLoading = false;
        });
      }
    } on Object catch (e) {
      AppLogger.error(
        'Error loading order history: $e',
        tag: 'MyOrders',
        error: e,
      );
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<OrderSummary> get _filteredOrders {
    var orders = _allOrders;

    // Filter by tab
    final tabIndex = _tabController.index;
    if (tabIndex == 1) {
      // Active orders
      orders = orders
          .where(
            (o) => ![
              OrderStatus.completed,
              OrderStatus.canceled,
              OrderStatus.delivered,
              OrderStatus.installed,
            ].contains(o.orderStatus),
          )
          .toList();
    } else if (tabIndex == 2) {
      // Completed orders
      orders = orders
          .where(
            (o) => [
              OrderStatus.delivered,
              OrderStatus.installed,
              OrderStatus.completed,
            ].contains(o.orderStatus),
          )
          .toList();
    }

    // Filter by order type
    if (_orderTypeFilter == 'upgrade') {
      orders = orders.where((o) => o.orderType == OrderType.upgrade).toList();
    } else if (_orderTypeFilter == 'part') {
      orders = orders.where((o) => o.orderType == OrderType.part).toList();
    }

    // Filter by search
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      orders = orders.where((o) {
        return o.productName.toLowerCase().contains(query) ||
            o.orderId.toLowerCase().contains(query) ||
            (o.oldAssetName?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort by order date, newest first
    orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

    return orders;
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, y').format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Check if family member has 'orders' service access
    final isOwner = ref.watch(selectedHomeIsOwnerProvider);
    final grantedSvcAsync = ref.watch(grantedServiceTypesProvider);
    final grantedSvc = grantedSvcAsync.valueOrNull;
    final hasOrdersAccess =
        !grantedSvcAsync.hasValue ||
        isOwner ||
        (grantedSvc?.contains('orders') ?? true);

    if (!hasOrdersAccess) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: _headerColor,
          elevation: 2,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'My Orders',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.headerForeground,
            ),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Access',
                  style: TextStyle(
                    fontSize: responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You don\'t have permission to view orders for this home. Contact the home owner to request access.',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'My Orders',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.headerForeground,
          ),
        ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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
                            decoration: InputDecoration(
                              hintText: 'Search Orders...',
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
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
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
                SizedBox(width: responsive.spacing(10)),
                // Filter Button
                GestureDetector(
                  onTap: _showFilterDrawer,
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
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

          // Orders List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : _filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 8,
                      bottom: 16,
                    ),
                    itemCount: _filteredOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(_filteredOrders[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(OrderSummary order) {
    return GestureDetector(
      onTap: () {
        context.push('/orders/${order.id}');
      },
      child: Container(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Section: Order ID (left) and Badge (right) in same row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Order ID at top left
                  Text(
                    'Order #${order.orderId}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // Status Badge at top right
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: OrderHelper.getStatusBackgroundColor(
                        order.orderStatus,
                      ),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(order.orderStatus),
                          size: 13,
                          color: OrderHelper.getStatusColor(order.orderStatus),
                        ),
                        SizedBox(width: responsive.spacing(5)),
                        Text(
                          OrderHelper.getStatusLabel(order.orderStatus),
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: OrderHelper.getStatusColor(
                              order.orderStatus,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content Row
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image - Real asset image
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: _getAssetImage(order.productName),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),

                  // Product Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name
                        Text(
                          order.productName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(15),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: responsive.spacing(6)),

                        // Price and Date
                        Row(
                          children: [
                            Text(
                              '\$${order.totalAmount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Text(
                              _formatDate(order.orderDate),
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),

                        // Trade-in or Part Info
                        if (order.hasTradeIn && order.oldAssetName != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    responsive.spacing(1),
                                  ),

                                  child: Icon(
                                    Icons.sync,
                                    size: responsive.iconSize(18),
                                    color: AppColors.navy,
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(6)),
                                Expanded(
                                  child: Text(
                                    'Replacing ${order.oldAssetName}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(11),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        if (order.orderType == OrderType.part &&
                            order.partCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(
                                    responsive.spacing(1),
                                  ),
                                  child: Icon(
                                    Icons.build,
                                    size: responsive.iconSize(18),
                                    color: AppColors.navy,
                                  ),
                                ),
                                SizedBox(width: responsive.spacing(6)),
                                Expanded(
                                  child: Text(
                                    '${order.partCategory} • ${order.compatibleWith ?? 'Compatible Part'}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(11),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.navy,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Chevron
                  Icon(
                    Icons.chevron_right,
                    color: AppColors.textSecondary,
                    size: responsive.iconSize(24),
                  ),
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, thickness: 1),

            // Bottom Info: Delivery date at bottom left
            Padding(
              padding: EdgeInsets.all(responsive.spacing(12)),
              child: Row(
                children: [
                  // Delivery/Status info on the left
                  if (order.estimatedDelivery != null &&
                      ![
                        OrderStatus.completed,
                        OrderStatus.delivered,
                        OrderStatus.installed,
                      ].contains(order.orderStatus))
                    Row(
                      children: [
                        Icon(
                          Icons.local_shipping,
                          size: responsive.iconSize(16),
                          color: AppColors.navyLight,
                        ),
                        SizedBox(width: responsive.spacing(6)),
                        Text(
                          'Est. ${_formatDate(order.estimatedDelivery!)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    )
                  else if ([
                    OrderStatus.completed,
                    OrderStatus.delivered,
                    OrderStatus.installed,
                  ].contains(order.orderStatus))
                    Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: responsive.iconSize(16),
                          color: AppColors.slate500,
                        ),
                        SizedBox(width: responsive.spacing(6)),
                        Text(
                          'Order Complete',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: AppColors.slate500,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: responsive.iconSize(16),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: responsive.spacing(6)),
                        Text(
                          'Processing',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: responsive.iconSize(80),
            color: AppColors.gray300,
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'No orders found',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Your orders will appear here',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
      case OrderStatus.processing:
        return Icons.schedule;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
      case OrderStatus.installed:
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.canceled:
        return Icons.cancel;
    }
  }

  Widget _getAssetImage(String productName) {
    String imagePath;

    // Map product names to their corresponding images
    if (productName.toLowerCase().contains('refrigerator')) {
      if (productName.toLowerCase().contains('samsung')) {
        imagePath = 'lib/asset_img/samsung 4-door flex refrigerator.jpg';
      } else if (productName.toLowerCase().contains('frigidaire')) {
        imagePath =
            'lib/asset_img/Frrigidaire Gallery French Door Refrigerator.jpg';
      } else if (productName.toLowerCase().contains('ge')) {
        imagePath = 'lib/asset_img/GE French door refri refrigerator.jpg';
      } else if (productName.toLowerCase().contains('whirlpool')) {
        imagePath = 'lib/asset_img/Whirlpool French Door Refrigerator.jpg';
      } else if (productName.toLowerCase().contains('lg')) {
        imagePath = 'lib/asset_img/lg instaview door-in-door refrigerator.jpg';
      } else {
        imagePath = 'lib/asset_img/Refrigerator.jpg';
      }
    } else if (productName.toLowerCase().contains('washing machine') ||
        productName.toLowerCase().contains('washer')) {
      if (productName.toLowerCase().contains('lg') ||
          productName.toLowerCase().contains('front load')) {
        imagePath = 'lib/asset_img/LG Front Load Washer (4.5 cu ft).jpg';
      } else if (productName.toLowerCase().contains('samsung') ||
          productName.toLowerCase().contains('top load')) {
        imagePath = 'lib/asset_img/Samsung top load washer(5.0 cu ft).jpg';
      } else {
        imagePath = 'lib/asset_img/Washing_Machine.jpg';
      }
    } else if (productName.toLowerCase().contains('dishwasher')) {
      if (productName.toLowerCase().contains('whirlpool')) {
        imagePath = 'lib/asset_img/bosch 300 series dishwasher.jpg';
      } else if (productName.toLowerCase().contains('bosch')) {
        imagePath = 'lib/asset_img/bosch_dishwasher.jpg';
      } else if (productName.toLowerCase().contains('ge')) {
        imagePath = 'lib/asset_img/GE profile Dshwasher with Microban.jpg';
      } else {
        imagePath = 'lib/asset_img/bosch 300 series dishwasher.jpg';
      }
    } else if (productName.toLowerCase().contains('water filter')) {
      imagePath =
          'lib/asset_img/Refrigerator.jpg'; // Use refrigerator for water filter
    } else if (productName.toLowerCase().contains('ac') ||
        productName.toLowerCase().contains('air conditioner')) {
      if (productName.toLowerCase().contains('window')) {
        imagePath = 'lib/asset_img/carrier 12,000 BTU Window AC.jpg';
      } else {
        imagePath = 'lib/asset_img/Daikin 12,000 BTU Mini Split AC.jpg';
      }
    } else if (productName.toLowerCase().contains('water heater')) {
      imagePath = 'lib/asset_img/Water_Heater.jpg';
    } else if (productName.toLowerCase().contains('oven')) {
      imagePath = 'lib/asset_img/Oven.jpg';
    } else if (productName.toLowerCase().contains('tv')) {
      imagePath = 'lib/asset_img/TV.jpg';
    } else if (productName.toLowerCase().contains('router')) {
      imagePath = 'lib/asset_img/Router.jpg';
    } else {
      // Default fallback icon
      return Icon(
        Icons.inventory_2,
        size: responsive.iconSize(32),
        color: AppColors.gray400,
      );
    }

    return Image.asset(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Icon(
          Icons.inventory_2,
          size: responsive.iconSize(32),
          color: AppColors.gray400,
        );
      },
    );
  }

  void _showFilterDrawer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(responsive.spacing(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter Orders',
                    style: TextStyle(
                      fontSize: responsive.fontSize(20),
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
              SizedBox(height: responsive.spacing(24)),

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
                  _buildFilterChip('All', _tabController.index == 0, () {
                    setState(() {
                      _tabController.index = 0;
                    });
                    setModalState(() {});
                  }),
                  _buildFilterChip('Active', _tabController.index == 1, () {
                    setState(() {
                      _tabController.index = 1;
                    });
                    setModalState(() {});
                  }),
                  _buildFilterChip('Completed', _tabController.index == 2, () {
                    setState(() {
                      _tabController.index = 2;
                    });
                    setModalState(() {});
                  }),
                ],
              ),
              SizedBox(height: responsive.spacing(24)),

              // Type Filter
              Text(
                'Order Type',
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
                  _buildFilterChip('All Types', _orderTypeFilter == 'all', () {
                    setState(() {
                      _orderTypeFilter = 'all';
                    });
                    setModalState(() {});
                  }),
                  _buildFilterChip(
                    'Upgrades',
                    _orderTypeFilter == 'upgrade',
                    () {
                      setState(() {
                        _orderTypeFilter = 'upgrade';
                      });
                      setModalState(() {});
                    },
                  ),
                  _buildFilterChip('Parts', _orderTypeFilter == 'part', () {
                    setState(() {
                      _orderTypeFilter = 'part';
                    });
                    setModalState(() {});
                  }),
                ],
              ),
              SizedBox(height: responsive.spacing(24)),

              // Apply Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.spacing(16),
                    ),
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
              SizedBox(height: responsive.spacing(8)),
            ],
          ),
        ),
      ),
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
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.gray300,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: isSelected ? AppColors.textOnPrimary : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
