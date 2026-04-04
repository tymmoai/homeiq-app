import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';

/// Card displaying selected add-ons with prices.
class BookingReviewAddonsCard extends StatelessWidget {
  final Set<String> selectedAddons;
  final List<ServiceAddon> availableAddons;

  const BookingReviewAddonsCard({
    super.key,
    required this.selectedAddons,
    required this.availableAddons,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: context.responsive.padding(all: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(context.responsive.borderRadius(16.0)),
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
                      context.responsive.borderRadius(10.0)),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: AppColors.primary,
                  size: context.responsive.iconSize(20.0),
                ),
              ),
              context.responsive.widthBox(12.0),
              Text(
                'Add-ons (${selectedAddons.length})',
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
          ...selectedAddons.map((addonName) {
            final addon = availableAddons.firstWhere(
              (a) => a.name == addonName,
              orElse: () =>
                  ServiceAddon(name: addonName, price: 0, icon: Icons.add),
            );
            return Padding(
              padding: context.responsive.padding(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      addon.name,
                      style: TextStyle(
                        fontSize: context.responsive.fontSize(14.0),
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                  Text(
                    '+\$${addon.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: context.responsive.fontSize(15.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
