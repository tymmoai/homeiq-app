import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

class SummaryTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color? iconColor;
  final String label;
  final String value;
  final String? valueSuffix;
  final Color valueColor;

  const SummaryTile({
    super.key,
    required this.icon,
    required this.iconBgColor,
    this.iconColor,
    required this.label,
    required this.value,
    this.valueSuffix,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: EdgeInsets.all(responsive.spacing(14.0)),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(responsive.borderRadius(16.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: responsive.iconSize(44.0),
            height: responsive.iconSize(44.0),
            decoration: BoxDecoration(
              color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: responsive.iconSize(24.0),
              color: iconColor ?? AppColors.primary,
            ),
          ),
          SizedBox(width: responsive.spacing(14.0)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(10.0),
                    color: AppColors.gray600,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                SizedBox(height: responsive.spacing(6.0)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: responsive.fontSize(26.0),
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                        height: 1.0,
                      ),
                    ),
                    if (valueSuffix != null)
                      Padding(
                        padding: EdgeInsets.only(left: responsive.spacing(2.0)),
                        child: Text(
                          valueSuffix!,
                          style: TextStyle(
                            fontSize: responsive.fontSize(20.0),
                            fontWeight: FontWeight.bold,
                            color: AppColors.gray400,
                            height: 1.0,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
