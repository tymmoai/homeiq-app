// Order Success Screen - Final confirmation after checkout

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  final String trackingId;
  final String expectedDelivery;
  final Map<String, dynamic>? product;
  final int? quantity;
  final double? subtotal;
  final double? tradeInTotal;
  final double? tax;
  final double? totalAmount;
  final Map<String, String>? address;
  final String? paymentMethod;
  final Map<String, dynamic>? asset;
  final bool fromUpgradeFlow;

  const CheckoutSuccessScreen({
    super.key,
    required this.trackingId,
    required this.expectedDelivery,
    this.product,
    this.quantity,
    this.subtotal,
    this.tradeInTotal,
    this.tax,
    this.totalAmount,
    this.address,
    this.paymentMethod,
    this.asset,
    this.fromUpgradeFlow = false,
  });

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static const Color _backgroundColor = Colors.white;

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: _headerColor),
            onPressed: () {
              if (widget.fromUpgradeFlow && widget.asset != null) {
                context.push('/upgrade-offer', extra: widget.asset);
              } else {
                context.go('/home');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: responsive.padding(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    responsive.heightBox(16.0),
                    // Success Icon
                    Icon(
                      Icons.check_circle,
                      size: responsive.iconSize(80.0),
                      color: AppColors.success,
                    ),
                    responsive.heightBox(16.0),

                    // Success Title
                    Text(
                      'Order Placed Successfully!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive.fontSize(24.0),
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    responsive.heightBox(12.0),

                    // Success Message
                    Text(
                      'Your order has been confirmed and will be delivered soon.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: responsive.fontSize(15.0),
                        color: _textSecondary,
                        height: 1.5,
                      ),
                    ),
                    responsive.heightBox(24.0),

                    // Order Details Card (Merged Shipping & widget.product)
                    _buildInfoCard(
                      responsive,
                      icon: Icons.receipt_long_outlined,
                      title: 'Order Details',
                      children: [
                        // widget.product Information
                        if (widget.product != null) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.devices_outlined,
                                size: responsive.iconSize(20.0),
                                color: _headerColor,
                              ),
                              responsive.widthBox(8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.product!['name'] ?? 'Product',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(15.0),
                                        fontWeight: FontWeight.w600,
                                        color: _textPrimary,
                                      ),
                                    ),
                                    responsive.heightBox(6.0),
                                    // Brand and widget.quantity in one row
                                    Row(
                                      children: [
                                        Text(
                                          '${widget.product!['brand'] ?? ''} ${widget.product!['model'] ?? ''}'
                                              .trim(),
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(13.0),
                                            color: _textSecondary,
                                          ),
                                        ),
                                        Text(
                                          ' â€¢ ',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(13.0),
                                            color: _textSecondary,
                                          ),
                                        ),
                                        Text(
                                          'Qty: ${widget.quantity ?? 1}',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(13.0),
                                            fontWeight: FontWeight.w600,
                                            color: _textPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          responsive.heightBox(12.0),
                          Divider(height: 1, color: AppColors.gray200),
                          responsive.heightBox(12.0),
                        ],
                        // Shipping Information
                        _buildInfoRow(responsive, 'Tracking ID', widget.trackingId),
                        responsive.heightBox(8.0),
                        _buildInfoRow(
                          responsive,
                          'Expected Delivery',
                          deliveryLabel,
                        ),
                      ],
                    ),

                    // Delivery widget.address Card (moved before payment for logical flow)
                    if (widget.address != null && widget.address!.isNotEmpty) ...[
                      responsive.heightBox(16.0),
                      _buildInfoCard(
                        responsive,
                        icon: Icons.location_on_outlined,
                        title: 'Delivery Address',
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: responsive.iconSize(18.0),
                                color: _headerColor,
                              ),
                              responsive.widthBox(8.0),
                              Text(
                                widget.address!['fullName'] ?? 'N/A',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14.0),
                                  fontWeight: FontWeight.w600,
                                  color: _textPrimary,
                                ),
                              ),
                            ],
                          ),
                          responsive.heightBox(8.0),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.home_outlined,
                                size: responsive.iconSize(18.0),
                                color: _headerColor,
                              ),
                              responsive.widthBox(8.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.address!['street'] ?? '',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        color: _textSecondary,
                                      ),
                                    ),
                                    if ((widget.address!['city'] ?? '')
                                        .isNotEmpty) ...[
                                      responsive.heightBox(2.0),
                                      Text(
                                        '${widget.address!['city']}, ${widget.address!['state']} ${widget.address!['zip']}'
                                            .trim(),
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(13.0),
                                          color: _textSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                          responsive.heightBox(8.0),
                          Row(
                            children: [
                              Icon(
                                Icons.phone_outlined,
                                size: responsive.iconSize(18.0),
                                color: _headerColor,
                              ),
                              responsive.widthBox(8.0),
                              Text(
                                widget.address!['phone'] ?? '',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],

                    // Payment & Pricing Card (moved to end for logical flow)
                    if (widget.totalAmount != null) ...[
                      responsive.heightBox(16.0),
                      _buildInfoCard(
                        responsive,
                        icon: Icons.account_balance_wallet_outlined,
                        title: 'Payment & Pricing',
                        children: [
                          // Payment Method
                          if (widget.paymentMethod != null) ...[
                            Row(
                              children: [
                                Icon(
                                  _getPaymentIcon(widget.paymentMethod!),
                                  size: responsive.iconSize(18.0),
                                  color: _headerColor,
                                ),
                                responsive.widthBox(8.0),
                                Text(
                                  _getPaymentMethodLabel(widget.paymentMethod!),
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14.0),
                                    fontWeight: FontWeight.w600,
                                    color: _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            responsive.heightBox(12.0),
                            const Divider(height: 1),
                            responsive.heightBox(12.0),
                          ],
                          // Price Breakdown
                          if (widget.subtotal != null)
                            _buildInfoRow(
                              responsive,
                              'Product Price',
                              '\$${widget.subtotal!.toStringAsFixed(2)}',
                            ),
                          if (widget.tradeInTotal != null && widget.tradeInTotal! > 0) ...[
                            responsive.heightBox(8.0),
                            _buildInfoRow(
                              responsive,
                              'Trade-in Credit',
                              '-\$${widget.tradeInTotal!.toStringAsFixed(2)}',
                              valueColor: AppColors.successMaterialDark,
                            ),
                          ],
                          if (widget.tax != null) ...[
                            responsive.heightBox(8.0),
                            _buildInfoRow(
                              responsive,
                              'Tax (8%)',
                              '\$${widget.tax!.toStringAsFixed(2)}',
                            ),
                          ],
                          responsive.heightBox(12.0),
                          const Divider(height: 1),
                          responsive.heightBox(12.0),
                          _buildInfoRow(
                            responsive,
                            'Total Amount',
                            '\$${widget.totalAmount!.toStringAsFixed(2)}',
                            isBold: true,
                          ),
                        ],
                      ),
                    ],

                    responsive.heightBox(24.0),
                  ],
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: responsive.padding(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: responsive.buttonHeight(52.0),
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/orders'),
                      icon: Icon(
                        Icons.shopping_bag_outlined,
                        size: responsive.iconSize(20.0),
                      ),
                      label: Text(
                        'View My Orders',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16.0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                    ),
                  ),
                  responsive.heightBox(12.0),
                  SizedBox(
                    width: double.infinity,
                    height: responsive.buttonHeight(52.0),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        if (widget.asset != null) {
                          context.push('/asset-detail', extra: widget.asset);
                        } else {
                          context.go('/home');
                        }
                      },
                      icon: Icon(
                        Icons.arrow_back_outlined,
                        size: responsive.iconSize(20.0),
                      ),
                      label: Text(
                        'Back to Assets',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16.0),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _headerColor,
                        side: BorderSide(color: _headerColor),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    ResponsiveUtils responsive, {
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: responsive.spacing(12.0),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Title with faded background
          Container(
            padding: responsive.padding(all: 16),
            decoration: BoxDecoration(
              color: _headerColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(responsive.borderRadius(12.0)),
                topRight: Radius.circular(responsive.borderRadius(12.0)),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: responsive.iconSize(22.0),
                  color: _headerColor,
                ),
                responsive.widthBox(10.0),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16.0),
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
              ],
            ),
          ),
          // Card Content
          Padding(
            padding: responsive.padding(all: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    ResponsiveUtils responsive,
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: _textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(14.0),
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? _textPrimary,
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String method) {
    switch (method.toLowerCase()) {
      case 'apple_pay':
        return Icons.apple;
      case 'google_pay':
        return Icons.payment;
      case 'credit_card':
        return Icons.credit_card;
      case 'installment':
        return Icons.calendar_month_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'apple_pay':
        return 'Apple Pay';
      case 'google_pay':
        return 'Google Pay';
      case 'credit_card':
        return 'Credit Card';
      case 'installment':
        return 'Monthly Installments';
      default:
        return 'Card Payment';
    }
  }
}
