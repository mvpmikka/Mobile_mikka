import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mikka_mobile/main.dart';
import 'package:mikka_mobile/providers/auth_provider.dart';

// Bypasses the real AuthController (which hits secure storage/network) so
// AuthGate resolves straight to unauthenticated without ever showing the
// splash screen's indeterminate spinner — pumpAndSettle hangs forever
// while that's on screen since it never stops scheduling frames.
class _FakeAuthController extends AuthController {
  @override
  Future<AuthState> build() async => const AuthState.unauthenticated();
}

void main() {
  testWidgets('Welcome screen shows logo and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authControllerProvider.overrideWith(_FakeAuthController.new)],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('mikka'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
