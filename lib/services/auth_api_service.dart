import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/config/environment.dart';
import '../main.dart';

/// Keys for token storage
const _accessTokenKey = 'auth_access_token';
const _refreshTokenKey = 'auth_refresh_token';
const _isLoggedInKey = 'is_logged_in';

/// Simple provider to track auth state reactively.
/// Screens read this; login/logout toggle it.
final authStateProvider = StateProvider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return prefs.getBool(_isLoggedInKey) ?? false;
});

/// Auth API service that connects to backend-client (/api/v1/auth/...)
///
/// Handles: register, send-login-otp, verify-login-otp, verify-email,
/// resend-otp, google sign-in, token refresh, logout.
class AuthApiService {
  AuthApiService._();
  static final AuthApiService instance = AuthApiService._();

  /// Encrypted storage for sensitive auth tokens (iOS Keychain / Android Keystore).
  static const _storage = FlutterSecureStorage();

  /// Auth endpoint base — derived from the single EnvironmentConfig.apiV1Url.
  String get _authBase => '${EnvironmentConfig.apiV1Url}/auth';

  /// Google Sign-In instance — configured with scopes matching web client.
  /// The serverClientId must match the Web client ID in your Google Console
  /// (same one the backend uses for token verification).
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId:
        '1098490859710-cb75btvar7t23p6pm2qs32uo5nopjhkg.apps.googleusercontent.com',
  );

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Get stored access token from encrypted storage.
  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  /// Save tokens after login.
  /// Tokens go to FlutterSecureStorage (encrypted); the logged-in flag
  /// stays in SharedPreferences (non-sensitive, needed for sync startup read).
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await Future.wait([
      _storage.write(key: _accessTokenKey, value: accessToken),
      _storage.write(key: _refreshTokenKey, value: refreshToken),
    ]);
    final prefs = await _preferences;
    await prefs.setBool(_isLoggedInKey, true);
  }

  /// Clear tokens on logout.
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _accessTokenKey),
      _storage.delete(key: _refreshTokenKey),
    ]);
    final prefs = await _preferences;
    await prefs.setBool(_isLoggedInKey, false);
  }

  /// Common headers
  Map<String, String> _headers({String? accessToken}) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'X-Client-Type': 'app',
    };
    if (accessToken != null) h['Authorization'] = 'Bearer $accessToken';
    return h;
  }

  /// POST helper with error extraction and robust network error handling
  Future<Map<String, dynamic>> _post(
    String path,
    Map<String, dynamic> body, {
    String? accessToken,
  }) async {
    final uri = Uri.parse('$_authBase$path');
    debugPrint('[AuthAPI] POST $uri');

    http.Response response;
    try {
      response = await http
          .post(uri, headers: _headers(accessToken: accessToken), body: jsonEncode(body))
          .timeout(const Duration(seconds: 30));
    } on SocketException catch (_) {
      throw Exception(
        'Unable to connect to server. Please check your internet connection and try again.',
      );
    } on TimeoutException catch (_) {
      throw Exception(
        'Connection timed out. Please check your internet connection and try again.',
      );
    } on HttpException catch (_) {
      throw Exception(
        'A network error occurred. Please try again.',
      );
    } on HandshakeException catch (_) {
      throw Exception(
        'Secure connection failed. Please try again.',
      );
    } on Object catch (e) {
      // Catch any other platform-specific network errors
      final msg = e.toString().toLowerCase();
      if (msg.contains('connection refused') ||
          msg.contains('network is unreachable') ||
          msg.contains('no route to host') ||
          msg.contains('connection reset') ||
          msg.contains('software caused connection abort') ||
          msg.contains('no address associated') ||
          msg.contains('failed host lookup')) {
        throw Exception(
          'Unable to connect to server. Please check your internet connection and try again.',
        );
      }
      rethrow;
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object catch (_) {
      throw Exception('Unexpected server response. Please try again.');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return data;
    }

    // Extract error message from backend response
    final message = data['message'] ?? data['error'] ?? 'Request failed';
    throw Exception(message);
  }

  // ── Auth flows ──────────────────────────────────────────────────────────────

  /// Register a new account (email + name)
  Future<void> register({
    required String email,
    required String name,
  }) async {
    await _post('/register', {'email': email, 'name': name});
  }

  /// Send login OTP to email
  Future<void> sendLoginOtp(String email) async {
    await _post('/send-login-otp', {'email': email});
  }

  /// Verify login OTP — returns tokens + user
  Future<Map<String, dynamic>> verifyLoginOtp({
    required String email,
    required String otp,
  }) async {
    final res = await _post('/verify-login-otp', {'email': email, 'otp': otp});
    final data = res['data'] as Map<String, dynamic>;
    return data; // { accessToken, refreshToken, user }
  }

  /// Verify email OTP after registration — returns tokens + user
  Future<Map<String, dynamic>> verifyEmail({
    required String email,
    required String otp,
  }) async {
    final res = await _post('/verify-email', {'email': email, 'otp': otp});
    final data = res['data'] as Map<String, dynamic>;
    return data; // { accessToken, refreshToken, user }
  }

  /// Resend OTP
  Future<void> resendOtp({
    required String email,
    required String type,
  }) async {
    await _post('/resend-otp', {'email': email, 'type': type});
  }

  /// Google Sign-In — gets ID token from Google, sends to backend.
  /// Backend verifies the ID token and returns app JWT tokens.
  /// Returns { accessToken, refreshToken, user, isNewUser }.
  Future<Map<String, dynamic>> googleSignIn() async {
    // Sign out any previous session to force account picker
    await _googleSignIn.signOut();

    final GoogleSignInAccount? account = await _googleSignIn.signIn();
    if (account == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    final GoogleSignInAuthentication auth = await account.authentication;

    // Prefer idToken (available when serverClientId is set).
    // Fall back to accessToken if idToken is null.
    final String? idToken = auth.idToken;
    final String? accessToken = auth.accessToken;

    if (idToken == null && accessToken == null) {
      throw Exception('Failed to get Google authentication tokens');
    }

    debugPrint('[AuthAPI] Google Sign-In: got ${idToken != null ? 'idToken' : 'accessToken'}');

    // Send the token to our backend for verification
    final body = <String, dynamic>{};
    if (idToken != null) {
      body['idToken'] = idToken;
    } else {
      body['accessToken'] = accessToken;
    }

    final res = await _post('/google', body);
    final data = res['data'] as Map<String, dynamic>;
    return data; // { accessToken, refreshToken, user, isNewUser }
  }

  /// Silently check for existing Google session (for auto-login).
  Future<bool> isGoogleSessionActive() async {
    return await _googleSignIn.isSignedIn();
  }

  /// Sign out of Google (used during logout).
  Future<void> googleSignOut() async {
    try {
      await _googleSignIn.signOut();
    } on Object catch (_) {
      // Ignore — best effort
    }
  }

  /// Refresh tokens
  Future<Map<String, dynamic>> refreshTokens() async {
    final prefs = await _preferences;
    final refreshToken = prefs.getString(_refreshTokenKey);
    if (refreshToken == null) throw Exception('No refresh token');

    final res = await _post('/refresh', {'refreshToken': refreshToken});
    final data = res['data'] as Map<String, dynamic>;

    // Save new tokens
    await saveTokens(data['accessToken'], data['refreshToken']);
    return data;
  }

  /// Logout
  Future<void> logout() async {
    final prefs = await _preferences;
    final refreshToken = prefs.getString(_refreshTokenKey);
    try {
      if (refreshToken != null) {
        await _post('/logout', {'refreshToken': refreshToken});
      }
    } on Object catch (_) {
      // Ignore logout errors
    }
    // Also sign out of Google session
    await googleSignOut();
    await clearTokens();
  }
}