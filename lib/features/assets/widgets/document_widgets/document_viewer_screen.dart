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
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: onSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: onSurface,
            fontSize: responsive.fontSize(16),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(child: _buildDocumentContent()),
    );
  }

  Widget _buildDocumentContent() {
    final p = widget.imagePath;

    // No file was ever uploaded to the backend — shows when url = null in DB
    if (p.isEmpty) return _buildNoPreviewWidget();

    final isPdf = p.toLowerCase().endsWith('.pdf');
    final isNetwork = p.startsWith('http://') || p.startsWith('https://');
    final isFile = !isNetwork && (p.startsWith('/') || p.startsWith('file://'));

    if (isPdf) return _buildPdfPreview(isNetwork: isNetwork);
    if (isNetwork) return _buildNetworkImagePreview();
    // Local file path — show if it still exists on this device
    if (isFile) return _buildImagePreview(true);
    // Asset path (bundled) — extremely rare, keep as fallback
    return _buildImagePreview(false);
  }

  Widget _buildNoPreviewWidget() {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file_outlined,
            size: responsive.iconSize(72),
            color: onSurface.withValues(alpha: 0.55),
          ),
          SizedBox(height: responsive.spacing(20)),
          Text(
            widget.title,
            style: TextStyle(
              color: onSurface,
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: responsive.spacing(12)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(32)),
            child: Text(
              'Preview not available.\nThis document was saved without a file.\nDelete it and upload again to view.',
              style: TextStyle(
                color: onSurface.withValues(alpha: 0.55),
                fontSize: responsive.fontSize(14),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkImagePreview() {
    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: Image.network(
            widget.imagePath,
            fit: BoxFit.contain,
            errorBuilder: _buildErrorWidget,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                            progress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPdfPreview({bool isNetwork = false}) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: responsive.iconSize(80),
          color: onSurface.withValues(alpha: 0.8),
        ),
        SizedBox(height: responsive.spacing(24)),
        Text(
          'PDF Document',
          style: TextStyle(
            color: onSurface,
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
              color: onSurface.withValues(alpha: 0.75),
              fontSize: responsive.fontSize(16),
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: responsive.spacing(24)),
        ElevatedButton.icon(
          onPressed: () => _openPdf(isNetwork: isNetwork),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Open PDF'),
        ),
      ],
    );
  }

  Widget _buildImagePreview(bool isFile) {
    return InteractiveViewer(
      minScale: 0.1,
      maxScale: 5.0,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Center(
          child: isFile
              ? Image.file(
                  File(widget.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: _buildErrorWidget,
                )
              : Image.asset(
                  widget.imagePath,
                  fit: BoxFit.contain,
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
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: responsive.iconSize(48),
            color: onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(height: responsive.spacing(16)),
          Text(
            'Document not found',
            style: TextStyle(color: onSurface.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }

  Future<void> _openPdf({bool isNetwork = false}) async {
    try {
      if (isNetwork) {
        final uri = Uri.parse(widget.imagePath);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          _showError(
            'Cannot open PDF. Please install a PDF viewer.',
          );
        }
        return;
      }
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
