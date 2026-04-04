import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Address Form Screen for editing/adding addresses (used in combined flow)
class CombinedAddressFormScreen extends StatefulWidget {
  final Map<String, String>? existingAddress;

  const CombinedAddressFormScreen({super.key, this.existingAddress});

  @override
  State<CombinedAddressFormScreen> createState() =>
      _CombinedAddressFormScreenState();
}

class _CombinedAddressFormScreenState extends State<CombinedAddressFormScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressLine1Controller;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingAddress;
    if (existing != null) {
      _nameController = TextEditingController(text: existing['name']);
      _phoneController = TextEditingController(text: existing['phone']);
      final addressParts = (existing['address'] ?? '').split(', ');
      _addressLine1Controller = TextEditingController(
        text: addressParts.isNotEmpty ? addressParts[0] : '',
      );
      _cityController = TextEditingController(
        text: addressParts.length > 1 ? addressParts[1] : '',
      );
      if (addressParts.length > 2) {
        final stateZip = addressParts[2].split(' ');
        _stateController = TextEditingController(text: stateZip.isNotEmpty ? stateZip[0] : '');
        _zipController = TextEditingController(text: stateZip.length > 1 ? stateZip[1] : '');
      } else {
        _stateController = TextEditingController();
        _zipController = TextEditingController();
      }
    } else {
      _nameController = TextEditingController();
      _phoneController = TextEditingController();
      _addressLine1Controller = TextEditingController();
      _cityController = TextEditingController();
      _stateController = TextEditingController();
      _zipController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _saveAddress() {
    if (_formKey.currentState!.validate()) {
      final addressString =
          '${_addressLine1Controller.text}, ${_cityController.text}, ${_stateController.text} ${_zipController.text}';
      final result = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': addressString,
      };
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAddress != null;
    return Scaffold(
      backgroundColor: AppColors.backgroundWarm,
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Address' : 'Add New Address'),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerForeground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFormField('Full Name', _nameController, 'Enter full name'),
              SizedBox(height: responsive.spacing(16)),
              _buildFormField('Phone Number', _phoneController, 'Enter phone number',
                  keyboardType: TextInputType.phone),
              SizedBox(height: responsive.spacing(16)),
              _buildFormField('Street Address', _addressLine1Controller, 'Enter street address'),
              SizedBox(height: responsive.spacing(16)),
              _buildFormField('City', _cityController, 'Enter city'),
              SizedBox(height: responsive.spacing(16)),
              Row(
                children: [
                  Expanded(
                    child: _buildFormField('State', _stateController, 'e.g. NY'),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: _buildFormField('ZIP Code', _zipController, 'e.g. 10001',
                        keyboardType: TextInputType.number),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(32)),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    elevation: 0,
                  ),
                  child: Text(
                    isEditing ? 'Update Address' : 'Save Address',
                    style: TextStyle(fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormField(String label, TextEditingController controller, String hint,
      {TextInputType keyboardType = TextInputType.text}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: responsive.fontSize(14), color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(14)),
          ),
          style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textPrimary),
        ),
      ],
    );
  }
}