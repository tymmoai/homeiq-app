import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../../../profile/payment_methods/screens/payment_screen.dart'
    as payment;
import '../../../../profile/payment_methods/services/payment_service.dart';
import '../../../../profile/payment_methods/widgets/unified_payment_content.dart';
import '../models/service_booking_form_data.dart';
import 'booking_step_header.dart';

/// Payment step for service booking flows.
///
/// Opens the SAME payment screen used in the book technician flow
/// via [payment.PaymentScreen.show()].
/// After successful payment, auto-advances to next step (confirmation).
class BookingPaymentStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final String categoryName;
  final List<ServiceItem> availableItems;
  final List<ServiceAddon> availableAddons;
  final double serviceFee;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const BookingPaymentStep({
    super.key,
    required this.formData,
    required this.categoryName,
    this.availableItems = const [],
    this.availableAddons = const [],
    this.serviceFee = 0,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<BookingPaymentStep> createState() => _BookingPaymentStepState();
}

class _BookingPaymentStepState extends State<BookingPaymentStep> {
  bool _paymentComplete = false;
  PaymentResult? _paymentResult;

  double get _itemsTotal =>
      widget.formData.calculateItemsTotal(widget.availableItems);

  double get _addonsTotal =>
      widget.formData.calculateAddonsTotal(widget.availableAddons);

  double get _total => _itemsTotal + _addonsTotal + widget.serviceFee;

  List<OrderSummaryItem> get _orderSummaryItems {
    final items = <OrderSummaryItem>[];

    // Add individual items
    widget.formData.selectedItems.forEach((name, qty) {
      final item = widget.availableItems.firstWhere(
        (i) => i.name == name,
        orElse: () => const ServiceItem(name: '', price: 0, icon: Icons.error),
      );
      if (item.name.isNotEmpty) {
        items.add(OrderSummaryItem(
          label: '$name x$qty',
          amount: item.price * qty,
        ));
      }
    });

    // Add add-ons
    for (final addonName in widget.formData.selectedAddons) {
      final addon = widget.availableAddons.firstWhere(
        (a) => a.name == addonName,
        orElse: () => const ServiceAddon(name: '', price: 0, icon: Icons.error),
      );
      if (addon.name.isNotEmpty) {
        items.add(OrderSummaryItem(label: addonName, amount: addon.price));
      }
    }

    // Add service fee
    if (widget.serviceFee > 0) {
      items.add(OrderSummaryItem(label: 'Service Fee', amount: widget.serviceFee));
    }

    if (items.isEmpty) {
      items.add(OrderSummaryItem(label: widget.categoryName, amount: _total));
    }

    return items;
  }

  Future<void> _openPaymentScreen() async {
    final result = await payment.PaymentScreen.show(
      context: context,
      amount: _total,
      serviceName: widget.categoryName,
      bookingId: widget.formData.bookingId,
      orderSummaryItems: _orderSummaryItems,
    );

    if (result != null && mounted) {
      setState(() {
        _paymentComplete = true;
        _paymentResult = result;
      });
      // Auto-advance after payment success
      widget.onNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: responsive.padding(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                responsive.heightBox(8),
                Text(
                  'Payment',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'Complete your payment to confirm the booking',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(24),

                // Order summary card
                _buildOrderSummaryCard(responsive),
                responsive.heightBox(20),

                // Payment status or Pay button
                if (_paymentComplete)
                  _buildPaymentSuccessCard(responsive)
                else
                  _buildPayButton(responsive),

                responsive.heightBox(20),

                // Cancellation policy
                _buildCancellationPolicy(responsive),
                responsive.heightBox(40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryCard(ResponsiveUtils responsive) {
    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
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
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(1.5)),
          ..._orderSummaryItems.map((item) => Padding(
                padding: responsive.padding(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '\$${item.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              )),
          Divider(height: responsive.hp(2), color: AppColors.gray200),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton(ResponsiveUtils responsive) {
    return SizedBox(
      width: double.infinity,
      height: responsive.buttonHeight(52),
      child: ElevatedButton.icon(
        onPressed: _openPaymentScreen,
        icon: Icon(Icons.payment_rounded, size: responsive.iconSize(20)),
        label: Text(
          'Proceed to Pay  \$${_total.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: responsive.fontSize(16),
            fontWeight: FontWeight.w700,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          elevation: 2,
          shadowColor: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildPaymentSuccessCard(ResponsiveUtils responsive) {
    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: responsive.iconSize(24)),
          SizedBox(width: responsive.wp(3)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Successful',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.successMaterialDark,
                  ),
                ),
                if (_paymentResult?.transactionId != null)
                  Text(
                    'Transaction ID: ${_paymentResult!.transactionId}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.successMaterialAccent,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancellationPolicy(ResponsiveUtils responsive) {
    return Container(
      padding: responsive.padding(all: 14),
      decoration: BoxDecoration(
        color: AppColors.warningYellowBg,
        borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.warningAmberDark,
            size: responsive.iconSize(18),
          ),
          SizedBox(width: responsive.wp(2)),
          Expanded(
            child: Text(
              'Free cancellation up to 24 hours before your scheduled service. A cancellation fee may apply for late cancellations.',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                color: AppColors.warningBrownDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
