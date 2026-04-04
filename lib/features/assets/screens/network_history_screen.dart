import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../services/api_client.dart';

/// Displays all network devices ever seen on scans, sorted by lastSeen desc.
/// Data comes from GET /api/v1/discovery/history.
class NetworkHistoryScreen extends StatefulWidget {
  const NetworkHistoryScreen({super.key});

  @override
  State<NetworkHistoryScreen> createState() => _NetworkHistoryScreenState();
}

class _NetworkHistoryScreenState extends State<NetworkHistoryScreen> {
  List<Map<String, dynamic>> _devices = [];
  bool _loading = true;
  String? _error;
  String _filter = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final response = await ApiClient().get('/discovery/history', queryParameters: {'limit': '200'});
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (body['data'] as List?)?.cast<Map<String, dynamic>>() ?? [];
        setState(() {
          _devices = data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server returned ${response.statusCode}';
          _loading = false;
        });
      }
    } on Object catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter.isEmpty) return _devices;
    final q = _filter.toLowerCase();
    return _devices.where((d) {
      final name = (d['deviceName'] ?? '').toString().toLowerCase();
      final mfr  = (d['manufacturer'] ?? '').toString().toLowerCase();
      final ip   = (d['ipAddress'] ?? '').toString().toLowerCase();
      final host = (d['hostname'] ?? '').toString().toLowerCase();
      return name.contains(q) || mfr.contains(q) || ip.contains(q) || host.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final devices = _filtered;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Network History',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────────────
          Container(
            color: primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: TextField(
              onChanged: (v) => setState(() => _filter = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search by name, manufacturer or IP…',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                prefixIcon: Icon(Icons.search, color: Colors.white.withValues(alpha: 0.8)),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),

          // ── Body ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _ErrorView(error: _error!, onRetry: _load)
                    : devices.isEmpty
                        ? _EmptyView(hasFilter: _filter.isNotEmpty)
                        : _DeviceList(devices: devices),
          ),
        ],
      ),
    );
  }
}

// ── Device list ──────────────────────────────────────────────────────────────

class _DeviceList extends StatelessWidget {
  const _DeviceList({required this.devices});
  final List<Map<String, dynamic>> devices;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: devices.length,
      itemBuilder: (context, i) => _DeviceCard(device: devices[i]),
    );
  }
}

// ── Single device card ───────────────────────────────────────────────────────

class _DeviceCard extends StatelessWidget {
  const _DeviceCard({required this.device});
  final Map<String, dynamic> device;

  @override
  Widget build(BuildContext context) {
    final meta        = device['metadata'] as Map<String, dynamic>? ?? {};
    final name        = (device['deviceName'] as String?)?.isNotEmpty == true
        ? device['deviceName'] as String
        : (device['hostname'] as String?) ?? 'Unknown Device';
    final ip          = (device['ipAddress'] as String?) ?? '—';
    final mfr         = (device['manufacturer'] as String?) ?? 'Unknown';
    final category    = (meta['category'] as String?) ?? '';
    final model       = (meta['model'] as String?) ?? '';
    final confidence  = (meta['confidence'] as num?)?.toInt() ?? 0;
    final status      = (device['status'] as String?) ?? 'unknown';
    final rawLastSeen = device['lastSeen'] as String?;
    final lastSeen    = rawLastSeen != null
        ? _formatDate(DateTime.tryParse(rawLastSeen))
        : '—';
    final isOnline    = status == 'online';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 2,
      shadowColor: Colors.black12,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _categoryColor(category).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_categoryIcon(category),
                    color: _categoryColor(category), size: 26),
              ),
              const SizedBox(width: 12),

              // Main info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 14)),
                        ),
                        _ConfidenceBadge(score: confidence),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(mfr,
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    if (model.isNotEmpty)
                      Text(model,
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(icon: Icons.router, label: ip),
                        const SizedBox(width: 6),
                        if (category.isNotEmpty)
                          _Chip(icon: Icons.devices, label: category),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.7)),
                        const SizedBox(width: 3),
                        Text('Last seen $lastSeen',
                            style: TextStyle(
                                color: AppColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 11)),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isOnline ? Colors.green : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(isOnline ? 'Online' : 'Offline',
                            style: TextStyle(
                                fontSize: 11,
                                color: isOnline ? Colors.green : Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    final meta        = device['metadata'] as Map<String, dynamic>? ?? {};
    final name        = (device['deviceName'] as String?)?.isNotEmpty == true
        ? device['deviceName'] as String
        : (device['hostname'] as String?) ?? 'Unknown Device';
    final ip          = (device['ipAddress'] as String?) ?? '—';
    final mac         = (device['macAddress'] as String?) ?? '—';
    final mfr         = (device['manufacturer'] as String?) ?? 'Unknown';
    final category    = (meta['category'] as String?) ?? '';
    final model       = (meta['model'] as String?) ?? '';
    final serial      = (meta['serial'] as String?) ?? '';
    final confidence  = (meta['confidence'] as num?)?.toInt() ?? 0;
    final method      = (meta['discoveryMethod'] as String?) ?? '';
    final httpBanner  = (meta['httpBanner'] as String?) ?? '';
    final htmlTitle   = (meta['htmlTitle'] as String?) ?? '';
    final osHint      = (meta['osHint'] as String?) ?? '';
    final snmpDescr   = (meta['snmpDescr'] as String?) ?? '';
    final ports       = (device['openPorts'] as List?)?.cast<int>() ?? [];
    final rawLastSeen = device['lastSeen'] as String?;
    final lastSeen    = rawLastSeen != null
        ? _formatDate(DateTime.tryParse(rawLastSeen))
        : '—';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _categoryColor(category).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(_categoryIcon(category),
                        color: _categoryColor(category), size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        if (mfr.isNotEmpty)
                          Text(mfr,
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  _ConfidenceBadge(score: confidence, large: true),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(),
              _DetailRow('IP Address',   ip),
              _DetailRow('MAC Address',  mac),
              if (category.isNotEmpty) _DetailRow('Category',      category),
              if (model.isNotEmpty)    _DetailRow('Model',         model),
              if (serial.isNotEmpty)   _DetailRow('Serial',        serial),
              if (method.isNotEmpty)   _DetailRow('Discovered via', method),
              _DetailRow('Last Seen',   lastSeen),
              if (httpBanner.isNotEmpty) _DetailRow('HTTP Banner',  httpBanner),
              if (htmlTitle.isNotEmpty)  _DetailRow('Page Title',   htmlTitle),
              if (osHint.isNotEmpty)     _DetailRow('OS Hint',      osHint),
              if (snmpDescr.isNotEmpty)  _DetailRow('SNMP Descr',   snmpDescr),
              if (ports.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text('Open Ports',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: ports
                      .map((p) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$p',
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF4F46E5))),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'router':
      case 'network equipment':
        return Icons.router;
      case 'printer':
        return Icons.print;
      case 'smart tv':
      case 'streaming device':
        return Icons.tv;
      case 'smart speaker':
        return Icons.speaker;
      case 'smart plug':
      case 'smart switch':
      case 'smart hub':
        return Icons.electrical_services;
      case 'ip camera':
      case 'security camera':
        return Icons.videocam;
      case 'nas / storage':
        return Icons.storage;
      case 'media server':
        return Icons.video_library;
      case 'computer':
      case 'laptop':
        return Icons.computer;
      case 'phone':
        return Icons.smartphone;
      default:
        return Icons.devices;
    }
  }

  static Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'router':
      case 'network equipment':
        return const Color(0xFF6366F1);
      case 'printer':
        return const Color(0xFF0EA5E9);
      case 'smart tv':
      case 'streaming device':
        return const Color(0xFF8B5CF6);
      case 'smart speaker':
        return const Color(0xFF14B8A6);
      case 'smart plug':
      case 'smart switch':
      case 'smart hub':
        return const Color(0xFFF59E0B);
      case 'ip camera':
      case 'security camera':
        return const Color(0xFFEF4444);
      case 'nas / storage':
        return const Color(0xFF10B981);
      case 'media server':
        return const Color(0xFFEC4899);
      case 'computer':
      case 'laptop':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF6366F1);
    }
  }

  static String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1)  return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)   return '${diff.inHours}h ago';
    if (diff.inDays < 7)     return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ── Minor helper widgets ─────────────────────────────────────────────────────

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({required this.score, this.large = false});
  final int score;
  final bool large;

  Color get _color {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 50) return Colors.orange.shade600;
    return Colors.red.shade400;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: large ? 10 : 7, vertical: large ? 4 : 3),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Text('$score%',
          style: TextStyle(
              fontSize: large ? 13 : 11,
              fontWeight: FontWeight.w700,
              color: _color)),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Empty / Error states ─────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.hasFilter});
  final bool hasFilter;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.wifi_find,
            size: 72, color: AppColors.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          hasFilter
              ? 'No devices match your search'
              : 'No network history yet.\nRun a WiFi scan to populate this list.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
        ),
      ]),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});
  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.cloud_off,
              size: 64, color: Colors.red.shade300),
          const SizedBox(height: 12),
          Text('Could not load history',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Colors.red.shade600)),
          const SizedBox(height: 6),
          Text(error,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}
