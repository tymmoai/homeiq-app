import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'core/config/environment.dart';
import 'core/constants/app_colors.dart';
import 'core/constants/app_dimensions.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'providers/button_layout_provider.dart';
import 'providers/theme_provider.dart';
import 'routes/app_router.dart';
import 'services/api_usage_tracker.dart';
import 'services/deep_link_service.dart';
import 'services/user_service.dart';
// Note: goRouterProvider is defined in app_router.dart

// Provider for SharedPreferences
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences not initialized');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize API usage tracker (loads persisted counts)
  await ApiUsageTracker().init();

  // Load persisted user data so returning users see their own profile.
  await UserService.instance.init();

  // Check backend connectivity (dev builds only — prevents URL leak in release)
  if (kDebugMode) {
    _checkBackendConnectivity();
  }

  // Initialise deep-link handler before runApp so cold-start links are caught.
  DeepLinkService.instance.init(rootNavigatorKey);
  
  runApp(
    ProviderScope(
      overrides: [
        // Override the sharedPreferencesProvider with actual instance
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const SquareTradeApp(),
    ),
  );
}

/// Checks if the Flutter app can reach the backend server.
/// Logs the result to the debug console (visible in terminal).
Future<void> _checkBackendConnectivity() async {
  const baseUrl = EnvironmentConfig.apiBaseUrl;
  debugPrint('');
  debugPrint('╔══════════════════════════════════════════════════════════════╗');
  debugPrint('║              BACKEND CONNECTIVITY CHECK                     ║');
  debugPrint('╠══════════════════════════════════════════════════════════════╣');
  debugPrint('║ Backend URL: $baseUrl');
  debugPrint('║ API Base:    ${EnvironmentConfig.apiV1Url}');

  try {
    final response = await http
        .get(Uri.parse('$baseUrl/health'))
        .timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      debugPrint('║ Status:      ✅ CONNECTED (${response.statusCode})');
      debugPrint('║ Response:    ${response.body.length > 80 ? response.body.substring(0, 80) : response.body}');
    } else {
      debugPrint('║ Status:      ⚠️  REACHABLE but returned ${response.statusCode}');
    }
  } on Object catch (e) {
    debugPrint('║ Status:      ❌ NOT CONNECTED');
    debugPrint('║ Error:       $e');
    debugPrint('║');
    debugPrint('║ Troubleshooting:');
    debugPrint('║ 1. Is the backend running? (cd packages/backend-client && npm run dev)');
    debugPrint('║ 2. Check API_BASE_URL matches your machine IP');
    debugPrint('║ 3. For physical device, use LAN IP (not localhost)');
    debugPrint('║ 4. For Android emulator, use http://10.0.2.2:5000');
  }

  debugPrint('╚══════════════════════════════════════════════════════════════╝');
  debugPrint('');
}

class SquareTradeApp extends ConsumerWidget {
  const SquareTradeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preset = ref.watch(themePresetProvider);
    final buttonLayout = ref.watch(buttonLayoutProvider);
    final themeData = AppTheme.fromPreset(preset, layout: buttonLayout);

    // Keep the static AppColors in sync so every file that references
    // AppColors.primary automatically picks up the dynamic theme color.
    AppColors.updateFromPreset(
      newPrimary: preset.primary,
      newPrimaryLight: preset.primaryLight,
      newPrimaryDark: preset.primaryDark,
      newAccent: preset.accent,
      newAccentDark: preset.accentDark,
      newAccentLight: preset.accentLight,
      brightness: preset.brightness,
    );

    // Keep badge radius in sync with the button layout selection.
    AppDimensions.updateBadgeRadius(buttonLayout.badgeRadius);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: themeData,
      darkTheme: preset.brightness == Brightness.dark ? themeData : null,
      themeMode: preset.brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      routerConfig: ref.watch(goRouterProvider),
    );
  }
}

