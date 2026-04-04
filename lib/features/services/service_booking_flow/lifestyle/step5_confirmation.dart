import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../services/services/booking_service.dart';
import './lifestyle_booking_flow.dart';

class LifestyleConfirmationScreen extends StatefulWidget {
  final LifestyleBookingFormData formData;
  final VoidCallback onDone;

  const LifestyleConfirmationScreen({
    super.key,
    required this.formData,
    required this.onDone,
  });

  @override
  State<LifestyleConfirmationScreen> createState() => _LifestyleConfirmationScreenState();
}

class _LifestyleConfirmationScreenState extends State<LifestyleConfirmationScreen> {
  @override
  void initState() {
    super.initState();
    _saveBooking();
  }

  Future<void> _saveBooking() async {
    final formData = widget.formData;
    await BookingService.saveLifestyleBooking(
      serviceType: formData.selectedService ?? 'Lifestyle',
      serviceName: formData.selectedService ?? 'Lifestyle Service',
      scheduledDate: formData.selectedDate ?? DateTime.now(),
      scheduledTime: formData.selectedTimeSlot ?? '',
      total: formData.totalPrice,
      bookingId: formData.bookingId,
      contactName: formData.customerName,
      contactPhone: formData.customerPhone,
      address: formData.serviceAddress,
      specialRequirements: formData.specialRequirements,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  _buildSuccessIcon(context),
                  const SizedBox(height: 24),
                  Text(
                    'Booking Confirmed!',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your ${widget.formData.selectedService?.toLowerCase()} has been successfully booked',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildBookingIdCard(context),
                  const SizedBox(height: 16),
                  _buildBookingDetailsCard(),
                  const SizedBox(height: 16),
                  _buildNextStepsCard(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ),
        _buildDoneButton(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: widget.onDone,
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

  Widget _buildSuccessIcon(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      width: responsive.spacing(80.0),
      height: responsive.spacing(80.0),
      decoration: const BoxDecoration(
        color: AppColors.success,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        size: responsive.iconSize(48.0),
        color: AppColors.white,
      ),
    );
  }

  Widget _buildBookingIdCard(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final bookingId = 'LIF${DateTime.now().millisecondsSinceEpoch % 1000000}';

    return Container(
      width: double.infinity,
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(16)),
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
          Row(
            children: [
              Container(
                width: responsive.spacing(44.0),
                height: responsive.spacing(44.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(12.0),
                  ),
                ),
                child: Icon(
                  Icons.confirmation_number,
                  color: AppColors.primary,
                  size: responsive.iconSize(24.0),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking ID',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bookingId,
                      style: TextStyle(
                        fontSize: responsive.fontSize(18),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetailsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.category,
            'Service',
            widget.formData.selectedService ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.calendar_today,
            'Date',
            widget.formData.selectedDate != null
                ? DateFormat('EEEE, MMM d, yyyy').format(widget.formData.selectedDate!)
                : '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time,
            'Time',
            widget.formData.selectedTimeSlot ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.person, 'Name', widget.formData.customerName ?? ''),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.phone, 'Phone', widget.formData.customerPhone ?? ''),
          ..._buildServiceSpecificDetails(),
        ],
      ),
    );
  }

  List<Widget> _buildServiceSpecificDetails() {
    switch (widget.formData.selectedService) {
      case 'Cab Booking':
        return [
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.my_location,
            'Pickup',
            widget.formData.pickupLocation ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.location_on,
            'Drop',
            widget.formData.dropLocation ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.directions_car,
            'Vehicle',
            widget.formData.vehicleType ?? '',
          ),
        ];
      case 'Restaurant Reservations':
        return [
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.restaurant,
            'Type',
            widget.formData.restaurantType ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.people,
            'Party Size',
            '${widget.formData.partySize ?? 0} people',
          ),
        ];
      case 'Hotel Booking':
        return [
          const SizedBox(height: 12),
          _buildDetailRow(Icons.hotel, 'Hotel Type', widget.formData.hotelType ?? ''),
          const SizedBox(height: 12),
          _buildDetailRow(Icons.king_bed, 'Room Type', widget.formData.roomType ?? ''),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.door_front_door,
            'Rooms',
            '${widget.formData.numberOfRooms ?? 1} room(s)',
          ),
        ];
      case 'Healthcare Appointments':
        return [
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.medical_services,
            'Type',
            widget.formData.appointmentType ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.local_hospital,
            'Specialization',
            widget.formData.doctorSpecialization ?? '',
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.video_call,
            'Consultation',
            widget.formData.consultationType ?? '',
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.textSecondary),
        const SizedBox(width: 12),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildNextStepsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
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
          Text(
            'What\'s Next?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildNextStep(
            '1',
            'Confirmation Sent',
            'A confirmation email/SMS has been sent to your contact',
          ),
          const SizedBox(height: 12),
          _buildNextStep(
            '2',
            'Service Provider Contact',
            'The service provider will contact you shortly to confirm details',
          ),
          const SizedBox(height: 12),
          _buildNextStep(
            '3',
            'Prepare for Service',
            'Be ready at the scheduled time. You can track your booking in the app',
          ),
        ],
      ),
    );
  }

  Widget _buildNextStep(String number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDoneButton() {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => context.push('/service-history'),
                icon: const Icon(Icons.history, size: 20),
                label: const Text(
                  'View My Bookings',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: widget.onDone,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  elevation: 0,
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}