import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:homeiq/services/google_sign_in_service.dart';

/// Riverpod provider for Google Sign-In service
final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService.instance;
});

/// Riverpod provider for current Google user
final googleCurrentUserProvider = StreamProvider<GoogleSignInAccount?>((ref) {
  final service = ref.watch(googleSignInServiceProvider);
  return service._googleSignIn.onCurrentUserChanged;
});

/// Riverpod provider for Google sign-in state
final googleSignInStateProvider = StateNotifierProvider<GoogleSignInStateNotifier, GoogleSignInState>((ref) {
  return GoogleSignInStateNotifier();
});

class GoogleSignInState {
  final GoogleSignInAccount? user;
  final bool isLoading;
  final String? error;

  GoogleSignInState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  GoogleSignInState copyWith({
    GoogleSignInAccount? user,
    bool? isLoading,
    String? error,
  }) {
    return GoogleSignInState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GoogleSignInStateNotifier extends StateNotifier<GoogleSignInState> {
  GoogleSignInStateNotifier() : super(GoogleSignInState());

  /// Sign in with Google
  Future<void> signIn() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final service = GoogleSignInService.instance;
      final account = await service.signIn();

      if (account != null) {
        state = state.copyWith(user: account, isLoading: false);
      } else {
        state = state.copyWith(isLoading: false, error: 'Sign-in cancelled');
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      final service = GoogleSignInService.instance;
      await service.signOut();
      state = GoogleSignInState(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Check if signed in
  Future<void> checkSignInStatus() async {
    try {
      final service = GoogleSignInService.instance;
      final isSignedIn = await service.isSignedIn();
      if (isSignedIn) {
        final user = service.currentUser;
        state = state.copyWith(user: user);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
