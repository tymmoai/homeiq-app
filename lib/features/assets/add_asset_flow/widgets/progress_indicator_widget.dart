import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class AddAssetProgressIndicator extends StatelessWidget {
  final int currentStep; // 1-5

  const AddAssetProgressIndicator({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final steps = ['TYPE', 'IDENTIFY', 'DETAILS', 'DOCS', 'DONE'];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(16),
      ),
      child: Column(
        children: [
          // Row with circles and connection lines
          Stack(
            children: [
              // Connection Lines (positioned between circles)
              Positioned(
                left: 36, // 20 padding + 16 (half circle)
                right: 36, // 20 padding + 16 (half circle)
                top:
                    15, // Center of circle (32/2 = 16, but 15 for better alignment)
                child: Row(
                  children: List.generate(steps.length - 1, (index) {
                    final stepNumber = index + 1;
                    return Expanded(
                      child: Container(
                        height: 2,
                        decoration: BoxDecoration(
                          color: stepNumber < currentStep
                              ? AppColors.primary
                              : AppColors.divider,
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Step Circles with proper spacing
              Row(
                children: List.generate(steps.length, (index) {
                  final stepNumber = index + 1;
                  final isCompleted = stepNumber < currentStep;
                  final isActive = stepNumber == currentStep;

                  return Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted || isActive
                              ? AppColors.primary
                              : AppColors.divider,
                          border: isActive
                              ? Border.all(color: AppColors.primary, width: 3)
                              : null,
                        ),
                        child: isCompleted
                            ? Icon(
                                Icons.check,
                                size: responsive.iconSize(18),
                                color: Colors.white,
                              )
                            : Center(
                                child: Text(
                                  stepNumber.toString(),
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w600,
                                    color: isActive || isCompleted
                                        ? Colors.white
                                        : AppColors.textLight,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(8)),
          // Step Labels - directly below each circle
          Row(
            children: List.generate(steps.length, (index) {
              final stepNumber = index + 1;
              final isActive = stepNumber == currentStep;
              final isCompleted = stepNumber < currentStep;

              return Expanded(
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(10),
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.5,
                    color: isActive || isCompleted
                        ? AppColors.primary
                        : AppColors.textLight,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
