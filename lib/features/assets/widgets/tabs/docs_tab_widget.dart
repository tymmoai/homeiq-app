import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../document_menu_widget.dart';
import '../document_widgets/document_viewer_screen.dart';

class DocsTabWidget extends StatelessWidget {
  final ScrollController scrollController;
  final List<Map<String, dynamic>> uploadedDocuments;
  final List<Map<String, dynamic>> defaultDocuments;
  final String? openMenuDocId;
  final Function(String?) onMenuToggle;
  final Function() onMenuClose;
  final Function({
    required bool isUploaded,
    int? documentIndex,
    int? defaultDocIndex,
  })
  onEditDocument;
  final Function({
    required bool isUploaded,
    int? documentIndex,
    int? defaultDocIndex,
    required String imagePath,
    required String title,
  })
  onDownloadDocument;
  final Function({
    required bool isUploaded,
    int? documentIndex,
    int? defaultDocIndex,
    required String imagePath,
    required String title,
  })
  onShareDocument;
  final Function({
    required bool isUploaded,
    int? uploadedIndex,
    int? defaultIndex,
  })
  onDeleteDocument;
  final Function() onUploadDocument;

  const DocsTabWidget({
    super.key,
    required this.scrollController,
    required this.uploadedDocuments,
    required this.defaultDocuments,
    required this.openMenuDocId,
    required this.onMenuToggle,
    required this.onMenuClose,
    required this.onEditDocument,
    required this.onDownloadDocument,
    required this.onShareDocument,
    required this.onDeleteDocument,
    required this.onUploadDocument,
  });

  @override
  Widget build(BuildContext context) {
    // Combine uploaded documents first (newest first), then default documents
    // Reverse uploaded documents list so newest appears first
    final reversedUploaded = uploadedDocuments.reversed.toList();
    final allDocuments = [...reversedUploaded, ...defaultDocuments];
    final responsive = ResponsiveUtils(context);

    return Container(
      color: AppColors.backgroundGray50,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth;
          final crossAxisCount = maxWidth < 360
              ? 1
              : maxWidth < 700
              ? 2
              : 3;
          final childAspectRatio = maxWidth < 360 ? 1.2 : 0.75;

          return SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.all(responsive.spacing(20.0)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Upload Document Button
                SizedBox(
                  width: double.infinity,
                  height: responsive.spacing(56.0),
                  child: ElevatedButton.icon(
                    onPressed: onUploadDocument,
                    icon: Icon(
                      Icons.upload,
                      size: responsive.iconSize(20.0),
                      color: AssetDetailColors.surfaceColor,
                    ),
                    label: Text(
                      'Upload Document',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w600,
                        color: AssetDetailColors.surfaceColor,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AssetDetailColors.primaryDark,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(12.0),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(24.0)),

                // Empty state when no documents
                if (allDocuments.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.spacing(60.0),
                      horizontal: responsive.spacing(24.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(12.0),
                      ),
                      border: Border.all(
                        color: AppColors.borderMedium.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: responsive.iconSize(48.0),
                          color: AssetDetailColors.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16.0)),
                        Text(
                          'No Documents',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16.0),
                            fontWeight: FontWeight.w600,
                            color: AssetDetailColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8.0)),
                        Text(
                          'Upload receipts, warranties, manuals, or service records to keep everything in one place.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: responsive.fontSize(13.0),
                            color: AssetDetailColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Documents Grid - responsive columns
                if (allDocuments.isNotEmpty)
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      mainAxisSpacing: responsive.spacing(12.0),
                      crossAxisSpacing: responsive.spacing(12.0),
                      childAspectRatio: childAspectRatio,
                    ),
                    itemCount: allDocuments.length,
                    itemBuilder: (context, index) {
                      final doc = allDocuments[index];
                      // Determine if uploaded based on position in the combined list,
                      // NOT by isLocalFile (which changes when a default doc's image is replaced)
                      final isUploaded = index < reversedUploaded.length;
                      // Calculate document index based on type
                      final docIndex = isUploaded
                          ? uploadedDocuments.length -
                                1 -
                                index // For uploaded: reverse index
                          : index -
                                reversedUploaded
                                    .length; // For default: index in default list
                      return _buildDocumentCard(
                        context,
                        doc['title'] as String,
                        doc['date'] as String,
                        doc['fileInfo'] as String,
                        doc['imagePath'] as String? ??
                            'lib/asset_img/doc_waarranty.jpg',
                        isUploaded: isUploaded,
                        isDefault: !isUploaded,
                        isLocalFile: doc['isLocalFile'] == true,
                        documentIndex: isUploaded ? docIndex : null,
                        defaultDocIndex: !isUploaded ? docIndex : null,
                      );
                    },
                  ),
                SizedBox(height: responsive.spacing(20.0)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDocumentCard(
    BuildContext context,
    String title,
    String uploadDate,
    String fileInfo,
    String imagePath, {
    bool isUploaded = false,
    bool isDefault = false,
    bool isLocalFile = false,
    int? documentIndex,
    int? defaultDocIndex,
  }) {
    final responsive = ResponsiveUtils(context);
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            _openDocumentViewer(context, imagePath, title);
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                responsive.borderRadius(12.0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: responsive.spacing(8.0),
                  offset: Offset(0, responsive.spacing(2.0)),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Document Preview (Half visible - showing actual document image)
                Expanded(
                  child: ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(
                              responsive.borderRadius(12.0),
                            ),
                            topRight: Radius.circular(
                              responsive.borderRadius(12.0),
                            ),
                          ),
                          child: Container(
                            width: constraints.maxWidth,
                            height: constraints.maxHeight,
                            color: AssetDetailColors.backgroundColor,
                            child: Stack(
                              children: [
                                // Document Image Preview
                                Positioned.fill(
                                  child: Padding(
                                    padding: EdgeInsets.all(
                                      responsive.spacing(12.0),
                                    ),
                                    child: isLocalFile
                                        ? Image.file(
                                            File(imagePath),
                                            fit: BoxFit.contain,
                                            width:
                                                constraints.maxWidth -
                                                responsive.spacing(24.0),
                                            height:
                                                constraints.maxHeight -
                                                responsive.spacing(24.0),
                                            cacheWidth: 600,
                                            cacheHeight: 600,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: AssetDetailColors
                                                        .surfaceColor,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.description,
                                                        size: responsive
                                                            .iconSize(40.0),
                                                        color: AssetDetailColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          )
                                        : Image.asset(
                                            imagePath,
                                            fit: BoxFit.contain,
                                            width:
                                                constraints.maxWidth -
                                                responsive.spacing(24.0),
                                            height:
                                                constraints.maxHeight -
                                                responsive.spacing(24.0),
                                            cacheWidth: 600,
                                            cacheHeight: 600,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                                  return Container(
                                                    color: AssetDetailColors
                                                        .surfaceColor,
                                                    child: Center(
                                                      child: Icon(
                                                        Icons.description,
                                                        size: responsive
                                                            .iconSize(40.0),
                                                        color: AssetDetailColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  );
                                                },
                                          ),
                                  ),
                                ),
                                // Gradient overlay to show it's cut off (half visible)
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: responsive.spacing(40.0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          AssetDetailColors.backgroundColor
                                              .withValues(alpha: 0.0),
                                          AssetDetailColors.backgroundColor,
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                // Document Info
                Padding(
                  padding: EdgeInsets.all(responsive.spacing(12.0)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          fontWeight: FontWeight.bold,
                          color: AssetDetailColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: responsive.spacing(8.0)),
                      // Simplified info: Date • Size (no file type, no pages)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: responsive.iconSize(12.0),
                            color: AssetDetailColors.textSecondary,
                          ),
                          SizedBox(width: responsive.spacing(4.0)),
                          Text(
                            _convertToUSDateFormat(uploadDate),
                            style: TextStyle(
                              fontSize: responsive.fontSize(12.0),
                              color: AssetDetailColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8.0)),
                          Text(
                            '•',
                            style: TextStyle(
                              fontSize: responsive.fontSize(12.0),
                              color: AssetDetailColors.textSecondary,
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8.0)),
                          Expanded(
                            child: Builder(
                              builder: (context) {
                                // Try to get documentSize field first, fallback to extracting from fileInfo
                                String sizeText = 'Unknown';
                                if (isUploaded &&
                                    documentIndex != null &&
                                    documentIndex < uploadedDocuments.length) {
                                  final doc = uploadedDocuments[documentIndex];
                                  sizeText =
                                      (doc['documentSize'] as String?) ??
                                      _extractSizeFromFileInfo(fileInfo);
                                } else if (isDefault &&
                                    defaultDocIndex != null &&
                                    defaultDocIndex < defaultDocuments.length) {
                                  final doc = defaultDocuments[defaultDocIndex];
                                  sizeText =
                                      (doc['documentSize'] as String?) ??
                                      _extractSizeFromFileInfo(fileInfo);
                                } else {
                                  sizeText = _extractSizeFromFileInfo(fileInfo);
                                }
                                return Text(
                                  sizeText,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(12.0),
                                    color: AssetDetailColors.textSecondary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // 3-dot menu button for all documents
        if ((isUploaded && documentIndex != null) ||
            (isDefault && defaultDocIndex != null))
          Positioned(
            top: 8,
            right: 8,
            child: DocumentMenu(
              isMenuOpen:
                  openMenuDocId ==
                  (isUploaded
                      ? 'uploaded_$documentIndex'
                      : 'default_$defaultDocIndex'),
              onMenuToggle: () {
                final docId = isUploaded
                    ? 'uploaded_$documentIndex'
                    : 'default_$defaultDocIndex';
                onMenuToggle(openMenuDocId == docId ? null : docId);
              },
              onMenuClose: onMenuClose,
              onEdit: () => onEditDocument(
                isUploaded: isUploaded,
                documentIndex: documentIndex,
                defaultDocIndex: defaultDocIndex,
              ),
              onDownload: () => onDownloadDocument(
                isUploaded: isUploaded,
                documentIndex: documentIndex,
                defaultDocIndex: defaultDocIndex,
                imagePath: imagePath,
                title: title,
              ),
              onShare: () => onShareDocument(
                isUploaded: isUploaded,
                documentIndex: documentIndex,
                defaultDocIndex: defaultDocIndex,
                imagePath: imagePath,
                title: title,
              ),
              onDelete: () => onDeleteDocument(
                isUploaded: isUploaded,
                uploadedIndex: documentIndex,
                defaultIndex: defaultDocIndex,
              ),
            ),
          ),
      ],
    );
  }

  String _extractSizeFromFileInfo(String fileInfo) {
    if (fileInfo.isEmpty) return 'Unknown';
    final parts = fileInfo.split('•').map((p) => p.trim()).toList();
    // Second part is typically the size
    if (parts.length > 1) {
      return parts[1];
    }
    return 'Unknown';
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

  void _openDocumentViewer(
    BuildContext context,
    String imagePath,
    String title,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            DocumentViewerScreen(imagePath: imagePath, title: title),
      ),
    );
  }
}
