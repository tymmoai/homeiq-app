// Integration test: Auth flow
// Equivalent of Playwright's e2e/auth/login.spec.ts
//
// Run: flutter test integration_test/auth/login_test.dart -d <device>
// CI:  flutter test integration_test/auth/login_test.dart -d flutter-tester

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth — Sign In Flow', () {
    testWidgets('should display sign-in form on launch', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // After splash, should land on sign-in screen
      expect(find.byType(TextFormField), findsAtLeastNWidgets(1));
    });

    testWidgets('should show OTP screen after entering valid email', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter email
      final emailField = find.byType(TextFormField).first;
      await tester.tap(emailField);
      await tester.enterText(emailField, 'test@example.com');
      await tester.pumpAndSettle();

      // Tap continue / submit button
      final continueBtn = find.byType(ElevatedButton).first;
      await tester.tap(continueBtn);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Should navigate to OTP screen (contains OTP input or "code" text)
      expect(
        find.textContaining(RegExp(r'code|verify|otp', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });

    testWidgets('should show validation error for empty email', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap submit without entering email
      final continueBtn = find.byType(ElevatedButton).first;
      await tester.tap(continueBtn);
      await tester.pumpAndSettle();

      // Should show a validation message
      expect(
        find.textContaining(RegExp(r'email|required|valid', caseSensitive: false)),
        findsAtLeastNWidgets(1),
      );
    });
  });
}
