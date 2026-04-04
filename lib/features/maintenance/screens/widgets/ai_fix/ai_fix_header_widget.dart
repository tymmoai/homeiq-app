import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/features/maintenance/screens/ai_fix_models.dart';
import '../../../../../utils/responsive_utils.dart';

/// Header widget for the AI Fix Problem screen.
/// Handles the back button, progress indicator, and close button.
class AiFixHeaderWidget extends StatelessWidget {
  final AiStep currentStep;
  final VoidCallback onBack;
  final VoidCallback onClose;
  final bool isCombinedFlow;
  final bool isStandaloneBooking;

  const AiFixHeaderWidget({
    super.key,
    required this.currentStep,
    required this.onBack,
    required this.onClose,
    required this.isCombinedFlow,
    required this.isStandaloneBooking,
  });

  @override
  Widget build(BuildContext context) {
    // Combined order+booking success: close-only header
    if (currentStep == AiStep.combinedOrderBookingConfirmation) {
      return _buildCloseOnlyHeader(context);
    }
    return _buildHeader(context);
  }

  Widget _buildHeader(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final showBackButton = currentStep != AiStep.issueSelection;

    // Only hide stepper for booking confirmed screen
    final isCloseOnlyScreen =
        currentStep == AiStep.technicianBookingConfirmation;

    if (isCloseOnlyScreen) {
      return _buildCloseOnlyHeader(context);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16, right: 20),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                if (showBackButton) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: GestureDetector(
                      onTap: onBack,
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.textPrimary,
                        size: responsive.iconSize(24),
                      ),
                    ),
                  ),
                ],
                Expanded(child: _buildProgressIndicator()),
              ],
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseOnlyHeader(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 16, left: 20, right: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          GestureDetector(
            onTap: onClose,
            child: Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final progress = _getFlowProgress();

    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.gray200,
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            // Animated progress fill
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withValues(alpha: 0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculate current flow progress (0.0 to 1.0)
  double _getFlowProgress() {
    // If we're in any technician flow step - show progress 0-100% ONLY for technician steps
    final isTechnicianFlow = isStandaloneBooking || isCombinedFlow;

    if (isTechnicianFlow) {
      // Standalone technician flow steps: Selection → TimeSlot → Confirmation (with address) → Payment → Success
      if (currentStep == AiStep.technicianSelection) return 0.0;
      if (currentStep == AiStep.technicianTimeSlot) return 0.25;
      if (currentStep == AiStep.technicianConfirmation) return 0.5;
      if (currentStep == AiStep.technicianPaymentConfirmation) return 0.75;
      if (currentStep == AiStep.technicianBookingConfirmation) return 1.0;

      // Combined flow steps: Tech Selection → TimeSlot → Confirmation → Payment → Success
      if (currentStep == AiStep.combinedTechnicianSelection) return 0.0;
      if (currentStep == AiStep.combinedTimeSlot) return 0.25;
      if (currentStep == AiStep.combinedConfirmation) return 0.5;
      if (currentStep == AiStep.combinedPayment) return 0.75;
      if (currentStep == AiStep.combinedOrderBookingConfirmation) return 1.0;
    }

    // Pre-decision troubleshooting flow (Issue → Analysis → Solution)
    if (currentStep == AiStep.issueSelection) return 0.0;
    if (currentStep == AiStep.analysis) return 0.33;
    if (currentStep == AiStep.solution) return 0.66;
    if (currentStep == AiStep.diyGuide) return 0.66;

    // Buy Parts flow: Comparison → Action → Confirmation → Payment → Summary
    if (currentStep == AiStep.partsComparison) return 0.0;
    if (currentStep == AiStep.partsActionSelection) return 0.25;
    if (currentStep == AiStep.partsOrderConfirmation) return 0.5;
    if (currentStep == AiStep.partsPaymentInfo) return 0.75;
    if (currentStep == AiStep.partsOrderSummary) return 1.0;

    return 0.0;
  }
}