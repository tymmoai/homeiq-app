import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/asset_form_model.dart';

// Document type definitions with icon and color
const _docTypes = <String, ({IconData icon, Color color, String label})>{
  'warranty': (
    icon: Icons.verified_user_outlined,
    color: Color(0xFF2E7D32),
    label: 'Warranty',
  ),
  'receipt': (
    icon: Icons.receipt_long_outlined,
    color: Color(0xFF1565C0),
    label: 'Receipt',
  ),
  'manual': (
    icon: Icons.menu_book_outlined,
    color: Color(0xFF6A1B9A),
    label: 'Manual',
  ),
  'photo': (
    icon: Icons.photo_camera_outlined,
    color: Color(0xFFE65100),
    label: 'Photo',
  ),
  'other': (
    icon: Icons.insert_drive_file_outlined,
    color: Color(0xFF546E7A),
    label: 'Other',
  ),
};

class Step4DocumentsScreen extends StatefulWidget {
  final AssetFormModel formData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step4DocumentsScreen({
    super.key,
    required this.formData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step4DocumentsScreen> createState() => _Step4DocumentsScreenState();
}

class _Step4DocumentsScreenState extends State<Step4DocumentsScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);

  static const int _maxFileSizeBytes = 10 * 1024 * 1024; // 10 MB

  void _showDocumentPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final r = ResponsiveUtils(context);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              r.spacing(20),
              r.spacing(20),
              r.spacing(20),
              r.spacing(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upload from',
                  style: TextStyle(
                    fontSize: r.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: r.spacing(16)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Photo Gallery',
                    style: TextStyle(
                      fontSize: r.fontSize(15),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Select an image',
                    style: TextStyle(
                      fontSize: r.fontSize(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addDocument('gallery');
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.folder_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Files',
                    style: TextStyle(
                      fontSize: r.fontSize(15),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'PDF, Word, or image files',
                    style: TextStyle(
                      fontSize: r.fontSize(12),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _addDocument('files');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _addDocument(String source) async {
    try {
      String? filePath;
      String? fileName;

      if (source == 'gallery') {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
        );
        if (image != null) {
          filePath = image.path;
          fileName = image.name;
        }
      } else if (source == 'files') {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        );
        if (result != null && result.files.single.path != null) {
          filePath = result.files.single.path!;
          fileName = result.files.single.name;
        }
      }

      if (filePath != null && fileName != null) {
        final file = File(filePath);
        if (await file.exists()) {
          final sizeBytes = await file.length();
          if (sizeBytes > _maxFileSizeBytes) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'File is too large (${(sizeBytes / 1024 / 1024).toStringAsFixed(1)} MB). Maximum is 10 MB.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 3),
                ),
              );
            }
            return;
          }
        }

        // Show type picker before adding
        if (!mounted) return;
        final docType = await _showTypePickerSheet(fileName);
        if (docType == null) return; // user dismissed

        setState(() {
          widget.formData.documentPaths.add(filePath!);
          widget.formData.documentTypes.add(docType);
        });
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('We could not upload your file. Please try again.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<String?> _showTypePickerSheet(String fileName) {
    return showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final r = ResponsiveUtils(ctx);
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              r.spacing(20),
              r.spacing(20),
              r.spacing(20),
              r.spacing(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What type of document is this?',
                  style: TextStyle(
                    fontSize: r.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: r.spacing(4)),
                Text(
                  fileName,
                  style: TextStyle(
                    fontSize: r.fontSize(13),
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: r.spacing(16)),
                ..._docTypes.entries.map((e) {
                  final meta = e.value;
                  return Padding(
                    padding: EdgeInsets.only(bottom: r.spacing(4)),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: r.spacing(4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: meta.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(meta.icon, color: meta.color, size: 20),
                      ),
                      title: Text(
                        meta.label,
                        style: TextStyle(
                          fontSize: r.fontSize(15),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, e.key),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  String _displayFileName(String path) {
    if (path.contains('/') || path.contains('\\')) {
      return path.split(RegExp(r'[\\/]')).last;
    }
    return path;
  }

  void _removeDocument(int index) {
    setState(() {
      widget.formData.documentPaths.removeAt(index);
      if (index < widget.formData.documentTypes.length) {
        widget.formData.documentTypes.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: Container(
            color: Colors.grey.shade50,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: responsive.spacing(4)),
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Your Documents',
                          style: TextStyle(
                            fontSize: responsive.fontSize(22),
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      if (widget.formData.documentPaths.isNotEmpty)
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: responsive.spacing(10),
                            vertical: responsive.spacing(3),
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${widget.formData.documentPaths.length}',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12),
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    'Upload warranty, receipts, manuals, or photos related to this asset.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  _buildDocumentUploadArea(),
                  SizedBox(height: responsive.spacing(24)),
                  if (widget.formData.documentPaths.isEmpty)
                    _buildSuggestedDocumentsCard(),
                  SizedBox(height: responsive.spacing(24)),
                ],
              ),
            ),
          ),
        ),
        _buildFooterButtons(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(6)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: responsive.iconSize(20),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
              child: _buildMinimalStepper(4),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(6)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: responsive.iconSize(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(int currentStep) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(4, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isActive = stepNumber == currentStep;
        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (index < 3) SizedBox(width: responsive.spacing(4)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildDocumentUploadArea() {
    final docs = widget.formData.documentPaths;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Upload button (always visible)
        GestureDetector(
          onTap: _showDocumentPicker,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: responsive.spacing(docs.isEmpty ? 48 : 20),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    responsive.spacing(docs.isEmpty ? 14 : 10),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.06),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    docs.isEmpty
                        ? Icons.upload_file_outlined
                        : Icons.add_rounded,
                    size: responsive.iconSize(docs.isEmpty ? 32 : 24),
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(height: responsive.spacing(docs.isEmpty ? 14 : 8)),
                Text(
                  docs.isEmpty
                      ? 'Tap to Upload Documents'
                      : 'Add Another Document',
                  style: TextStyle(
                    fontSize: responsive.fontSize(docs.isEmpty ? 16 : 14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (docs.isEmpty) ...[
                  SizedBox(height: responsive.spacing(6)),
                  Text(
                    'Photos, PDFs, or Word documents (max 10 MB)',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        // Uploaded documents list
        if (docs.isNotEmpty) ...[
          SizedBox(height: responsive.spacing(20)),
          Text(
            'Uploaded Documents',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(10)),
          ...List.generate(docs.length, (i) {
            final path = docs[i];
            final type = i < widget.formData.documentTypes.length
                ? widget.formData.documentTypes[i]
                : 'other';
            return _buildDocumentCard(path, type, i);
          }),
        ],
      ],
    );
  }

  Widget _buildDocumentCard(String path, String type, int index) {
    final displayName = _displayFileName(path);
    final meta = _docTypes[type] ?? _docTypes['other']!;
    return Container(
      margin: EdgeInsets.only(bottom: responsive.spacing(10)),
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            width: responsive.spacing(42),
            height: responsive.spacing(42),
            decoration: BoxDecoration(
              color: meta.color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              meta.icon,
              color: meta.color,
              size: responsive.iconSize(20),
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          // Name + type badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: responsive.spacing(4)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(8),
                    vertical: responsive.spacing(2),
                  ),
                  decoration: BoxDecoration(
                    color: meta.color.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    meta.label,
                    style: TextStyle(
                      fontSize: responsive.fontSize(11),
                      fontWeight: FontWeight.w600,
                      color: meta.color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Delete
          GestureDetector(
            onTap: () => _removeDocument(index),
            child: Padding(
              padding: EdgeInsets.all(responsive.spacing(6)),
              child: Icon(
                Icons.close_rounded,
                size: responsive.iconSize(18),
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedDocumentsCard() {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                Icons.lightbulb_outline,
                color: AppColors.primary,
                size: responsive.iconSize(18),
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: Text(
                  'Suggested Documents',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildSuggestionRow(
            Icons.verified_user_outlined,
            'Warranty card or certificate',
          ),
          SizedBox(height: responsive.spacing(8)),
          _buildSuggestionRow(
            Icons.receipt_long_outlined,
            'Purchase receipt or invoice',
          ),
          SizedBox(height: responsive.spacing(8)),
          _buildSuggestionRow(
            Icons.menu_book_outlined,
            'User manual or setup guide',
          ),
          SizedBox(height: responsive.spacing(8)),
          _buildSuggestionRow(
            Icons.build_outlined,
            'Service or maintenance records',
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: responsive.iconSize(16),
          color: AppColors.textSecondary,
        ),
        SizedBox(width: responsive.spacing(10)),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooterButtons() {
    final hasDocuments = widget.formData.documentPaths.isNotEmpty;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.spacing(20),
        responsive.spacing(16),
        responsive.spacing(20),
        responsive.spacing(16) + bottomInset,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: responsive.spacing(52),
              child: OutlinedButton(
                onPressed: widget.onNext,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  padding: EdgeInsets.zero,
                  side: BorderSide(color: AppColors.gray300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Skip',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            flex: 2,
            child: SizedBox(
              height: responsive.spacing(52),
              child: ElevatedButton(
                onPressed: hasDocuments ? widget.onNext : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasDocuments
                      ? AppColors.primary
                      : AppColors.gray300.withValues(alpha: 0.3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  disabledBackgroundColor: AppColors.gray300.withValues(
                    alpha: 0.3,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Continue',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: hasDocuments
                        ? Colors.white
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
