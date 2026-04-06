import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../utils/responsive_utils.dart';

/// Card displaying selected service items with quantities and prices.
class BookingReviewItemsCard extends StatelessWidget {
  final List<Map<String, dynamic>> selectedItemsList;

  const BookingReviewItemsCard({super.key, required this.selectedItemsList});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(
          context.responsive.borderRadius(16.0),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: 10,
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
                width: context.responsive.spacing(40.0),
                height: context.responsive.spacing(40.0),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    context.responsive.borderRadius(10.0),
                  ),
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Items (${selectedItemsList.length})',
                style: TextStyle(
                  fontSize: context.responsive.fontSize(16.0),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
          context.responsive.heightBox(16.0),
          Divider(height: 1, color: AppColors.gray200),
          ...List.generate(selectedItemsList.length, (index) {
            final item = selectedItemsList[index];
            final isLast = index == selectedItemsList.length - 1;
            return Column(
              children: [
                Padding(
                  padding: context.responsive.padding(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item['name'],
                          style: TextStyle(
                            fontSize: context.responsive.fontSize(14.0),
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      Container(
                        padding: context.responsive.padding(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.backgroundGray100,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Text(
                          'x${item['quantity']}',
                          style: TextStyle(
                            fontSize: context.responsive.fontSize(13.0),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textQuaternary,
                          ),
                        ),
                      ),
                      context.responsive.widthBox(16.0),
                      Text(
                        '\$${(item['total'] as num).toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: context.responsive.fontSize(15.0),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Divider(height: 1, color: AppColors.backgroundGray100),
              ],
            );
          }),
        ],
      ),
    );
  }
}
