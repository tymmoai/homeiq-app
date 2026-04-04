// Compare Drawer for Warranty Plans - Exact Layout Match

import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';

class WarrantyCompareDrawer extends StatefulWidget {
  final List<Map<String, dynamic>> plans;
  final Function(String) onRemovePlan;
  final Function(String) onSelectPlan;
  final VoidCallback onClose;
  final ScrollController? scrollController;
  final String? assetName; // Asset name to display

  const WarrantyCompareDrawer({
    super.key,
    required this.plans,
    required this.onRemovePlan,
    required this.onSelectPlan,
    required this.onClose,
    this.scrollController,
    this.assetName,
  });

  @override
  State<WarrantyCompareDrawer> createState() => _WarrantyCompareDrawerState();
}

class _WarrantyCompareDrawerState extends State<WarrantyCompareDrawer> {
  String _selectedDuration = 'monthly'; // 'monthly' or 'yearly'

  Color get _headerColor => Theme.of(context).colorScheme.primary; // App header color
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static const Color _successGreen = AppColors.success;

  /// Fixed width for feature title column so wrapping is consistent (min 1 line, max 2 lines).
  static const double _featureTitleColumnWidth = 110;

  // Coverage features to compare (no "Zero Deductible" â€” deductible amount is in SERVICE)
  final List<String> _coverageFeatures = [
    'No Service Fees',
    'Parts & Labor',
    'Accidental Damage',
    '24/7 Phone Support',
  ];

  String _getPlanShortName(String planName) {
    final name = planName.toLowerCase();
    if (name.contains('essential')) return 'Essential';
    if (name.contains('premium')) return 'Premium';
    if (name.contains('ultimate')) return 'Ultimate';
    if (name.contains(AppStrings.brandProvider)) return AppStrings.appName;
    if (name.contains('choice')) return 'Choice Total';
    if (name.contains('asurion')) return 'Asurion Home+';
    return planName;
  }

  bool _planHasFeature(Map<String, dynamic> plan, String feature, String duration) {
    // First check for duration-specific coverage/features
    final durationCoverage = plan['${duration}Coverage'] as List<dynamic>? ?? [];
    final durationFeatures = plan['${duration}Features'] as List<dynamic>? ?? [];
    
    // Check if this plan has duration-specific exclusion for this feature
    final durationExclusions = plan['${duration}Exclusions'] as List<dynamic>? ?? [];
    
    // Base features and coverage
    final features = plan['features'] as List<dynamic>? ?? [];
    final coverage = plan['coverage'] as List<dynamic>? ?? [];
    
    // Combine all features - prioritize duration-specific ones
    final allFeatures = [
      ...durationFeatures,
      ...durationCoverage,
      ...features,
      ...coverage,
    ].map((e) => e.toString().toLowerCase()).toList();
    
    final featureLower = feature.toLowerCase();
    
    // Check exclusions first - if excluded for this duration, return false
    final exclusionLower = durationExclusions.map((e) => e.toString().toLowerCase()).toList();
    if (exclusionLower.any((ex) => ex.contains(featureLower) || featureLower.contains(ex))) {
      return false;
    }
    
    // Direct match
    if (allFeatures.any((f) => f == featureLower)) return true;
    
    // Check for key words in feature name
    final featureWords = featureLower.split(' ');
    for (final word in featureWords) {
      if (word.length > 3) {
        if (allFeatures.any((f) => f.contains(word) || word.contains(f))) {
          return true;
        }
      }
    }
    
    // Specific feature checks with duration awareness
    if (featureLower.contains('zero') || featureLower.contains('deductible')) {
      // Check duration-specific deductible setting
      final durationDeductible = plan['${duration}Deductible'] as int?;
      if (durationDeductible != null) {
        return durationDeductible == 0;
      }
      return allFeatures.any((f) => f.contains('deductible') && (f.contains('zero') || f.contains('no') || f.contains('0')));
    }
    if (featureLower.contains('service fee') || featureLower.contains('no service')) {
      // Check duration-specific service fee setting
      final durationFee = plan['${duration}ServiceFee'] as int?;
      if (durationFee != null) {
        return durationFee == 0;
      }
      return allFeatures.any((f) => f.contains('service') && (f.contains('fee') || f.contains('free') || f.contains('no')));
    }
    if (featureLower.contains('parts') && featureLower.contains('labor')) {
      // Check duration-specific parts & labor
      final durationPartsLabor = plan['${duration}PartsLabor'] as bool?;
      if (durationPartsLabor != null) {
        return durationPartsLabor;
      }
      return allFeatures.any((f) => (f.contains('parts') || f.contains('labor')) || f.contains('parts & labor'));
    }
    if (featureLower.contains('accidental')) {
      // Check duration-specific accidental damage
      final durationAccidental = plan['${duration}AccidentalDamage'] as bool?;
      if (durationAccidental != null) {
        return durationAccidental;
      }
      return allFeatures.any((f) => f.contains('accidental') || f.contains('damage'));
    }
    if (featureLower.contains('24/7') || featureLower.contains('phone') || featureLower.contains('support')) {
      // 24/7 Phone Support: require 24/7 or "24" in the feature text so 9â€“5 plans show âœ–
      final durationSupport = plan['${duration}Support'] as bool?;
      if (durationSupport != null) {
        return durationSupport;
      }
      return allFeatures.any((f) =>
          (f.contains('24') || f.contains('24/7')) && (f.contains('support') || f.contains('phone')));
    }
    
    return false;
  }

  String _getPlanDeductible(Map<String, dynamic> plan, String duration) {
    // Check for duration-specific deductible
    final durationDeductible = plan['${duration}Deductible'] as int?;
    if (durationDeductible != null) {
      return durationDeductible == 0 ? 'No Deductible' : '\$$durationDeductible';
    }
    final deductible = plan['deductible'] as int? ?? 0;
    return deductible == 0 ? 'No Deductible' : '\$$deductible';
  }

  String _getPlanServiceFee(Map<String, dynamic> plan, String duration) {
    // Check for duration-specific service fee
    final durationFee = plan['${duration}ServiceFee'] as int?;
    if (durationFee != null) {
      return durationFee == 0 ? 'Free' : '\$$durationFee';
    }
    final fee = plan['serviceCallFee'] as int? ?? 0;
    return fee == 0 ? 'Free' : '\$$fee';
  }

  String _getPlanResponseTime(Map<String, dynamic> plan, String duration) {
    // Check for duration-specific response time
    final durationResponse = plan['${duration}ResponseTime'] as String?;
    if (durationResponse != null) {
      return durationResponse;
    }
    return plan['responseTime'] as String? ?? '24-48 hours';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.plans.isEmpty) {
      return Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.gray200,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shield, size: 32, color: _textSecondary),
              ),
              const SizedBox(height: 16),
              Text(
                'No plans selected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select 2-3 plans to compare them',
                style: TextStyle(
                  fontSize: 14,
                  color: _textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onClose,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _headerColor,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text('Browse Plans'),
              ),
            ],
          ),
        ),
      );
    }

    final planCount = widget.plans.length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with Asset Name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Compare Plans',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        if (widget.assetName != null && widget.assetName!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            widget.assetName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: _textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, size: 24, color: _textPrimary),
                    onPressed: widget.onClose,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Monthly/Yearly Toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            color: AppColors.white,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.gray200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDuration = 'monthly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedDuration == 'monthly' ? AppColors.white : AppColors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedDuration == 'monthly'
                              ? [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Monthly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _selectedDuration == 'monthly' ? _textPrimary : _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedDuration = 'yearly'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedDuration == 'yearly' ? AppColors.white : AppColors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedDuration == 'yearly'
                              ? [
                                  BoxShadow(
                                    color: AppColors.shadowLight,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          'Yearly',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _selectedDuration == 'yearly' ? _textPrimary : _textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Comparison Table â€” reduced horizontal padding for wider table
          Expanded(
            child: SingleChildScrollView(
              controller: widget.scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Container(
                margin: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 0),
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
                    // Header Row - PLANS + Plan Names (title column flex: 2 so feature column aligns with SERVICE/COVERAGE)
                    Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 0),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray50,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
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
                          SizedBox(
                            width: _featureTitleColumnWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'PLANS',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: _headerColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          ...widget.plans.map((plan) {
                            final planName = plan['name'] as String? ?? 'Plan';
                            final shortName = _getPlanShortName(planName);
                            final badge = plan['badge'] as String?;
                            final isPopular = badge?.toLowerCase().contains('popular') ?? false;
                            final isUltimate = shortName.toLowerCase().contains('ultimate');
                            
                            return Expanded(
                              flex: 2,
                              child: Container(
                                margin: const EdgeInsets.only(left: 1),
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isPopular) ...[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _headerColor,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'POPULAR',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.w900,
                                            color: AppColors.white,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                    ],
                                    Text(
                                      shortName,
                                      textAlign: TextAlign.center,
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: isUltimate ? _successGreen : _headerColor,
                                        height: 1.25,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    if (isPopular) ...[
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 3,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: _headerColor,
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),

                    // PRICING Section Header â€” title column flex: 2, padding 16 to align with feature rows
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray50,
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
                        children: [
                          SizedBox(
                            width: _featureTitleColumnWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'PRICING',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _headerColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          Expanded(flex: planCount, child: const SizedBox()),
                        ],
                      ),
                    ),

                    // Price Row â€” shows only selected duration (monthly or yearly)
                    _buildTableRow(
                      label: _selectedDuration == 'monthly' ? 'Monthly Price' : 'Yearly Price',
                      planCount: planCount,
                      children: widget.plans.map((plan) {
                        final pricing = plan['pricing'] as Map<String, dynamic>? ?? {};
                        final monthlyPrice = pricing['monthly'] as num? ?? 19.99;
                        final yearlyPrice = pricing['yearly'] as num? ?? 199.0;
                        final displayPrice = _selectedDuration == 'monthly' ? monthlyPrice : yearlyPrice;
                        return _buildPlanCell(
                          '\$${displayPrice.toStringAsFixed(_selectedDuration == 'monthly' ? 2 : 0)}',
                          '', // no subtitle â€” only selected duration price
                        );
                      }).toList(),
                    ),

                    // SERVICE Section Header â€” title column flex: 2, padding 16
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray50,
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
                        children: [
                          SizedBox(
                            width: _featureTitleColumnWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'SERVICE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _headerColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          Expanded(flex: planCount, child: const SizedBox()),
                        ],
                      ),
                    ),

                    // Deductible Row
                    _buildTableRow(
                      label: 'Deductible',
                      planCount: planCount,
                      children: widget.plans.map((plan) {
                        return _buildPlanCell(_getPlanDeductible(plan, _selectedDuration), '');
                      }).toList(),
                    ),

                    // Service Fee Row
                    _buildTableRow(
                      label: 'Service Fee',
                      planCount: planCount,
                      children: widget.plans.map((plan) {
                        return _buildPlanCell(_getPlanServiceFee(plan, _selectedDuration), '');
                      }).toList(),
                    ),

                    // Response Time Row
                    _buildTableRow(
                      label: 'Response Time',
                      planCount: planCount,
                      children: widget.plans.map((plan) {
                        return _buildPlanCell(_getPlanResponseTime(plan, _selectedDuration), '');
                      }).toList(),
                    ),

                    // COVERAGE Section Header â€” title column flex: 2, padding 16
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 0),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundGray50,
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
                        children: [
                          SizedBox(
                            width: _featureTitleColumnWidth,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: Text(
                                'COVERAGE',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: _headerColor,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                          Expanded(flex: planCount, child: const SizedBox()),
                        ],
                      ),
                    ),

                    // Coverage Features Rows
                    ..._coverageFeatures.map((feature) {
                      return _buildTableRow(
                        label: feature,
                        planCount: planCount,
                        children: widget.plans.map((plan) {
                          final hasFeature = _planHasFeature(plan, feature, _selectedDuration);
                          return _buildFeatureCell(hasFeature);
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Fixed Bar with SELECT Buttons â€” match table horizontal padding
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    child: Text(
                      'CHOOSE PLAN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: _textSecondary,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  ...widget.plans.asMap().entries.map((entry) {
                    final index = entry.key;
                    final plan = entry.value;
                    final badge = plan['badge'] as String?;
                    final isPopular = badge?.toLowerCase().contains('popular') ?? false;
                    final isHighlighted = isPopular || (planCount == 2 && index == 1);
                    
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(left: index > 0 ? 12 : 0),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.shadow,
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => widget.onSelectPlan(plan['id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isHighlighted ? _headerColor : AppColors.gray200,
                              foregroundColor: isHighlighted ? AppColors.white : _textPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                            ),
                            child: const Text(
                              'SELECT',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Feature title wrapping: min 1 line, max 2 lines. 1 wordâ†’1 line; 2 wordsâ†’2 lines; 3+â†’first 2 on line 1, rest on line 2. No mid-word break.
  Widget _buildTableRow({
    required String label,
    required int planCount,
    required List<Widget> children,
  }) {
    final words = label.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final labelStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: _headerColor,
      height: 1.3,
      letterSpacing: 0.2,
    );

    Widget titleContent;
    if (words.isEmpty) {
      titleContent = const SizedBox.shrink();
    } else if (words.length == 1) {
      titleContent = Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.visible);
    } else if (words.length == 2) {
      titleContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(words[0], style: labelStyle), Text(words[1], style: labelStyle)],
      );
    } else {
      final line1 = '${words[0]} ${words[1]}';
      final line2 = words.sublist(2).join(' ');
      titleContent = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(line1, style: labelStyle), Text(line2, style: labelStyle)],
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowLight,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _featureTitleColumnWidth,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
              child: Align(alignment: Alignment.centerLeft, child: titleContent),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlanCell(String value, String subtitle) {
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.only(left: 1),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (value.isNotEmpty)
              Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textPrimary,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.visible,
              ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: _textSecondary,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.visible,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCell(bool hasFeature) {
    return Expanded(
      flex: 2,
      child: Container(
        margin: const EdgeInsets.only(left: 2),
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Center(
          child: Icon(
            hasFeature ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 18,
            color: hasFeature ? AppColors.successMaterialDark : AppColors.errorMaterialDark,
          ),
        ),
      ),
    );
  }
}

