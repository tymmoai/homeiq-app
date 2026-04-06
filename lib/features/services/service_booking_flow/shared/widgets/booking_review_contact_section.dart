import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import 'booking_review_shadow_field.dart';

/// Contact information section with edit toggle for booking review.
class BookingReviewContactSection extends StatelessWidget {
  final bool isEditing;
  final VoidCallback onToggleEdit;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final GlobalKey<FormState> contactFormKey;
  final VoidCallback onFieldChanged;
  final String Function(String) formatPhoneNumber;

  const BookingReviewContactSection({
    super.key,
    required this.isEditing,
    required this.onToggleEdit,
    required this.nameController,
    required this.emailController,
    required this.phoneController,
    required this.contactFormKey,
    required this.onFieldChanged,
    required this.formatPhoneNumber,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Container(
      padding: responsive.padding(all: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: responsive.spacing(36.0),
                    height: responsive.spacing(36.0),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(8),
                      ),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                      size: responsive.iconSize(18),
                    ),
                  ),
                  SizedBox(width: responsive.wp(2.5)),
                  Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16.0),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: onToggleEdit,
                icon: Icon(
                  isEditing ? Icons.check_rounded : Icons.edit_outlined,
                  size: responsive.iconSize(16),
                  color: AppColors.primary,
                ),
                label: Text(
                  isEditing ? 'Done' : 'Edit',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.hp(1.5)),

          // Read-only display or edit form
          if (!isEditing) ...[
            _buildContactDisplayRow(
              context,
              Icons.person_outline,
              nameController.text.isNotEmpty
                  ? nameController.text
                  : 'Not provided',
            ),
            SizedBox(height: responsive.hp(1)),
            _buildContactDisplayRow(
              context,
              Icons.email_outlined,
              emailController.text.isNotEmpty
                  ? emailController.text
                  : 'Not provided',
            ),
            SizedBox(height: responsive.hp(1)),
            _buildContactDisplayRow(
              context,
              Icons.phone_outlined,
              phoneController.text.isNotEmpty
                  ? phoneController.text
                  : 'Not provided',
            ),
          ] else ...[
            Form(
              key: contactFormKey,
              child: Column(
                children: [
                  BookingReviewShadowField(
                    controller: nameController,
                    label: 'Full Name',
                    icon: Icons.person_outline,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      if (v.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.name,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]')),
                    ],
                    onChanged: (_) => onFieldChanged(),
                  ),
                  SizedBox(height: responsive.hp(1.5)),
                  BookingReviewShadowField(
                    controller: emailController,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your email';
                      }
                      final emailRegex = RegExp(
                        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                      );
                      if (!emailRegex.hasMatch(v)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) => onFieldChanged(),
                  ),
                  SizedBox(height: responsive.hp(1.5)),
                  BookingReviewShadowField(
                    controller: phoneController,
                    label: 'Cell Number',
                    icon: Icons.phone_outlined,
                    hintText: '(555) 123-4567',
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter your cell number';
                      }
                      final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                      if (digitsOnly.length != 10) {
                        return 'Please enter a valid 10-digit number';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.phone,
                    onChanged: (v) {
                      String formatted = formatPhoneNumber(v);
                      if (formatted != v) {
                        phoneController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      }
                      onFieldChanged();
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactDisplayRow(
    BuildContext context,
    IconData icon,
    String value,
  ) {
    final responsive = context.responsive;
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.iconSize(16),
          color: AppColors.textSecondary,
        ),
        SizedBox(width: responsive.wp(2)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
