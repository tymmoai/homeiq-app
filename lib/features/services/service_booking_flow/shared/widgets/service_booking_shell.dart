import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/constants/app_colors.dart';
import '../models/service_booking_form_data.dart';

/// A generic service booking flow shell that manages step navigation,
/// back button handling, and the Scaffold/SafeArea wrapper.
///
/// Usage:
/// ```dart
/// ServiceBookingShell(
///   categoryName: 'Assembly',
///   totalSteps: 4,
///   formData: _formData,
///   bookingIdPrefix: 'BK',
///   stepBuilder: (step, formData, onNext, onBack, onClose) {
///     switch (step) {
///       case 1: return MyStep1(...);
///       case 2: return MyStep2(...);
///       ...
///     }
///   },
/// )
/// ```
class ServiceBookingShell extends StatefulWidget {
  final String categoryName;
  final int totalSteps;
  final ServiceBookingFormData formData;
  final String bookingIdPrefix;

  /// Builder that returns the widget for the current step.
  ///
  /// Parameters:
  /// - [currentStep]: Current step number (1-based)
  /// - [formData]: The shared mutable form data
  /// - [onNext]: Call to advance to the next step
  /// - [onBack]: Call to go back one step
  /// - [onClose]: Call to close the entire flow
  final Widget Function(
    int currentStep,
    ServiceBookingFormData formData,
    VoidCallback onNext,
    VoidCallback onBack,
    VoidCallback onClose,
  ) stepBuilder;

  const ServiceBookingShell({
    super.key,
    required this.categoryName,
    required this.totalSteps,
    required this.formData,
    required this.bookingIdPrefix,
    required this.stepBuilder,
  });

  @override
  State<ServiceBookingShell> createState() => _ServiceBookingShellState();
}

class _ServiceBookingShellState extends State<ServiceBookingShell> {
  int _currentStep = 1;

  void _goToNextStep() {
    if (_currentStep < widget.totalSteps + 1) {
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

  void _onBookingComplete() {
    // Generate booking ID with the service-specific prefix
    final now = DateTime.now();
    widget.formData.bookingId =
        '${widget.bookingIdPrefix}${now.millisecondsSinceEpoch.toString().substring(7)}';
    setState(() {
      _currentStep = widget.totalSteps + 1; // Go to confirmation step
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
        body: SafeArea(
          child: widget.stepBuilder(
            _currentStep,
            widget.formData,
            // For the second-to-last step (review), use _onBookingComplete
            _currentStep == widget.totalSteps ? _onBookingComplete : _goToNextStep,
            _goToPreviousStep,
            _closeFlow,
          ),
        ),
      ),
    );
  }
}
