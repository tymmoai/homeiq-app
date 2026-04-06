import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../core/utils/logger.dart';
import '../../../../services/api_client.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/maintenance_models.dart';

class MaintenancePartsOrderScreen extends StatefulWidget {
  final Reminder reminder;

  const MaintenancePartsOrderScreen({super.key, required this.reminder});

  @override
  State<MaintenancePartsOrderScreen> createState() =>
      _MaintenancePartsOrderScreenState();
}

class _MaintenancePartsOrderScreenState
    extends State<MaintenancePartsOrderScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  bool _isLoading = true;
  String? _error;
  List<_Part> _parts = [];
  List<bool> _selectedParts = [];
  bool _showComparison = false;
  int _subtotal = 0;
  Map<String, int> _providerTotals = {};
  // ignore: unused_field
  Map<String, int>? _priceRange;

  // Use centralized backend API

  final _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _generatePartsFromMaintenance();
  }

  Future<void> _generatePartsFromMaintenance() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _apiClient.post(
        '/ai/generate-maintenance-parts',
        body: {
          'taskName': widget.reminder.taskName,
          'assetName': widget.reminder.assetName,
          'assetLocation': widget.reminder.assetLocation,
          'whyItMatters': widget.reminder.whyItMatters,
        },
        timeout: const Duration(seconds: 20),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch parts');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['data'] ?? data;
      final partsJson = content['parts'] as List<dynamic>? ?? [];

      final parsed = <_Part>[];
      for (final p in partsJson) {
        final part = p as Map<String, dynamic>;
        parsed.add(
          _Part(
            name: part['name'] as String? ?? 'Part',
            quantity: (part['qty'] as num?)?.toInt() ?? 1,
            description: part['description'] as String? ?? '',
          ),
        );
      }

      // Fallback if parsing fails
      final finalParts = parsed.isNotEmpty
          ? parsed.take(4).toList()
          : [
              _Part(
                name: 'General replacement part',
                quantity: 1,
                description: 'Likely component based on maintenance task',
              ),
            ];

      // Generate prices (Encompass base, others higher)
      final baseMin = 95 + (finalParts.length * 5);
      final weights = List.generate(
        finalParts.length,
        (_) => 0.5 + (0.5 * (1 / finalParts.length)),
      );
      final sumW = weights.fold<double>(0.0, (a, b) => a + b);
      final encPrices = weights
          .map((w) => ((w / sumW * baseMin).round()))
          .toList();

      // Adjust for rounding
      final drift = baseMin - encPrices.fold<int>(0, (a, b) => a + b);
      if (drift != 0 && encPrices.isNotEmpty) {
        encPrices[0] = encPrices[0] + drift;
      }

      final partsWithPrices = finalParts.asMap().entries.map((entry) {
        final i = entry.key;
        final part = entry.value;
        return _Part(
          name: part.name,
          quantity: part.quantity,
          description: part.description,
          priceEncompass: encPrices[i],
          priceMarcone: encPrices[i] + 3 + (i % 7),
          priceLocal: encPrices[i] + 8 + (i % 12),
        );
      }).toList();

      final allSelected = List.generate(partsWithPrices.length, (_) => true);
      final encTotal = partsWithPrices.fold<int>(
        0,
        (sum, p) => sum + (p.priceEncompass * p.quantity),
      );

      setState(() {
        _parts = partsWithPrices;
        _selectedParts = allSelected;
        _subtotal = encTotal;
        _providerTotals = {'Encompass': encTotal};
        _priceRange = {
          'min': encTotal.clamp(95, 125),
          'max': (encTotal + 10).clamp(95, 125),
        };
        _isLoading = false;
      });
    } on Object catch (e) {
      AppLogger.error(
        'Error generating parts: $e',
        tag: 'PartsOrder',
        error: e,
      );
      setState(() {
        _error = 'Unable to load parts. Please try again.';
        _isLoading = false;
        // Fallback parts
        _parts = [
          _Part(
            name: 'Replacement part',
            quantity: 1,
            description: 'Component for maintenance',
            priceEncompass: 25,
            priceMarcone: 32,
            priceLocal: 45,
          ),
          _Part(
            name: 'Cleaning supplies',
            quantity: 1,
            description: 'For maintenance cleaning',
            priceEncompass: 32,
            priceMarcone: 40,
            priceLocal: 50,
          ),
          _Part(
            name: 'Accessories',
            quantity: 1,
            description: 'Additional items needed',
            priceEncompass: 45,
            priceMarcone: 55,
            priceLocal: 65,
          ),
        ];
        _selectedParts = List.generate(_parts.length, (_) => true);
        _subtotal = _parts.fold(
          0,
          (sum, p) => sum + (p.priceEncompass * p.quantity),
        );
        _providerTotals = {'Encompass': _subtotal};
        _priceRange = {'min': 95, 'max': 112};
      });
    }
  }

  void _updateSelection(int index, bool value) {
    setState(() {
      _selectedParts[index] = value;
      _recalculateTotals();
    });
  }

  void _recalculateTotals() {
    final encTotal = _parts.asMap().entries.fold(0, (sum, entry) {
      final i = entry.key;
      final part = entry.value;
      return sum +
          (_selectedParts[i] ? part.priceEncompass * part.quantity : 0);
    });

    setState(() {
      _subtotal = encTotal;
      _providerTotals = {'Encompass': encTotal};
      if (_showComparison) {
        final marcTotal = _parts.asMap().entries.fold(0, (sum, entry) {
          final i = entry.key;
          final part = entry.value;
          return sum +
              (_selectedParts[i] ? part.priceMarcone * part.quantity : 0);
        });
        final localTotal = _parts.asMap().entries.fold(0, (sum, entry) {
          final i = entry.key;
          final part = entry.value;
          return sum +
              (_selectedParts[i] ? part.priceLocal * part.quantity : 0);
        });
        _providerTotals = {
          'Encompass': encTotal,
          'Marcone': marcTotal,
          'Reliable Parts': localTotal,
        };
      }
    });
  }

  void _toggleComparison() {
    setState(() {
      _showComparison = !_showComparison;
      _recalculateTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        leading: const SizedBox.shrink(),
        title: Text(
          AppStrings.aiNameFull,
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
            fontSize: responsive.fontSize(18),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: AppColors.white),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _parts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_error!),
                  SizedBox(height: responsive.spacing(16)),
                  ElevatedButton(
                    onPressed: _generatePartsFromMaintenance,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(24),
                        vertical: responsive.spacing(12),
                      ),
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Container(
              color: AppColors.backgroundGray50,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.spacing(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and Estimated
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Parts for Maintenance',
                          style: TextStyle(
                            fontSize: responsive.fontSize(24),
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          widget.reminder.taskName,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            color: AppColors.gray600,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(15)),
                    // Selected summary + Parts list in one container
                    Container(
                      padding: EdgeInsets.all(responsive.spacing(16)),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  'Selected: ${_selectedParts.where((s) => s).length} parts',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  'Subtotal: \$$_subtotal',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.spacing(16)),
                          // Parts list
                          Column(
                            children: _parts.asMap().entries.map((entry) {
                              final index = entry.key;
                              final part = entry.value;
                              final isSelected = _selectedParts[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index < _parts.length - 1 ? 15 : 0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Checkbox(
                                      value: isSelected,
                                      onChanged: (value) => _updateSelection(
                                        index,
                                        value ?? false,
                                      ),
                                      activeColor: AppColors.black,
                                    ),
                                    SizedBox(width: responsive.spacing(12)),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${part.name} ×${part.quantity}',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(14),
                                              fontWeight: FontWeight.w500,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          if (part.description != null) ...[
                                            SizedBox(
                                              height: responsive.spacing(4),
                                            ),
                                            Text(
                                              part.description!,
                                              style: TextStyle(
                                                fontSize: responsive.fontSize(
                                                  12,
                                                ),
                                                color: AppColors.gray600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '\$${part.priceEncompass * part.quantity}',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(14),
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          '\$${part.priceEncompass} each',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12),
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24)),
                    // Total Price section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Price',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!_showComparison)
                          TextButton(
                            onPressed: _toggleComparison,
                            child: Text(
                              'Compare',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: responsive.spacing(12)),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(8),
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
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(16)),
                            decoration: BoxDecoration(
                              color: AppColors.backgroundGray50,
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(8),
                              ),
                              border: Border(
                                bottom: BorderSide(color: AppColors.border),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Encompass',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(14),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(width: responsive.spacing(8)),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: responsive.spacing(8),
                                        vertical: responsive.spacing(2),
                                      ),
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
                                      child: Text(
                                        'Recommended',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(10),
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '\$${_providerTotals['Encompass'] ?? 0}',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_showComparison &&
                              _providerTotals.containsKey('Marcone'))
                            Container(
                              padding: EdgeInsets.all(responsive.spacing(16)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Marcone',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '\$${_providerTotals['Marcone']}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (_showComparison &&
                              _providerTotals.containsKey('Reliable Parts'))
                            Container(
                              padding: EdgeInsets.all(responsive.spacing(16)),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Reliable Parts',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    '\$${_providerTotals['Reliable Parts']}',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.spacing(32)),
                    // Buy Parts button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _selectedParts.any((s) => s)
                            ? () {
                                // Navigate to checkout address screen
                                context.push(
                                  '/maintenance/parts-checkout-address',
                                  extra: {
                                    'reminder': widget.reminder,
                                    'parts': _parts,
                                    'selectedParts': _selectedParts,
                                    'subtotal': _subtotal,
                                    'providerTotals': _providerTotals,
                                  },
                                );
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          elevation: 0,
                        ),
                        child: Text(
                          'Buy Parts (\$${_providerTotals['Encompass'] ?? 0})',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(20)),
                  ],
                ),
              ),
            ),
    );
  }
}

class _Part {
  final String name;
  final int quantity;
  final String? description;
  final int priceEncompass;
  final int priceMarcone;
  final int priceLocal;

  _Part({
    required this.name,
    required this.quantity,
    this.description,
    this.priceEncompass = 0,
    this.priceMarcone = 0,
    this.priceLocal = 0,
  });
}
