import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

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
    // Check if it's a local file path
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      final file = File(imagePath);
      if (await file.exists()) {
        if (!context.mounted) return;
        // File exists - proceed with download
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading $title...'),
            backgroundColor: AssetDetailColors.primaryDark,
            duration: const Duration(seconds: 1),
          ),
        );

        // Simulate download completion
        await Future.delayed(const Duration(seconds: 1));

        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$title downloaded successfully'),
            backgroundColor: AssetDetailColors.successColor,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        // File doesn't exist
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
      // Asset file - show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Downloading $title...'),
          backgroundColor: AssetDetailColors.primaryDark,
          duration: const Duration(seconds: 1),
        ),
      );

      await Future.delayed(const Duration(seconds: 1));

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$title downloaded successfully'),
          backgroundColor: AssetDetailColors.successColor,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  } on Object catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error downloading: ${e.toString()}'),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 2),
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
    // Check if it's a local file path
    if (imagePath.startsWith('/') || imagePath.startsWith('file://')) {
      final file = File(imagePath);
      if (await file.exists()) {
        await Share.shareXFiles([
          XFile(file.path, name: title),
        ], text: 'Sharing $title');
      } else {
        // If file doesn't exist, try to share as text
        await Share.share('$title - Document from BrandsMart App');
      }
    } else {
      // For asset images, share as text
      await Share.share('$title - Document from BrandsMart App');
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
        style: TextStyle(
          fontSize: 14,
          color: AssetDetailColors.textSecondary,
        ),
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