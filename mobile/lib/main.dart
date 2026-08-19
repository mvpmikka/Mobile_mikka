import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/explore_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/welcome_screen.dart';
import 'theme/app_colors.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appLinks = AppLinks();
  final _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      await _handleLink(initialUri);
    }
    _linkSubscription = _appLinks.uriLinkStream.listen(_handleLink);
  }

  // mikka://verify-email?token=... and mikka://reset-password?token=... —
  // sent as links in the verification/password-reset emails.
  Future<void> _handleLink(Uri uri) async {
    if (uri.scheme != 'mikka') return;
    final token = uri.queryParameters['token'];
    if (token == null) return;

    if (uri.host == 'verify-email') {
      try {
        await ref.read(authControllerProvider.notifier).verifyEmail(token);
      } catch (_) {
        // Invalid/expired token — nothing to recover here automatically.
      }
      return;
    }

    if (uri.host == 'reset-password') {
      // There's no reliable BuildContext in this State (it sits above
      // MaterialApp), so navigation goes through the global navigator key
      // instead of Navigator.of(context).
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => ResetPasswordScreen(token: token)),
      );
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'Mikka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE97A3C),
        fontFamily: 'Roboto',
      ),
      home: const AuthGate(),
    );
  }
}

/// Waits for the stored session (if any) to be validated against the
/// backend, then routes to the signed-in, unverified, or signed-out entry
/// point.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Keeps the chat WebSocket connected for the lifetime of the signed-in
    // session (not just while a chat screen happens to be open), so
    // real-time messages/badges work app-wide — and torn down on logout.
    ref.listen(authControllerProvider, (previous, next) async {
      final socket = ref.read(chatSocketServiceProvider);
      final isAuthenticated = next.value?.isAuthenticated ?? false;
      if (!isAuthenticated) {
        socket.disconnect();
        return;
      }
      final token = await ref.read(tokenStorageProvider).readAccessToken();
      if (token != null) socket.connect(token);
    });

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (_, _) => const WelcomeScreen(),
      data: (state) {
        final user = state.user;
        if (user == null) return const WelcomeScreen();
        return user.isEmailVerified
            ? const ExploreScreen()
            : VerifyEmailScreen(email: user.email);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.cream,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
    );
  }
}
