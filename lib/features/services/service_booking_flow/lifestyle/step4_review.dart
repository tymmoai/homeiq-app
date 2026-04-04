import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../services/user_service.dart';
import '../../../../utils/responsive_utils.dart';
import './lifestyle_booking_flow.dart';

class LifestyleStep4Review extends StatefulWidget {
  final LifestyleBookingFormData formData;
  final String categoryName;
  final int totalSteps;
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LifestyleStep4Review({
    super.key,
    required this.formData,
    required this.categoryName,
    required this.totalSteps,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LifestyleStep4Review> createState() => _LifestyleStep4ReviewState();
}

class _LifestyleStep4ReviewState extends State<LifestyleStep4Review> {
  bool _acceptTerms = false;
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final userService = UserService.instance;

    _nameController = TextEditingController(
      text: widget.formData.customerName ?? userService.getUserName(),
    );
    _emailController = TextEditingController(
      text: widget.formData.customerEmail ?? userService.getUserEmail(),
    );
    _phoneController = TextEditingController(
      text: widget.formData.customerPhone ?? userService.getUserPhone(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: responsive.padding(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Booking',
                    style: TextStyle(
                      fontSize: responsive.fontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  Text(
                    'Confirm your booking details',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  _buildServiceDetailsCard(),
                  SizedBox(height: responsive.spacing(16)),
                  _buildScheduleCard(),
                  SizedBox(height: responsive.spacing(16)),
                  _buildContactCard(),
                  SizedBox(height: responsive.spacing(16)),
                  _buildPriceCard(),
                  SizedBox(height: responsive.spacing(16)),
                  _buildTermsCheckbox(),
                  SizedBox(height: responsive.spacing(100)),
                ],
              ),
            ),
          ),
        ),
        _buildConfirmButton(),
      ],
    );
  }

  Widget _buildServiceDetailsCard() {
    return _buildCard(
      title: 'Service Details',
      children: [
        _buildDetailRow('Service Type', widget.formData.selectedService ?? ''),
        const Divider(height: 24),
        ..._buildServiceSpecificDetails(),
      ],
    );
  }

  List<Widget> _buildServiceSpecificDetails() {
    switch (widget.formData.selectedService) {
      case 'Cab Booking':
        return [
          _buildDetailRow('Pickup', widget.formData.pickupLocation ?? ''),
          const Divider(height: 24),
          _buildDetailRow('Drop', widget.formData.dropLocation ?? ''),
          const Divider(height: 24),
          _buildDetailRow('Vehicle Type', widget.formData.vehicleType ?? ''),
          if (widget.formData.estimatedDistance != null) ...[
            const Divider(height: 24),
            _buildDetailRow(
              'Distance',
              '${widget.formData.estimatedDistance!.toStringAsFixed(1)} km',
            ),
          ],
        ];
      case 'Restaurant Reservations':
        return [
          _buildDetailRow(
            'Restaurant Type',
            widget.formData.restaurantType ?? '',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Party Size',
            '${widget.formData.partySize ?? 0} people',
          ),
          if (widget.formData.seatingPreference != null) ...[
            const Divider(height: 24),
            _buildDetailRow('Seating', widget.formData.seatingPreference!),
          ],
        ];
      case 'Hotel Booking':
        return [
          _buildDetailRow('Hotel Type', widget.formData.hotelType ?? ''),
          const Divider(height: 24),
          _buildDetailRow('Room Type', widget.formData.roomType ?? ''),
          const Divider(height: 24),
          _buildDetailRow('Rooms', '${widget.formData.numberOfRooms ?? 1}'),
          const Divider(height: 24),
          _buildDetailRow('Guests', '${widget.formData.numberOfGuests ?? 2}'),
        ];
      case 'Healthcare Appointments':
        return [
          _buildDetailRow(
            'Appointment Type',
            widget.formData.appointmentType ?? '',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Specialization',
            widget.formData.doctorSpecialization ?? '',
          ),
          const Divider(height: 24),
          _buildDetailRow(
            'Consultation',
            widget.formData.consultationType ?? '',
          ),
          if (widget.formData.healthConcern != null &&
              widget.formData.healthConcern!.isNotEmpty) ...[
            const Divider(height: 24),
            _buildDetailRow('Health Concern', widget.formData.healthConcern!),
          ],
        ];
      default:
        return [];
    }
  }

  Widget _buildScheduleCard() {
    return _buildCard(
      title: 'Schedule',
      children: [
        _buildDetailRow(
          'Date',
          widget.formData.selectedDate != null
              ? DateFormat(
                  'EEEE, MMMM d, yyyy',
                ).format(widget.formData.selectedDate!)
              : '',
        ),
        const Divider(height: 24),
        _buildDetailRow('Time', widget.formData.selectedTimeSlot ?? ''),
      ],
    );
  }

  Widget _buildContactCard() {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(
          responsive.borderRadius(12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildTextField(
                  controller: _nameController,
                  label: 'Full Name',
                  hint: 'Enter your name',
                  icon: Icons.person_outline,
                  onChanged: (value) => widget.formData.customerName = value,
                ),
                const SizedBox(height: 16),
                _buildPhoneField(),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email (Optional)',
                  hint: 'Enter your email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => widget.formData.customerEmail = value,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Phone Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
            _USPhoneNumberFormatter(),
          ],
          onChanged: (value) {
            widget.formData.customerPhone = value;
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Phone number is required';
            }
            final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
            if (digitsOnly.length != 10) {
              return 'Please enter a valid 10-digit US phone number';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: '(555) 123-4567',
            hintStyle: TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(
              Icons.phone_outlined,
              color: AppColors.textSecondary,
            ),
            filled: true,
            fillColor: AppColors.backgroundGray50,
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
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textHint),
            prefixIcon: Icon(icon, color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.backgroundGray50,
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
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard() {
    final totalPrice = widget.formData.totalPrice;

    return _buildCard(
      title: 'Price Summary',
      children: [
        _buildDetailRow('Service Charge', '\$${totalPrice.toStringAsFixed(2)}'),
        const Divider(height: 24),
        _buildDetailRow(
          'Taxes & Fees',
          '\$${(totalPrice * 0.1).toStringAsFixed(2)}',
        ),
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total Amount',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '\$${(totalPrice * 1.1).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCard({required String title, required List<Widget> children}) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTermsCheckbox() {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(
          responsive.borderRadius(12),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value ?? false;
                });
              },
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'I accept the terms and conditions, cancellation policy, and privacy policy',
              style: TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  bool _canContinue() {
    return _acceptTerms &&
        _nameController.text.trim().isNotEmpty &&
        _phoneController.text.trim().isNotEmpty;
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMinimalStepper(widget.currentStep),
            ),
          ),
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(int currentStep) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(widget.totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isCurrent = stepNumber == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isCurrent
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (index < widget.totalSteps - 1) const SizedBox(width: 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildConfirmButton() {
    final bool canContinue = _canContinue();
    final responsive = ResponsiveUtils(context);

    return Container(
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(-2.0)),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canContinue
                ? () {
                    // Save user profile data before proceeding
                    widget.formData.customerName = _nameController.text;
                    widget.formData.customerEmail = _emailController.text;
                    widget.formData.customerPhone = _phoneController.text;

                    // Update user profile with any changes made during booking
                    final userService = UserService.instance;
                    userService.updateUserData({
                      'name': _nameController.text,
                      'email': _emailController.text,
                      'phone': _phoneController.text,
                    });

                    widget.onNext();
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: const Text(
              'Confirm & Book',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

// US Phone Number Formatter
class _USPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;
    if (text.isEmpty) {
      return newValue;
    }

    // Get only digits
    final digitsOnly = text.replaceAll(RegExp(r'\D'), '');

    // Limit to 10 digits
    if (digitsOnly.length > 10) {
      return oldValue;
    }

    // Format as (XXX) XXX-XXXX
    final buffer = StringBuffer();
    if (digitsOnly.isNotEmpty) {
      if (digitsOnly.length <= 3) {
        buffer.write('(${digitsOnly.substring(0, digitsOnly.length)}');
      } else if (digitsOnly.length <= 6) {
        buffer.write(
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}',
        );
      } else {
        buffer.write(
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}',
        );
      }
    }

    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}