import 'dart:convert';

import '../models/api_models.dart';
import 'api_client.dart';

/// Thrown by [AssetApiService.createAsset] when the backend returns 409
/// because an asset with the same identifying fields already exists.
class DuplicateAssetException implements Exception {
  final AssetDto existingAsset;
  const DuplicateAssetException(this.existingAsset);

  @override
  String toString() => 'DuplicateAssetException: ${existingAsset.name}';
}

/// Service for Asset CRUD operations against backend-client `/api/v1/assets`.
class AssetApiService {
  AssetApiService._();
  static final AssetApiService instance = AssetApiService._();

  final _api = ApiClient();

  /// Fetch all assets for a given home.
  Future<List<AssetDto>> getAssets({required String homeId}) async {
    final response = await _api.get(
      '/assets',
      queryParameters: {'homeId': homeId},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data
        .map((a) => AssetDto.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  /// Get a single asset by ID.
  Future<AssetDto> getAsset(String id) async {
    final response = await _api.get('/assets/$id');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AssetDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Create a new asset with full enriched data from the add-asset flow.
  Future<AssetDto> createAsset({
    required String homeId,
    required String name,
    required String category,
    String? brand,
    String? model,
    String? serialNumber,
    DateTime? purchasedAt,
    DateTime? warrantyExpiresAt,
    String? imageUrl,
    String? notes,
    // Enriched fields
    String? productTitle,
    String? productDescription,
    String? productCategory,
    String? subCategory,
    String? manufacturer,
    String? mpn,
    String? barcode,
    String? productImageUrl,
    String? productColor,
    String? enrichmentSource,
    String? location,
    int? purchaseYear,
    int? purchaseMonth,
    // WiFi / network fields
    String? networkMac,
    String? networkIp,
  }) async {
    final response = await _api.post(
      '/assets',
      body: {
        'homeId': homeId,
        'name': name,
        'category': category,
        'brand': ?brand,
        'model': ?model,
        'serialNumber': ?serialNumber,
        if (purchasedAt != null) 'purchasedAt': purchasedAt.toIso8601String(),
        if (warrantyExpiresAt != null)
          'warrantyExpiresAt': warrantyExpiresAt.toIso8601String(),
        'imageUrl': ?imageUrl,
        'notes': ?notes,
        'productTitle': ?productTitle,
        'productDescription': ?productDescription,
        'productCategory': ?productCategory,
        'subCategory': ?subCategory,
        'manufacturer': ?manufacturer,
        'mpn': ?mpn,
        'barcode': ?barcode,
        'productImageUrl': ?productImageUrl,
        'productColor': ?productColor,
        'enrichmentSource': ?enrichmentSource,
        'location': ?location,
        'purchaseYear': ?purchaseYear,
        'purchaseMonth': ?purchaseMonth,
        'networkMac': ?networkMac,
        'networkIp': ?networkIp,
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    // 409 means the backend detected a duplicate
    if (response.statusCode == 409) {
      throw DuplicateAssetException(
        AssetDto.fromJson(body['data'] as Map<String, dynamic>),
      );
    }
    return AssetDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Update an existing asset.
  Future<AssetDto> updateAsset(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/assets/$id', body: data);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return AssetDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Delete an asset.
  Future<void> deleteAsset(String id) async {
    await _api.delete('/assets/$id');
  }

  // ── Issues ───────────────────────────────────────────────────────────────

  /// Fetch all issues for a specific asset.
  Future<List<Map<String, dynamic>>> getAssetIssues(String assetId) async {
    final response = await _api.get(
      '/issues',
      queryParameters: {'assetId': assetId},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Report a new issue on an asset.
  Future<Map<String, dynamic>> createIssue({
    required String homeId,
    required String assetId,
    required String title,
    String? description,
    String severity = 'medium',
  }) async {
    final response = await _api.post(
      '/issues',
      body: {
        'homeId': homeId,
        'assetId': assetId,
        'title': title,
        'description': ?description,
        'severity': severity,
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  // ── Documents ────────────────────────────────────────────────────────────

  /// Fetch all documents for a specific asset.
  Future<List<Map<String, dynamic>>> getDocuments(String assetId) async {
    final response = await _api.get('/assets/$assetId/documents');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Record a document against an asset.
  ///
  /// [name] is the filename (e.g. "warranty.pdf").
  /// [type] is one of: warranty | manual | receipt | photo | other.
  /// [url] is optional — set once the file has been uploaded to cloud storage.
  /// [mimeType] and [sizeBytes] are optional metadata read from the device file.
  Future<Map<String, dynamic>> addDocument({
    required String assetId,
    required String name,
    String type = 'other',
    String? url,
    String? mimeType,
    int? sizeBytes,
  }) async {
    final response = await _api.post(
      '/assets/$assetId/documents',
      body: {
        'name': name,
        'type': type,
        'url': ?url,
        'mimeType': ?mimeType,
        'sizeBytes': ?sizeBytes,
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  /// Update the cloud URL of a document once it has been uploaded to storage.
  Future<Map<String, dynamic>> updateDocumentUrl(
    String assetId,
    String docId,
    String url,
  ) async {
    final response = await _api.patch(
      '/assets/$assetId/documents/$docId',
      body: {'url': url},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  /// Delete a document record.
  Future<void> deleteDocument(String assetId, String docId) async {
    await _api.delete('/assets/$assetId/documents/$docId');
  }

  // ── Service History ──────────────────────────────────────────────────────

  /// Fetch service (maintenance) history for a specific asset.
  Future<List<Map<String, dynamic>>> getServiceHistory(String assetId) async {
    final response = await _api.get('/assets/$assetId/service-history');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }

  /// Add a service record to an asset.
  Future<Map<String, dynamic>> addServiceRecord({
    required String assetId,
    required String title,
    required DateTime performedAt,
    String? description,
    DateTime? nextDueAt,
    double? cost,
  }) async {
    final response = await _api.post(
      '/assets/$assetId/service-history',
      body: {
        'title': title,
        'performedAt': performedAt.toIso8601String(),
        'description': ?description,
        if (nextDueAt != null) 'nextDueAt': nextDueAt.toIso8601String(),
        'cost': ?cost,
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['data'] as Map<String, dynamic>;
  }

  // ── Maintenance (Home-level) ─────────────────────────────────────────────

  /// Fetch all maintenance records for a home (all assets).
  Future<List<Map<String, dynamic>>> getMaintenanceRecords({
    required String homeId,
  }) async {
    final response = await _api.get(
      '/maintenance',
      queryParameters: {'homeId': homeId},
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data.cast<Map<String, dynamic>>();
  }
}
