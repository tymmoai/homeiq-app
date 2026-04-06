import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import './step2_service_details.dart';
import './step3_schedule.dart';
import './step4_review.dart';
import './step5_confirmation.dart';

/// Lifestyle booking form data model
class LifestyleBookingFormData {
  String? selectedService;
  String? serviceIcon;

  // Empty serviceItems for compatibility with main service booking step1
  static final Map<String, List<Map<String, dynamic>>> serviceItems = {};

  // Cab Booking specific
  String? pickupLocation;
  String? dropLocation;
  String? vehicleType;
  double? estimatedFare;
  double? estimatedDistance;

  // Restaurant Reservation specific
  String? restaurantType;
  int? partySize;
  String? seatingPreference;
  String? mealType;

  // Hotel Booking specific
  String? hotelType;
  String? roomType;
  int? numberOfRooms;
  int? numberOfGuests;
  DateTime? checkOutDate;

  // Healthcare Appointments specific
  String? appointmentType;
  String? doctorSpecialization;
  String? consultationType;
  String? healthConcern;

  // Common fields
  String? specialRequirements;
  DateTime? selectedDate;
  String? selectedTimeSlot;
  bool termsAccepted = false;
  String? bookingId;
  double totalPrice = 0.0;

  // Contact information
  String? customerName;
  String? customerEmail;
  String? customerPhone;

  // Service address (for some services)
  String? serviceAddress;
  String? serviceCity;
  String? serviceState;
  String? serviceZipCode;

  void clearServiceSpecificData() {
    // Cab Booking
    pickupLocation = null;
    dropLocation = null;
    vehicleType = null;
    estimatedFare = null;
    estimatedDistance = null;

    // Restaurant
    restaurantType = null;
    partySize = null;
    seatingPreference = null;
    mealType = null;

    // Hotel
    hotelType = null;
    roomType = null;
    numberOfRooms = null;
    numberOfGuests = null;
    checkOutDate = null;

    // Healthcare
    appointmentType = null;
    doctorSpecialization = null;
    consultationType = null;
    healthConcern = null;

    specialRequirements = null;
    totalPrice = 0.0;
  }
}

class LifestyleBookingFlow extends StatefulWidget {
  final String categoryName;
  final String? preSelectedService;

  const LifestyleBookingFlow({
    super.key,
    required this.categoryName,
    this.preSelectedService,
  });

  @override
  State<LifestyleBookingFlow> createState() => _LifestyleBookingFlowState();
}

class _LifestyleBookingFlowState extends State<LifestyleBookingFlow> {
  final LifestyleBookingFormData _formData = LifestyleBookingFormData();
  int _currentStep = 1;
  final int _totalSteps = 3;

  @override
  void initState() {
    super.initState();
    // Service must be pre-selected, set it in form data
    if (widget.preSelectedService != null) {
      _formData.selectedService = widget.preSelectedService;
    }
  }

  void _goToNextStep() {
    if (_currentStep < _totalSteps + 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      _closeFlow();
    }
  }

  void _onStepComplete() {
    _goToNextStep();
  }

  void _onBookingComplete() {
    _formData.bookingId =
        'LST${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      _currentStep = 4;
    });
  }

  void _closeFlow() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 1) {
          _goToPreviousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray50,
        body: SafeArea(child: _buildCurrentStep()),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return LifestyleStep2ServiceDetails(
          formData: _formData,
          categoryName: widget.categoryName,
          totalSteps: _totalSteps,
          currentStep: _currentStep,
          onNext: _onStepComplete,
          onBack: _goToPreviousStep,
        );
      case 2:
        return LifestyleStep3Schedule(
          formData: _formData,
          categoryName: widget.categoryName,
          totalSteps: _totalSteps,
          currentStep: _currentStep,
          onNext: _onStepComplete,
          onBack: _goToPreviousStep,
        );
      case 3:
        return LifestyleStep4Review(
          formData: _formData,
          categoryName: widget.categoryName,
          totalSteps: _totalSteps,
          currentStep: _currentStep,
          onNext: _onBookingComplete,
          onBack: _goToPreviousStep,
        );
      case 4:
        return LifestyleConfirmationScreen(
          formData: _formData,
          onDone: _closeFlow,
        );
      default:
        return Container();
    }
  }
}
