import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingReviewStep extends StatelessWidget {
  final Map<String, dynamic> service;
  final Map<String, int> selectedItems;
  final String formattedDate;
  final String? selectedTimeSlot;
  final Map<String, dynamic>? selectedHome;
  final String roomDetails;
  final String notesText;
  final double basePrice;
  final double totalItemsPrice;
  final double totalPrice;
  final bool termsAccepted;
  final ValueChanged<bool> onTermsChanged;

  const BookingReviewStep({
    super.key,
    required this.service,
    required this.selectedItems,
    required this.formattedDate,
    required this.selectedTimeSlot,
    required this.selectedHome,
    required this.roomDetails,
    required this.notesText,
    required this.basePrice,
    required this.totalItemsPrice,
    required this.totalPrice,
    required this.termsAccepted,
    required this.onTermsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review your booking',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Please confirm all details are correct',
          style: TextStyle(
            fontSize: 14,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Summary Card
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Service
              _buildReviewRow(
                icon: Icons.home_repair_service_outlined,
                label: 'Service',
                value: service['name'] as String,
              ),
              _buildReviewDivider(),

              // Items
              _buildReviewRow(
                icon: Icons.inventory_2_outlined,
                label: 'Items',
                value: selectedItems.entries
                    .map((e) => '${e.value}x ${e.key}')
                    .join(', '),
              ),
              _buildReviewDivider(),

              // Date & Time
              _buildReviewRow(
                icon: Icons.calendar_today_outlined,
                label: 'Date & Time',
                value: '$formattedDate\n$selectedTimeSlot',
              ),
              _buildReviewDivider(),

              // Location
              if (selectedHome != null)
                _buildReviewRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  value:
                      '${selectedHome!['name']}\n${selectedHome!['address']}${roomDetails.isNotEmpty ? '\n$roomDetails' : ''}',
                ),
              _buildReviewDivider(),

              // Professional
              _buildReviewRow(
                icon: Icons.person_outlined,
                label: 'Professional',
                value: 'Auto-assigned (Best Match)',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AssetDetailColors.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                  ),
                  child: const Text(
                    'Recommended',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AssetDetailColors.successColor,
                    ),
                  ),
                ),
              ),

              // Notes (if any)
              if (notesText.isNotEmpty) ...[
                _buildReviewDivider(),
                _buildReviewRow(
                  icon: Icons.note_outlined,
                  label: 'Notes',
                  value: notesText,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Price Breakdown
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowMedium,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Base Price', style: TextStyle(fontSize: 14)),
                  Text(
                    '\$${basePrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Items', style: TextStyle(fontSize: 14)),
                  Text(
                    '\$${totalItemsPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(color: AppColors.gray200),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${totalPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AssetDetailColors.successColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Terms and Conditions
        GestureDetector(
          onTap: () => onTermsChanged(!termsAccepted),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: termsAccepted
                        ? AppColors.success
                        : AppColors.transparent,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                    border: termsAccepted
                        ? null
                        : Border.all(color: AppColors.gray400, width: 1.5),
                  ),
                  child: termsAccepted
                      ? const Icon(Icons.check, color: AppColors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(fontSize: 13, color: AppColors.textQuaternary),
                      children: [
                        const TextSpan(text: 'I agree to the '),
                        TextSpan(
                          text: 'Terms of Service',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const TextSpan(text: ' and '),
                        TextSpan(
                          text: 'Cancellation Policy',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        if (!termsAccepted) ...[
          const SizedBox(height: 8),
          const Text(
            'Please accept the terms to continue',
            style: TextStyle(fontSize: 12, color: AppColors.warningOrange),
          ),
        ],
      ],
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AssetDetailColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AssetDetailColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }

  Widget _buildReviewDivider() {
    return Divider(height: 1, color: AppColors.backgroundGray100, indent: 48);
  }
}