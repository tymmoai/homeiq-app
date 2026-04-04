// Integration test entry point — equivalent of playwright.config.ts
// Run with: flutter test integration_test/ --device-id=<device>
//           flutter test integration_test/ -d chrome  (web)
//           flutter test integration_test/            (uses connected device)
//
// In CI: flutter test integration_test/ --dart-define=CI=true

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'auth/login_test.dart' as login;
import 'dashboard/dashboard_test.dart' as dashboard;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Auth', login.main);
  group('Dashboard', dashboard.main);
}
