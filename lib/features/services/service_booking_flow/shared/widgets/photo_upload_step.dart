import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../models/service_booking_form_data.dart';
import 'booking_continue_button.dart';
import 'booking_shadow_card.dart';
import 'booking_step_header.dart';

/// Photo upload step for Home Repairs service flow.
///
/// Matches web's HomeRepairFlow photo step:
/// - Upload photos of the issue
/// - Camera or gallery option
/// - Preview uploaded photos
class PhotoUploadStep extends StatefulWidget {
  final ServiceBookingFormData formData;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onClose;

  const PhotoUploadStep({
    super.key,
    required this.formData,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onBack,
    required this.onClose,
  });

  @override
  State<PhotoUploadStep> createState() => _PhotoUploadStepState();
}

class _PhotoUploadStepState extends State<PhotoUploadStep> {
  // Simulated photo list (in real app would use image_picker)
  List<String> _photos = [];

  @override
  void initState() {
    super.initState();
    _photos = List.from(widget.formData.photoUrls);
  }

  void _addPhoto() {
    // Simulate adding a photo — in production, use image_picker
    setState(() {
      _photos.add('photo_${_photos.length + 1}');
      widget.formData.photoUrls = List.from(_photos);
    });
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
      widget.formData.photoUrls = List.from(_photos);
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;

    return Column(
      children: [
        BookingStepHeader(
          currentStep: widget.currentStep,
          totalSteps: widget.totalSteps,
          onBack: widget.onBack,
          onClose: widget.onClose,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: responsive.padding(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                responsive.heightBox(8),
                Text(
                  'Upload Photos',
                  style: TextStyle(
                    fontSize: responsive.fontSize(22),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                responsive.heightBox(4),
                Text(
                  'Help us understand the issue better (optional)',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                ),
                responsive.heightBox(24),

                // Upload area
                GestureDetector(
                  onTap: _addPhoto,
                  child: Container(
                    width: double.infinity,
                    padding: responsive.padding(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(16),
                      ),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        width: 2,
                        strokeAlign: BorderSide.strokeAlignInside,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: responsive.wp(16),
                          height: responsive.wp(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: AppColors.primary,
                            size: responsive.iconSize(32),
                          ),
                        ),
                        responsive.heightBox(12),
                        Text(
                          'Tap to Add Photo',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                        responsive.heightBox(4),
                        Text(
                          'Take a photo or choose from gallery',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                responsive.heightBox(20),

                // Photo previews
                if (_photos.isNotEmpty) ...[
                  Text(
                    'Uploaded Photos (${_photos.length})',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  responsive.heightBox(12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: responsive.wp(2),
                      mainAxisSpacing: responsive.wp(2),
                    ),
                    itemCount: _photos.length,
                    itemBuilder: (_, index) {
                      return BookingShadowCard(
                        padding: EdgeInsets.zero,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                responsive.borderRadius(12),
                              ),
                              child: Container(
                                color: AppColors.gray200,
                                child: Icon(
                                  Icons.image_rounded,
                                  color: AppColors.gray400,
                                  size: responsive.iconSize(32),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () => _removePhoto(index),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.9,
                                    ),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: Colors.white,
                                    size: responsive.iconSize(14),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                responsive.heightBox(16),

                // Info note
                Container(
                  padding: responsive.padding(all: 14),
                  decoration: BoxDecoration(
                    color: AppColors.infoBackground,
                    borderRadius: BorderRadius.circular(
                      responsive.borderRadius(10),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: AppColors.infoDark,
                        size: responsive.iconSize(18),
                      ),
                      SizedBox(width: responsive.wp(2)),
                      Expanded(
                        child: Text(
                          'Photos help our technicians come prepared with the right tools and parts. You can add up to 5 photos.',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.infoDarkest,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                responsive.heightBox(40),
              ],
            ),
          ),
        ),
        BookingContinueButton(
          isValid: true, // Photos are optional
          label: _photos.isEmpty ? 'Skip' : 'Continue',
          onPressed: widget.onNext,
        ),
      ],
    );
  }
}
