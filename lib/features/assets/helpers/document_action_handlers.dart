import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../services/document_download_service.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../widgets/document_widgets/upload_document_sheet.dart';
import 'asset_detail_helpers.dart';

/// Handle document download action.
Future<void> handleDocumentDownload({
  required BuildContext context,
  required String imagePath,
  required String title,
}) async {
  try {
    late final List<int> bytes;

    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Step 1 — download bytes with a spinner snackbar
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Downloading...'),
            ],
          ),
          backgroundColor: AssetDetailColors.primaryDark,
          duration: const Duration(seconds: 30),
        ),
      );

      final response = await http.get(Uri.parse(imagePath)).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Download timeout'),
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      bytes = response.bodyBytes;
    } else if (imagePath.startsWith('/') ||
        imagePath.startsWith('file://')) {
      final file = File(imagePath.replaceFirst('file://', ''));
      if (!await file.exists()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: $title'),
            backgroundColor: AssetDetailColors.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
      bytes = await file.readAsBytes();
    } else {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot download: $title'),
          backgroundColor: AssetDetailColors.errorColor,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (!context.mounted) return;

    // Step 2 — open the native "Save As" picker so user chooses location
    final rawName = imagePath.split('/').last.split('?').first;
    final fileName =
        rawName.isNotEmpty ? rawName : '${title.replaceAll(' ', '_')}.pdf';

    final savedPath = await FilePicker.platform.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(bytes),
    );

    if (!context.mounted) return;

    if (savedPath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Saved: $fileName'),
          backgroundColor: AssetDetailColors.successColor,
          duration: const Duration(seconds: 3),
        ),
      );
    }
    // If savedPath is null the user cancelled — do nothing
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download failed: $e'),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

/// Handle document share action.
Future<void> handleDocumentShare({
  required BuildContext context,
  required String imagePath,
  required String title,
}) async {
  try {
    // Check if it's a network URL
    if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
      // Download the file first, then share it
      final fileName = imagePath.split('/').last.split('?').first;
      final cleanFileName = fileName.isNotEmpty ? fileName : title;

      // Show downloading indicator
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preparing to share $title...'),
            backgroundColor: AssetDetailColors.primaryDark,
            duration: const Duration(seconds: 1),
          ),
        );
      }

      // Download the file using DocumentDownloadService
      final file = await DocumentDownloadService().downloadDocument(
        url: imagePath,
        fileName: cleanFileName,
      );

      if (!context.mounted) return;

      // Share the downloaded file
      await DocumentDownloadService().shareDocument(
        file,
        subject: title,
      );
    } else if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      // Local file path
      final file = File(imagePath);
      if (await file.exists()) {
        // Get the MIME type for proper sharing
        final mimeType = DocumentDownloadService.getMimeType(imagePath);
        await Share.shareXFiles(
          [XFile(file.path, mimeType: mimeType)],
          subject: title,
          text: 'Sharing $title from BrandsMart App',
        );
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File not found: $title'),
            backgroundColor: AssetDetailColors.errorColor,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else {
      // Asset file - share as text only
      await Share.share(
        '$title - Document from BrandsMart App',
        subject: title,
      );
    }
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error sharing: ${e.toString()}'),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Show a confirmation dialog for deleting a document.
void showDeleteDocumentDialog({
  required BuildContext context,
  required VoidCallback onConfirmDelete,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AssetDetailColors.surfaceColor,
      title: Text(
        'Delete Document',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AssetDetailColors.textPrimary,
        ),
      ),
      content: Text(
        'Are you sure you want to delete this document? This action cannot be undone.',
        style: TextStyle(fontSize: 14, color: AssetDetailColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(
            foregroundColor: AssetDetailColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            side: BorderSide(color: AssetDetailColors.borderColor),
          ),
          child: const Text(
            'Cancel',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirmDelete();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AssetDetailColors.primaryDark,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            elevation: 0,
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Pick and upload document from camera or gallery.
Future<void> pickAndUploadDocument({
  required BuildContext context,
  required ImageSource source,
  required void Function(Map<String, dynamic> newDoc) onDocumentUploaded,
}) async {
  try {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 85);

    if (image == null) return;

    final file = File(image.path);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File not found'),
          backgroundColor: AssetDetailColors.errorColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get file details
    final fileSize = await file.length();
    final sizeLabel = formatFileSize(fileSize);
    final fileName = file.path.split('/').last;
    final ext = fileName.contains('.') ? fileName.split('.').last : 'jpg';

    if (!context.mounted) return;

    // Show upload bottom sheet with pre-selected file
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadDocumentBottomSheet(
        selectedFile: file,
        selectedFileName: fileName,
        fileSizeLabel: sizeLabel,
        fileExtension: ext.toUpperCase(),
        onDocumentUploaded: (newDoc) {
          onDocumentUploaded(newDoc);
          // Show success message after sheet closes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document uploaded successfully'),
                  backgroundColor: AssetDetailColors.successColor,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        },
      ),
    );
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error selecting file: ${e.toString()}'),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Pick and upload document from file system.
Future<void> pickAndUploadDocumentFromFiles({
  required BuildContext context,
  required void Function(Map<String, dynamic> newDoc) onDocumentUploaded,
}) async {
  try {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    if (!await file.exists()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File not found'),
          backgroundColor: AssetDetailColors.errorColor,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Get file details
    final fileSize = await file.length();
    final sizeLabel = formatFileSize(fileSize);
    final fileName = file.path.split('/').last;
    final ext = fileName.contains('.') ? fileName.split('.').last : 'pdf';

    if (!context.mounted) return;

    // Show upload bottom sheet with pre-selected file
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => UploadDocumentBottomSheet(
        selectedFile: file,
        selectedFileName: fileName,
        fileSizeLabel: sizeLabel,
        fileExtension: ext.toUpperCase(),
        onDocumentUploaded: (newDoc) {
          onDocumentUploaded(newDoc);
          // Show success message after sheet closes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Document uploaded successfully'),
                  backgroundColor: AssetDetailColors.successColor,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          });
        },
      ),
    );
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error selecting file: ${e.toString()}'),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
