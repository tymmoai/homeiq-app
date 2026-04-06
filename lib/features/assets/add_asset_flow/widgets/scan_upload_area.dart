import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/barcode_lookup_service.dart';
import '../widgets/dashed_border_widget.dart';

/// Displays the barcode scan area with:
///  - "Tap to Scan Barcode" prompt (initial state)
///  - Loading spinner while looking up product
///  - Scanned product details (success state)
///  - Error message with retry/manual options (error state)
class ScanUploadArea extends StatelessWidget {
  final bool isLookingUp;
  final String? scannedBarcode;
  final BarcodeProduct? scannedProduct;
  final String? scanError;
  final bool detailsExtracted;
  final String? brand;
  final String? model;
  final String? serial;
  final VoidCallback onScanTap;
  final VoidCallback onScanAgain;
  final VoidCallback onEnterManually;

  /// True when the scan detected useful info (serial/model) but no full product match.
  final bool isPartial;

  /// Detailed info about what was detected from the scanned value.
  final ScannedValueInfo? partialInfo;

  /// Enriched result from the 3-tier pipeline (Barcode API + ChatGPT).
  final EnrichedScanResult? enrichedResult;

  /// True while ChatGPT enrichment is running in background.
  final bool isEnriching;

  /// Loading stage message (e.g., "Looking up barcode...", "Identifying product with AI...")
  final String? loadingMessage;

  const ScanUploadArea({
    super.key,
    required this.isLookingUp,
    required this.scannedBarcode,
    required this.scannedProduct,
    required this.scanError,
    required this.detailsExtracted,
    required this.brand,
    required this.model,
    required this.serial,
    required this.onScanTap,
    required this.onScanAgain,
    required this.onEnterManually,
    this.isPartial = false,
    this.partialInfo,
    this.enrichedResult,
    this.isEnriching = false,
    this.loadingMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Looking up product ──
        if (isLookingUp) _buildLookingUpState(),

        // ── Enriched success: full product data from pipeline ──
        if (!isLookingUp && enrichedResult != null && enrichedResult!.isSuccess)
          _buildEnrichedSuccessState(),

        // ── Partial match: serial/model detected but no full product ──
        if (!isLookingUp &&
            enrichedResult == null &&
            isPartial &&
            partialInfo != null)
          _buildPartialMatchState(),

        // ── Error state ──
        if (!isLookingUp &&
            enrichedResult == null &&
            !isPartial &&
            scanError != null)
          _buildErrorState(),

        // ── Legacy success: product found (Barcode API only) ──
        if (!isLookingUp &&
            enrichedResult == null &&
            detailsExtracted &&
            scannedProduct != null)
          _buildSuccessState(),

        // ── Initial state: tap to scan ──
        if (!isLookingUp &&
            enrichedResult == null &&
            !detailsExtracted &&
            !isPartial &&
            scanError == null)
          _buildInitialScanArea(),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  INITIAL STATE — "Tap to Scan Barcode"
  // ═══════════════════════════════════════════════════════════════
  Widget _buildInitialScanArea() {
    return GestureDetector(
      onTap: onScanTap,
      child: DashedBorder(
        color: AppColors.primary,
        strokeWidth: 2.0,
        dashWidth: 8.0,
        dashSpace: 4.0,
        borderRadius: 12.0,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 40),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary05,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.qr_code_scanner,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Tap to Scan Barcode',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'Point your camera at the barcode on the product packaging or label.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              // Supported formats badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'UPC · EAN · QR Code · ISBN',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  PARTIAL MATCH — serial / model detected from appliance label
  // ═══════════════════════════════════════════════════════════════
  Widget _buildPartialMatchState() {
    final info = partialInfo!;
    final typeLabel = switch (info.type) {
      ScannedValueType.serialNumber => 'Serial Number',
      ScannedValueType.modelNumber => 'Model Number',
      ScannedValueType.manufacturerUrl => 'Product QR Code',
      ScannedValueType.unknownCode => 'Scanned Code',
    };
    final typeIcon = switch (info.type) {
      ScannedValueType.serialNumber => Icons.numbers,
      ScannedValueType.modelNumber => Icons.inventory_2_outlined,
      ScannedValueType.manufacturerUrl => Icons.qr_code_2,
      ScannedValueType.unknownCode => Icons.barcode_reader,
    };

    return Column(
      children: [
        // Detected info card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Info icon + header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(typeIcon, size: 36, color: const Color(0xFF2196F3)),
              ),
              const SizedBox(height: 12),
              Text(
                '$typeLabel Detected',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                info.userMessage,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Detected values grid
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    if (info.brand != null)
                      _partialDetailRow('Brand', info.brand!),
                    if (info.serialNumber != null)
                      _partialDetailRow('Serial', info.serialNumber!),
                    if (info.modelNumber != null)
                      _partialDetailRow('Model', info.modelNumber!),
                    if (info.url != null)
                      _partialDetailRow('URL', info.url!, isSmall: true),
                    _partialDetailRow('Raw Scan', info.rawValue, isSmall: true),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Extracted details confirmation
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF2196F3).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.auto_fix_high,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Details auto-filled below',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2196F3),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (brand != null && brand!.isNotEmpty)
                          _miniChip('Brand: $brand'),
                        if (model != null && model!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _miniChip('Model: $model'),
                        ],
                        if (serial != null && serial!.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          _miniChip('Serial'),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Action buttons
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onScanAgain,
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: const Text('Scan Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEnterManually,
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Edit Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _partialDetailRow(String label, String value, {bool isSmall = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: isSmall ? 11 : 14,
                fontWeight: isSmall ? FontWeight.w400 : FontWeight.w600,
                color: isSmall ? AppColors.textLight : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Color(0xFF2196F3),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ENRICHED SUCCESS STATE — full product data from 3-tier pipeline
  // ═══════════════════════════════════════════════════════════════
  Widget _buildEnrichedSuccessState() {
    final result = enrichedResult!;
    return Column(
      children: [
        // ── Generic URL Warning Banner ──
        if (result.isGenericUrl || result.userGuidanceMessage != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFF9800).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFFE65100),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'QR code has no product details',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFE65100),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        result.userGuidanceMessage ??
                            'This QR code is a generic link. Please scan the barcode near the model number on your label, or enter the model number manually below.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4E342E),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Asset details card — brand, model, serial only
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    result.isGenericUrl && result.model.isEmpty
                        ? Icons.warning_amber_rounded
                        : Icons.check_circle,
                    color: result.isGenericUrl && result.model.isEmpty
                        ? const Color(0xFFFF9800)
                        : AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.isGenericUrl && result.model.isEmpty
                          ? 'Brand detected — model number needed'
                          : 'Asset identified!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: result.isGenericUrl && result.model.isEmpty
                            ? const Color(0xFFE65100)
                            : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _detailColumn(
                      'Brand',
                      result.brand.isNotEmpty ? result.brand : '-',
                    ),
                  ),
                  Expanded(
                    child: _detailColumn(
                      'Model',
                      result.model.isNotEmpty ? result.model : '-',
                    ),
                  ),
                  if (result.serialNumber.isNotEmpty)
                    Expanded(
                      child: _detailColumn('Serial', result.serialNumber),
                    ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Scan another button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan a Different Barcode'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LOOKING UP STATE — loading spinner
  // ═══════════════════════════════════════════════════════════════
  Widget _buildLookingUpState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            loadingMessage ?? 'Looking up product...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Barcode: ${scannedBarcode ?? ''}',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  ERROR STATE — product not found / API error
  // ═══════════════════════════════════════════════════════════════
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            scanError ?? 'Something went wrong.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (scannedBarcode != null) ...[
            const SizedBox(height: 4),
            Text(
              'Barcode: $scannedBarcode',
              style: TextStyle(fontSize: 12, color: AppColors.textLight),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onScanAgain,
                  icon: const Icon(Icons.qr_code_scanner, size: 18),
                  label: const Text('Scan Again'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onEnterManually,
                  icon: const Icon(Icons.edit_note, size: 18),
                  label: const Text('Enter Manually'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SUCCESS STATE — product details extracted
  // ═══════════════════════════════════════════════════════════════
  Widget _buildSuccessState() {
    return Column(
      children: [
        // Asset details card — brand, model, serial only
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.successLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Asset identified!',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _detailColumn('Brand', brand ?? '-')),
                  Expanded(child: _detailColumn('Model', model ?? '-')),
                  Expanded(child: _detailColumn('Serial', serial ?? '-')),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Scan another button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onScanAgain,
            icon: const Icon(Icons.qr_code_scanner, size: 18),
            label: const Text('Scan a Different Barcode'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
