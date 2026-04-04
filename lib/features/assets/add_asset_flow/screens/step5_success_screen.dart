import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/asset_image_widget.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/asset_form_model.dart';

class Step5SuccessScreen extends StatelessWidget {
  final AssetFormModel formData;
  final VoidCallback onDone;

  const Step5SuccessScreen({
    super.key,
    required this.formData,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // ── Hero section with success icon ──
                _buildHeroSection(context),
                // ── Summary content ──
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: responsive.spacing(24)),
                      _buildAssetCard(context),
                      SizedBox(height: responsive.spacing(16)),
                      _buildDetailsSection(context),
                      SizedBox(height: responsive.spacing(16)),
                      _buildStatusSection(context),
                      SizedBox(height: responsive.spacing(24)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Fixed footer ──
        _buildFooter(context),
      ],
    );
  }

  /// Top hero section: gradient background + success icon + headline.
  Widget _buildHeroSection(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Close button row
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(20),
                vertical: responsive.spacing(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onDone,
                    child: Container(
                      padding: EdgeInsets.all(responsive.spacing(6)),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: responsive.iconSize(20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            // Success icon
            Container(
              width: responsive.spacing(72),
              height: responsive.spacing(72),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Icon(
                Icons.check_rounded,
                size: responsive.iconSize(38),
                color: AppColors.success,
              ),
            ),
            SizedBox(height: responsive.spacing(20)),
            Text(
              'Asset Added Successfully',
              style: TextStyle(
                fontSize: responsive.fontSize(22),
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: responsive.spacing(8)),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(40)),
              child: Text(
                '${formData.getAssetName()} has been added to your home',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: Colors.white.withValues(alpha: 0.8),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: responsive.spacing(28)),
          ],
        ),
      ),
    );
  }

  /// Product image + name card at top of content area.
  Widget _buildAssetCard(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    // Show the image panel when we have either a real URL OR a known failure
    // reason (quota, timeout, etc.) — so the user always gets context.
    final hasTried =
        _hasValue(formData.productImageUrl) ||
        formData.productImageSource != null;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          if (hasTried) ...[
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: AssetImageWidget(
                imageUrl: formData.productImageUrl,
                assetType: formData.selectedAssetType,
                imageSource: ImageSource.fromString(
                  formData.productImageSource,
                ),
                width: double.infinity,
                height: responsive.spacing(180),
                fit: BoxFit.contain,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                backgroundColor: AppColors.backgroundGray50,
              ),
            ),
          ],
          Padding(
            padding: EdgeInsets.all(responsive.spacing(20)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formData.getAssetName(),
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: responsive.spacing(6)),
                Row(
                  children: [
                    if (_hasValue(formData.selectedAssetType)) ...[
                      _buildInfoChip(
                        context,
                        formData.selectedAssetType!,
                        Icons.category_outlined,
                      ),
                      SizedBox(width: responsive.spacing(8)),
                    ],
                    if (_hasValue(formData.location))
                      _buildInfoChip(
                        context,
                        formData.location!,
                        Icons.location_on_outlined,
                      ),
                  ],
                ),
                // WiFi badge
                if (formData.isWifiDiscovered) ...[
                  SizedBox(height: responsive.spacing(10)),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(10),
                      vertical: responsive.spacing(5),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.wifi_rounded,
                          size: responsive.iconSize(14),
                          color: AppColors.success,
                        ),
                        SizedBox(width: responsive.spacing(5)),
                        Text(
                          'WiFi Verified',
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            fontWeight: FontWeight.w600,
                            color: AppColors.success,
                          ),
                        ),
                        if (formData.wifiConfidence != null) ...[
                          Text(
                            ' · ${formData.wifiConfidence}%',
                            style: TextStyle(
                              fontSize: responsive.fontSize(11),
                              color: AppColors.success.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Key details in a clean grouped card.
  Widget _buildDetailsSection(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    final details = <_DetailEntry>[];
    if (_hasValue(formData.brand)) {
      details.add(_DetailEntry('Brand', formData.brand!));
    }
    if (_hasValue(formData.model)) {
      details.add(_DetailEntry('Model', formData.model!));
    }
    if (_hasValue(formData.serial)) {
      details.add(_DetailEntry('Serial No.', formData.serial!));
    }
    if (_hasValue(formData.manufacturer) &&
        formData.manufacturer != formData.brand) {
      details.add(_DetailEntry('Manufacturer', formData.manufacturer!));
    }
    if (_hasValue(formData.productColor)) {
      details.add(_DetailEntry('Color', formData.productColor!));
    }
    if (_hasValue(formData.subCategory)) {
      details.add(_DetailEntry('Sub Category', formData.subCategory!));
    }
    final purchaseDate = _getPurchaseDateDisplay();
    if (purchaseDate != '-') {
      details.add(_DetailEntry('Purchased', purchaseDate));
    }
    if (formData.documentPaths.isNotEmpty) {
      details.add(
        _DetailEntry('Documents', '${formData.documentPaths.length} attached'),
      );
    }

    if (details.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              responsive.spacing(20),
              responsive.spacing(18),
              responsive.spacing(20),
              responsive.spacing(12),
            ),
            child: Text(
              'Asset Details',
              style: TextStyle(
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ),
          Divider(height: 1, color: AppColors.divider.withValues(alpha: 0.5)),
          Padding(
            padding: EdgeInsets.all(responsive.spacing(20)),
            child: Column(
              children: [
                for (int i = 0; i < details.length; i++) ...[
                  _buildDetailRow(context, details[i].label, details[i].value),
                  if (i < details.length - 1)
                    SizedBox(height: responsive.spacing(14)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Status badges — what was completed.
  Widget _buildStatusSection(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    final items = <_StatusItem>[
      const _StatusItem('Asset saved to your home', Icons.home_outlined),
    ];
    if (formData.enrichmentSource != null) {
      items.add(
        _StatusItem(
          'Product details verified via ${_formatSource(formData.enrichmentSource!)}',
          Icons.verified_outlined,
        ),
      );
    }
    if (formData.documentPaths.isNotEmpty) {
      items.add(
        _StatusItem(
          '${formData.documentPaths.length} document(s) attached',
          Icons.attachment_rounded,
        ),
      );
    }
    if (formData.isWifiDiscovered) {
      items.add(const _StatusItem('WiFi network confirmed', Icons.wifi_rounded));
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(20)),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildStatusRow(context, items[i]),
            if (i < items.length - 1) SizedBox(height: responsive.spacing(14)),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(BuildContext context, _StatusItem item) {
    final responsive = ResponsiveUtils(context);
    return Row(
      children: [
        Container(
          width: responsive.spacing(28),
          height: responsive.spacing(28),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_rounded,
            size: responsive.iconSize(16),
            color: AppColors.success,
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        Expanded(
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
              height: 1.3,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoChip(BuildContext context, String text, IconData icon) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(10),
        vertical: responsive.spacing(5),
      ),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: responsive.iconSize(13),
            color: AppColors.textSecondary,
          ),
          SizedBox(width: responsive.spacing(5)),
          Text(
            text,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final responsive = ResponsiveUtils(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: responsive.spacing(110),
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter(BuildContext context) {
    final responsive = ResponsiveUtils(context);
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
      child: SizedBox(
        width: double.infinity,
        height: responsive.spacing(52),
        child: ElevatedButton(
          onPressed: onDone,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: Text(
            'Done',
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  bool _hasValue(String? value) =>
      value != null && value.isNotEmpty && value != '-';

  String _formatSource(String source) {
    const labels = {
      'wifi_discovery': 'WiFi Discovery',
      'barcode_api': 'Barcode Lookup',
      'chatgpt': 'AI Analysis',
      'merged': 'Multiple Sources',
      'wifi_model_lookup': 'WiFi + Model Lookup',
      'manual': 'Manual Entry',
    };
    final parts = source.split('+');
    return parts.map((p) => labels[p.trim()] ?? p.trim()).join(' + ');
  }

  String _getPurchaseDateDisplay() {
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
    final year = formData.purchaseYear;
    final month = formData.purchaseMonth;
    if (year == null) return '-';
    if (month != null) {
      final idx = int.tryParse(month);
      if (idx != null && idx >= 1 && idx <= 12) {
        return '${monthNames[idx - 1]} $year';
      }
    }
    return year;
  }
}

class _DetailEntry {
  final String label;
  final String value;
  const _DetailEntry(this.label, this.value);
}

class _StatusItem {
  final String label;
  final IconData icon;
  const _StatusItem(this.label, this.icon);
}
