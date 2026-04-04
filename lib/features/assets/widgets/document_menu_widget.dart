import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../theme/asset_detail_colors.dart';
import '../../../utils/responsive_utils.dart';

/// Reusable 3-dot menu for document cards
/// Shows a dropdown with Download, Share, Delete options
/// Only one menu can be open at a time (handled by parent)
class DocumentMenu extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback onDownload;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final bool isMenuOpen;
  final VoidCallback onMenuToggle;
  final VoidCallback? onMenuClose;

  const DocumentMenu({
    super.key,
    this.onEdit,
    required this.onDownload,
    required this.onShare,
    required this.onDelete,
    required this.isMenuOpen,
    required this.onMenuToggle,
    this.onMenuClose,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return PopupMenuButton<DocumentMenuAction>(
      offset: const Offset(-50, 30),
      elevation: 8,
      itemBuilder: (BuildContext context) => [
        if (onEdit != null)
          PopupMenuItem<DocumentMenuAction>(
            value: DocumentMenuAction.edit,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.edit,
                  size: responsive.iconSize(18),
                  color: AssetDetailColors.textPrimary,
                ),
                SizedBox(width: responsive.spacing(12)),
                Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AssetDetailColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        PopupMenuItem<DocumentMenuAction>(
          value: DocumentMenuAction.download,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.download,
                size: responsive.iconSize(18),
                color: AssetDetailColors.textPrimary,
              ),
              SizedBox(width: responsive.spacing(12)),
              Text(
                'Download',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AssetDetailColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<DocumentMenuAction>(
          value: DocumentMenuAction.share,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.share,
                size: responsive.iconSize(18),
                color: AssetDetailColors.textPrimary,
              ),
              SizedBox(width: responsive.spacing(12)),
              Text(
                'Share',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AssetDetailColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<DocumentMenuAction>(
          value: DocumentMenuAction.delete,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delete_outline,
                size: responsive.iconSize(18),
                color: AppColors.errorMaterialDark,
              ),
              SizedBox(width: responsive.spacing(12)),
              Text(
                'Delete',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AppColors.errorMaterialDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (DocumentMenuAction action) {
        switch (action) {
          case DocumentMenuAction.edit:
            if (onEdit != null) {
              onEdit!();
            }
            break;
          case DocumentMenuAction.download:
            onDownload();
            break;
          case DocumentMenuAction.share:
            onShare();
            break;
          case DocumentMenuAction.delete:
            onDelete();
            break;
        }
      },
      onCanceled: () {
        onMenuClose?.call();
      },
      child: Container(
        padding: EdgeInsets.all(responsive.spacing(6)),
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowDark,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.more_vert,
          size: responsive.iconSize(18),
          color: AssetDetailColors.textPrimary,
        ),
      ),
    );
  }
}

enum DocumentMenuAction {
  edit,
  download,
  share,
  delete,
}