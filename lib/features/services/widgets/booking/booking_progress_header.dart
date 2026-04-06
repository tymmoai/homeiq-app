import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  final String serviceName;

  const BookingProgressHeader({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.serviceName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Step ${currentStep + 1} of ${totalSteps - 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AssetDetailColors.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                serviceName,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentStep + 1) / (totalSteps - 1),
              backgroundColor: AppColors.gray200,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
