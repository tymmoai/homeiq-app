import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

/// Shared header widget for all service booking flow steps.
///
/// Step 1: Shows stepper + close(X) button only.
/// Steps 2+: Shows back arrow + stepper + close(X) button.
class BookingStepHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final VoidCallback onBack;
  final VoidCallback onClose;

  /// When false, the back arrow is never shown even on steps 2+.
  /// Useful for the confirmation step where going back is not allowed.
  final bool showBack;

  const BookingStepHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.onBack,
    required this.onClose,
    this.showBack = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.responsive.padding(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Back button (only on steps 2+ and when showBack is true)
          if (currentStep > 1 && showBack)
            GestureDetector(
              onTap: onBack,
              child: Icon(
                Icons.arrow_back,
                color: AppColors.textPrimary,
                size: context.responsive.iconSize(24.0),
              ),
            ),
          // Stepper
          Expanded(
            child: Padding(
              padding: context.responsive.padding(
                left: (currentStep > 1 && showBack) ? 16 : 0,
                right: 16,
              ),
              child: _buildMinimalStepper(context),
            ),
          ),
          // Close button
          GestureDetector(
            onTap: onClose,
            child: Icon(
              currentStep == 1 ? Icons.close_outlined : Icons.close,
              color: AppColors.textPrimary,
              size: context.responsive.iconSize(24.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(totalSteps, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isActive = stepNumber == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(
                      context.responsive.borderRadius(1.0),
                    ),
                  ),
                ),
              ),
              if (index < totalSteps - 1)
                context.responsive.widthBox(4.0),
            ],
          ),
        );
      }),
    );
  }
}
