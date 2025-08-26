// PayTrack App Widget Test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:payment_reminder_app/app.dart';
import 'package:payment_reminder_app/providers/theme_provider.dart';

void main() {
  testWidgets('PayTrack app smoke test', (WidgetTester tester) async {
    // Build our app with the required Provider and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ThemeProvider(),
        child: const MyApp(),
      ),
    );

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
