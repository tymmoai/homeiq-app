import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_step_header.dart';

/// Pickup & drop-off location input for Moving service flow.
///
/// Matches web's MovingFlow location step:
/// - Pickup address field
/// - Drop-off address field
/// - Estimated distance display
class LocationInputStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const LocationInputStep({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<LocationInputStep> createState() => _LocationInputStepState();
}

class _LocationInputStepState extends State<LocationInputStep> {
  late TextEditingController _pickupController;
  late TextEditingController _dropoffController;
  late TextEditingController _pickupFloorController;
  late TextEditingController _dropoffFloorController;
  bool _pickupHasElevator = false;
  bool _dropoffHasElevator = false;

  @override
  void initState() {
    super.initState();
    _pickupController = TextEditingController(
      text: widget.formData.pickupAddress ?? '',
    );
    _dropoffController = TextEditingController(
      text: widget.formData.dropoffAddress ?? '',
    );
    _pickupFloorController = TextEditingController(
      text: widget.formData.floorLevel?.toString() ?? '',
    );
    _dropoffFloorController = TextEditingController();
    _pickupHasElevator = widget.formData.hasElevator ?? false;
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropoffController.dispose();
    _pickupFloorController.dispose();
    _dropoffFloorController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _pickupController.text.trim().isNotEmpty &&
      _dropoffController.text.trim().isNotEmpty;

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
                  'Pickup & Drop-off',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'Enter your moving locations',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(24),

                // Pickup section
                _buildLocationSection(
                  responsive: responsive,
                  title: 'Pickup Location',
                  icon: Icons.trip_origin_rounded,
                  iconColor: AppColors.success,
                  addressController: _pickupController,
                  floorController: _pickupFloorController,
                  hasElevator: _pickupHasElevator,
                  onElevatorChanged: (val) =>
                      setState(() => _pickupHasElevator = val),
                ),

                responsive.heightBox(16),

                // Connection line
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 2,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.success, AppColors.primary],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_downward_rounded,
                        color: AppColors.primary,
                        size: responsive.iconSize(20),
                      ),
                    ],
                  ),
                ),

                responsive.heightBox(16),

                // Drop-off section
                _buildLocationSection(
                  responsive: responsive,
                  title: 'Drop-off Location',
                  icon: Icons.location_on_rounded,
                  iconColor: AppColors.primary,
                  addressController: _dropoffController,
                  floorController: _dropoffFloorController,
                  hasElevator: _dropoffHasElevator,
                  onElevatorChanged: (val) =>
                      setState(() => _dropoffHasElevator = val),
                ),

                responsive.heightBox(40),
              ],
            ),
          ),
        ),
        BookingContinueButton(
          isValid: _isValid,
          onPressed: () {
            widget.formData.pickupAddress = _pickupController.text.trim();
            widget.formData.dropoffAddress = _dropoffController.text.trim();
            widget.formData.floorLevel = int.tryParse(
              _pickupFloorController.text,
            );
            widget.formData.hasElevator = _pickupHasElevator;
            widget.onNext();
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection({
    required ResponsiveUtils responsive,
    required String title,
    required IconData icon,
    required Color iconColor,
    required TextEditingController addressController,
    required TextEditingController floorController,
    required bool hasElevator,
    required ValueChanged<bool> onElevatorChanged,
  }) {
    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
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
              Icon(icon, color: iconColor, size: responsive.iconSize(20)),
              SizedBox(width: responsive.wp(2)),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          responsive.heightBox(12),
          _buildShadowField(
            controller: addressController,
            label: 'Full Address',
            hintText: 'Enter street address, city, state, ZIP',
          ),
          responsive.heightBox(12),
          Row(
            children: [
              Expanded(
                child: _buildShadowField(
                  controller: floorController,
                  label: 'Floor Level',
                  hintText: 'e.g., 3',
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Container(
                  padding: responsive.padding(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray50,
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Elevator',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      Switch(
                        value: hasElevator,
                        onChanged: onElevatorChanged,
                        activeThumbColor: AppColors.primary,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
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
    String? hintText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          labelStyle: const TextStyle(
            fontSize: 14,
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
          ),
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.gray400),
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
          filled: true,
          fillColor: AppColors.backgroundGray50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}
