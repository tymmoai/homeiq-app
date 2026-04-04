import 'package:flutter/material.dart';
import '../shared/data/assembly_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Assembly service booking flow.
///
/// Web steps: Select Type → Select Items → Add-ons → Schedule → Address → Review → Payment → Confirmation
/// Total steps: 7 + confirmation
class AssemblyBookingFlow extends StatelessWidget {
  final String categoryName;

  const AssemblyBookingFlow({super.key, this.categoryName = 'Assembly'});

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 7,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: AssemblyServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = AssemblyServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => AssemblyServiceData.categories.first,
        );

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: AssemblyServiceData.categories,
              title: 'Furniture Assembly',
              subtitle: 'What do you need assembled?',
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 2:
            return ItemQuantitySelector(
              formData: formData,
              items: category.items,
              title: selected,
              subtitle: 'Select items & quantities',
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return AddonsSelector(
              formData: formData,
              addons: AssemblyServiceData.addons,
              title: 'Any add-ons?',
              subtitle: 'Optional extra services',
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 4:
            return BookingScheduleStep(
              formData: formData,
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 5:
            return BookingAddressStep(
              formData: formData,
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 6:
            return BookingReviewStep(
              formData: formData,
              categoryName: AssemblyServiceData.serviceName,
              availableItems: category.items,
              availableAddons: AssemblyServiceData.addons,
              serviceFee: AssemblyServiceData.basePrice,
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 7:
            return BookingPaymentStep(
              formData: formData,
              categoryName: AssemblyServiceData.serviceName,
              availableItems: category.items,
              availableAddons: AssemblyServiceData.addons,
              serviceFee: AssemblyServiceData.basePrice,
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 8:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: AssemblyServiceData.serviceName,
              bookingIdPrefix: AssemblyServiceData.bookingIdPrefix,
              availableItems: category.items,
              availableAddons: AssemblyServiceData.addons,
              serviceFee: AssemblyServiceData.basePrice,
              currentStep: step,
              totalSteps: 7,
              onClose: onClose,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
