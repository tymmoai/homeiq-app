import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../utils/responsive_utils.dart';

class AddressFormScreen extends StatefulWidget {
  final Map<String, String>? existingAddress;
  final bool isEdit;

  const AddressFormScreen({
    super.key,
    this.existingAddress,
    this.isEdit = false,
  });

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;

  @override
  void initState() {
    super.initState();

    if (widget.isEdit && widget.existingAddress != null) {
      // Parse existing address if editing
      final addressParts =
          widget.existingAddress!['address']?.split(', ') ?? [];
      _nameController = TextEditingController(
        text: widget.existingAddress!['name'],
      );
      _phoneController = TextEditingController(
        text: widget.existingAddress!['phone'],
      );
      _streetController = TextEditingController(
        text: addressParts.isNotEmpty ? addressParts[0] : '',
      );

      if (addressParts.length > 1) {
        final cityStateParts = addressParts[1].split(', ');
        _cityController = TextEditingController(
          text: cityStateParts.isNotEmpty ? cityStateParts[0] : '',
        );

        if (addressParts.length > 2) {
          final stateZipParts = addressParts[2].split(' ');
          _stateController = TextEditingController(
            text: stateZipParts.isNotEmpty ? stateZipParts[0] : '',
          );
          _zipController = TextEditingController(
            text: stateZipParts.length > 1 ? stateZipParts[1] : '',
          );
        } else {
          _stateController = TextEditingController();
          _zipController = TextEditingController();
        }
      } else {
        _cityController = TextEditingController();
        _stateController = TextEditingController();
        _zipController = TextEditingController();
      }
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _streetController = TextEditingController();
      _cityController = TextEditingController();
      _stateController = TextEditingController();
      _zipController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'Name should only contain letters';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Remove formatting characters
    final cleaned = value.replaceAll(RegExp(r'[^\d]'), '');
    if (cleaned.length != 10) {
      return 'Phone must be 10 digits';
    }
    return null;
  }

  String? _validateStreet(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Street address is required';
    }
    if (value.trim().length < 5) {
      return 'Please enter a valid street address';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter a valid city';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'City should only contain letters';
    }
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'State is required';
    }
    if (value.trim().length != 2) {
      return 'Use 2-letter state code (e.g., NY)';
    }
    if (!RegExp(r'^[A-Z]{2}$').hasMatch(value.toUpperCase())) {
      return 'Invalid state code';
    }
    return null;
  }

  String? _validateZip(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'ZIP code is required';
    }
    if (!RegExp(r'^\d{5}$').hasMatch(value)) {
      return 'ZIP must be 5 digits';
    }
    return null;
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final addressData = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address':
            '${_streetController.text.trim()}, ${_cityController.text.trim()}, ${_stateController.text.trim().toUpperCase()} ${_zipController.text.trim()}',
      };
      Navigator.pop(context, addressData);
    }
  }

  Widget _buildShadowField({
    required TextEditingController controller,
    required String label,
    required String? Function(String?) validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    int maxLines = 1,
  }) {
    return Container(
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
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
          errorStyle: TextStyle(fontSize: responsive.fontSize(12), height: 0.8),
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
          fillColor: AppColors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = screenHeight * 0.03; // 3% from bottom

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
        ),
        title: Text(
          widget.isEdit ? 'Edit Address' : 'Add New Address',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: AppColors.headerForeground,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: bottomPadding + 70, // Extra space for button
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full Name
                  _buildShadowField(
                    controller: _nameController,
                    label: 'Full Name',
                    validator: _validateName,
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(16)),

                  // Phone Number
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
                  SizedBox(height: responsive.spacing(16)),

                  // Street Address
                  _buildShadowField(
                    controller: _streetController,
                    label: 'Street Address',
                    validator: _validateStreet,
                    keyboardType: TextInputType.streetAddress,
                  ),
                  SizedBox(height: responsive.spacing(16)),

                  // City
                  _buildShadowField(
                    controller: _cityController,
                    label: 'City',
                    validator: _validateCity,
                    keyboardType: TextInputType.text,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(16)),

                  // State and ZIP in a row
                  Row(
                    children: [
                      Expanded(
                        flex: 1,
                        child: _buildShadowField(
                          controller: _stateController,
                          label: 'State',
                          validator: _validateState,
                          keyboardType: TextInputType.text,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[A-Za-z]'),
                            ),
                            LengthLimitingTextInputFormatter(2),
                            TextInputFormatter.withFunction((
                              oldValue,
                              newValue,
                            ) {
                              return newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                              );
                            }),
                          ],
                        ),
                      ),
                      SizedBox(width: responsive.spacing(16)),
                      Expanded(
                        flex: 1,
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
                ],
              ),
            ),
          ),

          // Save Button positioned at 3% from bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: bottomPadding,
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowDark,
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(16),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  widget.isEdit ? 'Save Changes' : 'Save Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
