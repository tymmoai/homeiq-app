import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_strings.dart';
import '../core/utils/logger.dart';
import 'api_client.dart';

/// Service to persist and query purchased protection plans.
/// Stores plan data in SharedPreferences keyed by asset ID so that
/// the warranty / protection section can reflect the active plan
/// across the entire app without any centralized state management.
class ProtectionPlanService {
  static const String _plansKey = 'active_protection_plans';
  static SharedPreferences? _prefs;

  static Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save an active protection plan for an asset.
  static Future<void> saveActivePlan({
    required String assetId,
    required String planName,
    required String billingPeriod, // 'monthly', 'yearly', 'one-time'
    required double price,
    required String priceLabel,
    required DateTime coverageStart,
    required DateTime coverageEnd,
    String? deductible,
    String? provider,
    List<String>? features,
  }) async {
    try {
      final prefs = await _preferences;
      final plansJson = prefs.getString(_plansKey) ?? '{}';
      final Map<String, dynamic> plans = jsonDecode(plansJson) as Map<String, dynamic>;

      plans[assetId] = {
        'assetId': assetId,
        'planName': planName,
        'billingPeriod': billingPeriod,
        'price': price,
        'priceLabel': priceLabel,
        'coverageStart': coverageStart.toIso8601String(),
        'coverageEnd': coverageEnd.toIso8601String(),
        'deductible': deductible,
        'provider': provider ?? AppStrings.appName,
        'features': features ?? [],
        'purchasedAt': DateTime.now().toIso8601String(),
        'isActive': true,
      };

      await prefs.setString(_plansKey, jsonEncode(plans));
      AppLogger.info('ProtectionPlanService: Saved plan "$planName" for asset $assetId', tag: 'ProtectionPlan');

      // Fire-and-forget: sync to backend (non-fatal)
      unawaited(_syncActivePlanToBackend(
        assetId: assetId,
        planName: planName,
        billingPeriod: billingPeriod,
        price: price,
        priceLabel: priceLabel,
        coverageStart: coverageStart,
        coverageEnd: coverageEnd,
        deductible: deductible,
        provider: provider ?? AppStrings.appName,
        features: features ?? [],
      ));
    } on Object catch (e) {
      AppLogger.error('ProtectionPlanService: Error saving plan: $e', tag: 'ProtectionPlan', error: e);
    }
  }

  /// Get the active protection plan for an asset. Returns null if none exists.
  static Future<Map<String, dynamic>?> getActivePlan(String assetId) async {
    try {
      final prefs = await _preferences;
      final plansJson = prefs.getString(_plansKey) ?? '{}';
      final Map<String, dynamic> plans = jsonDecode(plansJson) as Map<String, dynamic>;

      if (plans.containsKey(assetId)) {
        final plan = plans[assetId] as Map<String, dynamic>;
        // Check if the plan is still active (not past coverage end date)
        final coverageEnd = DateTime.parse(plan['coverageEnd'] as String);
        if (coverageEnd.isAfter(DateTime.now()) && plan['isActive'] == true) {
          return plan;
        }
      }

      // SharedPreferences miss — fall back to backend (covers reinstall / new device)
      return _fetchPlanFromBackend(assetId);
    } on Object catch (e) {
      AppLogger.error('ProtectionPlanService: Error getting plan: $e', tag: 'ProtectionPlan', error: e);
      return null;
    }
  }

  /// Fetches the active protection plan for [assetId] directly from the
  /// backend (`GET /protection-plans?assetId=...`).
  ///
  /// Used as a fallback when the local SharedPreferences cache is empty
  /// (e.g. after a fresh install or sign-in on a new device).
  /// Returns `null` on a network error or when no plan exists.
  static Future<Map<String, dynamic>?> _fetchPlanFromBackend(
    String assetId,
  ) async {
    try {
      final api = ApiClient();
      final response = await api.get('/protection-plans?assetId=$assetId');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataRaw = body['data'];

      // Accept either a single object or a list; take the first active entry.
      Map<String, dynamic>? planData;
      if (dataRaw is List && dataRaw.isNotEmpty) {
        planData = dataRaw.first as Map<String, dynamic>?;
      } else if (dataRaw is Map<String, dynamic>) {
        planData = dataRaw;
      }

      if (planData == null) return null;

      // Normalise backend field names to the local schema used by the rest
      // of the app (SharedPreferences format).
      final coverageEndRaw = planData['coverageEnd']?.toString() ?? '';
      if (coverageEndRaw.isEmpty) return null;
      final coverageEnd = DateTime.tryParse(coverageEndRaw);
      if (coverageEnd == null || !coverageEnd.isAfter(DateTime.now())) {
        return null; // plan expired
      }

      final normalised = <String, dynamic>{
        'assetId': assetId,
        'planName': planData['planName']?.toString() ?? '',
        'billingPeriod': planData['billingPeriod']?.toString() ?? 'one-time',
        'price': (planData['price'] as num?)?.toDouble() ?? 0.0,
        'priceLabel': planData['priceLabel']?.toString() ?? '',
        'coverageStart':
            planData['coverageStart']?.toString() ?? coverageEndRaw,
        'coverageEnd': coverageEndRaw,
        'deductible': planData['deductible']?.toString(),
        'provider': planData['provider']?.toString() ?? AppStrings.appName,
        'features': (planData['features'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            <String>[],
        'purchasedAt':
            planData['createdAt']?.toString() ?? DateTime.now().toIso8601String(),
        'isActive': true,
      };

      // Persist to local cache so subsequent reads are instant.
      final prefs = await _preferences;
      final plansJson = prefs.getString(_plansKey) ?? '{}';
      final Map<String, dynamic> plans = jsonDecode(plansJson) as Map<String, dynamic>;
      plans[assetId] = normalised;
      await prefs.setString(_plansKey, jsonEncode(plans));

      AppLogger.info(
        'ProtectionPlanService: Fetched plan from backend for $assetId',
        tag: 'ProtectionPlan',
      );
      return normalised;
    } on Object catch (e) {
      AppLogger.warning(
        'ProtectionPlanService: Backend fallback failed (non-fatal): $e',
        tag: 'ProtectionPlan',
      );
      return null;
    }
  }

  /// Check if an asset has an active protection plan.
  static Future<bool> hasActivePlan(String assetId) async {
    final plan = await getActivePlan(assetId);
    return plan != null;
  }

  /// Update the asset map in-place with the active protection plan data.
  /// This mutates the passed map so all references to it reflect the change.
  static Future<bool> applyPlanToAsset(Map<String, dynamic> asset) async {
    final assetId = asset['id']?.toString() ?? '';
    if (assetId.isEmpty) return false;

    final plan = await getActivePlan(assetId);
    if (plan == null) return false;

    // Update asset warranty fields to reflect the active protection plan
    asset['warranty'] = 'Active';
    asset['warrantyEndDate'] = plan['coverageEnd'];
    asset['protectionPlan'] = plan['planName'];
    asset['protectionPlanBillingPeriod'] = plan['billingPeriod'];
    asset['protectionPlanPrice'] = plan['priceLabel'];
    asset['protectionPlanProvider'] = plan['provider'];
    asset['hasActiveProtectionPlan'] = true;

    return true;
  }

  /// Remove a protection plan for an asset (e.g., cancellation).
  static Future<void> removePlan(String assetId) async {
    try {
      final prefs = await _preferences;
      final plansJson = prefs.getString(_plansKey) ?? '{}';
      final Map<String, dynamic> plans = jsonDecode(plansJson) as Map<String, dynamic>;
      plans.remove(assetId);
      await prefs.setString(_plansKey, jsonEncode(plans));
      AppLogger.info('ProtectionPlanService: Removed plan for asset $assetId', tag: 'ProtectionPlan');
    } on Object catch (e) {
      AppLogger.error('ProtectionPlanService: Error removing plan: $e', tag: 'ProtectionPlan', error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // Backend sync (fire-and-forget, non-fatal)
  // ---------------------------------------------------------------------------

  static Future<void> _syncActivePlanToBackend({
    required String assetId,
    required String planName,
    required String billingPeriod,
    required double price,
    required String priceLabel,
    required DateTime coverageStart,
    required DateTime coverageEnd,
    String? deductible,
    required String provider,
    required List<String> features,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final homeId = prefs.getString('selected_home_id');
      if (homeId == null || homeId.isEmpty) return;

      final api = ApiClient();
      await api.post('/protection-plans', body: {
        'homeId': homeId,
        'assetId': assetId,
        'planName': planName,
        'provider': provider,
        'billingPeriod': billingPeriod,
        'price': price,
        'priceLabel': priceLabel,
        'deductible': deductible,
        'features': features,
        'coverageStart': coverageStart.toIso8601String(),
        'coverageEnd': coverageEnd.toIso8601String(),
      });
      AppLogger.info('ProtectionPlanService: Synced plan "$planName" to backend', tag: 'ProtectionPlan');
    } on Object catch (e) {
      AppLogger.warning('ProtectionPlanService: Backend sync failed (non-fatal): $e', tag: 'ProtectionPlan');
    }
  }

  /// Clear all plans (for testing).
  static Future<void> clearAll() async {
    final prefs = await _preferences;
    await prefs.remove(_plansKey);
  }
}
