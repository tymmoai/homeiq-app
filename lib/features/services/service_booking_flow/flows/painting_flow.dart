import 'package:flutter/material.dart';
import '../shared/data/painting_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Painting service booking flow.
///
/// Web steps: Select Type → Area Size → Surface Condition → Add-ons → Schedule → Address → Payment → Review → Confirmation
/// Total steps: 8 + confirmation
class PaintingBookingFlow extends StatelessWidget {
  final String categoryName;

  const PaintingBookingFlow({super.key, this.categoryName = 'Painting'});

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 8,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: PaintingServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = PaintingServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => PaintingServiceData.categories.first,
        );

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: PaintingServiceData.categories,
              title: 'Painting Services',
              subtitle: 'What do you need painted?',
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
              subtitle: 'How large is the painting area?',
              customSizes: AreaSizeSelector.defaultPaintingSizes,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return SurfaceConditionSelector(
              formData: formData,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 4:
            return AddonsSelector(
              formData: formData,
              addons: PaintingServiceData.addons,
              title: 'Any add-ons?',
              subtitle: 'Optional surface prep & extras',
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
              categoryName: PaintingServiceData.serviceName,
              availableItems: category.items,
              availableAddons: PaintingServiceData.addons,
              serviceFee: PaintingServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 8:
            return BookingReviewStep(
              formData: formData,
              categoryName: PaintingServiceData.serviceName,
              availableItems: category.items,
              availableAddons: PaintingServiceData.addons,
              serviceFee: PaintingServiceData.basePrice,
              currentStep: step,
              totalSteps: 8,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 9:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: PaintingServiceData.serviceName,
              bookingIdPrefix: PaintingServiceData.bookingIdPrefix,
              availableItems: category.items,
              availableAddons: PaintingServiceData.addons,
              serviceFee: PaintingServiceData.basePrice,
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
