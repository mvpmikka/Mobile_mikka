import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/auth_provider.dart';
import 'providers/call_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/incoming_call_screen.dart';
import 'screens/main_shell_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/verify_email_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/call_socket_service.dart';
import 'theme/app_colors.dart';

void main() {
  // Any widget build that throws (e.g. an uncaught network-timeout
  // exception) would otherwise surface as Flutter's raw red debug screen —
  // show a friendly, retryable Uzbek message instead.
  ErrorWidget.builder = (details) => Material(
        color: const Color(0xFFF8F1E6),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Nimadir xato ketdi. Qayta urinib ko\'ring.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      );

  runApp(const ProviderScope(child: MyApp()));
}

// Top-level so it can be reached from places with no BuildContext of their
// own — e.g. pushing IncomingCallScreen when a call arrives while the user
// is anywhere in the app.
final navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  final _appLinks = AppLinks();
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
      navigatorKey.currentState?.push(
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
      navigatorKey: navigatorKey,
      title: 'Mikka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE97A3C),
        brightness: Brightness.light,
        fontFamily: 'Roboto',
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFE97A3C),
        brightness: Brightness.dark,
        fontFamily: 'Roboto',
      ),
      themeMode: ThemeMode.system,
      home: const AuthGate(),
    );
  }
}

/// Waits for the stored session (if any) to be validated against the
/// backend, then routes to the signed-in, unverified, or signed-out entry
/// point.
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  StreamSubscription<IncomingCallEvent>? _incomingCallSub;

  @override
  void dispose() {
    _incomingCallSub?.cancel();
    super.dispose();
  }

  void _handleIncomingCall(IncomingCallEvent event) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => IncomingCallScreen(
          callId: event.callId,
          callerId: event.callerId,
          kind: event.kind,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    // Keeps the chat/call WebSockets connected for the lifetime of the
    // signed-in session (not just while a chat/call screen happens to be
    // open), so real-time messages/badges/incoming calls work app-wide —
    // and torn down on logout.
    ref.listen(authControllerProvider, (previous, next) async {
      final chatSocket = ref.read(chatSocketServiceProvider);
      final callSocket = ref.read(callSocketServiceProvider);
      final isAuthenticated = next.value?.isAuthenticated ?? false;
      if (!isAuthenticated) {
        chatSocket.disconnect();
        callSocket.disconnect();
        _incomingCallSub?.cancel();
        _incomingCallSub = null;
        return;
      }
      try {
        final token = await ref.read(tokenStorageProvider).readAccessToken();
        if (token == null) return;
        chatSocket.connect(token);
        callSocket.connect(token);
        _incomingCallSub ??= callSocket.onIncomingCall.listen(
          _handleIncomingCall,
        );
      } catch (e) {
        // Socket setup failing (e.g. a timed-out network) shouldn't take
        // down the app — real-time features just stay off this session.
        debugPrint('Socket connect failed: $e');
      }
    });

    return authState.when(
      loading: () => const _SplashScreen(),
      error: (_, _) => const WelcomeScreen(),
      data: (state) {
        final user = state.user;
        if (user == null) return const WelcomeScreen();
        return user.isEmailVerified
            ? const MainShellScreen()
            : VerifyEmailScreen(email: user.email);
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
    );
  }
}
