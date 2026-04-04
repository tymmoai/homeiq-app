import 'package:flutter/material.dart';
import '../shared/data/outdoor_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Outdoor service booking flow.
///
/// Web steps: Select Type → Area Size → Condition → Add-ons → Schedule (+ Recurring) → Address → Review → Payment → Confirmation
/// Total steps: 8 + confirmation
class OutdoorBookingFlow extends StatelessWidget {
  final String categoryName;

  const OutdoorBookingFlow({super.key, this.categoryName = 'Outdoor'});

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 8,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: OutdoorServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = OutdoorServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => OutdoorServiceData.categories.first,
        );

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: OutdoorServiceData.categories,
              title: 'Outdoor Services',
              subtitle: 'What outdoor work do you need?',
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 2:
            return AreaSizeSelector(
              formData: formData,
              title: 'Area Size',
              subtitle: 'How large is the outdoor area?',
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return ConditionSelector(
              formData: formData,
              title: 'Current Condition',
              subtitle: 'What condition is the area in?',
              conditions: ConditionSelector.outdoorConditions,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 4:
            return AddonsSelector(
              formData: formData,
              addons: category.addons,
              title: 'Any add-ons?',
              subtitle: 'Optional extras for $selected',
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
              extraContent: RecurringToggle(
                formData: formData,
                discounts: RecurringToggle.outdoorDiscounts,
              ),
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
              categoryName: OutdoorServiceData.serviceName,
              availableItems: category.items,
              availableAddons: category.addons,
              serviceFee: OutdoorServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 8:
            return BookingPaymentStep(
              formData: formData,
              categoryName: OutdoorServiceData.serviceName,
              availableItems: category.items,
              availableAddons: category.addons,
              serviceFee: OutdoorServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 9:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: OutdoorServiceData.serviceName,
              bookingIdPrefix: OutdoorServiceData.bookingIdPrefix,
              availableItems: category.items,
              availableAddons: category.addons,
              serviceFee: OutdoorServiceData.basePrice,
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
