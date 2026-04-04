import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/utils/logger.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../../services/booking_service.dart';
import '../models/service_booking_form_data.dart';
import 'booking_step_header.dart';

/// Shared confirmation/success step for all service booking flows.
///
/// Shows a success animation, booking ID, booking details, items summary,
/// price summary and a "Back to Services" button. Persists the booking via
/// [BookingService].
class BookingConfirmationStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final String serviceName;
  final String bookingIdPrefix;
  final List<ServiceItem> availableItems;
  final List<ServiceAddon> availableAddons;
  final double serviceFee;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onClose;

  const BookingConfirmationStep({
    super.key,
    required this.formData,
    required this.serviceName,
    required this.bookingIdPrefix,
    required this.availableItems,
    this.availableAddons = const [],
    this.serviceFee = 29.0,
    required this.currentStep,
    required this.totalSteps,
    required this.onClose,
  });

  @override
  State<BookingConfirmationStep> createState() =>
      _BookingConfirmationStepState();
}

class _BookingConfirmationStepState extends State<BookingConfirmationStep>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _bookingSaved = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );
    _controller.forward();
    _saveBooking();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBooking() async {
    if (_bookingSaved) return;
    try {
      await BookingService.saveBooking(
        serviceType: widget.formData.selectedService ?? '',
        serviceName: widget.serviceName,
        selectedItems: widget.formData.selectedItems,
        scheduledDate: widget.formData.selectedDate ?? DateTime.now(),
        scheduledTime: widget.formData.selectedTimeSlot ?? '',
        contactName: widget.formData.customerName ?? '',
        contactEmail: widget.formData.customerEmail ?? '',
        contactPhone: widget.formData.customerPhone ?? '',
        address: widget.formData.serviceAddress ?? '',
        city: widget.formData.serviceCity ?? '',
        state: widget.formData.serviceState ?? '',
        zipCode: widget.formData.serviceZipCode ?? '',
        itemsTotal: _itemsTotal,
        serviceFee: widget.serviceFee,
        total: _total,
        specialInstructions: widget.formData.specialRequirements,
      );
      _bookingSaved = true;
    } on Object catch (e) {
      AppLogger.error('Error saving booking: $e', tag: 'BookingConfirmation', error: e);
    }
  }

  List<Map<String, dynamic>> get _selectedItemsList {
    final List<Map<String, dynamic>> result = [];
    widget.formData.selectedItems.forEach((itemName, quantity) {
      for (var item in widget.availableItems) {
        if (item.name == itemName) {
          result.add({
            'name': itemName,
            'quantity': quantity,
            'price': item.price,
            'total': item.price * quantity,
          });
          break;
        }
      }
    });
    return result;
  }

  double get _itemsTotal {
    double total = 0;
    for (var item in _selectedItemsList) {
      total += (item['total'] as num).toDouble();
    }
    return total;
  }

  double get _addonsTotal =>
      widget.formData.calculateAddonsTotal(widget.availableAddons);

  double get _total => _itemsTotal + _addonsTotal + widget.serviceFee;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: () {}, // no back from confirmation
          onClose: widget.onClose,
          showBack: false,
        ),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: context.responsive.padding(horizontal: 20, vertical: 0),
              child: Column(
                children: [
                  context.responsive.heightBox(24.0),
                  _buildSuccessIcon(),
                  context.responsive.heightBox(20.0),
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        Text(
                          'Booking Confirmed!',
                          style: TextStyle(
                            fontSize: context.responsive.fontSize(24.0),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        context.responsive.heightBox(8.0),
                        Text(
                          'Your ${widget.serviceName.toLowerCase()} service has been booked successfully.',
                          style: TextStyle(
                            fontSize: context.responsive.fontSize(14.0),
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        context.responsive.heightBox(24.0),
                        _buildBookingIdCard(),
                        context.responsive.heightBox(16.0),
                        _buildBookingDetailsCard(),
                        context.responsive.heightBox(16.0),
                        _buildItemsSummaryCard(),
                        if (widget.formData.selectedAddons.isNotEmpty) ...[
                          context.responsive.heightBox(16.0),
                          _buildAddonsSummaryCard(),
                        ],
                        context.responsive.heightBox(16.0),
                        _buildPriceSummaryCard(),
                        context.responsive.heightBox(24.0),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBackToServicesButton(),
      ],
    );
  }

  Widget _buildSuccessIcon() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: context.responsive.spacing(80.0),
        height: context.responsive.spacing(80.0),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: context.responsive.iconSize(50.0),
        ),
      ),
    );
  }

  Widget _buildBookingIdCard() {
    return Container(
      width: double.infinity,
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(16.0)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(
            'Booking ID',
            style: TextStyle(
              fontSize: context.responsive.fontSize(14.0),
              color: AppColors.textQuaternary,
            ),
          ),
          context.responsive.heightBox(8.0),
          Text(
            widget.formData.bookingId ?? 'N/A',
            style: TextStyle(
              fontSize: context.responsive.fontSize(22.0),
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(16.0)),
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
          Row(
            children: [
              Container(
                width: context.responsive.spacing(40.0),
                height: context.responsive.spacing(40.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.responsive.borderRadius(10.0)),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Booking Details',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(16.0),
          _buildDetailRow('Service', widget.formData.selectedService ?? ''),
          _buildDetailRow(
              'Date',
              widget.formData.selectedDate != null
                  ? DateFormat('EEEE, MMMM d, yyyy')
                      .format(widget.formData.selectedDate!)
                  : ''),
          _buildDetailRow(
              'Time Slot', widget.formData.selectedTimeSlot ?? '', isLast: true),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Column(
      children: [
        Padding(
          padding: context.responsive.padding(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: context.responsive.fontSize(14.0),
                  color: AppColors.textQuaternary,
                ),
              ),
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(14.0),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        if (!isLast)
          Divider(height: 1, color: AppColors.gray200),
      ],
    );
  }

  Widget _buildItemsSummaryCard() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(16.0)),
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
          Row(
            children: [
              Container(
                width: context.responsive.spacing(40.0),
                height: context.responsive.spacing(40.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.responsive.borderRadius(10.0)),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Items Summary',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(16.0),
          ...List.generate(_selectedItemsList.length, (index) {
            final item = _selectedItemsList[index];
            final isLast = index == _selectedItemsList.length - 1;
            return Column(
              children: [
                Padding(
                  padding: context.responsive.padding(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: context.responsive.fontSize(14.0),
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      Text(
                        'x${item['quantity']}',
                        style: TextStyle(
                          fontSize: context.responsive.fontSize(13.0),
                          color: AppColors.textQuaternary,
                        ),
                      ),
                      context.responsive.widthBox(16.0),
                      Text(
                        '\$${(item['total'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.responsive.fontSize(14.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast) Divider(height: 1, color: AppColors.backgroundGray100),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAddonsSummaryCard() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(16.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
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
                width: context.responsive.spacing(40.0),
                height: context.responsive.spacing(40.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(context.responsive.borderRadius(10.0)),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Add-ons',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(16.0),
          ...widget.formData.selectedAddons.map((addonName) {
            final addon = widget.availableAddons.firstWhere(
              (a) => a.name == addonName,
              orElse: () => ServiceAddon(name: addonName, price: 0, icon: Icons.add),
            );
            return Padding(
              padding: context.responsive.padding(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    addon.name,
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      color: AppColors.textTertiary,
                    ),
                  ),
                  Text(
                    '+\$${addon.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(context.responsive.borderRadius(16.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildPriceRow('Subtotal', '\$${_itemsTotal.toStringAsFixed(0)}'),
          if (_addonsTotal > 0) ...[
            context.responsive.heightBox(10.0),
            _buildPriceRow('Add-ons', '\$${_addonsTotal.toStringAsFixed(0)}'),
          ],
          context.responsive.heightBox(10.0),
          _buildPriceRow('Service Fee', '\$${widget.serviceFee.toStringAsFixed(0)}'),
          Padding(
            padding: context.responsive.padding(vertical: 12),
            child: Divider(height: 1, color: Colors.white.withValues(alpha: 0.2)),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(18.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                '\$${_total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(24.0),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: context.responsive.fontSize(14.0),
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: context.responsive.fontSize(14.0),
            fontWeight: FontWeight.w500,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToServicesButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: Colors.white),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: widget.onClose,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            elevation: 2,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
          child: const Text(
            'Back to Services',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
