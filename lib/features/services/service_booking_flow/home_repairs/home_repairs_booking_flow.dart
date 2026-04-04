import 'package:flutter/material.dart';
import '../shared/data/home_repairs_service_data.dart';
import '../shared/models/service_booking_form_data.dart';
import '../shared/widgets/booking_widgets.dart';

/// Home Repairs service booking flow.
///
/// Steps: Select Category → Select Issue → Schedule → Review → Confirmation
class HomeRepairsBookingFlow extends StatelessWidget {
  final String categoryName;

  const HomeRepairsBookingFlow({super.key, this.categoryName = 'Home Repairs'});

  @override
  Widget build(BuildContext context) {
    return ServiceBookingShell(
      categoryName: categoryName,
      totalSteps: 4,
      formData: ServiceBookingFormData(),
      bookingIdPrefix: HomeRepairsServiceData.bookingIdPrefix,
      stepBuilder: (step, formData, onNext, onBack, onClose) {
        final selected = formData.selectedService ?? '';
        final category = HomeRepairsServiceData.categories.firstWhere(
          (c) => c.name == selected,
          orElse: () => HomeRepairsServiceData.categories.first,
        );

        switch (step) {
          case 1:
            return ServiceTypeSelector(
              formData: formData,
              categories: HomeRepairsServiceData.categories,
              title: 'Home Repairs',
              subtitle: 'What needs fixing?',
              currentStep: step,
              totalSteps: 4,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 2:
            return ItemQuantitySelector(
              formData: formData,
              items: category.items,
              title: selected,
              subtitle: 'Select the issue(s)',
              sectionTitle: 'Issues',
              currentStep: step,
              totalSteps: 4,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 3:
            return BookingScheduleStep(
              formData: formData,
              currentStep: step,
              totalSteps: 4,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 4:
            return BookingReviewStep(
              formData: formData,
              categoryName: HomeRepairsServiceData.serviceName,
              availableItems: category.items,
              serviceFee: HomeRepairsServiceData.basePrice,
              currentStep: step,
              totalSteps: 4,
              onNext: onNext,
              onBack: onBack,
              onClose: onClose,
            );
          case 5:
            return BookingConfirmationStep(
              formData: formData,
              serviceName: HomeRepairsServiceData.serviceName,
              bookingIdPrefix: HomeRepairsServiceData.bookingIdPrefix,
              availableItems: category.items,
              serviceFee: HomeRepairsServiceData.basePrice,
              currentStep: step,
              totalSteps: 4,
              onClose: onClose,
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}
