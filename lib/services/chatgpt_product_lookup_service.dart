import 'dart:convert';
import '../core/utils/logger.dart';
import 'api_client.dart';
import 'api_usage_tracker.dart';

/// Extracted identification data returned by ChatGPT.
///
/// ChatGPT's ONLY job is to extract identifiers from a scanned value:
///   - Serial number
///   - Model number
///   - Barcode / UPC / EAN
///   - Brand (if detectable from the value)
///
/// The Barcode Lookup API then uses these identifiers to fetch
/// full product details (specs, warranty, price, images, etc.).
class ChatGPTProductInfo {
  final String brand;
  final String model;
  final String serialNumber;
  final String? upcHint; // UPC/EAN if ChatGPT can determine it
  final String? productName; // Brief name only for context, not authoritative
  final String? category; // High-level category hint (Appliances, Electronics)
  final String? subCategory; // Sub-category hint
  final bool isGenericUrl; // True if QR code was a generic marketing link
  final String? message; // Message from ChatGPT (e.g., guidance when generic URL)

  const ChatGPTProductInfo({
    required this.brand,
    required this.model,
    required this.serialNumber,
    this.upcHint,
    this.productName,
    this.category,
    this.subCategory,
    this.isGenericUrl = false,
    this.message,
  });

  factory ChatGPTProductInfo.fromJson(Map<String, dynamic> json) {
    // Validate UPC — only accept if it's purely numeric and correct length
    String? upc;
    final rawUpc = (json['upc'] ?? '').toString().trim();
    if (rawUpc.isNotEmpty) {
      final digitsOnly = rawUpc.replaceAll(RegExp(r'[^0-9]'), '');
      // Only accept if it's 8, 12, 13, or 14 digits (valid UPC/EAN lengths)
      if (digitsOnly.length == rawUpc.length &&
          (digitsOnly.length == 8 ||
              digitsOnly.length == 12 ||
              digitsOnly.length == 13 ||
              digitsOnly.length == 14)) {
        upc = digitsOnly;
      }
    }

    return ChatGPTProductInfo(
      brand: _str(json['brand']),
      model: _str(json['model']),
      serialNumber: _str(json['serialNumber']),
      upcHint: upc,
      productName: _nullableStr(json['productName']),
      category: _nullableStr(json['category']),
      subCategory: _nullableStr(json['subCategory']),
      isGenericUrl: json['isGenericUrl'] == true,
      message: _nullableStr(json['message']),
    );
  }

  static String _str(dynamic val) {
    final s = (val ?? '').toString().trim();
    // ChatGPT sometimes returns "Unknown" or "N/A" — treat as empty
    if (s.toLowerCase() == 'unknown' || s.toLowerCase() == 'n/a' || s == '-') {
      return '';
    }
    return s;
  }

  static String? _nullableStr(dynamic val) {
    final s = (val ?? '').toString().trim();
    if (s.isEmpty || s.toLowerCase() == 'unknown' || s.toLowerCase() == 'n/a' || s == '-') {
      return null;
    }
    return s;
  }

  bool get hasBrand => brand.isNotEmpty;
  bool get hasModel => model.isNotEmpty;
  bool get hasSerial => serialNumber.isNotEmpty;
  bool get hasUpc => upcHint != null && upcHint!.isNotEmpty;
}

/// Result wrapper for ChatGPT product lookup.
class ChatGPTProductResult {
  final ChatGPTProductInfo? product;
  final String? errorMessage;
  final bool isSuccess;

  const ChatGPTProductResult._({
    this.product,
    this.errorMessage,
    required this.isSuccess,
  });

  factory ChatGPTProductResult.success(ChatGPTProductInfo product) {
    return ChatGPTProductResult._(product: product, isSuccess: true);
  }

  factory ChatGPTProductResult.error(String message) {
    return ChatGPTProductResult._(errorMessage: message, isSuccess: false);
  }
}

/// Service that uses ChatGPT to identify products from scanned values
/// (serial numbers, model numbers, URLs, barcodes) and return rich
/// product data including specs, warranty, and support information.
///
/// This is Tier 2 in the scanning pipeline:
///   Tier 0: Local regex → Tier 1: Barcode API → **Tier 2: ChatGPT** → Tier 3: Barcode API w/ UPC hint
class ChatGPTProductLookupService {
  static final ChatGPTProductLookupService _instance =
      ChatGPTProductLookupService._internal();
  factory ChatGPTProductLookupService() => _instance;
  ChatGPTProductLookupService._internal();

  final _usageTracker = ApiUsageTracker();
  final _apiClient = ApiClient();

  static const Duration _timeout = Duration(seconds: 25);

  /// Identify a product from a scanned value via backend AI endpoint.
  ///
  /// [scannedValue] — the raw barcode/serial/model/URL from the scanner.
  /// [assetType] — optional context from Step 1 (e.g., "Refrigerator").
  /// [detectedBrand] — optional brand hint from Tier 0 local regex.
  /// [valueType] — what Tier 0 detected this as ("serial", "model", "url", "upc").
  Future<ChatGPTProductResult> identifyProduct({
    required String scannedValue,
    String? assetType,
    String? detectedBrand,
    String? valueType,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/identify-product',
        body: {
          'scannedValue': scannedValue,
          'assetType': ?assetType,
          'detectedBrand': ?detectedBrand,
          'valueType': ?valueType,
        },
        timeout: _timeout,
      );

      _usageTracker.recordOpenAiRequest();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final content = data['data'] ?? data;

        // Check if backend could identify the product
        if (content['identified'] == false) {
          final msg = content['message'] as String? ??
              'Could not identify this product. Please enter details manually.';
          return ChatGPTProductResult.error(msg);
        }

        final product = ChatGPTProductInfo.fromJson(content);

        // Verify we got at least brand or model
        if (!product.hasBrand && !product.hasModel) {
          return ChatGPTProductResult.error(
            'Could not determine product details. Please enter them manually.',
          );
        }

        return ChatGPTProductResult.success(product);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return ChatGPTProductResult.error(
          'AI service authentication error. Please try again later.',
        );
      } else if (response.statusCode == 429) {
        return ChatGPTProductResult.error(
          'AI service is busy. Please try again in a moment.',
        );
      } else {
        AppLogger.error(
          'Product lookup error: ${response.statusCode} - ${response.body}',
          tag: 'ChatGPT-Lookup',
        );
        return ChatGPTProductResult.error(
          'AI service error. Please try again.',
        );
      }
    } on Object catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return ChatGPTProductResult.error(
          'AI lookup timed out. Please try again.',
        );
      }
      AppLogger.error(
        'ChatGPT lookup exception: $e',
        tag: 'ChatGPT-Lookup',
        error: e,
      );
      return ChatGPTProductResult.error(
        'Something went wrong. Please try again.',
      );
    }
  }

}
