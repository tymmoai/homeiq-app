import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';
import 'upgrade_replace_success_screen.dart';

class UpgradeReplaceScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const UpgradeReplaceScreen({super.key, required this.asset});

  @override
  State<UpgradeReplaceScreen> createState() => _UpgradeReplaceScreenState();
}

class _UpgradeReplaceScreenState extends State<UpgradeReplaceScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _problemFieldKey = GlobalKey();
  final _dateFieldKey = GlobalKey();
  final _problemController = TextEditingController();
  final _dateController = TextEditingController();
  bool _submitting = false;
  final List<PlatformFile> _uploadedFiles = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _problemController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );
    if (picked != null) {
      // US-style date only (MM/DD/YYYY)
      _dateController.text = '${picked.month}/${picked.day}/${picked.year}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!context.mounted) return;
      double scrollPosition = 0;
      if (_problemController.text.trim().isEmpty) {
        final problemContext = _problemFieldKey.currentContext;
        if (problemContext != null) {
          final problemBox = problemContext.findRenderObject() as RenderBox?;
          if (problemBox != null) {
            scrollPosition =
                problemBox.localToGlobal(Offset.zero).dy +
                _scrollController.offset -
                100;
          }
        }
      } else if (_dateController.text.trim().isEmpty) {
        final dateContext = _dateFieldKey.currentContext;
        if (dateContext != null) {
          final dateBox = dateContext.findRenderObject() as RenderBox?;
          if (dateBox != null) {
            scrollPosition =
                dateBox.localToGlobal(Offset.zero).dy +
                _scrollController.offset -
                100;
          }
        }
      }
      _scrollController.animateTo(
        scrollPosition.clamp(0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
      return;
    }
    setState(() {
      _submitting = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _submitting = false;
    });
    // Capture values BEFORE clearing
    final problemText = _problemController.text;
    final dateText = _dateController.text;
    final photosCount = _uploadedFiles.length;
    final assetName = widget.asset['name'] as String? ?? 'Asset';
    final assetType = widget.asset['type'] as String? ?? 'Appliance';

    // Clear form after successful submit
    _problemController.clear();
    _dateController.clear();
    setState(() {
      _uploadedFiles.clear();
    });

    // Navigate to success screen with captured values
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpgradeReplaceSuccessScreen(
          assetName: assetName,
          assetType: assetType,
          problemDescription: problemText,
          inspectionDate: dateText,
          photosCount: photosCount,
        ),
      ),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: false,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        // Append new files to existing ones so all selected files appear
        _uploadedFiles.addAll(result.files);
      });
    }
  }

  Color get _headerColor => AppColors.headerBackground;

  @override
  Widget build(BuildContext context) {
    final assetName = widget.asset['name'] as String? ?? 'Asset';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 2,
        centerTitle: false,
        leadingWidth: 40,
        titleSpacing: 0,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Replace Under Warranty',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: AppColors.headerForeground,
          ),
        ),
      ),
      backgroundColor: AppColors.background,
      body: _buildForm(assetName),
    );
  }

  /// Derive warranty type from asset name
  String _getWarrantyType() {
    final type = (widget.asset['name']?.toString() ?? '').toLowerCase();
    if (type.contains('refrigerator') || type.contains('fridge'))
      return 'Parts & Labor';
    if (type.contains('tv') || type.contains('television'))
      return '1-Year Limited';
    if (type.contains('ac') || type.contains('air conditioner'))
      return '5-Year Limited';
    if (type.contains('microwave') || type.contains('oven'))
      return 'Lifetime Limited';
    if (type.contains('washer') || type.contains('washing'))
      return 'Parts & Labor';
    if (type.contains('dishwasher')) return '2-Year Limited';
    if (type.contains('dryer')) return 'Parts Limited';
    if (type.contains('water heater') || type.contains('heater'))
      return '6-Year Limited';
    return 'Standard Warranty';
  }

  /// Format warranty end date for display
  String _formatEndDate() {
    final endDateStr = widget.asset['warrantyEndDate']?.toString();
    if (endDateStr == null) return 'N/A';
    final dt = DateTime.tryParse(endDateStr);
    if (dt == null) return endDateStr;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  Widget _buildForm(String assetName) {
    final warranty = widget.asset['warranty']?.toString() ?? '';
    final warrantyEndDateStr = widget.asset['warrantyEndDate']?.toString();
    final bool isExpired =
        warranty.toLowerCase() == 'expired' ||
        (warrantyEndDateStr != null &&
            (DateTime.tryParse(warrantyEndDateStr)?.isBefore(DateTime.now()) ??
                false));

    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(responsive.spacing(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                Container(
                  padding: EdgeInsets.all(responsive.spacing(20)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(responsive.spacing(16)),
                        decoration: BoxDecoration(
                          color: isExpired
                              ? AppColors.errorSoft
                              : AppColors.gray100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isExpired
                              ? Icons.shield_outlined
                              : Icons.shield_outlined,
                          size: responsive.iconSize(32),
                          color: isExpired
                              ? AppColors.error
                              : AppColors.gray700,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(16)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isExpired
                                  ? 'Warranty Expired'
                                  : 'Warranty Replacement Claim',
                              style: TextStyle(
                                fontSize: responsive.fontSize(20),
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(8)),
                            Text(
                              isExpired
                                  ? 'Your warranty has expired. This replacement will be processed as an out-of-warranty claim and may incur charges.'
                                  : 'Your asset is covered under warranty. Follow the simple steps below to initiate your replacement claim.',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: AppColors.textSecondary,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Coverage Details Card — uses actual asset data
                Container(
                  padding: EdgeInsets.all(responsive.spacing(20)),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isExpired
                          ? [AppColors.errorSoft, AppColors.errorLight]
                          : [AppColors.backgroundGray50, AppColors.gray100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isExpired
                          ? AppColors.errorBorder
                          : AppColors.gray300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isExpired
                                  ? AppColors.error
                                  : AppColors.gray400,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shield,
                              size: responsive.iconSize(16),
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          Text(
                            'Coverage Details',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.bold,
                              color: isExpired
                                  ? AppColors.errorDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          if (isExpired) ...[
                            SizedBox(width: responsive.spacing(8)),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: responsive.spacing(8),
                                vertical: responsive.spacing(2),
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.errorLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusBadge,
                                ),
                              ),
                              child: Text(
                                'EXPIRED',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(10),
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.errorDark,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      _buildCoverageItem('Warranty Type', _getWarrantyType()),
                      SizedBox(height: responsive.spacing(8)),
                      _buildCoverageItem('Valid Until', _formatEndDate()),
                      SizedBox(height: responsive.spacing(8)),
                      _buildCoverageItem(
                        'Status',
                        isExpired
                            ? 'Expired — Not Covered'
                            : 'Active — Full Replacement',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Step 1: Problem Description
                _buildStepHeader(1, 'Describe the Problem'),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  'What\'s wrong with your asset? *',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    key: _problemFieldKey,
                    controller: _problemController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText:
                          'Describe the issue, symptoms, and any error codes.',
                      hintStyle: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      errorStyle: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.error,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textPrimary,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please describe the problem';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Step 2: Upload Images
                _buildStepHeader(2, 'Upload Photos'),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  'Photo Evidence (Recommended)',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                GestureDetector(
                  onTap: _pickFiles,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(20)),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _uploadedFiles.isEmpty
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: responsive.iconSize(32),
                                color: AppColors.textLight,
                              ),
                              SizedBox(height: responsive.spacing(8)),
                              Text(
                                'Tap to select images from your device',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(14),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              SizedBox(height: responsive.spacing(12)),
                              OutlinedButton(
                                onPressed: _pickFiles,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: BorderSide(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  'Choose Files',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_uploadedFiles.length} file(s) selected',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: _pickFiles,
                                    icon: Icon(
                                      Icons.add,
                                      size: responsive.iconSize(16),
                                    ),
                                    label: const Text('Add More'),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.spacing(12)),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  const spacing = 12.0;
                                  // 3 thumbnails per row
                                  final thumbSize =
                                      (constraints.maxWidth - (spacing * 2)) /
                                      3;
                                  return Wrap(
                                    spacing: spacing,
                                    runSpacing: spacing,
                                    children: _uploadedFiles.asMap().entries.map((
                                      entry,
                                    ) {
                                      final index = entry.key;
                                      final file = entry.value;
                                      return Stack(
                                        children: [
                                          Container(
                                            width: thumbSize,
                                            height: thumbSize,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black
                                                      .withValues(alpha: 0.05),
                                                  blurRadius: 4,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child:
                                                  file.path != null &&
                                                      File(
                                                        file.path!,
                                                      ).existsSync()
                                                  ? Image.file(
                                                      File(file.path!),
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) {
                                                            return Container(
                                                              color: AppColors
                                                                  .backgroundGray200,
                                                              child: const Icon(
                                                                Icons
                                                                    .description,
                                                                color: AppColors
                                                                    .grayMedium,
                                                              ),
                                                            );
                                                          },
                                                    )
                                                  : Container(
                                                      color: AppColors
                                                          .backgroundGray200,
                                                      child: const Icon(
                                                        Icons.description,
                                                        color: AppColors
                                                            .grayMedium,
                                                      ),
                                                    ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: GestureDetector(
                                              onTap: () {
                                                setState(() {
                                                  _uploadedFiles.removeAt(
                                                    index,
                                                  );
                                                });
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(
                                                  4,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  size: responsive.iconSize(14),
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Step 3: Inspection Date
                _buildStepHeader(3, 'Schedule Inspection'),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  'When can our technician visit? *',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(6)),
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextFormField(
                    key: _dateFieldKey,
                    controller: _dateController,
                    readOnly: true,
                    onTap: _pickDate,
                    decoration: InputDecoration(
                      suffixIcon: IconButton(
                        icon: Icon(
                          Icons.calendar_today_outlined,
                          color: AppColors.textSecondary,
                          size: responsive.iconSize(20),
                        ),
                        onPressed: _pickDate,
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      hintText: 'MM/DD/YYYY',
                      hintStyle: TextStyle(
                        fontSize: responsive.fontSize(14),
                        color: AppColors.textSecondary,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      errorStyle: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.error,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textPrimary,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please choose a date';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // What's Covered Section
                Container(
                  padding: EdgeInsets.all(responsive.spacing(20)),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.shadow,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: responsive.iconSize(20),
                            color: AppColors.successDark,
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          Text(
                            'What\'s Covered',
                            style: TextStyle(
                              fontSize: responsive.fontSize(16),
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(16)),
                      _buildCoveredItem('Manufacturing defects'),
                      SizedBox(height: responsive.spacing(12)),
                      _buildCoveredItem('Component failures'),
                      SizedBox(height: responsive.spacing(12)),
                      _buildCoveredItem('Performance issues'),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),

                // Important Notes Section
                Container(
                  padding: EdgeInsets.all(responsive.spacing(20)),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: responsive.iconSize(20),
                            color: AppColors.gray600,
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          Text(
                            'Important Notes',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              fontWeight: FontWeight.bold,
                              color: AppColors.gray900,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      _buildNoteItem('Physical damage may void coverage'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildNoteItem('Inspection required before approval'),
                      SizedBox(height: responsive.spacing(8)),
                      _buildNoteItem('Processing time: 1-2 business days'),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(14),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                        : Text(
                            'Submit Replacement Claim',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper method for step headers
  Widget _buildStepHeader(int stepNumber, String title) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        Text(
          title,
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // Helper method for coverage items
  Widget _buildCoverageItem(String label, String value) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              color: AppColors.gray600,
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
      ),
    );
  }

  // Helper method for covered items
  Widget _buildCoveredItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: AppColors.successLight,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            size: responsive.iconSize(14),
            color: AppColors.successDark,
          ),
        ),
        SizedBox(width: responsive.spacing(8)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  // Helper method for note items
  Widget _buildNoteItem(String text) {
    return Text(
      '• $text',
      style: TextStyle(
        fontSize: responsive.fontSize(12),
        color: AppColors.gray700,
      ),
    );
  }
}
