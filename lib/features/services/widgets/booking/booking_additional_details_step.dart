import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../theme/asset_detail_colors.dart';

class BookingAdditionalDetailsStep extends StatelessWidget {
  final TextEditingController notesController;
  final List<String> uploadedPhotos;

  const BookingAdditionalDetailsStep({
    super.key,
    required this.notesController,
    required this.uploadedPhotos,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Any special requirements?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add notes or photos to help our professional',
          style: TextStyle(
            fontSize: 14,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),

        // Notes
        Text(
          'Additional Notes',
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
            controller: notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText:
                  'e.g., Heavy item - may need 2 professionals\nFurniture is on 2nd floor\nPlease bring extra screws',
              hintStyle: TextStyle(
                color: AppColors.gray400,
                fontSize: 14,
                height: 1.5,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Photo Upload
        Text(
          'Add Photos (Optional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Upload photos of furniture or assembly instructions',
          style: TextStyle(
            fontSize: 13,
            color: AssetDetailColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        GestureDetector(
          onTap: () {
            // Add photo upload logic
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo upload is not yet available.')),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.backgroundGray50,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Tap to add photos',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'JPG, PNG up to 10MB',
                  style: TextStyle(
                    fontSize: 12,
                    color: AssetDetailColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        if (uploadedPhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: uploadedPhotos.map((photo) {
              return Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.image, color: AppColors.gray400),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}