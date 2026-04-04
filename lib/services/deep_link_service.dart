import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/auth_provider.dart';
import '../providers/deep_link_provider.dart';

/// SharedPreferences keys used to persist invite data across sign-in.
const pendingInviteTokenKey = 'pending_invite_token';
const pendingInviteActionKey = 'pending_invite_action'; // 'signin' | 'signup'
const pendingInviteEmailKey = 'pending_invite_email';

/// Intercepts incoming [homeiq://accept-invite?token=xxx] deep links.
///
/// Three cases:
///  • User is **authenticated** → writes the token to [pendingInviteTokenProvider]
///    which triggers the GoRouter redirect to /accept-invite.
///  • User is **unauthenticated** + invite email is already registered →
///    persists the token in SharedPreferences and navigates to /signin with
///    email pre-filled.
///  • User is **unauthenticated** + invite email is not registered →
///    persists the token and navigates to /signup with email pre-filled.
///
/// The backend embed `action=signin|signup` and `email=xxx` into the deep
/// link so the app never needs to make an extra network call here.
class DeepLinkService {
  DeepLinkService._();
  static final DeepLinkService instance = DeepLinkService._();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _subscription;
  GlobalKey<NavigatorState>? _navigatorKey;

  /// Call once from [main] after the Flutter engine is initialised.
  void init(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;

    // Handle cold-start deep link (app launched by tapping the email link).
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _handleUri(uri);
    }).catchError((_) {});

    // Handle deep links received while the app is already running.
    _subscription = _appLinks.uriLinkStream.listen(
      _handleUri,
      onError: (_) {},
    );
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _handleUri(Uri uri) {
    debugPrint('[DeepLink] Received: $uri');

    if (uri.scheme != 'homeiq' || uri.host != 'accept-invite') return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final context = _navigatorKey?.currentContext;

    if (context == null || !context.mounted) {
      // Context not ready yet (very early cold start) — persist all three
      // pieces so AuthNotifier can reconstruct the correct nav route.
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(pendingInviteTokenKey, token);
        prefs.setString(
          pendingInviteActionKey,
          uri.queryParameters['action'] ?? 'signin',
        );
        prefs.setString(
          pendingInviteEmailKey,
          uri.queryParameters['email'] ?? '',
        );
      });
      return;
    }

    final container = ProviderScope.containerOf(context, listen: false);
    final authState = container.read(authProvider);

    if (authState == AuthState.authenticated) {
      // Already signed in → trigger redirect immediately.
      container.read(pendingInviteTokenProvider.notifier).state = token;
    } else {
      // Not signed in → persist token and route to the correct auth screen.
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString(pendingInviteTokenKey, token);
      });

      // The backend embeds action=signin|signup and email=xxx into the deep
      // link so the app doesn't need an extra network call.
      final action = uri.queryParameters['action'] ?? 'signin';
      final email = uri.queryParameters['email'] ?? '';
      final emailParam = email.isNotEmpty
          ? '&prefilledEmail=${Uri.encodeComponent(email)}'
          : '';

      if (action == 'signup') {
        GoRouter.of(context).go('/signup?fromInvite=true$emailParam');
      } else {
        GoRouter.of(context).go('/signin?fromInvite=true$emailParam');
      }
    }
  }
}
