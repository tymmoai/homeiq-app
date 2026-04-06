import 'dart:io';
import 'package:flutter/material.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Preview widget for document thumbnails
class DocumentPreviewWidget extends StatelessWidget {
  final String imagePath;
  final bool isLocalFile;
  final String fileExtension;
  final bool isLoading;
  final VoidCallback onTap;

  const DocumentPreviewWidget({
    super.key,
    required this.imagePath,
    required this.isLocalFile,
    required this.fileExtension,
    required this.isLoading,
    required this.onTap,
  });

  bool _isImageExtension(String extension) {
    final ext = extension.toLowerCase();
    return ext == 'png' || ext == 'jpg' || ext == 'jpeg';
  }

  bool _isPdfExtension(String extension) => extension.toLowerCase() == 'pdf';

  String _extensionFromPath(String path) {
    if (path.isEmpty || !path.contains('.')) return '';
    return path.split('.').last;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final effectiveExtension = fileExtension.isNotEmpty
        ? fileExtension
        : _extensionFromPath(imagePath);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Container(
              height: 210,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AssetDetailColors.backgroundColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AssetDetailColors.borderColor,
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _buildPreviewContent(context, effectiveExtension),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: responsive.iconSize(28),
                    ),
                    SizedBox(height: responsive.spacing(6)),
                    const Text(
                      'Tap to replace',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (isLoading)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AssetDetailColors.surfaceColor,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(BuildContext context, String extension) {
    final responsive = ResponsiveUtils(context);
    if (imagePath.isEmpty) {
      return Center(
        child: Icon(
          Icons.description,
          size: responsive.iconSize(56),
          color: AssetDetailColors.textSecondary,
        ),
      );
    }

    if (_isImageExtension(extension)) {
      return _buildImageContent(context);
    }

    if (_isPdfExtension(extension)) {
      return _buildPdfContent(context, extension);
    }

    return _buildGenericFileContent(context, extension);
  }

  Widget _buildImageContent(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate reasonable cache dimensions to prevent memory issues
        const maxCacheDimension = 800;

        return SizedBox(
          width: constraints.maxWidth,
          height: constraints.maxHeight,
          child: isLocalFile
              ? Image.file(
                  File(imagePath),
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  cacheWidth: maxCacheDimension,
                  cacheHeight: maxCacheDimension,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image,
                      size: responsive.iconSize(56),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                )
              : Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  cacheWidth: maxCacheDimension,
                  cacheHeight: maxCacheDimension,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Icon(
                      Icons.broken_image,
                      size: responsive.iconSize(56),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                ),
        );
      },
    );
  }

  Widget _buildPdfContent(BuildContext context, String extension) {
    final responsive = ResponsiveUtils(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.picture_as_pdf,
          size: responsive.iconSize(56),
          color: AssetDetailColors.textSecondary,
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          '${extension.toUpperCase()} Document',
          style: TextStyle(
            color: AssetDetailColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildGenericFileContent(BuildContext context, String extension) {
    final responsive = ResponsiveUtils(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insert_drive_file,
          size: responsive.iconSize(56),
          color: AssetDetailColors.textSecondary,
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          extension.isNotEmpty ? extension.toUpperCase() : 'FILE',
          style: TextStyle(
            color: AssetDetailColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
