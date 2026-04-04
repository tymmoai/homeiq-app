import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../services/user_service.dart';
import '../../../utils/responsive_utils.dart';
import 'address_form_screen.dart';
import 'ai_fix_models.dart';

class TechnicianConfirmationWidget extends StatefulWidget {
  final TechnicianOption? selectedTechnician;
  final String? selectedSlot;
  final Map<String, String> deliveryAddress;
  final void Function(String field, String value) onUpdateAddressField;
  final VoidCallback onContinuePayment;

  const TechnicianConfirmationWidget({
    super.key,
    required this.selectedTechnician,
    required this.selectedSlot,
    required this.deliveryAddress,
    required this.onUpdateAddressField,
    required this.onContinuePayment,
  });

  @override
  State<TechnicianConfirmationWidget> createState() =>
      _TechnicianConfirmationWidgetState();
}

class _TechnicianConfirmationWidgetState
    extends State<TechnicianConfirmationWidget> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  late List<Map<String, String>> _savedAddresses;
  int _selectedAddressIndex = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with current delivery address + dummy alternatives
    final user = UserService.instance;
    _savedAddresses = [
      {
        'name': widget.deliveryAddress['name'] ?? user.getUserName(),
        'phone': widget.deliveryAddress['phone'] ?? user.getUserPhone(),
        'address':
            '${widget.deliveryAddress['street'] ?? user.getUserAddress()}, ${widget.deliveryAddress['city'] ?? user.getUserCity()}, ${widget.deliveryAddress['state'] ?? user.getUserState()} ${widget.deliveryAddress['zip'] ?? user.getUserZipCode()}',
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
      backgroundColor: AppColors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.overlayLight,
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray300,
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
                    'Select Service Address',
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
                      color: AppColors.gray600,
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
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowMedium,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 2,
                                              ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(AppDimensions.radiusBadge),
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
                                          color: AppColors.gray600,
                                          height: 1.4,
                                        ),
                                      ),
                                      SizedBox(height: responsive.spacing(8)),
                                      Row(
                                        children: [
                                          Icon(Icons.phone_outlined,
                                              size: responsive.iconSize(16),
                                              color: AppColors.gray600),
                                          SizedBox(width: responsive.spacing(6)),
                                          Text(
                                            address['phone'] ?? 'N/A',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(14),
                                              color: AppColors.gray600,
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
                                        // Navigate to edit address form
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
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
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
        builder: (context) => AddressFormScreen(
          existingAddress: existingAddress,
          isEdit: existingAddress != null,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (index != null) {
          // Edit existing address
          _savedAddresses[index] = result;
        } else {
          // Add new address
          _savedAddresses.add(result);
          _selectedAddressIndex = _savedAddresses.length - 1;
        }
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    final tech = widget.selectedTechnician;
    if (tech == null) {
      return const SizedBox.shrink();
    }

    String visitDate = 'TBD';
    String visitTime = '';
    if (widget.selectedSlot != null) {
      final parts = widget.selectedSlot!.split(' at ');
      if (parts.length == 2) {
        visitDate = parts[0];
        visitTime = parts[1];
      }
    }

    final selectedAddress = _savedAddresses[_selectedAddressIndex];

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Booking Summary',
            style: TextStyle(
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(20)),
          // Technician Details Box
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
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
                Text(
                  'TECHNICIAN DETAILS',
                  style: TextStyle(
                    fontSize: responsive.fontSize(11),
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tech.name,
                            style: TextStyle(
                              fontSize: responsive.fontSize(16),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(4)),
                          Row(
                            children: [
                              Icon(Icons.star, size: responsive.iconSize(16), color: AppColors.warningGold),
                              SizedBox(width: responsive.spacing(4)),
                              Text(
                                tech.rating.toStringAsFixed(1),
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(width: responsive.spacing(12)),
                              Text(
                                '${tech.experienceYears} yrs',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13),
                                  color: AppColors.gray600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Text(
                        '\$${tech.fee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.w700,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(20)),
          // Date & Time Box
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
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
                Text(
                  'VISIT SCHEDULE',
                  style: TextStyle(
                    fontSize: responsive.fontSize(11),
                    fontWeight: FontWeight.w500,
                    color: AppColors.gray600,
                    letterSpacing: 0.5,
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(6)),
                          Text(
                            visitDate,
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Time Slot',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              fontWeight: FontWeight.w500,
                              color: AppColors.gray600,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(6)),
                          Text(
                            visitTime.isNotEmpty ? visitTime : 'TBD',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(20)),
          // Service Address Section (Like Checkout Flow)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service Address',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton.icon(
                onPressed: () => _showAddressSelectionSheet(context),
                icon: Icon(
                  Icons.edit_outlined,
                  size: responsive.iconSize(16),
                  color: AppColors.primary,
                ),
                label: Text(
                  'Edit address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(4)),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          // Address Display Card
          Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowMedium,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedAddress['name'] ?? '',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  selectedAddress['address'] ?? '',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Row(
                  children: [
                    Icon(Icons.phone_outlined,
                        size: responsive.iconSize(16), color: AppColors.gray600),
                    SizedBox(width: responsive.spacing(6)),
                    Text(
                      selectedAddress['phone'] ?? 'N/A',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: responsive.spacing(80)), // Bottom spacing for floating button
        ],
      ),
    );
  }
}