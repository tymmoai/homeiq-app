import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../services/wifi_discovery_service.dart';
import '../../../shared/models/asset_form_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// WiFi Discovery Widget
//
// This widget plugs directly into Step 2 of the Add Asset flow.
// It lets users discover smart devices on their home WiFi and select one
// to auto-fill the brand, model, and serial number fields.
//
// FEATURES:
//   - Scan button with progress bar
//   - Device list with category icons
//   - Confirm dialog before filling form fields
//
// Usage:
//   WifiDiscoveryWidget(
//     onDeviceSelected: (brand, model, serial) {
//       // fill in the form fields
//     },
//   )
// ─────────────────────────────────────────────────────────────────────────────

class WifiDiscoveryWidget extends StatefulWidget {
  /// Called when the user confirms a device selection.
  final void Function(WifiDevice device) onDeviceSelected;

  /// Form data model — used to cache scan results across step navigation.
  final AssetFormModel formData;

  /// The resolved image source key ('serpapi', 'bestbuy', 'discovery_enrich', …).
  /// Passed from the parent after product-image lookup completes. When non-null
  /// a small source badge replaces the "Searching…" spinner.
  final String? resolvedImageSource;

  const WifiDiscoveryWidget({
    super.key,
    required this.onDeviceSelected,
    required this.formData,
    this.resolvedImageSource,
  });

  @override
  State<WifiDiscoveryWidget> createState() => _WifiDiscoveryWidgetState();
}

class _WifiDiscoveryWidgetState extends State<WifiDiscoveryWidget>
    with SingleTickerProviderStateMixin {
  final _service = WifiDiscoveryService();

  bool _isScanning = false;
  bool _hasScanStarted = false;
  double _progress = 0;
  String _scanMessage = '';
  List<WifiDevice> _devices = [];
  String? _error;

  // ── Filter & post-selection state ────────────────────────────────────────
  String _selectedFilter = 'All';
  bool _showLowConfidence = false;

  // Pulse animation for the radar/wifi icon during scanning
  // Nullable so hot reload never causes LateInitializationError.
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    // Restore cached scan results from form data (persists across step navigation)
    if (widget.formData.cachedWifiDevices.isNotEmpty) {
      _devices = widget.formData.cachedWifiDevices;
      _hasScanStarted = true;
      _progress = 100;
    }
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Maps raw service progress messages to user-friendly text.
  String _toFriendlyMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('checking permission') ||
        lower.contains('getting ready')) {
      return 'Getting ready…';
    }
    if (lower.contains('getting network info') ||
        lower.contains('multicast lock')) {
      return 'Preparing network scan…';
    }
    if (lower.contains('scanning all device') ||
        lower.contains('scanning your')) {
      return 'Scanning your WiFi network…';
    }
    final foundMatch = RegExp(r'Found (\d+) device').firstMatch(raw);
    if (foundMatch != null) {
      return 'Found ${foundMatch.group(1)} devices so far…';
    }
    final portMatch = RegExp(r'Scanning ports.*?(\d+)/(\d+)').firstMatch(raw);
    if (portMatch != null) {
      return 'Checking device ${portMatch.group(1)} of ${portMatch.group(2)}…';
    }
    final identifyMatch = RegExp(r'Identifying (\d+) device').firstMatch(raw);
    if (identifyMatch != null) {
      return 'Identifying ${identifyMatch.group(1)} devices…';
    }
    if (lower.contains('resolving device') || lower.contains('listening for')) {
      return 'Identifying devices on your network…';
    }
    if (lower.contains('loading') && lower.contains('device detail')) {
      return 'Reading device details…';
    }
    if (lower.contains('mdns done') || lower.contains('processing result')) {
      return 'Processing results…';
    }
    if (lower.contains('snmp scanning')) {
      return 'Scanning for additional info…';
    }
    if (lower.contains('enriching') ||
        lower.contains('looking up product') ||
        lower.contains('backend')) {
      return 'Looking up product details…';
    }
    if (lower.contains('deep-probing') || lower.contains('unidentified')) {
      return 'Identifying remaining devices…';
    }
    if (lower.startsWith('done')) {
      final count = RegExp(r'(\d+) device').firstMatch(raw);
      if (count != null) return 'Found ${count.group(1)} devices!';
      return 'Scan complete!';
    }
    return raw;
  }

  /// Devices filtered by the current category chip selection.
  List<WifiDevice> get _visibleDevices {
    if (_selectedFilter == 'All') return _devices;
    return _devices.where((d) => d.assetType == _selectedFilter).toList();
  }

  // Discovery logs removed from UI — debug output only via debugPrint

  // ── Scan ──────────────────────────────────────────────────────────────────

  Future<void> _startScan() async {
    setState(() {
      _isScanning = true;
      _hasScanStarted = true;
      _progress = 0;
      _scanMessage = 'Getting ready…';
      _devices = [];
      _error = null;
      _selectedFilter = 'All';
    });
    _pulseController?.repeat(reverse: true);

    final result = await _service.startDiscovery(
      onProgress: (progress, message) {
        if (mounted) {
          setState(() {
            // Animate progress smoothly: never go backwards, clamp to 0–100
            _progress = progress.toDouble().clamp(_progress, 100.0);
            _scanMessage = _toFriendlyMessage(message);
          });
        }
      },
    );

    if (!mounted) return;

    _pulseController?.stop();
    setState(() {
      _isScanning = false;
      _progress = 100;
      _devices = result.devices;
      _error = result.error;
    });
    // Cache scan results in form data so they survive step navigation
    widget.formData.cachedWifiDevices = result.devices;
  }

  // ── Device selected — show confirm dialog ─────────────────────────────────

  void _onDeviceTapped(WifiDevice device) {
    // Log full device diagnostics to console for debugging
    debugPrint('\n══════════════════════════════════════════════════════');
    debugPrint('DEVICE TAP: ${device.displayTitle}');
    debugPrint('══════════════════════════════════════════════════════');
    debugPrint('  IP Address:        ${device.ipAddress}');
    debugPrint('  MAC Address:       ${device.macAddress ?? "N/A"}');
    debugPrint('  Hostname:          ${device.hostname ?? "N/A"}');
    debugPrint('  Device Name (raw): ${device.deviceName}');
    debugPrint('  Manufacturer:      ${device.manufacturer}');
    debugPrint('  Category (raw):    ${device.deviceCategory}');
    debugPrint('  Type (raw):        ${device.deviceTypeRaw}');
    debugPrint('  Asset Type:        ${device.assetType}');
    debugPrint('  Icon Category:     ${device.iconCategory}');
    debugPrint('  Confidence:        ${device.confidenceScore}%');
    debugPrint('  Discovery Method:  ${device.discoveryMethod}');
    debugPrint('  TTL Value:         ${device.ttlValue ?? "N/A"}');
    debugPrint('  OS Hint:           ${device.osHint ?? "N/A"}');
    debugPrint('  OS Guess:          ${device.osGuess ?? "N/A"}');
    debugPrint('  Detected OS:       ${device.detectedOS ?? "N/A"}');
    debugPrint('  Brand Guess:       ${device.brandGuess ?? "N/A"}');
    debugPrint('  Model Number:      ${device.modelNumber ?? "N/A"}');
    debugPrint('  Serial Number:     ${device.serialNumber ?? "N/A"}');
    debugPrint('  DHCP Hostname:     ${device.dhcpHostname ?? "N/A"}');
    debugPrint('  HTTP Banner:       ${device.httpBanner ?? "N/A"}');
    debugPrint('  HTML Title:        ${device.htmlTitle ?? "N/A"}');
    debugPrint('  SSH Banner:        ${device.sshBanner ?? "N/A"}');
    debugPrint('  TLS Cert Subject:  ${device.tlsCertSubject ?? "N/A"}');
    debugPrint('  SMB OS Version:    ${device.smbOsVersion ?? "N/A"}');
    debugPrint('  Firmware Version:  ${device.firmwareVersion ?? "N/A"}');
    debugPrint('  Product Name:      ${device.productName ?? "N/A"}');
    debugPrint('  Product Image URL: ${device.productImageUrl ?? "N/A"}');
    if (device.openPorts.isNotEmpty) {
      debugPrint('  Open Ports:        ${device.openPorts.join(", ")}');
    }
    if (device.portFingerprint.isNotEmpty) {
      debugPrint('  Port Fingerprint:  ${device.portFingerprint.join(", ")}');
    }
    if (device.serviceVersions.isNotEmpty) {
      debugPrint('  Service Versions:');
      device.serviceVersions.forEach((port, ver) {
        debugPrint('    Port $port → $ver');
      });
    }
    if (device.fingerprintReasoning.isNotEmpty) {
      debugPrint('  Fingerprint Reasoning:');
      for (final step in device.fingerprintReasoning) {
        debugPrint('    • $step');
      }
    }
    if (device.backendData != null) {
      debugPrint('  Backend Data:      ${device.backendData}');
    }
    debugPrint('══════════════════════════════════════════════════════\n');

    showDialog<bool>(
      context: context,
      builder: (ctx) => _ConfirmDeviceDialog(
        device: device,
        onConfirm: () {
          Navigator.of(ctx).pop(true);
          widget.onDeviceSelected(device);
        },
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Info card — hidden while scan is running to reclaim space
        if (!_isScanning) ...[_buildInfoCard(), const SizedBox(height: 16)],

        // Scan button — idle state
        if (!_isScanning)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _startScan,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 0,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_find_rounded, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _hasScanStarted ? 'Scan Again' : 'Start WiFi Scan',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Compact scanning card — horizontal layout to minimise vertical space
        if (_isScanning)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                // Small pulsing radar icon
                _pulseAnimation != null
                    ? ScaleTransition(
                        scale: _pulseAnimation!,
                        child: _buildRadarIcon(),
                      )
                    : _buildRadarIcon(),
                const SizedBox(width: 12),
                // Progress bar + label
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: _progress / 100),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, _) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                _scanMessage,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${_progress.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 5,
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.15,
                            ),
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),

        // Error state
        if (_error != null) _buildErrorState(),

        // Empty state (scanned but nothing found)
        if (!_isScanning &&
            _hasScanStarted &&
            _devices.isEmpty &&
            _error == null)
          _buildEmptyState(),

        // Device list with category filter chips
        if (_devices.isNotEmpty) ...[_buildDeviceList()],
      ],
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildDeviceList() {
    final types = _devices.map((d) => d.assetType).toSet().toList()..sort();
    final visible = _visibleDevices;

    // Split into identified devices vs low-confidence unknowns.
    // A device is "low-confidence" if it has assetType == 'Unknown Device'
    // AND a confidence score below 40 — these are essentially just IP pings
    // with no useful identification data.
    final identified = <WifiDevice>[];
    final lowConfidence = <WifiDevice>[];
    for (final d in visible) {
      if (d.assetType == 'Unknown Device' && d.confidenceScore < 40) {
        lowConfidence.add(d);
      } else {
        identified.add(d);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category filter chips — only shown when multiple types are found
        if (types.length > 1) ...[
          _buildFilterChips(types),
          const SizedBox(height: 10),
        ],
        // Count row
        Text(
          _selectedFilter == 'All'
              ? '${_devices.length} device${_devices.length == 1 ? '' : 's'} found'
              : '${visible.length} of ${_devices.length} shown',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),

        // ── Identified devices (shown normally) ──────────────────────────
        if (identified.isNotEmpty)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: identified.length,
            separatorBuilder: (context2, i) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return _DeviceCard(
                device: identified[index],
                onTap: () => _onDeviceTapped(identified[index]),
              );
            },
          ),

        // ── Low-confidence collapsible group ─────────────────────────────
        if (lowConfidence.isNotEmpty) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () =>
                setState(() => _showLowConfidence = !_showLowConfidence),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.devices_other_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${lowConfidence.length} other device${lowConfidence.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    'Low confidence',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _showLowConfidence ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Expanded low-confidence device cards
          if (_showLowConfidence) ...[
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: lowConfidence.length,
              separatorBuilder: (context2, i) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                return _DeviceCard(
                  device: lowConfidence[index],
                  onTap: () => _onDeviceTapped(lowConfidence[index]),
                );
              },
            ),
          ],
        ],
      ],
    );
  }

  Widget _buildFilterChips(List<String> types) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: ['All', ...types].map((type) {
          final selected = _selectedFilter == type;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: ChoiceChip(
              label: Text(
                type,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              selected: selected,
              onSelected: (_) => setState(() => _selectedFilter = type),
              selectedColor: AppColors.primary,
              backgroundColor: AppColors.backgroundGray50,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.gray200,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              visualDensity: VisualDensity.compact,
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRadarIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.wifi_find_rounded, size: 18, color: AppColors.primary),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary05,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary20),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_find_rounded, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Make sure your phone is on the same WiFi as your smart devices — '
              'this scan will find fridges, washers, dryers, ovens, ACs, TVs, speakers, cameras, and more.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFFCCCC)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: Color(0xFFD32F2F),
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFD32F2F),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundGray50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Column(
        children: [
          Icon(Icons.devices_other_rounded, size: 36, color: AppColors.gray300),
          const SizedBox(height: 8),
          Text(
            'No smart devices found',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Make sure devices are powered on and connected to the same WiFi network.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Single device card — displayed in the results list.
// Shows rich fingerprint data: type, brand, OS, IP, ports, discovery method.
// ─────────────────────────────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  final WifiDevice device;
  final VoidCallback onTap;

  const _DeviceCard({required this.device, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Effective brand: prefer fingerprint brandGuess over manufacturer
    final effectiveBrand = (device.brandGuess?.isNotEmpty == true)
        ? device.brandGuess!
        : (device.manufacturer.isNotEmpty && device.manufacturer != 'Unknown')
        ? device.manufacturer
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary10,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForCategory(device.iconCategory),
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Name + category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.displayTitle,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      device.assetType,
                      if (effectiveBrand != null &&
                          !device.displayTitle.toLowerCase().contains(
                            effectiveBrand.toLowerCase(),
                          ))
                        effectiveBrand,
                      device.ipAddress,
                    ].join(' · '),
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForCategory(IconCategory cat) {
    switch (cat) {
      case IconCategory.tv:
        return Icons.tv_rounded;
      case IconCategory.speaker:
        return Icons.speaker_group_rounded;
      case IconCategory.printer:
        return Icons.print_rounded;
      case IconCategory.camera:
        return Icons.videocam_rounded;
      case IconCategory.smartPlug:
        return Icons.power_rounded;
      case IconCategory.lightBulb:
        return Icons.lightbulb_outline_rounded;
      case IconCategory.thermostat:
        return Icons.thermostat_rounded;
      case IconCategory.computer:
        return Icons.computer_rounded;
      case IconCategory.router:
        return Icons.router_rounded;
      case IconCategory.phone:
        return Icons.smartphone_rounded;
      case IconCategory.tablet:
        return Icons.tablet_rounded;
      case IconCategory.gameConsole:
        return Icons.sports_esports_rounded;
      case IconCategory.appliance:
        return Icons.kitchen_rounded;
      case IconCategory.generic:
        return Icons.devices_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confirmation dialog — shown when user taps a device
// Shows full detail including fingerprint reasoning so user can verify.
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmDeviceDialog extends StatelessWidget {
  final WifiDevice device;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ConfirmDeviceDialog({
    required this.device,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBrand = (device.brandGuess?.isNotEmpty == true)
        ? device.brandGuess!
        : (device.manufacturer.isNotEmpty && device.manufacturer != 'Unknown')
        ? device.manufacturer
        : null;

    final effectiveOS = (device.osGuess?.isNotEmpty == true)
        ? device.osGuess!
        : device.detectedOS;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Device icon + confidence
            Stack(
              alignment: Alignment.topRight,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.primary10,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconForCategory(device.iconCategory),
                    color: AppColors.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Device name
            Text(
              device.displayTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            // Category + Confidence row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    device.assetType,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6A1B9A),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _ConfidenceBadge(score: device.confidenceScore),
              ],
            ),
            const SizedBox(height: 16),

            // ── Device Details ────────────────────────────────────────
            const _SectionHeader(title: 'Device Details'),
            _Row(label: 'Type', value: device.assetType),
            if (effectiveBrand != null)
              _Row(label: 'Brand', value: effectiveBrand),
            if (effectiveOS != null && effectiveOS != 'Unknown OS')
              _Row(label: 'OS', value: effectiveOS),
            if (device.modelNumber != null && device.modelNumber!.isNotEmpty)
              _Row(label: 'Model', value: device.modelNumber!),
            if (device.serialNumber != null && device.serialNumber!.isNotEmpty)
              _Row(label: 'Serial', value: device.serialNumber!),

            const SizedBox(height: 12),
            Text(
              'You can edit these details in the next step.',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        Row(
          children: [
            Expanded(
              flex: 2,
              child: OutlinedButton(
                onPressed: onCancel,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cancel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: ElevatedButton(
                onPressed: onConfirm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                child: const Text(
                  'Use This Device',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _iconForCategory(IconCategory cat) {
    switch (cat) {
      case IconCategory.tv:
        return Icons.tv_rounded;
      case IconCategory.speaker:
        return Icons.speaker_group_rounded;
      case IconCategory.printer:
        return Icons.print_rounded;
      case IconCategory.camera:
        return Icons.videocam_rounded;
      case IconCategory.smartPlug:
        return Icons.power_rounded;
      case IconCategory.lightBulb:
        return Icons.lightbulb_outline_rounded;
      case IconCategory.thermostat:
        return Icons.thermostat_rounded;
      case IconCategory.computer:
        return Icons.computer_rounded;
      case IconCategory.router:
        return Icons.router_rounded;
      case IconCategory.phone:
        return Icons.smartphone_rounded;
      case IconCategory.tablet:
        return Icons.tablet_rounded;
      case IconCategory.gameConsole:
        return Icons.sports_esports_rounded;
      case IconCategory.appliance:
        return Icons.kitchen_rounded;
      case IconCategory.generic:
        return Icons.devices_rounded;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section header for confirmation dialog grouping
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: AppColors.divider, height: 1)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Confidence badge — shows a color-coded score chip
// ─────────────────────────────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  final int score;
  const _ConfidenceBadge({required this.score});

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    if (score >= 75) {
      bg = const Color(0xFFE8F5E9);
      fg = const Color(0xFF2E7D32);
    } else if (score >= 50) {
      bg = const Color(0xFFFFF3E0);
      fg = const Color(0xFFE65100);
    } else {
      bg = const Color(0xFFFFEBEE);
      fg = const Color(0xFFC62828);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$score%',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}
