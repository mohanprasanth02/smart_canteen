import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_canteen/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame inside ProviderScope
    await tester.pumpWidget(
      const ProviderScope(
        child: SmartCanteenApp(),
      ),
    );

    // Verify we have the app loaded
    expect(find.byType(SmartCanteenApp), findsOneWidget);
  });
}
