import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In Service
/// Handles authentication with Google OAuth
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  static GoogleSignInService get instance => _instance;

  late GoogleSignIn _googleSignIn;

  /// Initialize Google Sign-In
  void initialize() {
    _googleSignIn = GoogleSignIn(
      clientId: '1098490859710-i59hut1mq2npqmpuhvlnmnann9qd8u7h.apps.googleusercontent.com',
      scopes: [
        'email',
        'profile',
        // Add other scopes as needed
      ],
    );

    if (kDebugMode) {
      debugPrint('✅ Google Sign-In initialized');
    }
  }

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      // Check if already signed in
      final account = await _googleSignIn.signInSilently();
      if (account != null) {
        if (kDebugMode) {
          debugPrint('✅ Already signed in: ${account.email}');
        }
        return account;
      }

      // Prompt user to sign in
      final account = await _googleSignIn.signIn();
      if (account != null) {
        if (kDebugMode) {
          debugPrint('✅ Google Sign-In successful: ${account.email}');
        }

        // Get ID token for backend authentication
        final authentication = await account.authentication;
        if (kDebugMode) {
          debugPrint('📱 ID Token: ${authentication.idToken}');
          debugPrint('📱 Access Token: ${authentication.accessToken}');
        }
      }
      return account;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google Sign-In failed: $e');
      }
      return null;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (kDebugMode) {
        debugPrint('✅ Signed out from Google');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Sign out failed: $e');
      }
    }
  }

  /// Check if user is signed in
  Future<bool> isSignedIn() async {
    final account = await _googleSignIn.signInSilently();
    return account != null;
  }

  /// Get current user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Get ID token for sending to backend
  Future<String?> getIdToken() async {
    try {
      final account = currentUser;
      if (account == null) {
        return null;
      }

      final authentication = await account.authentication;
      return authentication.idToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting ID token: $e');
      }
      return null;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      final account = currentUser;
      if (account == null) {
        return null;
      }

      final authentication = await account.authentication;
      return authentication.accessToken;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting access token: $e');
      }
      return null;
    }
  }
}
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In Service for HomeIQ
/// Handles authentication with Google OAuth credentials
class GoogleSignInService {
  static final GoogleSignInService _instance = GoogleSignInService._internal();

  factory GoogleSignInService() {
    return _instance;
  }

  GoogleSignInService._internal();

  static GoogleSignInService get instance => _instance;

  // Initialize with your Google OAuth Client ID
  // Client ID: 1098490859710-i59hut1mq2npqmpuhvlnmnann9qd8u7h.apps.googleusercontent.com
  // Project ID: tymmo-ai
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId:
        '1098490859710-i59hut1mq2npqmpuhvlnmnann9qd8u7h.apps.googleusercontent.com',
    scopes: [
      'email',
      'profile',
    ],
  );

  /// Sign in with Google
  Future<Map<String, dynamic>?> signIn() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        if (kDebugMode) {
          debugPrint('👤 Google Sign-In cancelled by user');
        }
        return null;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      if (kDebugMode) {
        debugPrint('✅ Google Sign-In successful');
        debugPrint('👤 User: ${googleUser.displayName} (${googleUser.email})');
        debugPrint('🔑 ID Token: ${googleAuth.idToken?.substring(0, 20)}...');
      }

      return {
        'email': googleUser.email,
        'displayName': googleUser.displayName,
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Google Sign-In error: $e');
      }
      return null;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      if (kDebugMode) {
        debugPrint('👋 Signed out from Google');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error signing out: $e');
      }
    }
  }

  /// Disconnect (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
      if (kDebugMode) {
        debugPrint('🔌 Disconnected from Google');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error disconnecting: $e');
      }
    }
  }

  /// Check if user is currently signed in
  Future<bool> isSignedIn() async {
    final isSignedIn = await _googleSignIn.isSignedIn();
    return isSignedIn;
  }

  /// Get current signed-in user
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Listen to sign-in state changes
  Stream<GoogleSignInAccount?> get onCurrentUserChanged =>
      _googleSignIn.onCurrentUserChanged;
}
