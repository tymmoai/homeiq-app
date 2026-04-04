import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/core/constants/app_dimensions.dart';
import 'package:homeiq/services/user_service.dart';

import '../../../../utils/responsive_utils.dart';
import '../ai_fix_models.dart';
import 'combined_address_form_screen.dart';

/// NEW: Combined Confirmation Widget - Review all before payment
/// Shows Parts Summary, Technician Summary, and Delivery Address (editable)
class CombinedConfirmationWidget extends StatefulWidget {
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final double partsSubtotal;
  final TechnicianOption technician;
  final String? selectedSlot;
  final String? expectedDelivery;
  final Map<String, String> deliveryAddress;
  final bool agreeTerms;
  final bool isProcessing;
  final ValueChanged<bool?> onAgreeChanged;
  final void Function(String key, String value) onUpdateAddress;
  final VoidCallback onConfirmPayment;

  const CombinedConfirmationWidget({
    super.key,
    required this.parts,
    required this.selectedPartsIndexes,
    required this.partsSubtotal,
    required this.technician,
    required this.selectedSlot,
    required this.expectedDelivery,
    required this.deliveryAddress,
    required this.agreeTerms,
    required this.isProcessing,
    required this.onAgreeChanged,
    required this.onUpdateAddress,
    required this.onConfirmPayment,
  });

  @override
  State<CombinedConfirmationWidget> createState() =>
      _CombinedConfirmationWidgetState();
}

class _CombinedConfirmationWidgetState
    extends State<CombinedConfirmationWidget> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  int _selectedAddressIndex = 0;

  late List<Map<String, String>> _savedAddresses;

  @override
  void initState() {
    super.initState();
    // Initialize saved addresses from the current delivery address + dummy alternatives
    final user = UserService.instance;
    _savedAddresses = [
      {
        'name': widget.deliveryAddress['name'] ?? user.getUserName(),
        'phone': widget.deliveryAddress['phone'] ?? user.getUserPhone(),
        'address': '${widget.deliveryAddress['street'] ?? user.getUserAddress()}, ${widget.deliveryAddress['city'] ?? user.getUserCity()}, ${widget.deliveryAddress['state'] ?? user.getUserState()} ${widget.deliveryAddress['zip'] ?? user.getUserZipCode()}',
      },
      {
        'name': 'Jane Smith',
        'phone': '(555) 987-6543',
        'address': '456 Oak Avenue, Brooklyn, NY 11201',
      },
    ];
  }

  void _showAddressSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.backgroundWarm,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Delivery Address',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.grey.shade600,
                      size: responsive.iconSize(24),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Address List
            Expanded(
              child: StatefulBuilder(
                builder: (context, setSheetState) {
                  return ListView.builder(
                    padding: EdgeInsets.all(responsive.spacing(20)),
                    itemCount: _savedAddresses.length,
                    itemBuilder: (context, index) {
                      final address = _savedAddresses[index];
                      final isSelected = index == _selectedAddressIndex;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAddressIndex = index;
                              _updateDeliveryAddressFromSaved(index);
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                              border: isSelected
                                  ? Border.all(color: AppColors.primary, width: 2)
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            address['name'] ?? '',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(15),
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            SizedBox(width: responsive.spacing(8)),
                                            Container(
                                              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(2)),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                                              ),
                                              child: Text(
                                                'Selected',
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
                                      SizedBox(height: responsive.spacing(8)),
                                      Text(
                                        address['address'] ?? '',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(14),
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: responsive.spacing(8)),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined, size: responsive.iconSize(16), color: Colors.grey.shade600),
                                          SizedBox(width: responsive.spacing(6)),
                                          Text(
                                            address['phone'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(14),
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _navigateToAddressForm(
                                          context,
                                          existingAddress: address,
                                          index: index,
                                        );
                                      },
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: AppColors.primary,
                                        size: responsive.iconSize(20),
                                      ),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    if (isSelected) ...[
                                      SizedBox(width: responsive.spacing(12)),
                                      Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: responsive.iconSize(24),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            // Add New Address Button
            Container(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20), vertical: responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.backgroundWarm,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToAddressForm(context);
                  },
                  icon: Icon(Icons.add, size: responsive.iconSize(20)),
                  label: Text(
                    'Add New Address',
                    style: TextStyle(fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                    elevation: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAddressForm(
    BuildContext context, {
    Map<String, String>? existingAddress,
    int? index,
  }) async {
    final result = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (context) => CombinedAddressFormScreen(existingAddress: existingAddress),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          _savedAddresses[index] = result;
        } else {
          _savedAddresses.add(result);
          _selectedAddressIndex = _savedAddresses.length - 1;
        }
        _updateDeliveryAddressFromSaved(_selectedAddressIndex);
      });
    }
  }

  void _updateDeliveryAddressFromSaved(int index) {
    final address = _savedAddresses[index];
    // Parse the combined address string back to individual fields
    final fullAddress = address['address'] ?? '';
    final addressParts = fullAddress.split(', ');
    final street = addressParts.isNotEmpty ? addressParts[0] : '';
    final city = addressParts.length > 1 ? addressParts[1] : '';
    String state = '';
    String zip = '';
    if (addressParts.length > 2) {
      final stateZip = addressParts[2].split(' ');
      state = stateZip.isNotEmpty ? stateZip[0] : '';
      zip = stateZip.length > 1 ? stateZip[1] : '';
    }
    widget.onUpdateAddress('name', address['name'] ?? '');
    widget.onUpdateAddress('phone', address['phone'] ?? '');
    widget.onUpdateAddress('street', street);
    widget.onUpdateAddress('city', city);
    widget.onUpdateAddress('state', state);
    widget.onUpdateAddress('zip', zip);
  }

  @override
  Widget build(BuildContext context) {
    // Calculate all totals
    const shipping = 9.99;
    final partsTax = widget.partsSubtotal * 0.08;
    final partsTotal = widget.partsSubtotal + shipping + partsTax;
    final techFee = widget.technician.fee;
    final techTax = techFee * 0.08;
    final techTotal = techFee + techTax;
    final grandTotal = partsTotal + techTotal;

    // Parse slot for display
    String visitDate = 'TBD';
    String visitTime = '';
    if (widget.selectedSlot != null) {
      final slotParts = widget.selectedSlot!.split(' at ');
      if (slotParts.length == 2) {
        visitDate = slotParts[0];
        visitTime = slotParts[1];
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm Order',
            style: TextStyle(
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(4)),
          Text(
            'Review your order details before payment',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: responsive.spacing(20)),

          // ========== PARTS ORDER SECTION ==========
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                      padding: EdgeInsets.all(responsive.spacing(6)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: responsive.iconSize(18),
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(10)),
                    Text(
                      'Parts Order',
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(12)),
                Divider(height: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(12)),

                // Parts list
                for (var i = 0; i < widget.parts.length; i++)
                  if (widget.selectedPartsIndexes.contains(i))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.parts[i].name,
                              style: TextStyle(
                                fontSize: responsive.fontSize(13),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Text(
                            '\$${(widget.parts[i].priceEncompass * widget.parts[i].quantity).toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(13),
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                SizedBox(height: responsive.spacing(8)),
                _buildPriceRow('Subtotal', widget.partsSubtotal),
                SizedBox(height: responsive.spacing(4)),
                _buildPriceRow('Shipping', shipping, isSecondary: true),
                SizedBox(height: responsive.spacing(4)),
                _buildPriceRow('Tax (8%)', partsTax, isSecondary: true),
                SizedBox(height: responsive.spacing(8)),
                Divider(height: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(8)),
                _buildPriceRow('Parts Total', partsTotal, isBold: true, isPrimary: true),

                // Expected delivery
                SizedBox(height: responsive.spacing(12)),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(10), vertical: responsive.spacing(8)),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping_outlined, size: responsive.iconSize(16), color: AppColors.primary),
                      SizedBox(width: responsive.spacing(6)),
                      Expanded(
                        child: Text(
                          'Expected Delivery: ${widget.expectedDelivery ?? "TBD"}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(12)),

          // ========== TECHNICIAN BOOKING SECTION ==========
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                      padding: EdgeInsets.all(responsive.spacing(6)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Icon(
                        Icons.build_outlined,
                        size: responsive.iconSize(18),
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(10)),
                    Text(
                      'Technician Booking',
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(12)),
                Divider(height: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(12)),

                // Technician info
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          widget.technician.name.substring(0, 1),
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.spacing(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.technician.name,
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(2)),
                          Row(
                            children: [
                              Icon(Icons.star, size: responsive.iconSize(12), color: AppColors.warningGold),
                              SizedBox(width: responsive.spacing(3)),
                              Text(
                                '${widget.technician.rating} • ${widget.technician.experienceYears} yrs',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(11),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: responsive.spacing(12)),

                // Appointment info
                Container(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(10), vertical: responsive.spacing(8)),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: responsive.iconSize(14), color: Colors.grey.shade600),
                      SizedBox(width: responsive.spacing(6)),
                      Expanded(
                        child: Text(
                          '$visitDate${visitTime.isNotEmpty ? " at $visitTime" : ""}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: responsive.spacing(12)),
                _buildPriceRow('Technician Fee', techFee),
                SizedBox(height: responsive.spacing(4)),
                _buildPriceRow('Service Tax (8%)', techTax, isSecondary: true),
                SizedBox(height: responsive.spacing(8)),
                Divider(height: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(8)),
                _buildPriceRow('Technician Total', techTotal, isBold: true, isPrimary: true),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(12)),

          // ========== DELIVERY ADDRESS SECTION ==========
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
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
                      padding: EdgeInsets.all(responsive.spacing(6)),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        size: responsive.iconSize(18),
                        color: AppColors.primary,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(10)),
                    Expanded(
                      child: Text(
                        'Delivery & Service Address',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showAddressSelectionSheet(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: responsive.spacing(10), vertical: responsive.spacing(4)),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: responsive.iconSize(14),
                              color: AppColors.primary,
                            ),
                            SizedBox(width: responsive.spacing(4)),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(12)),
                Divider(height: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(12)),

                // Display address (tap Edit to open bottom sheet)
                Text(
                  widget.deliveryAddress['name'] ?? '',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  '${widget.deliveryAddress['street'] ?? ''}, ${widget.deliveryAddress['city'] ?? ''}, ${widget.deliveryAddress['state'] ?? ''} ${widget.deliveryAddress['zip'] ?? ''}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Row(
                  children: [
                    Icon(Icons.phone_outlined, size: responsive.iconSize(14), color: Colors.grey.shade600),
                    SizedBox(width: responsive.spacing(4)),
                    Text(
                      widget.deliveryAddress['phone'] ?? '',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(12)),

          // ========== GRAND TOTAL SECTION ==========
          Container(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(10)),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Grand Total',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '\$${grandTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(16)),

          // ========== TERMS CHECKBOX ==========
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 24,
                height: 24,
                child: Checkbox(
                  value: widget.agreeTerms,
                  onChanged: widget.onAgreeChanged,
                  activeColor: AppColors.primary,
                ),
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: GestureDetector(
                  onTap: () => widget.onAgreeChanged(!widget.agreeTerms),
                  child: Text(
                    'I authorize the payment of \$${grandTotal.toStringAsFixed(2)} for parts and technician service.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: responsive.spacing(20)),

          // ========== CONFIRM BUTTON ==========
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: (widget.isProcessing || !widget.agreeTerms)
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: ElevatedButton(
              onPressed: (widget.isProcessing || !widget.agreeTerms)
                  ? null
                  : widget.onConfirmPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: AppColors.textOnPrimary,
                disabledForegroundColor: Colors.grey.shade500,
                elevation: 0,
              ),
              child: widget.isProcessing
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                      ),
                    )
                  : Text(
                      'Pay & Confirm All',
                      style: TextStyle(fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600),
                    ),
            ),
          ),

          SizedBox(height: responsive.spacing(24)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isSecondary = false, bool isBold = false, bool isPrimary = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSecondary ? 12 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.normal,
            color: isPrimary ? AppColors.primary : (isSecondary ? AppColors.textSecondary : AppColors.textPrimary),
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isSecondary ? 12 : 13,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            color: isPrimary ? AppColors.primary : (isSecondary ? AppColors.textSecondary : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}