import 'dart:convert';

import '../models/api_models.dart';
import 'api_client.dart';

/// Service for Home CRUD operations against backend-client `/api/v1/homes`.
class HomeApiService {
  HomeApiService._();
  static final HomeApiService instance = HomeApiService._();

  final _api = ApiClient();

  /// Fetch all homes belonging to the authenticated user.
  Future<List<HomeDto>> getHomes() async {
    final response = await _api.get('/homes');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as List;
    return data
        .map((h) => HomeDto.fromJson(h as Map<String, dynamic>))
        .toList();
  }

  /// Create a new home.
  Future<HomeDto> createHome({
    String? name,
    required String address,
    required String city,
    required String state,
    required String zip,
    String country = 'US',
    int? yearBuilt,
    int? sqft,
  }) async {
    final response = await _api.post(
      '/homes',
      body: {
        if (name != null && name.isNotEmpty) 'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zip': zip,
        'country': country,
        'yearBuilt': ?yearBuilt,
        'sqft': ?sqft,
      },
    );
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Get a single home by ID (includes its assets).
  Future<HomeDto> getHome(String id) async {
    final response = await _api.get('/homes/$id');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Update a home.
  Future<HomeDto> updateHome(String id, Map<String, dynamic> data) async {
    final response = await _api.put('/homes/$id', body: data);
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return HomeDto.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Delete a home (owner only).
  Future<void> deleteHome(String id) async {
    await _api.delete('/homes/$id');
  }
}
