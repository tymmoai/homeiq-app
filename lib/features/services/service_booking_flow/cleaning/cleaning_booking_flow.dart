import 'package:flutter/material.dart';
import '../shared/data/cleaning_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Cleaning service booking flow.
///
/// Steps: Select Type → Select Size/Items → Add-ons → Schedule → Review → Confirmation
class CleaningBookingFlow extends StatelessWidget {
  final String categoryName;

  const CleaningBookingFlow({super.key, this.categoryName = 'Cleaning'});

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 5,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: CleaningServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = CleaningServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => CleaningServiceData.categories.first,
        );

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: CleaningServiceData.categories,
              title: 'Professional Cleaning',
              subtitle: 'What needs cleaning?',
              currentStep: step,
              totalSteps: 5,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 2:
            return ItemQuantitySelector(
              formData: formData,
              items: category.items,
              title: selected,
              subtitle: 'Select size & details',
              currentStep: step,
              totalSteps: 5,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return AddonsSelector(
              formData: formData,
              addons: CleaningServiceData.addons,
              title: 'Any add-ons?',
              subtitle: 'Optional extra services',
              currentStep: step,
              totalSteps: 5,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 4:
            return BookingScheduleStep(
              formData: formData,
              currentStep: step,
              totalSteps: 5,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 5:
            return BookingReviewStep(
              formData: formData,
              categoryName: CleaningServiceData.serviceName,
              availableItems: category.items,
              availableAddons: CleaningServiceData.addons,
              serviceFee: CleaningServiceData.basePrice,
              currentStep: step,
              totalSteps: 5,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 6:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: CleaningServiceData.serviceName,
              bookingIdPrefix: CleaningServiceData.bookingIdPrefix,
              availableItems: category.items,
              availableAddons: CleaningServiceData.addons,
              serviceFee: CleaningServiceData.basePrice,
              currentStep: step,
              totalSteps: 5,
              onClose: onClose,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
