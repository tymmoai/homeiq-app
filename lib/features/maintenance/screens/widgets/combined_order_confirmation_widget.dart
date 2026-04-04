import 'package:flutter/material.dart';
import 'package:homeiq/core/constants/app_colors.dart';
import 'package:homeiq/core/constants/app_dimensions.dart';

import '../../../../utils/responsive_utils.dart';
import '../ai_fix_models.dart';

class CombinedOrderConfirmationWidget extends StatelessWidget {
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final double subtotal;
  final Map<String, String> deliveryAddress;
  final String expectedDeliveryDate;
  final ValueChanged<String> onNameChanged;
  final ValueChanged<String> onPhoneChanged;
  final ValueChanged<String> onStreetChanged;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onStateChanged;
  final ValueChanged<String> onZipChanged;
  final VoidCallback onContinue;

  const CombinedOrderConfirmationWidget({
    super.key,
    required this.parts,
    required this.selectedPartsIndexes,
    required this.subtotal,
    required this.deliveryAddress,
    required this.expectedDeliveryDate,
    required this.onNameChanged,
    required this.onPhoneChanged,
    required this.onStreetChanged,
    required this.onCityChanged,
    required this.onStateChanged,
    required this.onZipChanged,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final selectedCount = selectedPartsIndexes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Confirmation',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // Order Summary Box - White with shadow
        Container(
          padding: EdgeInsets.all(responsive.spacing(16)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // "1 PARTS SELECTED" in uppercase, smaller, light gray
              Text(
                '$selectedCount PARTS SELECTED',
                style: TextStyle(
                  fontSize: responsive.fontSize(11),
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              // Part items - simple row layout
              for (var i = 0; i < parts.length; i++)
                if (selectedPartsIndexes.contains(i))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            parts[i].name,
                            style: TextStyle(
                              fontSize: responsive.fontSize(13),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '\$${(parts[i].priceEncompass * parts[i].quantity).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
              SizedBox(height: responsive.spacing(12)),
              const Divider(height: 1, color: Colors.grey),
              SizedBox(height: responsive.spacing(12)),
              // Subtotal - Bold
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Subtotal',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '\$${subtotal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(24)),
        // Delivery Address Section
        Text(
          'Delivery Address',
          style: TextStyle(
            fontSize: responsive.fontSize(16),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        // Full Name - No border, shadow container
        _buildShadowTextField(context, 
          label: 'Full Name',
          text: deliveryAddress['name'] ?? '',
          onChanged: onNameChanged,
        ),
        SizedBox(height: responsive.spacing(16)),
        // Phone - No border, shadow container
        _buildShadowTextField(context, 
          label: 'Cell Number',
          text: deliveryAddress['phone'] ?? '',
          keyboardType: TextInputType.phone,
          onChanged: onPhoneChanged,
        ),
        SizedBox(height: responsive.spacing(16)),
        // Street Address - No border, shadow container
        _buildShadowTextField(context, 
          label: 'Street Address',
          text: deliveryAddress['street'] ?? '',
          onChanged: onStreetChanged,
        ),
        SizedBox(height: responsive.spacing(14)),
        // City, State, ZIP - Horizontal layout with labels inside border
        Row(
          children: [
            Expanded(
              child: _buildShadowTextField(context, 
                label: 'City',
                text: deliveryAddress['city'] ?? '',
                onChanged: onCityChanged,
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              flex: 1,
              child: _buildShadowTextField(context, 
                label: 'State',
                text: deliveryAddress['state'] ?? '',
                onChanged: onStateChanged,
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              flex: 1,
              child: _buildShadowTextField(context, 
                label: 'ZIP',
                text: deliveryAddress['zip'] ?? '',
                keyboardType: TextInputType.number,
                onChanged: onZipChanged,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(16)),
        // Estimated Delivery Box
        Container(
          padding: EdgeInsets.all(responsive.spacing(12)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.local_shipping, size: responsive.iconSize(18), color: Colors.grey.shade600),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Delivery',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(2)),
                    Text(
                      'Arrives in 6 business days ($expectedDeliveryDate)',
                      style: TextStyle(
                        fontSize: responsive.fontSize(11),
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        // Bottom Button
        Container(
          width: double.infinity,
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: onContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              elevation: 0,
            ),
            child: Text(
              'Confirm Address & Continue',
              style: TextStyle(fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShadowTextField(BuildContext context, {
    required String label,
    required String text,
    required ValueChanged<String> onChanged,
    TextInputType? keyboardType,
  }) {
    final responsive = ResponsiveUtils(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.textSecondary,
          ),
          floatingLabelStyle: TextStyle(
            fontSize: responsive.fontSize(11),
            color: AppColors.textSecondary,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
        controller: TextEditingController(text: text),
        keyboardType: keyboardType,
        onChanged: onChanged,
      ),
    );
  }
}