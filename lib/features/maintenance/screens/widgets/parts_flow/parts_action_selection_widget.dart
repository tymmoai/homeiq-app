import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

class PartsActionSelectionWidget extends StatelessWidget {
  final VoidCallback onBuyParts;
  final VoidCallback onBookTechnician;
  final VoidCallback onBuyPartsAndBookTechnician;

  const PartsActionSelectionWidget({
    super.key,
    required this.onBuyParts,
    required this.onBookTechnician,
    required this.onBuyPartsAndBookTechnician,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose an action',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Select how you would like to proceed with your parts order.',
          style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textSecondary),
        ),
        SizedBox(height: responsive.spacing(32)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBuyParts,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray100,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(18)),
              side: const BorderSide(
                  color: AppColors.gray400,
              ),
              elevation: 0,
            ),
            child: Text(
              'Buy Parts',
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBookTechnician,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray100,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(18)),
              side: const BorderSide(
                  color: AppColors.gray400,
              ),
              elevation: 0,
            ),
            child: Text(
              'Book Technician',
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onBuyPartsAndBookTechnician,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gray100,
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(18)),
              side: const BorderSide(
                  color: AppColors.gray400,
              ),
              elevation: 0,
            ),
            child: Text(
              'Buy Parts + Book Technician',
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}