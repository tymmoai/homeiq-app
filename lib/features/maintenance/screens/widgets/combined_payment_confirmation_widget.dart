import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/core/constants/app_dimensions.dart';

import '../../../../utils/responsive_utils.dart';
import '../ai_fix_models.dart';

class CombinedPaymentConfirmationWidget extends StatelessWidget {
  final TechnicianOption technician;
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final bool agreePayment;
  final bool isProcessing;
  final double partsSubtotal;
  final ValueChanged<bool?> onAgreeChanged;
  final VoidCallback onConfirmPayment;

  const CombinedPaymentConfirmationWidget({
    super.key,
    required this.technician,
    required this.parts,
    required this.selectedPartsIndexes,
    required this.agreePayment,
    required this.isProcessing,
    required this.partsSubtotal,
    required this.onAgreeChanged,
    required this.onConfirmPayment,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    const shipping = 9.99;
    final partsTax = partsSubtotal * 0.08;
    final partsTotal = partsSubtotal + shipping + partsTax;
    final techFee = technician.fee;
    final techTax = techFee * 0.08;
    final techTotal = techFee + techTax;
    final combinedTotal = partsTotal + techTotal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Combined Confirmation',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        // Part Order Section - Premium Design
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(8)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                    ),
                    child: Icon(
                      Icons.inventory_2,
                      size: responsive.iconSize(20),
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Text(
                      'Part Order',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '\$${partsTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(16)),
              Divider(height: 1, thickness: 1, color: AppColors.border),
              SizedBox(height: responsive.spacing(12)),
              for (var i = 0; i < parts.length; i++)
                if (selectedPartsIndexes.contains(i))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            parts[i].name,
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '\$${(parts[i].priceEncompass * parts[i].quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              SizedBox(height: responsive.spacing(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shipping',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${shipping.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(6)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax (8%)',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${partsTax.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // Technician Service Section - Premium Design
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(8)),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                    ),
                    child: Icon(
                      Icons.build,
                      size: responsive.iconSize(20),
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Text(
                      'Technician Service',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    '\$${techTotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(16)),
              Divider(height: 1, thickness: 1, color: AppColors.border),
              SizedBox(height: responsive.spacing(12)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Technician Fee',
                    style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textPrimary),
                  ),
                  Text(
                    '\$${techFee.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Service Tax (8%)',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '\$${techTax.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // Total Amount Section - Premium Design
        Container(
          padding: EdgeInsets.all(responsive.spacing(20)),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount Due',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '\$${combinedTotal.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: responsive.fontSize(24),
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Checkbox(
              value: agreePayment,
              onChanged: onAgreeChanged,
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Text(
                'I authorize the payment of the combined total amount.',
                style: TextStyle(fontSize: responsive.fontSize(11), color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(20)),
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: (isProcessing || !agreePayment)
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
            onPressed: (isProcessing || !agreePayment)
                ? null
                : onConfirmPayment,
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
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.textOnPrimary),
                    ),
                  )
                : Text(
                    'Pay & Confirm All',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}