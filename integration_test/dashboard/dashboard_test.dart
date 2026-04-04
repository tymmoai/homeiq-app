// Integration test: Dashboard / Home screen
// Equivalent of Playwright's e2e/dashboard/dashboard.spec.ts
//
// Run: flutter test integration_test/dashboard/dashboard_test.dart -d <device>

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:homeiq/main.dart' as app;
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Dashboard', () {
    testWidgets('should show home screen UI after authentication', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify bottom navigation bar exists (main app shell)
      expect(find.byType(BottomNavigationBar), findsOneWidget);
    });

    testWidgets('should display at least one asset card or empty state', (tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Either a list of assets or an empty state message
      final hasCards = find.byType(Card).evaluate().isNotEmpty;
      final hasEmptyState = find.textContaining(
        RegExp(r'no assets|add.*asset|get started', caseSensitive: false),
      ).evaluate().isNotEmpty;

      expect(hasCards || hasEmptyState, isTrue);
    });
  });
}
