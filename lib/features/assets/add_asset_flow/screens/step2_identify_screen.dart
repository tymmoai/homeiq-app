import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../services/api_diagnostics_logger.dart';
import '../../../../services/barcode_lookup_service.dart';
import '../../../../services/chatgpt_service.dart';
import '../../../../services/wifi_discovery_service.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/asset_form_model.dart';
import '../helpers/model_number_detector.dart';
import '../models/label_position_mapping.dart';
import '../screens/barcode_scanner_screen.dart';
import '../widgets/dashed_border_widget.dart';
import '../widgets/identify_guidance_section.dart';
import '../widgets/manual_entry_fields.dart';
import '../widgets/scan_upload_area.dart';
import '../widgets/wifi_discovery_widget.dart';

class Step2IdentifyScreen extends StatefulWidget {
  final AssetFormModel formData;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2IdentifyScreen({
    super.key,
    required this.formData,
    required this.onNext,
    required this.onBack,
  });

  @override
  State<Step2IdentifyScreen> createState() => _Step2IdentifyScreenState();
}

class _Step2IdentifyScreenState extends State<Step2IdentifyScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _serialController = TextEditingController();

  // Additional controllers for enriched data (used in Edit Details)
  final _manufacturerController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _productDescriptionController = TextEditingController();
  final _colorController = TextEditingController();
  final _productTitleController = TextEditingController();
  final _productCategoryController = TextEditingController();
  final _productTypeController = TextEditingController();
  final Map<String, TextEditingController> _additionalInfoControllers = {};
  String? _selectedBrand;
  String? _selectedSubCategory;
  bool _detailsExtracted = false;

  // Barcode scan state
  final _barcodeLookupService = BarcodeLookupService();
  bool _isLookingUp = false;
  String? _scannedBarcode;
  BarcodeProduct? _scannedProduct;
  String? _scanError;
  bool _isPartialMatch = false;
  ScannedValueInfo? _partialInfo;
  String? _loadingMessage;

  // Enriched pipeline result
  EnrichedScanResult? _enrichedResult;
  bool _isEnriching = false;
  bool _wifiDataLocked =
      false; // true after WiFi device selected — prevents re-resolve on edits
  bool _isAutoResolvingImage =
      false; // true while debounced image resolution is in progress
  /// Incremented every time a new image-resolve call is intentionally started.
  /// _resolveImageAfterEnrichment stores the value at call-start; after the
  /// await it checks the stored value still matches — if not, a newer call
  /// already started so this stale result is silently discarded.
  int _imageResolveGeneration = 0;
  String?
  _imageSource; // source label for the currently displayed product image

  // Label image state (from scan camera or gallery upload)
  Uint8List? _labelImage;
  bool _isExtractingFromImage = false;
  LabelExtractionResult? _labelExtractionResult;
  int _currentExtractionStep = -1;
  Timer? _extractionProgressTimer;
  final List<String> _extractionStepLabels = const [
    'Analyzing image',
    'Extracting brand info',
    'Extracting model number',
    'Extracting serial number',
    'Looking up product in database',
    'Finalizing details',
  ];

  // ChatGPT Guidance State
  final _chatGPTService = ChatGPTService();
  bool _isLoadingGuidance = false;
  NameplateGuidance? _nameplateGuidance;
  String? _guidanceError;

  // Dynamic Brands from ChatGPT
  List<String> _dynamicBrands = [];
  bool _isLoadingBrands = false;

  // Dynamic Sub Categories from ChatGPT
  List<String> _dynamicSubCategories = [];
  bool _isLoadingSubCategories = false;

  // Label location wireframe image (DALL-E generated)
  Uint8List? _wireframeImage;
  bool _isLoadingImage = false;

  // Active brands (dynamic from ChatGPT)
  List<String> get _activeBrands {
    return _dynamicBrands.isNotEmpty ? _dynamicBrands : ['Other'];
  }

  // Active subcategories (dynamic from ChatGPT)
  List<String> get _activeSubCategories {
    return _dynamicSubCategories.isNotEmpty ? _dynamicSubCategories : [];
  }

  // Validate and get the selected brand
  String? get _validatedSelectedBrand {
    if (_selectedBrand != null && _activeBrands.contains(_selectedBrand)) {
      return _selectedBrand;
    }
    return null;
  }

  // Validate and get the selected subcategory
  String? get _validatedSelectedSubCategory {
    if (_selectedSubCategory != null &&
        _activeSubCategories.contains(_selectedSubCategory)) {
      return _selectedSubCategory;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _brandController.text = widget.formData.brand ?? '';
    _modelController.text = widget.formData.model ?? '';
    _serialController.text = widget.formData.serial ?? '';
    _manufacturerController.text = widget.formData.manufacturer ?? '';
    _barcodeController.text = widget.formData.barcode ?? '';
    _productDescriptionController.text =
        widget.formData.productDescription ?? '';
    _colorController.text = widget.formData.productColor ?? '';
    _productTitleController.text = widget.formData.productTitle ?? '';
    _productCategoryController.text = widget.formData.productCategory ?? '';
    _selectedBrand = widget.formData.brand;
    _selectedSubCategory = widget.formData.subCategory;

    // Fetch brands from ChatGPT for the selected asset type
    _fetchDynamicBrands();
  }

  @override
  void dispose() {
    _extractionProgressTimer?.cancel();
    _brandController.dispose();
    _modelController.dispose();
    _serialController.dispose();
    _manufacturerController.dispose();
    _barcodeController.dispose();
    _productDescriptionController.dispose();
    _colorController.dispose();
    _productTitleController.dispose();
    _productCategoryController.dispose();
    _productTypeController.dispose();
    for (final c in _additionalInfoControllers.values) {
      c.dispose();
    }
    _additionalInfoControllers.clear();
    super.dispose();
  }

  void _handleBrandChanged(String? newValue) {
    setState(() {
      _selectedBrand = newValue;
      widget.formData.brand = newValue;
      _brandController.text = newValue ?? '';
      // Reset subcategory when brand changes
      _selectedSubCategory = null;
      widget.formData.subCategory = null;
      _nameplateGuidance = null;
      _wireframeImage = null;
      _dynamicSubCategories = [];
    });
    // Fetch dynamic subcategories from ChatGPT
    if (newValue != null) {
      _fetchDynamicSubCategories(newValue);
    }
  }

  void _handleSubCategoryChanged(String? newValue) {
    setState(() {
      _selectedSubCategory = newValue;
      widget.formData.subCategory = newValue;
    });
    // Fetch guidance if both brand and subcategory are selected
    if (newValue != null && _selectedBrand != null) {
      _fetchNameplateGuidance();
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetType = widget.formData.selectedAssetType ?? 'Asset';

    return Column(
      children: [
        // Header
        _buildHeader(),
        // Content
        Expanded(
          child: Container(
            color: AppColors.backgroundGray50,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(20),
                vertical: responsive.spacing(0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    'Identify your $assetType',
                    style: TextStyle(
                      fontSize: responsive.fontSize(24),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  Text(
                    'We need details to find the right parts and manuals.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(32)),
                  // Action Buttons — 3 options: Upload Label, Enter Manually, WiFi Scan
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          label: 'Upload Label',
                          icon: Icons.camera_alt_outlined,
                          isSelected:
                              widget.formData.identificationMethod == 'photo',
                          onTap: () {
                            setState(() {
                              widget.formData.identificationMethod = 'photo';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Expanded(
                        child: _buildActionButton(
                          label: 'Manual',
                          icon: Icons.edit_note,
                          isSelected:
                              widget.formData.identificationMethod == 'manual',
                          onTap: () {
                            setState(() {
                              widget.formData.identificationMethod = 'manual';
                            });
                          },
                        ),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Expanded(
                        child: _buildActionButton(
                          label: 'WiFi Scan',
                          icon: Icons.wifi_find_rounded,
                          isSelected:
                              widget.formData.identificationMethod == 'wifi',
                          onTap: () {
                            setState(() {
                              widget.formData.identificationMethod = 'wifi';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  // Upload Label Area
                  if (widget.formData.identificationMethod == 'photo')
                    _buildUploadLabelArea(),
                  // WiFi Discovery Area — kept alive via Offstage so scan
                  // results persist when switching to Manual and back.
                  Offstage(
                    offstage: widget.formData.identificationMethod != 'wifi',
                    child: WifiDiscoveryWidget(
                      formData: widget.formData,
                      resolvedImageSource: _imageSource,
                      onDeviceSelected: (WifiDevice device) {
                        setState(() {
                          // Clear stale data from any previous scan / WiFi device
                          // selection so Edit Details always reflects THIS device only.
                          _clearPreviousProductData();

                          // Fill all form fields from the discovered device
                          String brand = '';
                          if (device.manufacturer.isNotEmpty &&
                              device.manufacturer != 'Unknown') {
                            brand = device.manufacturer;
                          } else if (device.deviceName.isNotEmpty) {
                            // Fallback: extract first word of device name as brand hint
                            brand = device.deviceName.split(' ').first;
                          }

                          // Prefer enriched product name from backend over raw display title
                          final displayName =
                              (device.productName != null &&
                                  device.productName!.isNotEmpty)
                              ? device.productName!
                              : device.displayTitle;

                          // Use device display name as model fallback when the raw
                          // model number is empty (WiFi scanning often can't get it).
                          final effectiveModel =
                              (device.modelNumber != null &&
                                  device.modelNumber!.isNotEmpty)
                              ? device.modelNumber!
                              : displayName;

                          _brandController.text = brand;
                          _modelController.text = effectiveModel;
                          _serialController.text = device.serialNumber ?? '';
                          _manufacturerController.text = brand;
                          // Keep brand dropdown in sync with the text field
                          _selectedBrand = brand.isNotEmpty ? brand : null;

                          widget.formData.brand = brand.isNotEmpty
                              ? brand
                              : null;
                          widget.formData.model = effectiveModel;
                          widget.formData.serial = device.serialNumber ?? '';
                          widget.formData.manufacturer = brand.isNotEmpty
                              ? brand
                              : null;
                          _productTitleController.text = displayName;
                          widget.formData.productTitle = displayName;
                          // Use Step 1 asset type as the authoritative category
                          // (not the WiFi scanner's guess which might say "Windows PC" for a laptop)
                          final step1Type =
                              widget.formData.selectedAssetType ??
                              device.assetType;
                          _productCategoryController.text = step1Type;
                          widget.formData.productCategory = step1Type;
                          widget.formData.enrichmentSource = 'wifi_discovery';

                          // Set product image from backend enrichment as initial placeholder.
                          // We'll still call _resolveImageAfterEnrichment below to get
                          // a type-appropriate image based on the Step 1 asset type.
                          if (device.productImageUrl != null &&
                              device.productImageUrl!.isNotEmpty) {
                            widget.formData.productImageUrl =
                                device.productImageUrl;
                            widget.formData.photoPath = device.productImageUrl;
                            _imageSource = 'discovery_enrich';
                          }

                          // WiFi metadata — for verification badge
                          widget.formData.isWifiDiscovered = true;
                          widget.formData.wifiDeviceIp = device.ipAddress;
                          widget.formData.wifiDeviceName = device.displayTitle;
                          widget.formData.wifiDeviceMac = device.macAddress;
                          widget.formData.wifiHostname = device.hostname;
                          widget.formData.wifiOpenPorts =
                              device.openPorts.isNotEmpty
                              ? device.openPorts
                              : null;
                          widget.formData.wifiFirmware = device.firmwareVersion;
                          widget.formData.wifiOsHint = device.detectedOS;
                          widget.formData.wifiSshBanner = device.sshBanner;
                          widget.formData.wifiTlsCert = device.tlsCertSubject;
                          widget.formData.wifiSmbOs = device.smbOsVersion;
                          widget.formData.wifiConfidence =
                              device.confidenceScore;
                          widget.formData.wifiDiscoveryMethod =
                              device.discoveryMethod;
                          widget.formData.wifiHttpBanner = device.httpBanner;
                          widget.formData.wifiHtmlTitle = device.htmlTitle;

                          // Switch to manual mode so user can review/edit
                          widget.formData.identificationMethod = 'manual';
                          _wifiDataLocked = true;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${device.displayTitle} added! Review and edit below.',
                            ),
                            backgroundColor: const Color(0xFF2E7D32),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        // Check if the discovered device's category matches
                        // the asset type the user selected in Step 1.
                        // If not, show the mismatch dialog so they can correct it.
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (!mounted) return;
                          _mismatchDialogShown = false;
                          _performUnifiedMismatchCheck(
                            texts: [
                              device.deviceCategory,
                              device.assetType,
                              device.displayTitle,
                              device.deviceTypeRaw,
                            ],
                            modelNumber: device.modelNumber ?? '',
                          );
                          // Only fetch image if no mismatch dialog was shown.
                          // When a dialog IS shown, the image fetch is driven by
                          // the Keep / Update Type button (with confirmed type).
                          if (!_mismatchDialogShown) {
                            _resolveImageAfterEnrichment(
                              force: device.productImageUrl != null,
                            );
                          }
                        });
                        // If backend enrichment didn't return a product image,
                        // attempt a silent barcode-lookup enrichment using the model number.
                        if (device.productImageUrl == null &&
                            device.modelNumber != null &&
                            device.modelNumber!.length >= 4) {
                          _enrichWifiDeviceFromModelNumber(
                            modelNumber: device.modelNumber!,
                            assetType: widget.formData.selectedAssetType,
                          );
                        }
                      },
                    ),
                  ),
                  // Manual Entry Fields
                  if (widget.formData.identificationMethod == 'manual')
                    ManualEntryFields(
                      brandController: _brandController,
                      modelController: _modelController,
                      serialController: _serialController,
                      onBrandChanged: (value) {
                        widget.formData.brand = value;
                        setState(() {});
                        // Unlock WiFi lock so the Retry button can overwrite
                        // the WiFi-resolved image when user edits manually.
                        if (_wifiDataLocked) {
                          _wifiDataLocked = false;
                        }
                        // Do NOT auto-trigger image API here — user must click
                        // Retry to intentionally fetch a new image with all fields.
                      },
                      onModelChanged: (value) {
                        widget.formData.model = value;
                        setState(() {});
                        // Check model number prefix for asset type mismatch
                        if (value.length >= 2) {
                          _checkModelNumberPrefix(value);
                        }
                        // Unlock WiFi lock on manual edit (same as brand above).
                        if (_wifiDataLocked) {
                          _wifiDataLocked = false;
                        }
                        // Do NOT auto-trigger — only Retry button fires the API.
                      },
                      onSerialChanged: (value) {
                        widget.formData.serial = value;
                      },
                      manufacturerController: _manufacturerController,
                      barcodeController: _barcodeController,

                      productDescriptionController:
                          _productDescriptionController,
                      colorController: _colorController,
                      onManufacturerChanged: (value) {
                        widget.formData.manufacturer = value;
                      },
                      onBarcodeChanged: (value) {
                        widget.formData.barcode = value;
                      },

                      onProductDescriptionChanged: (value) {
                        widget.formData.productDescription = value;
                      },
                      onColorChanged: (value) {
                        widget.formData.productColor = value;
                      },
                      productTitleController: _productTitleController,
                      productCategoryController: _productCategoryController,
                      onProductTitleChanged: (value) {
                        widget.formData.productTitle = value;
                      },
                      onProductCategoryChanged: (value) {
                        widget.formData.productCategory = value;
                      },
                      productTypeController: _productTypeController,
                      additionalInfoControllers: _additionalInfoControllers,
                      productImageUrl: widget.formData.productImageUrl,
                      isResolvingImage: _isAutoResolvingImage,
                      imageSource: _imageSource,
                      onRetryImage: () {
                        final brand = _brandController.text.trim();
                        final model = _modelController.text.trim();
                        if (brand.isEmpty || model.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                brand.isEmpty && model.isEmpty
                                    ? 'Please enter Brand and Model Number to find a product image'
                                    : brand.isEmpty
                                    ? 'Please enter Brand to find a product image'
                                    : 'Please enter Model Number to find a product image',
                              ),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: AppColors.headerBackground,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }
                        // Force re-fetch even if a reliable image already exists,
                        // and unlock WiFi data-lock so the new image can overwrite.
                        _wifiDataLocked = false;
                        _resolveImageAfterEnrichment(force: true);
                      },
                    ),
                  // Guidance Section
                  IdentifyGuidanceSection(
                    isLoadingBrands: _isLoadingBrands,
                    isLoadingSubCategories: _isLoadingSubCategories,
                    selectedBrand: _selectedBrand,
                    selectedSubCategory: _selectedSubCategory,
                    validatedSelectedBrand: _validatedSelectedBrand,
                    validatedSelectedSubCategory: _validatedSelectedSubCategory,
                    activeBrands: _activeBrands,
                    activeSubCategories: _activeSubCategories,
                    onBrandChanged: _handleBrandChanged,
                    onSubCategoryChanged: _handleSubCategoryChanged,
                    isLoadingGuidance: _isLoadingGuidance,
                    guidanceError: _guidanceError,
                    nameplateGuidance: _nameplateGuidance,
                    wireframeImage: _wireframeImage,
                    isLoadingImage: _isLoadingImage,
                  ),
                ],
              ),
            ),
          ),
        ),
        // Continue Button
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: widget.onBack,
            child: Icon(
              Icons.arrow_back,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
              child: _buildMinimalStepper(2),
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(
              Icons.close,
              color: AppColors.textPrimary,
              size: responsive.iconSize(24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStepper(int currentStep) {
    return Row(
      mainAxisSize: MainAxisSize.max,
      children: List.generate(4, (index) {
        final stepNumber = index + 1;
        final isCompleted = stepNumber < currentStep;
        final isActive = stepNumber == currentStep;

        return Expanded(
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: isCompleted || isActive
                        ? AppColors.primary
                        : AppColors.gray300,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
              if (index < 3) SizedBox(width: responsive.spacing(4)),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: responsive.spacing(44),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: responsive.iconSize(16),
                color: isSelected ? AppColors.white : AppColors.textPrimary,
              ),
              SizedBox(width: responsive.spacing(4)),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadLabelArea() {
    // If we have a label image (from scan or gallery), show image-centered UI
    if (_labelImage != null) {
      return _buildLabelImageSection();
    }

    // Fall back to existing scan results UI (barcode scan without captured image)
    if (_isLookingUp ||
        _enrichedResult != null ||
        (_isPartialMatch && _partialInfo != null) ||
        _scanError != null ||
        (_detailsExtracted && _scannedProduct != null)) {
      return ScanUploadArea(
        isLookingUp: _isLookingUp,
        scannedBarcode: _scannedBarcode,
        scannedProduct: _scannedProduct,
        scanError: _scanError,
        detailsExtracted: _detailsExtracted,
        isPartial: _isPartialMatch,
        partialInfo: _partialInfo,
        enrichedResult: _enrichedResult,
        isEnriching: _isEnriching,
        loadingMessage: _loadingMessage,
        brand: widget.formData.brand,
        model: widget.formData.model,
        serial: widget.formData.serial,
        onScanTap: _showUploadLabelDrawer,
        onScanAgain: _showUploadLabelDrawer,
        onEnterManually: _switchToManualWithExtractedData,
      );
    }

    // If form already has data (from WiFi scan or manual entry),
    // show a preview card instead of the empty upload prompt so the
    // user knows their data is still intact.
    final hasExistingData =
        (widget.formData.brand?.isNotEmpty == true) ||
        (widget.formData.model?.isNotEmpty == true);
    if (hasExistingData) {
      return _buildDataAlreadyCapturedArea();
    }

    // Initial state — Upload Label prompt with dashed border
    return _buildUploadLabelInitial();
  }

  /// Shown on the Upload Label tab when data was already entered via WiFi
  /// scan or manual entry. Gives the user a clear visual that their data
  /// is preserved, with an option to rescan to replace it.
  Widget _buildDataAlreadyCapturedArea() {
    const green = Color(0xFF10b981);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(20)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: green.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(8)),
                decoration: BoxDecoration(
                  color: green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  color: green,
                  size: responsive.iconSize(20),
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: Text(
                  'Details already captured',
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(16)),
          if (widget.formData.brand?.isNotEmpty == true)
            _buildDataRow('Brand', widget.formData.brand!),
          if (widget.formData.model?.isNotEmpty == true)
            _buildDataRow('Model', widget.formData.model!),
          if (widget.formData.serial?.isNotEmpty == true)
            _buildDataRow('Serial', widget.formData.serial!),
          SizedBox(height: responsive.spacing(16)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showUploadLabelDrawer,
              icon: Icon(
                Icons.camera_alt_outlined,
                size: responsive.iconSize(18),
              ),
              label: const Text('Rescan to update'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: BorderSide(color: AppColors.primary),
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(8)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: responsive.spacing(60),
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          SizedBox(width: responsive.spacing(8)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadLabelInitial() {
    return GestureDetector(
      onTap: _showUploadLabelDrawer,
      child: DashedBorder(
        color: AppColors.primary,
        strokeWidth: 2.0,
        dashWidth: 8.0,
        dashSpace: 5.0,
        borderRadius: 16.0,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(40)),
          decoration: BoxDecoration(
            color: AppColors.primary05,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(responsive.spacing(16)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  size: responsive.iconSize(40),
                  color: AppColors.primary,
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              Text(
                'Upload Product Label',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(8)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(24),
                ),
                child: Text(
                  'Scan or photograph the label on your product to auto-fill details.',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'UPC · EAN · QR Code · Barcode · Label Photo',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
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

  void _showUploadLabelDrawer() {
    // Reset mismatch guard so new scan can show a dialog
    _mismatchDialogShown = false;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
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
                SizedBox(height: responsive.spacing(20)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20),
                  ),
                  child: Text(
                    'Upload Product Label',
                    style: TextStyle(
                      fontSize: responsive.fontSize(18),
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(4)),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20),
                  ),
                  child: Text(
                    'Choose how to capture your product label',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(24)),
                // Scan Barcode option
                _buildDrawerOption(
                  icon: Icons.qr_code_scanner,
                  label: 'Scan Barcode',
                  subtitle: 'Use camera to scan barcode or QR code',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _openBarcodeScanner();
                  },
                ),
                // Upload from Gallery option
                _buildDrawerOption(
                  icon: Icons.photo_library_outlined,
                  label: 'Upload from Gallery',
                  subtitle: 'Select a photo of your product label',
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _pickImageFromGallery();
                  },
                ),
                SizedBox(height: responsive.spacing(24)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.spacing(20),
          vertical: responsive.spacing(12),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(responsive.spacing(12)),
              decoration: BoxDecoration(
                color: AppColors.primary05,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: responsive.iconSize(24),
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: responsive.spacing(16)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textLight,
              size: responsive.iconSize(24),
            ),
          ],
        ),
      ),
    );
  }

  /// Opens the barcode scanner camera and runs the 2-step enriched pipeline.
  ///
  /// Flow: Scan → Tier0 (local regex) → Step1 (ChatGPT extracts identifiers)
  ///       → Step2 (Barcode API with extracted UPC/model) → Merged result
  Future<void> _openBarcodeScanner() async {
    // Reset all previous scan state
    setState(() {
      _scanError = null;
      _scannedProduct = null;
      _scannedBarcode = null;
      _detailsExtracted = false;
      _isPartialMatch = false;
      _partialInfo = null;
      _enrichedResult = null;
      _isEnriching = false;
      _loadingMessage = null;
      _labelImage = null;
      _labelExtractionResult = null;
      _isExtractingFromImage = false;
      _currentExtractionStep = -1;
    });
    _extractionProgressTimer?.cancel();

    // Clear all product data from any previous identification method so
    // "Edit Details" always shows data from THIS scan, not stale WiFi/manual data.
    _clearPreviousProductData();

    // Open scanner and wait for scan result (barcode + optional image)
    final scanResult = await Navigator.of(context).push<BarcodeScanResult>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );

    if (scanResult == null || !mounted) return;

    final scannedValue = scanResult.barcode;

    // Store captured camera image if available
    if (scanResult.capturedImage != null) {
      setState(() {
        _labelImage = scanResult.capturedImage;
      });
    }

    // We got a barcode — start the pipeline
    setState(() {
      _scannedBarcode = scannedValue;
      _isLookingUp = true;
      _loadingMessage = 'Looking up product...';
    });

    // Run full enriched pipeline (Fast path: Barcode API first, Slow path: ChatGPT → Barcode API)
    final assetType = widget.formData.selectedAssetType;

    // Update message if still loading after fast path timeout
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted && _isLookingUp) {
        setState(() {
          _loadingMessage = 'Identifying product with AI...';
        });
      }
    });

    final enriched = await _barcodeLookupService.lookupWithEnrichment(
      barcode: scannedValue,
      assetType: assetType,
    );

    if (!mounted) return;

    if (enriched.isSuccess) {
      setState(() {
        _isLookingUp = false;
        _enrichedResult = enriched;
        _detailsExtracted = true;

        // Auto-fill form with best available data
        if (enriched.brand.isNotEmpty) {
          widget.formData.brand = enriched.brand;
          _brandController.text = enriched.brand;
          _selectedBrand = enriched.brand;
        }
        if (enriched.model.isNotEmpty) {
          widget.formData.model = enriched.model;
          _modelController.text = enriched.model;
        }
        if (enriched.serialNumber.isNotEmpty) {
          widget.formData.serial = enriched.serialNumber;
          _serialController.text = enriched.serialNumber;
        } else if (enriched.barcode.isNotEmpty) {
          widget.formData.serial = enriched.barcode;
          _serialController.text = enriched.barcode;
        }

        // Store product details ONLY from Barcode API in form model
        // ChatGPT data is NOT used for product details — only for identifiers above
        if (enriched.barcodeProduct != null) {
          widget.formData.productTitle = enriched.productName;
          widget.formData.productDescription = enriched.description;
          widget.formData.productCategory = enriched.category;
          widget.formData.manufacturer = enriched.manufacturer;
          // Filter out images for non-product items (warranty plans, care+, etc.)
          // These return brand logos instead of actual product images
          final enrichedImage = enriched.productImage;
          final isNonProductResult = RegExp(
            r'\b(protection plan|warranty|care\+?|applecare|geek squad|plan|service|coverage)\b',
            caseSensitive: false,
          ).hasMatch('${enriched.productName} ${enriched.model}');
          if (enrichedImage != null &&
              enrichedImage.isNotEmpty &&
              !isNonProductResult) {
            widget.formData.productImageUrl = enrichedImage;
            widget.formData.photoPath = enrichedImage;
          } else {
            widget.formData.productImageUrl = null;
            widget.formData.photoPath = null;
          }
          widget.formData.productColor = enriched.color.isNotEmpty
              ? enriched.color
              : null;
          // Keep controllers in sync so manual-entry fields display correctly
          // if the user navigates back to photo→manual mode.
          _productTitleController.text = enriched.productName;
          _productCategoryController.text = enriched.category;
          _productDescriptionController.text = enriched.description;
          _manufacturerController.text = enriched.manufacturer;
          _colorController.text = enriched.color.isNotEmpty
              ? enriched.color
              : '';
        } else {
          // No Barcode API data — clear all product detail fields
          widget.formData.productTitle = null;
          widget.formData.productDescription = null;
          widget.formData.productCategory = null;
          widget.formData.manufacturer = null;
          widget.formData.productImageUrl = null;
          widget.formData.photoPath = null;
          widget.formData.productColor = null;
          _productTitleController.text = '';
          _productCategoryController.text = '';
          _productDescriptionController.text = '';
          _manufacturerController.text = '';
          _colorController.text = '';
        }
        widget.formData.barcode = enriched.barcode;
        widget.formData.productSpecs = null;
        widget.formData.warrantyDetails = null;
        widget.formData.supportUrl = null;
        widget.formData.manualUrl = null;
        widget.formData.enrichmentSource = enriched.source;

        // subCategory comes from Barcode API only
        if (enriched.barcodeProduct != null &&
            enriched.subCategory.isNotEmpty) {
          widget.formData.subCategory = enriched.subCategory;
          _selectedSubCategory = enriched.subCategory;
        }
      });

      // Check for category mismatch on barcode scan results
      _checkCategoryMismatchForEnriched(enriched);
      // Defer image fetch until the user resolves the mismatch dialog.
      // If no dialog was shown, kick it off immediately.
      if (!_mismatchDialogShown) {
        _resolveImageAfterEnrichment();
      }
    } else if (enriched.isPartialOnly) {
      // Got brand hints but no full identification
      setState(() {
        _isLookingUp = false;
        _isPartialMatch = true;
        _partialInfo = ScannedValueInfo(
          rawValue: scannedValue,
          type: ScannedValueType.unknownCode,
          brand: enriched.detectedBrand,
          userMessage:
              enriched.errorMessage ?? 'Could not fully identify this product.',
        );

        if (enriched.detectedBrand != null) {
          widget.formData.brand = enriched.detectedBrand;
          _brandController.text = enriched.detectedBrand!;
          _selectedBrand = enriched.detectedBrand;
        }
        widget.formData.barcode = scannedValue;
      });
    } else {
      setState(() {
        _isLookingUp = false;
        _scanError = enriched.errorMessage ?? 'Product not found. Try again.';
      });
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  GALLERY UPLOAD + IMAGE EXTRACTION
  // ═══════════════════════════════════════════════════════════════

  /// Wipes all product-identification data from [formData] and the matching
  /// controllers so that a new scan / upload starts from a clean state.
  ///
  /// Called before every barcode scan and gallery upload so that stale data
  /// from a previous identification method (e.g. WiFi MacBook Air) is never
  /// carried forward into the new scan's Edit Details view.
  void _clearPreviousProductData() {
    widget.formData.brand = null;
    widget.formData.model = null;
    widget.formData.serial = null;
    widget.formData.manufacturer = null;
    widget.formData.barcode = null;
    widget.formData.productTitle = null;
    widget.formData.productDescription = null;
    widget.formData.productCategory = null;
    widget.formData.productImageUrl = null;
    widget.formData.photoPath = null;
    widget.formData.productImageSource = null;
    widget.formData.productColor = null;
    widget.formData.productSpecs = null;
    widget.formData.warrantyDetails = null;
    widget.formData.supportUrl = null;
    widget.formData.manualUrl = null;
    widget.formData.enrichmentSource = null;
    widget.formData.subCategory = null;
    widget.formData.manufacturedYear = null;
    widget.formData.madeIn = null;
    // Clear WiFi metadata — the new scan is the authoritative source
    widget.formData.isWifiDiscovered = false;
    widget.formData.wifiDeviceIp = null;
    widget.formData.wifiDeviceName = null;
    widget.formData.wifiDeviceMac = null;
    widget.formData.wifiHostname = null;
    widget.formData.wifiOpenPorts = null;
    widget.formData.wifiFirmware = null;
    widget.formData.wifiOsHint = null;
    widget.formData.wifiSshBanner = null;
    widget.formData.wifiTlsCert = null;
    widget.formData.wifiSmbOs = null;
    widget.formData.wifiConfidence = null;
    widget.formData.wifiDiscoveryMethod = null;
    widget.formData.wifiHttpBanner = null;
    widget.formData.wifiHtmlTitle = null;
    _wifiDataLocked = false;
    _imageSource = null;
    // Sync all controllers
    _brandController.text = '';
    _modelController.text = '';
    _serialController.text = '';
    _manufacturerController.text = '';
    _barcodeController.text = '';
    _productTitleController.text = '';
    _productCategoryController.text = '';
    _productDescriptionController.text = '';
    _colorController.text = '';
    _selectedBrand = null;
    _selectedSubCategory = null;
  }

  /// Pick an image from the device gallery and extract product details.
  Future<void> _pickImageFromGallery() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      // Keep max 1280 px — large enough for GPT-4o to read label text
      // but small enough that the base64 payload is always well under 1 MB.
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 72,
    );

    if (image == null || !mounted) return;

    final bytes = await image.readAsBytes();
    if (!mounted) return;

    // Reset all previous states
    setState(() {
      _scanError = null;
      _scannedProduct = null;
      _scannedBarcode = null;
      _detailsExtracted = false;
      _isPartialMatch = false;
      _partialInfo = null;
      _enrichedResult = null;
      _isEnriching = false;
      _loadingMessage = null;
      _labelExtractionResult = null;
      _labelImage = bytes;
    });

    // Clear all product data from any previous identification method so
    // "Edit Details" always shows data from THIS scan, not stale WiFi/manual data.
    _clearPreviousProductData();

    // Start extraction from the image
    _extractDetailsFromImage(bytes);
  }

  /// Extract product details from a label image using GPT-4o Vision,
  /// then enrich with Barcode Lookup API using the extracted barcode/model.
  Future<void> _extractDetailsFromImage(Uint8List imageBytes) async {
    setState(() {
      _isExtractingFromImage = true;
      _currentExtractionStep = 0;
      _labelExtractionResult = null;
    });

    // Start progress animation (simulate step-by-step progress)
    _extractionProgressTimer?.cancel();
    _extractionProgressTimer = Timer.periodic(
      const Duration(milliseconds: 1800),
      (timer) {
        if (!mounted || !_isExtractingFromImage) {
          timer.cancel();
          return;
        }
        // Don't auto-advance past step 3 (serial extraction) —
        // step 4 (barcode lookup) and step 5 (finalize) are driven by actual results
        if (_currentExtractionStep < 3) {
          setState(() {
            _currentExtractionStep++;
          });
        } else {
          timer.cancel();
        }
      },
    );

    // ── STEP 1: Call GPT-4o Vision API to extract label details ──
    final result = await _chatGPTService.extractDetailsFromLabelImage(
      imageBytes,
      assetType: widget.formData.selectedAssetType,
    );

    _extractionProgressTimer?.cancel();

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() {
        _isExtractingFromImage = false;
        _labelExtractionResult = result;
      });
      return;
    }

    // Move progress to "Looking up product in database" step
    setState(() {
      _currentExtractionStep = 4; // "Looking up product in database"
    });

    // Auto-fill form with ChatGPT-extracted data immediately
    setState(() {
      if (result.brand.isNotEmpty) {
        widget.formData.brand = result.brand;
        _brandController.text = result.brand;
        _selectedBrand = result.brand;
      }
      if (result.model.isNotEmpty) {
        widget.formData.model = result.model;
        _modelController.text = result.model;
      }
      if (result.serial.isNotEmpty) {
        widget.formData.serial = result.serial;
        _serialController.text = result.serial;
      }
      if (result.barcode.isNotEmpty) {
        widget.formData.barcode = result.barcode;
      }
      // Store the 8 enterprise fields straight from GPT
      if (result.manufacturer?.isNotEmpty == true) {
        widget.formData.manufacturer = result.manufacturer;
        _manufacturerController.text = result.manufacturer!;
      }
      // Pre-fill purchase year from manufacture date on the label (GPT extracted).
      // Only set if formData doesn't already have a user-entered year.
      final mfgYear = result.manufacturedYear ?? '';
      if (mfgYear.isNotEmpty && widget.formData.purchaseYear == null) {
        widget.formData.purchaseYear = mfgYear;
      }
      widget.formData.manufacturedYear = mfgYear.isNotEmpty ? mfgYear : null;
      widget.formData.madeIn = result.madeIn?.isNotEmpty == true
          ? result.madeIn
          : null;

      // ── Asset type mismatch detection from productType ────────────────────
      // If GPT detected a different product type than what the user selected in
      // Step 1, store it so the mismatch dialog can ask the user to confirm.
      // We do NOT auto-correct silently — the user must always confirm via popup
      // before the asset type changes.
      if (result.productType.isNotEmpty) {
        final combinedText = ' ${result.productType} '.toLowerCase();
        for (final entry in _categoryKeywordsOrdered) {
          final matches = entry.value.any((kw) => combinedText.contains(kw));
          if (matches && entry.key != widget.formData.selectedAssetType) {
            debugPrint(
              '[AssetType] Mismatch detected: user selected '
              '"${widget.formData.selectedAssetType}", GPT detected "${entry.key}" '
              '(GPT productType: "${result.productType}"). Awaiting user confirmation.',
            );
            break;
          }
        }
      }
    });

    // ── STEP 2: Lookup via Barcode API using extracted barcode or model ──
    // (Barcode API returns product image URL via SerpAPI)
    LabelExtractionResult enrichedResult = result;

    final lookupBarcode = result.barcode.isNotEmpty ? result.barcode : null;
    final lookupModel = result.model.isNotEmpty ? result.model : null;
    final lookupBrand = result.brand.isNotEmpty ? result.brand : null;

    BarcodeLookupResult? barcodeResult;

    // Try barcode first (most reliable), then model number (MPN), then search
    if (lookupBarcode != null) {
      barcodeResult = await _barcodeLookupService.lookupBarcode(lookupBarcode);
    }

    if ((barcodeResult == null || !barcodeResult.isSuccess) &&
        lookupModel != null) {
      barcodeResult = await _barcodeLookupService.lookupByMpn(
        lookupModel,
        manufacturer: lookupBrand,
      );
    }

    if ((barcodeResult == null || !barcodeResult.isSuccess) &&
        lookupBrand != null &&
        lookupModel != null) {
      barcodeResult = await _barcodeLookupService.lookupBySearch(
        '$lookupBrand $lookupModel',
      );
    }

    if (!mounted) return;

    // ── STEP 3: Merge results ──
    if (barcodeResult != null &&
        barcodeResult.isSuccess &&
        barcodeResult.product != null) {
      final product = barcodeResult.product!;
      enrichedResult = result.copyWithBarcodeEnrichment(
        productTitle: product.title,
        productDescription: product.description,
        productCategory: product.category,
        manufacturer: product.manufacturer,
        productImageUrl: product.primaryImage,
        productColor: product.color,
        enrichedBrand: product.effectiveBrand,
        enrichedModel: product.effectiveModel,
        enrichedBarcode: product.barcode,
        barcodeApiSuccess: true,
      );

      // Update form with enriched data from Barcode API.
      // Model, serial, and barcode from GPT are ground-truth (physical label)
      // — only fill from barcode API if GPT found nothing.
      if (product.effectiveBrand.isNotEmpty && result.brand.isEmpty) {
        widget.formData.brand = product.effectiveBrand;
        _brandController.text = product.effectiveBrand;
        _selectedBrand = product.effectiveBrand;
      }
      // Never overwrite model — GPT read it directly off the label.

      // Validate barcode API productTitle against user-selected asset type.
      // e.g. if barcode says "Samsung 77\" OLED TV" but user chose "Microwave",
      // we discard the title so it doesn't pollute the image search query.
      final resolvedTitle =
          _isTitleCompatible(product.title, widget.formData.selectedAssetType)
          ? product.title
          : null;
      if (resolvedTitle != null) {
        widget.formData.productTitle = resolvedTitle;
      }
      widget.formData.productDescription = product.description;
      // Validate barcode API category against user-selected asset type.
      // If barcode says "Televisions" but user chose "Microwave", we keep
      // "Microwave" — the user's explicit intent always wins.
      final resolvedCategory = _resolveCompatibleCategory(
        product.category,
        widget.formData.selectedAssetType,
      );
      widget.formData.productCategory = resolvedCategory;
      // Only fill manufacturer from barcode API if GPT didn't extract it from the label
      if (result.manufacturer?.isEmpty != false) {
        widget.formData.manufacturer = product.manufacturer;
        _manufacturerController.text = product.manufacturer;
      }
      // Filter out images for non-product items (warranty plans, logos)
      final isNonProductItem = RegExp(
        r'\b(protection plan|warranty|care\+?|applecare|geek squad|plan|service|coverage)\b',
        caseSensitive: false,
      ).hasMatch('${product.title} ${product.effectiveModel}');
      final pImage = product.primaryImage;
      if (pImage != null && pImage.isNotEmpty && !isNonProductItem) {
        widget.formData.productImageUrl = pImage;
        widget.formData.photoPath = pImage;
      } else {
        widget.formData.productImageUrl = null;
        widget.formData.photoPath = null;
      }
      widget.formData.productColor = product.color.isNotEmpty
          ? product.color
          : null;
      widget.formData.barcode = product.barcode.isNotEmpty
          ? product.barcode
          : result.barcode;
      widget.formData.enrichmentSource = 'merged';
      // Sync controllers so manual-entry fields reflect the enriched data
      _productTitleController.text = resolvedTitle ?? '';
      _productCategoryController.text = resolvedCategory;
      _productDescriptionController.text = product.description;
      _manufacturerController.text = product.manufacturer;
      _colorController.text = product.color.isNotEmpty ? product.color : '';
      _barcodeController.text = widget.formData.barcode ?? '';
    } else {
      // Barcode API didn't find anything — just mark it as attempted
      enrichedResult = result.copyWithBarcodeEnrichment(
        barcodeApiSuccess: false,
      );
      widget.formData.enrichmentSource = 'chatgpt';
    }

    // Finalize
    setState(() {
      _currentExtractionStep = _extractionStepLabels.length; // all complete
      _isExtractingFromImage = false;
      _labelExtractionResult = enrichedResult;
    });

    // Sync controllers for Edit Details section
    _manufacturerController.text = widget.formData.manufacturer ?? '';
    _barcodeController.text = widget.formData.barcode ?? '';
    _productDescriptionController.text =
        widget.formData.productDescription ?? '';
    _colorController.text = widget.formData.productColor ?? '';

    // Log extraction results to console (full detail for debugging)
    _logExtractionResults(enrichedResult);

    // Check for category mismatch (shows dialog if type doesn't match selected).
    // _resolveImageAfterEnrichment is ONLY called from inside the dialog buttons
    // so it always runs with the final confirmed asset type.
    _checkCategoryMismatch(enrichedResult);

    // If no mismatch was detected (dialog not shown), kick off image search now.
    if (!_mismatchDialogShown) {
      _resolveImageAfterEnrichment();
    }
  }

  /// Log per-field data source to console for diagnostics.
  void _logExtractionResults(LabelExtractionResult result) {
    final diagLogger = ApiDiagnosticsLogger();
    final sources = result.fieldSources;
    diagLogger.logLabelExtractionResults(
      brand: result.brand,
      model: result.model,
      serial: result.serial,
      barcode: result.barcode,
      productType: result.productType,
      productTitle: result.productTitle,
      manufacturer: result.manufacturer,
      color: result.productColor,
      enrichmentSource: result.enrichmentSource,
      barcodeApiSuccess: result.barcodeApiSuccess,
      fieldSources: {
        'Brand': sources['Brand'],
        'Model': sources['Model'],
        'Serial': sources['Serial'],
        'Barcode': sources['Barcode'],
        'Type': sources['Type'],
        'Manufacturer': sources['Manufacturer'],
        'Manufactured': sources['Manufactured'],
        'Made In': sources['Made In'],
        'Product Title': result.productTitle != null ? 'Barcode API' : null,
        'Color': result.productColor != null ? 'Barcode API' : null,
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  CATEGORY MISMATCH DETECTION (unified)
  // ═══════════════════════════════════════════════════════════════

  /// Guard: only one mismatch dialog per scan cycle.
  bool _mismatchDialogShown = false;

  /// Known asset type keywords for matching detected product types.
  /// Order matters — more specific types are checked first to avoid
  /// false positives (e.g. "Microwave" before "Range / Stove" so
  /// "Over the Range Microwave" doesn't match Range).
  static const List<MapEntry<String, List<String>>> _categoryKeywordsOrdered = [
    // Most specific first
    MapEntry('Microwave', ['microwave']),
    MapEntry('Dishwasher', ['dishwasher', 'dish washer']),
    MapEntry('Garbage Disposal', [
      'garbage disposal',
      'disposer',
      'food waste',
    ]),
    MapEntry('Water Heater', ['water heater', 'tankless', 'boiler']),
    MapEntry('Sump Pump', ['sump pump']),
    MapEntry('Refrigerator', [
      'refrigerator',
      'fridge',
      'freezer',
      'ice maker',
    ]),
    MapEntry('Washer', ['washer', 'washing machine', 'laundry']),
    MapEntry('Dryer', ['dryer', 'tumble dry']),
    MapEntry('Range / Stove', ['range', 'stove', 'oven', 'cooktop', 'cooker']),
    MapEntry('Heating & Cooling', [
      'hvac',
      'air conditioner',
      'furnace',
      'heat pump',
      'heater',
      'mini split',
      'split system',
    ]),
    // Computer BEFORE Television: laptop product descriptions often contain
    // 'display', 'screen', or 'monitor' which would falsely match Television
    // if Television were checked first.
    MapEntry('Computer', [
      'computer',
      'laptop',
      'desktop',
      'notebook',
      'macbook',
      'chromebook',
    ]),
    MapEntry('Television', [
      'television',
      ' tv ',
      'smart tv',
      'flat screen',
      'oled tv',
      'qled',
    ]),
    MapEntry('Gaming Console', [
      'gaming console',
      'playstation',
      'xbox',
      'nintendo',
    ]),
    MapEntry('Smart Speaker', [
      'smart speaker',
      'echo',
      'alexa',
      'google home',
    ]),
  ];

  /// Check if the extracted product type matches the user-selected category.
  void _checkCategoryMismatch(LabelExtractionResult result) {
    final detectedTypes = <String>[];
    if (result.productType.isNotEmpty) detectedTypes.add(result.productType);
    if (result.productCategory != null && result.productCategory!.isNotEmpty) {
      detectedTypes.add(result.productCategory!);
    }
    if (result.productTitle != null && result.productTitle!.isNotEmpty) {
      detectedTypes.add(result.productTitle!);
    }
    if (result.productDescription != null &&
        result.productDescription!.isNotEmpty) {
      detectedTypes.add(result.productDescription!);
    }
    _performUnifiedMismatchCheck(
      texts: detectedTypes,
      modelNumber: result.model,
    );
  }

  /// Returns a category string that is safe to display for the user-selected
  /// asset type.  If [barcodeCategory] contains keywords that map to a
  /// *different* asset type (e.g. barcode says "Televisions" but user selected
  /// "Microwave"), we discard the barcode category and fall back to
  /// [selectedAssetType] so the UI never shows a conflicting category.
  ///
  /// If the category is neutral (no known keywords) or matches the selected
  /// type, it is returned unchanged.
  String _resolveCompatibleCategory(
    String barcodeCategory,
    String? selectedAssetType,
  ) {
    if (selectedAssetType == null || barcodeCategory.isEmpty) {
      return barcodeCategory;
    }

    final categoryLower = ' $barcodeCategory '.toLowerCase();

    for (final entry in _categoryKeywordsOrdered) {
      if (entry.key == selectedAssetType) continue; // same type — OK
      final conflictsWithOtherType = entry.value.any(
        (kw) => categoryLower.contains(kw),
      );
      if (conflictsWithOtherType) {
        debugPrint(
          '[CategoryValidation] Barcode category "$barcodeCategory" conflicts '
          'with selectedAssetType "$selectedAssetType" '
          '(matches "${entry.key}"). Ignoring barcode category.',
        );
        return selectedAssetType;
      }
    }

    return barcodeCategory;
  }

  /// Returns true if [title] is consistent with [selectedAssetType], i.e. the
  /// title does NOT contain keywords that identify a *different* product type.
  ///
  /// A null or empty title is considered compatible (no evidence of conflict).
  /// Example: title="Samsung 77\" OLED TV", assetType="Microwave" → false
  bool _isTitleCompatible(String? title, String? selectedAssetType) {
    if (selectedAssetType == null || title == null || title.isEmpty) {
      return true;
    }

    final titleLower = ' $title '.toLowerCase();

    for (final entry in _categoryKeywordsOrdered) {
      if (entry.key == selectedAssetType) {
        continue; // matches selected type — fine
      }
      final conflictsWithOtherType = entry.value.any(
        (kw) => titleLower.contains(kw),
      );
      if (conflictsWithOtherType) {
        debugPrint(
          '[TitleValidation] productTitle "$title" conflicts with '
          'selectedAssetType "$selectedAssetType" '
          '(matches "${entry.key}"). Title will be suppressed.',
        );
        return false;
      }
    }

    return true;
  }

  /// Verify that extraction result has critical fields (brand, model, serial, or barcode).
  /// This ensures we don't show success for images that weren't actually product labels.
  bool _hasCriticalFields(LabelExtractionResult result) {
    return result.brand.isNotEmpty ||
        result.model.isNotEmpty ||
        result.serial.isNotEmpty ||
        result.barcode.isNotEmpty;
  }

  /// Check category mismatch for barcode/enriched scan results.
  void _checkCategoryMismatchForEnriched(EnrichedScanResult result) {
    final detectedTypes = <String>[];
    if (result.productName.isNotEmpty) detectedTypes.add(result.productName);
    if (result.category.isNotEmpty) detectedTypes.add(result.category);
    if (result.description.isNotEmpty) detectedTypes.add(result.description);
    if (result.brand.isNotEmpty) detectedTypes.add(result.brand);
    if (result.model.isNotEmpty) detectedTypes.add(result.model);
    if (result.chatGPTProduct?.category != null) {
      detectedTypes.add(result.chatGPTProduct!.category!);
    }
    if (result.chatGPTProduct?.subCategory != null) {
      detectedTypes.add(result.chatGPTProduct!.subCategory!);
    }
    _performUnifiedMismatchCheck(
      texts: detectedTypes,
      modelNumber: result.model,
    );
  }

  /// Single entry point for all mismatch detection.
  ///
  /// Priority order:
  /// 1. Model number prefix (highest confidence)
  /// 2. Text-based keyword matching (fallback)
  ///
  /// Only one dialog is shown per scan cycle.
  void _performUnifiedMismatchCheck({
    required List<String> texts,
    required String modelNumber,
  }) {
    if (!mounted || _mismatchDialogShown) return;

    final selectedType = widget.formData.selectedAssetType;
    if (selectedType == null) return;

    // ── 1. Model number prefix detection (highest confidence) ──
    String? detectedType;
    String? detectionSource;
    String? detectionReason;

    if (modelNumber.isNotEmpty) {
      final prefixType = ModelNumberDetector.detectAssetType(modelNumber);
      if (prefixType != null && prefixType != selectedType) {
        detectedType = prefixType;
        detectionSource = 'model';
        detectionReason = ModelNumberDetector.getDetectionReason(modelNumber);
      }
    }

    // ── 2. Text-based keyword matching (fallback) ──
    if (detectedType == null && texts.isNotEmpty) {
      final combinedText = ' ${texts.join(' ')} '.toLowerCase();

      // First check if text matches the selected type (no mismatch)
      bool matchesSelected = false;
      for (final entry in _categoryKeywordsOrdered) {
        if (entry.key != selectedType) continue;
        matchesSelected = entry.value.any((kw) => combinedText.contains(kw));
        break;
      }

      if (!matchesSelected) {
        // Find what it actually matches (first match wins due to priority order)
        for (final entry in _categoryKeywordsOrdered) {
          if (entry.key == selectedType) continue;
          final matches = entry.value.any((kw) => combinedText.contains(kw));
          if (matches) {
            detectedType = entry.key;
            detectionSource = 'text';
            break;
          }
        }
      }
    }

    if (detectedType == null) return; // No mismatch found

    // ── Show single unified dialog ──
    _mismatchDialogShown = true;
    // Clear any image that was set by the barcode API before the mismatch was
    // detected — it may belong to the wrong product type.  The correct image
    // is fetched after the user confirms or updates the asset type.
    setState(() {
      widget.formData.productImageUrl = null;
      widget.formData.productImageSource = null;
      widget.formData.photoPath = null;
    });
    _showMismatchDialog(
      selectedType: selectedType,
      detectedType: detectedType,
      source: detectionSource!,
      reason: detectionReason,
    );
  }

  /// Check model number prefix for manual entry (triggered on keystrokes).
  void _checkModelNumberPrefix(String modelNumber) {
    if (!mounted || _mismatchDialogShown) return;

    final selectedType = widget.formData.selectedAssetType;
    if (selectedType == null) return;

    final detectedType = ModelNumberDetector.detectAssetType(modelNumber);
    if (detectedType == null || detectedType == selectedType) return;

    _mismatchDialogShown = true;
    final reason = ModelNumberDetector.getDetectionReason(modelNumber);
    _showMismatchDialog(
      selectedType: selectedType,
      detectedType: detectedType,
      source: 'model',
      reason: reason,
    );
  }

  /// Silently enriches a WiFi-discovered device using its model number.
  /// Calls the barcode/product lookup pipeline and updates formData with
  /// a product image and richer title if found, without blocking the UI.
  Future<void> _enrichWifiDeviceFromModelNumber({
    required String modelNumber,
    String? assetType,
  }) async {
    if (!mounted) return;
    try {
      final enriched = await _barcodeLookupService.lookupWithEnrichment(
        barcode: modelNumber,
        assetType: assetType,
      );
      if (!mounted) return;
      if (enriched.isSuccess && enriched.barcodeProduct != null) {
        setState(() {
          // Only set image if not already set from WiFi backend enrichment
          // and if it's a real product (not a warranty plan/logo)
          final isNonProductWifi = RegExp(
            r'\b(protection plan|warranty|care\+?|applecare|geek squad|plan|service|coverage)\b',
            caseSensitive: false,
          ).hasMatch('${enriched.productName} ${enriched.model}');
          if ((widget.formData.productImageUrl == null ||
                  widget.formData.productImageUrl!.isEmpty) &&
              (enriched.productImage?.isNotEmpty ?? false) &&
              !isNonProductWifi) {
            widget.formData.productImageUrl = enriched.productImage;
            widget.formData.photoPath = enriched.productImage;
          }
          // Upgrade generic WiFi title to specific product name if available
          final currentTitle = widget.formData.productTitle ?? '';
          final isGenericTitle =
              currentTitle.isEmpty ||
              currentTitle.toLowerCase().contains('device') ||
              currentTitle.toLowerCase().contains('unknown');
          if (isGenericTitle && enriched.productName.isNotEmpty) {
            widget.formData.productTitle = enriched.productName;
            _productTitleController.text = enriched.productName;
          }
          if (enriched.manufacturer.isNotEmpty &&
              (widget.formData.manufacturer == null ||
                  widget.formData.manufacturer!.isEmpty)) {
            widget.formData.manufacturer = enriched.manufacturer;
            _manufacturerController.text = enriched.manufacturer;
          }
          final prev = widget.formData.enrichmentSource;
          widget.formData.enrichmentSource = prev != null && prev.isNotEmpty
              ? '$prev+barcode_api'
              : 'wifi_model_lookup';
        });
      }
    } on Object catch (_) {
      // Silent failure — WiFi form data is still valid without extra enrichment
    }
  }

  /// Final image resolution: called when user taps Continue.
  /// Uses confirmed brand + model to fetch the most accurate product image
  /// from BestBuy → UPC ItemDB → SerpAPI → Pexels → Unsplash chain.
  /// If a better image is found, updates formData. Then proceeds to Step 3.
  bool _isResolvingImage = false;

  Future<void> _resolveImageAndContinue() async {
    final existingImage = widget.formData.productImageUrl;
    final brand = widget.formData.brand;
    final model = widget.formData.model;
    final category = widget.formData.selectedAssetType;

    // Can't search without brand, model, OR category — skip
    if ((brand == null || brand.isEmpty) &&
        (model == null || model.isEmpty) &&
        (category == null || category.isEmpty)) {
      widget.onNext();
      return;
    }

    // Check if the model looks like a non-product (warranty plan, SKU, etc.)
    final modelLower = (model ?? '').toLowerCase();
    final brandLower = (brand ?? '').toLowerCase();
    final titleLower = (widget.formData.productTitle ?? '').toLowerCase();
    final isNonProduct =
        modelLower.contains('\$') ||
        RegExp(
          r'\b(yr|year|plan|warranty|care\+?|protect|coverage|service)\b',
        ).hasMatch(modelLower) ||
        RegExp(
          r'\b(protection plan|warranty|care\+?|applecare|geek squad)\b',
        ).hasMatch(titleLower);

    // Skip image lookup when the model/brand are WiFi-discovered placeholders
    // (e.g. brand="Device", model="Device at 192.168.x.x") — they produce random
    // unrelated photos which is worse than showing no image at all.
    final looksLikeNetworkDevice =
        RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(model ?? '') ||
        RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(brand ?? '') ||
        (brandLower == 'device' &&
            (modelLower.startsWith('device') ||
                modelLower.startsWith('unknown') ||
                modelLower.isEmpty));
    if (looksLikeNetworkDevice) {
      // Clear any image that may have been auto-set from a previous lookup
      widget.formData.productImageUrl = null;
      widget.formData.photoPath = null;
      widget.onNext();
      return;
    }

    // Only skip lookup if we have a reliable image AND it's for an actual product (not a plan/warranty)
    if (!isNonProduct &&
        existingImage != null &&
        existingImage.isNotEmpty &&
        Uri.tryParse(existingImage)?.hasScheme == true &&
        (widget.formData.enrichmentSource?.contains('bestbuy') == true ||
            widget.formData.enrichmentSource?.contains('barcode') == true ||
            widget.formData.enrichmentSource?.contains('serpapi') == true)) {
      widget.onNext();
      return;
    }

    if (!mounted) return;
    setState(() => _isResolvingImage = true);

    try {
      final result = await _barcodeLookupService.resolveProductImage(
        brand: brand,
        model: isNonProduct ? null : model, // Don't send warranty SKU as model
        category: category,
        productTitle: widget.formData.productTitle,
        manufacturer: widget.formData.manufacturer,
      );

      if (!mounted) return;

      final imageUrl = result['productImageUrl'];
      // Always record the source — even when imageUrl is null — so the UI can
      // explain WHY no photo is available (quota, no results, etc.)
      final imageSrc = result['imageSource'];
      setState(() => widget.formData.productImageSource = imageSrc);
      if (imageUrl != null && imageUrl.isNotEmpty) {
        setState(() {
          widget.formData.productImageUrl = imageUrl;
          widget.formData.photoPath = imageUrl;
          _imageSource = imageSrc;
          // Fill in missing details ONLY if not already set (preserves WiFi/barcode data)
          if (!_wifiDataLocked) {
            final name = result['productName'];
            if (name != null &&
                name.isNotEmpty &&
                (widget.formData.productTitle == null ||
                    widget.formData.productTitle!.isEmpty)) {
              widget.formData.productTitle = name;
              _productTitleController.text = name;
            }
            final desc = result['description'];
            if (desc != null &&
                desc.isNotEmpty &&
                (widget.formData.productDescription == null ||
                    widget.formData.productDescription!.isEmpty)) {
              widget.formData.productDescription = desc;
              _productDescriptionController.text = desc;
            }
          }
        });
      }
    } on Object catch (_) {
      // Silent — proceed with whatever image we have
    } finally {
      if (mounted) {
        setState(() => _isResolvingImage = false);
      }
    }

    widget.onNext();
  }

  /// After enrichment completes, checks if the product image is missing or
  /// doesn't match the actual asset. If so, calls the image resolution API
  /// with brand + assetType + model to get the right product photo.
  Future<void> _resolveImageAfterEnrichment({bool force = false}) async {
    if (!mounted) return;

    // ── In-flight deduplication ──────────────────────────────────────────────
    // If an image resolve is already running and this is NOT a user-forced
    // retry (e.g. Retry button or dialog confirmation), skip to avoid a
    // redundant API call and the billing cost that comes with it.
    if (_isAutoResolvingImage && !force) return;

    // Bump the generation counter. Any older in-flight call will see that its
    // saved generation no longer matches and will discard its result.
    final thisGeneration = ++_imageResolveGeneration;
    // ────────────────────────────────────────────────────────────────────────

    final currentImage = widget.formData.productImageUrl;
    final brand = widget.formData.brand;
    final rawModel = widget.formData.model;
    // assetType is the validated, possibly auto-corrected type — most reliable
    // signal for choosing the right product image.
    final assetType = widget.formData.selectedAssetType;
    // Use productCategory only as a fallback if assetType is somehow empty
    final category = (assetType?.isNotEmpty == true)
        ? assetType
        : (widget.formData.productCategory?.isNotEmpty == true)
        ? widget.formData.productCategory
        : widget.formData.selectedAssetType;

    // If no model number was found, try to extract a useful product name hint
    // from the product title. e.g., "Kishan's MacBook Air" → "MacBook Air".
    // This gives SerpAPI / BestBuy a much more precise query than just "Apple Computer".
    final model = (rawModel == null || rawModel.isEmpty)
        ? _cleanDeviceNameForSearch(widget.formData.productTitle)
        : rawModel;

    // Check if model looks like a non-product (warranty, plan, etc.)
    final modelStr = (model ?? '').toLowerCase();
    final titleStr = (widget.formData.productTitle ?? '').toLowerCase();
    final isNonProduct =
        modelStr.contains('\$') ||
        RegExp(
          r'\b(yr|year|plan|warranty|care\+?|protect|coverage|service)\b',
        ).hasMatch(modelStr) ||
        RegExp(
          r'\b(protection plan|warranty|care\+?|applecare|geek squad)\b',
        ).hasMatch(titleStr);

    // Skip only if we already have an image from a real product API (bestbuy/barcode/serpapi)
    // AND the product is not a warranty/plan (which returns logos)
    final hasReliableImage =
        !isNonProduct &&
        currentImage != null &&
        currentImage.isNotEmpty &&
        Uri.tryParse(currentImage)?.hasScheme == true &&
        (widget.formData.enrichmentSource?.contains('bestbuy') == true ||
            widget.formData.enrichmentSource?.contains('barcode') == true ||
            widget.formData.enrichmentSource?.contains('serpapi') == true);
    if (!force && hasReliableImage) return;

    // Don't fetch images for WiFi-discovered network devices — the brand/model
    // are generic placeholders (e.g. "Device at 192.168.x.x") and will only
    // return unrelated random photos.
    final brandStr = (brand ?? '').toLowerCase();
    if (RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(model ?? '') ||
        RegExp(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}').hasMatch(brand ?? '') ||
        (brandStr == 'device' &&
            (modelStr.startsWith('device') ||
                modelStr.startsWith('unknown') ||
                modelStr.isEmpty))) {
      return;
    }

    if ((brand == null || brand.isEmpty) &&
        (assetType == null || assetType.isEmpty)) {
      return;
    }

    const sep = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    const thin =
        '──────────────────────────────────────────────────────────────';
    final imgShort = currentImage != null && currentImage.length > 55
        ? '${currentImage.substring(0, 55)}…'
        : (currentImage ?? '—');
    debugPrint('');
    debugPrint(sep);
    debugPrint('🔄  RESOLVE IMAGE  │  force: $force');
    debugPrint(thin);
    debugPrint('📋  VALIDATED INPUTS (going to image API)');
    debugPrint('  ${'brand'.padRight(16)}▸ ${brand ?? '—'}');
    debugPrint('  ${'rawModel'.padRight(16)}▸ ${rawModel ?? '—'}');
    debugPrint('  ${'effectiveModel'.padRight(16)}▸ ${model ?? '—'}');
    debugPrint('  ${'assetType'.padRight(16)}▸ ${assetType ?? '—'}');
    debugPrint('  ${'serial'.padRight(16)}▸ ${widget.formData.serial ?? '—'}');
    debugPrint(
      '  ${'manufacturer'.padRight(16)}▸ ${widget.formData.manufacturer ?? '—'}',
    );
    debugPrint('  ${'isNonProduct'.padRight(16)}▸ $isNonProduct');
    debugPrint('  ${'currentImage'.padRight(16)}▸ $imgShort');
    debugPrint(thin);

    // Show loading indicator for manual entry flow
    if (mounted) setState(() => _isAutoResolvingImage = true);

    try {
      final result = await _barcodeLookupService.resolveProductImage(
        brand: brand,
        model: isNonProduct ? null : model,
        category: category,
        // Only pass productTitle if it's consistent with the validated assetType.
        // A mismatched title (e.g. "77\" OLED TV" when assetType=Microwave) would
        // make SerpAPI search for the wrong product entirely.
        productTitle:
            _isTitleCompatible(widget.formData.productTitle, assetType)
            ? widget.formData.productTitle
            : null,
        manufacturer: widget.formData.manufacturer,
        assetType: assetType,
        serial: widget.formData.serial,
      );
      // Discard result if a newer resolve call has since started
      // (e.g. user confirmed mismatch dialog while this was in-flight).
      if (!mounted || thisGeneration != _imageResolveGeneration) return;
      final imageUrl = result['productImageUrl'];
      const sep2 =
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final shortUrl = imageUrl.length > 55
            ? '${imageUrl.substring(0, 55)}…'
            : imageUrl;
        debugPrint('✅  RESULT  │  Image resolved successfully');
        debugPrint(
          '  ${'source'.padRight(16)}▸ ${result["imageSource"] ?? "—"}',
        );
        debugPrint('  ${'imageUrl'.padRight(16)}▸ $shortUrl');
        debugPrint(sep2);
        debugPrint('');
        setState(() {
          widget.formData.productImageUrl = imageUrl;
          widget.formData.photoPath = imageUrl;
          widget.formData.productImageSource = result['imageSource'];
          _imageSource = result['imageSource'];
          _isAutoResolvingImage = false;
        });
      } else {
        debugPrint(
          '⚠️   RESULT  │  No image URL returned — imageSource: ${result["imageSource"] ?? "—"}',
        );
        debugPrint(sep2);
        debugPrint('');
        setState(() {
          widget.formData.productImageSource = result['imageSource'];
          _isAutoResolvingImage = false;
        });
      }
    } on Object catch (e) {
      const sep3 =
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
      debugPrint('🔥  ERROR  │  $e');
      debugPrint(sep3);
      debugPrint('');
      if (mounted) setState(() => _isAutoResolvingImage = false);
    }
  }

  /// Strips leading personal-name possessives from a device display name so it
  /// can be used as a product search query.
  /// “Kishan’s MacBook Air” → “MacBook Air”
  /// “John’s iPhone 15 Pro” → “iPhone 15 Pro”
  /// Returns null if the result would be too short or identical to the input.
  String? _cleanDeviceNameForSearch(String? title) {
    if (title == null || title.isEmpty) return null;
    final cleaned = title
        .replaceFirst(RegExp(r"^\w+[\u2019']s?\s+", caseSensitive: false), '')
        .trim();
    if (cleaned.isEmpty || cleaned.length < 3 || cleaned == title) return null;
    return cleaned;
  }

  void _showMismatchDialog({
    required String selectedType,
    required String detectedType,
    required String source,
    String? reason,
  }) {
    final isModelBased = source == 'model';
    final accentColor = isModelBased ? AppColors.info : AppColors.warning;
    final accentBg = isModelBased
        ? AppColors.infoBackground
        : AppColors.warningBackground;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Padding(
          padding: EdgeInsets.all(responsive.spacing(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Icon badge ──
              Container(
                width: responsive.spacing(56),
                height: responsive.spacing(56),
                decoration: BoxDecoration(
                  color: accentBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isModelBased
                      ? Icons.swap_horiz_rounded
                      : Icons.warning_amber_rounded,
                  color: accentColor,
                  size: responsive.iconSize(28),
                ),
              ),
              SizedBox(height: responsive.spacing(16)),

              // ── Title ──
              Text(
                'Different Asset Type Detected',
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacing(8)),

              // ── Subtitle ──
              Text(
                isModelBased
                    ? 'The model number suggests a different product type than what you selected.'
                    : 'The scanned product appears to be a different type than what you selected.',
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: responsive.spacing(20)),

              // ── Comparison cards ──
              Container(
                decoration: BoxDecoration(
                  color: AppColors.backgroundGray50,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.all(responsive.spacing(16)),
                child: Column(
                  children: [
                    _buildMismatchTypeRow(
                      label: 'You selected',
                      typeName: selectedType,
                      color: AppColors.textSecondary,
                      bgColor: AppColors.backgroundGray100,
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(8),
                      ),
                      child: Icon(
                        Icons.arrow_downward_rounded,
                        color: accentColor,
                        size: responsive.iconSize(20),
                      ),
                    ),
                    _buildMismatchTypeRow(
                      label: 'Detected as',
                      typeName: detectedType,
                      color: accentColor,
                      bgColor: accentBg,
                    ),
                  ],
                ),
              ),

              // ── Reason (if available) ──
              if (reason != null) ...[
                SizedBox(height: responsive.spacing(12)),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(12),
                    vertical: responsive.spacing(8),
                  ),
                  decoration: BoxDecoration(
                    color: accentBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: accentColor,
                        size: responsive.iconSize(16),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: responsive.spacing(24)),

              // ── Action buttons (side by side) ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        // Allow showing again if user rescans
                        Future.delayed(const Duration(seconds: 2), () {
                          if (mounted) _mismatchDialogShown = false;
                        });
                        // Run image search with the KEPT (original) type
                        _resolveImageAfterEnrichment(force: true);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: BorderSide(color: AppColors.gray300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.spacing(14),
                        ),
                      ),
                      child: Text(
                        'Keep $selectedType',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          widget.formData.selectedAssetType = detectedType;
                          final categoryMap = {
                            'Refrigerator': 'Appliances',
                            'Washer': 'Appliances',
                            'Dryer': 'Appliances',
                            'Dishwasher': 'Appliances',
                            'Range / Stove': 'Appliances',
                            'Microwave': 'Appliances',
                            'Heating & Cooling': 'Home Systems',
                            'Water Heater': 'Home Systems',
                            'Garbage Disposal': 'Home Systems',
                            'Sump Pump': 'Home Systems',
                            'EV Charger': 'Home Systems',
                            'Security System': 'Home Systems',
                            'Television': 'Electronics',
                            'Computer': 'Electronics',
                            'Gaming Console': 'Electronics',
                            'Smart Speaker': 'Electronics',
                            'Security Camera': 'Electronics',
                          };
                          final newCategory = categoryMap[detectedType];
                          if (newCategory != null) {
                            widget.formData.selectedCategory = newCategory;
                          }
                        });
                        Navigator.of(ctx).pop();
                        _mismatchDialogShown = false;
                        // Run image search with the UPDATED (detected) type
                        _resolveImageAfterEnrichment(force: true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: AppColors.textOnPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(
                          vertical: responsive.spacing(14),
                        ),
                      ),
                      child: Text(
                        'Update Type',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a comparison row for the mismatch dialog showing
  /// the label ("You selected" / "Detected as") and the type name.
  Widget _buildMismatchTypeRow({
    required String label,
    required String typeName,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(14),
        vertical: responsive.spacing(12),
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: responsive.fontSize(11),
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.spacing(2)),
                Text(
                  typeName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  LABEL IMAGE SECTION (image + progress + results)
  // ═══════════════════════════════════════════════════════════════

  Widget _buildLabelImageSection() {
    final isLoading = _isExtractingFromImage || _isLookingUp;
    final hasImageExtraction =
        _labelExtractionResult != null &&
        _labelExtractionResult!.isSuccess &&
        _hasCriticalFields(_labelExtractionResult!);
    final hasEnrichedResult =
        _enrichedResult != null && _enrichedResult!.isSuccess;
    final isSuccess = hasImageExtraction || hasEnrichedResult;

    return Column(
      children: [
        // ── Image Display ──
        _buildLabelImageDisplay(isLoading: isLoading, isSuccess: isSuccess),
        SizedBox(height: responsive.spacing(16)),

        // ── Extraction Progress Steps (gallery upload path) ──
        if (_isExtractingFromImage) _buildExtractionProgressSteps(),

        // ── Barcode Lookup Progress (scan path) ──
        if (_isLookingUp && !_isExtractingFromImage)
          _buildBarcodeLookupProgress(),

        // ── Extraction Results (from image) ──
        if (!isLoading && hasImageExtraction) _buildExtractionResultsCard(),

        // ── Enriched Results (from barcode scan pipeline) ──
        if (!isLoading && !hasImageExtraction && hasEnrichedResult)
          _buildEnrichedResultsForImage(),

        // ── Product Image (resolved via SerpAPI after extraction) ──
        // Shown below the extracted-data card once the image API call finishes.
        if (!isLoading && isSuccess) _buildResolvedProductImageCard(),

        // ── Partial Match (barcode scan partial) ──
        if (!isLoading &&
            _isPartialMatch &&
            _partialInfo != null &&
            !hasImageExtraction &&
            !hasEnrichedResult)
          _buildPartialMatchForImage(),

        // ── Extraction Error ──
        if (!isLoading &&
            _labelExtractionResult != null &&
            (!_labelExtractionResult!.isSuccess ||
                !_hasCriticalFields(_labelExtractionResult!)))
          _buildExtractionErrorCard(),

        // ── Scan Error ──
        if (!isLoading &&
            _labelExtractionResult == null &&
            _scanError != null &&
            !_isPartialMatch)
          _buildScanErrorForImage(),

        // ── Action Buttons ──
        if (!isLoading) ...[
          SizedBox(height: responsive.spacing(12)),
          _buildLabelActionButtons(),
        ],

        // API usage tracked via console logging only
      ],
    );
  }

  Widget _buildLabelImageDisplay({
    required bool isLoading,
    required bool isSuccess,
  }) {
    final hasError =
        (_labelExtractionResult != null &&
            !_labelExtractionResult!.isSuccess) ||
        (_scanError != null && !_isPartialMatch);

    return GestureDetector(
      onTap: isLoading ? null : _showUploadLabelDrawer,
      child: DashedBorder(
        color: isSuccess
            ? AppColors.success
            : isLoading
            ? AppColors.primary
            : hasError
            ? AppColors.error
            : AppColors.gray300,
        strokeWidth: 2.0,
        dashWidth: 8.0,
        dashSpace: 5.0,
        borderRadius: 16.0,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 180),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                // The captured/uploaded image
                Image.memory(
                  _labelImage!,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                // Loading overlay
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              width: 36,
                              height: 36,
                              child: CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 3,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(12)),
                            Text(
                              _isExtractingFromImage
                                  ? 'Reading label...'
                                  : 'Processing...',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: responsive.fontSize(14),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Success badge — green if Barcode API was involved, blue if only ChatGPT
                if (isSuccess && !isLoading)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getExtractionBadgeColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.white,
                            size: responsive.iconSize(14),
                          ),
                          SizedBox(width: responsive.spacing(4)),
                          Text(
                            'Extracted',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: responsive.fontSize(12),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Tap to change hint
                if (!isLoading && !isSuccess)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: responsive.iconSize(14),
                          ),
                          SizedBox(width: responsive.spacing(4)),
                          Text(
                            'Tap to change',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: responsive.fontSize(11),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExtractionProgressSteps() {
    // User-friendly loading messages that rotate based on current step
    const friendlyMessages = [
      'Reading your product label...',
      'Identifying the product...',
      'Identifying the product...',
      'Looking up details...',
      'Almost done...',
      'Finishing up...',
    ];
    final msg =
        _currentExtractionStep >= 0 &&
            _currentExtractionStep < friendlyMessages.length
        ? friendlyMessages[_currentExtractionStep]
        : 'Analyzing your label...';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(18),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Text(
              msg,
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarcodeLookupProgress() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20),
        vertical: responsive.spacing(18),
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Text(
              'Looking up your product...',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build the list of extracted detail entries from a LabelExtractionResult.
  List<_ExtractedField> _buildFieldsFromLabelResult(
    LabelExtractionResult result,
  ) {
    // Show only the 8 enterprise fields the user cares about.
    // Full API response (description, color, additionalInfo, etc.) is logged
    // to the terminal — not surfaced in the UI card.
    final fields = <_ExtractedField>[];
    if (result.brand.isNotEmpty) {
      fields.add(_ExtractedField('Brand', result.brand));
    }
    if (result.model.isNotEmpty) {
      fields.add(_ExtractedField('Model Number', result.model));
    }
    if (result.serial.isNotEmpty) {
      fields.add(_ExtractedField('Serial Number', result.serial));
    }
    if (result.productType.isNotEmpty) {
      fields.add(_ExtractedField('Type', result.productType));
    }
    if (result.manufacturer?.isNotEmpty == true) {
      fields.add(_ExtractedField('Manufacturer', result.manufacturer!));
    }
    if (result.manufacturedYear?.isNotEmpty == true) {
      fields.add(_ExtractedField('Manufactured', result.manufacturedYear!));
    }
    if (result.madeIn?.isNotEmpty == true) {
      fields.add(_ExtractedField('Made In', result.madeIn!));
    }
    return fields;
  }

  /// Build the list of extracted detail entries from an EnrichedScanResult.
  List<_ExtractedField> _buildFieldsFromEnrichedResult(
    EnrichedScanResult result,
  ) {
    final fields = <_ExtractedField>[];
    if (result.brand.isNotEmpty) {
      fields.add(_ExtractedField('Brand', result.brand));
    }
    if (result.model.isNotEmpty) {
      fields.add(_ExtractedField('Model', result.model));
    }
    if (result.serialNumber.isNotEmpty) {
      fields.add(_ExtractedField('Serial', result.serialNumber));
    }
    if (result.barcode.isNotEmpty) {
      fields.add(_ExtractedField('Barcode', result.barcode));
    }
    if (result.productName.isNotEmpty) {
      fields.add(_ExtractedField('Product', result.productName));
    }
    if (result.manufacturer.isNotEmpty) {
      fields.add(_ExtractedField('Manufacturer', result.manufacturer));
    }
    if (result.description.isNotEmpty) {
      fields.add(_ExtractedField('Description', result.description));
    }
    if (result.category.isNotEmpty) {
      fields.add(_ExtractedField('Category', result.category));
    }
    if (result.color.isNotEmpty) {
      fields.add(_ExtractedField('Color', result.color));
    }
    return fields;
  }

  Widget _buildExtractionResultsCard() {
    final result = _labelExtractionResult!;
    final fields = _buildFieldsFromLabelResult(result);
    return _buildReadOnlyDetailsCard(
      title: 'Details Extracted Successfully',
      fields: fields,
    );
  }

  Widget _buildEnrichedResultsForImage() {
    final result = _enrichedResult!;
    final fields = _buildFieldsFromEnrichedResult(result);
    return _buildReadOnlyDetailsCard(
      title: 'Product Identified',
      fields: fields,
    );
  }

  /// Product image card shown below the extracted-data card in the Upload Label
  /// tab after a successful scan/OCR extraction. Displays a loading spinner
  /// while SerpAPI is fetching the image, then fades in the result.
  Widget _buildResolvedProductImageCard() {
    final imageUrl = widget.formData.productImageUrl;
    final isLoading = _isAutoResolvingImage;

    // Nothing to show yet and not loading — hide entirely
    if (!isLoading && (imageUrl == null || imageUrl.isEmpty)) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Icon(
              Icons.image_search_rounded,
              size: responsive.iconSize(16),
              color: AppColors.textSecondary,
            ),
            SizedBox(width: responsive.spacing(6)),
            Text(
              'Product Image',
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(8)),
        Container(
          width: double.infinity,
          height: 180,
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray300.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: AppColors.shadow,
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: isLoading
                ? Center(
                    child: Column(
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
                        SizedBox(height: responsive.spacing(10)),
                        Text(
                          'Finding product image…',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : AnimatedOpacity(
                    key: ValueKey(imageUrl),
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 350),
                    child: Image.network(
                      imageUrl!,
                      fit: BoxFit.contain,
                      loadingBuilder: (_, child, prog) {
                        if (prog == null) return child;
                        return Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                              value: prog.expectedTotalBytes != null
                                  ? prog.cumulativeBytesLoaded /
                                        prog.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, _, _) => Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.broken_image_outlined,
                              size: 32,
                              color: AppColors.gray300,
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            Text(
                              'Image unavailable',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  /// Simple read-only card showing extracted fields.
  Widget _buildReadOnlyDetailsCard({
    required String title,
    required List<_ExtractedField> fields,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.successSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.successBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.check_circle,
                size: responsive.iconSize(20),
                color: AppColors.success,
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: Text(
                  'Details Extracted Successfully',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.successDark,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          ...fields.map((f) => _extractedDetailRow(f.label, f.value)),
        ],
      ),
    );
  }

  Widget _buildPartialMatchForImage() {
    final info = _partialInfo!;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.infoBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                size: responsive.iconSize(20),
                color: AppColors.info,
              ),
              SizedBox(width: responsive.spacing(8)),
              Text(
                'Partial Match Found',
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.infoDark,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            info.userMessage,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: AppColors.textSecondary,
            ),
          ),
          if (info.brand != null) ...[
            SizedBox(height: responsive.spacing(8)),
            _extractedDetailRow('Brand', info.brand!),
          ],
        ],
      ),
    );
  }

  Widget _buildExtractionErrorCard() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                size: responsive.iconSize(20),
                color: AppColors.error,
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: Text(
                  _labelExtractionResult?.errorMessage ??
                      'Could not extract details',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    color: AppColors.error,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Try uploading a clearer image or enter details manually.',
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanErrorForImage() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorBorder),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: responsive.iconSize(20),
            color: AppColors.error,
          ),
          SizedBox(width: responsive.spacing(8)),
          Expanded(
            child: Text(
              _scanError ?? 'Product not found',
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _extractedDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.spacing(3)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Returns the badge color based on data source:
  /// Green if Barcode API was involved (alone or merged), Blue if only ChatGPT.
  Color _getExtractionBadgeColor() {
    // Check label extraction result first
    if (_labelExtractionResult != null) {
      final source = _labelExtractionResult!.enrichmentSource;
      if (source == 'merged' ||
          source == 'barcode_api' ||
          _labelExtractionResult!.barcodeApiSuccess) {
        return AppColors.success; // Green — Barcode API involved
      }
      return const Color(0xFF2196F3); // Blue — ChatGPT only
    }
    // Check enriched scan result
    if (_enrichedResult != null) {
      final source = _enrichedResult!.source;
      if (source == 'barcode_api' || source == 'merged') {
        return AppColors.success; // Green
      }
      return const Color(0xFF2196F3); // Blue
    }
    return AppColors.success; // Default green
  }

  Widget _buildLabelActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showUploadLabelDrawer,
            icon: Icon(Icons.refresh, size: responsive.iconSize(18)),
            label: const Text('Re-upload'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary),
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _switchToManualWithExtractedData,
            icon: Icon(Icons.edit_note, size: responsive.iconSize(18)),
            label: const Text('Edit Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sync ALL extracted data into manual entry controllers and switch tab.
  ///
  /// Only populates fields that were actually extracted from the label scan
  /// so the manual tab mirrors the extraction card exactly.
  void _switchToManualWithExtractedData() {
    // Clear all controllers first — only label-extracted fields should appear
    _brandController.text = '';
    _modelController.text = '';
    _serialController.text = '';
    _manufacturerController.text = '';
    _barcodeController.text = '';
    _productDescriptionController.text = '';
    _colorController.text = '';
    _productTitleController.text = '';
    _productCategoryController.text = '';
    _productTypeController.text = '';
    _additionalInfoControllers.clear();

    // Populate ONLY from the label extraction result
    if (_labelExtractionResult != null && _labelExtractionResult!.isSuccess) {
      final r = _labelExtractionResult!;
      if (r.brand.isNotEmpty) {
        _brandController.text = r.brand;
        widget.formData.brand = r.brand;
      }
      if (r.model.isNotEmpty) {
        _modelController.text = r.model;
        widget.formData.model = r.model;
      }
      if (r.serial.isNotEmpty) {
        _serialController.text = r.serial;
        widget.formData.serial = r.serial;
      }
      if (r.productType.isNotEmpty) {
        _productTypeController.text = r.productType;
      }
      if (r.manufacturer?.isNotEmpty == true) {
        _manufacturerController.text = r.manufacturer!;
        widget.formData.manufacturer = r.manufacturer;
      }

      // Populate dynamic additionalInfo controllers
      if (r.additionalInfo != null && r.additionalInfo!.isNotEmpty) {
        for (final entry in r.additionalInfo!.entries) {
          if (entry.value.isNotEmpty) {
            _additionalInfoControllers[entry.key] = TextEditingController();
            _additionalInfoControllers[entry.key]!.text = entry.value;
          }
        }
      }

      // manufacturedYear and madeIn are top-level fields on LabelExtractionResult
      if (r.manufacturedYear?.isNotEmpty == true) {
        _additionalInfoControllers['manufacturedYear'] =
            TextEditingController();
        _additionalInfoControllers['manufacturedYear']!.text =
            r.manufacturedYear!;
      }
      if (r.madeIn?.isNotEmpty == true) {
        _additionalInfoControllers['madeIn'] = TextEditingController();
        _additionalInfoControllers['madeIn']!.text = r.madeIn!;
      }
    }

    setState(() {
      widget.formData.identificationMethod = 'manual';
    });
  }

  /// Fetch dynamic brands from ChatGPT for the selected asset type
  Future<void> _fetchDynamicBrands() async {
    final assetType = widget.formData.selectedAssetType;
    if (assetType == null) return;

    setState(() {
      _isLoadingBrands = true;
      _dynamicBrands = [];
    });

    try {
      final brands = await _chatGPTService.getBrands(assetType: assetType);

      if (mounted) {
        setState(() {
          // Deduplicate to prevent DropdownButton assertion (duplicate values crash)
          final uniqueBrands = brands.toSet().toList();
          _dynamicBrands = uniqueBrands.isNotEmpty ? uniqueBrands : ['Other'];
          _isLoadingBrands = false;
        });

        // If brand was already selected, fetch subcategories too
        if (_selectedBrand != null && _activeBrands.contains(_selectedBrand)) {
          _fetchDynamicSubCategories(_selectedBrand!);
        } else if (_selectedBrand != null) {
          // The guidance-section dropdown brand is no longer in the freshly
          // loaded list.  Reset the dropdown selection ONLY — do NOT touch
          // formData.brand or _brandController because those hold live data
          // entered via image scan, WiFi discovery, or manual typing and must
          // survive a background brand-list reload.
          setState(() {
            _selectedBrand = null;
            _selectedSubCategory = null;
            widget.formData.subCategory = null;
          });
        }
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _dynamicBrands = ['Other'];
          _isLoadingBrands = false;
        });
      }
    }
  }

  /// Fetch dynamic subcategories from ChatGPT based on brand
  Future<void> _fetchDynamicSubCategories(String brand) async {
    final assetType = widget.formData.selectedAssetType;
    if (assetType == null) return;

    setState(() {
      _isLoadingSubCategories = true;
      _dynamicSubCategories = [];
    });

    try {
      final subCategories = await _chatGPTService.getSubCategories(
        assetType: assetType,
        brand: brand,
      );

      if (mounted) {
        setState(() {
          _dynamicSubCategories = subCategories.isNotEmpty ? subCategories : [];
          _isLoadingSubCategories = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        setState(() {
          _dynamicSubCategories = [];
          _isLoadingSubCategories = false;
        });
      }
    }
  }

  /// Fetch nameplate guidance and label image from ChatGPT/DALL-E
  Future<void> _fetchNameplateGuidance() async {
    final assetType = widget.formData.selectedAssetType;
    final brand = _selectedBrand;
    final subCategory = _selectedSubCategory;

    if (assetType == null || brand == null || subCategory == null) {
      return;
    }

    setState(() {
      _isLoadingGuidance = true;
      _isLoadingImage = true;
      _guidanceError = null;
      _wireframeImage = null;
    });

    // Fetch guidance text (fast - ChatGPT)
    _chatGPTService
        .generateNameplateGuidance(
          assetType: assetType,
          brand: brand,
          subCategory: subCategory,
        )
        .then((guidance) {
          if (mounted) {
            setState(() {
              _nameplateGuidance = guidance;
              _isLoadingGuidance = false;
            });
          }
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _guidanceError =
                  'Unable to load guidance. Please check your internet connection.';
              _isLoadingGuidance = false;
            });
          }
        });

    // Fetch wireframe image via DALL-E (using local mapping for prompt hints)
    final pos = getLabelPosition(
      assetType: assetType,
      brand: brand,
      subCategory: subCategory,
    );
    _chatGPTService
        .generateWireframeImage(
          assetType: assetType,
          brand: brand,
          subCategory: subCategory,
          labelHint: pos.promptHint,
          viewAngle: pos.viewAngle,
        )
        .then((imageBytes) {
          if (mounted) {
            setState(() {
              _wireframeImage = imageBytes;
              _isLoadingImage = false;
            });
          }
        })
        .catchError((Object e) {
          if (mounted) {
            setState(() {
              _isLoadingImage = false;
            });
          }
        });
  }

  Widget _buildContinueButton() {
    final isValid = widget.formData.isStep2Valid();
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
          onPressed: isValid && !_isResolvingImage
              ? () => _resolveImageAndContinue()
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: isValid
                ? AppColors.primary
                : AppColors.gray300.withValues(alpha: 0.5),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.zero,
            disabledBackgroundColor: AppColors.gray300.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isResolvingImage
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: responsive.iconSize(18),
                      height: responsive.iconSize(18),
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    Flexible(
                      child: Text(
                        'Finding product image...',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Continue',
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: isValid
                        ? Colors.white
                        : AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
        ),
      ),
    );
  }
}

/// Represents a single extracted detail field with label and value.
class _ExtractedField {
  final String label;
  final String value;

  const _ExtractedField(this.label, this.value);
}
