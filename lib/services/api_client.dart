import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/environment.dart';
import '../core/constants/app_config.dart';
import '../core/utils/logger.dart';

/// Centralized API client for making secure backend API calls.
/// Automatically refreshes access tokens on 401 and retries the request once.
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static Duration get _defaultTimeout => AppConfig.apiTimeout;

  // Auth token management
  String? _authToken;
  bool _isRefreshing = false;

  /// Callback set by AuthNotifier to handle forced logout (e.g. refresh token expired).
  void Function()? onForceLogout;

  void setAuthToken(String? token) {
    _authToken = token;
  }

  String? get authToken => _authToken;

  /// Get headers with authentication and client type.
  Map<String, String> _getHeaders() {
    final headers = {
      'Content-Type': 'application/json',
      'X-Client-Type': 'app',
    };

    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }

  /// Make GET request
  Future<http.Response> get(
    String endpoint, {
    Map<String, String>? queryParameters,
    Duration? timeout,
  }) async {
    return _requestWithRetry(() async {
      final uri = Uri.parse(
        '${EnvironmentConfig.apiV1Url}$endpoint',
      ).replace(queryParameters: queryParameters);

      AppLogger.info('→ GET $uri', tag: 'API');
      if (kDebugMode) print('[API] → GET $uri');
      final response = await http
          .get(uri, headers: _getHeaders())
          .timeout(timeout ?? _defaultTimeout);

      _logResponse('GET', uri.toString(), response);
      _handleResponseErrors(response);
      return response;
    });
  }

  /// Make POST request
  Future<http.Response> post(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    return _requestWithRetry(() async {
      final uri = Uri.parse('${EnvironmentConfig.apiV1Url}$endpoint');

      AppLogger.info('→ POST $uri  body=${_summarize(body)}', tag: 'API');
      if (kDebugMode) print('[API] → POST $uri  body=${_summarize(body)}');
      final response = await http
          .post(
            uri,
            headers: _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _defaultTimeout);

      _logResponse('POST', uri.toString(), response);
      _handleResponseErrors(response);
      return response;
    });
  }

  /// Make PUT request
  Future<http.Response> put(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    return _requestWithRetry(() async {
      final uri = Uri.parse('${EnvironmentConfig.apiV1Url}$endpoint');

      AppLogger.info('→ PUT $uri  body=${_summarize(body)}', tag: 'API');
      if (kDebugMode) print('[API] → PUT $uri  body=${_summarize(body)}');
      final response = await http
          .put(
            uri,
            headers: _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _defaultTimeout);

      _logResponse('PUT', uri.toString(), response);
      _handleResponseErrors(response);
      return response;
    });
  }

  /// Make DELETE request
  Future<http.Response> delete(String endpoint, {Duration? timeout}) async {
    return _requestWithRetry(() async {
      final uri = Uri.parse('${EnvironmentConfig.apiV1Url}$endpoint');

      AppLogger.info('→ DELETE $uri', tag: 'API');
      if (kDebugMode) print('[API] → DELETE $uri');
      final response = await http
          .delete(uri, headers: _getHeaders())
          .timeout(timeout ?? _defaultTimeout);

      _logResponse('DELETE', uri.toString(), response);
      _handleResponseErrors(response);
      return response;
    });
  }

  /// Make PATCH request
  Future<http.Response> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    Duration? timeout,
  }) async {
    return _requestWithRetry(() async {
      final uri = Uri.parse('${EnvironmentConfig.apiV1Url}$endpoint');

      AppLogger.info('→ PATCH $uri  body=${_summarize(body)}', tag: 'API');
      if (kDebugMode) print('[API] → PATCH $uri  body=${_summarize(body)}');
      final response = await http
          .patch(
            uri,
            headers: _getHeaders(),
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout ?? _defaultTimeout);

      _logResponse('PATCH', uri.toString(), response);
      _handleResponseErrors(response);
      return response;
    });
  }

  /// Logs a response with status code and a body preview.
  void _logResponse(String method, String url, http.Response response) {
    final statusCode = response.statusCode;
    final bodyPreview = response.body.length > 500
        ? '${response.body.substring(0, 500)}…'
        : response.body;
    final ok = statusCode >= 200 && statusCode < 300;
    final line = '← $method [$statusCode] $url\n   body: $bodyPreview';
    if (kDebugMode) print('[API${ok ? '' : '-ERR'}] $line');
    AppLogger.info(line, tag: ok ? 'API' : 'API-ERR');
  }

  /// Returns a short summary of a request body for logging (hides sensitive keys).
  String _summarize(Map<String, dynamic>? body) {
    if (body == null) return 'null';
    final safe = Map<String, dynamic>.from(body)
      ..remove('password')
      ..remove('refreshToken')
      ..remove('token');
    final preview = jsonEncode(safe);
    return preview.length > 200 ? '${preview.substring(0, 200)}…' : preview;
  }

  /// Execute a request and automatically retry once on 401 after refreshing tokens.
  Future<http.Response> _requestWithRetry(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      return await requestFn();
    } on SocketException catch (_) {
      throw ApiException(
        'Unable to connect to server. Please check your internet connection.',
        0,
      );
    } on TimeoutException catch (_) {
      throw ApiException(
        'Connection timed out. Please check your internet connection and try again.',
        0,
      );
    } on HandshakeException catch (_) {
      throw ApiException('Secure connection failed. Please try again.', 0);
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        // Attempt token refresh
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry the original request with the new token
          return await requestFn();
        }
        // Refresh failed — force logout
        onForceLogout?.call();
      }
      rethrow;
    } on Object catch (e) {
      AppLogger.error('API Error: $e', tag: 'API', error: e);
      rethrow;
    }
  }

  /// Attempt to refresh the access token using the stored refresh token.
  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      const storage = FlutterSecureStorage();
      final refreshToken = await storage.read(key: 'auth_refresh_token');
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final uri = Uri.parse('${EnvironmentConfig.apiV1Url}/auth/refresh');
      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'X-Client-Type': 'app',
            },
            body: jsonEncode({'refreshToken': refreshToken}),
          )
          .timeout(_defaultTimeout);

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = body['data'] as Map<String, dynamic>?;
        if (data != null) {
          final newAccessToken = data['accessToken'] as String?;
          final newRefreshToken = data['refreshToken'] as String?;
          if (newAccessToken != null) {
            _authToken = newAccessToken;
            await storage.write(
              key: 'auth_access_token',
              value: newAccessToken,
            );
            if (newRefreshToken != null) {
              await storage.write(
                key: 'auth_refresh_token',
                value: newRefreshToken,
              );
            }
            AppLogger.info('Token refreshed successfully', tag: 'API');
            return true;
          }
        }
      }
      return false;
    } on Object catch (e) {
      AppLogger.error('Token refresh failed: $e', tag: 'API', error: e);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  /// Handle HTTP response errors
  void _handleResponseErrors(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    String errorMessage = 'Request failed';

    try {
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      errorMessage = responseData['message'] ?? errorMessage;
    } on Object catch (_) {
      errorMessage = response.body.isNotEmpty
          ? response.body
          : 'HTTP ${response.statusCode}';
    }

    switch (response.statusCode) {
      case 401:
        throw ApiException('Unauthorized: $errorMessage', 401);
      case 403:
        throw ApiException('Forbidden: $errorMessage', 403);
      case 404:
        throw ApiException('Not found: $errorMessage', 404);
      case 500:
        throw ApiException('Server error: $errorMessage', 500);
      default:
        throw ApiException(errorMessage, response.statusCode);
    }
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;

  ApiException(this.message, this.statusCode);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}
