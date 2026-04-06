import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';

class NewCardFormFieldsWidget extends StatelessWidget {
  final void Function(String) onCardholderChanged;
  final void Function(String) onCardNumberChanged;
  final void Function(String) onExpiryChanged;
  final void Function(String) onCvvChanged;

  const NewCardFormFieldsWidget({
    super.key,
    required this.onCardholderChanged,
    required this.onCardNumberChanged,
    required this.onExpiryChanged,
    required this.onCvvChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Security message
        Container(
          padding: EdgeInsets.all(responsive.spacing(12)),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline,
                size: responsive.iconSize(16),
                color: AppColors.success,
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: Text(
                  'Your card details are encrypted and secure',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.success,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // Card holder name
        TextField(
          decoration: InputDecoration(
            labelText: 'Cardholder Name',
            labelStyle: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textQuaternary,
            ),
            floatingLabelStyle: TextStyle(
              fontSize: responsive.fontSize(12),
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
          ),
          onChanged: onCardholderChanged,
        ),
        SizedBox(height: responsive.spacing(12)),
        // Card number
        TextField(
          decoration: InputDecoration(
            labelText: 'Card Number',
            hintText: '1234 5678 9012 3456',
            labelStyle: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textQuaternary,
            ),
            floatingLabelStyle: TextStyle(
              fontSize: responsive.fontSize(12),
              color: AppColors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.gray300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: Colors.white,
            counterText: '',
          ),
          keyboardType: TextInputType.number,
          maxLength: 19,
          onChanged: (value) {
            final digits = value.replaceAll(' ', '');
            String formatted = '';
            for (int i = 0; i < digits.length; i++) {
              if (i > 0 && i % 4 == 0) {
                formatted += ' ';
              }
              formatted += digits[i];
            }
            onCardNumberChanged(formatted);
          },
        ),
        SizedBox(height: responsive.spacing(12)),
        // Expiry and CVV
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'Expiry Date',
                  hintText: 'MM/YY',
                  labelStyle: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textQuaternary,
                  ),
                  floatingLabelStyle: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                maxLength: 5,
                onChanged: onExpiryChanged,
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  labelText: 'CVV',
                  labelStyle: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textQuaternary,
                  ),
                  floatingLabelStyle: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.primary,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.gray300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                ),
                keyboardType: TextInputType.number,
                maxLength: 3,
                obscureText: true,
                onChanged: onCvvChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
