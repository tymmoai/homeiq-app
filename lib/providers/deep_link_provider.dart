import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds a pending invite token received from a deep link or email invite.
///
/// Lifecycle:
///  1. [DeepLinkService] writes the token here when a homeiq:// URI arrives
///     and the user is already authenticated.
///  2. [AuthNotifier.loginWithTokens] writes the token here after a successful
///     login when a token was saved to SharedPreferences pre-auth.
///  3. [goRouterProvider] redirect reads this and sends the user to
///     /accept-invite?token=TOKEN, then clears it.
final pendingInviteTokenProvider = StateProvider<String?>((ref) => null);

/// Navigation destination data for a pending invite when the user is NOT yet
/// authenticated (cold-start tap on invite email link, or app opened while
/// logged out).
///
/// Lifecycle:
///  1. Set by [AuthNotifier._checkAuthStatus] when the user is unauthenticated
///     but a pending invite token + nav data is in SharedPreferences (cold-start).
///  2. [goRouterProvider] redirect reads this, clears it, and routes to
///     /signin or /signup with [email] pre-filled.
class PendingInviteNavData {
  final String action; // 'signin' | 'signup'
  final String email;
  const PendingInviteNavData({required this.action, required this.email});
}

final pendingInviteNavDataProvider = StateProvider<PendingInviteNavData?>(
  (ref) => null,
);
