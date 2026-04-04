import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A simple widget that displays the DALL-E generated product image.
///
/// The image already contains a bright yellow rectangle at the
/// label location — no Flutter overlays needed.
///
/// ✅ No animated markers, arrows, or glow effects
/// ✅ No text descriptions, legends, or bottom sheets
/// ✅ Designed for elderly US users (>50) — simple and clear
class ProductLabelHighlightImage extends StatelessWidget {
  /// The DALL-E generated wireframe image bytes
  /// (already has yellow highlight baked in)
  final Uint8List wireframeImage;

  const ProductLabelHighlightImage({
    super.key,
    required this.wireframeImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(Icons.location_on, color: AppColors.primary, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Label Location on Your Asset',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Look for the yellow area — that\'s where your label is.',
          style: TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),

        // Product image with yellow highlight baked in
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.memory(
            wireframeImage,
            width: double.infinity,
            fit: BoxFit.contain,
          ),
        ),
      ],
    );
  }
}