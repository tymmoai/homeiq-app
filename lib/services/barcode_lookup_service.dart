import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'api_usage_tracker.dart';
import 'chatgpt_product_lookup_service.dart';

/// Model representing a product returned by the Barcode Lookup API.
class BarcodeProduct {
  final String barcode;
  final String title;
  final String brand;
  final String manufacturer;
  final String model;
  final String mpn; // Manufacturer Part Number
  final String category;
  final String description;
  final String color;
  final String size;
  final String weight;
  final List<String> images;
  final List<BarcodeProductStore> stores;

  const BarcodeProduct({
    required this.barcode,
    required this.title,
    required this.brand,
    required this.manufacturer,
    required this.model,
    required this.mpn,
    required this.category,
    required this.description,
    required this.color,
    required this.size,
    required this.weight,
    required this.images,
    required this.stores,
  });

  factory BarcodeProduct.fromJson(Map<String, dynamic> json) {
    // Parse images list — accepts both 'images' array and 'imageUrl' single string
    final imagesList = <String>[];
    if (json['images'] != null && json['images'] is List) {
      for (final img in json['images']) {
        if (img is String && img.isNotEmpty) {
          imagesList.add(img);
        }
      }
    }
    // Fallback: backend normalized format uses 'imageUrl' (single string)
    if (imagesList.isEmpty) {
      final single = json['imageUrl'] as String? ?? '';
      if (single.isNotEmpty) imagesList.add(single);
    }

    // Parse stores list
    final storesList = <BarcodeProductStore>[];
    if (json['stores'] != null && json['stores'] is List) {
      for (final store in json['stores']) {
        if (store is Map<String, dynamic>) {
          storesList.add(BarcodeProductStore.fromJson(store));
        }
      }
    }

    return BarcodeProduct(
      // Accept both 'barcode_number' (raw API) and 'barcode' (normalized backend)
      barcode: _str(json['barcode_number'] ?? json['barcode']),
      title: _str(json['title']),
      brand: _str(json['brand']),
      manufacturer: _str(json['manufacturer']),
      model: _str(json['model']),
      mpn: _str(json['mpn']),
      category: _str(json['category']),
      description: _str(json['description']),
      color: _str(json['color']),
      size: _str(json['size']),
      weight: _str(json['weight']),
      images: imagesList,
      stores: storesList,
    );
  }

  /// Best available brand name — prefers brand, falls back to manufacturer
  String get effectiveBrand {
    if (brand.isNotEmpty) return brand;
    if (manufacturer.isNotEmpty) return manufacturer;
    return '';
  }

  /// Best available model number — prefers model, falls back to mpn
  String get effectiveModel {
    if (model.isNotEmpty) return model;
    if (mpn.isNotEmpty) return mpn;
    return '';
  }

  /// First product image URL, or null
  String? get primaryImage => images.isNotEmpty ? images.first : null;

  /// Lowest US price from stores, or null
  String? get lowestUSPrice {
    final usPrices = stores
        .where((s) => s.country == 'US' && s.price.isNotEmpty)
        .map((s) => double.tryParse(s.price))
        .where((p) => p != null)
        .toList();
    if (usPrices.isEmpty) return null;
    usPrices.sort();
    return '\$${usPrices.first!.toStringAsFixed(2)}';
  }

  static String _str(dynamic val) => (val ?? '').toString().trim();
}

/// Store listing from the Barcode Lookup API response.
class BarcodeProductStore {
  final String name;
  final String country;
  final String currency;
  final String price;
  final String salePrice;
  final String link;
  final String condition;
  final String availability;

  const BarcodeProductStore({
    required this.name,
    required this.country,
    required this.currency,
    required this.price,
    required this.salePrice,
    required this.link,
    required this.condition,
    required this.availability,
  });

  factory BarcodeProductStore.fromJson(Map<String, dynamic> json) {
    return BarcodeProductStore(
      name: (json['name'] ?? '').toString().trim(),
      country: (json['country'] ?? '').toString().trim(),
      currency: (json['currency'] ?? '').toString().trim(),
      price: (json['price'] ?? '').toString().trim(),
      salePrice: (json['sale_price'] ?? '').toString().trim(),
      link: (json['link'] ?? '').toString().trim(),
      condition: (json['condition'] ?? '').toString().trim(),
      availability: (json['availability'] ?? '').toString().trim(),
    );
  }
}

/// Result type for barcode lookup operations.
class BarcodeLookupResult {
  final BarcodeProduct? product;
  final String? errorMessage;
  final bool isSuccess;

  /// Partial detection result — when API fails but we extracted useful info
  /// from the scanned value (serial number, model number, brand from URL, etc.)
  final ScannedValueInfo? partialInfo;
  final bool isPartial;

  const BarcodeLookupResult._({
    this.product,
    this.errorMessage,
    required this.isSuccess,
    this.partialInfo,
    this.isPartial = false,
  });

  factory BarcodeLookupResult.success(BarcodeProduct product) {
    return BarcodeLookupResult._(product: product, isSuccess: true);
  }

  factory BarcodeLookupResult.error(String message) {
    return BarcodeLookupResult._(errorMessage: message, isSuccess: false);
  }

  factory BarcodeLookupResult.partial(ScannedValueInfo info) {
    return BarcodeLookupResult._(
      isSuccess: false,
      isPartial: true,
      partialInfo: info,
    );
  }
}

/// Information extracted from a scanned value when the barcode API fails.
/// This handles real-world appliance labels where barcodes encode serial numbers,
/// QR codes encode manufacturer URLs, etc.
class ScannedValueInfo {
  final String rawValue;
  final ScannedValueType type;
  final String? serialNumber;
  final String? modelNumber;
  final String? brand;
  final String? url;
  final String userMessage;

  const ScannedValueInfo({
    required this.rawValue,
    required this.type,
    this.serialNumber,
    this.modelNumber,
    this.brand,
    this.url,
    required this.userMessage,
  });
}

enum ScannedValueType {
  serialNumber,
  modelNumber,
  manufacturerUrl,
  unknownCode,
}

/// Service to look up product information by barcode using barcodelookup.com API.
///
/// API key location:
///   Replace [_apiKey] below with your Barcode Lookup API key.
///   Get one at: https://www.barcodelookup.com/api
class BarcodeLookupService {
  BarcodeLookupService._();
  static final BarcodeLookupService _instance = BarcodeLookupService._();
  factory BarcodeLookupService() => _instance;

  final _usageTracker = ApiUsageTracker();
  final _apiClient = ApiClient();

  static const Duration _timeout = Duration(seconds: 15);

  /// Look up a product by its barcode number (UPC, EAN, ISBN, etc.).
  Future<BarcodeLookupResult> lookupBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) {
      return BarcodeLookupResult.error(
        'No barcode value detected. Please try again.',
      );
    }
    return _callApi({'barcode': cleanBarcode});
  }

  /// Look up a product by its MPN (Manufacturer Part Number / Model Number).
  Future<BarcodeLookupResult> lookupByMpn(
    String mpn, {
    String? manufacturer,
  }) async {
    final cleanMpn = mpn.trim();
    if (cleanMpn.isEmpty) {
      return BarcodeLookupResult.error('No model number provided.');
    }

    final params = <String, String>{'mpn': cleanMpn};
    if (manufacturer != null && manufacturer.isNotEmpty) {
      params['manufacturer'] = manufacturer;
    }
    return _callApi(params);
  }

  /// Search the Barcode Lookup API with a general search query.
  Future<BarcodeLookupResult> lookupBySearch(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return BarcodeLookupResult.error('No search query provided.');
    }

    return _callApi({'search': cleanQuery});
  }

  /// Resolve the most accurate product image using BestBuy + fallback chain.
  /// Call this after all enrichment is complete with confirmed brand + model.
  /// [assetType] is the validated, possibly auto-corrected type from Step 1
  /// (e.g. "Refrigerator") — this is the most important parameter for accuracy.
  /// Returns a map with: productImageUrl, imageSource, productName, brand, model, description, category.
  Future<Map<String, String?>> resolveProductImage({
    String? brand,
    String? model,
    String? category,
    String? productTitle,
    String? manufacturer,
    String? assetType,
    String? serial,
  }) async {
    if ((brand == null || brand.isEmpty) &&
        (model == null || model.isEmpty) &&
        (assetType == null || assetType.isEmpty) &&
        (productTitle == null || productTitle.isEmpty)) {
      debugPrint(
        '\n❌  [resolveProductImage] Skipped — no brand, model, assetType, or productTitle provided.\n',
      );
      return {};
    }

    final payload = {
      if (brand != null && brand.isNotEmpty) 'brand': brand,
      if (manufacturer != null && manufacturer.isNotEmpty)
        'manufacturer': manufacturer,
      if (model != null && model.isNotEmpty) 'model': model,
      if (category != null && category.isNotEmpty) 'category': category,
      if (productTitle != null && productTitle.isNotEmpty)
        'productTitle': productTitle,
      if (assetType != null && assetType.isNotEmpty) 'assetType': assetType,
      if (serial != null && serial.isNotEmpty) 'serial': serial,
    };

    const sep = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
    const thin =
        '──────────────────────────────────────────────────────────────';
    debugPrint('');
    debugPrint(sep);
    debugPrint('🚀  API REQUEST  →  POST /ai/resolve-product-image');
    debugPrint(thin);
    debugPrint(
      '📤  PAYLOAD  (${payload.length} field${payload.length == 1 ? '' : 's'})',
    );
    payload.forEach((k, v) => debugPrint('  ${k.padRight(15)}▸ $v'));
    debugPrint(thin);

    try {
      final response = await _apiClient.post(
        '/ai/resolve-product-image',
        body: payload,
        timeout: const Duration(seconds: 8),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = (data['data'] ?? data) as Map<String, dynamic>;
        final result = {
          'productImageUrl': content['productImageUrl']?.toString(),
          'imageSource': content['imageSource']?.toString(),
          'productName': content['productName']?.toString(),
          'brand': content['brand']?.toString(),
          'model': content['model']?.toString(),
          'description': content['description']?.toString(),
          'category': content['category']?.toString(),
        };
        final src = result['imageSource'] ?? '—';
        final imgUrl = result['productImageUrl'];
        final shortUrl = imgUrl != null && imgUrl.length > 55
            ? '${imgUrl.substring(0, 55)}…'
            : (imgUrl ?? '—');
        debugPrint(
          '📥  RESPONSE  │  HTTP ${response.statusCode}  │  source: $src',
        );
        debugPrint(
          '  ${'productName'.padRight(15)}▸ ${result['productName'] ?? '—'}',
        );
        debugPrint('  ${'imageSource'.padRight(15)}▸ $src');
        debugPrint('  ${'productImageUrl'.padRight(15)}▸ $shortUrl');
        debugPrint('  ${'brand'.padRight(15)}▸ ${result['brand'] ?? '—'}');
        debugPrint('  ${'model'.padRight(15)}▸ ${result['model'] ?? '—'}');
        debugPrint(
          '  ${'category'.padRight(15)}▸ ${result['category'] ?? '—'}',
        );
        debugPrint(
          '  ${'description'.padRight(15)}▸ ${result['description'] != null ? '(present)' : '—'}',
        );
        debugPrint(sep);
        debugPrint('');
        return result;
      } else {
        debugPrint('⚠️   RESPONSE  │  HTTP ${response.statusCode}');
        debugPrint('  body  ▸ ${response.body}');
        debugPrint(sep);
        debugPrint('');
      }
    } on Object catch (e) {
      debugPrint('🔥  ERROR  │  $e');
      debugPrint(sep);
      debugPrint('');
    }
    return {};
  }

  /// Generic API call helper via backend. Pass the search [params] (e.g., barcode, mpn, search).
  Future<BarcodeLookupResult> _callApi(Map<String, String> params) async {
    try {
      final response = await _apiClient.post(
        '/ai/barcode-lookup',
        body: params,
        timeout: _timeout,
      );

      _usageTracker.recordBarcodeApiRequest();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final content = data['data'] ?? data;

        if (content == null) {
          return BarcodeLookupResult.error('No products found.');
        }

        // The backend returns the barcodelookup.com response structure
        final products = content['products'] as List<dynamic>?;
        if (products != null && products.isNotEmpty) {
          final product = BarcodeProduct.fromJson(
            products.first as Map<String, dynamic>,
          );
          return BarcodeLookupResult.success(product);
        } else {
          return BarcodeLookupResult.error('No products found.');
        }
      } else if (response.statusCode == 404) {
        return BarcodeLookupResult.error('Product not found.');
      } else if (response.statusCode == 429) {
        return BarcodeLookupResult.error(
          'Too many requests. Please wait a moment and try again.',
        );
      } else {
        return BarcodeLookupResult.error(
          'Server error (${response.statusCode}). Please try again later.',
        );
      }
    } on Object catch (e) {
      if (e.toString().contains('TimeoutException')) {
        return BarcodeLookupResult.error(
          'Request timed out. Please check your connection and try again.',
        );
      }
      return BarcodeLookupResult.error(
        'Something went wrong. Please try again.',
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  HELPER METHODS — for Tier 0 local regex detection
  // ═══════════════════════════════════════════════════════════════════════

  bool _isUrl(String value) {
    final lower = value.toLowerCase();
    return lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.startsWith('www.');
  }

  /// Check if a value looks like a model number.
  /// Model numbers typically: have letters + numbers, may contain dashes/slashes,
  /// are 5-20 chars, and follow patterns like RF29A9071SR/AA, ME19R7041FS.
  bool _looksLikeModelNumber(String value) {
    if (value.length < 5 || value.length > 25) return false;
    // Must have both letters and numbers
    final hasLetters = RegExp(r'[A-Za-z]').hasMatch(value);
    final hasNumbers = RegExp(r'[0-9]').hasMatch(value);
    if (!hasLetters || !hasNumbers) return false;
    // Model numbers typically start with 2-3 letters followed by numbers
    // or have a structured pattern with slashes/dashes
    if (RegExp(r'^[A-Za-z]{1,4}\d{2}').hasMatch(value)) return true;
    if (value.contains('/') || value.contains('-')) return true;
    return false;
  }

  /// Try to detect brand from a model number prefix.
  /// Many manufacturers use consistent prefixes (e.g., RF=Samsung fridge, ME=Samsung microwave)
  String? _extractBrandFromModel(String value) {
    final upper = value.toUpperCase();
    // Samsung model prefixes
    if (RegExp(r'^(RF|RS|RH|RT|RB|RZ)\d').hasMatch(upper)) {
      return 'Samsung'; // Refrigerators
    }
    if (RegExp(r'^(ME|MS|MC|MW)\d').hasMatch(upper)) {
      return 'Samsung'; // Microwaves
    }
    if (RegExp(r'^(WF|WW|WD|WV)\d').hasMatch(upper)) {
      return 'Samsung'; // Washers
    }
    if (RegExp(r'^(DV|DVE|DVG)\d').hasMatch(upper)) return 'Samsung'; // Dryers
    if (RegExp(r'^(NX|NE|NA|NK)\d').hasMatch(upper)) return 'Samsung'; // Ranges
    if (RegExp(r'^(DW)\d').hasMatch(upper)) return 'Samsung'; // Dishwashers
    if (RegExp(r'^(AR|AJ|AC)\d').hasMatch(upper)) return 'Samsung'; // AC
    // LG model prefixes
    if (RegExp(r'^(LR|LF|LT|LS|LW|LD)\w{2}\d').hasMatch(upper)) return 'LG';
    if (RegExp(r'^(WM|WT|WK)\d').hasMatch(upper)) return 'LG'; // Washers
    if (RegExp(r'^(DLE|DLG|DLEX)\d').hasMatch(upper)) return 'LG'; // Dryers
    // GE model prefixes
    if (RegExp(r'^(GFE|GNE|GTE|GTW|GFW|GDT|GDF|JB|JGB)\d').hasMatch(upper)) {
      return 'GE';
    }
    // Whirlpool model prefixes
    if (RegExp(r'^(WR|WD|WT|WFW|WED|WTW)\w?\d').hasMatch(upper)) {
      return 'Whirlpool';
    }
    return null;
  }

  /// Try to detect brand from serial number format
  String? _extractBrandFromSerial(String value) {
    final upper = value.toUpperCase();
    // Samsung serial numbers: 10-20 chars, start with 0, alphanumeric
    // Examples: 0G38GDAT304495Z, 0KYR43BT500840J, 0JEE3CDW900153F
    if (value.length >= 10 &&
        value.length <= 20 &&
        upper.startsWith('0') &&
        RegExp(r'^0[A-Z0-9]{1,3}[A-Z]').hasMatch(upper)) {
      return 'Samsung';
    }
    // LG serial numbers: start with a digit followed by letters, 12-20 chars
    if (value.length >= 12 &&
        value.length <= 20 &&
        RegExp(r'^\d{3}[A-Z]{2,4}').hasMatch(upper)) {
      return 'LG';
    }
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  2-STEP ENRICHED PIPELINE
  //
  //  Step 1: ChatGPT extraction (~2-4 sec) → serial, model, barcode/UPC
  //  Step 2: Barcode API lookup using extracted identifiers:
  //          Try 1: ?barcode=UPC  (direct hit from scan or ChatGPT UPC)
  //          Try 2: ?mpn=MODEL    (model number / MPN search)
  //          Try 3: ?search=BRAND+MODEL  (general search)
  //
  //  Flow:
  //    Scan → Tier 0 (local regex) → ChatGPT extracts identifiers
  //    → Barcode API (?barcode= / ?mpn= / ?search=) → full product details
  //    → Merge identifiers + product details → DONE
  // ═══════════════════════════════════════════════════════════════════════

  final _chatGPTLookup = ChatGPTProductLookupService();

  /// Full enriched lookup pipeline.
  ///
  /// Fast path: For UPC barcodes and model numbers, try Barcode API directly
  /// using Tier 0 (local regex) analysis — no ChatGPT delay.
  ///
  /// Slow path: If fast path fails, use ChatGPT to extract identifiers,
  /// then retry Barcode API with ChatGPT-extracted data.
  ///
  /// [barcode] — raw scanned value.
  /// [assetType] — optional context from Step 1 (e.g., "Refrigerator").
  ///
  /// Returns [EnrichedScanResult] with merged data.
  Future<EnrichedScanResult> lookupWithEnrichment({
    required String barcode,
    String? assetType,
  }) async {
    final cleanValue = barcode.trim();
    if (cleanValue.isEmpty) {
      return EnrichedScanResult.error('No value detected. Please try again.');
    }

    // ── Tier 0: Local regex analysis (instant) ──
    final isLikelyUpc = _isLikelyUpc(cleanValue);
    final isUrl = _isUrl(cleanValue);
    final isModelLike = !isUrl && _looksLikeModelNumber(cleanValue);
    String? detectedBrand;
    String valueType;

    if (isLikelyUpc) {
      valueType = 'UPC/EAN barcode';
      detectedBrand = null;
    } else if (isUrl) {
      valueType = 'URL/QR code';
      detectedBrand = _extractBrandFromUrl(cleanValue);
    } else if (isModelLike) {
      valueType = 'model number';
      detectedBrand = _extractBrandFromModel(cleanValue);
    } else {
      valueType = 'serial number';
      detectedBrand = _extractBrandFromSerial(cleanValue);
    }

    BarcodeProduct? barcodeProduct;
    ChatGPTProductInfo? chatGPTProduct;

    // ══════════════════════════════════════════════════════════════
    //  FAST PATH — Direct Barcode API lookup using Tier 0 analysis
    //  No ChatGPT needed for UPC barcodes and model numbers.
    // ══════════════════════════════════════════════════════════════

    // Fast 1: Direct UPC lookup (scanned value is already a barcode)
    if (isLikelyUpc) {
      final barcodeResult = await lookupBarcode(cleanValue);
      if (barcodeResult.isSuccess && barcodeResult.product != null) {
        barcodeProduct = barcodeResult.product;
      }
    }

    // Fast 2: Model number detected by Tier 0 — try MPN + search immediately
    if (barcodeProduct == null && isModelLike) {
      // Try MPN search with raw scanned value
      final mpnResult = await lookupByMpn(
        cleanValue,
        manufacturer: detectedBrand,
      );
      if (mpnResult.isSuccess && mpnResult.product != null) {
        barcodeProduct = mpnResult.product;
      }

      // Try search: brand + model number
      if (barcodeProduct == null) {
        final searchQuery = detectedBrand != null
            ? '$detectedBrand $cleanValue'
            : cleanValue;
        final searchResult = await lookupBySearch(searchQuery);
        if (searchResult.isSuccess && searchResult.product != null) {
          barcodeProduct = searchResult.product;
        }
      }
    }

    // If fast path already found product for UPC/model, create minimal
    // ChatGPT info from Tier 0 to fill brand/model/serial fields.
    if (barcodeProduct != null && (isLikelyUpc || isModelLike)) {
      chatGPTProduct = ChatGPTProductInfo(
        brand: detectedBrand ?? barcodeProduct.effectiveBrand,
        model: isModelLike ? cleanValue : barcodeProduct.effectiveModel,
        serialNumber: '',
      );

      return EnrichedScanResult.success(
        barcodeProduct: barcodeProduct,
        chatGPTProduct: chatGPTProduct,
        scannedValue: cleanValue,
        detectedValueType: valueType,
        detectedBrand: detectedBrand,
      );
    }

    // ══════════════════════════════════════════════════════════════
    //  SLOW PATH — ChatGPT extracts identifiers, then Barcode API
    //  Used for: serial numbers, URLs, and when fast path fails.
    // ══════════════════════════════════════════════════════════════

    final chatGPTResult = await _chatGPTLookup.identifyProduct(
      scannedValue: cleanValue,
      assetType: assetType,
      detectedBrand: detectedBrand,
      valueType: valueType,
    );

    if (chatGPTResult.isSuccess) {
      chatGPTProduct = chatGPTResult.product;
      // Update brand from ChatGPT if we didn't have one
      if (detectedBrand == null && chatGPTProduct!.hasBrand) {
        detectedBrand = chatGPTProduct.brand;
      }
    }

    // Try Barcode API with ChatGPT-extracted identifiers
    // (only if fast path didn't already find a product)

    // Try: UPC extracted by ChatGPT
    if (barcodeProduct == null &&
        chatGPTProduct?.upcHint != null &&
        chatGPTProduct!.upcHint!.isNotEmpty) {
      final upcResult = await lookupBarcode(chatGPTProduct.upcHint!);
      if (upcResult.isSuccess && upcResult.product != null) {
        barcodeProduct = upcResult.product;
      }
    }

    // Try: Model number from ChatGPT as MPN search
    if (barcodeProduct == null &&
        chatGPTProduct != null &&
        chatGPTProduct.hasModel) {
      final mpnResult = await lookupByMpn(
        chatGPTProduct.model,
        manufacturer: detectedBrand ?? chatGPTProduct.brand,
      );
      if (mpnResult.isSuccess && mpnResult.product != null) {
        barcodeProduct = mpnResult.product;
      }
    }

    // Try: Broad search with best available brand + model
    if (barcodeProduct == null) {
      final searchBrand = detectedBrand ?? chatGPTProduct?.brand ?? '';
      final searchModel =
          chatGPTProduct?.model ?? (isModelLike ? cleanValue : '');
      String? searchQuery;

      if (searchBrand.isNotEmpty && searchModel.isNotEmpty) {
        searchQuery = '$searchBrand $searchModel';
      } else if (searchModel.isNotEmpty) {
        searchQuery = searchModel;
      } else if (searchBrand.isNotEmpty &&
          assetType != null &&
          assetType.isNotEmpty) {
        searchQuery = '$searchBrand $assetType';
      }

      if (searchQuery != null) {
        final searchResult = await lookupBySearch(searchQuery);
        if (searchResult.isSuccess && searchResult.product != null) {
          barcodeProduct = searchResult.product;
        }
      }
    }

    // ══════════════════════════════════════════════════════════════
    //  FALLBACK — If ChatGPT failed, use Tier 0 data for identifiers
    // ══════════════════════════════════════════════════════════════

    chatGPTProduct ??= ChatGPTProductInfo(
      brand: detectedBrand ?? '',
      model: isModelLike ? cleanValue : '',
      serialNumber: !isLikelyUpc && !isUrl && !isModelLike ? cleanValue : '',
    );

    // ── Detect generic URL (QR code with no product-specific info) ──
    final bool isGenericUrl =
        chatGPTProduct.isGenericUrl ||
        (isUrl &&
            !chatGPTProduct.hasModel &&
            !chatGPTProduct.hasSerial &&
            !chatGPTProduct.hasUpc);

    String? userGuidanceMessage;
    if (isGenericUrl) {
      userGuidanceMessage =
          chatGPTProduct.message ??
          'This QR code is a generic link — it does not contain your product\'s model number or serial number. '
              'Please scan the barcode printed near the model number on your label, or enter the model number manually.';
    }

    // ── Merge results ──
    if (barcodeProduct != null ||
        chatGPTProduct.hasBrand ||
        chatGPTProduct.hasModel ||
        chatGPTProduct.hasSerial) {
      return EnrichedScanResult.success(
        barcodeProduct: barcodeProduct,
        chatGPTProduct: chatGPTProduct,
        scannedValue: cleanValue,
        detectedValueType: valueType,
        detectedBrand: detectedBrand,
        isGenericUrl: isGenericUrl,
        userGuidanceMessage: userGuidanceMessage,
      );
    }

    // Nothing worked — return partial from Tier 0 analysis
    return EnrichedScanResult.partial(
      scannedValue: cleanValue,
      detectedValueType: valueType,
      detectedBrand: detectedBrand,
      isGenericUrl: isGenericUrl,
      userGuidanceMessage: userGuidanceMessage,
      message: isGenericUrl
          ? 'This QR code is a generic link. Please scan the barcode near the model number on your label, or enter the model number manually.'
          : 'Could not fully identify this product. '
                '${detectedBrand != null ? "Brand may be $detectedBrand. " : ""}'
                'Please enter details manually.',
    );
  }

  /// Check if a scanned value looks like a standard UPC/EAN barcode.
  /// UPC-A: 12 digits, EAN-13: 13 digits, EAN-8: 8 digits.
  bool _isLikelyUpc(String value) {
    final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');
    return digitsOnly.length == value.length &&
        (digitsOnly.length == 8 ||
            digitsOnly.length == 12 ||
            digitsOnly.length == 13 ||
            digitsOnly.length == 14);
  }

  /// Extract brand from a URL (for Tier 0 hint)
  String? _extractBrandFromUrl(String value) {
    final lower = value.toLowerCase();
    final brandDomains = {
      'samsung': 'Samsung',
      'lg': 'LG',
      'whirlpool': 'Whirlpool',
      'ge': 'GE',
      'geappliances': 'GE',
      'maytag': 'Maytag',
      'frigidaire': 'Frigidaire',
      'bosch': 'Bosch',
      'kitchenaid': 'KitchenAid',
      'kenmore': 'Kenmore',
      'electrolux': 'Electrolux',
      'sony': 'Sony',
      'panasonic': 'Panasonic',
      'toshiba': 'Toshiba',
      'honeywell': 'Honeywell',
    };
    for (final entry in brandDomains.entries) {
      if (lower.contains(entry.key)) return entry.value;
    }
    return null;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  ENRICHED SCAN RESULT — merged data from all pipeline tiers
// ═══════════════════════════════════════════════════════════════════════════

/// Combined result from the 2-step scanning pipeline.
///
/// Step 1: ChatGPT extracts identifiers (serial, model, UPC) from scanned value.
/// Step 2: Barcode API fetches full product details using extracted identifiers.
///
/// Use the convenience getters (e.g., [brand], [model]) which
/// automatically pick the best value from available sources.
/// Use [fieldSources] for debug UI showing where each field came from.
class EnrichedScanResult {
  final BarcodeProduct? barcodeProduct;
  final ChatGPTProductInfo? chatGPTProduct;
  final String scannedValue;
  final String? detectedValueType;
  final String? detectedBrand;
  final String? errorMessage;
  final bool isSuccess;
  final bool isPartialOnly;
  final bool isGenericUrl; // True if QR code was a generic marketing link
  final String?
  userGuidanceMessage; // Guidance for user (e.g., scan barcode instead)

  const EnrichedScanResult._({
    this.barcodeProduct,
    this.chatGPTProduct,
    required this.scannedValue,
    this.detectedValueType,
    this.detectedBrand,
    this.errorMessage,
    required this.isSuccess,
    this.isPartialOnly = false,
    this.isGenericUrl = false,
    this.userGuidanceMessage,
  });

  factory EnrichedScanResult.success({
    BarcodeProduct? barcodeProduct,
    ChatGPTProductInfo? chatGPTProduct,
    required String scannedValue,
    String? detectedValueType,
    String? detectedBrand,
    bool isGenericUrl = false,
    String? userGuidanceMessage,
  }) {
    return EnrichedScanResult._(
      barcodeProduct: barcodeProduct,
      chatGPTProduct: chatGPTProduct,
      scannedValue: scannedValue,
      detectedValueType: detectedValueType,
      detectedBrand: detectedBrand,
      isSuccess: true,
      isGenericUrl: isGenericUrl,
      userGuidanceMessage: userGuidanceMessage,
    );
  }

  factory EnrichedScanResult.partial({
    required String scannedValue,
    String? detectedValueType,
    String? detectedBrand,
    required String message,
    bool isGenericUrl = false,
    String? userGuidanceMessage,
  }) {
    return EnrichedScanResult._(
      scannedValue: scannedValue,
      detectedValueType: detectedValueType,
      detectedBrand: detectedBrand,
      errorMessage: message,
      isSuccess: false,
      isPartialOnly: true,
      isGenericUrl: isGenericUrl,
      userGuidanceMessage: userGuidanceMessage,
    );
  }

  factory EnrichedScanResult.error(String message) {
    return EnrichedScanResult._(
      scannedValue: '',
      errorMessage: message,
      isSuccess: false,
    );
  }

  // ── Convenience getters: best value from available sources ──
  // ChatGPT provides: identifiers (brand, model, serial, UPC, category hints)
  // Barcode API provides: full product details (title, description, specs, images, prices, stores)

  /// Source description for tracking
  String get source {
    if (barcodeProduct != null && chatGPTProduct != null) return 'merged';
    if (barcodeProduct != null) return 'barcode_api';
    if (chatGPTProduct != null) return 'chatgpt_ids';
    return 'local';
  }

  /// Brand — prefers Barcode API (exact), falls back to ChatGPT extraction
  String get brand =>
      _nonEmpty(barcodeProduct?.effectiveBrand) ??
      _nonEmpty(chatGPTProduct?.brand) ??
      detectedBrand ??
      '';

  /// Model — prefers Barcode API (exact), falls back to ChatGPT extraction
  String get model =>
      _nonEmpty(barcodeProduct?.effectiveModel) ??
      _nonEmpty(chatGPTProduct?.model) ??
      '';

  /// Product title — from Barcode API ONLY
  String get productName => _nonEmpty(barcodeProduct?.title) ?? '';

  /// Description — from Barcode API only
  String get description => _nonEmpty(barcodeProduct?.description) ?? '';

  /// Category — from Barcode API ONLY
  String get category => _nonEmpty(barcodeProduct?.category) ?? '';

  /// Sub-category — from Barcode API ONLY (not from ChatGPT)
  String get subCategory => '';

  /// Product image — from Barcode API only (real photos)
  String? get productImage => barcodeProduct?.primaryImage;

  /// Barcode (UPC/EAN) — prefers Barcode API, falls back to ChatGPT extraction
  String get barcode =>
      _nonEmpty(barcodeProduct?.barcode) ??
      _nonEmpty(chatGPTProduct?.upcHint) ??
      '';

  /// Serial number — from ChatGPT extraction (identifier)
  String get serialNumber => chatGPTProduct?.serialNumber ?? '';

  /// Manufacturer — from Barcode API ONLY
  String get manufacturer => _nonEmpty(barcodeProduct?.manufacturer) ?? '';

  /// MPN — from Barcode API only
  String get mpn => barcodeProduct?.mpn ?? '';

  /// Color — from Barcode API only
  String get color => barcodeProduct?.color ?? '';

  /// Store listings — from Barcode API only
  List<BarcodeProductStore> get stores => barcodeProduct?.stores ?? [];

  /// Support URL — not available without ChatGPT product lookup (removed)
  String get supportUrl => '';

  /// Manual URL — not available without ChatGPT product lookup (removed)
  String get manualUrl => '';

  /// Key specs — not available (Barcode API doesn't provide structured specs)
  Map<String, String> get specs => {};

  /// Warranty details — not available from barcode API
  Map<String, String> get warrantyInfo => {};

  // ── Per-field source tracking (for debug UI) ──

  /// Returns a map of field name → { value, source } for every populated field.
  /// This lets the UI show exactly where each piece of data came from.
  Map<String, Map<String, String>> get fieldSources {
    final map = <String, Map<String, String>>{};

    void add(String field, String value, String src) {
      if (value.isNotEmpty) map[field] = {'value': value, 'source': src};
    }

    // --- ChatGPT extracted identifiers ---
    if (chatGPTProduct != null) {
      add('Serial Number (extracted)', chatGPTProduct!.serialNumber, 'ChatGPT');
      add('Model (extracted)', chatGPTProduct!.model, 'ChatGPT');
      add('Brand (extracted)', chatGPTProduct!.brand, 'ChatGPT');
      add('UPC Hint (extracted)', chatGPTProduct!.upcHint ?? '', 'ChatGPT');
      add('Category Hint', chatGPTProduct!.category ?? '', 'ChatGPT');
      add('Sub-Category Hint', chatGPTProduct!.subCategory ?? '', 'ChatGPT');
    }

    // --- Barcode API product details ---
    if (barcodeProduct != null) {
      add('Brand (product)', barcodeProduct!.brand, 'Barcode API');
      add('Model (product)', barcodeProduct!.model, 'Barcode API');
      add('Product Title', barcodeProduct!.title, 'Barcode API');
      add('Description', barcodeProduct!.description, 'Barcode API');
      add('Manufacturer', barcodeProduct!.manufacturer, 'Barcode API');
      add('MPN', barcodeProduct!.mpn, 'Barcode API');
      add('Category (product)', barcodeProduct!.category, 'Barcode API');
      add('Color', barcodeProduct!.color, 'Barcode API');
      add('Barcode/UPC', barcodeProduct!.barcode, 'Barcode API');
      add('Image', barcodeProduct!.primaryImage ?? '', 'Barcode API');
      add('Stores', '${barcodeProduct!.stores.length} listings', 'Barcode API');
    }

    // --- Tier 0 local regex ---
    if (detectedBrand != null && detectedBrand!.isNotEmpty) {
      add('Brand (regex)', detectedBrand!, 'Local Regex');
    }
    if (detectedValueType != null) {
      add('Detected Type', detectedValueType!, 'Local Regex');
    }
    add('Raw Scanned Value', scannedValue, 'Scanner');

    return map;
  }

  String? _nonEmpty(String? val) => val != null && val.isNotEmpty ? val : null;
}
