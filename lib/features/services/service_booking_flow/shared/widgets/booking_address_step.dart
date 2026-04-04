import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../services/user_service.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_step_header.dart';

/// Address confirmation step for service booking flows.
///
/// Reuses the same address patterns from the technician booking flow:
/// - Shows saved addresses from [UserService]
/// - Edit address inline or via bottom sheet
/// - Add new address option
/// - Shadow card styling, no borders (app theme)
class BookingAddressStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const BookingAddressStep({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<BookingAddressStep> createState() => _BookingAddressStepState();
}

class _BookingAddressStepState extends State<BookingAddressStep> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;
  late TextEditingController _apartmentController;

  int _selectedAddressIndex = 0;
  bool _isEditingAddress = false;

  // Saved addresses list
  List<Map<String, String>> _savedAddresses = [];

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
    _initControllers();
  }

  void _loadSavedAddresses() {
    final user = UserService.instance;
    // Build saved addresses from user service & form data
    _savedAddresses = [];

    final userAddress = user.getUserAddress();
    final userName = user.getUserName();
    final userPhone = user.getUserPhone();
    final userCity = user.getUserCity();
    final userState = user.getUserState();
    final userZip = user.getUserZipCode();

    // Add user's default address if available
    if (userAddress.isNotEmpty) {
      _savedAddresses.add({
        'name': userName.isNotEmpty ? userName : 'Home',
        'phone': userPhone,
        'street': userAddress,
        'city': userCity,
        'state': userState,
        'zip': userZip,
        'apartment': '',
        'label': 'Home',
      });
    }

    // Add form data address if different
    if (widget.formData.serviceAddress?.isNotEmpty == true &&
        widget.formData.serviceAddress != userAddress) {
      _savedAddresses.add({
        'name': widget.formData.customerName ?? userName,
        'phone': widget.formData.customerPhone ?? userPhone,
        'street': widget.formData.serviceAddress ?? '',
        'city': widget.formData.serviceCity ?? '',
        'state': widget.formData.serviceState ?? '',
        'zip': widget.formData.serviceZipCode ?? '',
        'apartment': widget.formData.serviceApartmentUnit ?? '',
        'label': 'Other',
      });
    }

    // If no saved addresses, add an empty one to fill in
    if (_savedAddresses.isEmpty) {
      _savedAddresses.add({
        'name': userName,
        'phone': userPhone,
        'street': '',
        'city': '',
        'state': '',
        'zip': '',
        'apartment': '',
        'label': 'Home',
      });
      _isEditingAddress = true;
    }
  }

  void _initControllers() {
    final addr = _savedAddresses.isNotEmpty
        ? _savedAddresses[_selectedAddressIndex]
        : <String, String>{};

    _nameController = TextEditingController(text: addr['name'] ?? '');
    _phoneController = TextEditingController(text: addr['phone'] ?? '');
    _streetController = TextEditingController(text: addr['street'] ?? '');
    _cityController = TextEditingController(text: addr['city'] ?? '');
    _stateController = TextEditingController(text: addr['state'] ?? '');
    _zipController = TextEditingController(text: addr['zip'] ?? '');
    _apartmentController = TextEditingController(text: addr['apartment'] ?? '');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  void _selectAddress(int index) {
    setState(() {
      _selectedAddressIndex = index;
      _isEditingAddress = false;
      final addr = _savedAddresses[index];
      _nameController.text = addr['name'] ?? '';
      _phoneController.text = addr['phone'] ?? '';
      _streetController.text = addr['street'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _zipController.text = addr['zip'] ?? '';
      _apartmentController.text = addr['apartment'] ?? '';
    });
  }

  void _addNewAddress() {
    setState(() {
      _nameController.clear();
      _phoneController.clear();
      _streetController.clear();
      _cityController.clear();
      _stateController.clear();
      _zipController.clear();
      _apartmentController.clear();
      _isEditingAddress = true;
      _selectedAddressIndex = -1;
    });
  }

  void _showAddressSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildAddressSheet(ctx),
    );
  }

  Widget _buildAddressSheet(BuildContext ctx) {
    final responsive = ctx.responsive;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(ctx).size.height * 0.65,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(responsive.borderRadius(20)),
        ),
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
          // Title
          Padding(
            padding: responsive.padding(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _addNewAddress();
                  },
                  icon: Icon(Icons.add, size: responsive.iconSize(18), color: AppColors.primary),
                  label: Text(
                    'Add New',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
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
              itemCount: _savedAddresses.length,
              itemBuilder: (_, index) {
                final addr = _savedAddresses[index];
                final isSelected = index == _selectedAddressIndex;
                return GestureDetector(
                  onTap: () {
                    Navigator.pop(ctx);
                    _selectAddress(index);
                  },
                  child: Container(
                    margin: responsive.padding(bottom: 12),
                    padding: responsive.padding(all: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary05 : Colors.white,
                      borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.gray100,
                            borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
                          ),
                          child: Icon(
                            addr['label'] == 'Home' ? Icons.home_rounded : Icons.location_on_rounded,
                            color: isSelected ? AppColors.primary : AppColors.gray600,
                            size: responsive.iconSize(20),
                          ),
                        ),
                        SizedBox(width: responsive.wp(3)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                addr['name'] ?? addr['label'] ?? 'Address',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: responsive.hp(0.3)),
                              Text(
                                _formatAddress(addr),
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (addr['phone']?.isNotEmpty == true) ...[
                                SizedBox(height: responsive.hp(0.3)),
                                Row(
                                  children: [
                                    Icon(Icons.phone_outlined, size: responsive.iconSize(12), color: AppColors.textLight),
                                    SizedBox(width: responsive.wp(1)),
                                    Text(
                                      addr['phone']!,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(12),
                                        color: AppColors.textLight,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          Icon(Icons.check_circle, color: AppColors.primary, size: responsive.iconSize(22)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatAddress(Map<String, String> addr) {
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

  void _saveAndContinue() {
    if (_formKey.currentState?.validate() != true) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }

    widget.formData.customerName = _nameController.text.trim();
    widget.formData.customerPhone = _phoneController.text.trim();
    widget.formData.serviceAddress = _streetController.text.trim();
    widget.formData.serviceCity = _cityController.text.trim();
    widget.formData.serviceState = _stateController.text.trim().toUpperCase();
    widget.formData.serviceZipCode = _zipController.text.trim();
    widget.formData.serviceApartmentUnit = _apartmentController.text.trim();

    // Also save to UserService for persistence
    UserService.instance.updateUserData({
      'address': _streetController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim().toUpperCase(),
      'zipCode': _zipController.text.trim(),
    });

    widget.onNext();
  }

  bool get _isValid {
    return _streetController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty &&
        _stateController.text.trim().isNotEmpty &&
        _zipController.text.trim().isNotEmpty;
  }

  // ── Validators (same as AddressFormScreen) ──

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'Name should only contain letters';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 10) return 'Phone must be 10 digits';
    return null;
  }

  String? _validateStreet(String? value) {
    if (value == null || value.trim().isEmpty) return 'Street address is required';
    if (value.trim().length < 5) return 'Please enter a valid street address';
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) return 'City is required';
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) return 'City should only contain letters';
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) return 'State is required';
    if (value.trim().length != 2) return 'Use 2-letter state code';
    return null;
  }

  String? _validateZip(String? value) {
    if (value == null || value.trim().isEmpty) return 'ZIP code is required';
    if (!RegExp(r'^\d{5}$').hasMatch(value)) return 'ZIP must be 5 digits';
    return null;
  }

  // ── Build ──

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
            controller: _scrollController,
            padding: responsive.padding(horizontal: 20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  responsive.heightBox(8),
                  Text(
                    'Service Address',
                    style: TextStyle(
                      fontSize: responsive.fontSize(22),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  responsive.heightBox(4),
                  Text(
                    'Where should we provide the service?',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  responsive.heightBox(20),

                  // Saved address selector (if addresses exist)
                  if (_savedAddresses.isNotEmpty && !_isEditingAddress) ...[
                    _buildSelectedAddressCard(responsive),
                    responsive.heightBox(16),
                  ],

                  // Address form fields
                  if (_isEditingAddress || _savedAddresses.isEmpty) ...[
                    _buildShadowField(
                      controller: _nameController,
                      label: 'Full Name',
                      validator: _validateName,
                      keyboardType: TextInputType.name,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                    ),
                    responsive.heightBox(16),
                    _buildShadowField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      validator: _validatePhone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                    ),
                    responsive.heightBox(16),
                    _buildShadowField(
                      controller: _apartmentController,
                      label: 'Apt / Suite / Floor (Optional)',
                      validator: (_) => null,
                    ),
                    responsive.heightBox(16),
                    _buildShadowField(
                      controller: _streetController,
                      label: 'Street Address',
                      validator: _validateStreet,
                      keyboardType: TextInputType.streetAddress,
                    ),
                    responsive.heightBox(16),
                    _buildShadowField(
                      controller: _cityController,
                      label: 'City',
                      validator: _validateCity,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                      ],
                    ),
                    responsive.heightBox(16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildShadowField(
                            controller: _stateController,
                            label: 'State',
                            validator: _validateState,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                              LengthLimitingTextInputFormatter(2),
                              TextInputFormatter.withFunction(
                                (oldValue, newValue) => newValue.copyWith(
                                  text: newValue.text.toUpperCase(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: responsive.wp(4)),
                        Expanded(
                          child: _buildShadowField(
                            controller: _zipController,
                            label: 'ZIP Code',
                            validator: _validateZip,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(5),
                            ],
                          ),
                        ),
                      ],
                    ),
                    responsive.heightBox(24),
                  ],
                ],
              ),
            ),
          ),
        ),
        BookingContinueButton(
          isValid: _isValid,
          label: 'Confirm Address',
          onPressed: _saveAndContinue,
        ),
      ],
    );
  }

  Widget _buildSelectedAddressCard(ResponsiveUtils responsive) {
    final addr = _savedAddresses[_selectedAddressIndex];
    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.primary05,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        border: Border.all(color: AppColors.primary, width: 1.5),
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
                padding: responsive.padding(all: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
                ),
                child: Icon(
                  addr['label'] == 'Home' ? Icons.home_rounded : Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: responsive.iconSize(20),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      addr['name'] ?? 'Address',
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.3)),
                    Text(
                      _formatAddress(addr),
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (addr['phone']?.isNotEmpty == true) ...[
                      SizedBox(height: responsive.hp(0.3)),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: responsive.iconSize(13), color: AppColors.textLight),
                          SizedBox(width: responsive.wp(1)),
                          Text(
                            addr['phone']!,
                            style: TextStyle(fontSize: responsive.fontSize(12), color: AppColors.textLight),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.hp(1.5)),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _isEditingAddress = true),
                  icon: Icon(Icons.edit_outlined, size: responsive.iconSize(16)),
                  label: Text(
                    'Edit',
                    style: TextStyle(fontSize: responsive.fontSize(13)),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
                    padding: responsive.padding(vertical: 10),
                  ),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddressSelectionSheet,
                  icon: Icon(Icons.swap_horiz_rounded, size: responsive.iconSize(16)),
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

  Widget _buildShadowField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: const TextStyle(
            fontSize: 12,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
          errorStyle: const TextStyle(fontSize: 12, height: 0.8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
