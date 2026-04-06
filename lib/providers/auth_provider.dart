import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../services/api_client.dart';
import '../services/auth_api_service.dart';
import '../services/deep_link_service.dart'; // pendingInviteTokenKey, pendingInviteActionKey, pendingInviteEmailKey
import 'data_providers.dart';
import 'deep_link_provider.dart'; // pendingInviteTokenProvider, pendingInviteNavDataProvider, PendingInviteNavData
import 'home_selection_provider.dart';
import 'user_profile_provider.dart';

/// Keys for persisting auth state.
const _isLoggedInKey = 'is_logged_in';
const _loginTimestampKey = 'login_timestamp';
const _accessTokenKey = 'auth_access_token';

/// Possible authentication states.
enum AuthState {
  /// Auth status is being determined (e.g. reading from storage).
  loading,

  /// User is authenticated and should see the app.
  authenticated,

  /// User is not authenticated and should see sign-in.
  unauthenticated,
}

/// Provides the current [AuthState] across the app.
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AuthNotifier(prefs, ref);
});

/// Manages authentication state and persists login status.
class AuthNotifier extends StateNotifier<AuthState> {
  final SharedPreferences _prefs;
  final Ref _ref;
  // Encrypted storage for auth tokens — never readable without device unlock.
  static const _storage = FlutterSecureStorage();

  AuthNotifier(this._prefs, this._ref) : super(AuthState.loading) {
    _checkAuthStatus();
  }

  /// Reads stored login flag AND token presence, then updates state.
  Future<void> _checkAuthStatus() async {
    // Small delay so splash screen is visible briefly.
    await Future.delayed(const Duration(seconds: 2));

    final isLoggedIn = _prefs.getBool(_isLoggedInKey) ?? false;
    // Access token lives in encrypted storage — must be awaited.
    final accessToken = await _storage.read(key: _accessTokenKey);

    if (isLoggedIn && accessToken != null) {
      // Restore token on the generic API client so all services are authenticated.
      ApiClient().setAuthToken(accessToken);
      // Wire up automatic logout on token refresh failure.
      ApiClient().onForceLogout = _handleForceLogout;

      // Check for a pending invite token that was saved by DeepLinkService
      // during cold-start BEFORE the ProviderScope context was ready.
      // Set the token BEFORE state = authenticated so GoRouter picks it up
      // on the very first redirect evaluation.
      final pendingToken = _prefs.getString(pendingInviteTokenKey);
      if (pendingToken != null) {
        _prefs.remove(pendingInviteTokenKey); // fire-and-forget
        _ref.read(pendingInviteTokenProvider.notifier).state = pendingToken;
        debugPrint(
          '[Auth] 🔗 Cold-start invite token restored — will redirect to accept-invite',
        );
      }

      state = AuthState.authenticated;
      debugPrint('[Auth] ✅ User is authenticated (restored from storage)');
      // Refresh user profile from backend on every app restart.
      _ref.read(userProfileProvider.notifier).loadFromBackend().ignore();
    } else {
      // Check for a cold-start pending invite even when not authenticated.
      // DeepLinkService persists action + email to SharedPreferences when the
      // context isn’t ready (app launched cold by tapping the invite link).
      final pendingToken = _prefs.getString(pendingInviteTokenKey);
      if (pendingToken != null) {
        final action = _prefs.getString(pendingInviteActionKey) ?? 'signin';
        final email = _prefs.getString(pendingInviteEmailKey) ?? '';
        // Clean up action/email — the token itself stays for loginWithTokens.
        _prefs.remove(pendingInviteActionKey);
        _prefs.remove(pendingInviteEmailKey);
        // This triggers GoRouter (via _AuthRefreshNotifier) to redirect the
        // user to /signin or /signup with the email pre-filled.
        _ref.read(pendingInviteNavDataProvider.notifier).state =
            PendingInviteNavData(action: action, email: email);
        debugPrint(
          '[Auth] 🔗 Cold-start invite: routing to $action screen (email: $email)',
        );
      }
      state = AuthState.unauthenticated;
      debugPrint('[Auth] ⬚ User is unauthenticated');
    }
  }

  /// Login with JWT tokens from backend (used after OTP verification / Google sign-in).
  Future<void> loginWithTokens(String accessToken, String refreshToken) async {
    await AuthApiService.instance.saveTokens(accessToken, refreshToken);
    // Set token on the generic API client for all subsequent requests.
    ApiClient().setAuthToken(accessToken);
    // Wire up automatic logout on token refresh failure.
    ApiClient().onForceLogout = _handleForceLogout;
    await _prefs.setBool(_isLoggedInKey, true);
    await _prefs.setInt(
      _loginTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );

    // ── Invalidate all user-data providers so they re-fetch for THIS user.
    //    Must happen AFTER the token is set on ApiClient so the first fetch
    //    is authenticated. The providers lazy-rebuild on next widget read.
    _ref.invalidate(homeSelectionProvider);
    _ref.invalidate(homesProvider);
    _ref.invalidate(assetsProvider);

    // Check if the user tapped a family-invite email link before signing in.
    // If so, redirect them to /accept-invite to complete the flow.
    // IMPORTANT: Read the token and set the provider BEFORE setting
    // state = authenticated.  This avoids a race where GoRouter's redirect
    // fires (from the auth-state change) before the invite token is set,
    // briefly sending the user to /home instead of /accept-invite.
    final pendingToken = _prefs.getString(pendingInviteTokenKey);
    if (pendingToken != null) {
      // Fire-and-forget — don't await so the token provider is set
      // synchronously right before the auth state change.
      _prefs.remove(pendingInviteTokenKey);
      _ref.read(pendingInviteTokenProvider.notifier).state = pendingToken;
      debugPrint(
        '[Auth] 🔗 Pending invite token found — will redirect to accept-invite',
      );
    }

    state = AuthState.authenticated;
    debugPrint('[Auth] ✅ Login successful — tokens saved');
    // Immediately populate the user profile from backend.
    _ref.read(userProfileProvider.notifier).loadFromBackend().ignore();
  }

  /// Legacy login (for backward compatibility) — sets flag without tokens.
  Future<void> login() async {
    await _prefs.setBool(_isLoggedInKey, true);
    await _prefs.setInt(
      _loginTimestampKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    state = AuthState.authenticated;
  }

  /// Clears auth state, tokens, and persisted data.
  Future<void> logout() async {
    try {
      await AuthApiService.instance.logout();
    } on Object catch (_) {
      // Ignore logout API errors — still clear local state.
    }
    ApiClient().setAuthToken(null);
    ApiClient().onForceLogout = null;
    await _prefs.remove(_isLoggedInKey);
    await _prefs.remove(_loginTimestampKey);

    // ── Clear persisted home-selection keys so the next user starts fresh.
    //    Without this, the new user would inherit the previous user's selected
    //    home from SharedPreferences and see their data.
    await _prefs.remove('selected_home_name');
    await _prefs.remove('selected_home_id');

    // ── Clear user profile so the next login gets a fresh state.
    try {
      await _ref.read(userProfileProvider.notifier).clearProfile();
    } on Object catch (_) {}

    // ── Invalidate all user-data providers so they rebuild from scratch
    //    when the next user logs in. Token is already cleared above.
    _ref.invalidate(homeSelectionProvider);
    _ref.invalidate(homesProvider);
    _ref.invalidate(assetsProvider);

    state = AuthState.unauthenticated;
    debugPrint('[Auth] 🚪 User logged out');
  }

  /// Called by ApiClient when token refresh fails (e.g. refresh token expired).
  void _handleForceLogout() {
    debugPrint('[Auth] ⚠️ Force logout — token refresh failed');
    logout();
  }
}
