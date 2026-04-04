// Maintenance Parts Order Confirmation Screen

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/order_service.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/maintenance_models.dart';

class MaintenancePartsOrderConfirmationScreen extends StatefulWidget {
  final Reminder reminder;
  final List<dynamic> parts;
  final List<bool> selectedParts;
  final int subtotal;
  final Map<String, int> providerTotals;
  final Map<String, String> address;
  final String trackingId;
  final String expectedDelivery;

  MaintenancePartsOrderConfirmationScreen({
    super.key,
    required this.reminder,
    required this.parts,
    required this.selectedParts,
    required this.subtotal,
    required this.providerTotals,
    required this.address,
    required this.trackingId,
    required this.expectedDelivery,
  }) {
    AppLogger.debug('MaintenancePartsOrderConfirmationScreen constructor called', tag: 'PartsOrderConfirm');
    // Save order immediately in constructor since initState is not reliable
    _saveOrderSync();
  }
  
  void _saveOrderSync() {
    AppLogger.debug('_saveOrderSync called from constructor', tag: 'PartsOrderConfirm');
    final selectedPartsList = <Map<String, dynamic>>[];
    for (int i = 0; i < parts.length; i++) {
      if (selectedParts[i]) {
        final part = parts[i];
        if (part is Map<String, dynamic>) {
          selectedPartsList.add(part);
        } else {
          // Convert part object to map
          selectedPartsList.add({
            'id': part.toString(),
            'name': 'Part ${i + 1}',
            'provider': 'Provider',
          });
        }
      }
    }
    
    const shipping = 9.99;
    final tax = subtotal * 0.08;
    final total = subtotal + shipping + tax;

    AppLogger.debug('Saving parts order: Tracking ID: $trackingId, Parts count: ${selectedPartsList.length}, Subtotal: $subtotal, Total: $total, Reminder: ${reminder.taskName}', tag: 'PartsOrderConfirm');

    OrderService.savePartsOrder(
      trackingId: trackingId,
      parts: selectedPartsList,
      subtotal: subtotal.toDouble(),
      total: total,
      reminderName: reminder.taskName,
      expectedDelivery: expectedDelivery,
    ).then((_) {
      AppLogger.info('Parts order saved successfully', tag: 'PartsOrderConfirm');
    }).catchError((e) {
      AppLogger.error('Error saving parts order: $e', tag: 'PartsOrderConfirm', error: e);
    });
  }

  @override
  State<MaintenancePartsOrderConfirmationScreen> createState() => _MaintenancePartsOrderConfirmationScreenState();
}

class _MaintenancePartsOrderConfirmationScreenState extends State<MaintenancePartsOrderConfirmationScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  bool _orderSaved = false;
  
  @override
  void initState() {
    AppLogger.debug('ENTER initState - START', tag: 'PartsOrderConfirm');
    try {
      super.initState();
      AppLogger.debug('super.initState() completed', tag: 'PartsOrderConfirm');
      AppLogger.debug('About to call _saveOrder()', tag: 'PartsOrderConfirm');
      _saveOrder();
      AppLogger.debug('_saveOrder() called', tag: 'PartsOrderConfirm');
    } on Object catch (e, stackTrace) {
      AppLogger.error('ERROR in initState: $e', tag: 'PartsOrderConfirm', error: e, stackTrace: stackTrace);
      rethrow;
    }
    AppLogger.debug('EXIT initState - END', tag: 'PartsOrderConfirm');
  }

  @override
  void dispose() {
    AppLogger.debug('MaintenancePartsOrderConfirmationScreen dispose called', tag: 'PartsOrderConfirm');
    super.dispose();
  }

  Future<void> _saveOrder() async {
    if (_orderSaved) {
      AppLogger.warning('Order already saved, skipping', tag: 'PartsOrderConfirm');
      return;
    }
    _orderSaved = true;
    
    final selectedPartsList = widget.parts
        .asMap()
        .entries
        .where((entry) => widget.selectedParts[entry.key])
        .map((e) => e.value as Map<String, dynamic>)
        .toList();
    const shipping = 9.99;
    final tax = widget.subtotal * 0.08;
    final total = widget.subtotal + shipping + tax;

    AppLogger.debug('Saving parts order: Tracking ID: ${widget.trackingId}, Parts count: ${selectedPartsList.length}, Subtotal: ${widget.subtotal}, Total: $total, Reminder: ${widget.reminder.taskName}', tag: 'PartsOrderConfirm');

    await OrderService.savePartsOrder(
      trackingId: widget.trackingId,
      parts: selectedPartsList,
      subtotal: widget.subtotal.toDouble(),
      total: total,
      reminderName: widget.reminder.taskName,
      expectedDelivery: widget.expectedDelivery,
    );
    
    AppLogger.info('Parts order saved successfully', tag: 'PartsOrderConfirm');
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('MaintenancePartsOrderConfirmationScreen build called', tag: 'PartsOrderConfirm');
    
    // Save order on first build if initState didn't run
    if (!_orderSaved) {
      AppLogger.debug('Saving order from build method', tag: 'PartsOrderConfirm');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _saveOrder();
      });
    }
    const shipping = 9.99;
    final tax = widget.subtotal * 0.08;
    final total = widget.subtotal + shipping + tax;
    final selectedPartsList =
        widget.parts.asMap().entries.where((entry) => widget.selectedParts[entry.key]).map((e) => e.value).toList();
    final deliveryDate = DateTime.tryParse(widget.expectedDelivery);
    final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final deliveryLabel = deliveryDate != null
        ? '${monthNames[deliveryDate.month - 1]} ${deliveryDate.day}, ${deliveryDate.year}'
        : widget.expectedDelivery;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray200,
      appBar: AppBar(
        backgroundColor: AppColors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.primary),
            onPressed: () => context.go('/home'),
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundGray200,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsive.spacing(20)),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success Icon and Title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.success,
                    ),
                    child: Icon(Icons.check, color: AppColors.white, size: responsive.iconSize(32)),
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  Text(
                    'Order Placed Successfully',
                    style: TextStyle(
                      fontSize: responsive.fontSize(20),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    'Your order has been confirmed and will be delivered soon.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(24)),
            // Order Summary
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    'Order Summary',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  _buildSummaryRow('Tracking ID', widget.trackingId),
                  _buildSummaryRow('Items', '${selectedPartsList.length} parts'),
                  _buildSummaryRow('Subtotal', '\$${widget.subtotal.toStringAsFixed(2)}'),
                  _buildSummaryRow('Shipping', '\$${shipping.toStringAsFixed(2)}'),
                  _buildSummaryRow('Tax (8%)', '\$${tax.toStringAsFixed(2)}'),
                  const Divider(height: 20),
                  _buildSummaryRow('Total Paid', '\$${total.toStringAsFixed(2)}', isBold: true),
                  _buildSummaryRow('Estimated Delivery', deliveryLabel),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            // Delivery Details
            Container(
              padding: EdgeInsets.all(responsive.spacing(20)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(responsive.spacing(8)),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        ),
                        child: Icon(
                          Icons.location_on_outlined,
                          size: responsive.iconSize(20),
                          color: AppColors.primary,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Text(
                        'Delivery Details',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(20)),
                  // Full Name
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Name:',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.address['fullName'] ?? '',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  // Address
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Address:',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
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
                              widget.address['street'] ?? '',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            Text(
                              '${widget.address['city'] ?? ''}, ${widget.address['state'] ?? ''} ${widget.address['zip'] ?? ''}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(16)),
                  // Phone
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Phone:',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            fontWeight: FontWeight.w500,
                            color: AppColors.gray600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          widget.address['phone'] ?? '',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
            // Items Ordered
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
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
                  Text(
                    'Items Ordered',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  ...selectedPartsList.map((p) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(6)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '${p.name} Ã—${p.quantity}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '\$${(p.priceEncompass * p.quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(24)),
            // View My Orders button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  context.push('/orders');
                },
                icon: Icon(Icons.shopping_bag_outlined, size: responsive.iconSize(20)),
                label: Text(
                  'View My Orders',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(12)),
            // Back to Home button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () {
                  context.go('/home');
                },
                icon: Icon(Icons.home, size: responsive.iconSize(20)),
                label: Text(
                  'Back to Home',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: responsive.spacing(12)),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.spacing(4)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}


