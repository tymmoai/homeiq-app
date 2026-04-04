import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/features/maintenance/screens/ai_fix_models.dart';
import '../../../../../utils/responsive_utils.dart';

/// Floating action button widget for the AI Fix Problem screen.
/// Handles navigation between steps in parts, technician, and combined flows.
class AiFixFloatingButtonWidget extends StatelessWidget {
  final AiStep currentStep;
  final Set<int> selectedPartsIndexes;
  final TechnicianOption? selectedTechnician;
  final String? selectedSlot;
  final bool isCombinedFlow;
  final void Function(AiStep) onStepChange;

  const AiFixFloatingButtonWidget({
    super.key,
    required this.currentStep,
    required this.selectedPartsIndexes,
    this.selectedTechnician,
    this.selectedSlot,
    required this.isCombinedFlow,
    required this.onStepChange,
  });

  /// Whether the floating button should be shown for the given step
  static bool shouldShow(AiStep step) {
    return step == AiStep.partsComparison ||
        step == AiStep.partsOrderConfirmation ||
        step == AiStep.technicianSelection ||
        step == AiStep.technicianTimeSlot ||
        step == AiStep.technicianConfirmation ||
        step == AiStep.combinedTechnicianSelection ||
        step == AiStep.combinedTimeSlot;
  }

  bool get _isEnabled {
    switch (currentStep) {
      case AiStep.partsComparison:
        return selectedPartsIndexes.isNotEmpty;
      case AiStep.partsOrderConfirmation:
        return true; // Address is pre-filled
      case AiStep.technicianSelection:
        return selectedTechnician !=
            null; // Only enable when technician selected
      case AiStep.technicianTimeSlot:
        return selectedSlot != null;
      case AiStep.technicianConfirmation:
        return true; // Address is pre-filled
      case AiStep.combinedTechnicianSelection:
        return selectedTechnician != null;
      case AiStep.combinedTimeSlot:
        return selectedSlot != null;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    String buttonText = 'Continue';
    VoidCallback? onPressed;
    final enabled = _isEnabled;

    switch (currentStep) {
      case AiStep.partsComparison:
        buttonText = 'Continue';
        onPressed = () => onStepChange(AiStep.partsActionSelection);
        break;
      case AiStep.partsOrderConfirmation:
        buttonText = 'Confirm Address & Continue';
        onPressed = () => onStepChange(AiStep.partsPaymentInfo);
        break;
      case AiStep.technicianSelection:
        buttonText = 'Continue';
        onPressed = () => onStepChange(AiStep.technicianTimeSlot);
        break;
      case AiStep.technicianTimeSlot:
        buttonText = 'Continue';
        onPressed = () => onStepChange(
          isCombinedFlow
              ? AiStep.combinedPayment
              : AiStep.technicianConfirmation,
        );
        break;
      case AiStep.technicianConfirmation:
        buttonText = 'Continue to Payment';
        onPressed = () => onStepChange(AiStep.technicianPaymentConfirmation);
        break;
      case AiStep.combinedTechnicianSelection:
        buttonText = 'Continue';
        onPressed = () => onStepChange(AiStep.combinedTimeSlot);
        break;
      case AiStep.combinedTimeSlot:
        buttonText = 'Continue';
        onPressed = () => onStepChange(AiStep.combinedConfirmation);
        break;
      default:
        break;
    }

    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
        onPressed: enabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
          foregroundColor: AppColors.textOnPrimary,
          elevation: 0,
        ),
        child: Text(
          buttonText,
          style: TextStyle(fontSize: responsive.fontSize(16), fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
