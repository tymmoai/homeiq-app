// ignore_for_file: unintended_html_in_doc_comment, dangling_library_doc_comments

/// Environment Configuration
/// Runtime values loaded from --dart-define flags at build time.
///
/// ─── HOW TO RUN ON EVERY DEVICE ──────────────────────────────────────────────
/// The API_BASE_URL must point to wherever the backend-client server is running.
///
///  1. Android emulator (built-in alias for host machine localhost):
///       flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5000
///
///  2. iOS simulator (shares host networking):
///       flutter run --dart-define=API_BASE_URL=http://localhost:5000
///
///  3. Physical device on the SAME Wi-Fi as your dev machine:
///       • Find your machine's LAN IP: ipconfig (Windows) / ifconfig (Mac)
///       flutter run --dart-define=API_BASE_URL=http://192.168.x.x:5000
///
///  4. Physical device on ANY network (localtunnel — no account needed):
///       cd packages/backend-client
///       npm run dev:tunnel       ← starts backend + tunnel, prints public URL
///       flutter run --dart-define=API_BASE_URL=https://<id>.loca.lt
///
///  5. Use VS Code launch profiles (.vscode/launch.json) — all of the above
///     are pre-configured in the Run & Debug panel (Ctrl+Shift+D).
/// ─────────────────────────────────────────────────────────────────────────────
class EnvironmentConfig {
  EnvironmentConfig._();

  // Backend API server base URL (no trailing slash, no /api path).
  // Default: localhost:5000 for Chrome/web dev. Override with --dart-define=API_BASE_URL=...
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );

  /// Full API v1 base path — used by all service classes.
  static String get apiV1Url => '$apiBaseUrl/api/v1';

  /// Alias for BackendApiClient compatibility.
  static String get backendClientBaseUrl => apiBaseUrl;

  // Environment type
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  // Timeouts
  static const Duration defaultTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(seconds: 60);
}
