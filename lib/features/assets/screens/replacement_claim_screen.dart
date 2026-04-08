import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../features/claims/models/claim_model.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../services/claims_service.dart';
import '../../../utils/responsive_utils.dart';

class ReplacementClaimScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> asset;

  const ReplacementClaimScreen({super.key, required this.asset});

  @override
  ConsumerState<ReplacementClaimScreen> createState() =>
      _ReplacementClaimScreenState();
}

class _ReplacementClaimScreenState
    extends ConsumerState<ReplacementClaimScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  final List<File> _images = [];
  final ImagePicker _picker = ImagePicker();
  Claim? _createdClaim;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((xFile) => File(xFile.path)));
        if (_images.length > 5) {
          _images.removeRange(5, _images.length);
        }
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _submitClaim() async {
    if (_formKey.currentState!.validate() && _selectedDate != null) {
      // Save claim to ClaimsService (backend + local fallback)
      final claim = await ClaimsService.saveReplacementClaim(
        assetName: widget.asset['name'] ?? 'Unknown Asset',
        assetId: widget.asset['id'] ?? 'unknown',
        assetBrand: widget.asset['brand'] ?? '',
        assetLocation: widget.asset['location'] ?? '',
        assetType: widget.asset['category'] ?? '',
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : 'Replacement claim for ${widget.asset['name'] ?? 'asset'}. Inspection scheduled for ${_selectedDate != null ? "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}" : "selected date"}.',
      );

      setState(() => _createdClaim = claim);

      // Show success dialog
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.success,
                    size: responsive.iconSize(48),
                  ),
                ),
                SizedBox(height: responsive.spacing(20)),
                Text(
                  'Claim Submitted!',
                  style: TextStyle(
                    fontSize: responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                Text(
                  'Your replacement claim has been submitted successfully. Our technician will visit on your selected date for inspection.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop(); // Close dialog
                      if (_createdClaim != null) {
                        // Replace this screen with the claim detail screen
                        context.pop(); // Pop claim form
                        context.push('/claim-detail', extra: _createdClaim);
                      } else {
                        context.pop(); // Just go back
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(14),
                      ),
                    ),
                    child: Text(
                      'View Claim Details',
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
  }

  /// Check if the asset's warranty is expired
  bool _isWarrantyExpired() {
    final warranty = widget.asset['warranty']?.toString().toLowerCase() ?? '';
    if (warranty == 'expired') return true;
    final endDateStr = widget.asset['warrantyEndDate']?.toString();
    if (endDateStr != null) {
      final endDate = DateTime.tryParse(endDateStr);
      if (endDate != null && endDate.isBefore(DateTime.now())) return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final warranty = widget.asset['warranty']?.toString() ?? 'N/A';
    final warrantyEndDate =
        widget.asset['warrantyEndDate']?.toString() ?? 'N/A';
    final isExpired = _isWarrantyExpired();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Submit Replacement Claim',
          style: TextStyle(
            color: AppColors.headerForeground,
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Form Section
            Container(
              margin: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Replacement Claim Form',
                        style: TextStyle(
                          fontSize: responsive.fontSize(18),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),

                    Padding(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Problem Description
                          Text(
                            'Problem Description *',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          TextFormField(
                            controller: _descriptionController,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText:
                                  'Please describe the issue with your asset in detail...',
                              hintStyle: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please describe the problem';
                              }
                              if (value.length < 20) {
                                return 'Please provide more details (minimum 20 characters)';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: responsive.spacing(6)),
                          Text(
                            'Include symptoms, when it started, and any error messages',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(20)),

                          // Upload Images
                          Text(
                            'Upload Images (Optional)',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          GestureDetector(
                            onTap: _images.length < 5 ? _pickImages : null,
                            child: Container(
                              padding: EdgeInsets.all(responsive.spacing(24)),
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.textSecondary.withValues(
                                    alpha: 0.3,
                                  ),
                                  style: BorderStyle.solid,
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.cloud_upload,
                                    size: responsive.iconSize(40),
                                    color: Colors.grey.shade400,
                                  ),
                                  SizedBox(height: responsive.spacing(12)),
                                  Text(
                                    'Tap to upload images',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  SizedBox(height: responsive.spacing(4)),
                                  Text(
                                    'Maximum 5 images, up to 10MB each',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          if (_images.isNotEmpty) ...[
                            SizedBox(height: responsive.spacing(12)),
                            SizedBox(
                              height: 80,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _images.length,
                                itemBuilder: (context, index) {
                                  return Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.file(
                                            _images[index],
                                            width: 80,
                                            height: 80,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _images.removeAt(index);
                                              });
                                            },
                                            child: Container(
                                              padding: EdgeInsets.all(
                                                responsive.spacing(4),
                                              ),
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: Icon(
                                                Icons.close,
                                                color: Colors.white,
                                                size: responsive.iconSize(16),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                          SizedBox(height: responsive.spacing(20)),

                          // Inspection Date
                          Text(
                            'Preferred Inspection Date *',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(8)),
                          GestureDetector(
                            onTap: () => _selectDate(context),
                            child: Container(
                              padding: EdgeInsets.all(responsive.spacing(14)),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _selectedDate == null
                                      ? AppColors.textSecondary
                                      : AppColors.primary,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: AppColors.textSecondary,
                                    size: responsive.iconSize(20),
                                  ),
                                  SizedBox(width: responsive.spacing(12)),
                                  Text(
                                    _selectedDate == null
                                        ? 'Select inspection date'
                                        : '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      color: _selectedDate == null
                                          ? AppColors.textSecondary
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(6)),
                          Text(
                            'Our technician will visit to inspect the asset',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              color: AppColors.textSecondary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(24)),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: ref.watch(selectedHomeIsViewerProvider)
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Viewers cannot file claims. Contact the home owner to update your permissions.',
                                          ),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 3),
                                        ),
                                      );
                                    }
                                  : _submitClaim,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: EdgeInsets.symmetric(
                                  vertical: responsive.spacing(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.white,
                                    size: responsive.iconSize(20),
                                  ),
                                  SizedBox(width: responsive.spacing(8)),
                                  Text(
                                    'Submit Replacement Claim',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(15),
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Coverage Details Card
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.shield,
                          color: AppColors.primary,
                          size: responsive.iconSize(20),
                        ),
                        SizedBox(width: responsive.spacing(8)),
                        Text(
                          'Coverage Details',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    child: Column(
                      children: [
                        _buildInfoRow('Type', warranty),
                        SizedBox(height: responsive.spacing(12)),
                        _buildInfoRow('Valid Until', warrantyEndDate),
                        SizedBox(height: responsive.spacing(12)),
                        _buildInfoRow(
                          'Coverage',
                          isExpired
                              ? 'Not Covered (Expired)'
                              : 'Full Replacement',
                        ),
                        if (isExpired) ...[
                          SizedBox(height: responsive.spacing(16)),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(responsive.spacing(12)),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red.shade600,
                                  size: responsive.iconSize(20),
                                ),
                                SizedBox(width: responsive.spacing(8)),
                                Expanded(
                                  child: Text(
                                    'Your warranty has expired. This claim may not be covered and could incur out-of-pocket costs.',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(12),
                                      color: Colors.red.shade700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: responsive.spacing(16)),
                        const Divider(),
                        SizedBox(height: responsive.spacing(16)),
                        Text(
                          isExpired ? 'Previously Covered' : 'What\'s Covered',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(12)),
                        _buildCoverageItem('Manufacturing defects'),
                        _buildCoverageItem('Component failures'),
                        _buildCoverageItem('Performance issues'),
                        _buildCoverageItem('Free installation'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Important Notice
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.warningBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.warning,
                    size: responsive.iconSize(24),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.bold,
                            color: AppColors.warningBrown,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Text(
                          '• Physical damage may void coverage\n• Inspection required before approval\n• Processing time: 1-2 business days',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: Colors.orange.shade900,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: AppColors.success,
            size: responsive.iconSize(16),
          ),
          SizedBox(width: responsive.spacing(8)),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
