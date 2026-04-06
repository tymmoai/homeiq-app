import 'package:flutter/material.dart';
import '../shared/data/mounting_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Mounting service booking flow (complete — matches web).
///
/// Steps: Select Type → Select Items → Add-ons → Wall Type → Schedule → Address → Review → Payment → Confirmation
///
/// 8 interactive steps + 1 confirmation screen = 9 screens total.
class MountingBookingFlow extends StatelessWidget {
  final String categoryName;

  const MountingBookingFlow({super.key, this.categoryName = 'Mounting'});

  /// Duration per item (minutes) based on selected sub-category.
  /// Used to calculate "Estimated Duration" on the Schedule step.
  static int _durationPerItem(String subcategory) {
    switch (subcategory) {
      case 'TV Wall Mounting':
        return 45;
      case 'Picture & Frame Mounting':
        return 15;
      case 'Mirror Mounting':
        return 30;
      case 'Shelf Mounting':
        return 25;
      case 'Curtain & Blinds Installation':
        return 30;
      case 'Kitchen Cabinet Mounting':
        return 60;
      default:
        return 30;
    }
  }

  /// Calculate total estimated duration string from form data.
  static String _estimatedDuration(ServiceBookingFormData formData) {
    final subcategory = formData.selectedService ?? '';
    final perItem = _durationPerItem(subcategory);
    int totalItems = 0;
    formData.selectedItems.forEach((_, qty) => totalItems += qty);
    if (totalItems == 0) totalItems = 1;
    final totalMinutes = perItem * totalItems;
    if (totalMinutes >= 60) {
      final hours = totalMinutes ~/ 60;
      final mins = totalMinutes % 60;
      if (mins == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'} $mins min';
    }
    return '$totalMinutes min';
  }

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 8,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: MountingServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = MountingServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => MountingServiceData.categories.first,
        );

        switch (step) {
          // ── Step 1: Select Mounting Sub-Type ──
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: MountingServiceData.categories,
              title: 'Mounting & Installation',
              subtitle: 'What do you need mounted?',
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 2: Select Items & Quantities ──
          case 2:
            return ItemQuantitySelector(
              formData: formData,
              items: category.items,
              title: selected,
              subtitle: 'Select items & quantities',
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 3: Optional Add-ons ──
          case 3:
            return AddonsSelector(
              formData: formData,
              addons: MountingServiceData.addons,
              title: 'Any add-ons?',
              subtitle: 'Optional extra services',
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 4: Wall Type (Mounting-Specific) ──
          case 4:
            return WallTypeSelector(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 5: Pick a Date & Time + Estimated Duration ──
          case 5:
            return BookingScheduleStep(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
              estimatedDurationText: _estimatedDuration(formData),
              totalItemCount: formData.totalItemCount,
              serviceName: selected.isNotEmpty
                  ? selected.toLowerCase()
                  : 'mounting',
            );

          // ── Step 6: Service Address (with edit / change) ──
          case 6:
            return BookingAddressStep(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 7: Review Your Booking ──
          case 7:
            return BookingReviewStep(
              formData: formData,
              categoryName: MountingServiceData.serviceName,
              availableItems: category.items,
              availableAddons: MountingServiceData.addons,
              serviceFee: MountingServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 8: Payment / Checkout ──
          case 8:
            return BookingPaymentStep(
              formData: formData,
              categoryName: MountingServiceData.serviceName,
              availableItems: category.items,
              availableAddons: MountingServiceData.addons,
              serviceFee: MountingServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );

          // ── Step 9: Booking Confirmed (Success) ──
          case 9:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: MountingServiceData.serviceName,
              bookingIdPrefix: MountingServiceData.bookingIdPrefix,
              availableItems: category.items,
              availableAddons: MountingServiceData.addons,
              serviceFee: MountingServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onClose: onClose,
            );

          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
