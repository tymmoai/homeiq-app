import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../models/api_models.dart';
import '../../../shared/models/asset_form_model.dart';
import 'step1_type_selection_screen.dart';
import 'step2_identify_screen.dart';
import 'step3_details_screen.dart';
import 'step4_documents_screen.dart';
import 'step5_success_screen.dart';

class AddAssetFlowScreen extends StatefulWidget {
  final Future<void> Function(Map<String, dynamic>)? onAssetAdded;

  /// Already-saved assets for the current home — used for duplicate detection.
  final List<AssetDto> existingAssets;

  const AddAssetFlowScreen({
    super.key,
    this.onAssetAdded,
    this.existingAssets = const [],
  });

  @override
  State<AddAssetFlowScreen> createState() => _AddAssetFlowScreenState();
}

class _AddAssetFlowScreenState extends State<AddAssetFlowScreen> {
  final AssetFormModel _formData = AssetFormModel()
    ..selectedCategory =
        'Appliances' // Default to Appliances
    ..identificationMethod = 'photo'; // Default to Upload Label Photo
  int _currentStep = 1;
  bool _isSaving = false;
  Map<String, dynamic>? _builtAssetMap;

  // Track what type was selected when the user last left Step 1,
  // so we can detect changes if they come back.
  String? _lastConfirmedCategory;
  String? _lastConfirmedAssetType;

  void _goToNextStep() {
    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _goToPreviousStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  /// Called when Step 1 completes. If the user changed the asset type
  /// compared to the last time they left Step 1, wipe Steps 2-3 data
  /// so they start fresh for the new type.
  void _onStep1Complete() {
    final categoryChanged =
        _lastConfirmedCategory != null &&
        _lastConfirmedCategory != _formData.selectedCategory;
    final typeChanged =
        _lastConfirmedAssetType != null &&
        _lastConfirmedAssetType != _formData.selectedAssetType;

    if (categoryChanged || typeChanged) {
      // Preserve only Step 1 selections — clear everything else
      final savedCategory = _formData.selectedCategory;
      final savedAssetType = _formData.selectedAssetType;
      _formData.reset();
      _formData.selectedCategory = savedCategory;
      _formData.selectedAssetType = savedAssetType;
      _formData.identificationMethod = 'photo'; // default
    }

    _lastConfirmedCategory = _formData.selectedCategory;
    _lastConfirmedAssetType = _formData.selectedAssetType;
    _goToNextStep();
  }

  void _onStepComplete() {
    _goToNextStep();
  }

  /// Checks whether any existing asset is a likely duplicate of the
  /// current form data. Returns the first matching asset + reason, or null.
  ({AssetDto asset, String reason, String detail})? _findDuplicate() {
    final serial = _formData.serial?.trim().toLowerCase();
    final barcode = _formData.barcode?.trim().toLowerCase();
    final mac = _formData.wifiDeviceMac?.trim().toLowerCase();
    final model = _formData.model?.trim().toLowerCase();
    final brand = _formData.brand?.trim().toLowerCase();

    for (final existing in widget.existingAssets) {
      // Strong match — serial number
      if (serial != null &&
          serial.isNotEmpty &&
          existing.serialNumber != null &&
          existing.serialNumber!.trim().toLowerCase() == serial) {
        return (
          asset: existing,
          reason: 'Same serial number',
          detail: _formData.serial!,
        );
      }
      // Strong match — barcode / UPC
      if (barcode != null &&
          barcode.isNotEmpty &&
          existing.barcode != null &&
          existing.barcode!.trim().toLowerCase() == barcode) {
        return (
          asset: existing,
          reason: 'Same barcode',
          detail: _formData.barcode!,
        );
      }
      // Strong match — WiFi MAC address
      if (mac != null &&
          mac.isNotEmpty &&
          existing.networkMac != null &&
          existing.networkMac!.trim().toLowerCase() == mac) {
        return (
          asset: existing,
          reason: 'Same network device (MAC)',
          detail: _formData.wifiDeviceMac!,
        );
      }
      // Probable match — model + brand together
      if (model != null &&
          model.isNotEmpty &&
          brand != null &&
          brand.isNotEmpty &&
          existing.model != null &&
          existing.brand != null &&
          existing.model!.trim().toLowerCase() == model &&
          existing.brand!.trim().toLowerCase() == brand) {
        return (
          asset: existing,
          reason: 'Same brand & model',
          detail: '${_formData.brand} ${_formData.model}',
        );
      }
    }
    return null;
  }

  /// Shows the duplicate asset bottom sheet. Returns true if the user
  /// chose to add anyway, false if they went back to edit.
  Future<bool> _showDuplicateSheet(
    AssetDto existing,
    String reason,
    String detail,
  ) async {
    final result = await showModalBottomSheet<_DuplicateAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _DuplicateAssetSheet(
        existingAsset: existing,
        matchReason: reason,
        matchDetail: detail,
      ),
    );
    if (!mounted) return false;
    if (result == _DuplicateAction.viewExisting) {
      // Pop the add-asset flow and let the user see the existing asset
      Navigator.of(context).pop();
      return false;
    }
    if (result == _DuplicateAction.addAnyway) {
      return true;
    }
    // null / goBack — dismiss sheet, stay on step 4
    return false;
  }

  /// Transition from Step 4 to Step 5: run duplicate check first, then
  /// build the asset map, call the backend via onAssetAdded callback,
  /// and show the success screen.
  Future<void> _onStep4Complete() async {
    // --- Duplicate check (before any loading state) ---
    final dup = _findDuplicate();
    if (dup != null) {
      final proceed = await _showDuplicateSheet(
        dup.asset,
        dup.reason,
        dup.detail,
      );
      if (!proceed) return; // user chose to go back or view existing
    }

    setState(() {
      _isSaving = true;
    });

    try {
      _buildAssetMap();

      // Await the callback so asset + documents are fully uploaded before
      // showing the success screen (prevents docs tab from loading before URL is set)
      if (widget.onAssetAdded != null && _builtAssetMap != null) {
        await widget.onAssetAdded!(_builtAssetMap!);
      }

      // Move to success screen only after everything is persisted
      setState(() {
        _isSaving = false;
        _currentStep = 5;
      });
    } on Object catch (_) {
      setState(() {
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save asset. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Done button on success screen — just pop back
  void _onSuccessDone() {
    Navigator.of(context).pop(_builtAssetMap);
  }

  void _buildAssetMap() {
    // Parse purchase year for date calculations
    final now = DateTime.now();
    final purchaseYearInt = _formData.purchaseYear != null
        ? int.tryParse(_formData.purchaseYear!)
        : null;

    // Build purchaseDate string (e.g., "Jan 2019") for display in asset card
    final months = [
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
    String? purchaseDateStr;
    if (purchaseYearInt != null) {
      // Use selected month if available, otherwise omit month
      if (_formData.purchaseMonth != null) {
        final monthIdx = int.tryParse(_formData.purchaseMonth!);
        if (monthIdx != null && monthIdx >= 1 && monthIdx <= 12) {
          purchaseDateStr = '${months[monthIdx - 1]} $purchaseYearInt';
        } else {
          purchaseDateStr = '$purchaseYearInt';
        }
      } else {
        purchaseDateStr = '$purchaseYearInt';
      }
    }

    // Calculate warranty end date based on enriched warranty duration or default 1 year
    final DateTime warrantyEnd;
    final warrantyDuration =
        _formData.warrantyDetails?['duration']?.toString().toLowerCase() ?? '';
    final int warrantyYears;
    if (warrantyDuration.contains('lifetime')) {
      warrantyYears = 25;
    } else {
      // Extract the first number from the duration string (e.g. '2 years' → 2)
      final match = RegExp(r'(\d+)').firstMatch(warrantyDuration);
      final parsed = match != null ? int.tryParse(match.group(1)!) : null;
      if (parsed != null && parsed > 0 && parsed <= 25) {
        warrantyYears = parsed;
      } else {
        warrantyYears = 1; // Default: 1 year
      }
    }

    // Warranty starts from purchase date if known, otherwise from now
    if (purchaseYearInt != null) {
      final purchaseMonthInt = _formData.purchaseMonth != null
          ? (int.tryParse(_formData.purchaseMonth!) ?? 1)
          : 1;
      warrantyEnd = DateTime(
        purchaseYearInt + warrantyYears,
        purchaseMonthInt,
        1,
      );
    } else {
      warrantyEnd = DateTime(now.year + warrantyYears, now.month, now.day);
    }

    // Determine warranty status based on calculated end date
    final isWarrantyActive = warrantyEnd.isAfter(now);

    // New asset — no service history yet
    String lastService = 'Never';

    // Compute an initial health score for the new asset.
    // Scale: 10 = pristine, 5 = concern. Factors:
    //   - age in years (penalty)
    //   - warranty active (bonus) / expired (penalty)
    //   - WiFi confidence score available (small bonus)
    //   - product data enriched (small bonus)
    double healthScore = 9.5;
    if (purchaseYearInt != null) {
      final ageYears = now.year - purchaseYearInt;
      healthScore -= (ageYears * 0.3).clamp(0.0, 3.5);
    }
    if (!isWarrantyActive) {
      healthScore -= 1.5;
    }
    if (_formData.wifiConfidence != null && _formData.wifiConfidence! >= 80) {
      healthScore += 0.1;
    }
    if (_formData.productImageUrl != null &&
        _formData.productImageUrl!.isNotEmpty) {
      healthScore += 0.1;
    }
    healthScore = healthScore.clamp(5.0, 9.5);

    // Build asset data map — backend is the source of truth for persistence.
    // This map is used for immediate local display and backend API call payload.
    final assetMap = <String, dynamic>{
      'name':
          _formData.productTitle != null && _formData.productTitle!.isNotEmpty
          ? _formData.productTitle!
          : '${_formData.brand ?? ''} ${_formData.selectedAssetType ?? ''}'
                .trim(),
      // Store productTitle separately so backend can persist the enriched title
      if (_formData.productTitle != null && _formData.productTitle!.isNotEmpty)
        'productTitle': _formData.productTitle,
      'type': _formData.selectedAssetType ?? 'Unknown',
      'location': _formData.location,
      'model': _formData.model,
      'serial': _formData.serial,
      'serialNumber': _formData.serial,
      'brand': _formData.brand,
      'warranty': isWarrantyActive ? 'Active' : 'Expired',
      'warrantyEndDate': warrantyEnd.toIso8601String(),
      'lastService': lastService,
      'healthScore': double.parse(healthScore.toStringAsFixed(1)),
      'isNewAsset': true,
    };

    // Include scanned product data if available (from barcode scanning)
    if (_formData.productImageUrl != null &&
        _formData.productImageUrl!.isNotEmpty) {
      assetMap['productImageUrl'] = _formData.productImageUrl;
    }
    if (_formData.productDescription != null &&
        _formData.productDescription!.isNotEmpty) {
      assetMap['description'] = _formData.productDescription;
    }
    if (_formData.productCategory != null &&
        _formData.productCategory!.isNotEmpty) {
      assetMap['productCategory'] = _formData.productCategory;
    }
    if (_formData.manufacturer != null && _formData.manufacturer!.isNotEmpty) {
      assetMap['manufacturer'] = _formData.manufacturer;
    }
    if (_formData.barcode != null && _formData.barcode!.isNotEmpty) {
      assetMap['barcode'] = _formData.barcode;
    }
    if (_formData.subCategory != null && _formData.subCategory!.isNotEmpty) {
      assetMap['subCategory'] = _formData.subCategory;
    }
    if (_formData.photoPath != null && _formData.photoPath!.isNotEmpty) {
      assetMap['photoPath'] = _formData.photoPath;
    }

    // Include enriched data from ChatGPT (specs, warranty, support URLs)
    if (_formData.productColor != null && _formData.productColor!.isNotEmpty) {
      assetMap['productColor'] = _formData.productColor;
    }
    if (_formData.productSpecs != null && _formData.productSpecs!.isNotEmpty) {
      assetMap['productSpecs'] = _formData.productSpecs;
    }
    if (_formData.warrantyDetails != null &&
        _formData.warrantyDetails!.isNotEmpty) {
      assetMap['warrantyDetails'] = _formData.warrantyDetails;
    }
    if (_formData.supportUrl != null && _formData.supportUrl!.isNotEmpty) {
      assetMap['supportUrl'] = _formData.supportUrl;
    }
    if (_formData.manualUrl != null && _formData.manualUrl!.isNotEmpty) {
      assetMap['manualUrl'] = _formData.manualUrl;
    }
    if (_formData.enrichmentSource != null &&
        _formData.enrichmentSource!.isNotEmpty) {
      assetMap['enrichmentSource'] = _formData.enrichmentSource;
    }

    // Include manufacture info from label scan
    if (_formData.manufacturedYear != null &&
        _formData.manufacturedYear!.isNotEmpty) {
      assetMap['manufacturedYear'] = _formData.manufacturedYear;
    }
    if (_formData.madeIn != null && _formData.madeIn!.isNotEmpty) {
      assetMap['madeIn'] = _formData.madeIn;
    }

    // Include identification method so backend knows the source path
    if (_formData.identificationMethod != null) {
      assetMap['identificationMethod'] = _formData.identificationMethod;
    }

    // Include WiFi discovery metadata for backend persistence and verification
    if (_formData.isWifiDiscovered) {
      assetMap['isWifiDiscovered'] = true;
      // Map WiFi MAC/IP to backend's networkMac/networkIp fields
      if (_formData.wifiDeviceMac != null) {
        assetMap['networkMac'] = _formData.wifiDeviceMac;
      }
      if (_formData.wifiDeviceIp != null) {
        assetMap['networkIp'] = _formData.wifiDeviceIp;
      }
      if (_formData.wifiDeviceIp != null) {
        assetMap['wifiDeviceIp'] = _formData.wifiDeviceIp;
      }
      if (_formData.wifiDeviceName != null) {
        assetMap['wifiDeviceName'] = _formData.wifiDeviceName;
      }
      if (_formData.wifiDeviceMac != null) {
        assetMap['wifiDeviceMac'] = _formData.wifiDeviceMac;
      }
      if (_formData.wifiHostname != null) {
        assetMap['wifiHostname'] = _formData.wifiHostname;
      }
      if (_formData.wifiOpenPorts != null) {
        assetMap['wifiOpenPorts'] = _formData.wifiOpenPorts;
      }
      if (_formData.wifiFirmware != null) {
        assetMap['wifiFirmware'] = _formData.wifiFirmware;
      }
      if (_formData.wifiOsHint != null) {
        assetMap['wifiOsHint'] = _formData.wifiOsHint;
      }
      if (_formData.wifiSshBanner != null) {
        assetMap['wifiSshBanner'] = _formData.wifiSshBanner;
      }
      if (_formData.wifiTlsCert != null) {
        assetMap['wifiTlsCert'] = _formData.wifiTlsCert;
      }
      if (_formData.wifiSmbOs != null) {
        assetMap['wifiSmbOs'] = _formData.wifiSmbOs;
      }
      if (_formData.wifiConfidence != null) {
        assetMap['wifiConfidence'] = _formData.wifiConfidence;
      }
      if (_formData.wifiDiscoveryMethod != null) {
        assetMap['wifiDiscoveryMethod'] = _formData.wifiDiscoveryMethod;
      }
      if (_formData.wifiHttpBanner != null) {
        assetMap['wifiHttpBanner'] = _formData.wifiHttpBanner;
      }
      if (_formData.wifiHtmlTitle != null) {
        assetMap['wifiHtmlTitle'] = _formData.wifiHtmlTitle;
      }
    }

    // Only set purchase fields if user selected a year
    if (purchaseYearInt != null) {
      assetMap['purchaseYear'] = purchaseYearInt;
      assetMap['purchaseDate'] = purchaseDateStr;
    }
    // Always persist purchaseMonth if the user selected one
    if (_formData.purchaseMonth != null) {
      final monthInt = int.tryParse(_formData.purchaseMonth!);
      if (monthInt != null) assetMap['purchaseMonth'] = monthInt;
    }

    // Include uploaded documents from form data
    if (_formData.documentPaths.isNotEmpty) {
      assetMap['documentPaths'] = List<String>.from(_formData.documentPaths);
      assetMap['documentTypes'] = List<String>.from(_formData.documentTypes);
    }

    _builtAssetMap = assetMap;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentStep == 1,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentStep > 1) {
          _goToPreviousStep();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray50,
        body: SafeArea(child: _buildCurrentStep()),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 1:
        return Step1TypeSelectionScreen(
          formData: _formData,
          onNext: _onStep1Complete,
          onBack: _goToPreviousStep,
        );
      case 2:
        return Step2IdentifyScreen(
          formData: _formData,
          onNext: _onStepComplete,
          onBack: _goToPreviousStep,
        );
      case 3:
        return Step3DetailsScreen(
          formData: _formData,
          onNext: _onStepComplete,
          onBack: _goToPreviousStep,
        );
      case 4:
        return Stack(
          children: [
            Step4DocumentsScreen(
              formData: _formData,
              onNext: _onStep4Complete,
              onBack: _goToPreviousStep,
            ),
            if (_isSaving)
              Container(
                color: Colors.black.withValues(alpha: 0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text(
                          'Saving your asset...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      case 5:
        return Step5SuccessScreen(formData: _formData, onDone: _onSuccessDone);
      default:
        return Step1TypeSelectionScreen(
          formData: _formData,
          onNext: _onStepComplete,
          onBack: _goToPreviousStep,
        );
    }
  }
}

// ─── Duplicate action result ──────────────────────────────────────────────────

enum _DuplicateAction { viewExisting, addAnyway, goBack }

// ─── Duplicate Asset Bottom Sheet ─────────────────────────────────────────────

class _DuplicateAssetSheet extends StatelessWidget {
  final AssetDto existingAsset;
  final String matchReason;
  final String matchDetail;

  const _DuplicateAssetSheet({
    required this.existingAsset,
    required this.matchReason,
    required this.matchDetail,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottomInset = mq.padding.bottom;
    final screenWidth = mq.size.width;

    return Container(
      margin: EdgeInsets.only(
        left: screenWidth > 600 ? (screenWidth - 500) / 2 : 0,
        right: screenWidth > 600 ? (screenWidth - 500) / 2 : 0,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.gray300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + bottomInset),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Warning header ────────────────────────────────────────
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.warning,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Asset Already Added',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'This asset may be a duplicate of one you already have.',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Match reason chip ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.warning.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 15,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$matchReason: $matchDetail',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── Existing asset card ───────────────────────────────────
                _ExistingAssetCard(asset: existingAsset),
                const SizedBox(height: 24),

                // ── Actions ───────────────────────────────────────────────
                // "View Existing" button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.of(
                      context,
                    ).pop(_DuplicateAction.viewExisting),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new_rounded, size: 18),
                    label: const Text(
                      'View Existing Asset',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // "Add Anyway" + "Go Back" row
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(_DuplicateAction.goBack),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                            side: BorderSide(color: AppColors.gray300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Go Back',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(
                            context,
                          ).pop(_DuplicateAction.addAnyway),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textPrimary,
                            padding: EdgeInsets.zero,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.4),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Add Anyway',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Existing Asset mini-card ─────────────────────────────────────────────────

class _ExistingAssetCard extends StatelessWidget {
  final AssetDto asset;
  const _ExistingAssetCard({required this.asset});

  @override
  Widget build(BuildContext context) {
    final hasImage =
        asset.productImageUrl != null && asset.productImageUrl!.isNotEmpty;
    final displayName =
        (asset.productTitle?.isNotEmpty == true
                ? asset.productTitle!
                : asset.name)
            .trim();
    final subtitle = [
      if (asset.brand?.isNotEmpty == true) asset.brand,
      if (asset.model?.isNotEmpty == true) asset.model,
    ].join(' · ');
    final location = asset.location;
    final serial = asset.serialNumber;
    final addedDate = _formatDate(asset.createdAt);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundGray50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Image or icon
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(13),
            ),
            child: Container(
              width: 80,
              height: 80,
              color: AppColors.backgroundGray100,
              child: hasImage
                  ? Image.network(
                      asset.productImageUrl!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, e, stack) => _fallbackIcon(),
                    )
                  : _fallbackIcon(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (location?.isNotEmpty == true)
                        _chip(Icons.location_on_outlined, location!),
                      if (serial?.isNotEmpty == true)
                        _chip(
                          Icons.tag_rounded,
                          serial!.length > 12
                              ? '${serial.substring(0, 12)}…'
                              : serial,
                        ),
                      _chip(Icons.calendar_today_outlined, 'Added $addedDate'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _fallbackIcon() => Center(
    child: Icon(
      Icons.devices_other_rounded,
      size: 30,
      color: AppColors.gray300,
    ),
  );

  Widget _chip(IconData icon, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 11, color: AppColors.textSecondary),
      const SizedBox(width: 3),
      Text(
        label,
        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
      ),
    ],
  );

  String _formatDate(DateTime dt) {
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
    return '${months[dt.month - 1]} ${dt.year}';
  }
}
