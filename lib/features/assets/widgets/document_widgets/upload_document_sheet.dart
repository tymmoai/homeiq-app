import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';

enum _DocumentPickSource { camera, gallery, files }

class UploadDocumentBottomSheet extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onDocumentUploaded;
  final File? selectedFile;
  final String selectedFileName;
  final String fileSizeLabel;
  final String fileExtension;

  const UploadDocumentBottomSheet({
    super.key,
    required this.onDocumentUploaded,
    this.selectedFile,
    this.selectedFileName = '',
    this.fileSizeLabel = '',
    this.fileExtension = '',
  });

  @override
  State<UploadDocumentBottomSheet> createState() =>
      _UploadDocumentBottomSheetState();
}

class _UploadDocumentBottomSheetState extends State<UploadDocumentBottomSheet> {
  final List<String> _documentTypes = const [
    'Invoice',
    'Warranty',
    'Bill',
    'Manual',
    'Other',
  ];

  late TextEditingController _nameController;
  late TextEditingController _customTypeController;

  String _selectedType = 'Invoice';
  File? _selectedFile;
  String _selectedFileName = '';
  String _fileSizeLabel = '';
  String _fileExtension = '';
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _customTypeController = TextEditingController();

    // Initialize with passed file details if available
    if (widget.selectedFile != null) {
      _selectedFile = widget.selectedFile;
      _selectedFileName = widget.selectedFileName;
      _fileSizeLabel = widget.fileSizeLabel;
      _fileExtension = widget.fileExtension;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  /// Pick a file from camera, gallery, or file system
  Future<void> _pickFile(_DocumentPickSource source) async {
    try {
      File? file;

      if (source == _DocumentPickSource.camera) {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        file = image != null ? File(image.path) : null;
      } else if (source == _DocumentPickSource.gallery) {
        final picker = ImagePicker();
        final image = await picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        file = image != null ? File(image.path) : null;
      } else if (source == _DocumentPickSource.files) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
        );
        if (result != null && result.files.single.path != null) {
          file = File(result.files.single.path!);
        }
      }

      if (file == null) return;

      // Validate file exists
      if (!await file.exists()) {
        _showErrorSnackBar('File not found');
        return;
      }

      // Get file extension
      final ext = _getFileExtension(file.path);
      const allowedExtensions = ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'];

      if (!allowedExtensions.contains(ext.toLowerCase())) {
        _showErrorSnackBar(
          'Unsupported file type. Please choose a PDF or image.',
        );
        return;
      }

      // Get file size
      final fileSize = await file.length();
      final sizeLabel = _formatFileSize(fileSize);
      final fileName = file.path.split('/').last;

      setState(() {
        _selectedFile = file;
        _selectedFileName = fileName;
        _fileSizeLabel = sizeLabel;
        _fileExtension = ext.toUpperCase();
        if (_nameController.text.isEmpty) {
          _nameController.text = fileName.replaceAll('.$ext', '');
        }
      });
    } on Object catch (e) {
      _showErrorSnackBar('Error selecting file: ${e.toString()}');
    }
  }

  /// Show file picker source selection
  void _showFilePickerOptions() {
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
                _pickFile(_DocumentPickSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(_DocumentPickSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: const Text('Choose from Files'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(_DocumentPickSource.files);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Get file extension from path
  String _getFileExtension(String path) {
    if (!path.contains('.')) return '';
    return path.split('.').last;
  }

  /// Format file size to human-readable string
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Get current date in MM/DD/YYYY format
  String _getCurrentDateFormatted() {
    final now = DateTime.now();
    return '${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')}/${now.year}';
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Validate and upload document
  Future<void> _handleUpload() async {
    final documentName = _nameController.text.trim();

    // Validate document name
    if (documentName.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a document name';
      });
      return;
    }

    // Validate file selected
    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a document';
      });
      return;
    }

    // Validate custom type if "Other" selected
    if (_selectedType == 'Other' && _customTypeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter custom document type';
      });
      return;
    }

    // Clear error message if validation passes
    setState(() {
      _errorMessage = '';
      _isLoading = true;
    });

    try {
      // Simulate upload delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Create document object
      final now = DateTime.now();
      const monthNames = [
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

      final finalDocumentType = _selectedType == 'Other'
          ? _customTypeController.text.trim()
          : _selectedType;
      final uploadDate = '${monthNames[now.month - 1]} ${now.year}';

      // Compute file metadata so the parent can persist to backend
      final sizeBytes = await _selectedFile!.length();
      final extLower = _fileExtension.toLowerCase();
      final mimeType = switch (extLower) {
        'pdf'  => 'application/pdf',
        'jpg'  || 'jpeg' => 'image/jpeg',
        'png'  => 'image/png',
        'heic' => 'image/heic',
        'doc'  => 'application/msword',
        'docx' => 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        _      => null,
      };

      final newDocument = {
        'title': documentName,
        'date': uploadDate,
        'fileInfo': _fileSizeLabel,
        'imagePath': _selectedFile!.path,
        'type': finalDocumentType.toLowerCase(),
        'documentType': finalDocumentType,
        'isLocalFile': true,
        'documentSize': _fileSizeLabel,
        'fileExtension': _fileExtension,
        'sizeBytes': sizeBytes,
        'mimeType': mimeType,
      };

      // Notify parent to add document
      widget.onDocumentUploaded(newDocument);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on Object catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error uploading document: ${e.toString()}';
          _isLoading = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -2),
          ),
        ],
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
                  'Upload Document',
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
                    // Error message (shown above content if present)
                    if (_errorMessage.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AssetDetailColors.errorColor.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AssetDetailColors.errorColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AssetDetailColors.errorColor,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AssetDetailColors.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    // Document preview (always show since file is pre-selected)
                    if (_selectedFile != null) ...[
                      _buildDocumentPreview(),
                      const SizedBox(height: 12),
                    ],
                    // Document Name Field
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Document Name *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Warranty Certificate',
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Document Type Dropdown
                    SizedBox(
                      width: double.infinity,
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Document Type *',
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
                          labelText: 'Custom Document Type *',
                          border: OutlineInputBorder(),
                          hintText: 'e.g., Repair Receipt',
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    // Read-only Document Info in one row
                    Row(
                      children: [
                        Expanded(
                          child: _buildReadOnlyField(
                            'Upload Date',
                            _getCurrentDateFormatted(),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildReadOnlyField(
                            'Document Size',
                            _fileSizeLabel.isEmpty ? 'N/A' : _fileSizeLabel,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Upload Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleUpload,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AssetDetailColors.primaryDark,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          disabledBackgroundColor: AppColors.gray400,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                'Upload Document',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Build document preview widget
  Widget _buildDocumentPreview() {
    final isImage =
        _fileExtension.toLowerCase() == 'jpg' ||
        _fileExtension.toLowerCase() == 'jpeg' ||
        _fileExtension.toLowerCase() == 'png';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Preview',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AssetDetailColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AssetDetailColors.backgroundColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AssetDetailColors.borderColor, width: 1),
          ),
          child: isImage
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedFile!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.broken_image,
                          size: 48,
                          color: AssetDetailColors.textSecondary,
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _fileExtension.toLowerCase() == 'pdf'
                            ? Icons.picture_as_pdf
                            : Icons.insert_drive_file,
                        size: 48,
                        color: AssetDetailColors.textSecondary,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _fileExtension.toUpperCase(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AssetDetailColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _selectedFileName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.gray600,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _showFilePickerOptions,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit, size: 16, color: AssetDetailColors.primaryDark),
              const SizedBox(width: 6),
              Text(
                'Change Document',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AssetDetailColors.primaryDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build read-only field
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
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AssetDetailColors.textPrimary,
          ),
        ),
      ],
    );
  }
}