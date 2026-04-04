import 'dart:developer' as developer;

/// Centralized API diagnostics logger for console/terminal output.
///
/// Tracks and logs:
/// - Per-field data source (which API provided each extracted field)
/// - Every API call with timing, status code, and endpoint
/// - 429 (rate limit) errors with request counts before hitting the limit
/// - Session-level usage counters (per-session, per-minute rates)
class ApiDiagnosticsLogger {
  // Singleton
  static final ApiDiagnosticsLogger _instance =
      ApiDiagnosticsLogger._internal();
  factory ApiDiagnosticsLogger() => _instance;
  ApiDiagnosticsLogger._internal();

  static const String _tag = '🔧 API-DIAG';

  // ═══════════════════════════════════════════════════════════════
  //  SESSION COUNTERS
  // ═══════════════════════════════════════════════════════════════

  int _sessionOpenAiCalls = 0;
  int _sessionBarcodeCalls = 0;
  int _sessionOpenAi429Count = 0;
  int _sessionBarcode429Count = 0;
  final DateTime _sessionStart = DateTime.now();
  final List<DateTime> _openAiCallTimestamps = [];
  final List<DateTime> _barcodeCallTimestamps = [];

  // ═══════════════════════════════════════════════════════════════
  //  API CALL LOGGING
  // ═══════════════════════════════════════════════════════════════

  /// Log an OpenAI API call with full diagnostics.
  void logOpenAiCall({
    required String endpoint,
    required String model,
    required int statusCode,
    required Duration responseTime,
    String? purpose,
    int? retryAfterSeconds,
  }) {
    _sessionOpenAiCalls++;
    _openAiCallTimestamps.add(DateTime.now());

    final perMinute = _getCallsPerMinute(_openAiCallTimestamps);

    _log(
      '╔══════════════════════════════════════════════════════\n'
      '║ 🤖 OPENAI API CALL\n'
      '║ Purpose     : ${purpose ?? 'General'}\n'
      '║ Model       : $model\n'
      '║ Endpoint    : $endpoint\n'
      '║ Status      : $statusCode${statusCode == 429
          ? ' ⚠️ RATE LIMITED'
          : statusCode == 200
          ? ' ✅'
          : ' ❌'}\n'
      '║ Response    : ${responseTime.inMilliseconds}ms\n'
      '║ Session     : $_sessionOpenAiCalls total | ${perMinute.toStringAsFixed(1)}/min\n'
      '║ 429 Errors  : $_sessionOpenAi429Count this session\n'
      '╚══════════════════════════════════════════════════════',
    );

    if (statusCode == 429) {
      _sessionOpenAi429Count++;
      _logRateLimitHit(
        api: 'OpenAI',
        totalCallsBefore: _sessionOpenAiCalls - 1,
        perMinute: perMinute,
        retryAfterSeconds: retryAfterSeconds,
      );
    }
  }

  /// Log a Barcode Lookup API call with full diagnostics.
  void logBarcodeApiCall({
    required String endpoint,
    required Map<String, String> params,
    required int statusCode,
    required Duration responseTime,
    int? retryAfterSeconds,
  }) {
    _sessionBarcodeCalls++;
    _barcodeCallTimestamps.add(DateTime.now());

    final perMinute = _getCallsPerMinute(_barcodeCallTimestamps);
    final paramStr = params.entries
        .where((e) => e.key != 'key') // Don't log API key
        .map((e) => '${e.key}=${e.value}')
        .join(', ');

    _log(
      '╔══════════════════════════════════════════════════════\n'
      '║ 🔍 BARCODE API CALL\n'
      '║ Params      : $paramStr\n'
      '║ Endpoint    : $endpoint\n'
      '║ Status      : $statusCode${statusCode == 429
          ? ' ⚠️ RATE LIMITED'
          : statusCode == 200
          ? ' ✅'
          : ' ❌'}\n'
      '║ Response    : ${responseTime.inMilliseconds}ms\n'
      '║ Session     : $_sessionBarcodeCalls total | ${perMinute.toStringAsFixed(1)}/min\n'
      '║ 429 Errors  : $_sessionBarcode429Count this session\n'
      '╚══════════════════════════════════════════════════════',
    );

    if (statusCode == 429) {
      _sessionBarcode429Count++;
      _logRateLimitHit(
        api: 'Barcode Lookup',
        totalCallsBefore: _sessionBarcodeCalls - 1,
        perMinute: perMinute,
        retryAfterSeconds: retryAfterSeconds,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════════
  //  EXTRACTION RESULTS LOGGING
  // ═══════════════════════════════════════════════════════════════

  /// Log per-field data source after extraction completes.
  /// [fieldSources] maps field names to their source API.
  void logExtractionResults({
    required Map<String, String> fieldValues,
    required Map<String, String> fieldSources,
    required String overallSource,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('╔══════════════════════════════════════════════════════');
    buffer.writeln('║ 📋 EXTRACTION RESULTS');
    buffer.writeln('║ Overall Source: $overallSource');
    buffer.writeln('║ ──────────────────────────────────────────────────');

    for (final field in fieldValues.entries) {
      if (field.value.isNotEmpty) {
        final source = fieldSources[field.key] ?? 'Unknown';
        final sourceIcon = source.contains('Barcode')
            ? '🟢'
            : source.contains('ChatGPT')
            ? '🔵'
            : '⚪';
        buffer.writeln(
          '║ $sourceIcon ${field.key.padRight(18)} : ${_truncate(field.value, 40)} [$source]',
        );
      }
    }

    buffer.writeln('╚══════════════════════════════════════════════════════');
    _log(buffer.toString());
  }

  /// Log extraction results from a LabelExtractionResult-like data.
  void logLabelExtractionResults({
    required String brand,
    required String model,
    required String serial,
    required String barcode,
    required String productType,
    String? productTitle,
    String? manufacturer,
    String? color,
    required String enrichmentSource,
    required bool barcodeApiSuccess,
    required Map<String, String?> fieldSources,
  }) {
    final fields = <String, String>{
      'Brand': brand,
      'Model': model,
      'Serial': serial,
      'Barcode': barcode,
      'Type': productType,
      'Product Title': ?productTitle,
      'Manufacturer': ?manufacturer,
      'Color': ?color,
    };

    final sources = <String, String>{};
    for (final entry in fieldSources.entries) {
      if (entry.value != null) {
        sources[entry.key] = entry.value!;
      }
    }

    logExtractionResults(
      fieldValues: fields,
      fieldSources: sources,
      overallSource: enrichmentSource,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  RATE LIMIT DIAGNOSTICS
  // ═══════════════════════════════════════════════════════════════

  void _logRateLimitHit({
    required String api,
    required int totalCallsBefore,
    required double perMinute,
    int? retryAfterSeconds,
  }) {
    final sessionDuration = DateTime.now().difference(_sessionStart);
    final retryLine = retryAfterSeconds != null
        ? '║ Retry after         : ${retryAfterSeconds}s (access at ${DateTime.now().add(Duration(seconds: retryAfterSeconds)).toIso8601String()})\n'
        : '║ Retry after         : Not specified by server\n';

    _log(
      '╔══════════════════════════════════════════════════════\n'
      '║ ⚠️  429 RATE LIMIT HIT — $api\n'
      '║ ──────────────────────────────────────────────────\n'
      '║ Requests before 429 : $totalCallsBefore\n'
      '║ Rate (calls/min)    : ${perMinute.toStringAsFixed(1)}\n'
      '$retryLine'
      '║ Session duration    : ${_formatDuration(sessionDuration)}\n'
      '║ Timestamp           : ${DateTime.now().toIso8601String()}\n'
      '╚══════════════════════════════════════════════════════',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  SESSION SUMMARY
  // ═══════════════════════════════════════════════════════════════

  /// Log a summary of all API usage in the current session.
  void logSessionSummary() {
    final sessionDuration = DateTime.now().difference(_sessionStart);
    final openAiPerMin = _getCallsPerMinute(_openAiCallTimestamps);
    final barcodePerMin = _getCallsPerMinute(_barcodeCallTimestamps);

    _log(
      '╔══════════════════════════════════════════════════════\n'
      '║ 📊 SESSION API USAGE SUMMARY\n'
      '║ ──────────────────────────────────────────────────\n'
      '║ Session Duration : ${_formatDuration(sessionDuration)}\n'
      '║ ──────────────────────────────────────────────────\n'
      '║ OpenAI:\n'
      '║   Total calls    : $_sessionOpenAiCalls\n'
      '║   Rate           : ${openAiPerMin.toStringAsFixed(1)} calls/min\n'
      '║   429 Errors     : $_sessionOpenAi429Count\n'
      '║ ──────────────────────────────────────────────────\n'
      '║ Barcode API:\n'
      '║   Total calls    : $_sessionBarcodeCalls\n'
      '║   Rate           : ${barcodePerMin.toStringAsFixed(1)} calls/min\n'
      '║   429 Errors     : $_sessionBarcode429Count\n'
      '╚══════════════════════════════════════════════════════',
    );
  }

  // ═══════════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════════

  double _getCallsPerMinute(List<DateTime> timestamps) {
    if (timestamps.isEmpty) return 0;
    // Only count calls in the last 60 seconds
    final now = DateTime.now();
    final recentCalls = timestamps
        .where((t) => now.difference(t).inSeconds <= 60)
        .length;
    return recentCalls.toDouble();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  String _truncate(String text, int maxLen) {
    if (text.length <= maxLen) return text;
    return '${text.substring(0, maxLen - 3)}...';
  }

  void _log(String message) {
    developer.log(message, name: _tag);
    // Also print to console/terminal for visibility in debug mode
    // ignore: avoid_print
    print('[$_tag] $message');
  }
}
