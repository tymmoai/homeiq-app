// API smoke tests — equivalent of Playwright's test/api/health.api.spec.ts
// These run as standard Dart unit tests (no device needed).
//
// Run: flutter test test/api/
// Requires API server running at API_BASE_URL env var (default: http://localhost:3000)

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  final baseUrl = Platform.environment['API_BASE_URL'] ?? 'http://localhost:3000';

  group('Health API', () {
    test('GET /api/v1/health — returns 200 and status ok', () async {
      final response = await http.get(Uri.parse('$baseUrl/api/v1/health'));

      expect(response.statusCode, equals(200));
      final body = json.decode(response.body) as Map<String, dynamic>;
      expect(body['status'], equals('ok'));
    });
  });

  group('Auth API', () {
    test('POST /api/v1/auth/login — returns 400 for missing body', () async {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({}),
      );

      // Missing email → validation error, not 500
      expect(response.statusCode, lessThan(500));
    });

    test('GET /api/v1/profile — returns 401 without token', () async {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/profile'),
        headers: {'Content-Type': 'application/json'},
      );

      expect(response.statusCode, equals(401));
    });
  });
}
