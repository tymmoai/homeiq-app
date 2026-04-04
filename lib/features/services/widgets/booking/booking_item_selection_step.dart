import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingItemSelectionStep extends StatelessWidget {
  final List<Map<String, dynamic>> assemblyItems;
  final Map<String, int> selectedItems;
  final double totalItemsPrice;
  final TextEditingController otherItemController;
  final void Function(String itemName) onIncrement;
  final void Function(String itemName) onDecrement;

  const BookingItemSelectionStep({
    super.key,
    required this.assemblyItems,
    required this.selectedItems,
    required this.totalItemsPrice,
    required this.otherItemController,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What furniture needs assembly?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select items and specify quantity',
          style: TextStyle(
            fontSize: 14,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 20),

        // Items Grid
        ...List.generate(assemblyItems.length, (index) {
          final item = assemblyItems[index];
          final itemName = item['name'] as String;
          final isSelected = selectedItems.containsKey(itemName);
          final quantity = selectedItems[itemName] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
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
            child: Padding(
              padding: const EdgeInsets.all(16),
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
                      item['icon'] as IconData,
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
                          itemName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${item['price']} each',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AssetDetailColors.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Quantity Controls
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.backgroundGray100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => onDecrement(itemName),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.gray300,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(8),
                              ),
                            ),
                            child: Icon(
                              Icons.remove,
                              size: 18,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.gray600,
                            ),
                          ),
                        ),
                        Container(
                          width: 40,
                          height: 36,
                          color: AppColors.white,
                          child: Center(
                            child: Text(
                              '$quantity',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AssetDetailColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => onIncrement(itemName),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: const BorderRadius.horizontal(
                                right: Radius.circular(8),
                              ),
                            ),
                            child: const Icon(
                              Icons.add,
                              size: 18,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 16),

        // Other Item Input
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
          child: TextField(
            controller: otherItemController,
            decoration: InputDecoration(
              hintText: 'Other item (specify)',
              hintStyle: const TextStyle(color: AppColors.gray400, fontSize: 14),
              prefixIcon: Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),

        // Total
        if (selectedItems.isNotEmpty) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Items Total',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                Text(
                  '\$${totalItemsPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AssetDetailColors.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}