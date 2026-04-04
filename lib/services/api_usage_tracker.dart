import 'package:shared_preferences/shared_preferences.dart';

/// Tracks API request usage for OpenAI and Barcode Lookup APIs.
///
/// Persists counts to [SharedPreferences] so they survive app restarts.
/// Tracks per-month usage and resets automatically when the month changes.
///
/// Usage:
/// ```dart
/// final tracker = ApiUsageTracker();
/// await tracker.init();
/// tracker.recordOpenAiRequest();
/// print(tracker.openAiUsed);
/// ```
class ApiUsageTracker {
  // Singleton
  static final ApiUsageTracker _instance = ApiUsageTracker._internal();
  factory ApiUsageTracker() => _instance;
  ApiUsageTracker._internal();

  SharedPreferences? _prefs;
  bool _initialized = false;

  // ═══════════════════════════════════════════════════════════════
  //  STORAGE KEYS
  // ═══════════════════════════════════════════════════════════════

  static const _kOpenAiUsed = 'api_usage_openai_used';
  static const _kOpenAiVisionUsed = 'api_usage_openai_vision_used';
  static const _kOpenAiDalleUsed = 'api_usage_openai_dalle_used';
  static const _kBarcodeApiUsed = 'api_usage_barcode_used';
  static const _kTrackingMonth = 'api_usage_tracking_month';

  // ═══════════════════════════════════════════════════════════════
  //  DEFAULT LIMITS (configurable per plan)
  // ═══════════════════════════════════════════════════════════════

  // OpenAI (per minute — but we track monthly total for the user)
  // GPT-4o-mini: 500 RPM on Tier 1, 5000 RPM on Tier 2+
  // GPT-4o: 500 RPM on Tier 1, 5000 RPM on Tier 2+
  // DALL-E 3: 5 images/min on Tier 1, 7/min on Tier 2+
  //
  // We track monthly totals for user visibility.
  static const _kOpenAiLimit = 'api_usage_openai_limit';
  static const _kBarcodeApiLimit = 'api_usage_barcode_limit';

  // Default monthly limits (sensible defaults for paid plans)
  static const int defaultOpenAiMonthlyLimit = 500;
  static const int defaultBarcodeApiMonthlyLimit = 500;

  // ═══════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Must be called once before using the tracker (e.g., in main.dart).
  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
    _checkMonthReset();
  }

  /// Ensure prefs is loaded.
  void _ensureInit() {
    assert(_initialized, 'ApiUsageTracker.init() must be called first');
  }

  /// Reset counters if we're in a new month.
  void _checkMonthReset() {
    final currentMonth = _currentMonthKey();
    final storedMonth = _prefs?.getString(_kTrackingMonth);

    if (storedMonth != currentMonth) {
      // New month — reset all counters
      _prefs?.setInt(_kOpenAiUsed, 0);
      _prefs?.setInt(_kOpenAiVisionUsed, 0);
      _prefs?.setInt(_kOpenAiDalleUsed, 0);
      _prefs?.setInt(_kBarcodeApiUsed, 0);
      _prefs?.setString(_kTrackingMonth, currentMonth);
    }
  }

  String _currentMonthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════
  //  RECORD USAGE
  // ═══════════════════════════════════════════════════════════════

  /// Record a standard OpenAI ChatGPT call (gpt-4o-mini, gpt-4o text).
  void recordOpenAiRequest() {
    _ensureInit();
    _checkMonthReset();
    final current = _prefs?.getInt(_kOpenAiUsed) ?? 0;
    _prefs?.setInt(_kOpenAiUsed, current + 1);
  }

  /// Record an OpenAI Vision call (gpt-4o with image).
  void recordOpenAiVisionRequest() {
    _ensureInit();
    _checkMonthReset();
    final current = _prefs?.getInt(_kOpenAiVisionUsed) ?? 0;
    _prefs?.setInt(_kOpenAiVisionUsed, current + 1);
    // Also count toward total OpenAI
    recordOpenAiRequest();
  }

  /// Record a DALL-E image generation call.
  void recordDalleRequest() {
    _ensureInit();
    _checkMonthReset();
    final current = _prefs?.getInt(_kOpenAiDalleUsed) ?? 0;
    _prefs?.setInt(_kOpenAiDalleUsed, current + 1);
    // Also count toward total OpenAI
    recordOpenAiRequest();
  }

  /// Record a Barcode Lookup API call.
  void recordBarcodeApiRequest() {
    _ensureInit();
    _checkMonthReset();
    final current = _prefs?.getInt(_kBarcodeApiUsed) ?? 0;
    _prefs?.setInt(_kBarcodeApiUsed, current + 1);
  }

  // ═══════════════════════════════════════════════════════════════
  //  READ USAGE
  // ═══════════════════════════════════════════════════════════════

  /// Total OpenAI requests used this month (all types combined).
  int get openAiUsed {
    _ensureInit();
    _checkMonthReset();
    return _prefs?.getInt(_kOpenAiUsed) ?? 0;
  }

  /// OpenAI Vision requests used this month.
  int get openAiVisionUsed {
    _ensureInit();
    return _prefs?.getInt(_kOpenAiVisionUsed) ?? 0;
  }

  /// DALL-E requests used this month.
  int get dalleUsed {
    _ensureInit();
    return _prefs?.getInt(_kOpenAiDalleUsed) ?? 0;
  }

  /// Barcode API requests used this month.
  int get barcodeApiUsed {
    _ensureInit();
    _checkMonthReset();
    return _prefs?.getInt(_kBarcodeApiUsed) ?? 0;
  }

  // ═══════════════════════════════════════════════════════════════
  //  LIMITS
  // ═══════════════════════════════════════════════════════════════

  /// Monthly limit for OpenAI requests.
  int get openAiLimit {
    _ensureInit();
    return _prefs?.getInt(_kOpenAiLimit) ?? defaultOpenAiMonthlyLimit;
  }

  /// Monthly limit for Barcode API requests.
  int get barcodeApiLimit {
    _ensureInit();
    return _prefs?.getInt(_kBarcodeApiLimit) ?? defaultBarcodeApiMonthlyLimit;
  }

  /// Update the OpenAI monthly limit.
  Future<void> setOpenAiLimit(int limit) async {
    _ensureInit();
    await _prefs?.setInt(_kOpenAiLimit, limit);
  }

  /// Update the Barcode API monthly limit.
  Future<void> setBarcodeApiLimit(int limit) async {
    _ensureInit();
    await _prefs?.setInt(_kBarcodeApiLimit, limit);
  }

  // ═══════════════════════════════════════════════════════════════
  //  REMAINING
  // ═══════════════════════════════════════════════════════════════

  /// Remaining OpenAI requests this month.
  int get openAiRemaining => (openAiLimit - openAiUsed).clamp(0, openAiLimit);

  /// Remaining Barcode API requests this month.
  int get barcodeApiRemaining =>
      (barcodeApiLimit - barcodeApiUsed).clamp(0, barcodeApiLimit);

  /// Usage ratio (0.0 to 1.0) for OpenAI.
  double get openAiUsageRatio =>
      openAiLimit > 0 ? (openAiUsed / openAiLimit).clamp(0.0, 1.0) : 0.0;

  /// Usage ratio (0.0 to 1.0) for Barcode API.
  double get barcodeApiUsageRatio =>
      barcodeApiLimit > 0
          ? (barcodeApiUsed / barcodeApiLimit).clamp(0.0, 1.0)
          : 0.0;

  /// True if any API is near its limit (>80%).
  bool get isNearLimit =>
      openAiUsageRatio > 0.8 || barcodeApiUsageRatio > 0.8;

  /// True if any API has exceeded its limit.
  bool get isOverLimit =>
      openAiUsed >= openAiLimit || barcodeApiUsed >= barcodeApiLimit;

  // ═══════════════════════════════════════════════════════════════
  //  SNAPSHOT
  // ═══════════════════════════════════════════════════════════════

  /// Get a snapshot of all usage data for display.
  ApiUsageSnapshot get snapshot => ApiUsageSnapshot(
        openAiUsed: openAiUsed,
        openAiLimit: openAiLimit,
        openAiVisionUsed: openAiVisionUsed,
        dalleUsed: dalleUsed,
        barcodeApiUsed: barcodeApiUsed,
        barcodeApiLimit: barcodeApiLimit,
        trackingMonth: _prefs?.getString(_kTrackingMonth) ?? _currentMonthKey(),
      );

  // ═══════════════════════════════════════════════════════════════
  //  RESET
  // ═══════════════════════════════════════════════════════════════

  /// Manually reset all counters (e.g., for testing).
  Future<void> resetAll() async {
    _ensureInit();
    await _prefs?.setInt(_kOpenAiUsed, 0);
    await _prefs?.setInt(_kOpenAiVisionUsed, 0);
    await _prefs?.setInt(_kOpenAiDalleUsed, 0);
    await _prefs?.setInt(_kBarcodeApiUsed, 0);
    await _prefs?.setString(_kTrackingMonth, _currentMonthKey());
  }
}

/// Immutable snapshot of current API usage state, for passing to widgets.
class ApiUsageSnapshot {
  final int openAiUsed;
  final int openAiLimit;
  final int openAiVisionUsed;
  final int dalleUsed;
  final int barcodeApiUsed;
  final int barcodeApiLimit;
  final String trackingMonth;

  const ApiUsageSnapshot({
    required this.openAiUsed,
    required this.openAiLimit,
    required this.openAiVisionUsed,
    required this.dalleUsed,
    required this.barcodeApiUsed,
    required this.barcodeApiLimit,
    required this.trackingMonth,
  });

  int get openAiRemaining => (openAiLimit - openAiUsed).clamp(0, openAiLimit);
  int get barcodeApiRemaining =>
      (barcodeApiLimit - barcodeApiUsed).clamp(0, barcodeApiLimit);
  double get openAiRatio =>
      openAiLimit > 0 ? (openAiUsed / openAiLimit).clamp(0.0, 1.0) : 0.0;
  double get barcodeApiRatio =>
      barcodeApiLimit > 0
          ? (barcodeApiUsed / barcodeApiLimit).clamp(0.0, 1.0)
          : 0.0;
}
