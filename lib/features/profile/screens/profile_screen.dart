import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme_presets.dart';
import '../../../providers/button_layout_provider.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/home_selection_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/user_service.dart';
import '../../../utils/responsive_utils.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _error;

  /// The theme ID selected during editing (not yet applied).
  /// null means no change from current theme.
  String? _pendingThemeId;
  /// Custom color selected during editing (not yet applied).
  Color? _pendingCustomColor;

  /// Button layout selected during editing (not yet applied).
  /// null means no change from current layout.
  ButtonLayoutMode? _pendingButtonLayout;

  /// Picked profile image file (not yet saved).
  File? _pickedProfileImage;
  /// Whether user requested to remove the profile image during editing.
  bool _pendingRemoveProfileImage = false;
  final ImagePicker _imagePicker = ImagePicker();

  // Persistent controllers to avoid memory leaks and cursor jumps
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _aptUnitController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();

  /// Per-field validation error messages. Empty string = valid.
  final Map<String, String> _fieldErrors = {};

  /// Selected country code for cell number (matches signup style).
  String _selectedCountryCode = '+1-US';

  /// Country code config for cell number formatting.
  static const List<Map<String, String>> _countries = [
    {'code': '+1-US', 'country': 'United States', 'display': '+1'},
    {'code': '+1-CA', 'country': 'Canada', 'display': '+1'},
    {'code': '+44', 'country': 'United Kingdom', 'display': '+44'},
    {'code': '+91', 'country': 'India', 'display': '+91'},
    {'code': '+86', 'country': 'China', 'display': '+86'},
    {'code': '+81', 'country': 'Japan', 'display': '+81'},
    {'code': '+33', 'country': 'France', 'display': '+33'},
    {'code': '+49', 'country': 'Germany', 'display': '+49'},
    {'code': '+39', 'country': 'Italy', 'display': '+39'},
    {'code': '+34', 'country': 'Spain', 'display': '+34'},
  ];

  /// Max digits and format per country.
  static const Map<String, ({int maxDigits, String hint})> _countryPhoneConfig = {
    '+1-US': (maxDigits: 10, hint: '(123) 456-7890'),
    '+1-CA': (maxDigits: 10, hint: '(123) 456-7890'),
    '+44': (maxDigits: 10, hint: '7123 456789'),
    '+91': (maxDigits: 10, hint: '98765 43210'),
    '+86': (maxDigits: 11, hint: '138 1234 5678'),
    '+81': (maxDigits: 10, hint: '90-1234-5678'),
    '+33': (maxDigits: 9, hint: '6 12 34 56 78'),
    '+49': (maxDigits: 11, hint: '171 1234567'),
    '+39': (maxDigits: 10, hint: '312 345 6789'),
    '+34': (maxDigits: 9, hint: '612 345 678'),
  };

  /// US states for address dropdown (abbreviation → full name).
  static const Map<String, String> _usStateMap = {
    'AL': 'Alabama', 'AK': 'Alaska', 'AZ': 'Arizona', 'AR': 'Arkansas',
    'CA': 'California', 'CO': 'Colorado', 'CT': 'Connecticut', 'DE': 'Delaware',
    'FL': 'Florida', 'GA': 'Georgia', 'HI': 'Hawaii', 'ID': 'Idaho',
    'IL': 'Illinois', 'IN': 'Indiana', 'IA': 'Iowa', 'KS': 'Kansas',
    'KY': 'Kentucky', 'LA': 'Louisiana', 'ME': 'Maine', 'MD': 'Maryland',
    'MA': 'Massachusetts', 'MI': 'Michigan', 'MN': 'Minnesota', 'MS': 'Mississippi',
    'MO': 'Missouri', 'MT': 'Montana', 'NE': 'Nebraska', 'NV': 'Nevada',
    'NH': 'New Hampshire', 'NJ': 'New Jersey', 'NM': 'New Mexico', 'NY': 'New York',
    'NC': 'North Carolina', 'ND': 'North Dakota', 'OH': 'Ohio', 'OK': 'Oklahoma',
    'OR': 'Oregon', 'PA': 'Pennsylvania', 'RI': 'Rhode Island', 'SC': 'South Carolina',
    'SD': 'South Dakota', 'TN': 'Tennessee', 'TX': 'Texas', 'UT': 'Utah',
    'VT': 'Vermont', 'VA': 'Virginia', 'WA': 'Washington', 'WV': 'West Virginia',
    'WI': 'Wisconsin', 'WY': 'Wyoming', 'DC': 'Washington DC', 'PR': 'Puerto Rico',
    'VI': 'US Virgin Islands', 'GU': 'Guam', 'AS': 'American Samoa',
    'MP': 'Northern Mariana Islands',
  };

  /// Display labels for the state dropdown (e.g. "California (CA)").
  static final List<String> _usStates =
      _usStateMap.entries.map((e) => '${e.value} (${e.key})').toList();

  /// Supported languages for the dropdown.
  static const List<Map<String, String>> _supportedLanguages = [
    {'code': 'en', 'label': 'English'},
    {'code': 'es', 'label': 'Spanish'},
    {'code': 'fr', 'label': 'French'},
    {'code': 'de', 'label': 'German'},
    {'code': 'pt', 'label': 'Portuguese'},
    {'code': 'zh', 'label': 'Chinese'},
    {'code': 'ja', 'label': 'Japanese'},
    {'code': 'ko', 'label': 'Korean'},
    {'code': 'ar', 'label': 'Arabic'},
    {'code': 'hi', 'label': 'Hindi'},
  ];

  Map<String, dynamic> _formData = {};
  Map<String, dynamic> _initialFormData = {};

  @override
  void initState() {
    super.initState();
    _initializeFormData();
    _syncControllersFromFormData();
    _phoneController.addListener(_formatPhoneNumber);
  }

  @override
  void dispose() {
    _phoneController.removeListener(_formatPhoneNumber);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _aptUnitController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    super.dispose();
  }

  void _syncControllersFromFormData() {
    _nameController.text = _formData['name'] as String? ?? '';
    _emailController.text = _formData['email'] as String? ?? '';
    _phoneController.text = _formData['phone'] as String? ?? '';
    _addressController.text = _formData['address'] as String? ?? '';
    _aptUnitController.text = _formData['aptUnit'] as String? ?? '';
    _cityController.text = _formData['city'] as String? ?? '';
    _zipCodeController.text = _formData['zipCode'] as String? ?? '';
  }

  TextEditingController _controllerForKey(String key) {
    switch (key) {
      case 'name':
        return _nameController;
      case 'email':
        return _emailController;
      case 'phone':
        return _phoneController;
      case 'address':
        return _addressController;
      case 'aptUnit':
        return _aptUnitController;
      case 'city':
        return _cityController;
      case 'zipCode':
        return _zipCodeController;
      default:
        return TextEditingController(text: _formData[key] as String? ?? '');
    }
  }

  /// Returns the display label for a language code, or the code itself.
  String _languageLabel(String code) {
    final match = _supportedLanguages.where((l) => l['code'] == code);
    return match.isNotEmpty ? match.first['label']! : code;
  }

  /// Initializes form data from the Riverpod user profile provider.
  void _initializeFormData() {
    final profile = ref.read(userProfileProvider);

    // If the user's profile has no saved address, auto-fill from the selected home.
    String address = profile.address;
    String city = profile.city;
    String usState = profile.usState;
    String zipCode = profile.zipCode;

    if (address.isEmpty) {
      final selectedHomeId = ref.read(selectedHomeIdProvider);
      if (selectedHomeId != null) {
        final homes = ref.read(homesProvider).valueOrNull ?? [];
        final selectedHome = homes.where((h) => h.id == selectedHomeId).firstOrNull;
        if (selectedHome != null) {
          address = selectedHome.address;
          city = selectedHome.city;
          usState = selectedHome.state;
          zipCode = selectedHome.zip;
        }
      }
    }

    _selectedCountryCode = profile.countryCode.isNotEmpty
        ? profile.countryCode
        : '+1-US';

    _formData = {
      'name': profile.name,
      'email': profile.email,
      'phone': profile.phone,
      'address': address,
      'aptUnit': profile.aptUnit,
      'city': city,
      'usState': usState,
      'zipCode': zipCode,
      'profileImage': '',
      'role': 'Homeowner',
      'language': 'en',
    };
    _initialFormData = Map<String, dynamic>.from(_formData);
  }

  // ─── Validation helpers ──────────────────────────────────────────

  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final _phoneDigitsRegex = RegExp(r'\d');
  static final _zipRegex = RegExp(r'^\d{5}(-\d{4})?$');

  /// Validates a single field and returns the error message (empty = valid).
  String _validateField(String key, String value) {
    switch (key) {
      case 'name':
        final trimmed = value.trim();
        if (trimmed.isEmpty) return 'Full name is required';
        if (trimmed.length < 2) return 'Name must be at least 2 characters';
        if (trimmed.length > 50) return 'Name must be under 50 characters';
        if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(trimmed)) {
          return 'Name can only contain letters, spaces, hyphens, and apostrophes';
        }
        return '';
      case 'email':
        final trimmed = value.trim();
        if (trimmed.isEmpty) return 'Email address is required';
        if (!_emailRegex.hasMatch(trimmed)) return 'Enter a valid email address';
        if (trimmed.length > 254) return 'Email is too long';
        return '';
      case 'phone':
        final trimmed = value.trim();
        if (trimmed.isEmpty) return ''; // Phone is optional — allow saving without one
        final digits =
            _phoneDigitsRegex.allMatches(trimmed).map((m) => m.group(0)).join();
        final config = _countryPhoneConfig[_selectedCountryCode] ?? _countryPhoneConfig['+1-US']!;
        if (digits.length < config.maxDigits) {
          return 'Cell number must be ${config.maxDigits} digits for this country';
        }
        return '';
      case 'address':
        final trimmed = value.trim();
        if (trimmed.isEmpty) return ''; // optional
        if (trimmed.length < 3) return 'Address is too short';
        if (trimmed.length > 100) return 'Address is too long';
        return '';
      case 'city':
        final trimmed = value.trim();
        if (trimmed.isEmpty) return ''; // optional
        if (!RegExp(r"^[a-zA-Z\s'-]+$").hasMatch(trimmed)) {
          return 'City can only contain letters, spaces, hyphens';
        }
        return '';
      case 'usState':
        return ''; // optional
      case 'zipCode':
        final trimmed = value.trim();
        if (trimmed.isEmpty) return ''; // optional
        if (!_zipRegex.hasMatch(trimmed)) {
          return 'Enter a valid ZIP code (e.g. 12345 or 12345-6789)';
        }
        return '';
      default:
        return '';
    }
  }

  /// Syncs text controller values back into [_formData] so validation
  /// always works against the latest user input.
  void _syncFormDataFromControllers() {
    _formData['name'] = _nameController.text;
    _formData['email'] = _emailController.text;
    _formData['phone'] = _phoneController.text;
    _formData['address'] = _addressController.text;
    _formData['aptUnit'] = _aptUnitController.text;
    _formData['city'] = _cityController.text;
    _formData['zipCode'] = _zipCodeController.text;
  }

  /// Validates all editable fields. Returns true when everything is valid.
  bool _validateAll() {
    // Ensure _formData reflects current controller text.
    _syncFormDataFromControllers();

    bool allValid = true;
    for (final key in ['name', 'email', 'phone', 'address', 'city', 'usState', 'zipCode']) {
      final error = _validateField(key, _formData[key] as String? ?? '');
      _fieldErrors[key] = error;
      if (error.isNotEmpty) allValid = false;
    }
    setState(() {});
    return allValid;
  }

  /// Clears all validation errors (e.g. when cancelling).
  void _clearErrors() {
    _fieldErrors.clear();
  }

  void _handleSave() async {
    // Validate all fields before saving.
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the errors before saving'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      // Persist profile data app-wide via provider + UserService.
      final name = (_formData['name'] as String).trim();
      final email = (_formData['email'] as String).trim();
      final phone = (_formData['phone'] as String).trim();
      final address = (_formData['address'] as String? ?? '').trim();
      final aptUnit = (_formData['aptUnit'] as String? ?? '').trim();
      final city = (_formData['city'] as String? ?? '').trim();
      final usState = (_formData['usState'] as String? ?? '').trim();
      final zipCode = (_formData['zipCode'] as String? ?? '').trim();

      // ── 1. Save supported fields to backend ──────────────────────────────
      await ref.read(userProfileProvider.notifier).saveToBackend(
        name: name,
        phone: phone.isNotEmpty ? phone : null,
      );

      // Apply pending theme change
      if (_pendingCustomColor != null) {
        ref.read(themePresetProvider.notifier).selectCustomColor(_pendingCustomColor!);
      } else if (_pendingThemeId != null) {
        ref.read(themePresetProvider.notifier).selectTheme(_pendingThemeId!);
      }

      // Apply pending button layout change
      if (_pendingButtonLayout != null) {
        ref.read(buttonLayoutProvider.notifier).setLayout(_pendingButtonLayout!);
      }

      // ── 2. Update local state (SharedPreferences + Riverpod provider) ──
      await ref.read(userProfileProvider.notifier).updateProfile(
        name: name,
        email: email,
        phone: phone,
        countryCode: _selectedCountryCode,
        address: address,
        aptUnit: aptUnit,
        city: city,
        usState: usState,
        zipCode: zipCode,
        profileImagePath: _pickedProfileImage?.path,
        clearProfileImage: _pendingRemoveProfileImage,
      );

      // Keep UserService in sync so non-Riverpod widgets also see updates.
      await UserService.instance.updateUserData({
        'name': name,
        'email': email,
        'phone': phone,
        'countryCode': _selectedCountryCode,
        'address': address,
        'apartmentUnit': aptUnit,
        'city': city,
        'state': usState,
        'zipCode': zipCode,
      });

      _initialFormData = Map<String, dynamic>.from(_formData);
      setState(() {
        _isEditing = false;
        _isSaving = false;
        _pendingThemeId = null;
        _pendingCustomColor = null;
        _pendingButtonLayout = null;
        _pickedProfileImage = null;
        _pendingRemoveProfileImage = false;
        _clearErrors();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } on Object catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isSaving = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_error ?? 'Failed to update profile. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _handleCancel() {
    final profile = ref.read(userProfileProvider);
    setState(() {
      _formData = Map<String, dynamic>.from(_initialFormData);
      _selectedCountryCode = profile.countryCode.isNotEmpty
          ? profile.countryCode
          : '+1-US';
      _syncControllersFromFormData();
      _isEditing = false;
      _error = null;
      _pendingThemeId = null;
      _pendingCustomColor = null;
      _pendingButtonLayout = null;
      _pickedProfileImage = null;
      _pendingRemoveProfileImage = false;
      _clearErrors();
    });
  }

  void _showImagePickerSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              Text(
                'Change Profile Photo',
                style: TextStyle(
                  fontSize: responsive.fontSize(17),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(8)),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _headerColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.camera_alt, color: _headerColor),
                ),
                title: const Text('Take Photo'),
                subtitle: const Text('Use your camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.purple),
                ),
                title: const Text('Choose from Gallery'),
                subtitle: const Text('Pick an existing photo'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickProfileImage(ImageSource.gallery);
                },
              ),
              if (_pickedProfileImage != null ||
                  (!_pendingRemoveProfileImage &&
                      ref.read(userProfileProvider).hasProfileImage))
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.delete_outline, color: Colors.red),
                  ),
                  title: const Text('Remove Photo'),
                  subtitle: const Text('Use default avatar'),
                  onTap: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _pickedProfileImage = null;
                      _pendingRemoveProfileImage = true;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _pickedProfileImage = File(image.path);
          _pendingRemoveProfileImage = false;
        });
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not access ${source == ImageSource.camera ? 'camera' : 'gallery'}. Please check permissions.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'U';
    final parts = trimmed.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    // When backend data arrives (e.g. loadFromBackend() completes after login),
    // refresh the form ONLY if the user is not currently in edit mode.
    ref.listen<UserProfile>(userProfileProvider, (previous, next) {
      if (!_isEditing && mounted) {
        _initializeFormData();
        _syncControllersFromFormData();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'Profile',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.bold,
            color: AppColors.headerForeground,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: responsive.spacing(24)),
            // Profile Summary Card
            _buildProfileSummaryCard(),
            SizedBox(height: responsive.spacing(24)),
            // Main Content Card
            _buildMainContentCard(),
            if (_error != null) ...[
              SizedBox(height: responsive.spacing(16)),
              _buildErrorCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSummaryCard() {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile Avatar
          Stack(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _headerColor.withValues(alpha: 0.08),
                  border: Border.all(
                    color: _headerColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Builder(
                  builder: (context) {
                    final userProfile = ref.watch(userProfileProvider);
                    // Priority: picked image > saved image from provider > network image > initials
                    if (_pickedProfileImage != null) {
                      return ClipOval(
                        child: Image.file(
                          _pickedProfileImage!,
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      );
                    }
                    if (_pendingRemoveProfileImage) {
                      return Center(
                        child: Text(
                          _getInitials(_formData['name'] as String),
                          style: TextStyle(
                            fontSize: responsive.fontSize(44),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      );
                    }
                    if (userProfile.hasProfileImage) {
                      final imagePath = userProfile.profileImagePath!;
                      final isNetwork = imagePath.startsWith('http://') ||
                          imagePath.startsWith('https://');
                      return ClipOval(
                        child: isNetwork
                            ? Image.network(
                                imagePath,
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _getInitials(_formData['name'] as String),
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(44),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                },
                              )
                            : Image.file(
                                File(imagePath),
                                width: 88,
                                height: 88,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Text(
                                      _getInitials(_formData['name'] as String),
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(44),
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      );
                    }
                    if (_formData['profileImage'] != null &&
                        (_formData['profileImage'] as String).isNotEmpty) {
                      return ClipOval(
                        child: Image.network(
                          _formData['profileImage'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Text(
                                _getInitials(_formData['name'] as String),
                                style: TextStyle(
                                  fontSize: responsive.fontSize(44),
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    return Center(
                      child: Text(
                        _getInitials(_formData['name'] as String),
                        style: TextStyle(
                          fontSize: responsive.fontSize(44),
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isEditing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _showImagePickerSheet,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: _headerColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                      ),
                      child: Icon(
                        Icons.edit,
                        color: AppColors.white,
                        size: responsive.iconSize(14),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          Text(
            _formData['name'] as String? ?? 'User',
            style: TextStyle(
              fontSize: responsive.fontSize(18),
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(2)),
          Text(
            _formData['email'] as String? ?? 'No email',
            style: TextStyle(fontSize: responsive.fontSize(12), color: AppColors.textSecondary),
          ),
          SizedBox(height: responsive.spacing(12)),
          if (!_isEditing)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                icon: Icon(Icons.edit, size: responsive.iconSize(18)),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(vertical: responsive.spacing(11)),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                ),
              ),
            ),
          SizedBox(height: responsive.spacing(12)),
          const Divider(),
          SizedBox(height: responsive.spacing(12)),
          // Quick Stats
          _buildStatRow(
            icon: Icons.calendar_today,
            label: 'Member Since',
            value: _getMemberSinceDate(),
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildStatRow(
            icon: Icons.home,
            label: 'Homes',
            value: '2',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: EdgeInsets.all(responsive.spacing(5)),
              decoration: BoxDecoration(
                color: _headerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Icon(icon, size: responsive.iconSize(14), color: _headerColor),
            ),
            SizedBox(width: responsive.spacing(10)),
            Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
            fontFamily: isMonospace ? 'monospace' : null,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContentCard() {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Personal Information Section
          _buildSectionHeader(
            icon: Icons.person,
            title: 'Personal Information',
            subtitle: 'Update your personal details',
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildFormField(
            label: 'Full Name',
            icon: Icons.person,
            fieldKey: 'name',
            onChanged: (value) {
              setState(() {
                _formData['name'] = value;
                _fieldErrors['name'] = _validateField('name', value);
              });
            },
            enabled: _isEditing,
            hint: 'Enter your full name',
            errorText: _fieldErrors['name'],
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildFormField(
            label: 'Email Address',
            icon: Icons.email,
            fieldKey: 'email',
            onChanged: (value) {
              setState(() {
                _formData['email'] = value;
                _fieldErrors['email'] = _validateField('email', value);
              });
            },
            enabled: _isEditing,
            keyboardType: TextInputType.emailAddress,
            hint: 'email@example.com',
            errorText: _fieldErrors['email'],
          ),
          SizedBox(height: responsive.spacing(12)),
          // Cell Number with Country Code (matches signup screen)
          _buildCellNumberField(),
          SizedBox(height: responsive.spacing(24)),
          // Address Section (US Standard)
          _buildSectionHeader(
            icon: Icons.location_on,
            title: 'Address',
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildFormField(
            label: 'Street Address',
            icon: Icons.home,
            fieldKey: 'address',
            onChanged: (value) {
              setState(() {
                _formData['address'] = value;
                _fieldErrors['address'] = _validateField('address', value);
              });
            },
            enabled: _isEditing,
            hint: '123 Main Street',
            errorText: _fieldErrors['address'],
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildFormField(
            label: 'Apt / Unit / Suite (Optional)',
            icon: Icons.apartment,
            fieldKey: 'aptUnit',
            onChanged: (value) {
              setState(() {
                _formData['aptUnit'] = value;
              });
            },
            enabled: _isEditing,
            hint: 'e.g. Apt 4B',
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildFormField(
            label: 'City',
            icon: Icons.location_city,
            fieldKey: 'city',
            onChanged: (value) {
              setState(() {
                _formData['city'] = value;
                _fieldErrors['city'] = _validateField('city', value);
              });
            },
            enabled: _isEditing,
            hint: 'e.g. New York',
            errorText: _fieldErrors['city'],
          ),
          SizedBox(height: responsive.spacing(12)),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildDropdownField(
                  label: 'State',
                  value: _getStateDisplayLabel(_formData['usState'] as String? ?? ''),
                  items: _usStates,
                  enabled: _isEditing,
                  onChanged: (value) {
                    setState(() {
                      _formData['usState'] = _extractStateAbbreviation(value);
                      _fieldErrors['usState'] = '';
                    });
                  },
                  errorText: _fieldErrors['usState'],
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                flex: 2,
                child: _buildFormField(
                  label: 'ZIP Code',
                  icon: Icons.pin,
                  fieldKey: 'zipCode',
                  onChanged: (value) {
                    setState(() {
                      _formData['zipCode'] = value;
                      _fieldErrors['zipCode'] = _validateField('zipCode', value);
                    });
                  },
                  enabled: _isEditing,
                  keyboardType: TextInputType.number,
                  hint: '12345',
                  errorText: _fieldErrors['zipCode'],
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(16)),
          // Account Settings Section
          _buildSectionHeader(
            icon: Icons.shield,
            title: 'Account Settings',
            subtitle: 'Manage your account settings',
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildDropdownField(
            label: 'Role',
            value: _formData['role'] as String? ?? '',
            items: const ['Homeowner', 'Admin', 'Service Provider'],
            enabled: _isEditing,
            onChanged: (value) {
              setState(() {
                _formData['role'] = value;
              });
            },
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildDropdownField(
            label: 'Language',
            value: _languageLabel(_formData['language'] as String? ?? 'en'),
            items: _supportedLanguages.map((l) => l['label']!).toList(),
            enabled: _isEditing,
            onChanged: (value) {
              final match =
                  _supportedLanguages.where((l) => l['label'] == value);
              setState(() {
                _formData['language'] =
                    match.isNotEmpty ? match.first['code']! : 'en';
              });
            },
          ),
          SizedBox(height: responsive.spacing(16)),
          // App Color Theme Section
          _buildSectionHeader(
            icon: Icons.palette,
            title: 'Appearance',
            subtitle: 'Choose your app color theme',
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildColorThemePicker(),
          SizedBox(height: responsive.spacing(20)),
          // Button Layout Section
          _buildSectionHeader(
            icon: Icons.rounded_corner,
            title: 'Button Style',
            subtitle: 'Choose button shape across the app',
          ),
          SizedBox(height: responsive.spacing(12)),
          _buildButtonLayoutPicker(),
          // Action Buttons
          if (_isEditing) ...[
            SizedBox(height: responsive.spacing(32)),
            const Divider(),
            SizedBox(height: responsive.spacing(24)),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      foregroundColor: AppColors.primary,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.close, size: responsive.iconSize(18)),
                        SizedBox(width: responsive.spacing(8)),
                        const Text('Cancel'),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textOnPrimary,
                              ),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: responsive.iconSize(18)),
                              SizedBox(width: responsive.spacing(8)),
                              const Text('Save Changes'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Color-theme picker grid.
  /// Disabled when not editing. Theme is only applied on Save.
  Widget _buildColorThemePicker() {
    final currentPreset = ref.watch(themePresetProvider);
    const presets = AppThemePresets.all;

    // Determine what's visually "selected": pending choice or current
    final activeId = _pendingCustomColor != null
        ? 'custom'
        : _pendingThemeId ?? currentPreset.id;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid of preset swatches
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: presets.length + 1, // +1 for Custom Color
          itemBuilder: (context, index) {
            // Last item is the Custom Color swatch
            if (index == presets.length) {
              return _buildCustomColorGridItem(activeId, currentPreset);
            }
            final preset = presets[index];
            final isSelected = preset.id == activeId;

            return GestureDetector(
              onTap: _isEditing
                  ? () {
                      setState(() {
                        _pendingThemeId = preset.id;
                        _pendingCustomColor = null;
                      });
                    }
                  : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                decoration: BoxDecoration(
                  color: isSelected
                      ? (preset.brightness == Brightness.dark
                          ? const Color(0xFF263238).withValues(alpha: 0.12)
                          : preset.primary.withValues(alpha: 0.08))
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? (preset.brightness == Brightness.dark
                            ? const Color(0xFF263238)
                            : preset.primary)
                        : AppColors.border,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (preset.brightness == Brightness.dark
                                    ? const Color(0xFF263238)
                                    : preset.primary)
                                .withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Opacity(
                  opacity: _isEditing ? 1.0 : 0.6,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Dual-color swatch: primary (left) + accent (right)
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? (preset.brightness == Brightness.dark
                                    ? const Color(0xFF263238)
                                    : preset.primary)
                                : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: (preset.brightness == Brightness.dark
                                            ? const Color(0xFF263238)
                                            : preset.primary)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : [],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            // Left half: primary color
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 19,
                              child: Container(
                                color: preset.brightness == Brightness.dark
                                    ? const Color(0xFF1E1E1E)
                                    : preset.primary,
                              ),
                            ),
                            // Right half: accent color
                            Positioned(
                              right: 0,
                              top: 0,
                              bottom: 0,
                              width: 19,
                              child: Container(
                                color: preset.accent,
                              ),
                            ),
                            if (isSelected)
                              Center(
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: preset.brightness == Brightness.dark
                                            ? const Color(0xFF263238)
                                            : preset.primary,
                                        width: 1.5),
                                  ),
                                  child: Icon(Icons.check,
                                      color: preset.brightness == Brightness.dark
                                          ? const Color(0xFF263238)
                                          : preset.primary,
                                      size: 8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: responsive.spacing(3)),
                      Flexible(
                        child: Text(
                          preset.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: responsive.fontSize(8.5),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? (preset.brightness == Brightness.dark
                                    ? const Color(0xFF263238)
                                    : preset.primary)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        SizedBox(height: responsive.spacing(14)),

        // Active theme indicator
        _buildActiveThemeIndicator(activeId, currentPreset),
      ],
    );
  }

  /// Custom Color swatch shown as the last item in the theme grid.
  Widget _buildCustomColorGridItem(String activeId, AppThemePreset currentPreset) {
    final isSelected = activeId == 'custom';
    final customColor = _pendingCustomColor ?? currentPreset.primary;

    return GestureDetector(
      onTap: _isEditing ? _openColorPicker : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? customColor.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? customColor : AppColors.border,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: customColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Opacity(
          opacity: _isEditing ? 1.0 : 0.6,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Rainbow/custom color swatch
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: _pendingCustomColor != null
                      ? LinearGradient(
                          colors: [
                            _pendingCustomColor!,
                            HSLColor.fromColor(_pendingCustomColor!)
                                .withHue(
                                  (HSLColor.fromColor(_pendingCustomColor!).hue + 40) % 360,
                                )
                                .toColor(),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : (currentPreset.id == 'custom'
                          ? LinearGradient(
                              colors: [
                                currentPreset.primary,
                                currentPreset.accent,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : const LinearGradient(
                              colors: [
                                Color(0xFFFF6B6B),
                                Color(0xFF4ECDC4),
                                Color(0xFF45B7D1),
                                Color(0xFFFFA07A),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )),
                  border: Border.all(
                    color: isSelected ? customColor : Colors.grey.shade300,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: customColor.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: isSelected
                    ? Icon(Icons.check, color: Colors.white, size: responsive.iconSize(14))
                    : Icon(Icons.colorize, color: Colors.white, size: responsive.iconSize(14)),
              ),
              SizedBox(height: responsive.spacing(3)),
              Flexible(
                child: Text(
                  'Custom',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: responsive.fontSize(8.5),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? customColor
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows the currently active (or pending) theme.
  Widget _buildActiveThemeIndicator(
      String activeId, AppThemePreset currentPreset) {
    Color displayColor;
    Color indicatorColor; // color used for text, border, tint
    String displayName;
    String displayEmoji;

    if (_pendingCustomColor != null) {
      displayColor = _pendingCustomColor!;
      indicatorColor = _pendingCustomColor!;
      displayName = _isEditing ? 'Pending: Custom Color' : 'Custom';
      displayEmoji = '🎨';
    } else if (_pendingThemeId != null && _isEditing) {
      final pending = AppThemePresets.getById(_pendingThemeId!);
      displayColor = pending.primary;
      // For dark mode, use a dark color for the indicator styling
      indicatorColor = pending.brightness == Brightness.dark
          ? const Color(0xFF263238)
          : pending.primary;
      displayName = 'Pending: ${pending.name}';
      displayEmoji = pending.emoji;
    } else {
      displayColor = currentPreset.primary;
      indicatorColor = currentPreset.brightness == Brightness.dark
          ? const Color(0xFF263238)
          : currentPreset.primary;
      displayName = 'Active: ${currentPreset.name}';
      displayEmoji = currentPreset.emoji;
    }

    // Resolve the preset for swatch colors
    final resolvedPreset = _pendingCustomColor != null
        ? null
        : (_pendingThemeId != null && _isEditing
            ? AppThemePresets.getById(_pendingThemeId!)
            : currentPreset);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(10)),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: indicatorColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    color: _pendingCustomColor != null
                        ? _pendingCustomColor!
                        : (resolvedPreset != null && resolvedPreset.brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : displayColor),
                  ),
                ),
                Expanded(
                  child: Container(
                    color: _pendingCustomColor != null
                        ? HSLColor.fromColor(_pendingCustomColor!)
                            .withHue((HSLColor.fromColor(_pendingCustomColor!).hue + 180) % 360)
                            .toColor()
                        : (resolvedPreset?.accent ?? currentPreset.accent),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.spacing(10)),
          Expanded(
            child: Text(
              displayName,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                fontWeight: FontWeight.w600,
                color: indicatorColor,
              ),
            ),
          ),
          Text(displayEmoji, style: TextStyle(fontSize: responsive.fontSize(16))),
        ],
      ),
    );
  }

  /// Button layout toggle — capsule vs normal.
  Widget _buildButtonLayoutPicker() {
    final currentLayout = ref.watch(buttonLayoutProvider);
    final activeLayout = _pendingButtonLayout ?? currentLayout;

    return Opacity(
      opacity: _isEditing ? 1.0 : 0.6,
      child: Row(
        children: [
          _buildLayoutOption(
            label: 'Capsule',
            icon: Icons.stadium_outlined,
            mode: ButtonLayoutMode.capsule,
            isSelected: activeLayout == ButtonLayoutMode.capsule,
            borderRadius: 50,
          ),
          SizedBox(width: responsive.spacing(12)),
          _buildLayoutOption(
            label: 'Normal',
            icon: Icons.rectangle_outlined,
            mode: ButtonLayoutMode.normal,
            isSelected: activeLayout == ButtonLayoutMode.normal,
            borderRadius: 12,
          ),
        ],
      ),
    );
  }

  Widget _buildLayoutOption({
    required String label,
    required IconData icon,
    required ButtonLayoutMode mode,
    required bool isSelected,
    required double borderRadius,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: _isEditing
            ? () {
                setState(() {
                  _pendingButtonLayout = mode;
                });
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
          decoration: BoxDecoration(
            color: isSelected
                ? _headerColor.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? _headerColor : AppColors.border,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _headerColor.withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Column(
            children: [
              // Preview button shape
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 80,
                height: 30,
                decoration: BoxDecoration(
                  color: isSelected ? _headerColor : AppColors.gray300,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Center(
                  child: Text(
                    'Button',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: responsive.fontSize(11),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.spacing(8)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isSelected)
                    Icon(Icons.check_circle, size: responsive.iconSize(14), color: _headerColor),
                  if (isSelected) SizedBox(width: responsive.spacing(4)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? _headerColor : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opens a full-screen color picker dialog.
  void _openColorPicker() {
    Color pickedColor = _pendingCustomColor ?? _headerColor;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('Pick a Custom Color'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Preview
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: pickedColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: pickedColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),

                    // Hue slider
                    Text('Hue',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                    SizedBox(height: responsive.spacing(8)),
                    _buildHueSlider(pickedColor, (color) {
                      setDialogState(() => pickedColor = color);
                    }),

                    SizedBox(height: responsive.spacing(16)),

                    // Saturation slider
                    Text('Saturation',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                    SizedBox(height: responsive.spacing(8)),
                    _buildSaturationSlider(pickedColor, (color) {
                      setDialogState(() => pickedColor = color);
                    }),

                    SizedBox(height: responsive.spacing(16)),

                    // Lightness slider
                    Text('Lightness',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                    SizedBox(height: responsive.spacing(8)),
                    _buildLightnessSlider(pickedColor, (color) {
                      setDialogState(() => pickedColor = color);
                    }),

                    SizedBox(height: responsive.spacing(20)),

                    // Quick color palette
                    Text('Quick Colors',
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        )),
                    SizedBox(height: responsive.spacing(8)),
                    _buildQuickColorPalette((color) {
                      setDialogState(() => pickedColor = color);
                    }),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _pendingCustomColor = pickedColor;
                      _pendingThemeId = null;
                    });
                    Navigator.of(ctx).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: pickedColor,
                    foregroundColor: pickedColor.computeLuminance() > 0.5 ? const Color(0xFF1A1A2E) : Colors.white,
                  ),
                  child: const Text('Select'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildHueSlider(Color current, ValueChanged<Color> onChanged) {
    final hsl = HSLColor.fromColor(current);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: List.generate(
            360 ~/ 10,
            (i) => HSLColor.fromAHSL(1, i * 10.0, hsl.saturation, hsl.lightness)
                .toColor(),
          ),
        ),
      ),
      child: SliderTheme(
        data: const SliderThemeData(
          trackHeight: 28,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
          trackShape: RoundedRectSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
          thumbColor: Colors.white,
          overlayColor: Colors.white24,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
        ),
        child: Slider(
          value: hsl.hue,
          min: 0,
          max: 359,
          onChanged: (v) {
            onChanged(hsl.withHue(v).toColor());
          },
        ),
      ),
    );
  }

  Widget _buildSaturationSlider(Color current, ValueChanged<Color> onChanged) {
    final hsl = HSLColor.fromColor(current);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            hsl.withSaturation(0).toColor(),
            hsl.withSaturation(1).toColor(),
          ],
        ),
      ),
      child: SliderTheme(
        data: const SliderThemeData(
          trackHeight: 28,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
          trackShape: RoundedRectSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
          thumbColor: Colors.white,
          overlayColor: Colors.white24,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
        ),
        child: Slider(
          value: hsl.saturation.clamp(0.0, 1.0),
          min: 0,
          max: 1,
          onChanged: (v) {
            onChanged(hsl.withSaturation(v).toColor());
          },
        ),
      ),
    );
  }

  Widget _buildLightnessSlider(Color current, ValueChanged<Color> onChanged) {
    final hsl = HSLColor.fromColor(current);
    return Container(
      height: 28,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          colors: [
            hsl.withLightness(0.1).toColor(),
            hsl.withLightness(0.5).toColor(),
            hsl.withLightness(0.9).toColor(),
          ],
        ),
      ),
      child: SliderTheme(
        data: const SliderThemeData(
          trackHeight: 28,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 14),
          trackShape: RoundedRectSliderTrackShape(),
          overlayShape: RoundSliderOverlayShape(overlayRadius: 20),
          thumbColor: Colors.white,
          overlayColor: Colors.white24,
          activeTrackColor: Colors.transparent,
          inactiveTrackColor: Colors.transparent,
        ),
        child: Slider(
          value: hsl.lightness.clamp(0.1, 0.9),
          min: 0.1,
          max: 0.9,
          onChanged: (v) {
            onChanged(hsl.withLightness(v).toColor());
          },
        ),
      ),
    );
  }

  Widget _buildQuickColorPalette(ValueChanged<Color> onChanged) {
    const quickColors = [
      Color(0xFFE53935), // Red
      Color(0xFFD81B60), // Pink
      Color(0xFF8E24AA), // Purple
      Color(0xFF5E35B1), // Deep Purple
      Color(0xFF3949AB), // Indigo
      Color(0xFF1E88E5), // Blue
      Color(0xFF039BE5), // Light Blue
      Color(0xFF00ACC1), // Cyan
      Color(0xFF00897B), // Teal
      Color(0xFF43A047), // Green
      Color(0xFF7CB342), // Light Green
      Color(0xFFC0CA33), // Lime
      Color(0xFFFDD835), // Yellow
      Color(0xFFFFB300), // Amber
      Color(0xFFFB8C00), // Orange
      Color(0xFFF4511E), // Deep Orange
      Color(0xFF6D4C41), // Brown
      Color(0xFF546E7A), // Blue Grey
      Color(0xFF424242), // Grey
      Color(0xFF000000), // Black
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: quickColors.map((color) {
        return GestureDetector(
          onTap: () => onChanged(color),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Cell Number formatting helpers (mirrors signup) ─────────────

  String _formatDigitsByCountry(String digits) {
    final config = _countryPhoneConfig[_selectedCountryCode] ?? _countryPhoneConfig['+1-US']!;
    if (digits.isEmpty) return '';
    final max = config.maxDigits;
    final value = digits.length > max ? digits.substring(0, max) : digits;
    switch (_selectedCountryCode) {
      case '+1-US':
      case '+1-CA':
        if (value.length <= 3) return value;
        if (value.length <= 6) return '(${value.substring(0, 3)}) ${value.substring(3)}';
        return '(${value.substring(0, 3)}) ${value.substring(3, 6)}-${value.substring(6)}';
      case '+44':
        if (value.length <= 4) return value;
        return '${value.substring(0, 4)} ${value.substring(4)}';
      case '+91':
        if (value.length <= 5) return value;
        return '${value.substring(0, 5)} ${value.substring(5)}';
      case '+86':
        if (value.length <= 3) return value;
        if (value.length <= 7) return '${value.substring(0, 3)} ${value.substring(3)}';
        return '${value.substring(0, 3)} ${value.substring(3, 7)} ${value.substring(7)}';
      case '+81':
        if (value.length <= 2) return value;
        if (value.length <= 6) return '${value.substring(0, 2)}-${value.substring(2)}';
        return '${value.substring(0, 3)}-${value.substring(3, 6)}-${value.substring(6)}';
      case '+33':
        if (value.length <= 1) return value;
        if (value.length <= 3) return '${value[0]} ${value.substring(1)}';
        if (value.length <= 5) return '${value[0]} ${value.substring(1, 3)} ${value.substring(3)}';
        if (value.length <= 7) return '${value[0]} ${value.substring(1, 3)} ${value.substring(3, 5)} ${value.substring(5)}';
        return '${value[0]} ${value.substring(1, 3)} ${value.substring(3, 5)} ${value.substring(5, 7)} ${value.substring(7)}';
      case '+49':
        if (value.length <= 3) return value;
        return '${value.substring(0, 3)} ${value.substring(3)}';
      case '+39':
        if (value.length <= 3) return value;
        if (value.length <= 6) return '${value.substring(0, 3)} ${value.substring(3)}';
        return '${value.substring(0, 3)} ${value.substring(3, 6)} ${value.substring(6)}';
      case '+34':
        if (value.length <= 3) return value;
        if (value.length <= 6) return '${value.substring(0, 3)} ${value.substring(3)}';
        return '${value.substring(0, 3)} ${value.substring(3, 6)} ${value.substring(6)}';
      default:
        if (value.length <= 3) return value;
        if (value.length <= 6) return '(${value.substring(0, 3)}) ${value.substring(3)}';
        return '(${value.substring(0, 3)}) ${value.substring(3, 6)}-${value.substring(6)}';
    }
  }

  void _formatPhoneNumber() {
    final text = _phoneController.text;
    final selection = _phoneController.selection;
    final cursorPosition = selection.baseOffset;
    int digitsBeforeCursor = 0;
    for (int i = 0; i < cursorPosition && i < text.length; i++) {
      if (RegExp(r'\d').hasMatch(text[i])) digitsBeforeCursor++;
    }
    String value = text.replaceAll(RegExp(r'\D'), '');
    final config = _countryPhoneConfig[_selectedCountryCode] ?? _countryPhoneConfig['+1-US']!;
    if (value.length > config.maxDigits) value = value.substring(0, config.maxDigits);
    final formattedValue = _formatDigitsByCountry(value);
    if (formattedValue != text) {
      int newCursorPosition = formattedValue.length;
      if (digitsBeforeCursor > 0) {
        int digitCount = 0;
        for (int i = 0; i < formattedValue.length; i++) {
          if (RegExp(r'\d').hasMatch(formattedValue[i])) {
            digitCount++;
            if (digitCount == digitsBeforeCursor) {
              newCursorPosition = i + 1;
              break;
            }
          }
        }
      }
      _phoneController.value = _phoneController.value.copyWith(
        text: formattedValue,
        selection: TextSelection.collapsed(offset: newCursorPosition.clamp(0, formattedValue.length)),
      );
    }
    // Update form data and validate
    _formData['phone'] = _phoneController.text;
    _fieldErrors['phone'] = _validateField('phone', _phoneController.text);
  }

  /// Opens country code picker menu.
  Future<void> _showCountryCodeMenu(BuildContext countryCodeContext) async {
    final RenderBox box = countryCodeContext.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        box.localToGlobal(Offset.zero),
        box.localToGlobal(box.size.bottomRight(Offset.zero)),
      ),
      Offset.zero & overlay.size,
    );
    final String? selected = await showMenu<String>(
      context: context,
      position: position,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
        minWidth: box.size.width,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: _countries
          .map((country) => PopupMenuItem<String>(
                value: country['code']!,
                child: Row(
                  children: [
                    Text(
                      country['display']!,
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    Expanded(
                      child: Text(
                        country['country']!,
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
    if (selected != null && mounted) {
      setState(() => _selectedCountryCode = selected);
      if (_phoneController.text.replaceAll(RegExp(r'\D'), '').isNotEmpty) {
        _formatPhoneNumber();
      }
    }
  }

  /// Cell Number field with country code picker (same UX as signup).
  Widget _buildCellNumberField() {
    final hasError = (_fieldErrors['phone'] ?? '').isNotEmpty;
    final config = _countryPhoneConfig[_selectedCountryCode] ?? _countryPhoneConfig['+1-US']!;
    final displayCode = _countries.firstWhere(
      (c) => c['code'] == _selectedCountryCode,
      orElse: () => _countries.first,
    )['display']!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cell Number',
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w500,
            color: hasError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        Container(
          decoration: BoxDecoration(
            color: _isEditing ? AppColors.surface : AppColors.backgroundGray50,
            borderRadius: BorderRadius.circular(8),
            border: hasError
                ? Border.all(color: AppColors.error, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Country code button
              Builder(
                builder: (ctx) => InkWell(
                  onTap: _isEditing ? () => _showCountryCodeMenu(ctx) : null,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(12)),
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: AppColors.border, width: 1),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayCode,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: FontWeight.w600,
                            color: _isEditing
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        if (_isEditing) ...[
                          SizedBox(width: responsive.spacing(4)),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: responsive.iconSize(18),
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              // Phone number input
              Expanded(
                child: TextField(
                  controller: _phoneController,
                  enabled: _isEditing,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    hintText: config.hint,
                    filled: true,
                    fillColor: AppColors.transparent,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                  ),
                  style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        if (hasError) ...[
          SizedBox(height: responsive.spacing(4)),
          Row(
            children: [
              Icon(Icons.error_outline, size: responsive.iconSize(14), color: AppColors.error),
              SizedBox(width: responsive.spacing(4)),
              Flexible(
                child: Text(
                  _fieldErrors['phone']!,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(responsive.spacing(7)),
          decoration: BoxDecoration(
            color: _headerColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          ),
          child: Icon(icon, size: responsive.iconSize(18), color: _headerColor),
        ),
        SizedBox(width: responsive.spacing(10)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                SizedBox(height: responsive.spacing(2)),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: responsive.fontSize(11),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required String label,
    required IconData icon,
    required String fieldKey,
    required Function(String) onChanged,
    required bool enabled,
    String? hint,
    TextInputType? keyboardType,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            fontWeight: FontWeight.w500,
            color: hasError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        Container(
          decoration: BoxDecoration(
            color: enabled ? AppColors.surface : AppColors.backgroundGray50,
            borderRadius: BorderRadius.circular(8),
            border: hasError
                ? Border.all(color: AppColors.error, width: 1.5)
                : null,
            boxShadow: [
              BoxShadow(
                color: AppColors.shadowLight,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _controllerForKey(fieldKey),
            onChanged: onChanged,
            enabled: enabled,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: AppColors.transparent,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
            style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textPrimary),
          ),
        ),
        if (hasError) ...[
          SizedBox(height: responsive.spacing(4)),
          Row(
            children: [
              Icon(Icons.error_outline, size: responsive.iconSize(14), color: AppColors.error),
              SizedBox(width: responsive.spacing(4)),
              Flexible(
                child: Text(
                  errorText,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required bool enabled,
    required Function(String) onChanged,
    String? errorText,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w500,
            color: hasError ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(6)),
        PopupMenuButton<String>(
          enabled: enabled,
          initialValue: value,
          onSelected: enabled ? onChanged : null,
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(12)),
            decoration: BoxDecoration(
              color: enabled ? AppColors.surface : AppColors.backgroundGray50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              border: hasError
                  ? Border.all(color: AppColors.error, width: 1.5)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowLight,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  value.isEmpty ? 'Not set' : value,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: enabled
                        ? (value.isEmpty
                              ? AppColors.textSecondary
                              : AppColors.textPrimary)
                        : AppColors.textSecondary,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ],
            ),
          ),
          itemBuilder: (context) {
            return items.map((item) {
              return PopupMenuItem<String>(
                value: item,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (item == value)
                      Icon(Icons.check, size: responsive.iconSize(18), color: _headerColor),
                  ],
                ),
              );
            }).toList();
          },
        ),
        if (hasError) ...[
          SizedBox(height: responsive.spacing(4)),
          Row(
            children: [
              Icon(Icons.error_outline, size: responsive.iconSize(14), color: AppColors.error),
              SizedBox(width: responsive.spacing(4)),
              Flexible(
                child: Text(
                  errorText,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildErrorCard() {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Text(
              _error ?? '',
              style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Returns a formatted member-since date from the user's registration.
  String _getMemberSinceDate() {
    final profile = ref.read(userProfileProvider);
    if (profile.createdAt.isNotEmpty) {
      try {
        final date = DateTime.parse(profile.createdAt);
        return _formatDate(date);
      } on Object catch (_) {
        return 'N/A';
      }
    }
    return 'N/A';
  }

  /// Converts a stored state abbreviation (e.g. "CA") to the display label
  /// (e.g. "California (CA)"). Returns empty string if not found.
  String _getStateDisplayLabel(String abbreviation) {
    if (abbreviation.isEmpty) return '';
    final fullName = _usStateMap[abbreviation.toUpperCase()];
    if (fullName != null) return '$fullName ($abbreviation)';
    // If already a display label or unknown, return as-is.
    return abbreviation;
  }

  /// Extracts the state abbreviation from a display label like "California (CA)".
  String _extractStateAbbreviation(String displayLabel) {
    final match = RegExp(r'\(([A-Z]{2})\)$').firstMatch(displayLabel);
    if (match != null) return match.group(1)!;
    return displayLabel;
  }
}
