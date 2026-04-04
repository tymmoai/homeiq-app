import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../utils/responsive_utils.dart';

class TechnicianAddressConfirmationWidget extends StatelessWidget {
  final Map<String, String> deliveryAddress;
  final void Function(String key, String value) onUpdateAddressField;
  final VoidCallback onContinue;

  const TechnicianAddressConfirmationWidget({
    super.key,
    required this.deliveryAddress,
    required this.onUpdateAddressField,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Confirmation',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Container(
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
              labelText: 'Full Name',
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
            controller: TextEditingController(text: deliveryAddress['name']),
            onChanged: (value) => onUpdateAddressField('name', value),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Container(
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
              labelText: 'Cell Number',
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
            controller: TextEditingController(text: deliveryAddress['phone']),
            keyboardType: TextInputType.phone,
            onChanged: (value) => onUpdateAddressField('phone', value),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Container(
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
              labelText: 'Street Address',
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
            controller: TextEditingController(text: deliveryAddress['street']),
            onChanged: (value) => onUpdateAddressField('street', value),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
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
                    labelText: 'City',
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
                  controller: TextEditingController(
                    text: deliveryAddress['city'],
                  ),
                  onChanged: (value) => onUpdateAddressField('city', value),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: responsive.spacing(3)),
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
                    labelText: 'State',
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
                  controller: TextEditingController(
                    text: deliveryAddress['state'],
                  ),
                  onChanged: (value) => onUpdateAddressField('state', value),
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 6),
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
                    labelText: 'ZIP',
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
                  controller: TextEditingController(
                    text: deliveryAddress['zip'],
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => onUpdateAddressField('zip', value),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(20)),
        // Bottom spacing for floating button
        SizedBox(height: responsive.spacing(80)),
      ],
    );
  }
}