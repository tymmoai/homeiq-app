import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import 'new_card_form_fields_widget.dart';

class PartsPaymentInfoWidget extends StatelessWidget {
  final double subtotal;
  final bool useNewCard;
  final bool isProcessing;
  final bool isNewCardValid;
  final VoidCallback onSelectExistingCard;
  final VoidCallback onSelectNewCard;
  final Future<void> Function() onConfirmPayment;
  final void Function(String) onCardholderChanged;
  final void Function(String) onCardNumberChanged;
  final void Function(String) onExpiryChanged;
  final void Function(String) onCvvChanged;

  const PartsPaymentInfoWidget({
    super.key,
    required this.subtotal,
    required this.useNewCard,
    required this.isProcessing,
    required this.isNewCardValid,
    required this.onSelectExistingCard,
    required this.onSelectNewCard,
    required this.onConfirmPayment,
    required this.onCardholderChanged,
    required this.onCardNumberChanged,
    required this.onExpiryChanged,
    required this.onCvvChanged,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    const shipping = 9.99;
    final tax = subtotal * 0.08;
    final total = subtotal + shipping + tax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: TextStyle(
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          'Select payment method',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Payment Methods
        GestureDetector(
          onTap: onSelectExistingCard,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: !useNewCard ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: !useNewCard
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.credit_card,
                    color: !useNewCard ? AppColors.primary : AppColors.gray600,
                    size: responsive.iconSize(24),
                  ),
                ),
                SizedBox(width: responsive.spacing(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'VISA •••• 4532',
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: !useNewCard
                          ? AppColors.primary
                          : AppColors.gray300,
                      width: 2,
                    ),
                    color: !useNewCard ? AppColors.primary : Colors.white,
                  ),
                  child: !useNewCard
                      ? Icon(
                          Icons.check,
                          size: responsive.iconSize(14),
                          color: AppColors.textOnPrimary,
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),

        // Add Payment Method
        GestureDetector(
          onTap: onSelectNewCard,
          child: Container(
            padding: EdgeInsets.all(responsive.spacing(16)),
            decoration: BoxDecoration(
              color: AppColors.primary05,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary),
                SizedBox(width: responsive.spacing(8)),
                Text(
                  'Add Payment Method',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // New card form
        if (useNewCard) ...[
          SizedBox(height: responsive.spacing(16)),
          NewCardFormFieldsWidget(
            onCardholderChanged: onCardholderChanged,
            onCardNumberChanged: onCardNumberChanged,
            onExpiryChanged: onExpiryChanged,
            onCvvChanged: onCvvChanged,
          ),
        ],

        SizedBox(height: responsive.spacing(32)),

        // Total Amount
        Container(
          padding: EdgeInsets.all(responsive.spacing(20)),
          decoration: BoxDecoration(
            color: AppColors.primary05,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Amount',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(4)),
                  Text(
                    'Pay now to confirm order',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${total.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: responsive.fontSize(28),
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(24)),

        // Pay Button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: (isProcessing || (useNewCard && !isNewCardValid))
                ? []
                : [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: ElevatedButton(
            onPressed: (isProcessing || (useNewCard && !isNewCardValid))
                ? null
                : () async {
                    await onConfirmPayment();
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
            ),
            child: isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textOnPrimary,
                      ),
                    ),
                  )
                : Text(
                    'Confirm Payment',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
