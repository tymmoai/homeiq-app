import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../services/chatgpt_service.dart';
import 'nameplate_guidance_card.dart';

/// Displays the "To Locate Your Product Label" guidance section with
/// brand / product-type dropdowns and the nameplate guidance card.
class IdentifyGuidanceSection extends StatelessWidget {
  final bool isLoadingBrands;
  final bool isLoadingSubCategories;
  final String? selectedBrand;
  final String? selectedSubCategory;
  final String? validatedSelectedBrand;
  final String? validatedSelectedSubCategory;
  final List<String> activeBrands;
  final List<String> activeSubCategories;
  final ValueChanged<String?> onBrandChanged;
  final ValueChanged<String?> onSubCategoryChanged;

  // Nameplate guidance props (forwarded to NameplateGuidanceCard)
  final bool isLoadingGuidance;
  final String? guidanceError;
  final NameplateGuidance? nameplateGuidance;
  final Uint8List? wireframeImage;
  final bool isLoadingImage;

  const IdentifyGuidanceSection({
    super.key,
    required this.isLoadingBrands,
    required this.isLoadingSubCategories,
    required this.selectedBrand,
    required this.selectedSubCategory,
    required this.validatedSelectedBrand,
    required this.validatedSelectedSubCategory,
    required this.activeBrands,
    required this.activeSubCategories,
    required this.onBrandChanged,
    required this.onSubCategoryChanged,
    required this.isLoadingGuidance,
    required this.guidanceError,
    required this.nameplateGuidance,
    required this.wireframeImage,
    required this.isLoadingImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray200,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'To Locate Your Product Label',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Please select your appliance brand and model from the options below to receive personalized guidance and illustrations.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BRAND *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    isLoadingBrands
                        ? Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: validatedSelectedBrand,
                                hint: Text(
                                  'Brand',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                                items: activeBrands.map((String brand) {
                                  return DropdownMenuItem<String>(
                                    value: brand,
                                    child: Text(
                                      brand,
                                      style: TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: onBrandChanged,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PRODUCT TYPE *',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    isLoadingSubCategories
                        ? Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Loading...',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                              border: Border.all(
                                color: AppColors.border.withValues(alpha: 0.3),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.shadowLight,
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: validatedSelectedSubCategory,
                                hint: Text(
                                  selectedBrand == null
                                      ? 'Select brand first'
                                      : 'Product Type',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                                isExpanded: true,
                                menuMaxHeight: 300,
                                icon: Icon(
                                  Icons.arrow_drop_down,
                                  color: AppColors.textSecondary,
                                ),
                                items: activeSubCategories.isEmpty
                                    ? null
                                    : activeSubCategories.map((
                                        String category,
                                      ) {
                                        return DropdownMenuItem<String>(
                                          value: category,
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                onChanged: activeSubCategories.isEmpty
                                    ? null
                                    : onSubCategoryChanged,
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
          // Show "Where to Find Your Nameplate" after both selections are made
          if (selectedBrand != null && selectedSubCategory != null) ...[
            const SizedBox(height: 24),
            NameplateGuidanceCard(
              isLoadingGuidance: isLoadingGuidance,
              guidanceError: guidanceError,
              nameplateGuidance: nameplateGuidance,
              wireframeImage: wireframeImage,
              isLoadingImage: isLoadingImage,
            ),
          ],
        ],
      ),
    );
  }
}
