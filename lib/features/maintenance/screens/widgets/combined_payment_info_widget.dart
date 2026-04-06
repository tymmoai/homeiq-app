import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/features/profile/payment_methods/widgets/payment_method_selector.dart';
import '../../../../utils/responsive_utils.dart';

/// OLD: CombinedPaymentInfoWidget - DEPRECATED, kept for backward compatibility
/// Use CombinedPaymentWidget instead
class CombinedPaymentInfoWidget extends StatefulWidget {
  final double subtotal;
  final bool isProcessing;
  final VoidCallback onConfirmPayment;
  final ValueChanged<SelectedPaymentInfo>? onPaymentInfoChanged;

  const CombinedPaymentInfoWidget({
    super.key,
    required this.subtotal,
    required this.isProcessing,
    required this.onConfirmPayment,
    this.onPaymentInfoChanged,
  });

  @override
  State<CombinedPaymentInfoWidget> createState() =>
      _CombinedPaymentInfoWidgetState();
}

class _CombinedPaymentInfoWidgetState extends State<CombinedPaymentInfoWidget> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final GlobalKey<PaymentMethodSelectorState> _selectorKey =
      GlobalKey<PaymentMethodSelectorState>();

  @override
  Widget build(BuildContext context) {
    const shipping = 9.99;
    final tax = widget.subtotal * 0.08;
    final total = widget.subtotal + shipping + tax;

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

        // Payment Method Selector - matches protection plan payment UI
        PaymentMethodSelector(
          key: _selectorKey,
          totalAmount: total,
          onPaymentInfoChanged: widget.onPaymentInfoChanged,
        ),

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
                    'Pay now for parts order',
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
            boxShadow: widget.isProcessing
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
            onPressed: widget.isProcessing ? null : _onPayPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
            ),
            child: widget.isProcessing
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

  void _onPayPressed() {
    final error = _selectorKey.currentState?.validate();
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: AppColors.primary),
      );
      return;
    }
    widget.onConfirmPayment();
  }
}
