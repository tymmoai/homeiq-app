import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../services/user_service.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_review_addons_card.dart';
import 'booking_review_address_section.dart';
import 'booking_review_contact_section.dart';
import 'booking_review_items_card.dart';
import 'booking_review_order_card.dart';
import 'booking_review_price_card.dart';
import 'booking_step_header.dart';

/// Shared step widget for reviewing and confirming a booking.
///
/// Displays:
/// - Order details (service type, date, time)
/// - Contact information card with Edit button (technician-flow style)
/// - Delivery address card with Edit / Change buttons + address selection sheet
/// - Selected items and add-ons
/// - Wall details (if mounting)
/// - Price breakdown
/// - Terms & conditions checkbox
///
/// The contact info and delivery address sections follow the same pattern as
/// the **asset tab → SquareTrade AI → book technician → order confirmation**
/// flow, with saved address selection and inline editing.
class BookingReviewStep extends StatefulWidget {
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

  /// Optional extra widget to show between items card and price card.
  final Widget? extraContent;

  const BookingReviewStep({
    super.key,
    required this.formData,
    required this.categoryName,
    required this.availableItems,
    this.availableAddons = const [],
    this.serviceFee = 29.0,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
    this.extraContent,
  });

  @override
  State<BookingReviewStep> createState() => _BookingReviewStepState();
}

class _BookingReviewStepState extends State<BookingReviewStep> {
  final _scrollController = ScrollController();
  bool _termsAccepted = false;

  // ── Contact Information ──
  bool _isEditingContact = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _contactFormKey = GlobalKey<FormState>();

  // ── Delivery Address (technician-flow style) ──
  bool _isEditingAddress = false;
  int _selectedAddressIndex = 0;
  late List<Map<String, String>> _savedAddresses;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipCodeController;
  late TextEditingController _apartmentController;
  final _addressFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final user = UserService.instance;

    // Contact controllers
    _nameController = TextEditingController(
      text: widget.formData.customerName ?? user.getUserName(),
    );
    _emailController = TextEditingController(
      text: widget.formData.customerEmail ?? user.getUserEmail(),
    );
    _phoneController = TextEditingController(
      text: widget.formData.customerPhone ?? user.getUserPhone(),
    );

    // Address controllers
    _streetController = TextEditingController(
      text: widget.formData.serviceAddress ?? user.getUserAddress(),
    );
    _cityController = TextEditingController(
      text: widget.formData.serviceCity ?? user.getUserCity(),
    );
    _stateController = TextEditingController(
      text: widget.formData.serviceState ?? user.getUserState(),
    );
    _zipCodeController = TextEditingController(
      text: widget.formData.serviceZipCode ?? user.getUserZipCode(),
    );
    _apartmentController = TextEditingController(
      text: widget.formData.serviceApartmentUnit ??
          user.getUserApartmentUnit(),
    );

    // Build saved addresses list
    _buildSavedAddresses();
  }

  void _buildSavedAddresses() {
    final user = UserService.instance;
    _savedAddresses = [];

    final userAddress = user.getUserAddress();
    final userName = user.getUserName();
    final userPhone = user.getUserPhone();
    final userCity = user.getUserCity();
    final userState = user.getUserState();
    final userZip = user.getUserZipCode();

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

    // Address from form data if different
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
        'label': 'Service',
      });
    }

    // Add a secondary address option (like technician flow)
    if (_savedAddresses.length < 2) {
      _savedAddresses.add({
        'name': userName.isNotEmpty ? userName : 'Home',
        'phone': userPhone.isNotEmpty ? userPhone : '(555) 987-6543',
        'street': '456 Oak Avenue',
        'city': 'Brooklyn',
        'state': 'NY',
        'zip': '11201',
        'apartment': '',
        'label': 'Work',
      });
    }

    if (_savedAddresses.isEmpty) {
      _savedAddresses.add({
        'name': '',
        'phone': '',
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

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _apartmentController.dispose();
    super.dispose();
  }

  String _formatPhoneNumber(String phone) {
    final digitsOnly = phone.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length > 10) {
      return _formatPhoneNumber(digitsOnly.substring(0, 10));
    }
    if (digitsOnly.length >= 6) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    } else if (digitsOnly.length >= 3) {
      return '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else if (digitsOnly.isNotEmpty) {
      return '($digitsOnly';
    }
    return digitsOnly;
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

  void _selectAddress(int index) {
    setState(() {
      _selectedAddressIndex = index;
      _isEditingAddress = false;
      final addr = _savedAddresses[index];
      _streetController.text = addr['street'] ?? '';
      _cityController.text = addr['city'] ?? '';
      _stateController.text = addr['state'] ?? '';
      _zipCodeController.text = addr['zip'] ?? '';
      _apartmentController.text = addr['apartment'] ?? '';
      _nameController.text = addr['name'] ?? '';
      _phoneController.text = addr['phone'] ?? '';
    });
  }

  void _addNewAddress() {
    setState(() {
      _streetController.clear();
      _cityController.clear();
      _stateController.clear();
      _zipCodeController.clear();
      _apartmentController.clear();
      _isEditingAddress = true;
      _selectedAddressIndex = -1;
    });
  }

  // ──────────────────────────────────────────────────────────────────────
  // BUILD
  // ──────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: context.responsive.padding(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review your booking',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(24.0),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  context.responsive.heightBox(8.0),
                  Text(
                    'Please confirm all details are correct',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(14.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  context.responsive.heightBox(24.0),

                  // ── Order Details ──
                  BookingReviewOrderDetailsCard(formData: widget.formData),
                  context.responsive.heightBox(16.0),

                  // ── Contact Information (technician-flow style) ──
                  BookingReviewContactSection(
                    isEditing: _isEditingContact,
                    onToggleEdit: () =>
                        setState(() => _isEditingContact = !_isEditingContact),
                    nameController: _nameController,
                    emailController: _emailController,
                    phoneController: _phoneController,
                    contactFormKey: _contactFormKey,
                    onFieldChanged: () => setState(() {}),
                    formatPhoneNumber: _formatPhoneNumber,
                  ),
                  context.responsive.heightBox(16.0),

                  // ── Delivery Address (technician-flow style with edit/change) ──
                  BookingReviewAddressSection(
                    isEditing: _isEditingAddress,
                    selectedAddressIndex: _selectedAddressIndex,
                    savedAddresses: _savedAddresses,
                    streetController: _streetController,
                    cityController: _cityController,
                    stateController: _stateController,
                    zipCodeController: _zipCodeController,
                    apartmentController: _apartmentController,
                    nameController: _nameController,
                    phoneController: _phoneController,
                    addressFormKey: _addressFormKey,
                    onStartEditing: () {
                      setState(() {
                        _isEditingAddress = true;
                        final a = _savedAddresses[_selectedAddressIndex];
                        _streetController.text = a['street'] ?? '';
                        _cityController.text = a['city'] ?? '';
                        _stateController.text = a['state'] ?? '';
                        _zipCodeController.text = a['zip'] ?? '';
                        _apartmentController.text = a['apartment'] ?? '';
                      });
                    },
                    onSelectAddress: _selectAddress,
                    onSelectAndEditAddress: (index) {
                      _selectAddress(index);
                      setState(() => _isEditingAddress = true);
                    },
                    onAddNewAddress: _addNewAddress,
                    onSaveAddress: (newAddr) {
                      setState(() {
                        if (_selectedAddressIndex >= 0 &&
                            _selectedAddressIndex < _savedAddresses.length) {
                          _savedAddresses[_selectedAddressIndex] = newAddr;
                        } else {
                          _savedAddresses.add(newAddr);
                          _selectedAddressIndex = _savedAddresses.length - 1;
                        }
                        _isEditingAddress = false;
                      });
                    },
                    onFieldChanged: () => setState(() {}),
                  ),
                  context.responsive.heightBox(16.0),

                  // ── Items ──
                  BookingReviewItemsCard(
                      selectedItemsList: _selectedItemsList),

                  // ── Add-ons ──
                  if (widget.formData.selectedAddons.isNotEmpty) ...[
                    context.responsive.heightBox(16.0),
                    BookingReviewAddonsCard(
                      selectedAddons: widget.formData.selectedAddons,
                      availableAddons: widget.availableAddons,
                    ),
                  ],

                  // ── Wall Type (if set — mounting) ──
                  if (widget.formData.wallType != null) ...[
                    context.responsive.heightBox(16.0),
                    _buildWallTypeCard(),
                  ],

                  // ── Special Requirements ──
                  if (widget.formData.specialRequirements != null &&
                      widget.formData.specialRequirements!.isNotEmpty) ...[
                    context.responsive.heightBox(16.0),
                    _buildSpecialRequirementsCard(),
                  ],

                  // ── Extra content ──
                  if (widget.extraContent != null) ...[
                    context.responsive.heightBox(16.0),
                    widget.extraContent!,
                  ],

                  context.responsive.heightBox(16.0),
                  BookingReviewPriceCard(
                    itemsTotal: _itemsTotal,
                    addonsTotal: _addonsTotal,
                    serviceFee: widget.serviceFee,
                  ),
                  context.responsive.heightBox(16.0),
                  _buildTermsCheckbox(),
                  context.responsive.heightBox(24.0),
                ],
              ),
            ),
          ),
        ),
        _buildConfirmButton(),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // WALL TYPE CARD (mounting-specific)
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildWallTypeCard() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(context.responsive.borderRadius(16.0)),
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
                  borderRadius: BorderRadius.circular(
                      context.responsive.borderRadius(10.0)),
                ),
                child: Icon(
                  Icons.grid_4x4_rounded,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Wall Details',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(12.0),
          BookingReviewDetailRow(
            label: 'Wall Type:',
            value: widget.formData.wallType ?? 'Not specified',
            showDivider: widget.formData.mountingHeight != null,
          ),
          if (widget.formData.mountingHeight != null)
            BookingReviewDetailRow(
              label: 'Mount Height:',
              value: widget.formData.mountingHeight!,
              showDivider: false,
            ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // SPECIAL REQUIREMENTS CARD
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildSpecialRequirementsCard() {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(context.responsive.borderRadius(16.0)),
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
                  borderRadius: BorderRadius.circular(
                      context.responsive.borderRadius(10.0)),
                ),
                child: Icon(
                  Icons.edit_note_outlined,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Special Requirements',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(12.0),
          Text(
            widget.formData.specialRequirements!,
            style: TextStyle(
              fontSize: context.responsive.fontSize(14.0),
              color: AppColors.gray700,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // TERMS CHECKBOX
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _termsAccepted = !_termsAccepted),
      child: Padding(
        padding: context.responsive.padding(vertical: 8),
        child: Row(
          children: [
            Container(
              width: context.responsive.spacing(22.0),
              height: context.responsive.spacing(22.0),
              decoration: BoxDecoration(
                color:
                    _termsAccepted ? AppColors.success : AppColors.transparent,
                borderRadius: BorderRadius.circular(
                    context.responsive.borderRadius(4.0)),
                border: _termsAccepted
                    ? null
                    : Border.all(color: AppColors.gray400, width: 1.5),
              ),
              child: _termsAccepted
                  ? Icon(Icons.check,
                      color: AppColors.white,
                      size: context.responsive.iconSize(16.0))
                  : null,
            ),
            context.responsive.widthBox(12.0),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: context.responsive.fontSize(13.0),
                    color: AppColors.textQuaternary,
                  ),
                  children: [
                    const TextSpan(text: 'I agree to the '),
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Cancellation Policy',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // CONFIRM BUTTON
  // ──────────────────────────────────────────────────────────────────────

  Widget _buildConfirmButton() {
    final isValid = _termsAccepted;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(color: AppColors.white),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: isValid
              ? () {
                  if (_isEditingContact &&
                      _contactFormKey.currentState?.validate() != true) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    return;
                  }
                  if (_isEditingAddress &&
                      _addressFormKey.currentState?.validate() != true) {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                    return;
                  }
                  _saveFormDataToState();
                  widget.onNext();
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                isValid ? AppColors.primary : AppColors.divider,
            elevation: isValid ? 2 : 0,
            shadowColor: AppColors.primary.withValues(alpha: 0.3),
          ),
          child: Text(
            'Confirm & Continue to Payment',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isValid ? AppColors.white : AppColors.textLight,
            ),
          ),
        ),
      ),
    );
  }

  void _saveFormDataToState() {
    widget.formData.customerName = _nameController.text;
    widget.formData.customerEmail = _emailController.text;
    widget.formData.customerPhone = _phoneController.text;

    if (_selectedAddressIndex >= 0 &&
        _selectedAddressIndex < _savedAddresses.length &&
        !_isEditingAddress) {
      final addr = _savedAddresses[_selectedAddressIndex];
      widget.formData.serviceAddress = addr['street'];
      widget.formData.serviceCity = addr['city'];
      widget.formData.serviceState = addr['state'];
      widget.formData.serviceZipCode = addr['zip'];
      widget.formData.serviceApartmentUnit = addr['apartment'];
    } else {
      widget.formData.serviceAddress = _streetController.text;
      widget.formData.serviceCity = _cityController.text;
      widget.formData.serviceState = _stateController.text;
      widget.formData.serviceZipCode = _zipCodeController.text;
      widget.formData.serviceApartmentUnit = _apartmentController.text;
    }

    final userService = UserService.instance;
    userService.updateUserData({
      'name': _nameController.text,
      'email': _emailController.text,
      'phone': _phoneController.text,
      'address': widget.formData.serviceAddress ?? '',
      'city': widget.formData.serviceCity ?? '',
      'state': widget.formData.serviceState ?? '',
      'zipCode': widget.formData.serviceZipCode ?? '',
      'apartmentUnit': widget.formData.serviceApartmentUnit ?? '',
    });
  }
}
