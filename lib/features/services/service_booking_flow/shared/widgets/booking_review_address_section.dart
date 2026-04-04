import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import 'booking_review_shadow_field.dart';

/// Delivery address section with edit, change, and address selection sheet.
///
/// Follows the same pattern as the asset tab â†’ SquareTrade AI â†’
/// book technician â†’ order confirmation flow, with saved address
/// selection and inline editing.
class BookingReviewAddressSection extends StatelessWidget {
  final bool isEditing;
  final int selectedAddressIndex;
  final List<Map<String, String>> savedAddresses;
  final TextEditingController streetController;
  final TextEditingController cityController;
  final TextEditingController stateController;
  final TextEditingController zipCodeController;
  final TextEditingController apartmentController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final GlobalKey<FormState> addressFormKey;
  final VoidCallback onStartEditing;
  final ValueChanged<int> onSelectAddress;
  final ValueChanged<int> onSelectAndEditAddress;
  final VoidCallback onAddNewAddress;
  final void Function(Map<String, String>) onSaveAddress;
  final VoidCallback onFieldChanged;

  const BookingReviewAddressSection({
    super.key,
    required this.isEditing,
    required this.selectedAddressIndex,
    required this.savedAddresses,
    required this.streetController,
    required this.cityController,
    required this.stateController,
    required this.zipCodeController,
    required this.apartmentController,
    required this.nameController,
    required this.phoneController,
    required this.addressFormKey,
    required this.onStartEditing,
    required this.onSelectAddress,
    required this.onSelectAndEditAddress,
    required this.onAddNewAddress,
    required this.onSaveAddress,
    required this.onFieldChanged,
  });

  /// Format an address map into a single display string.
  static String formatAddress(Map<String, String> addr) {
    final parts = <String>[];
    if (addr['apartment']?.isNotEmpty == true) parts.add(addr['apartment']!);
    if (addr['street']?.isNotEmpty == true) parts.add(addr['street']!);
    if (addr['city']?.isNotEmpty == true) parts.add(addr['city']!);
    final stateZip = <String>[];
    if (addr['state']?.isNotEmpty == true) stateZip.add(addr['state']!);
    if (addr['zip']?.isNotEmpty == true) stateZip.add(addr['zip']!);
    if (stateZip.isNotEmpty) parts.add(stateZip.join(' '));
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with Edit button (same as technician flow)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: responsive.spacing(36.0),
                  height: responsive.spacing(36.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(responsive.borderRadius(8)),
                  ),
                  child: Icon(
                    Icons.location_on_outlined,
                    color: AppColors.primary,
                    size: responsive.iconSize(18),
                  ),
                ),
                SizedBox(width: responsive.wp(2.5)),
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16.0),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.hp(1.5)),

        if (!isEditing &&
            savedAddresses.isNotEmpty &&
            selectedAddressIndex >= 0) ...[
          _buildSelectedAddressDisplayCard(context, responsive),
        ] else ...[
          _buildAddressEditForm(context, responsive),
        ],
      ],
    );
  }

  Widget _buildSelectedAddressDisplayCard(
      BuildContext context, ResponsiveUtils responsive) {
    final addr = savedAddresses[selectedAddressIndex];
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
            addr['name'] ?? 'Address',
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.hp(1)),
          Text(
            formatAddress(addr),
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (addr['phone']?.isNotEmpty == true) ...[
            SizedBox(height: responsive.hp(1)),
            Row(
              children: [
                Icon(Icons.phone_outlined,
                    size: responsive.iconSize(16),
                    color: AppColors.textSecondary),
                SizedBox(width: responsive.wp(1.5)),
                Text(
                  addr['phone']!,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
          SizedBox(height: responsive.hp(1.5)),
          // Edit + Change buttons (same as BookingAddressStep / technician flow)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onStartEditing,
                  icon: Icon(Icons.edit_outlined,
                      size: responsive.iconSize(16)),
                  label: Text(
                    'Edit',
                    style: TextStyle(fontSize: responsive.fontSize(13)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.3)),
                    padding: responsive.padding(vertical: 10),
                  ),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddressSelectionSheet(context),
                  icon: Icon(Icons.swap_horiz_rounded,
                      size: responsive.iconSize(16)),
                  label: Text(
                    'Change',
                    style: TextStyle(fontSize: responsive.fontSize(13)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.gray300),
                    padding: responsive.padding(vertical: 10),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressEditForm(
      BuildContext context, ResponsiveUtils responsive) {
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
      child: Form(
        key: addressFormKey,
        child: Column(
          children: [
            BookingReviewShadowField(
              controller: streetController,
              label: 'Street Address',
              icon: Icons.location_on_outlined,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Street address is required';
                }
                if (v.trim().length < 5) {
                  return 'Please enter a valid street address';
                }
                return null;
              },
              keyboardType: TextInputType.streetAddress,
              onChanged: (_) => onFieldChanged(),
            ),
            SizedBox(height: responsive.hp(1.5)),
            BookingReviewShadowField(
              controller: apartmentController,
              label: 'Apt / Suite / Floor (Optional)',
              icon: Icons.apartment_outlined,
              validator: (_) => null,
              onChanged: (_) => onFieldChanged(),
            ),
            SizedBox(height: responsive.hp(1.5)),
            BookingReviewShadowField(
              controller: cityController,
              label: 'City',
              icon: Icons.location_city_outlined,
              validator: (v) =>
                  v?.isEmpty ?? true ? 'City is required' : null,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
              ],
              onChanged: (_) => onFieldChanged(),
            ),
            SizedBox(height: responsive.hp(1.5)),
            Row(
              children: [
                Expanded(
                  child: BookingReviewShadowField(
                    controller: stateController,
                    label: 'State',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (v.trim().length != 2) return '2-letter code';
                      return null;
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                      LengthLimitingTextInputFormatter(2),
                      TextInputFormatter.withFunction(
                        (oldValue, newValue) => newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        ),
                      ),
                    ],
                    onChanged: (_) => onFieldChanged(),
                  ),
                ),
                SizedBox(width: responsive.wp(3)),
                Expanded(
                  child: BookingReviewShadowField(
                    controller: zipCodeController,
                    label: 'ZIP Code',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (!RegExp(r'^\d{5}$').hasMatch(v)) return '5 digits';
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    onChanged: (_) => onFieldChanged(),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.hp(1.5)),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  if (addressFormKey.currentState?.validate() == true) {
                    final newAddr = {
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'street': streetController.text.trim(),
                      'city': cityController.text.trim(),
                      'state': stateController.text.trim().toUpperCase(),
                      'zip': zipCodeController.text.trim(),
                      'apartment': apartmentController.text.trim(),
                      'label': 'Home',
                    };
                    onSaveAddress(newAddr);
                  }
                },
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(
                  'Save Address',
                  style: TextStyle(fontSize: responsive.fontSize(14)),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: responsive.padding(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // â”€â”€ Address Selection Bottom Sheet (technician-flow style) â”€â”€

  void _showAddressSelectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        final responsive = ctx.responsive;
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(responsive.borderRadius(20)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowDark,
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: responsive.padding(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: responsive.padding(horizontal: 20, vertical: 8),
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
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close,
                          color: AppColors.gray600, size: 24),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Address list
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: responsive.padding(horizontal: 20, vertical: 12),
                  itemCount: savedAddresses.length,
                  itemBuilder: (_, index) {
                    final addr = savedAddresses[index];
                    final isSelected = index == selectedAddressIndex;
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        onSelectAddress(index);
                      },
                      child: Container(
                        margin: responsive.padding(bottom: 12),
                        padding: responsive.padding(all: 16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12)),
                          border: isSelected
                              ? Border.all(color: AppColors.primary, width: 2)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadowMedium,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
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
                                        addr['name'] ??
                                            addr['label'] ??
                                            'Address',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(15),
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      if (isSelected) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            'Selected',
                                            style: TextStyle(
                                              fontSize:
                                                  responsive.fontSize(11),
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: responsive.hp(0.8)),
                                  Text(
                                    formatAddress(addr),
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      color: AppColors.textSecondary,
                                      height: 1.4,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (addr['phone']?.isNotEmpty == true) ...[
                                    SizedBox(height: responsive.hp(0.8)),
                                    Row(
                                      children: [
                                        Icon(Icons.phone_outlined,
                                            size: responsive.iconSize(14),
                                            color: AppColors.textSecondary),
                                        SizedBox(width: responsive.wp(1)),
                                        Text(
                                          addr['phone']!,
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(13),
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    onSelectAndEditAddress(index);
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
                                  SizedBox(width: responsive.wp(3)),
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
                    );
                  },
                ),
              ),
              // Add New Address button
              Container(
                padding: responsive.padding(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
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
                      Navigator.pop(ctx);
                      onAddNewAddress();
                    },
                    icon: Icon(Icons.add, size: responsive.iconSize(20)),
                    label: Text(
                      'Add New Address',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: responsive.padding(vertical: 14),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
