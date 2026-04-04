import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Installment payment section: duration selector with monthly breakdown.
class PaymentInstallmentSection extends StatelessWidget {
  final double total;
  final int installmentMonths;
  final ValueChanged<int> onInstallmentMonthsChanged;

  const PaymentInstallmentSection({
    super.key,
    required this.total,
    required this.installmentMonths,
    required this.onInstallmentMonthsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      width: double.infinity,
      padding: responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: responsive.spacing(10.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Installment Duration',
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          responsive.heightBox(12.0),
          Container(
            padding: EdgeInsets.zero,
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: responsive.spacing(8.0),
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonFormField<int>(
              // ignore: deprecated_member_use
              value: installmentMonths,
              isDense: true,
              icon: const Icon(Icons.keyboard_arrow_down),
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(8.0),
                  ),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(8.0),
                  ),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(8.0),
                  ),
                  borderSide: BorderSide.none,
                ),
                contentPadding: responsive.padding(
                  horizontal: 14,
                  vertical: 10,
                ),
              ),
              items: [3, 6, 9, 12].map((months) {
                return DropdownMenuItem(
                  value: months,
                  child: Text(
                    '$months Months - \$${(total / months).toStringAsFixed(0)}/month',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  onInstallmentMonthsChanged(value);
                }
              },
            ),
          ),
          responsive.heightBox(16.0),
          Container(
            padding: responsive.padding(all: 12),
            decoration: BoxDecoration(
              color: AppColors.primary05,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: responsive.iconSize(16.0),
                  color: AppColors.primary,
                ),
                responsive.widthBox(8.0),
                Expanded(
                  child: Text(
                    'or \$${(total / installmentMonths).toStringAsFixed(0)}/month for $installmentMonths months',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12.0),
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
