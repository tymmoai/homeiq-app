import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/dashed_border_widget.dart';

/// Displays the photo upload area with image preview, upload progress,
/// and extracted-details confirmation.
class PhotoUploadArea extends StatelessWidget {
  final String? photoPath;
  final bool isUploading;
  final double uploadProgress;
  final bool detailsExtracted;
  final bool isRedirecting;
  final String? brand;
  final String? model;
  final String? serial;
  final VoidCallback onTap;

  const PhotoUploadArea({
    super.key,
    required this.photoPath,
    required this.isUploading,
    required this.uploadProgress,
    required this.detailsExtracted,
    required this.isRedirecting,
    required this.brand,
    required this.model,
    required this.serial,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = photoPath != null && photoPath!.isNotEmpty;

    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: hasPhoto
              ? Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Image fills the container
                        SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: photoPath!.startsWith('http')
                              ? Image.network(photoPath!, fit: BoxFit.cover)
                              : photoPath!.startsWith('/') ||
                                    photoPath!.contains('\\')
                              ? Image.file(
                                  File(photoPath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.successLight,
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 48,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    );
                                  },
                                )
                              : Image.asset(
                                  photoPath!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: AppColors.successLight,
                                      child: const Center(
                                        child: Icon(
                                          Icons.check_circle,
                                          size: 48,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                        // Overlay with tap message
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.transparent,
                                  AppColors.overlay,
                                ],
                              ),
                            ),
                            child: const Text(
                              'Tap to upload another photo',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.white,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : DashedBorder(
                  color: AppColors.primary,
                  strokeWidth: 2.0,
                  dashWidth: 8.0,
                  dashSpace: 4.0,
                  borderRadius: 12.0,
                  child: Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Click to Upload Photo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Take a clear picture of the product label showing the model and serial number.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
        // Upload Progress
        if (isUploading) ...[
          const SizedBox(height: 12),
          Column(
            children: [
              LinearProgressIndicator(
                value: uploadProgress,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 4,
              ),
              const SizedBox(height: 8),
              Text(
                uploadProgress < 1.0
                    ? 'Uploading... ${(uploadProgress * 100).toInt()}%'
                    : 'Processing...',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
        // Extracted Details Section (Photo Uploaded section hidden after extraction)
        if (detailsExtracted && !isUploading) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.successLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: AppColors.success,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Details extracted successfully!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Brand',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            brand ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Model',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            model ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Serial',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            serial ?? '-',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (isRedirecting) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Redirecting to details page...',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
