import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_shadows.dart';
import '../../../../utils/responsive_utils.dart';
import './lifestyle_booking_flow.dart';

class LifestyleStep2ServiceDetails extends StatefulWidget {
  final LifestyleBookingFormData formData;
  final String categoryName;
  final int totalSteps;
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const LifestyleStep2ServiceDetails({
    super.key,
    required this.formData,
    required this.categoryName,
    required this.totalSteps,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<LifestyleStep2ServiceDetails> createState() =>
      _LifestyleStep2ServiceDetailsState();
}

class _LifestyleStep2ServiceDetailsState
    extends State<LifestyleStep2ServiceDetails> {
  final _pickupController = TextEditingController();
  final _dropController = TextEditingController();
  final _specialReqController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _pickupController.text = widget.formData.pickupLocation ?? '';
    _dropController.text = widget.formData.dropLocation ?? '';
    _specialReqController.text = widget.formData.specialRequirements ?? '';
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _dropController.dispose();
    _specialReqController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.formData.selectedService ?? 'Service Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Provide service details',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildServiceSpecificForm(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildServiceSpecificForm() {
    switch (widget.formData.selectedService) {
      case 'Cab Booking':
        return _buildCabBookingForm();
      case 'Restaurant Reservations':
        return _buildRestaurantForm();
      case 'Hotel Booking':
        return _buildHotelForm();
      case 'Healthcare Appointments':
        return _buildHealthcareForm();
      default:
        return const SizedBox();
    }
  }

  Widget _buildCabBookingForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ride Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pickupController,
          label: 'Pickup Location',
          hint: 'Enter pickup address',
          icon: Icons.my_location_outlined,
          onChanged: (value) => widget.formData.pickupLocation = value,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _dropController,
          label: 'Drop Location',
          hint: 'Enter destination address',
          icon: Icons.location_on_outlined,
          onChanged: (value) {
            widget.formData.dropLocation = value;
            _calculateFare();
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Select Vehicle Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildVehicleOptions(),
      ],
    );
  }

  Widget _buildVehicleOptions() {
    final responsive = ResponsiveUtils(context);
    final vehicles = [
      {
        'type': 'Mini',
        'capacity': '4 seats',
        'price': 50.0,
        'icon': Icons.directions_car_outlined,
      },
      {
        'type': 'Sedan',
        'capacity': '4 seats',
        'price': 75.0,
        'icon': Icons.directions_car_outlined,
      },
      {
        'type': 'SUV',
        'capacity': '6 seats',
        'price': 100.0,
        'icon': Icons.airport_shuttle_outlined,
      },
      {
        'type': 'Premium',
        'capacity': '4 seats',
        'price': 150.0,
        'icon': Icons.electric_car_outlined,
      },
    ];

    return Column(
      children: vehicles.map((vehicle) {
        final isSelected = widget.formData.vehicleType == vehicle['type'];
        return Padding(
          padding: EdgeInsets.only(bottom: responsive.spacing(12)),
          child: GestureDetector(
            onTap: () {
              setState(() {
                widget.formData.vehicleType = vehicle['type'] as String;
                widget.formData.estimatedFare = vehicle['price'] as double;
                widget.formData.totalPrice = vehicle['price'] as double;
              });
            },
            child: Container(
              padding: responsive.padding(all: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary05 : AppColors.white,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12),
                ),
                border: isSelected
                    ? Border.all(color: AppColors.primary, width: 2)
                    : null,
                boxShadow: isSelected
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: responsive.spacing(8.0),
                          offset: Offset(0, responsive.spacing(2.0)),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Icon(
                    vehicle['icon'] as IconData,
                    size: responsive.iconSize(32),
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textPrimary,
                  ),
                  SizedBox(width: responsive.spacing(16)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle['type'] as String,
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          vehicle['capacity'] as String,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${(vehicle['price'] as double).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRestaurantForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Restaurant Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.restaurantType,
          items: [
            'Fine Dining',
            'Casual Dining',
            'Fast Food',
            'Café',
            'Bar & Grill',
          ],
          onChanged: (value) {
            setState(() {
              widget.formData.restaurantType = value;
              _calculateRestaurantPrice();
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Party Size',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildCompactNumberSelector(
          label: 'Number of People',
          value: widget.formData.partySize ?? 2,
          min: 1,
          max: 20,
          onChanged: (value) {
            setState(() {
              widget.formData.partySize = value;
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Seating Preference',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.seatingPreference,
          items: [
            'Indoor',
            'Outdoor',
            'Private Room',
            'Window Seat',
            'No Preference',
          ],
          onChanged: (value) {
            setState(() {
              widget.formData.seatingPreference = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHotelForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hotel Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.hotelType,
          items: [
            'Budget Hotel',
            'Business Hotel',
            '4-Star Hotel',
            '5-Star Hotel',
            'Resort',
          ],
          onChanged: (value) {
            setState(() {
              widget.formData.hotelType = value;
              _calculateHotelPrice();
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Room Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.roomType,
          items: [
            'Standard Room',
            'Deluxe Room',
            'Suite',
            'Executive Suite',
            'Presidential Suite',
          ],
          onChanged: (value) {
            setState(() {
              widget.formData.roomType = value;
              _calculateHotelPrice();
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Room & Guest Details',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildCompactNumberSelector(
          label: 'Number of Rooms',
          value: widget.formData.numberOfRooms ?? 1,
          min: 1,
          max: 10,
          onChanged: (value) {
            setState(() {
              widget.formData.numberOfRooms = value;
              _calculateHotelPrice();
            });
          },
        ),
        const SizedBox(height: 12),
        _buildCompactNumberSelector(
          label: 'Number of Guests',
          value: widget.formData.numberOfGuests ?? 2,
          min: 1,
          max: 20,
          onChanged: (value) {
            setState(() {
              widget.formData.numberOfGuests = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildHealthcareForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appointment Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.appointmentType,
          items: [
            'General Checkup',
            'Specialist Consultation',
            'Follow-up',
            'Emergency',
          ],
          onChanged: (value) {
            setState(() {
              widget.formData.appointmentType = value;
              _calculateHealthcarePrice();
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Doctor Specialization',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.doctorSpecialization,
          items: [
            'General Physician',
            'Cardiologist',
            'Dermatologist',
            'Orthopedic',
            'ENT',
            'Dentist',
          ],
          onChanged: (value) {
            setState(() {
              widget.formData.doctorSpecialization = value;
              _calculateHealthcarePrice();
            });
          },
        ),
        const SizedBox(height: 20),
        Text(
          'Consultation Type',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        _buildOptionGrid(
          value: widget.formData.consultationType,
          items: ['In-person', 'Video Call', 'Phone Call'],
          onChanged: (value) {
            setState(() {
              widget.formData.consultationType = value;
              _calculateHealthcarePrice();
            });
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _specialReqController,
          label: 'Health Concern (Optional)',
          hint: 'Describe your symptoms or reason for visit',
          icon: Icons.note_alt_outlined,
          maxLines: 3,
          onChanged: (value) => widget.formData.healthConcern = value,
        ),
      ],
    );
  }

  Widget _buildOptionGrid({
    required String? value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    final responsive = ResponsiveUtils(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final isSelected = value == item;
        return GestureDetector(
          onTap: () => onChanged(item),
          child: Container(
            padding: responsive.padding(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary05 : AppColors.white,
              borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: isSelected
                  ? null
                  : [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: responsive.spacing(8.0),
                        offset: Offset(0, responsive.spacing(2.0)),
                      ),
                    ],
            ),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
            boxShadow: AppShadows.standard,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: AppColors.textHint,
                fontSize: responsive.fontSize(14),
              ),
              prefixIcon: Icon(
                icon,
                color: AppColors.textSecondary,
                size: responsive.iconSize(20),
              ),
              filled: true,
              fillColor: AppColors.transparent,
              contentPadding: responsive.padding(horizontal: 16, vertical: 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
            style: TextStyle(fontSize: responsive.fontSize(14)),
          ),
        ),
      ],
    );
  }

  /// A cleaner, compact number selector with -/+ buttons
  Widget _buildCompactNumberSelector({
    required String label,
    required int value,
    required int min,
    required int max,
    required Function(int) onChanged,
  }) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: responsive.padding(horizontal: 16, vertical: 14),
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
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary05,
              borderRadius: BorderRadius.circular(responsive.borderRadius(10)),
              border: Border.all(color: AppColors.primary20, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: value > min ? () => onChanged(value - 1) : null,
                  child: Container(
                    width: responsive.spacing(36),
                    height: responsive.spacing(36),
                    decoration: BoxDecoration(
                      color: value > min
                          ? AppColors.primary
                          : AppColors.gray300,
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(responsive.borderRadius(8)),
                      ),
                    ),
                    child: Icon(
                      Icons.remove,
                      size: responsive.iconSize(18),
                      color: AppColors.white,
                    ),
                  ),
                ),
                Container(
                  width: responsive.spacing(52),
                  height: responsive.spacing(36),
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: AppColors.white),
                  child: Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: value < max ? () => onChanged(value + 1) : null,
                  child: Container(
                    width: responsive.spacing(36),
                    height: responsive.spacing(36),
                    decoration: BoxDecoration(
                      color: value < max
                          ? AppColors.primary
                          : AppColors.gray300,
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(responsive.borderRadius(8)),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      size: responsive.iconSize(18),
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _calculateFare() {
    if (widget.formData.pickupLocation != null &&
        widget.formData.dropLocation != null &&
        widget.formData.vehicleType != null) {
      // Mock calculation
      setState(() {
        widget.formData.estimatedDistance =
            5.0 + (widget.formData.dropLocation!.length % 10);
      });
    }
  }

  void _calculateRestaurantPrice() {
    double basePrice = 0;
    switch (widget.formData.restaurantType) {
      case 'Fine Dining':
        basePrice = 100;
        break;
      case 'Casual Dining':
        basePrice = 50;
        break;
      case 'Fast Food':
        basePrice = 20;
        break;
      case 'Café':
        basePrice = 30;
        break;
      case 'Bar & Grill':
        basePrice = 60;
        break;
    }
    widget.formData.totalPrice = basePrice;
  }

  void _calculateHotelPrice() {
    double basePrice = 100;
    if (widget.formData.hotelType == '5-Star Hotel' ||
        widget.formData.hotelType == 'Resort') {
      basePrice = 300;
    } else if (widget.formData.hotelType == '4-Star Hotel' ||
        widget.formData.hotelType == 'Business Hotel') {
      basePrice = 150;
    }

    if (widget.formData.roomType == 'Suite' ||
        widget.formData.roomType == 'Executive Suite') {
      basePrice *= 1.5;
    } else if (widget.formData.roomType == 'Presidential Suite') {
      basePrice *= 3;
    }

    basePrice *= (widget.formData.numberOfRooms ?? 1);
    widget.formData.totalPrice = basePrice;
  }

  void _calculateHealthcarePrice() {
    double basePrice = 50;

    if (widget.formData.doctorSpecialization == 'Cardiologist' ||
        widget.formData.doctorSpecialization == 'Dermatologist') {
      basePrice = 150;
    } else if (widget.formData.doctorSpecialization == 'Orthopedic') {
      basePrice = 120;
    }

    if (widget.formData.consultationType == 'Video Call') {
      basePrice *= 0.8;
    } else if (widget.formData.consultationType == 'Phone Call') {
      basePrice *= 0.6;
    }

    widget.formData.totalPrice = basePrice;
  }

  bool _canContinue() {
    switch (widget.formData.selectedService) {
      case 'Cab Booking':
        return widget.formData.pickupLocation != null &&
            widget.formData.dropLocation != null &&
            widget.formData.vehicleType != null;
      case 'Restaurant Reservations':
        return widget.formData.restaurantType != null &&
            widget.formData.partySize != null;
      case 'Hotel Booking':
        return widget.formData.hotelType != null &&
            widget.formData.roomType != null;
      case 'Healthcare Appointments':
        return widget.formData.appointmentType != null &&
            widget.formData.doctorSpecialization != null &&
            widget.formData.consultationType != null;
      default:
        return false;
    }
  }

  Widget _buildHeader() {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: responsive.padding(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.arrow_back_outlined,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
            ),
          ),
          Expanded(
            child: Padding(
              padding: responsive.padding(horizontal: 16),
              child: _buildMinimalStepper(widget.currentStep),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close_outlined,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
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

  Widget _buildContinueButton() {
    final bool canContinue = _canContinue();

    return Container(
      padding: const EdgeInsets.all(20),
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
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: canContinue ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: AppColors.white,
              elevation: 0,
            ),
            child: const Text(
              'Continue',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}