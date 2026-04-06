// ignore_for_file: unused_element, use_null_aware_elements

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/config/environment.dart';
import '../core/utils/logger.dart';
import '../features/assets/add_asset_flow/models/label_location_model.dart';
import 'api_client.dart';
import 'api_diagnostics_logger.dart';
import 'api_usage_tracker.dart';

/// Simple label position info for matching steps to image
class LabelPositionInfo {
  final String promptHint;
  final String viewAngle;

  LabelPositionInfo({required this.promptHint, required this.viewAngle});
}

/// ChatGPT Service for generating dynamic nameplate location guidance
class ChatGPTService {
  static final ChatGPTService _instance = ChatGPTService._internal();
  factory ChatGPTService() => _instance;
  ChatGPTService._internal();

  final _usageTracker = ApiUsageTracker();
  final _diagLogger = ApiDiagnosticsLogger();
  final _apiClient = ApiClient();

  /// Get dynamic brands from backend AI endpoint
  Future<List<String>> getBrands({required String assetType}) async {
    try {
      final response = await _apiClient.post(
        '/ai/get-brands',
        body: {'assetType': assetType},
        timeout: const Duration(seconds: 15),
      );

      _usageTracker.recordOpenAiRequest();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['data'] as Map<String, dynamic>?) ?? data;
        final brands = List<String>.from(content['brands'] ?? []);
        brands.remove('Other');
        brands.add('Other');
        return brands;
      }
      return [];
    } on Object catch (e) {
      AppLogger.error('Error fetching brands: $e', tag: 'ChatGPT', error: e);
      return [];
    }
  }

  /// Get dynamic subcategories from backend AI endpoint
  Future<List<String>> getSubCategories({
    required String assetType,
    required String brand,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/get-subcategories',
        body: {'assetType': assetType, 'brand': brand},
        timeout: const Duration(seconds: 15),
      );

      _usageTracker.recordOpenAiRequest();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['data'] as Map<String, dynamic>?) ?? data;
        return List<String>.from(content['subCategories'] ?? []);
      }
      return [];
    } on Object catch (e) {
      AppLogger.error(
        'Error fetching subcategories: $e',
        tag: 'ChatGPT',
        error: e,
      );
      return [];
    }
  }

  /// Generate a clean wireframe image via backend (DALL-E proxy)
  Future<Uint8List?> generateWireframeImage({
    required String assetType,
    required String brand,
    required String subCategory,
    required String labelHint,
    required String viewAngle,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/generate-wireframe',
        body: {
          'assetType': assetType,
          'brand': brand,
          'subCategory': subCategory,
          'labelHint': labelHint,
          'viewAngle': viewAngle,
        },
        timeout: const Duration(seconds: 120),
      );

      _usageTracker.recordDalleRequest();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final b64 =
            ((data['data'] as Map<String, dynamic>?)?['image'] ?? data['image'])
                as String?;
        if (b64 != null && b64.isNotEmpty) {
          return base64Decode(b64);
        }
      } else {
        AppLogger.error(
          'Wireframe API error: ${response.statusCode}',
          tag: 'ChatGPT',
        );
      }
    } on Object catch (e) {
      AppLogger.error(
        'Error generating wireframe image: $e',
        tag: 'ChatGPT',
        error: e,
      );
    }
    return null;
  }

  /// Generate complete label location data via backend:
  /// 1. Ask backend for exact label positions
  /// 2. Generate a clean wireframe via backend (DALL-E proxy)
  Future<ProductLabelData> generateProductLabelData({
    required String assetType,
    required String brand,
    required String subCategory,
  }) async {
    List<LabelIndicator> indicators = [];
    String viewDesc = '';

    try {
      // STEP 1: Get structured label location data from backend
      final locationResponse = await _apiClient.post(
        '/ai/label-locations',
        body: {
          'assetType': assetType,
          'brand': brand,
          'subCategory': subCategory,
        },
        timeout: const Duration(seconds: 15),
      );

      _usageTracker.recordOpenAiRequest();
      String labelLocation = 'on the back panel';
      String viewAngle = 'front view';

      if (locationResponse.statusCode == 200) {
        final locData =
            jsonDecode(locationResponse.body) as Map<String, dynamic>;
        final locContent =
            (locData['data'] as Map<String, dynamic>?) ?? locData;

        viewDesc = locContent['view'] as String? ?? '';
        viewAngle = viewDesc.isNotEmpty ? viewDesc : 'front view';
        labelLocation = '';

        final labels = locContent['labels'] as List<dynamic>? ?? [];
        for (int i = 0; i < labels.length; i++) {
          final label = labels[i] as Map<String, dynamic>;
          indicators.add(LabelIndicator.fromJson(label, i));
          if (labelLocation.isNotEmpty) labelLocation += '. Also ';
          labelLocation += label['short_label'] as String? ?? '';
        }

        if (indicators.isEmpty) {
          indicators = [
            LabelIndicator(
              number: 1,
              position: LabelPosition.backPanel,
              shortLabel: 'Check back panel for label',
              fullDescription:
                  'Look at the back of the $assetType for a white sticker with model and serial numbers.',
            ),
          ];
          labelLocation = 'on the back panel';
        }
      } else {
        indicators = [
          LabelIndicator(
            number: 1,
            position: LabelPosition.backPanel,
            shortLabel: 'Check back panel for label',
            fullDescription:
                'Look at the back of the $assetType for a white sticker with model and serial numbers.',
          ),
        ];
        labelLocation = 'on the back panel';
      }

      // STEP 2: Generate wireframe image via backend (DALL-E proxy)
      Uint8List? imageBytes;
      try {
        final response = await _apiClient.post(
          '/ai/generate-wireframe',
          body: {
            'assetType': assetType,
            'brand': brand,
            'subCategory': subCategory,
            'labelHint': labelLocation,
            'viewAngle': viewAngle,
          },
          timeout: const Duration(seconds: 120),
        );

        _usageTracker.recordDalleRequest();
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final b64 =
              ((data['data'] as Map<String, dynamic>?)?['image'] ??
                      data['image'])
                  as String?;
          if (b64 != null && b64.isNotEmpty) {
            imageBytes = base64Decode(b64);
          }
        } else {
          AppLogger.error(
            'Wireframe API error: ${response.statusCode}',
            tag: 'ChatGPT',
          );
        }
      } on Object catch (e) {
        AppLogger.error(
          'Error generating wireframe: $e',
          tag: 'ChatGPT',
          error: e,
        );
      }

      return ProductLabelData(
        wireframeImage: imageBytes,
        indicators: indicators,
        viewDescription: viewDesc,
      );
    } on Object catch (e) {
      AppLogger.error(
        'Error in generateProductLabelData: $e',
        tag: 'ChatGPT',
        error: e,
      );
      return ProductLabelData(
        indicators: indicators.isNotEmpty
            ? indicators
            : [
                LabelIndicator(
                  number: 1,
                  position: LabelPosition.backPanel,
                  shortLabel: 'Check back panel for label',
                  fullDescription:
                      'Look at the back of the $assetType for a white sticker with model and serial numbers.',
                ),
              ],
        viewDescription: viewDesc,
      );
    }
  }

  /// Legacy method — now delegates to generateProductLabelData
  Future<Uint8List?> generateLabelLocationImage({
    required String assetType,
    required String brand,
    required String subCategory,
  }) async {
    final data = await generateProductLabelData(
      assetType: assetType,
      brand: brand,
      subCategory: subCategory,
    );
    return data.wireframeImage;
  }

  /// Generate nameplate location guidance via backend AI endpoint
  Future<NameplateGuidance> generateNameplateGuidance({
    required String assetType,
    required String brand,
    required String subCategory,
  }) async {
    try {
      final labelPos = _getLabelPosition(assetType, brand, subCategory);

      final response = await _apiClient.post(
        '/ai/nameplate-guidance',
        body: {
          'assetType': assetType,
          'brand': brand,
          'subCategory': subCategory,
          'promptHint': labelPos.promptHint,
          'viewAngle': labelPos.viewAngle,
        },
        timeout: const Duration(seconds: 30),
      );

      _usageTracker.recordOpenAiRequest();
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = (data['data'] as Map<String, dynamic>?) ?? data;

        return NameplateGuidance(
          description:
              content['description'] ??
              _getFallbackDescription(assetType, brand, subCategory),
          steps: List<String>.from(
            content['steps'] ?? _getFallbackSteps(assetType, subCategory),
          ),
        );
      } else {
        return _getFallbackGuidance(assetType, brand, subCategory);
      }
    } on Object catch (e) {
      AppLogger.error(
        'Error generating nameplate guidance: $e',
        tag: 'ChatGPT',
        error: e,
      );
      return _getFallbackGuidance(assetType, brand, subCategory);
    }
  }

  String _buildPrompt(String assetType, String brand, String subCategory) {
    // Get the actual label position from the mapping to ensure steps match the image
    final labelPos = _getLabelPosition(assetType, brand, subCategory);

    return '''
I am an elderly person in the USA. I own a $brand $subCategory $assetType.
I need to find the product label that has the model number and serial number.

IMPORTANT: Based on technical specifications for $brand $subCategory $assetType, the product label is located: ${labelPos.promptHint}

Tell me exactly where to look, step by step:
- Give me 3-5 simple steps to find the label at this EXACT location: ${labelPos.promptHint}
- Make sure the steps match the actual location (${labelPos.viewAngle})
- If the label is on the front/outside, DO NOT tell me to open doors
- If the label is inside/hidden, DO tell me how to access it
- What does the label look like? (color, size)
- What numbers should I look for?

Keep it super simple. Short sentences only. The steps MUST match the actual label location.
''';
  }

  /// Get label position from local mapping (used by image generation)
  LabelPositionInfo _getLabelPosition(
    String assetType,
    String brand,
    String subCategory,
  ) {
    // This should use the same logic as the screen's getLabelPosition function
    // For now, return a basic mapping

    // Common dishwasher positions
    if (assetType.toLowerCase().contains('dishwasher')) {
      if (brand.toLowerCase().contains('bosch') ||
          brand.toLowerCase().contains('miele')) {
        return LabelPositionInfo(
          promptHint:
              'on the top edge of the door frame when you open the door',
          viewAngle: 'front view with door open showing top edge',
        );
      } else {
        return LabelPositionInfo(
          promptHint:
              'on the front panel at the top edge, visible without opening',
          viewAngle: 'front view',
        );
      }
    }

    // Common refrigerator positions
    if (assetType.toLowerCase().contains('refrigerator')) {
      if (subCategory.toLowerCase().contains('side')) {
        return LabelPositionInfo(
          promptHint: 'inside the refrigerator on the left wall near the top',
          viewAngle: 'front view with left door open',
        );
      } else {
        return LabelPositionInfo(
          promptHint: 'inside on the upper left or right wall',
          viewAngle: 'front view with door open',
        );
      }
    }

    // Common washing machine positions
    if (assetType.toLowerCase().contains('washing')) {
      return LabelPositionInfo(
        promptHint: 'behind the door or on the top edge of the opening',
        viewAngle: 'front view with door open',
      );
    }

    // Default fallback
    return LabelPositionInfo(
      promptHint: 'on the back panel or inside the unit',
      viewAngle: 'front view',
    );
  }

  /// Fallback guidance when API fails
  NameplateGuidance _getFallbackGuidance(
    String assetType,
    String brand,
    String subCategory,
  ) {
    return NameplateGuidance(
      description: _getFallbackDescription(assetType, brand, subCategory),
      steps: _getFallbackSteps(assetType, subCategory),
    );
  }

  String _getFallbackDescription(
    String assetType,
    String brand,
    String subCategory,
  ) {
    final category = subCategory.isNotEmpty
        ? subCategory.toLowerCase()
        : assetType.toLowerCase();
    return 'Finding the model and serial number on your $brand $category is straightforward. Here\'s where to look!';
  }

  List<String> _getFallbackSteps(String assetType, String subCategory) {
    // Provide generic but helpful fallback steps based on asset type
    if (assetType.toLowerCase().contains('refrigerator')) {
      if (subCategory.toLowerCase().contains('side')) {
        return [
          'Open the refrigerator door',
          'Look on the left or right interior wall',
          'Check near the vegetable/crisper drawer area',
          'Look for a white or metallic sticker with model/serial numbers',
        ];
      } else {
        return [
          'Open the refrigerator door',
          'Check the interior left or right wall',
          'Look near the top or middle section',
          'Find the product label sticker with model and serial numbers',
        ];
      }
    } else if (assetType.toLowerCase().contains('washing machine')) {
      return [
        'Open the washing machine door or lid',
        'Look at the top inner rim or door frame',
        'Check the back panel near the water connections',
        'Look for a sticker or metal plate with model/serial numbers',
      ];
    } else if (assetType.toLowerCase().contains('air conditioner')) {
      if (subCategory.toLowerCase().contains('portable')) {
        return [
          'Check the side panel of the unit',
          'Look for a metal or sticker label',
          'Alternatively, check the back of the unit',
          'Note the model and serial numbers from the label',
        ];
      } else if (subCategory.toLowerCase().contains('window') ||
          subCategory.toLowerCase().contains('split')) {
        return [
          'Look at the front panel or grille',
          'Check the side panels of the indoor unit',
          'For outdoor units, check the side or back panel',
          'Find the product label with model/serial numbers',
        ];
      } else {
        return [
          'Check the indoor unit\'s front or side panel',
          'Open the front cover to check inside',
          'Look at the outdoor unit\'s side panel',
          'Find the product information label',
        ];
      }
    } else if (assetType.toLowerCase().contains('microwave')) {
      return [
        'Open the microwave door',
        'Check the inner door frame or edge',
        'Look at the back or side panel of the unit',
        'Find the product label with model/serial information',
      ];
    } else if (assetType.toLowerCase().contains('dishwasher')) {
      return [
        'Open the dishwasher door fully',
        'Look along the top edge or door frame',
        'Check the side panels inside the door',
        'Locate the product label sticker',
      ];
    } else if (assetType.toLowerCase().contains('water heater')) {
      return [
        'Look at the front panel of the water heater',
        'Check the side panels',
        'Look near the control panel or temperature dial',
        'Find the product identification label',
      ];
    } else {
      // Generic fallback for any other asset type
      return [
        'Check the back panel of the unit',
        'Look at the side panels',
        'Check inside doors or access panels',
        'Find the product label with model and serial numbers',
      ];
    }
  }

  /// Extract product details from a label image via backend AI endpoint.
  ///
  /// Routes through `/api/v1/ai/analyze-label` so the OpenAI key stays
  /// server-side and is never embedded in the mobile app.
  ///
  /// Takes [imageBytes] (JPEG/PNG) and optionally an [assetType] hint.
  /// Returns [LabelExtractionResult] with brand, model, serial, barcode, etc.
  Future<LabelExtractionResult> extractDetailsFromLabelImage(
    Uint8List imageBytes, {
    String? assetType,
  }) async {
    final stopwatch = Stopwatch()..start();
    try {
      final base64Image = base64Encode(imageBytes);
      final apiClient = ApiClient();

      final response = await apiClient.post(
        '/ai/analyze-label',
        body: {
          'image': base64Image,
          if (assetType != null) 'assetType': assetType,
        },
        timeout: const Duration(seconds: 45),
      );

      stopwatch.stop();
      _usageTracker.recordOpenAiVisionRequest();
      _diagLogger.logOpenAiCall(
        endpoint: '${EnvironmentConfig.apiV1Url}/ai/analyze-label',
        model: 'gpt-4o (Vision via backend)',
        statusCode: response.statusCode,
        responseTime: stopwatch.elapsed,
        purpose:
            'Extract details from label image${assetType != null ? ' ($assetType)' : ''}',
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        // Backend wraps in { success: true, data: { ... } }
        final content = (body['data'] as Map<String, dynamic>?) ?? body;
        final mfr = (content['manufacturer'] as String? ?? '').trim();
        final mfgYear = (content['manufacturedYear'] as String? ?? '').trim();
        final madeInVal = (content['madeIn'] as String? ?? '').trim();
        // Barcode API enrichment fields (for mismatch detection only)
        final productTitle = (content['productTitle'] as String?);
        final productDescription = (content['productDescription'] as String?);
        final productCategory = (content['productCategory'] as String?);
        return LabelExtractionResult(
          brand: (content['brand'] as String? ?? '').trim(),
          model: (content['model'] as String? ?? '').trim(),
          serial: (content['serial'] as String? ?? '').trim(),
          barcode: (content['barcode'] as String? ?? '').trim(),
          productType: (content['productType'] as String? ?? '').trim(),
          manufacturer: mfr.isNotEmpty ? mfr : null,
          manufacturedYear: mfgYear.isNotEmpty ? mfgYear : null,
          madeIn: madeInVal.isNotEmpty ? madeInVal : null,
          productTitle: (productTitle?.isNotEmpty == true)
              ? productTitle
              : null,
          productDescription: (productDescription?.isNotEmpty == true)
              ? productDescription
              : null,
          productCategory: (productCategory?.isNotEmpty == true)
              ? productCategory
              : null,
          enrichmentSource: content['enrichmentSource'] as String? ?? 'chatgpt',
          barcodeApiSuccess: content['barcodeApiSuccess'] as bool? ?? false,
          isSuccess: true,
        );
      } else if (response.statusCode == 401) {
        return LabelExtractionResult(
          isSuccess: false,
          errorMessage: 'Please sign in again to use this feature.',
        );
      } else if (response.statusCode == 503 || response.statusCode == 500) {
        return LabelExtractionResult(
          isSuccess: false,
          errorMessage:
              'Our image reading service is temporarily unavailable. Please enter your product details manually.',
        );
      } else {
        AppLogger.error(
          'Label analysis API error: ${response.statusCode} - ${response.body}',
          tag: 'ChatGPT',
        );
        return LabelExtractionResult(
          isSuccess: false,
          errorMessage:
              'We couldn\'t read your product label right now. Please try again or enter details manually.',
        );
      }
    } on http.ClientException catch (_) {
      return LabelExtractionResult(
        isSuccess: false,
        errorMessage:
            'Unable to connect to the server. Please check your internet connection and try again.',
      );
    } on Object catch (e) {
      AppLogger.error(
        'Error extracting from label image: $e',
        tag: 'ChatGPT',
        error: e,
      );
      if (e.toString().contains('TimeoutException') ||
          e.toString().contains('timed out')) {
        return LabelExtractionResult(
          isSuccess: false,
          errorMessage:
              'Reading your label is taking too long. Please try a clearer photo or enter details manually.',
        );
      }
      return LabelExtractionResult(
        isSuccess: false,
        errorMessage:
            'Something went wrong while reading your label. Please try again or enter details manually.',
      );
    }
  }
}

/// Data model for nameplate guidance
class NameplateGuidance {
  final String description;
  final List<String> steps;
  final String? imageUrl;

  NameplateGuidance({
    required this.description,
    required this.steps,
    this.imageUrl,
  });
}

/// Result of extracting product details from a label image via GPT-4o Vision.
/// After initial extraction, the barcode/model can be sent to the Barcode
/// Lookup API for enriched product details (title, price, stores, images).
class LabelExtractionResult {
  final String brand;
  final String model;
  final String serial;
  final String barcode;
  final String productType;
  final Map<String, String>? additionalInfo;
  final bool isSuccess;
  final String? errorMessage;

  // ── 8 display fields extracted by GPT-4o ──
  // manufacturer: full legal company name (e.g. "Samsung Electronics Co., Ltd.")
  // manufacturedYear: 4-digit year if present on label (replaces productYear)
  // madeIn: country of manufacture from label
  final String? manufacturer;
  final String? manufacturedYear;
  final String? madeIn;

  /// Legacy alias — kept for compatibility; same as manufacturedYear.
  String get productYear => manufacturedYear ?? '';

  // Barcode API enrichment fields (for mismatch detection — NOT shown in card)
  final String? productTitle;
  final String? productDescription;
  final String? productCategory;
  final String? productImageUrl;
  final String? productColor;

  /// Tracks where each field came from: 'chatgpt', 'barcode_api', or 'merged'
  final String enrichmentSource;

  /// True if Barcode API lookup was performed (regardless of result)
  final bool barcodeApiAttempted;

  /// True if Barcode API returned product data
  final bool barcodeApiSuccess;

  LabelExtractionResult({
    this.brand = '',
    this.model = '',
    this.serial = '',
    this.barcode = '',
    this.productType = '',
    this.additionalInfo,
    this.isSuccess = false,
    this.errorMessage,
    this.manufacturer,
    this.manufacturedYear,
    this.madeIn,
    this.productTitle,
    this.productDescription,
    this.productCategory,
    this.productImageUrl,
    this.productColor,
    this.enrichmentSource = 'chatgpt',
    this.barcodeApiAttempted = false,
    this.barcodeApiSuccess = false,
  });

  /// Create a copy with Barcode API enrichment data merged in.
  LabelExtractionResult copyWithBarcodeEnrichment({
    String? productTitle,
    String? productDescription,
    String? productCategory,
    String? manufacturer,
    String? productImageUrl,
    String? productColor,
    String? enrichedBrand,
    String? enrichedModel,
    String? enrichedBarcode,
    required bool barcodeApiSuccess,
  }) {
    return LabelExtractionResult(
      // GPT-extracted identifiers from the physical label take priority.
      // Fall back to barcode API only if GPT found nothing.
      brand: brand.isNotEmpty ? brand : (enrichedBrand ?? ''),
      model: model.isNotEmpty ? model : (enrichedModel ?? ''),
      serial: serial,
      barcode: barcode.isNotEmpty ? barcode : (enrichedBarcode ?? ''),
      productType: productType,
      additionalInfo: additionalInfo,
      isSuccess: isSuccess,
      errorMessage: errorMessage,
      // GPT fields take priority; barcode API fills in only if GPT found nothing
      manufacturer: (this.manufacturer?.isNotEmpty == true)
          ? this.manufacturer
          : manufacturer,
      manufacturedYear: manufacturedYear,
      madeIn: madeIn,
      productTitle: productTitle,
      productDescription: productDescription,
      productCategory: productCategory,
      productImageUrl: productImageUrl,
      productColor: productColor,
      enrichmentSource: barcodeApiSuccess ? 'merged' : 'chatgpt',
      barcodeApiAttempted: true,
      barcodeApiSuccess: barcodeApiSuccess,
    );
  }

  /// Per-field source map for UI display.
  Map<String, String> get fieldSources {
    final map = <String, String>{};
    // Brand and model always come from the physical label (ChatGPT vision);
    // barcode API only fills gaps, not overrides.
    if (brand.isNotEmpty) map['Brand'] = 'ChatGPT';
    if (model.isNotEmpty) map['Model'] = 'ChatGPT';
    if (serial.isNotEmpty) map['Serial'] = 'ChatGPT';
    if (barcode.isNotEmpty) {
      map['Barcode'] = barcodeApiSuccess ? 'Barcode API' : 'ChatGPT';
    }
    if (productType.isNotEmpty) map['Type'] = 'ChatGPT';
    if (manufacturer?.isNotEmpty == true) map['Manufacturer'] = 'ChatGPT';
    if (manufacturedYear?.isNotEmpty == true) map['Manufactured'] = 'ChatGPT';
    if (madeIn?.isNotEmpty == true) map['Made In'] = 'ChatGPT';
    if (productTitle != null && productTitle!.isNotEmpty) {
      map['Product'] = 'Barcode API';
    }
    if (productCategory != null && productCategory!.isNotEmpty) {
      map['Category'] = 'Barcode API';
    }
    return map;
  }
}
