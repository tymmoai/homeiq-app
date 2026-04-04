import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';
import '../features/claims/models/claim_model.dart';
import 'api_client.dart';

/// Centralized Claims Service for managing warranty/replacement claims.
/// Primary source: backend API (/api/v1/warranty/claims/all).
/// Falls back to SharedPreferences cache when offline.
class ClaimsService {
  static const String _claimsKey = 'user_claims';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Generate a unique claim number
  static String generateClaimNumber() {
    final now = DateTime.now();
    final random = now.millisecondsSinceEpoch % 10000;
    return 'CLM-${now.year}-${random.toString().padLeft(4, '0')}';
  }

  /// Save a new replacement claim — sends to backend API
  static Future<Claim> saveReplacementClaim({
    required String assetName,
    required String assetId,
    String assetBrand = '',
    String assetLocation = '',
    String assetType = '',
    String description = '',
  }) async {
    final now = DateTime.now();
    final claimNumber = generateClaimNumber();

    // Try to create via backend
    try {
      // To file a claim via backend, we need a warrantyPlanId
      // For now create the claim locally and sync
      final api = ApiClient();
      final prefs = await _preferences;
      final homeId = prefs.getString('selected_home_id') ?? '';

      // Find a warranty plan for this home to file against
      final plansResponse = await api.get(
        '/warranty',
        queryParameters: {'homeId': homeId},
      );
      final plansData = jsonDecode(plansResponse.body) as Map<String, dynamic>;
      if (plansData['success'] == true &&
          (plansData['data'] as List).isNotEmpty) {
        final planId = plansData['data'][0]['id'];
        final claimResponse = await api.post(
          '/warranty/$planId/claim',
          body: {
            'assetId': assetId,
            'title': 'Replacement claim for $assetName',
            'description': description.isNotEmpty
                ? description
                : 'Replacement claim submitted for $assetName.',
            'incidentDate': now.toIso8601String(),
          },
        );
        final claimData = jsonDecode(claimResponse.body) as Map<String, dynamic>;
        if (claimData['success'] == true && claimData['data'] != null) {
          AppLogger.info(
            'ClaimsService: Claim created on backend: ${claimData['data']['claimNumber']}',
            tag: 'ClaimsService',
          );
          return _fromBackendJson(claimData['data']);
        }
      }
    } on Object catch (e) {
      AppLogger.warning(
        'ClaimsService: Backend create failed, saving locally: $e',
        tag: 'ClaimsService',
      );
    }

    // Fallback: save locally
    final claim = Claim(
      id: 'claim_${now.millisecondsSinceEpoch}',
      claimNumber: claimNumber,
      assetId: assetId,
      assetName: assetName,
      assetBrand: assetBrand,
      assetLocation: assetLocation,
      assetType: assetType,
      title: 'Replacement claim for $assetName',
      description: description.isNotEmpty
          ? description
          : 'Replacement claim submitted for $assetName.',
      issueCategory: 'Replacement',
      claimType: ClaimType.replacement,
      status: ClaimStatus.submitted,
      warrantyStatus: 'Under Review',
      isCovered: true,
      submittedAt: now,
    );

    await _addClaimLocal(claim);
    return claim;
  }

  /// Save a generic claim
  static Future<Claim> saveClaim(Claim claim) async {
    await _addClaimLocal(claim);
    return claim;
  }

  /// Internal: persist a claim locally
  static Future<void> _addClaimLocal(Claim claim) async {
    try {
      final prefs = await _preferences;
      final claimsJson = prefs.getString(_claimsKey) ?? '[]';
      final List<dynamic> claims = jsonDecode(claimsJson) as List<dynamic>;

      if (claims.any((c) => c['claimNumber'] == claim.claimNumber)) return;

      claims.insert(0, claim.toJson());
      await prefs.setString(_claimsKey, jsonEncode(claims));
    } on Object catch (e) {
      AppLogger.error(
        'ClaimsService: Error saving claim locally: $e',
        tag: 'ClaimsService',
        error: e,
      );
    }
  }

  /// Parse a backend WarrantyClaim JSON into app Claim model
  static Claim _fromBackendJson(Map<String, dynamic> json) {
    // Map backend status string to ClaimStatus enum
    ClaimStatus status;
    switch ((json['status'] as Object?)?.toString().toLowerCase()) {
      case 'submitted':
        status = ClaimStatus.submitted;
        break;
      case 'under_review':
      case 'underreview':
        status = ClaimStatus.underReview;
        break;
      case 'approved':
        status = ClaimStatus.approved;
        break;
      case 'in_progress':
      case 'inprogress':
        status = ClaimStatus.inProgress;
        break;
      case 'resolved':
        status = ClaimStatus.resolved;
        break;
      case 'denied':
        status = ClaimStatus.denied;
        break;
      case 'closed':
        status = ClaimStatus.closed;
        break;
      default:
        status = ClaimStatus.submitted;
    }

    // Extract asset info from included relation
    final asset = json['asset'] as Map<String, dynamic>?;
    final plan = json['plan'] as Map<String, dynamic>?;

    return Claim(
      id: json['id'] ?? '',
      claimNumber: json['claimNumber'] ?? '',
      assetId: json['assetId'] ?? '',
      assetName: asset?['name'] ?? '',
      assetBrand: asset?['brand'] ?? '',
      assetLocation: asset?['location'] ?? '',
      assetType: asset?['category'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      issueCategory: json['title'] ?? '',
      claimType: ClaimType.repair,
      status: status,
      warrantyStatus: plan != null ? 'Covered' : 'Unknown',
      planName: plan?['planName'],
      isCovered: plan != null,
      submittedAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      resolvedAt: json['updatedAt'] != null && status == ClaimStatus.resolved
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      resolutionNotes: json['resolutionNote'],
    );
  }

  /// Get all claims — backend first, local cache fallback
  static Future<List<Claim>> getAllClaims() async {
    try {
      final api = ApiClient();
      final prefs = await _preferences;
      final homeId = prefs.getString('selected_home_id');
      final queryParams = <String, String>{};
      if (homeId != null && homeId.isNotEmpty) {
        queryParams['homeId'] = homeId;
      }
      final response = await api.get(
        '/warranty/claims/all',
        queryParameters: queryParams,
      );
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['success'] == true && data['data'] is List) {
        final List<dynamic> claimsList = data['data'];
        final results = <Claim>[];
        for (final json in claimsList) {
          try {
            results.add(_fromBackendJson(json as Map<String, dynamic>));
          } on Object catch (e) {
            AppLogger.warning(
              'ClaimsService: Skipping bad backend claim: $e',
              tag: 'ClaimsService',
            );
          }
        }
        // Also include any local-only claims (user-created that haven't synced)
        final localClaims = await _getLocalClaims();
        for (final local in localClaims) {
          if (!results.any((r) => r.claimNumber == local.claimNumber)) {
            results.add(local);
          }
        }
        AppLogger.info(
          'ClaimsService: Loaded ${results.length} claims (${claimsList.length} backend + local)',
          tag: 'ClaimsService',
        );
        return results;
      }
    } on Object catch (e) {
      AppLogger.warning(
        'ClaimsService: Backend fetch failed, using local cache: $e',
        tag: 'ClaimsService',
      );
    }
    // Fallback to local cache
    return _getLocalClaims();
  }

  /// Get only local claims from SharedPreferences
  static Future<List<Claim>> _getLocalClaims() async {
    try {
      final prefs = await _preferences;
      final claimsJson = prefs.getString(_claimsKey) ?? '[]';
      final List<dynamic> claimsList = jsonDecode(claimsJson) as List<dynamic>;
      final List<Claim> results = [];
      for (final json in claimsList) {
        try {
          results.add(Claim.fromJson(json as Map<String, dynamic>));
        } on Object catch (e) {
          AppLogger.warning(
            'ClaimsService: Skipping bad local claim: $e',
            tag: 'ClaimsService',
            error: e,
          );
        }
      }
      return results;
    } on Object catch (e) {
      AppLogger.error(
        'ClaimsService: Error loading local claims: $e',
        tag: 'ClaimsService',
        error: e,
      );
      return [];
    }
  }

  /// Get active claims
  Future<List<Claim>> getActiveClaims() async {
    final all = await getAllClaims();
    return all
        .where(
          (c) => [
            ClaimStatus.submitted,
            ClaimStatus.underReview,
            ClaimStatus.approved,
            ClaimStatus.inProgress,
          ].contains(c.status),
        )
        .toList();
  }

  /// Get resolved claims
  Future<List<Claim>> getResolvedClaims() async {
    final all = await getAllClaims();
    return all
        .where(
          (c) => [ClaimStatus.resolved, ClaimStatus.closed].contains(c.status),
        )
        .toList();
  }

  /// Get denied claims
  Future<List<Claim>> getDeniedClaims() async {
    final all = await getAllClaims();
    return all.where((c) => c.status == ClaimStatus.denied).toList();
  }

  /// Clear user claims (for testing)
  Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_claimsKey);
  }
}
