import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';
import 'document_preview_widget.dart';

/// Bottom sheet for editing document metadata
/// Allows updating document name, type, and replacing the document file
class EditDocumentBottomSheet extends StatefulWidget {
  final Map<String, dynamic> document;
  final ValueChanged<Map<String, dynamic>> onSave;

  const EditDocumentBottomSheet({
    super.key,
    required this.document,
    required this.onSave,
  });

  @override
  State<EditDocumentBottomSheet> createState() =>
      _EditDocumentBottomSheetState();
}

class _EditDocumentBottomSheetState extends State<EditDocumentBottomSheet> {
  final List<String> _documentTypes = const [
    'Invoice',
    'Warranty',
    'Bill',
    'Manual',
    'Other',
  ];

  late TextEditingController _nameController;
  late TextEditingController _customTypeController;

  String _selectedType = 'Other';
  String _previewPath = '';
  String _fileExtension = '';
  String _uploadDateFormatted = '';
  String _sizeLabel = '';
  bool _isLocalFile = false;
  bool _isReplacing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _customTypeController = TextEditingController();
    _initializeFromDocument();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  void _initializeFromDocument() {
    final title = widget.document['title'] as String? ?? 'Document';
    final dateLabel = widget.document['date'] as String? ?? '';
    final fileInfo = widget.document['fileInfo'] as String? ?? '';
    final parsedInfo = _parseFileInfo(fileInfo);

    _selectedType = _normalizeType(
      widget.document['documentType'] ?? widget.document['type'],
    );
    if (!_documentTypes.contains(_selectedType)) {
      _selectedType = 'Other';
    }

    _uploadDateFormatted = _convertToUSDateFormat(dateLabel);
    _sizeLabel =
        (widget.document['documentSize'] as String?) ?? parsedInfo.sizeLabel;
    _previewPath = widget.document['imagePath'] as String? ?? '';
    _isLocalFile = widget.document['isLocalFile'] == true;
    _fileExtension =
        (widget.document['fileExtension'] as String?) ??
        (parsedInfo.extension.isNotEmpty
            ? parsedInfo.extension
            : _extensionFromPath(_previewPath));

    _nameController = TextEditingController(text: title);
  }

  String _normalizeType(dynamic typeValue) {
    final raw = (typeValue ?? '').toString().toLowerCase();
    if (raw.contains('invoice')) return 'Invoice';
    if (raw.contains('warranty')) return 'Warranty';
    if (raw.contains('bill')) return 'Bill';
    if (raw.contains('manual')) return 'Manual';
    return 'Other';
  }

  /// Convert date label (e.g., "Jan 2020") to US format (MM/DD/YYYY)
  String _convertToUSDateFormat(String dateLabel) {
    if (dateLabel.isEmpty) return '';

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

    final parts = dateLabel.replaceAll(',', '').split(' ');
    if (parts.length >= 2) {
      final monthIndex = months.indexOf(parts[0]);
      final year = int.tryParse(parts[parts.length - 1]);
      if (monthIndex != -1 && year != null) {
        return '${(monthIndex + 1).toString().padLeft(2, '0')}/01/$year';
      }
    }

    return dateLabel;
  }

  _ParsedFileInfo _parseFileInfo(String fileInfo) {
    if (fileInfo.isEmpty) {
      return const _ParsedFileInfo();
    }

    final parts = fileInfo.split('•').map((part) => part.trim()).toList();
    int? pageCount;
    String sizeLabel = '';
    String extension = '';

    if (parts.isNotEmpty) {
      final pageMatch = RegExp(r'(\d+)').firstMatch(parts[0]);
      if (pageMatch != null) {
        pageCount = int.tryParse(pageMatch.group(1) ?? '');
      }
    }

    if (parts.length > 1) {
      sizeLabel = parts[1];
    }

    if (parts.length > 2) {
      extension = parts[2];
    }

    return _ParsedFileInfo(
      pageCount: pageCount,
      sizeLabel: sizeLabel,
      extension: extension,
    );
  }

  String _extensionFromPath(String path) {
    if (path.isEmpty || !path.contains('.')) return '';
    return path.split('.').last;
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showReplaceSourcePicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickReplacementFromSource(_DocumentPickSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickReplacementFromSource(_DocumentPickSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose from Files'),
              onTap: () {
                Navigator.pop(context);
                _pickReplacementFromSource(_DocumentPickSource.files);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickReplacementFromSource(_DocumentPickSource source) async {
    setState(() {
      _isReplacing = true;
    });

    try {
      String? path;
      if (source == _DocumentPickSource.camera) {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        path = image?.path;
      } else if (source == _DocumentPickSource.gallery) {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        path = image?.path;
      } else {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        );
        path = result?.files.single.path;
      }

      if (path == null) return;

      final extension = _extensionFromPath(path).toLowerCase();
      const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

      if (!allowedExtensions.contains(extension)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unsupported file type. Please choose a PDF or image.',
            ),
            backgroundColor: AssetDetailColors.errorColor,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }

      final fileSize = await File(path).length();
      final sizeLabel = _formatFileSize(fileSize);

      setState(() {
        _previewPath = path!;
        _isLocalFile = true;
        _fileExtension = extension.toUpperCase();
        _sizeLabel = sizeLabel;
      });
    } on Object catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error replacing document: ${e.toString()}'),
            backgroundColor: AssetDetailColors.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReplacing = false;
        });
      }
    }
  }

  void _handleSave() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a document name.'),
          backgroundColor: AssetDetailColors.errorColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final updatedDocument = Map<String, dynamic>.from(widget.document);
    updatedDocument['title'] = name;
    updatedDocument['documentType'] = _selectedType;
    updatedDocument['type'] = _selectedType.toLowerCase();
    updatedDocument['documentSize'] = _sizeLabel;

    // If preview path changed, update it
    if (_previewPath.isNotEmpty &&
        _previewPath != widget.document['imagePath']) {
      updatedDocument['imagePath'] = _previewPath;
      updatedDocument['isLocalFile'] = _isLocalFile;
      if (_fileExtension.isNotEmpty) {
        updatedDocument['fileExtension'] = _fileExtension;
      }
    }

    widget.onSave(updatedDocument);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Document updated successfully'),
        backgroundColor: AssetDetailColors.successColor,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.of(context).pop();
  }

  /// Build a read-only field as plain text (not an input field)
  Widget _buildReadOnlyField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.gray600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value.isEmpty ? 'N/A' : value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AssetDetailColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(top: BorderSide(color: AppColors.gray200, width: 1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with close button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Edit Document',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          // Scrollable content to avoid overflow when keyboard/dropdown opens
          Flexible(
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DocumentPreviewWidget(
                      imagePath: _previewPath,
                      isLocalFile: _isLocalFile,
                      fileExtension: _fileExtension,
                      isLoading: _isReplacing,
                      onTap: _showReplaceSourcePicker,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Document Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Document Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        items: _documentTypes
                            .map(
                              (type) => DropdownMenuItem<String>(
                                value: type,
                                child: Text(type),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                        isExpanded: true,
                      ),
                    ),
                    // Custom Type Field (if "Other" selected)
                    if (_selectedType == 'Other') ...[
                      const SizedBox(height: 16),
                      TextField(
                        controller: _customTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Enter Custom Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildReadOnlyField(
                            'Upload Date',
                            _uploadDateFormatted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildReadOnlyField(
                            'Document Size',
                            _sizeLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AssetDetailColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class for parsed file information
class _ParsedFileInfo {
  final int? pageCount;
  final String sizeLabel;
  final String extension;

  const _ParsedFileInfo({
    this.pageCount,
    this.sizeLabel = '',
    this.extension = '',
  });
}

/// Document pick source options
enum _DocumentPickSource { camera, gallery, files }