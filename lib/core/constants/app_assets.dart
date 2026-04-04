/// Centralized asset paths for the SquareTrade app
/// All image, icon, and asset references should use these constants
class AppAssets {
  AppAssets._(); // Private constructor to prevent instantiation

  // Base paths
  static const String _imagesBase = 'assets/images';
  static const String _iconsBase = 'assets/icons';
  static const String _illustrationsBase = 'assets/illustrations';
  static const String _animationsBase = 'assets/animations';

  // ==================== IMAGES ====================
  
  // Logo & Branding
  static const String logo = 'lib/asset_img/logo.png';
  static const String logoWhite = '$_imagesBase/logo_white.png';
  static const String logoIcon = 'lib/asset_img/allstate_icon.jpg';
  static const String appIcon = 'lib/asset_img/allstate_icon.jpg';

  // Placeholder Images
  static const String placeholder = '$_imagesBase/placeholder.png';
  static const String imagePlaceholder = '$_imagesBase/image_placeholder.png';
  static const String avatarPlaceholder = '$_imagesBase/avatar_placeholder.png';
  static const String productPlaceholder = '$_imagesBase/product_placeholder.png';

  // Onboarding Images
  static const String onboarding1 = '$_imagesBase/onboarding_1.png';
  static const String onboarding2 = '$_imagesBase/onboarding_2.png';
  static const String onboarding3 = '$_imagesBase/onboarding_3.png';

  // Background Images
  static const String backgroundPattern = '$_imagesBase/background_pattern.png';
  static const String splashBackground = '$_imagesBase/splash_bg.png';

  // ==================== ICONS ====================
  
  // Navigation Icons
  static const String homeIcon = '$_iconsBase/home.svg';
  static const String assetsIcon = '$_iconsBase/assets.svg';
  static const String servicesIcon = '$_iconsBase/services.svg';
  static const String shoppingIcon = '$_iconsBase/shopping.svg';
  static const String profileIcon = '$_iconsBase/profile.svg';

  // Asset Category Icons
  static const String appliancesIcon = '$_iconsBase/appliances.svg';
  static const String plumbingIcon = '$_iconsBase/plumbing.svg';
  static const String electricalIcon = '$_iconsBase/electrical.svg';
  static const String hvacIcon = '$_iconsBase/hvac.svg';
  static const String structuralIcon = '$_iconsBase/structural.svg';
  static const String exteriorIcon = '$_iconsBase/exterior.svg';
  static const String safetyIcon = '$_iconsBase/safety.svg';

  // Action Icons
  static const String addIcon = '$_iconsBase/add.svg';
  static const String editIcon = '$_iconsBase/edit.svg';
  static const String deleteIcon = '$_iconsBase/delete.svg';
  static const String shareIcon = '$_iconsBase/share.svg';
  static const String downloadIcon = '$_iconsBase/download.svg';
  static const String uploadIcon = '$_iconsBase/upload.svg';

  // Status Icons
  static const String successIcon = '$_iconsBase/success.svg';
  static const String errorIcon = '$_iconsBase/error.svg';
  static const String warningIcon = '$_iconsBase/warning.svg';
  static const String infoIcon = '$_iconsBase/info.svg';

  // ==================== ILLUSTRATIONS ====================
  
  // Empty States
  static const String emptyAssets = '$_illustrationsBase/empty_assets.svg';
  static const String emptyCart = '$_illustrationsBase/empty_cart.svg';
  static const String emptyOrders = '$_illustrationsBase/empty_orders.svg';
  static const String emptyNotifications = '$_illustrationsBase/empty_notifications.svg';
  static const String emptySearch = '$_illustrationsBase/empty_search.svg';
  static const String noResults = '$_illustrationsBase/no_results.svg';
  static const String noInternet = '$_illustrationsBase/no_internet.svg';

  // Success States
  static const String orderSuccess = '$_illustrationsBase/order_success.svg';
  static const String paymentSuccess = '$_illustrationsBase/payment_success.svg';
  static const String registrationSuccess = '$_illustrationsBase/registration_success.svg';

  // Error States
  static const String error404 = '$_illustrationsBase/error_404.svg';
  static const String error500 = '$_illustrationsBase/error_500.svg';
  static const String errorGeneral = '$_illustrationsBase/error_general.svg';
  static const String maintenance = '$_illustrationsBase/maintenance.svg';

  // Process Illustrations
  static const String loading = '$_illustrationsBase/loading.svg';
  static const String processing = '$_illustrationsBase/processing.svg';
  static const String uploading = '$_illustrationsBase/uploading.svg';

  // Feature Illustrations
  static const String homeManagement = '$_illustrationsBase/home_management.svg';
  static const String serviceRequest = '$_illustrationsBase/service_request.svg';
  static const String shopping = '$_illustrationsBase/shopping.svg';
  static const String warranty = '$_illustrationsBase/warranty.svg';
  static const String insurance = '$_illustrationsBase/insurance.svg';

  // ==================== ANIMATIONS ====================
  
  // Lottie Animations
  static const String loadingAnimation = '$_animationsBase/loading.json';
  static const String successAnimation = '$_animationsBase/success.json';
  static const String errorAnimation = '$_animationsBase/error.json';
  static const String emptyAnimation = '$_animationsBase/empty.json';
  static const String searchAnimation = '$_animationsBase/search.json';

  // ==================== PRODUCT IMAGES ====================
  // Note: Product images are typically loaded from network/API
  // These are fallback/sample images
  
  static const String sampleProduct1 = '$_imagesBase/products/sample_1.png';
  static const String sampleProduct2 = '$_imagesBase/products/sample_2.png';
  static const String sampleProduct3 = '$_imagesBase/products/sample_3.png';

  // ==================== HELPER METHODS ====================
  
  /// Check if asset is SVG
  static bool isSvg(String assetPath) {
    return assetPath.endsWith('.svg');
  }

  /// Check if asset is image (PNG/JPG)
  static bool isImage(String assetPath) {
    return assetPath.endsWith('.png') || 
           assetPath.endsWith('.jpg') || 
           assetPath.endsWith('.jpeg');
  }

  /// Check if asset is Lottie animation
  static bool isLottie(String assetPath) {
    return assetPath.endsWith('.json');
  }
}
