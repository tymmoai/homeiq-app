import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Standalone screen for adding or editing a shipping address.
///
/// Returns a `Map<String, String>` via `Navigator.pop` with keys:
/// `name`, `cellPhone`, and `address`.
class AddressFormScreen extends StatefulWidget {
  final Map<String, String>? existingAddress;

  const AddressFormScreen({super.key, this.existingAddress});

  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _cellPhoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _addressLine2Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;

  String _selectedCountryCode = '+1-US';
  final Map<String, String> _countryCodes = {
    '+1-US': 'United States (+1)',
    '+1-CA': 'Canada (+1)',
    '+44': 'United Kingdom (+44)',
    '+91': 'India (+91)',
    '+61': 'Australia (+61)',
  };

  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.background;
  static const Color _inputBackground = Colors.white;
  static const Color _shadowColor = Colors.black;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAddress;
    if (existing != null) {
      _nameController = TextEditingController(text: existing['name']);

      final cellPhoneData = existing['cellPhone'] ?? '';
      if (cellPhoneData.contains('-')) {
        final parts = cellPhoneData.split('-');
        _selectedCountryCode = '${parts[0]}-US';
        _cellPhoneController = TextEditingController(text: parts[1]);
      } else {
        _selectedCountryCode = '+1-US';
        _cellPhoneController = TextEditingController(text: cellPhoneData);
      }

      final addressParts = existing['address']!.split(', ');
      _addressLine1Controller = TextEditingController(
        text: addressParts.isNotEmpty ? addressParts[0] : '',
      );
      _addressLine2Controller = TextEditingController();
      _cityController = TextEditingController(
        text: addressParts.length > 1 ? addressParts[1] : '',
      );

      if (addressParts.length > 2) {
        final stateZip = addressParts[2].split(' ');
        _stateController = TextEditingController(
          text: stateZip.isNotEmpty ? stateZip[0] : '',
        );
        _zipController = TextEditingController(
          text: stateZip.length > 1 ? stateZip[1] : '',
        );
      } else {
        _stateController = TextEditingController();
        _zipController = TextEditingController();
      }
    } else {
      _nameController = TextEditingController();
      _cellPhoneController = TextEditingController();
      _addressLine1Controller = TextEditingController();
      _addressLine2Controller = TextEditingController();
      _cityController = TextEditingController();
      _stateController = TextEditingController();
      _zipController = TextEditingController();
      _selectedCountryCode = '+1-US';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cellPhoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  // â”€â”€ Validators â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String? _validateCellPhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter cell number';
    final cleanNumber = value.replaceAll(RegExp(r'\D'), '');
    final countryCodeOnly = _selectedCountryCode.split('-').first;
    if (countryCodeOnly == '+1' && cleanNumber.length != 10) {
      return 'US/Canada number must be exactly 10 digits';
    } else if (countryCodeOnly == '+44' &&
        (cleanNumber.length < 10 || cleanNumber.length > 11)) {
      return 'UK number must be 10-11 digits';
    } else if (countryCodeOnly == '+91' && cleanNumber.length != 10) {
      return 'India number must be exactly 10 digits';
    } else if (countryCodeOnly == '+61' && cleanNumber.length != 9) {
      return 'Australia number must be exactly 9 digits';
    }
    return null;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter full name';
    if (value.trim().length < 2) return 'Name must be at least 2 characters';
    if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens and apostrophes';
    }
    return null;
  }

  String? _validateCity(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter city';
    if (!RegExp(r'^[a-zA-Z\s\-\.]+$').hasMatch(value)) return 'City name is invalid';
    return null;
  }

  String? _validateState(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please select state';
    if (value.trim().length != 2) return 'State must be 2 letters (e.g., NY, CA)';
    if (!RegExp(r'^[a-zA-Z]{2}$').hasMatch(value)) return 'State must be 2 letters only';
    return null;
  }

  String? _validateZip(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter ZIP code';
    if (!RegExp(r'^\d{5}(-\d{4})?$').hasMatch(value)) {
      return 'ZIP must be 5 digits (12345) or 5+4 format (12345-6789)';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) return 'Please enter address';
    if (value.trim().length < 5) return 'Address must be at least 5 characters';
    return null;
  }

  // â”€â”€ Formatters â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  String _formatZipCode(String input) {
    final digitsOnly = input.replaceAll(RegExp(r'[^\d]'), '');
    final limited = digitsOnly.length > 9 ? digitsOnly.substring(0, 9) : digitsOnly;
    if (limited.length > 5) {
      return '${limited.substring(0, 5)}-${limited.substring(5)}';
    }
    return limited;
  }

  String _formatPhoneNumber(String input) {
    final cleanNumber = input.replaceAll(RegExp(r'\D'), '');
    final countryCodeOnly = _selectedCountryCode.split('-').first;

    int maxDigits;
    switch (countryCodeOnly) {
      case '+44':
        maxDigits = 11;
      case '+61':
        maxDigits = 9;
      default:
        maxDigits = 10;
    }

    final limited =
        cleanNumber.length > maxDigits ? cleanNumber.substring(0, maxDigits) : cleanNumber;

    switch (countryCodeOnly) {
      case '+1':
        if (limited.length >= 3) {
          if (limited.length <= 3) return '(${limited.substring(0, 3)}';
          if (limited.length <= 6) {
            return '(${limited.substring(0, 3)}) ${limited.substring(3)}';
          }
          return '(${limited.substring(0, 3)}) ${limited.substring(3, 6)}-${limited.substring(6)}';
        }
        return limited;
      case '+91':
        if (limited.length > 5) {
          return '${limited.substring(0, 5)} ${limited.substring(5)}';
        }
        return limited;
      case '+44':
        if (limited.length > 4) {
          return '${limited.substring(0, 4)} ${limited.substring(4)}';
        }
        return limited;
      case '+61':
        if (limited.length > 3) {
          if (limited.length <= 6) {
            return '${limited.substring(0, 3)} ${limited.substring(3)}';
          }
          return '${limited.substring(0, 3)} ${limited.substring(3, 6)} ${limited.substring(6)}';
        }
        return limited;
      default:
        return limited;
    }
  }

  // â”€â”€ Actions â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final addressLine2 = _addressLine2Controller.text.trim();
      final addressString = addressLine2.isEmpty
          ? '${_addressLine1Controller.text}, ${_cityController.text}, ${_stateController.text} ${_zipController.text}'
          : '${_addressLine1Controller.text}, $addressLine2, ${_cityController.text}, ${_stateController.text} ${_zipController.text}';

      final countryCodeOnly = _selectedCountryCode.split('-').first;
      final cleanPhoneNumber =
          _cellPhoneController.text.replaceAll(RegExp(r'\D'), '');

      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'cellPhone': '$countryCodeOnly-$cleanPhoneNumber',
        'address': addressString,
      });
    }
  }

  InputDecoration _buildInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      filled: true,
      fillColor: _inputBackground,
      hintStyle: TextStyle(color: AppColors.textSecondary),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      errorStyle: const TextStyle(color: AppColors.error, fontSize: 12),
    );
  }

  BoxDecoration _buildInputBoxDecoration() {
    return BoxDecoration(
      color: _inputBackground,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: _shadowColor.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: responsive.padding(all: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildField('Full Name', _nameController, 'Enter full name',
                        validator: _validateName),
                    responsive.heightBox(16.0),
                    _buildPhoneField(responsive),
                    responsive.heightBox(16.0),
                    _buildField('Address Line 1', _addressLine1Controller,
                        'Street address, P.O. box',
                        validator: _validateAddress),
                    responsive.heightBox(16.0),
                    _buildField('Address Line 2 (Optional)',
                        _addressLine2Controller, 'Apartment, suite, unit, etc.'),
                    responsive.heightBox(16.0),
                    _buildField('City', _cityController, 'Enter city',
                        validator: _validateCity),
                    responsive.heightBox(16.0),
                    _buildStateZipRow(responsive),
                  ],
                ),
              ),
            ),
          ),
          Container(
            padding: responsive.padding(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(color: _backgroundColor),
            child: SizedBox(
              width: double.infinity,
              height: responsive.buttonHeight(52.0),
              child: ElevatedButton(
                onPressed: _saveAddress,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: Text(
                  'Save Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16.0),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    String hint, {
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    TextInputType? keyboardType,
  }) {
    final responsive = context.responsive;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            )),
        responsive.heightBox(8.0),
        Container(
          decoration: _buildInputBoxDecoration(),
          constraints: const BoxConstraints(minHeight: 56),
          clipBehavior: Clip.hardEdge,
          child: TextFormField(
            controller: controller,
            decoration: _buildInputDecoration(hint),
            validator: validator,
            inputFormatters: formatters,
            keyboardType: keyboardType,
          ),
        ),
      ],
    );
  }

  Widget _buildPhoneField(ResponsiveUtils responsive) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cell Number',
            style: TextStyle(
              fontSize: responsive.fontSize(13.0),
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            )),
        responsive.heightBox(8.0),
        Row(
          children: [
            Container(
              decoration: _buildInputBoxDecoration(),
              constraints: const BoxConstraints(minHeight: 56),
              clipBehavior: Clip.hardEdge,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCountryCode,
                  isExpanded: false,
                  items: _countryCodes.entries
                      .map((e) => DropdownMenuItem(
                          value: e.key,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            child: Text(e.key,
                                style: const TextStyle(fontWeight: FontWeight.w600)),
                          )))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedCountryCode = v);
                  },
                ),
              ),
            ),
            responsive.widthBox(12.0),
            Expanded(
              child: Container(
                decoration: _buildInputBoxDecoration(),
                constraints: const BoxConstraints(minHeight: 56),
                clipBehavior: Clip.hardEdge,
                child: TextFormField(
                  controller: _cellPhoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _buildInputDecoration('Enter cell number'),
                  validator: _validateCellPhone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\d\s\-()]+'))  ,
                    TextInputFormatter.withFunction((old, nw) {
                      final f = _formatPhoneNumber(nw.text);
                      return nw.copyWith(
                        text: f,
                        selection:
                            TextSelection.fromPosition(TextPosition(offset: f.length)),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStateZipRow(ResponsiveUtils responsive) {
    return Row(
      children: [
        Expanded(
          child: _buildField('State', _stateController, 'State',
              validator: _validateState,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')),
                TextInputFormatter.withFunction((old, nw) {
                  if (nw.text.length > 2) return old;
                  return nw.copyWith(text: nw.text.toUpperCase());
                }),
              ]),
        ),
        responsive.widthBox(12.0),
        Expanded(
          child: _buildField('ZIP Code', _zipController, 'ZIP',
              validator: _validateZip,
              keyboardType: TextInputType.number,
              formatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d\-]')),
                TextInputFormatter.withFunction((old, nw) {
                  final f = _formatZipCode(nw.text);
                  return nw.copyWith(
                    text: f,
                    selection:
                        TextSelection.fromPosition(TextPosition(offset: f.length)),
                  );
                }),
              ]),
        ),
      ],
    );
  }
}
