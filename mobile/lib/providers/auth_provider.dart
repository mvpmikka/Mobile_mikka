import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../core/google_auth_config.dart';
import '../core/token_storage.dart';
import '../models/user.dart';
import '../services/auth_service.dart';

/// Current session: either signed out, or signed in as [user].
class AuthState {
  const AuthState._(this.user);

  const AuthState.unauthenticated() : this._(null);

  const AuthState.authenticated(AppUser user) : this._(user);

  final AppUser? user;

  bool get isAuthenticated => user != null;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(tokenStorage: ref.watch(tokenStorageProvider));
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final apiClient = ref.watch(apiClientProvider);
    // A refresh failure anywhere in the app (any screen's API call) should
    // drop the user back to the login screen, not just fail that one call.
    apiClient.onUnauthenticated = () {
      state = const AsyncData(AuthState.unauthenticated());
    };

    final authService = ref.watch(authServiceProvider);
    if (!await authService.hasStoredSession()) {
      return const AuthState.unauthenticated();
    }
    try {
      final user = await authService.fetchCurrentUser();
      return AuthState.authenticated(user);
    } catch (_) {
      await ref.read(tokenStorageProvider).clear();
      return const AuthState.unauthenticated();
    }
  }

  // login/register/logout intentionally don't set state on failure — the
  // calling screen shows the error inline (SnackBar) while the session
  // underneath stays whatever it already was.

  Future<void> login({required String email, required String password}) async {
    final authService = ref.read(authServiceProvider);
    await authService.login(email: email, password: password);
    final user = await authService.fetchCurrentUser();
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final authService = ref.read(authServiceProvider);
    await authService.register(email: email, username: username, password: password);
    final user = await authService.fetchCurrentUser();
    state = AsyncData(AuthState.authenticated(user));
  }

  // Native Google Sign-In returns null when the user dismisses the account
  // picker (not an error) — the caller should treat that as a silent no-op,
  // same as if they'd tapped "back" from the email form.
  Future<void> loginWithGoogle() async {
    final googleSignIn = GoogleSignIn(
      serverClientId: GoogleAuthConfig.serverClientId,
    );

    GoogleSignInAccount? account;
    GoogleSignInAuthentication googleAuth;
    try {
      account = await googleSignIn.signIn();
      if (account == null) return;
      googleAuth = await account.authentication;
    } on PlatformException catch (e) {
      throw ApiException(
        e.message ?? 'Google orqali kirishda xatolik yuz berdi (${e.code})',
      );
    }

    final idToken = googleAuth.idToken;
    if (idToken == null) {
      throw const ApiException('Google tokenini olib bo\'lmadi');
    }

    final authService = ref.read(authServiceProvider);
    await authService.loginWithGoogle(idToken);
    final user = await authService.fetchCurrentUser();
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(AuthState.unauthenticated());
  }

  Future<void> verifyEmail(String token) async {
    final authService = ref.read(authServiceProvider);
    await authService.verifyEmail(token);
    final user = await authService.fetchCurrentUser();
    state = AsyncData(AuthState.authenticated(user));
  }

  Future<void> resendVerification() async {
    final currentUser = state.value?.user;
    if (currentUser == null) return;
    final authService = ref.read(authServiceProvider);
    await authService.resendVerification(currentUser.email);
  }
}
