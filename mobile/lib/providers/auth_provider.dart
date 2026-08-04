import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_client.dart';
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

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = const AsyncData(AuthState.unauthenticated());
  }
}
