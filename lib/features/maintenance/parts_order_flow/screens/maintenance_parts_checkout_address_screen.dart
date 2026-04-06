// Maintenance Parts Checkout Address Screen
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../services/user_service.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/maintenance_models.dart';

class MaintenancePartsCheckoutAddressScreen extends StatefulWidget {
  final Reminder reminder;
  final List<dynamic> parts;
  final List<bool> selectedParts;
  final int subtotal;
  final Map<String, int> providerTotals;

  const MaintenancePartsCheckoutAddressScreen({
    super.key,
    required this.reminder,
    required this.parts,
    required this.selectedParts,
    required this.subtotal,
    required this.providerTotals,
  });

  @override
  State<MaintenancePartsCheckoutAddressScreen> createState() =>
      _MaintenancePartsCheckoutAddressScreenState();
}

class _MaintenancePartsCheckoutAddressScreenState
    extends State<MaintenancePartsCheckoutAddressScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _fullNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    final user = UserService.instance;
    _fullNameController = TextEditingController(text: user.getUserName());
    _phoneController = TextEditingController(text: user.getUserPhone());
    _streetController = TextEditingController(text: user.getUserAddress());
    _cityController = TextEditingController(text: user.getUserCity());
    _stateController = TextEditingController(text: user.getUserState());
    _zipController = TextEditingController(text: user.getUserZipCode());
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_formKey.currentState!.validate()) {
      context.push(
        '/maintenance/parts-checkout-payment',
        extra: {
          'reminder': widget.reminder,
          'parts': widget.parts,
          'selectedParts': widget.selectedParts,
          'subtotal': widget.subtotal,
          'providerTotals': widget.providerTotals,
          'address': {
            'fullName': _fullNameController.text,
            'phone': _phoneController.text,
            'street': _streetController.text,
            'city': _cityController.text,
            'state': _stateController.text,
            'zip': _zipController.text,
          },
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedParts.where((s) => s).length;
    final expectedDelivery = DateTime.now().add(const Duration(days: 6));
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final expectedDeliveryLabel =
        '${monthNames[expectedDelivery.month - 1]} ${expectedDelivery.day}, ${expectedDelivery.year}';

    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => context.pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_fix_high,
              size: responsive.iconSize(20),
              color: AppColors.headerForeground,
            ),
            SizedBox(width: responsive.spacing(8)),
            Text(
              AppStrings.aiName,
              style: TextStyle(
                color: AppColors.headerForeground,
                fontWeight: FontWeight.w700,
                fontSize: responsive.fontSize(18),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close, color: AppColors.headerForeground),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Container(
        color: AppColors.backgroundGray50,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(responsive.spacing(20)),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected parts summary
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
                        '$selectedCount PARTS SELECTED',
                        style: TextStyle(
                          fontSize: responsive.fontSize(11),
                          fontWeight: FontWeight.w500,
                          color: AppColors.gray600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      ...widget.parts
                          .asMap()
                          .entries
                          .where((entry) => widget.selectedParts[entry.key])
                          .map((entry) {
                            final part = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      part.name,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13),
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '\$${(part.priceEncompass * part.quantity).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(13),
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                      SizedBox(height: responsive.spacing(12)),
                      Divider(height: 1, color: AppColors.divider),
                      SizedBox(height: responsive.spacing(12)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '\$${widget.subtotal.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),
                // Delivery Address Section
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                // Full Name
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(
                        fontSize: responsive.fontSize(18),
                        color: AppColors.textSecondary,
                      ),
                      floatingLabelStyle: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(12),
                        vertical: responsive.spacing(14),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter full name'
                        : null,
                    style: TextStyle(fontSize: responsive.fontSize(14)),
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),
                // Phone
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      labelStyle: TextStyle(
                        fontSize: responsive.fontSize(18),
                        color: AppColors.textSecondary,
                      ),
                      floatingLabelStyle: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(12),
                        vertical: responsive.spacing(14),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter phone number'
                        : null,
                    style: TextStyle(fontSize: responsive.fontSize(14)),
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),
                // Street Address
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    controller: _streetController,
                    decoration: InputDecoration(
                      labelText: 'Street Address',
                      labelStyle: TextStyle(
                        fontSize: responsive.fontSize(18),
                        color: AppColors.textSecondary,
                      ),
                      floatingLabelStyle: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(12),
                        vertical: responsive.spacing(14),
                      ),
                      filled: true,
                      fillColor: AppColors.white,
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Please enter street address'
                        : null,
                    style: TextStyle(fontSize: responsive.fontSize(14)),
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),
                // City, State, ZIP Row
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _cityController,
                          decoration: InputDecoration(
                            labelText: 'City',
                            labelStyle: TextStyle(
                              fontSize: responsive.fontSize(18),
                              color: AppColors.textSecondary,
                            ),
                            floatingLabelStyle: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(12),
                              vertical: responsive.spacing(14),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter city'
                              : null,
                          style: TextStyle(fontSize: responsive.fontSize(14)),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _stateController,
                          decoration: InputDecoration(
                            labelText: 'State',
                            labelStyle: TextStyle(
                              fontSize: responsive.fontSize(18),
                              color: AppColors.textSecondary,
                            ),
                            floatingLabelStyle: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(12),
                              vertical: responsive.spacing(14),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter state'
                              : null,
                          style: TextStyle(fontSize: responsive.fontSize(14)),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.shadow,
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _zipController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'ZIP',
                            labelStyle: TextStyle(
                              fontSize: responsive.fontSize(18),
                              color: AppColors.textSecondary,
                            ),
                            floatingLabelStyle: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.primary,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              borderSide: BorderSide(color: AppColors.gray300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(12),
                              vertical: responsive.spacing(14),
                            ),
                            filled: true,
                            fillColor: AppColors.white,
                          ),
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter ZIP code'
                              : null,
                          style: TextStyle(fontSize: responsive.fontSize(14)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(24)),
                // Expected Delivery
                Container(
                  padding: EdgeInsets.all(responsive.spacing(12)),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.local_shipping,
                        size: responsive.iconSize(20),
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Expanded(
                        child: Text(
                          'Expected Delivery: $expectedDeliveryLabel',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AppColors.gray600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(32)),
                // Continue button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      elevation: 0,
                    ),
                    child: Text(
                      'Confirm Address & Continue',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(20)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
