import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import '../services/api_client.dart';

/// Keys for persisting user profile data.
const _nameKey = 'user_name';
const _emailKey = 'user_email';
const _phoneKey = 'user_phone';
const _countryCodeKey = 'user_country_code';
const _addressKey = 'user_address';
const _aptUnitKey = 'user_apartmentUnit';
const _cityKey = 'user_city';
const _stateKey = 'user_state';
const _zipCodeKey = 'user_zipCode';
const _profileImageKey = 'user_profile_image_path';
const _createdAtKey = 'user_created_at';

/// Immutable snapshot of user profile data.
class UserProfile {
  final String name;
  final String email;
  final String phone;
  final String countryCode;
  final String address;
  final String aptUnit;
  final String city;
  final String usState;
  final String zipCode;
  final String? profileImagePath;
  final String createdAt;

  const UserProfile({
    required this.name,
    required this.email,
    required this.phone,
    this.countryCode = '+1-US',
    this.address = '',
    this.aptUnit = '',
    this.city = '',
    this.usState = '',
    this.zipCode = '',
    this.profileImagePath,
    this.createdAt = '',
  });

  String getInitials() {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String getFirstName() {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts[0] : 'User';
  }

  bool get hasProfileImage =>
      profileImagePath != null && profileImagePath!.isNotEmpty;

  /// Formatted full address string (US standard).
  String get formattedAddress {
    final parts = <String>[];
    if (address.trim().isNotEmpty) parts.add(address.trim());
    if (aptUnit.trim().isNotEmpty) parts.add('Apt ${aptUnit.trim()}');
    if (city.trim().isNotEmpty || usState.trim().isNotEmpty || zipCode.trim().isNotEmpty) {
      final cityStateZip = <String>[];
      if (city.trim().isNotEmpty) cityStateZip.add(city.trim());
      if (usState.trim().isNotEmpty) cityStateZip.add(usState.trim());
      final csz = cityStateZip.join(', ');
      if (zipCode.trim().isNotEmpty) {
        parts.add('$csz ${zipCode.trim()}');
      } else {
        parts.add(csz);
      }
    }
    return parts.join(', ');
  }

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? countryCode,
    String? address,
    String? aptUnit,
    String? city,
    String? usState,
    String? zipCode,
    String? profileImagePath,
    bool clearProfileImage = false,
    String? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      countryCode: countryCode ?? this.countryCode,
      address: address ?? this.address,
      aptUnit: aptUnit ?? this.aptUnit,
      city: city ?? this.city,
      usState: usState ?? this.usState,
      zipCode: zipCode ?? this.zipCode,
      profileImagePath:
          clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Provides the current [UserProfile] across the app.
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UserProfileNotifier(prefs);
});

/// Manages user profile state and persists changes via SharedPreferences.
class UserProfileNotifier extends StateNotifier<UserProfile> {
  final SharedPreferences _prefs;

  UserProfileNotifier(this._prefs) : super(_loadFromPrefs(_prefs));

  static UserProfile _loadFromPrefs(SharedPreferences prefs) {
    return UserProfile(
      name: prefs.getString(_nameKey) ?? '',
      email: prefs.getString(_emailKey) ?? '',
      phone: prefs.getString(_phoneKey) ?? '',
      countryCode: prefs.getString(_countryCodeKey) ?? '+1-US',
      address: prefs.getString(_addressKey) ?? '',
      aptUnit: prefs.getString(_aptUnitKey) ?? '',
      city: prefs.getString(_cityKey) ?? '',
      usState: prefs.getString(_stateKey) ?? '',
      zipCode: prefs.getString(_zipCodeKey) ?? '',
      profileImagePath: prefs.getString(_profileImageKey),
      createdAt: prefs.getString(_createdAtKey) ?? '',
    );
  }

  /// Update the full profile and persist all fields.
  Future<void> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? countryCode,
    String? address,
    String? aptUnit,
    String? city,
    String? usState,
    String? zipCode,
    String? profileImagePath,
    bool clearProfileImage = false,
    String? createdAt,
  }) async {
    state = state.copyWith(
      name: name,
      email: email,
      phone: phone,
      countryCode: countryCode,
      address: address,
      aptUnit: aptUnit,
      city: city,
      usState: usState,
      zipCode: zipCode,
      profileImagePath: profileImagePath,
      clearProfileImage: clearProfileImage,
      createdAt: createdAt,
    );

    if (name != null) await _prefs.setString(_nameKey, name);
    if (email != null) await _prefs.setString(_emailKey, email);
    if (phone != null) await _prefs.setString(_phoneKey, phone);
    if (countryCode != null) await _prefs.setString(_countryCodeKey, countryCode);
    if (address != null) await _prefs.setString(_addressKey, address);
    if (aptUnit != null) await _prefs.setString(_aptUnitKey, aptUnit);
    if (city != null) await _prefs.setString(_cityKey, city);
    if (usState != null) await _prefs.setString(_stateKey, usState);
    if (zipCode != null) await _prefs.setString(_zipCodeKey, zipCode);
    if (createdAt != null) await _prefs.setString(_createdAtKey, createdAt);

    if (clearProfileImage) {
      await _prefs.remove(_profileImageKey);
    } else if (profileImagePath != null) {
      await _prefs.setString(_profileImageKey, profileImagePath);
    }
  }

  /// Fetches user profile from backend (`GET /api/v1/users/me`) and merges
  /// the response into the local state + SharedPreferences.
  ///
  /// Call this right after a successful login or on app restore.
  /// Silently swallows errors so the app still works offline.
  Future<void> loadFromBackend() async {
    try {
      final response = await ApiClient().get('/users/me');
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final userData = body['data'] as Map<String, dynamic>? ?? {};

      final name = (userData['name'] as String?)?.trim() ?? '';
      final email = (userData['email'] as String?)?.trim() ?? '';
      final phone = (userData['phone'] as String?)?.trim() ?? '';
      // avatarUrl is a network URL or null from the backend.
      final avatarUrl = userData['avatarUrl'] as String?;
      final createdAt = userData['createdAt'] as String? ?? '';
      final userId = userData['id'] as String? ?? '';

      // Persist user ID for downstream use.
      if (userId.isNotEmpty) await _prefs.setString('user_id', userId);

      // Build update, preserving existing local fields (address, city, etc.)
      // that the backend User model does not store.
      await updateProfile(
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        // Only update phone if the backend has one; don't overwrite local data.
        phone: phone.isNotEmpty ? phone : null,
        // Store avatarUrl in profileImagePath so ProfileAvatar can detect it.
        // ProfileAvatar checks if the value starts with 'http' to decide
        // between Image.network and Image.file.
        profileImagePath: (avatarUrl != null && avatarUrl.isNotEmpty) ? avatarUrl : null,
        createdAt: createdAt.isNotEmpty ? createdAt : null,
      );

      debugPrint('[UserProfile] ✅ Profile loaded from backend: $name <$email>');
    } on Object catch (e) {
      // Silently fail — local SharedPreferences data remains in use.
      debugPrint('[UserProfile] ⚠️ Failed to load profile from backend: $e');
    }
  }

  /// Persists profile changes to backend (`PUT /api/v1/users/me`).
  ///
  /// Only fields supported by the backend schema are sent (name, phone, avatarUrl).
  /// Throws on backend error so callers can surface the error to the user.
  Future<void> saveToBackend({
    required String name,
    String? phone,
  }) async {
    final body = <String, dynamic>{
      'name': name,
    };
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;

    await ApiClient().put('/users/me', body: body);
    debugPrint('[UserProfile] ✅ Profile saved to backend');
  }

  /// Clears all profile data from state and SharedPreferences.
  /// Call this on logout so the next user starts with a clean slate.
  Future<void> clearProfile() async {
    state = const UserProfile(name: '', email: '', phone: '');
    await _prefs.remove(_nameKey);
    await _prefs.remove(_emailKey);
    await _prefs.remove(_phoneKey);
    await _prefs.remove(_countryCodeKey);
    await _prefs.remove(_addressKey);
    await _prefs.remove(_aptUnitKey);
    await _prefs.remove(_cityKey);
    await _prefs.remove(_stateKey);
    await _prefs.remove(_zipCodeKey);
    await _prefs.remove(_profileImageKey);
    await _prefs.remove(_createdAtKey);
    await _prefs.remove('user_id');
    debugPrint('[UserProfile] 🗑️ Profile cleared on logout');
  }
}
