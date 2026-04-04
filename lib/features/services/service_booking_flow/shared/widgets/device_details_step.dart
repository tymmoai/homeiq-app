import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Device details step for Security / Smart Home service flow.
///
/// Replaces ItemQuantitySelector for Security.
/// Matches web's SmartHomeFlow device details step:
/// - Quantity selection
/// - Installation location (Indoor / Outdoor / Both)
/// - Power type (Wired / Battery / Solar)
class DeviceDetailsStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final String deviceName;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const DeviceDetailsStep({
    super.key,
    required this.formData,
    required this.deviceName,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<DeviceDetailsStep> createState() => _DeviceDetailsStepState();
}

class _DeviceDetailsStepState extends State<DeviceDetailsStep> {
  int _quantity = 1;

  static const _locationOptions = ['Indoor', 'Outdoor', 'Both'];
  static const _powerTypeOptions = ['Wired', 'Battery', 'Solar'];

  String? _selectedLocation;
  String? _selectedPowerType;

  @override
  void initState() {
    super.initState();
    _quantity = widget.formData.selectedItems[widget.deviceName] ?? 1;
    // Parse existing selections
    _selectedLocation = widget.formData.deviceBrand; // Reuse for location
    _selectedPowerType = widget.formData.paintType; // Reuse for power type
  }

  bool get _isValid =>
      _quantity > 0 && _selectedLocation != null && _selectedPowerType != null;

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
            padding: responsive.padding(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                responsive.heightBox(8),
                Text(
                  'Device Details',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'Configure your ${widget.deviceName}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(24),

                // Quantity selector
                BookingShadowCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      responsive.heightBox(12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildQuantityButton(
                            responsive,
                            icon: Icons.remove,
                            onTap: () {
                              if (_quantity > 1) setState(() => _quantity--);
                            },
                          ),
                          SizedBox(width: responsive.wp(6)),
                          Text(
                            '$_quantity',
                            style: TextStyle(
                              fontSize: responsive.fontSize(28),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(width: responsive.wp(6)),
                          _buildQuantityButton(
                            responsive,
                            icon: Icons.add,
                            onTap: () {
                              if (_quantity < 10) setState(() => _quantity++);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                responsive.heightBox(20),

                // Installation Location
                Text(
                  'Installation Location',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                Row(
                  children: _locationOptions.map((loc) {
                    final isSelected = _selectedLocation == loc;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedLocation = loc),
                        child: Container(
                          margin: responsive.padding(
                            right: loc != _locationOptions.last ? 8 : 0,
                          ),
                          padding: responsive.padding(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary05 : Colors.white,
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12),
                            ),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.gray300,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                loc == 'Indoor'
                                    ? Icons.home_rounded
                                    : loc == 'Outdoor'
                                        ? Icons.park_rounded
                                        : Icons.sync_alt_rounded,
                                color: isSelected ? AppColors.primary : AppColors.gray600,
                                size: responsive.iconSize(22),
                              ),
                              SizedBox(height: responsive.hp(0.5)),
                              Text(
                                loc,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                responsive.heightBox(20),

                // Power Type
                Text(
                  'Power Type',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(12),
                Row(
                  children: _powerTypeOptions.map((power) {
                    final isSelected = _selectedPowerType == power;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPowerType = power),
                        child: Container(
                          margin: responsive.padding(
                            right: power != _powerTypeOptions.last ? 8 : 0,
                          ),
                          padding: responsive.padding(vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary05 : Colors.white,
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12),
                            ),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.gray300,
                              width: isSelected ? 1.5 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                power == 'Wired'
                                    ? Icons.electrical_services_rounded
                                    : power == 'Battery'
                                        ? Icons.battery_charging_full_rounded
                                        : Icons.solar_power_rounded,
                                color: isSelected ? AppColors.primary : AppColors.gray600,
                                size: responsive.iconSize(22),
                              ),
                              SizedBox(height: responsive.hp(0.5)),
                              Text(
                                power,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13),
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                responsive.heightBox(40),
              ],
            ),
          ),
        ),
        BookingContinueButton(
          isValid: _isValid,
          onPressed: () {
            widget.formData.selectedItems[widget.deviceName] = _quantity;
            widget.formData.deviceBrand = _selectedLocation;
            widget.formData.paintType = _selectedPowerType;
            widget.onNext();
          },
        ),
      ],
    );
  }

  Widget _buildQuantityButton(
    ResponsiveUtils responsive, {
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: responsive.wp(11),
        height: responsive.wp(11),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.primary, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: AppColors.primary, size: responsive.iconSize(20)),
      ),
    );
  }
}
