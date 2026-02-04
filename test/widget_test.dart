// Basic widget test for Rwanda Pet Lovers app

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:rwanda_pet_lovers/main.dart';

void main() {
  testWidgets('App smoke test - splash screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: RwandaPetLoversApp(),
      ),
    );

    // Verify the app title is present
    expect(find.text('Rwanda Pet Lovers'), findsOneWidget);
  });
}
