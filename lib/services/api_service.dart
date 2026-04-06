import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants/app_config.dart';

/// API Service for handling HTTP requests.
///
/// Uses [AppConfig.apiUrl] which resolves to [EnvironmentConfig.apiV1Url]
/// so the correct base is always used regardless of environment.
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _accessToken;

  void setAccessToken(String? token) {
    _accessToken = token;
  }

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'X-Client-Type': 'app',
    if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
  };

  Future<Map<String, dynamic>> get(String endpoint) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConfig.apiUrl}$endpoint'), headers: _headers)
          .timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } on Object catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConfig.apiUrl}$endpoint'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } on Object catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await http
          .put(
            Uri.parse('${AppConfig.apiUrl}$endpoint'),
            headers: _headers,
            body: jsonEncode(data),
          )
          .timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } on Object catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http
          .delete(Uri.parse('${AppConfig.apiUrl}$endpoint'), headers: _headers)
          .timeout(AppConfig.apiTimeout);

      return _handleResponse(response);
    } on Object catch (e) {
      throw Exception('Network error: $e');
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) {
        return {'success': true};
      }
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw Exception('API error: ${response.statusCode} - ${response.body}');
    }
  }
}
