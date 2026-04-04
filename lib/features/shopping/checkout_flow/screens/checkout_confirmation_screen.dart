// Checkout Order Confirmation Screen for Asset Upgrade Flow

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../services/order_service.dart';
import '../../../../utils/responsive_utils.dart';

class CheckoutConfirmationScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int tradeInValuePerItem;
  final double subtotal;
  final double tradeInTotal;
  final double tax;
  final double totalAmount;
  final Map<String, String> address;
  final String trackingId;
  final String expectedDelivery;
  final bool fromUpgradeFlow;
  final Map<String, dynamic>? asset;

  const CheckoutConfirmationScreen({
    super.key,
    required this.items,
    required this.tradeInValuePerItem,
    required this.subtotal,
    required this.tradeInTotal,
    required this.tax,
    required this.totalAmount,
    required this.address,
    required this.trackingId,
    required this.expectedDelivery,
    this.fromUpgradeFlow = false,
    this.asset,
  });

  @override
  State<CheckoutConfirmationScreen> createState() =>
      _CheckoutConfirmationScreenState();
}

class _CheckoutConfirmationScreenState
    extends State<CheckoutConfirmationScreen> {
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.background;

  @override
  void initState() {
    super.initState();
    _saveOrderToHistory();
  }

  Future<void> _saveOrderToHistory() async {
    // Items come as [{'product': {...}, 'quantity': n}] from the router
    final product = widget.items.isNotEmpty
        ? widget.items[0]['product'] as Map<String, dynamic>?
        : null;

    await OrderService.saveUpgradeOrder(
      trackingId: widget.trackingId,
      productName: product?['name'] as String? ?? 'Unknown Product',
      productBrand: product?['brand'] as String? ?? 'Unknown',
      productModel: product?['model'] as String? ?? 'N/A',
      productId: product?['id'] as String? ?? 'N/A',
      totalAmount: widget.totalAmount,
      subtotal: widget.subtotal,
      tax: widget.tax,
      tradeInTotal: widget.tradeInTotal,
      itemCount: widget.items.length,
      expectedDelivery: widget.expectedDelivery,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final deliveryDate = DateTime.tryParse(widget.expectedDelivery);
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final deliveryLabel = deliveryDate != null
        ? '${monthNames[deliveryDate.month - 1]} ${deliveryDate.day}, ${deliveryDate.year}'
        : widget.expectedDelivery;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: const Text(
          'Order Confirmation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(responsive.spacing(20.0)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  Container(
                    padding: responsive.padding(all: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: responsive.spacing(10.0),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16.0),
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        responsive.heightBox(12.0),
                        _buildSummaryRow('Tracking ID', widget.trackingId),
                        _buildSummaryRow(
                          'Items',
                          '${widget.items.length} item${widget.items.length > 1 ? 's' : ''}',
                        ),
                        _buildSummaryRow(
                          'Subtotal',
                          '\$${widget.subtotal.toStringAsFixed(2)}',
                        ),
                        if (widget.tradeInTotal > 0)
                          _buildSummaryRow(
                            'Trade-in Credit',
                            '-\$${widget.tradeInTotal.toStringAsFixed(2)}',
                          ),
                        _buildSummaryRow(
                          'Tax (8%)',
                          '\$${widget.tax.toStringAsFixed(2)}',
                        ),
                        const Divider(height: 20),
                        _buildSummaryRow(
                          'Total Paid',
                          '\$${widget.totalAmount.toStringAsFixed(2)}',
                          isBold: true,
                        ),
                        _buildSummaryRow('Estimated Delivery', deliveryLabel),
                      ],
                    ),
                  ),
                  responsive.heightBox(16.0),
                  // Delivery Details
                  Container(
                    padding: responsive.padding(all: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: responsive.spacing(10.0),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: responsive.padding(all: 8),
                              decoration: BoxDecoration(
                                color: _headerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  responsive.borderRadius(8.0),
                                ),
                              ),
                              child: Icon(
                                Icons.location_on_outlined,
                                size: responsive.iconSize(20.0),
                                color: _headerColor,
                              ),
                            ),
                            responsive.widthBox(12.0),
                            Text(
                              'Delivery Details',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16.0),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        responsive.heightBox(20.0),
                        // Full Name
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: responsive.spacing(100.0),
                              child: Text(
                                'Name:',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.address['fullName'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        responsive.heightBox(16.0),
                        // Address
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: responsive.spacing(100.0),
                              child: Text(
                                'Address:',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.address['street'] ?? 'N/A',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      color: _textPrimary,
                                    ),
                                  ),
                                  if ((widget.address['city'] ?? '')
                                          .isNotEmpty ||
                                      (widget.address['state'] ?? '')
                                          .isNotEmpty ||
                                      (widget.address['zip'] ?? '')
                                          .isNotEmpty) ...[
                                    responsive.heightBox(4.0),
                                    Text(
                                      '${widget.address['city'] ?? ''}, ${widget.address['state'] ?? ''} ${widget.address['zip'] ?? ''}'
                                          .trim(),
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(14.0),
                                        color: _textPrimary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                        responsive.heightBox(16.0),
                        // Phone
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: responsive.spacing(100.0),
                              child: Text(
                                'Phone:',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.address['phone'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  responsive.heightBox(16.0),
                  // Items Ordered
                  Container(
                    padding: responsive.padding(all: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(16.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: responsive.spacing(10.0),
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Items Ordered',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16.0),
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        responsive.heightBox(12.0),
                        ...widget.items.map((item) {
                          final product =
                              item['product'] as Map<String, dynamic>;
                          final quantity = item['quantity'] as int;
                          final price = product['discountPrice'] as int;
                          return Padding(
                            padding: responsive.padding(vertical: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${product['name']} Ã— $quantity',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${(price * quantity).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14.0),
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  responsive.heightBox(24.0),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Container(
              padding: responsive.padding(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.transparent,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: responsive.buttonHeight(52.0),
                child: ElevatedButton(
                  onPressed: () {
                    // Get product from items list
                    final product =
                        widget.items.isNotEmpty &&
                            widget.items[0]['product'] != null
                        ? widget.items[0]['product'] as Map<String, dynamic>
                        : null;
                    final quantity =
                        widget.items.isNotEmpty &&
                            widget.items[0]['quantity'] != null
                        ? widget.items[0]['quantity'] as int
                        : 1;

                    context.push(
                      '/checkout-success',
                      extra: {
                        'trackingId': widget.trackingId,
                        'expectedDelivery': widget.expectedDelivery,
                        'product': product,
                        'quantity': quantity,
                        'subtotal': widget.subtotal,
                        'tradeInTotal': widget.tradeInTotal,
                        'tax': widget.tax,
                        'totalAmount': widget.totalAmount,
                        'address': widget.address,
                        'paymentMethod':
                            'card', // You can enhance this to track actual payment method
                        'fromUpgradeFlow': widget.fromUpgradeFlow,
                        'asset': widget.asset,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _headerColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    final responsive = context.responsive;
    return Padding(
      padding: responsive.padding(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: _textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
