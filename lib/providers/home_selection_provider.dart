import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/home_api_service.dart';
import '../services/user_service.dart';

/// Model for a home
class HomeModel {
  final String name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String? homeId;

  /// 'owner' | 'family_member' — mirrors the backend accessRole field.
  final String accessRole;

  /// 'owner' | 'member' | 'viewer' — the fine-grained role within the home.
  /// For home owners this equals 'owner'. For family members it reflects the
  /// role set during invite ('member' or 'viewer').
  final String memberRole;

  const HomeModel({
    required this.name,
    required this.address,
    this.city = '',
    this.state = '',
    this.zip = '',
    this.homeId,
    this.accessRole = 'owner',
    this.memberRole = 'owner',
  });

  /// True when the user is a read-only viewer of this home.
  bool get isViewer => memberRole == 'viewer';

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'homeId': homeId,
      'accessRole': accessRole,
      'memberRole': memberRole,
    };
  }

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    return HomeModel(
      name: json['name'] as String,
      address: json['address'] as String,
      city: (json['city'] as String?) ?? '',
      state: (json['state'] as String?) ?? '',
      zip: (json['zip'] as String?) ?? '',
      homeId: json['homeId'] as String?,
      accessRole: (json['accessRole'] as String?) ?? 'owner',
      memberRole: (json['memberRole'] as String?) ?? 'owner',
    );
  }
}

/// State for home selection
class HomeSelectionState {
  final String selectedHomeName;
  final String? selectedHomeId;
  final List<HomeModel> homes;

  const HomeSelectionState({
    required this.selectedHomeName,
    this.selectedHomeId,
    required this.homes,
  });

  HomeSelectionState copyWith({
    String? selectedHomeName,
    String? selectedHomeId,
    List<HomeModel>? homes,
  }) {
    return HomeSelectionState(
      selectedHomeName: selectedHomeName ?? this.selectedHomeName,
      selectedHomeId: selectedHomeId ?? this.selectedHomeId,
      homes: homes ?? this.homes,
    );
  }
}

/// Notifier for managing home selection
class HomeSelectionNotifier extends StateNotifier<HomeSelectionState> {
  final SharedPreferences _prefs;

  HomeSelectionNotifier(this._prefs)
    : super(
        const HomeSelectionState(
          selectedHomeName: 'Loading...',
          selectedHomeId: null,
          homes: [],
        ),
      ) {
    _loadHomesFromBackend();
  }

  /// Fetch homes from the backend API, then restore the saved selection.
  Future<void> _loadHomesFromBackend() async {
    try {
      final dtos = await HomeApiService.instance.getHomes();
      final homes = dtos
          .map(
            (h) => HomeModel(
              name: h.displayName,
              address: h.address,
              city: h.city,
              state: h.state,
              zip: h.zip,
              homeId: h.id,
              accessRole: h.accessRole ?? 'owner',
              memberRole:
                  h.memberRole ??
                  (h.accessRole == 'family_member' ? 'member' : 'owner'),
            ),
          )
          .toList();

      if (homes.isEmpty) {
        state = const HomeSelectionState(
          selectedHomeName: 'No homes yet',
          selectedHomeId: null,
          homes: [],
        );
        return;
      }

      // Restore previously-selected home, or default to the first one.
      final savedHomeName = _prefs.getString('selected_home_name');
      final selected = homes.firstWhere(
        (h) => h.name == savedHomeName,
        orElse: () => homes.first,
      );

      state = HomeSelectionState(
        selectedHomeName: selected.name,
        selectedHomeId: selected.homeId,
        homes: homes,
      );
      // Cache the homeId so static services (e.g. MaintenanceService) can read it
      if (selected.homeId != null) {
        await _prefs.setString('selected_home_id', selected.homeId!);
      }
      // Persist home address so all address screens auto-fill from the selected home
      await _prefs.setString('selected_home_address', selected.address);
      await _prefs.setString('selected_home_city', selected.city);
      await _prefs.setString('selected_home_state', selected.state);
      await _prefs.setString('selected_home_zip', selected.zip);
      UserService.instance.setSelectedHomeAddress(
        address: selected.address,
        city: selected.city,
        state: selected.state,
        zip: selected.zip,
      );
    } on Object catch (e) {
      debugPrint(
        '[HomeSelection] Backend fetch failed: $e — starting with empty list',
      );
      state = const HomeSelectionState(
        selectedHomeName: 'No homes',
        selectedHomeId: null,
        homes: [],
      );
    }
  }

  /// Refresh homes from the backend (call after creating a new home).
  Future<void> refreshHomes() async {
    await _loadHomesFromBackend();
  }

  /// Select a home by name
  Future<void> selectHome(String homeName) async {
    if (state.homes.isEmpty) return;

    final home = state.homes.firstWhere(
      (h) => h.name == homeName,
      orElse: () => state.homes.first,
    );

    state = HomeSelectionState(
      selectedHomeName: home.name,
      selectedHomeId: home.homeId,
      homes: state.homes,
    );

    // Persist selection (name + id so static services can read the current homeId)
    await _prefs.setString('selected_home_name', home.name);
    if (home.homeId != null) {
      await _prefs.setString('selected_home_id', home.homeId!);
    }
    // Persist home address so all address screens auto-fill from the selected home
    await _prefs.setString('selected_home_address', home.address);
    await _prefs.setString('selected_home_city', home.city);
    await _prefs.setString('selected_home_state', home.state);
    await _prefs.setString('selected_home_zip', home.zip);
    UserService.instance.setSelectedHomeAddress(
      address: home.address,
      city: home.city,
      state: home.state,
      zip: home.zip,
    );
  }

  /// Select a home by its database ID.
  /// Falls back to refresh + re-select if the home isn't loaded yet.
  Future<void> selectHomeById(String homeId) async {
    final existing = state.homes.firstWhere(
      (h) => h.homeId == homeId,
      orElse: () => const HomeModel(name: '', address: ''),
    );
    if (existing.homeId != null) {
      await selectHome(existing.name);
      return;
    }
    // Not in the list yet — refresh then try again.
    await refreshHomes();
    final afterRefresh = state.homes.firstWhere(
      (h) => h.homeId == homeId,
      orElse: () => const HomeModel(name: '', address: ''),
    );
    if (afterRefresh.homeId != null) {
      await selectHome(afterRefresh.name);
    } else {
      // Persist directly so it is restored when homes eventually load.
      await _prefs.setString('selected_home_id', homeId);
    }
  }

  /// Add a new home via the backend, then refresh the list and select it.
  ///
  /// If [city], [homeState], [zip] are not provided, the method attempts to
  /// parse them from [address] assuming a US-style format such as:
  ///   "123 Main St, Miami, FL 33101"
  Future<void> addHome(
    String name,
    String address, {
    String city = '',
    String homeState = '',
    String zip = '',
  }) async {
    try {
      // ── Parse city / state / zip from address if not provided ──────
      String parsedAddress = address;
      String parsedCity = city;
      String parsedState = homeState;
      String parsedZip = zip;

      if (parsedCity.isEmpty || parsedState.isEmpty || parsedZip.isEmpty) {
        // Try to extract from comma-separated US address:
        //   "123 Main St, Miami, FL 33101"
        //   "123 Main St, Miami, FL"
        //   "123 Main St, Miami FL 33101"
        final parts = address.split(',').map((s) => s.trim()).toList();
        if (parts.length >= 3) {
          // "123 Main St", "Miami", "FL 33101"
          parsedAddress = parts[0];
          if (parsedCity.isEmpty) parsedCity = parts[1];
          // Last part might be "FL 33101" or "FL"
          final lastPart = parts.last.trim();
          final stateZipMatch = RegExp(
            r'^([A-Za-z]{2})\s+(\d{5}(?:-\d{4})?)$',
          ).firstMatch(lastPart);
          if (stateZipMatch != null) {
            if (parsedState.isEmpty) {
              parsedState = stateZipMatch.group(1)!.toUpperCase();
            }
            if (parsedZip.isEmpty) parsedZip = stateZipMatch.group(2)!;
          } else if (lastPart.length == 2 &&
              RegExp(r'^[A-Za-z]{2}$').hasMatch(lastPart)) {
            if (parsedState.isEmpty) parsedState = lastPart.toUpperCase();
          }
        } else if (parts.length == 2) {
          // "123 Main St, Miami FL 33101"
          parsedAddress = parts[0];
          final tail = parts[1].trim();
          final match = RegExp(
            r'^(.+?)\s+([A-Za-z]{2})\s+(\d{5}(?:-\d{4})?)$',
          ).firstMatch(tail);
          if (match != null) {
            if (parsedCity.isEmpty) parsedCity = match.group(1)!.trim();
            if (parsedState.isEmpty) {
              parsedState = match.group(2)!.toUpperCase();
            }
            if (parsedZip.isEmpty) parsedZip = match.group(3)!;
          } else {
            if (parsedCity.isEmpty) parsedCity = tail;
          }
        }

        // Also try to find zip in the full string if still missing
        if (parsedZip.isEmpty) {
          final zipMatch = RegExp(
            r'\b(\d{5}(?:-\d{4})?)\b',
          ).firstMatch(address);
          if (zipMatch != null) parsedZip = zipMatch.group(1)!;
        }
      }

      debugPrint('[HomeSelection] Creating home: "$name"');
      debugPrint('[HomeSelection]   address: $parsedAddress');
      debugPrint(
        '[HomeSelection]   city: $parsedCity, state: $parsedState, zip: $parsedZip',
      );

      final newHomeDto = await HomeApiService.instance.createHome(
        name: name.isNotEmpty ? name : null,
        address: parsedAddress.isNotEmpty ? parsedAddress : address,
        city: parsedCity.isNotEmpty ? parsedCity : 'City',
        state: parsedState.isNotEmpty ? parsedState : 'ST',
        zip: parsedZip.isNotEmpty ? parsedZip : '00000',
      );
      // Refresh list from backend and select the newly-created home by its ID.
      // Using selectHomeById avoids the bug where owned homes come before
      // family-member homes in the API response, making `homes.last` point
      // to the wrong (family) home instead of the one just created.
      await refreshHomes();
      await selectHomeById(newHomeDto.id);
      debugPrint('[HomeSelection] ✅ Home "$name" created and selected');
    } on Object catch (e) {
      debugPrint('[HomeSelection] ❌ Failed to create home: $e');
      rethrow;
    }
  }

  /// Get currently selected home
  HomeModel get selectedHome {
    if (state.homes.isEmpty) {
      return const HomeModel(
        name: 'No homes yet',
        address: 'Add your first home',
      );
    }
    return state.homes.firstWhere(
      (h) => h.name == state.selectedHomeName,
      orElse: () => state.homes.first,
    );
  }

  /// Get home ID for the selected home
  String? get selectedHomeId {
    return selectedHome.homeId;
  }
}

/// Provider for home selection state
final homeSelectionProvider =
    StateNotifierProvider<HomeSelectionNotifier, HomeSelectionState>((ref) {
      final prefs = ref.watch(sharedPreferencesProvider);
      return HomeSelectionNotifier(prefs);
    });

/// Provider to get just the selected home ID (for convenience)
final selectedHomeIdProvider = Provider<String?>((ref) {
  final homeState = ref.watch(homeSelectionProvider);
  return homeState.selectedHomeId;
});

/// Provider to get just the selected home name (for convenience)
final selectedHomeNameProvider = Provider<String>((ref) {
  final homeState = ref.watch(homeSelectionProvider);
  return homeState.selectedHomeName;
});

/// Provider to get just the selected home address (for convenience)
final selectedHomeAddressProvider = Provider<String>((ref) {
  final homeState = ref.watch(homeSelectionProvider);
  if (homeState.homes.isEmpty) return '';
  final selected = homeState.homes.firstWhere(
    (h) => h.name == homeState.selectedHomeName,
    orElse: () => homeState.homes.first,
  );
  return selected.address;
});

/// Returns true if the currently selected home is owned by the user.
/// Family members see false — used to hide owner-only UI (Add Asset FAB, etc.).
final selectedHomeIsOwnerProvider = Provider<bool>((ref) {
  final homeState = ref.watch(homeSelectionProvider);
  final selectedId = homeState.selectedHomeId;
  if (selectedId == null) {
    return true; // No home selected → show owner UI (setup flow)
  }
  final selected = homeState.homes.firstWhere(
    (h) => h.homeId == selectedId,
    orElse: () => const HomeModel(name: '', address: '', accessRole: 'owner'),
  );
  return selected.accessRole == 'owner';
});

/// Returns the fine-grained memberRole for the currently selected home.
/// Values: 'owner' | 'member' | 'viewer'.
/// Defaults to 'owner' when no home is selected or on error (fail-open).
final selectedHomeMemberRoleProvider = Provider<String>((ref) {
  final homeState = ref.watch(homeSelectionProvider);
  final selectedId = homeState.selectedHomeId;
  if (selectedId == null) return 'owner';
  final selected = homeState.homes.firstWhere(
    (h) => h.homeId == selectedId,
    orElse: () => const HomeModel(name: '', address: ''),
  );
  return selected.memberRole;
});

/// Returns true if the current user is a read-only viewer of the selected home.
/// Viewers can browse but cannot create, edit, or delete any data.
final selectedHomeIsViewerProvider = Provider<bool>((ref) {
  return ref.watch(selectedHomeMemberRoleProvider) == 'viewer';
});
