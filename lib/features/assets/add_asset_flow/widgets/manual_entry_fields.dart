import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Manual entry fields for brand, model number, serial number,
/// and additional extracted details (manufacturer, barcode, etc.).
class ManualEntryFields extends StatelessWidget {
  final TextEditingController brandController;
  final TextEditingController modelController;
  final TextEditingController serialController;
  final ValueChanged<String> onBrandChanged;
  final ValueChanged<String> onModelChanged;
  final ValueChanged<String> onSerialChanged;

  // Additional optional controllers for enriched data
  final TextEditingController? manufacturerController;
  final TextEditingController? barcodeController;
  final TextEditingController? productDescriptionController;
  final TextEditingController? colorController;
  final TextEditingController? productTitleController;
  final TextEditingController? productCategoryController;
  final TextEditingController? productTypeController;
  final Map<String, TextEditingController>? additionalInfoControllers;
  final String? productImageUrl;
  final bool isResolvingImage;
  final String? imageSource;

  /// Called when the user taps the retry button to re-fetch the product image
  /// using the current form field values.
  final VoidCallback? onRetryImage;
  final ValueChanged<String>? onManufacturerChanged;
  final ValueChanged<String>? onBarcodeChanged;
  final ValueChanged<String>? onProductDescriptionChanged;
  final ValueChanged<String>? onColorChanged;
  final ValueChanged<String>? onProductTitleChanged;
  final ValueChanged<String>? onProductCategoryChanged;

  const ManualEntryFields({
    super.key,
    required this.brandController,
    required this.modelController,
    required this.serialController,
    required this.onBrandChanged,
    required this.onModelChanged,
    required this.onSerialChanged,
    this.manufacturerController,
    this.barcodeController,
    this.productDescriptionController,
    this.colorController,
    this.productTitleController,
    this.productCategoryController,
    this.productTypeController,
    this.additionalInfoControllers,
    this.productImageUrl,
    this.isResolvingImage = false,
    this.imageSource,
    this.onRetryImage,
    this.onManufacturerChanged,
    this.onBarcodeChanged,
    this.onProductDescriptionChanged,
    this.onColorChanged,
    this.onProductTitleChanged,
    this.onProductCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasAdditionalInfoData =
        additionalInfoControllers != null &&
        additionalInfoControllers!.values.any((c) => c.text.isNotEmpty);

    final hasImage = productImageUrl != null && productImageUrl!.isNotEmpty;
    final showImageSection =
        hasImage || isResolvingImage || onRetryImage != null;

    // "More details" — secondary fields shown only when any have data
    final hasMoreDetails =
        _hasText(manufacturerController) ||
        _hasText(productDescriptionController) ||
        _hasText(colorController) ||
        _hasText(productTypeController) ||
        hasAdditionalInfoData;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── 1. Product image (always at top) ──────────────────────────────
        if (showImageSection) ...[
          _buildImageSection(hasImage),
          const SizedBox(height: 20),
        ],

        // ── 2. Brand ──────────────────────────────────────────────────────
        _buildTextField(
          label: 'Brand *',
          controller: brandController,
          placeholder: 'e.g. Samsung, Whirlpool',
          onChanged: onBrandChanged,
        ),
        const SizedBox(height: 16),

        // ── 3. Model Number ───────────────────────────────────────────────
        _buildTextField(
          label: 'Model Number *',
          controller: modelController,
          placeholder: 'e.g. RF28...',
          onChanged: onModelChanged,
        ),
        const SizedBox(height: 16),

        // ── 4. Serial Number ──────────────────────────────────────────────
        _buildTextField(
          label: 'Serial Number (Optional)',
          controller: serialController,
          placeholder: 'e.g. 12345...',
          onChanged: onSerialChanged,
        ),

        // ── 5. Product Title (if populated) ───────────────────────────────
        if (_hasText(productTitleController)) ...[
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Product Title',
            controller: productTitleController!,
            placeholder: 'Full product name',
            onChanged: onProductTitleChanged ?? (_) {},
          ),
        ],

        // ── 6. Category (if populated) ────────────────────────────────────
        if (_hasText(productCategoryController)) ...[
          const SizedBox(height: 16),
          _buildTextField(
            label: 'Category',
            controller: productCategoryController!,
            placeholder: 'Product category',
            onChanged: onProductCategoryChanged ?? (_) {},
          ),
        ],

        // ── More details ──────────────────────────────────────────────────
        if (hasMoreDetails) ...[
          const SizedBox(height: 20),
          Divider(color: AppColors.divider),
          const SizedBox(height: 8),
          Text(
            'More Details',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          if (_hasText(productTypeController))
            _buildAdditionalField(
              label: 'Product Type',
              controller: productTypeController!,
              placeholder: 'e.g. Refrigerator, Washer',
              onChanged: null,
            ),
          if (_hasText(manufacturerController))
            _buildAdditionalField(
              label: 'Manufacturer',
              controller: manufacturerController!,
              placeholder: 'Manufacturer name',
              onChanged: onManufacturerChanged,
            ),
          if (_hasText(colorController))
            _buildAdditionalField(
              label: 'Color',
              controller: colorController!,
              placeholder: 'e.g. Stainless Steel',
              onChanged: onColorChanged,
            ),
          if (_hasText(productDescriptionController))
            _buildAdditionalField(
              label: 'Product Description',
              controller: productDescriptionController!,
              placeholder: 'Product description',
              onChanged: onProductDescriptionChanged,
              maxLines: 3,
            ),
          // Dynamic additionalInfo fields (Manufactured, Made In, Voltage, etc.)
          if (additionalInfoControllers != null)
            ...additionalInfoControllers!.entries
                .where((e) => e.value.text.isNotEmpty)
                .map(
                  (e) => _buildAdditionalField(
                    label: _formatKey(e.key),
                    controller: e.value,
                    placeholder: _formatKey(e.key),
                    onChanged: null,
                  ),
                ),
        ],
      ],
    );
  }

  Widget _buildImageSection(bool hasImage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxHeight: 200, minHeight: 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppColors.backgroundGray50,
              border: Border.all(color: AppColors.gray200),
            ),
            clipBehavior: Clip.antiAlias,
            child: isResolvingImage
                // ── Loading state: shown on every fetch/retry ──────────────
                // If there's an old image we dim it and overlay a spinner so the
                // user sees something is happening. If no image yet, just spinner.
                ? Stack(
                    alignment: Alignment.center,
                    children: [
                      if (hasImage)
                        Opacity(
                          opacity: 0.25,
                          child: Image.network(
                            productImageUrl!,
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const SizedBox.shrink(),
                          ),
                        ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            hasImage
                                ? 'Updating image…'
                                : 'Finding product image…',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : hasImage
                // ── Image loaded ──────────────────────────────────────
                // key forces Flutter to create a new widget (and reload)
                // whenever the URL changes after a retry.
                ? AnimatedOpacity(
                    key: ValueKey(productImageUrl),
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 350),
                    child: Image.network(
                      productImageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 36),
                          child: Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primary,
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.broken_image_outlined,
                                size: 32,
                                color: AppColors.gray300,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Image unavailable',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                // ── No image yet ──────────────────────────────────────
                : Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_search_rounded,
                            size: 32,
                            color: AppColors.gray300,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No product image yet',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 8),
        // Retry button (right-aligned)
        Row(
          children: [
            const Spacer(),
            if (onRetryImage != null)
              GestureDetector(
                onTap: isResolvingImage ? null : onRetryImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isResolvingImage)
                        SizedBox(
                          width: 13,
                          height: 13,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: AppColors.primary,
                          ),
                        )
                      else
                        Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: AppColors.primary,
                        ),
                      const SizedBox(width: 5),
                      Text(
                        isResolvingImage ? 'Searching…' : 'Retry image',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isResolvingImage
                              ? AppColors.textSecondary
                              : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  bool _hasText(TextEditingController? controller) {
    return controller != null && controller.text.isNotEmpty;
  }

  /// Formats a camelCase or snake_case key into a readable label.
  String _formatKey(String key) {
    return key
        .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  Widget _buildAdditionalField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    ValueChanged<String>? onChanged,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: _buildTextField(
        label: label,
        controller: controller,
        placeholder: placeholder,
        onChanged: onChanged ?? (_) {},
        maxLines: maxLines,
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String placeholder,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: placeholder,
              hintStyle: TextStyle(color: AppColors.textSecondary),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
