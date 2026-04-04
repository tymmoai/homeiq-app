import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingServiceOverview extends StatelessWidget {
  final Map<String, dynamic> service;
  final String categoryName;
  final VoidCallback onStartBooking;

  const BookingServiceOverview({
    super.key,
    required this.service,
    required this.categoryName,
    required this.onStartBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Image
              Container(
                height: 220,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        service['icon'] as IconData? ?? Icons.build,
                        size: 80,
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    // Back button
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 8,
                      left: 16,
                      child: GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadowDark,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            size: 18,
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service Title & Rating
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                service['name'] as String,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AssetDetailColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                categoryName,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AssetDetailColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.amber.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.amber,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${service['rating'] ?? 4.8}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.amber,
                                ),
                              ),
                              const Text(
                                ' (124)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.amber,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Price & Duration
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
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.attach_money,
                                  color: AssetDetailColors.successColor,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Starting From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AssetDetailColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  service['price'] as String? ?? '\$49',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AssetDetailColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 60,
                            color: AppColors.gray200,
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Duration',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AssetDetailColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '1-2 hours',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AssetDetailColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Description
                    Text(
                      'About this service',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AssetDetailColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Professional assembly service for all types of furniture. Our skilled technicians will assemble your furniture quickly and correctly, ensuring all pieces are secure and stable.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AssetDetailColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // What's Included
                    Text(
                      'What\'s included',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AssetDetailColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildIncludedItem(
                      Icons.build_outlined,
                      'All tools provided',
                    ),
                    _buildIncludedItem(
                      Icons.cleaning_services_outlined,
                      'Clean-up after assembly',
                    ),
                    _buildIncludedItem(
                      Icons.verified_outlined,
                      'Quality check & stability test',
                    ),
                    _buildIncludedItem(
                      Icons.support_agent_outlined,
                      '30-day service guarantee',
                    ),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ],
          ),
        ),

        // Book Now Button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: ElevatedButton(
                onPressed: onStartBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AssetDetailColors.successColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            ),
            child: Icon(icon, size: 18, color: AssetDetailColors.successColor),
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: AssetDetailColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}