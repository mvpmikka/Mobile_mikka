import 'package:flutter_test/flutter_test.dart';

import 'package:mikka_mobile/main.dart';

void main() {
  testWidgets('Welcome screen shows logo and action buttons', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('mikka'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
  });
}
