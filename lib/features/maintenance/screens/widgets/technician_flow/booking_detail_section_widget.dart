import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

class BookingDetailSectionWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? additionalInfo;
  final bool showRating;

  const BookingDetailSectionWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.additionalInfo,
    this.showRating = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: responsive.iconSize(20), color: AppColors.textHint),
        SizedBox(width: responsive.spacing(12)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textQuaternary,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  if (showRating &&
                      additionalInfo != null &&
                      additionalInfo!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: responsive.iconSize(16),
                          color: AppColors.warningGold,
                        ),
                        SizedBox(width: responsive.spacing(4)),
                        Text(
                          additionalInfo!,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w500,
                            color: AppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              if (!showRating &&
                  additionalInfo != null &&
                  additionalInfo!.isNotEmpty) ...[
                SizedBox(height: responsive.spacing(2)),
                Text(
                  additionalInfo!,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textQuaternary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}