import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/logger.dart';

/// Service to manage current user information
class UserService {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  /// Whether persisted data has been loaded into session cache.
  bool _initialized = false;

  // In-memory cache for current session user data (overrides defaults)
  static Map<String, dynamic>? _sessionUserData;

  // Fallback address from the currently selected home (used when profile has no address)
  String _selectedHomeAddress = '';
  String _selectedHomeCity = '';
  String _selectedHomeState = '';
  String _selectedHomeZip = '';

  // Default user data - empty until user registers
  static const Map<String, dynamic> _defaultUserData = {
    'id': '',
    'name': '',
    'email': '',
    'phone': '',
    'countryCode': '+1-US',
    'address': '',
    'city': '',
    'state': '',
    'zipCode': '',
    'apartmentUnit': '',
    'profileImage': '',
    'role': 'homeowner',
    'createdAt': '',
    'preferences': {
      'language': 'en',
      'theme': 'light',
      'colorTheme': 'default',
    },
  };

  /// Set user data for a newly signed-up user
  Future<void> setSignUpUserData({
    required String fullName,
    required String email,
    required String phone,
    String countryCode = '+1-US',
  }) async {
    _sessionUserData = {
      ..._defaultUserData,
      'name': fullName,
      'email': email,
      'phone': phone,
      'countryCode': countryCode,
      'createdAt': DateTime.now().toIso8601String(),
    };
    // Also persist
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_name', fullName);
    await prefs.setString('user_email', email);
    await prefs.setString('user_phone', phone);
    await prefs.setString('user_country_code', countryCode);
    await prefs.setString(
      'user_created_at',
      _sessionUserData!['createdAt'] as String,
    );
    await prefs.setBool('is_new_user', true);
  }

  /// Check if the current session is a new user (signed up, no data yet)
  Future<bool> isNewUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_new_user') ?? false;
  }

  /// Clear the new user flag (e.g. after the user adds their first asset)
  Future<void> clearNewUserFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_new_user', false);
  }

  /// Loads persisted user data from [SharedPreferences] into the in-memory
  /// session cache so that returning users see their own data instead of
  /// the hardcoded defaults.
  ///
  /// Safe to call multiple times — only runs once.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final prefs = await SharedPreferences.getInstance();
    final savedName = prefs.getString('user_name');

    // Only hydrate if the user has actually registered before.
    if (savedName != null) {
      _sessionUserData = {
        ..._defaultUserData,
        'name': savedName,
        'email': prefs.getString('user_email') ?? _defaultUserData['email'],
        'phone': prefs.getString('user_phone') ?? _defaultUserData['phone'],
        'countryCode':
            prefs.getString('user_country_code') ??
            _defaultUserData['countryCode'],
        'address':
            prefs.getString('user_address') ?? _defaultUserData['address'],
        'city': prefs.getString('user_city') ?? _defaultUserData['city'],
        'state': prefs.getString('user_state') ?? _defaultUserData['state'],
        'zipCode':
            prefs.getString('user_zipCode') ?? _defaultUserData['zipCode'],
        'apartmentUnit':
            prefs.getString('user_apartmentUnit') ??
            _defaultUserData['apartmentUnit'],
        'createdAt':
            prefs.getString('user_created_at') ?? _defaultUserData['createdAt'],
      };
    }
    // Load selected-home address fallback (populated by homeSelectionProvider)
    _selectedHomeAddress = prefs.getString('selected_home_address') ?? '';
    _selectedHomeCity = prefs.getString('selected_home_city') ?? '';
    _selectedHomeState = prefs.getString('selected_home_state') ?? '';
    _selectedHomeZip = prefs.getString('selected_home_zip') ?? '';
  }

  /// Get current user data
  Map<String, dynamic> getCurrentUserData() {
    if (_sessionUserData != null) {
      return Map<String, dynamic>.from(_sessionUserData!);
    }
    return Map<String, dynamic>.from(_defaultUserData);
  }

  /// Get user's full name
  String getUserName() {
    final name = getCurrentUserData()['name'] as String? ?? '';
    return name.isNotEmpty ? name : 'User';
  }

  /// Get user's first name
  String getFirstName() {
    final fullName = getUserName();
    final parts = fullName
        .trim()
        .split(' ')
        .where((p) => p.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts[0] : 'User';
  }

  /// Get user initials (first letter of first name + first letter of last name)
  String getInitials() {
    final fullName = getUserName().trim();
    if (fullName.isEmpty) return 'U';
    final parts = fullName.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  /// Get user's email
  String getUserEmail() {
    return getCurrentUserData()['email'] ?? '';
  }

  /// Get user's phone number
  String getUserPhone() {
    return getCurrentUserData()['phone'] ?? '';
  }

  /// Called by homeSelectionProvider whenever the selected home changes.
  /// Used as a fallback when the user's profile has no saved address.
  void setSelectedHomeAddress({
    required String address,
    required String city,
    required String state,
    required String zip,
  }) {
    _selectedHomeAddress = address;
    _selectedHomeCity = city;
    _selectedHomeState = state;
    _selectedHomeZip = zip;
  }

  /// Get user's address (falls back to selected home address if profile has none)
  String getUserAddress() {
    final profile = getCurrentUserData()['address'] as String? ?? '';
    return profile.isNotEmpty ? profile : _selectedHomeAddress;
  }

  /// Get user's city (falls back to selected home city if profile has none)
  String getUserCity() {
    final profile = getCurrentUserData()['city'] as String? ?? '';
    return profile.isNotEmpty ? profile : _selectedHomeCity;
  }

  /// Get user's state (falls back to selected home state if profile has none)
  String getUserState() {
    final profile = getCurrentUserData()['state'] as String? ?? '';
    return profile.isNotEmpty ? profile : _selectedHomeState;
  }

  /// Get user's zip code (falls back to selected home zip if profile has none)
  String getUserZipCode() {
    final profile = getCurrentUserData()['zipCode'] as String? ?? '';
    return profile.isNotEmpty ? profile : _selectedHomeZip;
  }

  /// Get user's apartment/unit number
  String getUserApartmentUnit() {
    return getCurrentUserData()['apartmentUnit'] ?? '';
  }

  /// Update user data (in real app this would sync to backend)
  Future<void> updateUserData(Map<String, dynamic> updates) async {
    // Update in-memory cache immediately
    _sessionUserData ??= Map<String, dynamic>.from(_defaultUserData);
    _sessionUserData!.addAll(updates);

    try {
      final prefs = await SharedPreferences.getInstance();

      // Save individual fields that might be updated from booking forms
      if (updates.containsKey('name')) {
        await prefs.setString('user_name', updates['name']);
      }
      if (updates.containsKey('email')) {
        await prefs.setString('user_email', updates['email']);
      }
      if (updates.containsKey('phone')) {
        await prefs.setString('user_phone', updates['phone']);
      }
      if (updates.containsKey('countryCode')) {
        await prefs.setString('user_country_code', updates['countryCode']);
      }
      if (updates.containsKey('address')) {
        await prefs.setString('user_address', updates['address']);
      }
      if (updates.containsKey('city')) {
        await prefs.setString('user_city', updates['city']);
      }
      if (updates.containsKey('state')) {
        await prefs.setString('user_state', updates['state']);
      }
      if (updates.containsKey('zipCode')) {
        await prefs.setString('user_zipCode', updates['zipCode']);
      }
      if (updates.containsKey('apartmentUnit')) {
        await prefs.setString('user_apartmentUnit', updates['apartmentUnit']);
      }
    } on Object catch (e) {
      // Handle error - in real app would log to crash reporting service
      AppLogger.error(
        'Error saving user data: $e',
        tag: 'UserService',
        error: e,
      );
    }
  }

  /// Load user data from persistent storage (for saved updates)
  Future<Map<String, dynamic>> loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = Map<String, dynamic>.from(_defaultUserData);

      // Override with any saved values
      final savedName = prefs.getString('user_name');
      if (savedName != null) userData['name'] = savedName;

      final savedEmail = prefs.getString('user_email');
      if (savedEmail != null) userData['email'] = savedEmail;

      final savedPhone = prefs.getString('user_phone');
      if (savedPhone != null) userData['phone'] = savedPhone;

      final savedAddress = prefs.getString('user_address');
      if (savedAddress != null) userData['address'] = savedAddress;

      final savedCity = prefs.getString('user_city');
      if (savedCity != null) userData['city'] = savedCity;

      final savedState = prefs.getString('user_state');
      if (savedState != null) userData['state'] = savedState;

      final savedZipCode = prefs.getString('user_zipCode');
      if (savedZipCode != null) userData['zipCode'] = savedZipCode;

      final savedApartmentUnit = prefs.getString('user_apartmentUnit');
      if (savedApartmentUnit != null) {
        userData['apartmentUnit'] = savedApartmentUnit;
      }

      return userData;
    } on Object catch (_) {
      // Handle error - return default data
      return Map<String, dynamic>.from(_defaultUserData);
    }
  }
}