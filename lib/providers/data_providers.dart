import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/api_models.dart';
import '../models/family_models.dart';
import '../services/asset_api_service.dart';
import '../services/family_api_service.dart';
import '../services/home_api_service.dart';
import 'home_selection_provider.dart';

// ─── Homes ───────────────────────────────────────────────────────────────────

/// Fetches the user's homes from the backend.
/// Automatically refreshes when invalidated.
final homesProvider = FutureProvider<List<HomeDto>>((ref) async {
  try {
    return await HomeApiService.instance.getHomes();
  } on Object catch (e) {
    debugPrint('[homesProvider] Failed to fetch homes: $e');
    return [];
  }
});

// ─── Assets ──────────────────────────────────────────────────────────────────

/// Fetches assets for the currently selected home.
/// Re-fetches whenever the selected home changes.
final assetsProvider = FutureProvider<List<AssetDto>>((ref) async {
  final homeState = ref.watch(homeSelectionProvider);
  final homeId = homeState.selectedHomeId;

  if (homeId == null || homeId.isEmpty) return [];

  try {
    return await AssetApiService.instance.getAssets(homeId: homeId);
  } on Object catch (e) {
    debugPrint('[assetsProvider] Failed to fetch assets: $e');
    return [];
  }
});

/// Convenience: assets as legacy Map format for existing widgets.
final assetsLegacyProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final asyncAssets = ref.watch(assetsProvider);
  return asyncAssets.when(
    data: (assets) => assets.map((a) => a.toLegacyMap()).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// ─── My Pending Invitations ───────────────────────────────────────────────────

/// Returns the service types the current user is granted for the selected home.
///
/// • Returns **null** when the user is the home owner (full access — no filtering).
/// • Returns a **List\<String\>** (may be empty) for family members.
/// • Returns **null** on error (fail-open — prefer showing content over hiding it).
///
/// Re-evaluates automatically whenever the selected home changes.
final grantedServiceTypesProvider = FutureProvider<List<String>?>((ref) async {
  final isOwner = ref.watch(selectedHomeIsOwnerProvider);
  if (isOwner) return null; // owner = full access

  final homeId = ref.watch(selectedHomeIdProvider);
  if (homeId == null || homeId.isEmpty) return null;

  try {
    final memberships = await FamilyApiService.instance.getMyAccess();
    final matches = memberships.where((m) => m.homeId == homeId).toList();
    if (matches.isEmpty) return [];
    return matches.first.grantedServiceTypes;
  } on Object catch (_) {
    debugPrint('[grantedServiceTypesProvider] Failed: \$e');
    return null; // fail-open
  }
});

/// Returns the asset IDs the current user can access in the selected home.
///
/// • Returns **null** when the user is the home owner (full access — no filtering).
/// • Returns a **List\<String\>** (may be empty) for family members.
/// • Returns **null** on error (fail-open).
///
/// Re-evaluates automatically whenever the selected home changes.
final grantedAssetIdsProvider = FutureProvider<List<String>?>((ref) async {
  final isOwner = ref.watch(selectedHomeIsOwnerProvider);
  if (isOwner) return null; // owner = full access

  final homeId = ref.watch(selectedHomeIdProvider);
  if (homeId == null || homeId.isEmpty) return null;

  try {
    final memberships = await FamilyApiService.instance.getMyAccess();
    final matches = memberships.where((m) => m.homeId == homeId).toList();
    if (matches.isEmpty) return [];
    return matches.first.grantedAssetIds;
  } on Object catch (_) {
    debugPrint('[grantedAssetIdsProvider] Failed: \$e');
    return null; // fail-open
  }
});

/// Fetches the logged-in user's own pending family invitations (sent TO them).
/// Used to show the in-app acceptance banner so the user doesn't need a deep link.
final myPendingInvitesProvider = FutureProvider<List<MyInviteDto>>((ref) async {
  try {
    return await FamilyApiService.instance.getMyInvites();
  } on Object catch (e) {
    debugPrint('[myPendingInvitesProvider] Failed to fetch: $e');
    return [];
  }
});
