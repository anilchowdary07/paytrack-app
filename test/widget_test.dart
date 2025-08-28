// PayTrack App Widget Test
import 'package:flutter_test/flutter_test.dart';
import 'package:paytrack_premium/main.dart';

void main() {
  testWidgets('PayTrack Premium app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(PayTrackPremiumApp());

    // Verify that our app starts with welcome screen.
    expect(find.text('PayTrack Premium'), findsOneWidget);
    expect(find.text('Your Smart Finance Companion'), findsOneWidget);

    // Wait for the timer to complete and pump to next screen
    await tester.pump(const Duration(seconds: 3));

    // Should now be on login screen
    expect(find.text('Welcome Back!'), findsOneWidget);
  });
}
