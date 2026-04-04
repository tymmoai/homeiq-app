import 'package:flutter/material.dart';
import '../shared/data/mounting_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Mounting service booking flow.
///
/// Web steps: Select Type → Select Items → Add-ons → Wall Type → Schedule → Address → Review → Payment → Confirmation
/// Total steps: 8 + confirmation
class MountingBookingFlow extends StatelessWidget {
  final String categoryName;

  const MountingBookingFlow({super.key, this.categoryName = 'Mounting'});

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
          case 4:
            return WallTypeSelector(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 5:
            return BookingScheduleStep(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 6:
            return BookingAddressStep(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
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
