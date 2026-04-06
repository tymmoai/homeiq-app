import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingLocationStep extends StatelessWidget {
  final List<Map<String, dynamic>> userHomes;
  final String? selectedHomeId;
  final TextEditingController roomDetailsController;
  final ValueChanged<String> onHomeSelected;

  const BookingLocationStep({
    super.key,
    required this.userHomes,
    required this.selectedHomeId,
    required this.roomDetailsController,
    required this.onHomeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Where do you need this service?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Select or confirm service location',
          style: TextStyle(
            fontSize: 14,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Home Selection
        Text(
          'Select Home',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(userHomes.length, (index) {
          final home = userHomes[index];
          final isSelected = selectedHomeId == home['id'];

          return GestureDetector(
            onTap: () => onHomeSelected(home['id'] as String),
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
                      Icons.home_outlined,
                      color: isSelected ? AppColors.primary : AppColors.gray600,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              home['name'] as String,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? AppColors.primary
                                    : AssetDetailColors.textPrimary,
                              ),
                            ),
                            if (home['isDefault'] == true) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusBadge,
                                  ),
                                ),
                                child: Text(
                                  'Default',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          home['address'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            color: AssetDetailColors.textSecondary,
                          ),
                        ),
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
                        ? const Icon(
                            Icons.check,
                            size: 14,
                            color: AppColors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          );
        }),

        const SizedBox(height: 24),

        // Room Details
        Text(
          'Room/Floor Details (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
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
            controller: roomDetailsController,
            decoration: InputDecoration(
              hintText: 'e.g., Living room, 2nd floor, Apt 4B',
              hintStyle: const TextStyle(
                color: AppColors.gray400,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.meeting_room_outlined,
                color: AppColors.primary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
        ),
      ],
    );
  }
}
