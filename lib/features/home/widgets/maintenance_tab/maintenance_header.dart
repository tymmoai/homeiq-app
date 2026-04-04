import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class MaintenanceHeader extends StatelessWidget {
  const MaintenanceHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Maintenance',
          style: TextStyle(
            fontSize: responsive.fontSize(24.0),
            fontWeight: FontWeight.w700,
            color: AppColors.textOnPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
