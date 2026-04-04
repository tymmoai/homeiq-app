import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/order_service.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/order_models.dart';

class OrderDetailScreen extends StatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderSummary? order;
  bool isLoading = true;
  List<TimelineEvent> orderTimeline = [];
  bool showFullTimeline = false;

  String _buildDeliveryAddressText() {
    final user = UserService.instance;
    final addr = user.getUserAddress();
    final apt = user.getUserApartmentUnit();
    final city = user.getUserCity();
    final state = user.getUserState();
    final zip = user.getUserZipCode();
    if (addr.isEmpty) return 'No address on file';
    final line1 = apt.isNotEmpty ? '$addr, $apt' : addr;
    final csz = <String>[
      if (city.isNotEmpty) city,
      if (state.isNotEmpty) state,
    ].join(', ');
    final line2 = zip.isNotEmpty ? '$csz $zip' : csz;
    return line2.trim().isNotEmpty
        ? '$line1\n$line2\nUnited States'
        : '$line1\nUnited States';
  }

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload order details when screen becomes visible again
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    try {
      AppLogger.debug(
        'OrderDetailScreen: Loading order ${widget.orderId}',
        tag: 'OrderDetail',
      );
      final loadedOrder = await OrderService.getOrderById(widget.orderId);

      if (mounted) {
        setState(() {
          order = loadedOrder;
          if (order != null) {
            orderTimeline = _generateTimeline(order!);
            AppLogger.info(
              'OrderDetailScreen: Order loaded - ${order!.productName}',
              tag: 'OrderDetail',
            );
          } else {
            AppLogger.warning(
              'OrderDetailScreen: Order not found',
              tag: 'OrderDetail',
            );
          }
          isLoading = false;
        });
      }
    } on Object catch (e) {
      AppLogger.error(
        'OrderDetailScreen: Error loading order: $e',
        tag: 'OrderDetail',
        error: e,
      );
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : order == null
          ? const Center(child: Text('Order not found'))
          : SafeArea(
              child: Column(
                children: [
                  _buildHeader(responsive),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.all(responsive.wp(4)),
                      child: Column(
                        children: [
                          _buildOrderStatusCard(responsive),
                          SizedBox(height: responsive.hp(2)),
                          _buildOrderDetailsCard(responsive),
                          SizedBox(height: responsive.hp(2)),
                          _buildProductDetailsCard(responsive),
                          if (order!.hasTradeIn) ...[
                            SizedBox(height: responsive.hp(2)),
                            _buildTradeInCard(responsive),
                          ],
                          SizedBox(height: responsive.hp(2)),
                          _buildPricingCard(responsive),
                          SizedBox(height: responsive.hp(2)),
                          _buildShippingDetailsCard(responsive),
                          SizedBox(height: responsive.hp(2)),
                          _buildOrderTimelineCard(responsive),
                          SizedBox(height: responsive.hp(4)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  List<TimelineEvent> _generateTimeline(OrderSummary order) {
    final events = <TimelineEvent>[];
    final orderDate = order.orderDate;

    // Order Placed
    events.add(
      TimelineEvent(
        id: '1',
        title: 'Order Placed',
        description: 'Your order has been confirmed',
        timestamp: orderDate,
        status: 'placed',
        isCompleted: true,
        isCurrent: false,
      ),
    );

    // Processing
    final processingDate = orderDate.add(const Duration(hours: 2));
    events.add(
      TimelineEvent(
        id: '2',
        title: 'Processing',
        description: 'Preparing your order for shipment',
        timestamp: order.orderStatus.index >= OrderStatus.processing.index
            ? processingDate
            : null,
        status: 'processing',
        isCompleted: order.orderStatus.index >= OrderStatus.shipped.index,
        isCurrent: order.orderStatus == OrderStatus.processing,
      ),
    );

    // Shipped
    final shippedDate = orderDate.add(const Duration(days: 2));
    events.add(
      TimelineEvent(
        id: '3',
        title: 'Shipped',
        description: 'Package is on its way',
        timestamp: order.orderStatus.index >= OrderStatus.shipped.index
            ? shippedDate
            : null,
        status: 'shipped',
        isCompleted:
            order.orderStatus.index >= OrderStatus.outForDelivery.index,
        isCurrent: order.orderStatus == OrderStatus.shipped,
      ),
    );

    // Out for Delivery
    if (order.estimatedDelivery != null) {
      final outForDeliveryDate = order.estimatedDelivery!;
      events.add(
        TimelineEvent(
          id: '4',
          title: 'Out for Delivery',
          description: 'Package will arrive today',
          timestamp: order.orderStatus.index >= OrderStatus.outForDelivery.index
              ? outForDeliveryDate
              : null,
          status: 'out-for-delivery',
          isCompleted: order.orderStatus.index >= OrderStatus.delivered.index,
          isCurrent: order.orderStatus == OrderStatus.outForDelivery,
        ),
      );
    }

    // Delivered
    events.add(
      TimelineEvent(
        id: '5',
        title: 'Delivered',
        description: order.actualDelivery != null
            ? 'Successfully delivered to your address'
            : 'Package will be delivered soon',
        timestamp: order.actualDelivery,
        status: 'delivered',
        isCompleted:
            order.orderStatus == OrderStatus.delivered ||
            order.orderStatus == OrderStatus.installed ||
            order.orderStatus == OrderStatus.completed,
        isCurrent:
            order.orderStatus == OrderStatus.delivered &&
            order.actualDelivery == null,
      ),
    );

    // Installation (if required)
    if (order.orderType == OrderType.upgrade) {
      events.add(
        TimelineEvent(
          id: '6',
          title: 'Installation',
          description: order.orderStatus == OrderStatus.installed
              ? 'Installation completed successfully'
              : 'Professional installation scheduled',
          timestamp: order.orderStatus == OrderStatus.installed
              ? order.actualDelivery?.add(const Duration(days: 1))
              : null,
          status: 'installed',
          isCompleted:
              order.orderStatus == OrderStatus.installed ||
              order.orderStatus == OrderStatus.completed,
          isCurrent:
              order.orderStatus == OrderStatus.delivered &&
              order.actualDelivery != null,
        ),
      );
    }

    return events;
  }

  IconData _getTimelineIcon(String status) {
    switch (status) {
      case 'placed':
        return Icons.receipt_long;
      case 'processing':
        return Icons.hourglass_empty;
      case 'shipped':
        return Icons.local_shipping;
      case 'out-for-delivery':
        return Icons.delivery_dining;
      case 'delivered':
        return Icons.check_circle;
      case 'installed':
        return Icons.build_circle;
      default:
        return Icons.circle;
    }
  }

  Widget _buildHeader(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.wp(4),
        responsive.hp(1),
        responsive.wp(4),
        responsive.hp(2),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: responsive.wp(10),
              height: responsive.wp(10),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
          SizedBox(width: responsive.wp(4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Details',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Order #${order!.orderId}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderStatusCard(ResponsiveUtils responsive) {
    final statusColor = OrderHelper.getStatusColor(order!.orderStatus);
    final statusText = OrderHelper.getStatusText(order!.orderStatus);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: responsive.wp(12),
                height: responsive.wp(12),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getStatusIcon(order!.orderStatus),
                  color: statusColor,
                  size: responsive.wp(6),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.5)),
                    Text(
                      _getStatusDescription(order!.orderStatus),
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.hp(2)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.wp(3)),
            decoration: BoxDecoration(
              color: AppColors.lightGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: AppColors.textSecondary,
                  size: responsive.wp(5),
                ),
                SizedBox(width: responsive.wp(2)),
                Expanded(
                  child: Text(
                    order!.actualDelivery != null
                        ? 'Delivered on ${DateFormat('MMM dd, yyyy').format(order!.actualDelivery!)}'
                        : order!.estimatedDelivery != null
                        ? 'Estimated delivery: ${DateFormat('MMM dd, yyyy').format(order!.estimatedDelivery!)}'
                        : 'Delivery date pending',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailsCard(ResponsiveUtils responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Information',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(2)),
          _buildDetailRow(
            'Order Date',
            DateFormat('MMM dd, yyyy').format(order!.orderDate),
            responsive,
          ),
          _buildDetailRow(
            'Order Type',
            _getOrderTypeText(order!.orderType),
            responsive,
          ),
          if (order!.partCategory != null)
            _buildDetailRow('Category', order!.partCategory!, responsive),
          if (order!.compatibleWith != null)
            _buildDetailRow(
              'Compatible With',
              order!.compatibleWith!,
              responsive,
            ),
        ],
      ),
    );
  }

  Widget _buildProductDetailsCard(ResponsiveUtils responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Product Details',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(2)),
          Row(
            children: [
              Container(
                width: responsive.wp(16),
                height: responsive.wp(16),
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child:
                      order!.productImage != null &&
                          order!.productImage!.isNotEmpty
                      ? Image.asset(
                          order!.productImage!,
                          fit: BoxFit.cover,
                          width: responsive.wp(16),
                          height: responsive.wp(16),
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              _getProductIcon(order!.orderType),
                              color: AppColors.primary,
                              size: responsive.wp(8),
                            );
                          },
                        )
                      : Icon(
                          _getProductIcon(order!.orderType),
                          color: AppColors.primary,
                          size: responsive.wp(8),
                        ),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order!.productName,
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.5)),
                    Text(
                      order!.productBrand,
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (order!.productModel.isNotEmpty) ...[
                      SizedBox(height: responsive.hp(0.3)),
                      Text(
                        'Model: ${order!.productModel}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (order!.orderType == OrderType.part &&
                        order!.compatibleWith != null) ...[
                      SizedBox(height: responsive.hp(0.5)),
                      Row(
                        children: [
                          Icon(
                            Icons.build,
                            size: responsive.fontSize(13),
                            color: AppColors.primary,
                          ),
                          SizedBox(width: responsive.wp(1)),
                          Expanded(
                            child: Text(
                              'For: ${order!.compatibleWith}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w500,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (order!.orderType == OrderType.part &&
                        order!.partCategory != null) ...[
                      SizedBox(height: responsive.hp(0.3)),
                      Container(
                        margin: EdgeInsets.only(top: responsive.hp(0.3)),
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.wp(2),
                          vertical: responsive.hp(0.3),
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Text(
                          order!.partCategory!,
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeInCard(ResponsiveUtils responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.wp(3),
                  vertical: responsive.hp(0.5),
                ),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                ),
                child: Text(
                  'Trade-In',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                '- \$${order!.tradeInValue?.toStringAsFixed(0) ?? '0'}',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.hp(1.5)),
          Text(
            order!.oldAssetName ?? 'Trade-in appliance',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(ResponsiveUtils responsive) {
    final subtotal = order!.totalAmount + (order!.tradeInValue ?? 0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Summary',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(2)),
          _buildPriceRow(
            'Subtotal',
            '\$${subtotal.toStringAsFixed(2)}',
            responsive,
          ),
          if (order!.hasTradeIn)
            _buildPriceRow(
              'Trade-in Credit',
              '-\$${order!.tradeInValue?.toStringAsFixed(2) ?? '0.00'}',
              responsive,
              isDiscount: true,
            ),
          _buildPriceRow('Shipping', 'Free', responsive),
          SizedBox(height: responsive.hp(1)),
          Container(height: 1, color: AppColors.border),
          SizedBox(height: responsive.hp(1)),
          _buildPriceRow(
            'Total',
            '\$${order!.totalAmount.toStringAsFixed(2)}',
            responsive,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    ResponsiveUtils responsive,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.hp(1.5)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: responsive.wp(25),
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value,
    ResponsiveUtils responsive, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.hp(1)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(isTotal ? 14 : 13),
              color: isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(isTotal ? 14 : 13),
              color: isDiscount
                  ? AppColors.success
                  : isTotal
                  ? AppColors.textPrimary
                  : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimelineCard(ResponsiveUtils responsive) {
    final displayedEvents = showFullTimeline
        ? orderTimeline
        : orderTimeline.take(4).toList();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Timeline',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(2)),
          ...displayedEvents.asMap().entries.map((entry) {
            final index = entry.key;
            final event = entry.value;
            final isLast = index == displayedEvents.length - 1;

            return _buildTimelineItem(event, isLast, responsive);
          }),
          if (orderTimeline.length > 4)
            GestureDetector(
              onTap: () => setState(() => showFullTimeline = !showFullTimeline),
              child: Container(
                width: double.infinity,
                margin: EdgeInsets.only(top: responsive.hp(1)),
                padding: EdgeInsets.symmetric(vertical: responsive.hp(1.5)),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      showFullTimeline ? 'Show Less' : 'Show All Events',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(width: responsive.wp(1)),
                    Icon(
                      showFullTimeline
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: responsive.wp(5),
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    TimelineEvent event,
    bool isLast,
    ResponsiveUtils responsive,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Node and Line
        Column(
          children: [
            Container(
              width: responsive.wp(8),
              height: responsive.wp(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: event.isCompleted ? AppColors.primary : Colors.white,
                border: Border.all(
                  color: event.isCompleted || event.isCurrent
                      ? AppColors.primary
                      : AppColors.border,
                  width: 2,
                ),
              ),
              child: Icon(
                _getTimelineIcon(event.status),
                size: responsive.wp(4),
                color: event.isCompleted
                    ? Colors.white
                    : event.isCurrent
                    ? AppColors.primary
                    : AppColors.textLight,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: responsive.hp(5),
                color: event.isCompleted ? AppColors.primary : AppColors.border,
              ),
          ],
        ),
        SizedBox(width: responsive.wp(3)),
        // Event Details
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : responsive.hp(2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: event.isCompleted || event.isCurrent
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
                if (event.description != null) ...[
                  SizedBox(height: responsive.hp(0.5)),
                  Text(
                    event.description!,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (event.timestamp != null) ...[
                  SizedBox(height: responsive.hp(0.5)),
                  Text(
                    '${DateFormat('MMM dd, yyyy').format(event.timestamp!)} at ${DateFormat('hh:mm a').format(event.timestamp!)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(11),
                      color: AppColors.textLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShippingDetailsCard(ResponsiveUtils responsive) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Shipping Details',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(2)),
          // Shipping Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: responsive.wp(5),
                color: AppColors.textSecondary,
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Delivery Address',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.5)),
                    Text(
                      _buildDeliveryAddressText(),
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppColors.textPrimary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Carrier Info (if shipped)
          if (order!.orderStatus.index >= OrderStatus.shipped.index) ...[
            SizedBox(height: responsive.hp(2)),
            Container(
              padding: EdgeInsets.all(responsive.wp(3)),
              decoration: BoxDecoration(
                color: AppColors.lightGray,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: responsive.wp(5),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: responsive.wp(3)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Carrier',
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: responsive.hp(0.3)),
                        Text(
                          'FedEx Ground',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: responsive.hp(0.5)),
                        Text(
                          'Tracking: TRK${order!.orderId.replaceAll(RegExp(r'[^0-9]'), '')}${order!.id.padLeft(3, '0')}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.textSecondary,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return Icons.receipt_long;
      case OrderStatus.processing:
        return Icons.hourglass_empty;
      case OrderStatus.shipped:
        return Icons.local_shipping;
      case OrderStatus.outForDelivery:
        return Icons.delivery_dining;
      case OrderStatus.delivered:
        return Icons.check_circle;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.canceled:
        return Icons.cancel;
      case OrderStatus.installed:
        return Icons.build;
    }
  }

  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.placed:
        return 'Your order has been placed successfully';
      case OrderStatus.processing:
        return 'Your order is being prepared for shipment';
      case OrderStatus.shipped:
        return 'Your order is on its way';
      case OrderStatus.outForDelivery:
        return 'Your order is out for delivery today';
      case OrderStatus.delivered:
        return 'Your order has been delivered';
      case OrderStatus.completed:
        return 'Your order is complete';
      case OrderStatus.canceled:
        return 'This order was canceled';
      case OrderStatus.installed:
        return 'Installation completed successfully';
    }
  }

  String _getOrderTypeText(OrderType type) {
    switch (type) {
      case OrderType.upgrade:
        return 'Appliance Upgrade';
      case OrderType.part:
        return 'Replacement Part';
    }
  }

  IconData _getProductIcon(OrderType type) {
    switch (type) {
      case OrderType.upgrade:
        return Icons.home_repair_service;
      case OrderType.part:
        return Icons.build_circle;
    }
  }
}

// OrderHelper is now defined in order_models.dart — remove duplicate
// to ensure status colors/labels are consistent across list and detail screens.

class TimelineEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime? timestamp;
  final String status;
  final bool isCompleted;
  final bool isCurrent;

  TimelineEvent({
    required this.id,
    required this.title,
    this.description,
    this.timestamp,
    required this.status,
    required this.isCompleted,
    required this.isCurrent,
  });
}
