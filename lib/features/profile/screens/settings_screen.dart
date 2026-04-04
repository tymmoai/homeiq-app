import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme_presets.dart';
import '../../../providers/button_layout_provider.dart';
import '../../../providers/theme_provider.dart';
import '../../../utils/responsive_utils.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  // Header color now derived from the active theme preset
  Color get _headerColor => AppColors.headerBackground;

  bool _isSaving = false;
  String? _successMessage;
  String? _errorMessage;

  // Password controllers
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  // Mock user preferences - shared across app while the app is running
  // so that changes feel global after saving.
  static final Map<String, dynamic> _preferences = {
    'theme': 'light',
    'colorTheme': 'default',
    'notifications': {
      'email': true,
      'sms': true,
      'inApp': true,
      'maintenanceReminders': true,
      'serviceBookings': true,
      'assetAlerts': true,
    },
    'maintenance': {
      'autoSchedule': true,
      'healthScoreThreshold': 6.0,
      'advanceNoticeDays': 7,
    },
    'language': 'en',
    'dateTimeFormat': {
      'dateFormat': 'MM/DD/YYYY',
      'timeFormat': '12h',
    },
    'defaultHomeId': '',
  };

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 2,
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
          'Settings',
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
            // Success/Error Messages
            if (_successMessage != null) ...[
              _buildMessageCard(_successMessage!, true),
              SizedBox(height: responsive.spacing(16)),
            ],
            if (_errorMessage != null) ...[
              _buildMessageCard(_errorMessage!, false),
              SizedBox(height: responsive.spacing(16)),
            ],
            // â”€â”€ Preferences: Theme Color â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
            _buildSectionCard(
              icon: Icons.palette,
              title: 'Preferences',
              children: [
                _buildThemePickerSection(),
                SizedBox(height: responsive.spacing(20)),
                _buildButtonLayoutSection(),
              ],
            ),
            SizedBox(height: responsive.spacing(8)),
            // Notifications Section
            _buildSectionCard(
              icon: Icons.notifications,
              title: 'Notifications',
              children: [
                _buildSwitchTile(
                  title: 'Email Notifications',
                  subtitle: 'Receive notifications via email',
                  value: _preferences['email'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['email'] = value;
                    });
                  },
                ),
                SizedBox(height: responsive.spacing(12)),
                _buildSwitchTile(
                  title: 'SMS Notifications',
                  subtitle: 'Receive notifications via SMS',
                  value: _preferences['sms'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['sms'] = value;
                    });
                  },
                ),
                SizedBox(height: responsive.spacing(12)),
                _buildSwitchTile(
                  title: 'In-App Notifications',
                  subtitle: 'Show notifications within the app',
                  value: _preferences['inApp'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['inApp'] = value;
                    });
                  },
                ),
                SizedBox(height: responsive.spacing(12)),
                const Divider(),
                SizedBox(height: responsive.spacing(12)),
                Text(
                  'Notification Types',
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),
                _buildSwitchTile(
                  title: 'Maintenance Reminders',
                  subtitle: 'Get reminders for scheduled maintenance',
                  value: _preferences['maintenanceReminders'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['maintenanceReminders'] = value;
                    });
                  },
                ),
                SizedBox(height: responsive.spacing(12)),
                _buildSwitchTile(
                  title: 'Service Booking Updates',
                  subtitle: 'Updates about your service bookings',
                  value: _preferences['serviceBookings'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['serviceBookings'] = value;
                    });
                  },
                ),
                SizedBox(height: responsive.spacing(12)),
                _buildSwitchTile(
                  title: 'Appliance Alerts',
                  subtitle: 'Warranty expiration and appliance health warnings',
                  value: _preferences['assetAlerts'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['assetAlerts'] = value;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(8)),
            // Maintenance Preferences Section
            _buildSectionCard(
              icon: Icons.build,
              title: 'Maintenance Preferences',
              children: [
                _buildSwitchTile(
                  title: 'Auto-Schedule Maintenance',
                  subtitle: 'Automatically schedule maintenance reminders',
                  value: _preferences['autoSchedule'] ?? false,
                  onChanged: (value) {
                    setState(() {
                      _preferences['autoSchedule'] = value;
                    });
                  },
                ),
                SizedBox(height: responsive.spacing(12)),
                _buildHealthScoreThresholdSection(),
                SizedBox(height: responsive.spacing(4)),
                _buildAdvanceNoticeSection(),
              ],
            ),
            SizedBox(height: responsive.spacing(8)),
            // Language & Region Section
            _buildSectionCard(
              icon: Icons.language,
              title: 'Language & Region',
              children: [
                _buildLanguageDropdown(),
                SizedBox(height: responsive.spacing(10)),
                Row(
                  children: [
                    Expanded(
                      child: _buildDateTimeFormatDropdown(
                        label: 'Date Format',
                        value: _preferences['dateFormat'] ?? 'MM/DD/YYYY',
                        items: const ['MM/DD/YYYY', 'DD/MM/YYYY'],
                        onChanged: (value) {
                          setState(() {
                            _preferences['dateFormat'] = value;
                          });
                        },
                      ),
                    ),
                    SizedBox(width: responsive.spacing(10)),
                    Expanded(
                      child: _buildDateTimeFormatDropdown(
                        label: 'Time Format',
                        value: _preferences['timeFormat'] ?? '12h',
                        items: const ['12h', '24h'],
                        onChanged: (value) {
                          setState(() {
                            _preferences['timeFormat'] = value;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(15)),
            // Save Button
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/home');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                SizedBox(width: responsive.spacing(8)),
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
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.save, size: responsive.iconSize(18)),
                              SizedBox(width: responsive.spacing(8)),
                              const Text('Save'),
                            ],
                          ),
                  ),
                ),
              ],
            ),
           
          ],
        ),
      ),
    );
  }

  Widget _buildMessageCard(String message, bool isSuccess) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: isSuccess
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
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
          Icon(
            isSuccess ? Icons.check_circle : Icons.error_outline,
            color: isSuccess ? AppColors.success : AppColors.error,
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                color: isSuccess ? AppColors.success : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
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
          Row(
            children: [
              Icon(icon, size: responsive.iconSize(20), color: AppColors.primary),
              SizedBox(width: responsive.spacing(12)),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(18),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.primary,
          activeTrackColor: AppColors.primary.withValues(alpha: 0.4),
        ),
      ],
    );
  }

  Widget _buildHealthScoreThresholdSection() {
    final threshold = (_preferences['healthScoreThreshold'] as num?)?.toDouble() ?? 6.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Appliance Health Alert Level',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Get alerts when appliance health falls below this level',
          style: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Expanded(
              child: Slider(
                value: threshold,
                min: 0,
                max: 10,
                divisions: 20,
                label: '$threshold/10',
                activeColor: AppColors.primary,
                onChanged: (value) {
                  setState(() {
                    _preferences['healthScoreThreshold'] = value;
                  });
                },
              ),
            ),
            SizedBox(width: responsive.spacing(16)),
            Container(
              width: 60,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(8), horizontal: responsive.spacing(12)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray100,
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Text(
                '$threshold/10',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdvanceNoticeSection() {
    final days = _preferences['advanceNoticeDays'] as int? ?? 7;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Advance Notice Days',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'How many days before maintenance should you be notified?',
          style: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [1, 3, 7].map((dayValue) {
            final isSelected = days == dayValue;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: dayValue != 7 ? 8 : 0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _preferences['advanceNoticeDays'] = dayValue;
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: responsive.spacing(10)),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowLight,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$dayValue ${dayValue == 1 ? 'Day' : 'Days'}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLanguageDropdown() {
    return _buildDropdownField(
      label: 'Language',
      value: _preferences['language'] as String? ?? 'en',
      items: const [
        {'value': 'en', 'label': 'English'},
        {'value': 'hi', 'label': 'Hindi'},
        {'value': 'es', 'label': 'Spanish'},
        {'value': 'fr', 'label': 'French'},
      ],
      onChanged: (value) {
        setState(() {
          _preferences['language'] = value;
        });
      },
    );
  }

  Widget _buildDateTimeFormatDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        _buildSimpleDropdown(
          value: value,
          items: items,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<Map<String, String>> items,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        _buildSimpleDropdown(
          value: value,
          items: items.map((item) => item['value']!).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSimpleDropdown({
    required String value,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return PopupMenuButton<String>(
      initialValue: value,
      onSelected: onChanged,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(12)),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
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
            Expanded(
              child: Text(
                items.firstWhere((item) => item == value, orElse: () => value),
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: value.isEmpty ? AppColors.textSecondary : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: AppColors.textPrimary),
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
                  Icon(Icons.check, size: responsive.iconSize(18), color: AppColors.primary),
              ],
            ),
          );
        }).toList();
      },
    );
  }

  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•
  //  THEME PICKER
  // â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•â•

  Widget _buildThemePickerSection() {
    final currentPreset = ref.watch(themePresetProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'App Theme Color',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Choose a color theme â€” it changes the entire app instantly',
          style: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // Grid of theme swatches
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.72,
          ),
          itemCount: AppThemePresets.all.length,
          itemBuilder: (context, index) {
            final preset = AppThemePresets.all[index];
            final isSelected = preset.id == currentPreset.id;

            return _buildThemeSwatch(preset, isSelected);
          },
        ),
        SizedBox(height: responsive.spacing(16)),
        // Current theme indicator
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(horizontal: responsive.spacing(14), vertical: responsive.spacing(10)),
          decoration: BoxDecoration(
            color: (currentPreset.brightness == Brightness.dark
                    ? const Color(0xFF263238)
                    : currentPreset.primary)
                .withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: (currentPreset.brightness == Brightness.dark
                      ? const Color(0xFF263238)
                      : currentPreset.primary)
                  .withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: (currentPreset.brightness == Brightness.dark
                            ? const Color(0xFF263238)
                            : currentPreset.primary)
                        .withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        color: currentPreset.brightness == Brightness.dark
                            ? const Color(0xFF1E1E1E)
                            : currentPreset.primary,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        color: currentPreset.accent,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: responsive.spacing(12)),
              Expanded(
                child: Text(
                  'Active: ${currentPreset.name}',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: currentPreset.brightness == Brightness.dark
                        ? const Color(0xFF263238)
                        : currentPreset.primary,
                  ),
                ),
              ),
              Text(
                currentPreset.emoji,
                style: TextStyle(fontSize: responsive.fontSize(18)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeSwatch(AppThemePreset preset, bool isSelected) {
    return GestureDetector(
      onTap: () {
        ref.read(themePresetProvider.notifier).selectTheme(preset.id);
      },
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
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            SizedBox(height: responsive.spacing(4)),
            Text(
              preset.name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: responsive.fontSize(9),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (preset.brightness == Brightness.dark
                        ? const Color(0xFF263238)
                        : preset.primary)
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  BUTTON LAYOUT PICKER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildButtonLayoutSection() {
    final currentLayout = ref.watch(buttonLayoutProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Button Style',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Choose button shape — changes all buttons across the app',
          style: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.textSecondary.withValues(alpha: 0.8),
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            _buildSettingsLayoutOption(
              label: 'Capsule',
              mode: ButtonLayoutMode.capsule,
              isSelected: currentLayout == ButtonLayoutMode.capsule,
              borderRadius: 50,
            ),
            SizedBox(width: responsive.spacing(12)),
            _buildSettingsLayoutOption(
              label: 'Normal',
              mode: ButtonLayoutMode.normal,
              isSelected: currentLayout == ButtonLayoutMode.normal,
              borderRadius: 12,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSettingsLayoutOption({
    required String label,
    required ButtonLayoutMode mode,
    required bool isSelected,
    required double borderRadius,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(buttonLayoutProvider.notifier).setLayout(mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2.5 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.15),
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
                  color: isSelected ? AppColors.primary : AppColors.gray300,
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
                    Icon(Icons.check_circle, size: responsive.iconSize(14), color: AppColors.primary),
                  if (isSelected) SizedBox(width: responsive.spacing(4)),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      color:
                          isSelected ? AppColors.primary : AppColors.textSecondary,
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

  Future<void> _handleSave() async {
    setState(() {
      _isSaving = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isSaving = false;
        _successMessage = 'Settings saved successfully!';
      });
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _successMessage = null;
          });
        }
      });
    } on Object catch (_) {
      setState(() {
        _isSaving = false;
        _errorMessage = 'Failed to save settings. Please try again.';
      });
    }
  }

}
