import 'package:flutter/material.dart';
import '../shared/data/moving_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Moving service booking flow.
///
/// Web steps: Select Type → Select Items → Packing → Schedule → Pickup & Drop-off → Review → Payment → Confirmation
/// Total steps: 7 + confirmation
class MovingBookingFlow extends StatelessWidget {
  final String categoryName;

  const MovingBookingFlow({super.key, this.categoryName = 'Moving'});

  @override
  Widget build(BuildContext context) {
    // Flatten all inventory items from all categories
    final allItems = MovingServiceData.categories
        .expand((c) => c.items)
        .toList();

    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 7,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: MovingServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final itemsTotal = formData.calculateItemsTotal(allItems);

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: MovingServiceData.categories,
              title: 'Moving & Packing',
              subtitle: 'What type of move do you need?',
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 2:
            return ItemQuantitySelector(
              formData: formData,
              items: allItems,
              title: 'What are you moving?',
              subtitle: 'Select items & quantities',
              sectionTitle: 'Inventory',
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return PackingSelector(
              formData: formData,
              baseTotal: itemsTotal + MovingServiceData.basePrice,
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
            return LocationInputStep(
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
              categoryName: MovingServiceData.serviceName,
              availableItems: allItems,
              serviceFee: MovingServiceData.basePrice,
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 7:
            return BookingPaymentStep(
              formData: formData,
              categoryName: MovingServiceData.serviceName,
              availableItems: allItems,
              serviceFee: MovingServiceData.basePrice,
              currentStep: step,
              totalSteps: 7,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 8:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: MovingServiceData.serviceName,
              bookingIdPrefix: MovingServiceData.bookingIdPrefix,
              availableItems: allItems,
              serviceFee: MovingServiceData.basePrice,
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
