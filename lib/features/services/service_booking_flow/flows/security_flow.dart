import 'package:flutter/material.dart';
import '../shared/data/security_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Smart Home & Security service booking flow.
///
/// Web steps: Select Device → Installation Type → Device Details → Add-ons → Schedule → Address → Payment → Review → Confirmation
/// Total steps: 8 + confirmation
class SecurityBookingFlow extends StatelessWidget {
  final String categoryName;

  const SecurityBookingFlow({super.key, this.categoryName = 'Security'});

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 8,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: SecurityServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = SecurityServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => SecurityServiceData.categories.first,
        );

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: SecurityServiceData.categories,
              title: 'Smart Home & Security',
              subtitle: 'What device do you need installed?',
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 2:
            return InstallationTypeSelector(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return DeviceDetailsStep(
              formData: formData,
              deviceName: selected.isNotEmpty ? selected : category.name,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 4:
            return AddonsSelector(
              formData: formData,
              addons: SecurityServiceData.addons,
              title: 'Any add-ons?',
              subtitle: 'Optional setup & integration services',
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
            return BookingPaymentStep(
              formData: formData,
              categoryName: SecurityServiceData.serviceName,
              availableItems: category.items,
              availableAddons: SecurityServiceData.addons,
              serviceFee: SecurityServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 8:
            return BookingReviewStep(
              formData: formData,
              categoryName: SecurityServiceData.serviceName,
              availableItems: category.items,
              availableAddons: SecurityServiceData.addons,
              serviceFee: SecurityServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 9:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: SecurityServiceData.serviceName,
              bookingIdPrefix: SecurityServiceData.bookingIdPrefix,
              availableItems: category.items,
              availableAddons: SecurityServiceData.addons,
              serviceFee: SecurityServiceData.basePrice,
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
