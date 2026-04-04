import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Full-screen document viewer for images and PDFs
class DocumentViewerScreen extends StatefulWidget {
  final String imagePath;
  final String title;

  const DocumentViewerScreen({
    super.key,
    required this.imagePath,
    required this.title,
  });

  @override
  State<DocumentViewerScreen> createState() => _DocumentViewerScreenState();
}

class _DocumentViewerScreenState extends State<DocumentViewerScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AssetDetailColors.textPrimary,
      appBar: AppBar(
        backgroundColor: AssetDetailColors.textPrimary,
        leading: IconButton(
          icon: Icon(Icons.close, color: AssetDetailColors.surfaceColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: AssetDetailColors.surfaceColor,
            fontSize: responsive.fontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(child: _buildDocumentContent()),
    );
  }

  Widget _buildDocumentContent() {
    final isPdf = widget.imagePath.toLowerCase().endsWith('.pdf');
    final isFile =
        widget.imagePath.startsWith('/') ||
        widget.imagePath.startsWith('file://');

    if (isPdf) {
      return _buildPdfPreview();
    }

    return _buildImagePreview(isFile);
  }

  Widget _buildPdfPreview() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: responsive.iconSize(80),
          color: AssetDetailColors.surfaceColor,
        ),
        SizedBox(height: responsive.spacing(24)),
        Text(
          'PDF Document',
          style: TextStyle(
            color: AssetDetailColors.surfaceColor,
            fontSize: responsive.fontSize(20),
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(32)),
          child: Text(
            widget.title,
            style: TextStyle(
              color: AssetDetailColors.surfaceColor,
              fontSize: responsive.fontSize(16),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),
        ElevatedButton.icon(
          onPressed: _openPdf,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open PDF'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AssetDetailColors.primaryDark,
            foregroundColor: AssetDetailColors.surfaceColor,
          ),
        ),
      ],
    );
  }

  Widget _buildImagePreview(bool isFile) {
    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      child: Container(
        color: AssetDetailColors.textPrimary,
        child: Center(
          child: isFile
              ? Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  cacheWidth: 1200,
                  cacheHeight: 1200,
                  errorBuilder: _buildErrorWidget,
                )
              : Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
                  cacheWidth: 1200,
                  cacheHeight: 1200,
                  errorBuilder: _buildErrorWidget,
                ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(
    BuildContext context,
    Object error,
    StackTrace? stackTrace,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: responsive.iconSize(48),
            color: AssetDetailColors.surfaceColor,
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'Document not found',
            style: TextStyle(color: AssetDetailColors.surfaceColor),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf() async {
    try {
      final file = File(widget.imagePath);
      if (await file.exists()) {
        final uri = Uri.file(file.path);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showError(
            'Cannot open ${widget.title}. Please install a PDF viewer.',
          );
        }
      } else {
        _showError('File not found: ${widget.title}');
      }
    } on Object catch (e) {
      _showError('Error opening PDF: ${e.toString()}');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AssetDetailColors.errorColor,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}