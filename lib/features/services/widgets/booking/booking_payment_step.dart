import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingPaymentStep extends StatelessWidget {
  final List<Map<String, dynamic>> paymentMethods;
  final String? selectedPaymentMethod;
  final double totalPrice;
  final ValueChanged<String> onPaymentMethodSelected;

  const BookingPaymentStep({
    super.key,
    required this.paymentMethods,
    required this.selectedPaymentMethod,
    required this.totalPrice,
    required this.onPaymentMethodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Payment',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select payment method',
          style: TextStyle(
            fontSize: 14,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Payment Methods
        ...List.generate(paymentMethods.length, (index) {
          final method = paymentMethods[index];
          final isSelected = selectedPaymentMethod == method['id'];

          return GestureDetector(
            onTap: () => onPaymentMethodSelected(method['id'] as String),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.transparent,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadowMedium,
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
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      method['icon'] as IconData,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.gray600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          method['type'] == 'wallet'
                              ? AppStrings.walletName
                              : '${(method['type'] as String).toUpperCase()} •••• ${method['last4']}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? AppColors.primary
                                : AssetDetailColors.textPrimary,
                          ),
                        ),
                        if (method['balance'] != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Balance: ${method['balance']}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AssetDetailColors.successColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.gray300,
                        width: 2,
                      ),
                      color: isSelected ? AppColors.primary : AppColors.white,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: AppColors.white)
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),

        // Add Payment Method
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Adding a payment method is not yet available.')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Add Payment Method',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 32),

        // Total Amount
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.05),
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
                      fontSize: 14,
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pay now to confirm booking',
                    style: TextStyle(
                      fontSize: 12,
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Text(
                '\$${totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.successColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}