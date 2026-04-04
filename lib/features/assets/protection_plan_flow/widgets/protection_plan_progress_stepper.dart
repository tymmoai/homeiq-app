// Progress Stepper Widget - Shows current step in protection plan flow
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ProtectionPlanProgressStepper extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const ProtectionPlanProgressStepper({
    super.key,
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            // Connector line
            final lineIndex = index ~/ 2;
            final isCompleted = currentStep > lineIndex;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.primary : AppColors.divider,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          } else {
            // Step circle
            final stepIndex = index ~/ 2;
            final isCompleted = currentStep > stepIndex;
            final isCurrent = currentStep == stepIndex;
            return _buildStepCircle(
              stepNumber: stepIndex + 1,
              isCompleted: isCompleted,
              isCurrent: isCurrent,
              label: steps[stepIndex],
            );
          }
        }),
      ),
    );
  }

  Widget _buildStepCircle({
    required int stepNumber,
    required bool isCompleted,
    required bool isCurrent,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted || isCurrent ? AppColors.primary : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isCompleted || isCurrent
                  ? AppColors.primary
                  : AppColors.divider,
              width: 2,
            ),
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, size: 16, color: Colors.white)
                : Text(
                    stepNumber.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isCurrent ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent ? AppColors.primary : AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
