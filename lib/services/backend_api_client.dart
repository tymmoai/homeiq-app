import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/environment.dart';
import '../core/utils/logger.dart';
import 'auth_api_service.dart';

/// Centralized HTTP client for backend-client CRUD API (port 3001).
///
/// All routes are prefixed with `/api/v1`.
/// Auth token is automatically attached from [AuthApiService].
class BackendApiClient {
  static final BackendApiClient _instance = BackendApiClient._internal();
  factory BackendApiClient() => _instance;
  BackendApiClient._internal();

  static const Duration _defaultTimeout = Duration(seconds: 30);

  /// Resolve the backend-client base URL.
  /// Uses `EnvironmentConfig.backendClientBaseUrl` (defaults to localhost:5000).
  String get _baseUrl => EnvironmentConfig.backendClientBaseUrl;

  /// Build full URL: `<baseUrl>/api/v1/<endpoint>`
  String _url(String endpoint) => '$_baseUrl/api/v1$endpoint';

  /// Build headers with auth token.
  Future<Map<String, String>> _getHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = await AuthApiService.instance.getAccessToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// Extract `data` field from standard `{ success, data, message }` response.
  /// Throws [BackendApiException] on error status codes.
  dynamic extractData(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body['data'];
    }

    final message = body['message'] as String? ?? 'Request failed';
    throw BackendApiException(message, response.statusCode);
  }

  // ── Logging helpers ─────────────────────────────────────────────────────────

  void _logRequest(
    String method,
    Uri uri, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) {
    final token = headers?['Authorization'];
    final auth = token != null ? 'JWT ${token.length} chars' : 'no auth';
    final bodyStr = body != null ? jsonEncode(body) : '-';
    AppLogger.debug(
      '>> $method ${uri.toString()}  [$auth]  body=$bodyStr',
      tag: 'API',
    );
  }

  void _logResponse(
    String method,
    String endpoint,
    http.Response response,
    Duration elapsed,
  ) {
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    final icon = ok ? '✓' : '✗';
    // Pretty-print JSON or fall back to raw (cap at 800 chars)
    String body = response.body;
    try {
      final decoded = jsonDecode(body) as Map<String, dynamic>;
      body = const JsonEncoder.withIndent('  ').convert(decoded);
    } on Object catch (_) {}
    if (body.length > 800) body = '${body.substring(0, 800)}... [+${body.length - 800} chars]';

    final log = ok ? AppLogger.info : AppLogger.warning;
    log(
      '$icon $method $endpoint  ${response.statusCode}  ${elapsed.inMilliseconds}ms\n$body',
      tag: 'API',
    );
  }

  // ── HTTP verbs ──────────────────────────────────────────────────────────────

  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(_url(endpoint))
        .replace(queryParameters: queryParameters);
    final headers = await _getHeaders();
    _logRequest('GET', uri, headers: headers);
    final sw = Stopwatch()..start();
    try {
      final response = await http
          .get(uri, headers: headers)
          .timeout(timeout ?? _defaultTimeout);
      sw.stop();
      _logResponse('GET', endpoint, response, sw.elapsed);
      return response;
    } on Object catch (e) {
      sw.stop();
      AppLogger.error(
        'GET $endpoint FAILED after ${sw.elapsedMilliseconds}ms → $e',
        tag: 'API',
        error: e,
      );
      rethrow;
    }
  }

  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(_url(endpoint));
    final headers = await _getHeaders();
    _logRequest('POST', uri, headers: headers, body: body);
    final sw = Stopwatch()..start();
    try {
      final response = await http
          .post(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _defaultTimeout);
      sw.stop();
      _logResponse('POST', endpoint, response, sw.elapsed);
      return response;
    } on Object catch (e) {
      sw.stop();
      AppLogger.error(
        'POST $endpoint FAILED after ${sw.elapsedMilliseconds}ms → $e',
        tag: 'API',
        error: e,
      );
      rethrow;
    }
  }

  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    final uri = Uri.parse(_url(endpoint));
    final headers = await _getHeaders();
    _logRequest('PUT', uri, headers: headers, body: body);
    final sw = Stopwatch()..start();
    try {
      final response = await http
          .put(
            uri,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _defaultTimeout);
      sw.stop();
      _logResponse('PUT', endpoint, response, sw.elapsed);
      return response;
    } on Object catch (e) {
      sw.stop();
      AppLogger.error(
        'PUT $endpoint FAILED after ${sw.elapsedMilliseconds}ms → $e',
        tag: 'API',
        error: e,
      );
      rethrow;
    }
  }

  Future<http.Response> delete(
    String endpoint, {
    Duration? timeout,
  }) async {
    final uri = Uri.parse(_url(endpoint));
    final headers = await _getHeaders();
    _logRequest('DELETE', uri, headers: headers);
    final sw = Stopwatch()..start();
    try {
      final response = await http
          .delete(uri, headers: headers)
          .timeout(timeout ?? _defaultTimeout);
      sw.stop();
      _logResponse('DELETE', endpoint, response, sw.elapsed);
      return response;
    } on Object catch (e) {
      sw.stop();
      AppLogger.error(
        'DELETE $endpoint FAILED after ${sw.elapsedMilliseconds}ms → $e',
        tag: 'API',
        error: e,
      );
      rethrow;
    }
  }
}

/// Exception for backend-client API errors.
class BackendApiException implements Exception {
  final String message;
  final int statusCode;

  BackendApiException(this.message, this.statusCode);

  @override
  String toString() => 'BackendApiException: $message (status $statusCode)';
}