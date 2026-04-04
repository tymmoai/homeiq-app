import '../config/environment.dart';
import 'app_strings.dart';

/// App configuration constants.
/// ─────────────────────────────────────────────────────────────────────────────
/// Environment variables, API settings, and app-wide configurations.
/// Brand name / version come from [AppStrings] so there is ONE source of truth.
/// ─────────────────────────────────────────────────────────────────────────────
class AppConfig {
  AppConfig._();

  // ==================== ENVIRONMENT ====================

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'development',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // ==================== APP INFO (delegated to AppStrings) ====================

  static String get appName => AppStrings.appName;
  static String get appVersion => AppStrings.appVersion;
  static const String appBuildNumber = '1';
  static const String packageName = 'com.squaretrade.app';

  // ==================== API CONFIGURATION ====================

  /// Base URL for API endpoints — delegates to [EnvironmentConfig] so there
  /// is a single source of truth with proper platform-aware defaults.
  static String get baseUrl => EnvironmentConfig.apiBaseUrl;

  /// API version
  static const String apiVersion = 'v1';

  /// Full API v1 URL — delegates to [EnvironmentConfig].
  static String get apiUrl => EnvironmentConfig.apiV1Url;

  /// API timeout duration
  static const Duration apiTimeout = Duration(seconds: 30);

  /// API retry attempts
  static const int apiRetryAttempts = 3;

  /// API retry delay
  static const Duration apiRetryDelay = Duration(seconds: 2);

  // ==================== API ENDPOINTS ====================
  
  // Authentication
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String logoutEndpoint = '/auth/logout';
  static const String refreshTokenEndpoint = '/auth/refresh';
  static const String forgotPasswordEndpoint = '/auth/forgot-password';
  static const String resetPasswordEndpoint = '/auth/reset-password';

  // Assets
  static const String assetsEndpoint = '/assets';
  static const String assetDetailEndpoint = '/assets/:id';
  static const String assetCreateEndpoint = '/assets';
  static const String assetUpdateEndpoint = '/assets/:id';
  static const String assetDeleteEndpoint = '/assets/:id';

  // Products
  static const String productsEndpoint = '/products';
  static const String productDetailEndpoint = '/products/:id';
  static const String productSearchEndpoint = '/products/search';
  static const String productCategoriesEndpoint = '/products/categories';

  // Orders
  static const String ordersEndpoint = '/orders';
  static const String orderDetailEndpoint = '/orders/:id';
  static const String orderCreateEndpoint = '/orders';
  static const String orderTrackingEndpoint = '/orders/:id/tracking';

  // Services
  static const String servicesEndpoint = '/services';
  static const String serviceRequestEndpoint = '/services/request';
  static const String serviceHistoryEndpoint = '/services/history';

  // User
  static const String profileEndpoint = '/user/profile';
  static const String updateProfileEndpoint = '/user/profile';
  static const String changePasswordEndpoint = '/user/change-password';

  // Notifications
  static const String notificationsEndpoint = '/notifications';
  static const String notificationReadEndpoint = '/notifications/:id/read';

  // ==================== PAGINATION ====================
  
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int minPageSize = 10;

  // ==================== CACHE ====================
  
  static const Duration cacheExpiry = Duration(hours: 1);
  static const Duration imageCacheExpiry = Duration(days: 7);
  static const int maxCacheSize = 100; // MB
  static const bool enableCache = true;

  // ==================== STORAGE KEYS ====================
  
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userNameKey = 'user_name';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language';
  static const String notificationsEnabledKey = 'notifications_enabled';
  static const String biometricsEnabledKey = 'biometrics_enabled';

  // ==================== FEATURES FLAGS ====================
  
  static const bool enableBiometrics = true;
  static const bool enablePushNotifications = true;
  static const bool enableAnalytics = true;
  static const bool enableCrashReporting = true;
  static const bool enableOfflineMode = true;
  static const bool enableDarkMode = true;
  static const bool enableMultiLanguage = false;

  // ==================== VALIDATION ====================
  
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 64;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 30;
  static const int maxEmailLength = 255;
  static const int maxPhoneLength = 15;
  
  // ==================== FILE UPLOAD ====================
  
  static const int maxFileSize = 10 * 1024 * 1024; // 10 MB
  static const int maxImageSize = 5 * 1024 * 1024; // 5 MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50 MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> allowedDocumentFormats = ['pdf', 'doc', 'docx', 'txt'];
  
  // ==================== MAP & LOCATION ====================
  
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
  
  static const double defaultLatitude = 37.7749; // San Francisco
  static const double defaultLongitude = -122.4194;
  static const double defaultMapZoom = 15.0;
  
  // ==================== PAYMENT ====================
  
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: '',
  );
  
  static const String paypalClientId = String.fromEnvironment(
    'PAYPAL_CLIENT_ID',
    defaultValue: '',
  );
  
  // ==================== ANALYTICS ====================
  
  static const String googleAnalyticsId = String.fromEnvironment(
    'GOOGLE_ANALYTICS_ID',
    defaultValue: '',
  );
  
  static const String mixpanelToken = String.fromEnvironment(
    'MIXPANEL_TOKEN',
    defaultValue: '',
  );
  
  // ==================== SOCIAL ====================
  
  static const String facebookAppId = String.fromEnvironment(
    'FACEBOOK_APP_ID',
    defaultValue: '',
  );
  
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
  
  // ==================== SUPPORT ====================
  
  static String get supportEmail => AppStrings.supportEmail;
  static String get supportPhone => AppStrings.supportPhone;
  static const String websiteUrl = 'https://www.squaretrade.com';
  static const String privacyPolicyUrl = 'https://www.squaretrade.com/privacy';
  static const String termsOfServiceUrl = 'https://www.squaretrade.com/terms';
  
  // ==================== DEBUG ====================
  
  static const bool enableDebugMode = bool.fromEnvironment(
    'DEBUG_MODE',
    defaultValue: false,
  );
  
  static const bool enableNetworkLogging = bool.fromEnvironment(
    'NETWORK_LOGGING',
    defaultValue: false,
  );
  
  static const bool enablePerformanceMonitoring = true;
}
