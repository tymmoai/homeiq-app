import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/core/constants/app_dimensions.dart';
import 'package:homeiq/features/profile/payment_methods/widgets/payment_method_selector.dart';
import '../../../../utils/responsive_utils.dart';

/// NEW: Combined Payment Widget - Payment only (Step 4)
/// Order summary is now handled by CombinedConfirmationWidget (Step 3)
/// This widget just shows grand total and payment method selection
class CombinedPaymentWidget extends StatefulWidget {
  final double partsSubtotal;
  final double technicianFee;
  final bool isProcessing;
  final VoidCallback onConfirmPayment;

  const CombinedPaymentWidget({
    super.key,
    required this.partsSubtotal,
    required this.technicianFee,
    required this.isProcessing,
    required this.onConfirmPayment,
  });

  @override
  State<CombinedPaymentWidget> createState() => _CombinedPaymentWidgetState();
}

class _CombinedPaymentWidgetState extends State<CombinedPaymentWidget> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final GlobalKey<PaymentMethodSelectorState> _selectorKey =
      GlobalKey<PaymentMethodSelectorState>();
  bool _paymentSelected = false;

  @override
  Widget build(BuildContext context) {
    // Calculate totals
    const shipping = 9.99;
    final partsTax = widget.partsSubtotal * 0.08;
    final partsTotal = widget.partsSubtotal + shipping + partsTax;
    final techTax = widget.technicianFee * 0.08;
    final techTotal = widget.technicianFee + techTax;
    final grandTotal = partsTotal + techTotal;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment',
            style: TextStyle(
              fontSize: responsive.fontSize(24),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Select your payment method to complete the order',
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: responsive.spacing(24)),

          // ========== ORDER TOTAL SUMMARY CARD ==========
          Container(
            padding: EdgeInsets.all(responsive.spacing(20)),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildSummaryRow('Parts Order', partsTotal),
                SizedBox(height: responsive.spacing(12)),
                _buildSummaryRow('Technician Service', techTotal),
                SizedBox(height: responsive.spacing(16)),
                Divider(height: 1, thickness: 1, color: AppColors.border),
                SizedBox(height: responsive.spacing(16)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '\$${grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(24),
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: responsive.spacing(24)),

          // ========== PAYMENT METHOD SECTION ==========
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(12)),

          PaymentMethodSelector(
            key: _selectorKey,
            totalAmount: grandTotal,
            onPaymentInfoChanged: (info) {
              setState(() {
                _paymentSelected = info.type != null;
              });
            },
          ),

          SizedBox(height: responsive.spacing(32)),

          // ========== CONFIRM BUTTON ==========
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: (widget.isProcessing || !_paymentSelected)
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
              onPressed: (widget.isProcessing || !_paymentSelected)
                  ? null
                  : _onConfirmPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.4,
                ),
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
                      'Pay \$${grandTotal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          SizedBox(height: responsive.spacing(32)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
            ),
            SizedBox(width: responsive.spacing(10)),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  void _onConfirmPressed() {
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
