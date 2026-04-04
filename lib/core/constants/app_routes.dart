/// Centralized route paths for the SquareTrade app
/// All navigation should use these constants instead of hardcoded strings
class AppRoutes {
  AppRoutes._(); // Private constructor to prevent instantiation

  // Authentication Routes
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';

  // Main Navigation Routes
  static const String home = '/home';
  static const String dashboard = '/dashboard';

  // Asset Management Routes
  static const String assets = '/assets';
  static const String assetDetail = '/asset-detail';
  static const String assetAdd = '/asset-add';
  static const String assetEdit = '/asset-edit';
  static const String assetHistory = '/asset-history';
  static const String assetMaintenance = '/asset-maintenance';

  // Service Routes
  static const String services = '/services';
  static const String serviceDetail = '/service-detail';
  static const String serviceRequest = '/service-request';
  static const String serviceHistory = '/service-history';
  static const String serviceTracking = '/service-tracking';

  // Shopping/Product Routes
  static const String shopping = '/shopping';
  static const String productList = '/products';
  static const String productDetail = '/product-detail';
  static const String productCompare = '/product-compare';
  static const String productSearch = '/product-search';

  // Cart & Checkout Routes
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String checkoutAddress = '/checkout/address';
  static const String checkoutPayment = '/checkout/payment';
  static const String checkoutReview = '/checkout/review';
  static const String checkoutSuccess = '/checkout-success';
  static const String orderDetail = '/order-detail';
  static const String orderHistory = '/orders';

  // Profile & Settings Routes
  static const String profile = '/profile';
  static const String profileEdit = '/profile-edit';
  static const String myClaims = '/my-claims';
  static const String settings = '/settings';
  static const String settingsNotifications = '/settings/notifications';
  static const String settingsPrivacy = '/settings/privacy';
  static const String settingsSecurity = '/settings/security';
  static const String settingsLanguage = '/settings/language';
  static const String settingsTheme = '/settings/theme';

  // Document Routes
  static const String documents = '/documents';
  static const String documentDetail = '/document-detail';
  static const String documentUpload = '/document-upload';

  // Warranty Routes
  static const String warranties = '/warranties';
  static const String warrantyDetail = '/warranty-detail';
  static const String warrantyAdd = '/warranty-add';

  // Insurance Routes
  static const String insurance = '/insurance';
  static const String insuranceDetail = '/insurance-detail';
  static const String insuranceQuote = '/insurance-quote';

  // Notification Routes
  static const String notifications = '/notifications';
  static const String notificationDetail = '/notification-detail';

  // Help & Support Routes
  static const String help = '/help';
  static const String helpCenter = '/help-center';
  static const String faq = '/faq';
  static const String contactSupport = '/contact-support';
  static const String feedback = '/feedback';

  // Legal Routes
  static const String termsOfService = '/terms-of-service';
  static const String privacyPolicy = '/privacy-policy';
  static const String about = '/about';

  // Error Routes
  static const String error = '/error';
  static const String notFound = '/404';
  static const String maintenance = '/maintenance';

  // Trade-in Routes
  static const String tradeIn = '/trade-in';
  static const String tradeInEvaluation = '/trade-in/evaluation';
  static const String tradeInHistory = '/trade-in/history';

  // Search Routes
  static const String search = '/search';
  static const String searchResults = '/search-results';
}
