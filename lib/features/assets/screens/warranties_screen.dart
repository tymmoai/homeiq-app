// Protection Plans Screen - Full implementation matching SquareTrade_WEB

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../theme/app_header_config.dart';
import '../../../utils/responsive_utils.dart';
import '../widgets/warranty_compare_drawer.dart';

class WarrantiesScreen extends StatefulWidget {
  final Map<String, dynamic> asset;

  const WarrantiesScreen({super.key, required this.asset});

  @override
  State<WarrantiesScreen> createState() => _WarrantiesScreenState();
}

class _WarrantiesScreenState extends State<WarrantiesScreen> {
  String _sortBy = 'price-low';
  bool _compareMode = false;
  bool _showOtherPlans = false;
  final List<String> _selectedForCompare = [];
  String _billingPeriod = 'monthly'; // 'monthly' or 'yearly'

  // App theme colors
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _borderColor = AppColors.divider;

  // Get plans for the asset category â€” Allstate Protection Plans (Essential, Premium, Ultimate)
  List<Map<String, dynamic>> _getSquareTradePlans() {
    _getAssetCategory();
    return [
      {
        'id': AppStrings.planEssentialSlug,
        'name': 'Essential Protection',
        'description':
            'Core protection with zero deductibles and no service fees',
        'provider': AppStrings.brandProvider,
        'pricing': {'monthly': 19.99, 'yearly': 199, 'oneTime': 199},
        'duration': {'years': 1},
        'deductible': 0,
        'serviceCallFee': 0,
        'responseTime': '24-48 hours',
        'features': [
          'No service call fees',
          'Parts and labor included',
          'Parts & labor',
          '24/7 phone support',
          'Free annual maintenance',
          'Unlimited service calls',
        ],
        'coverage': [
          'Mechanical failures',
          'Electrical issues',
          'Normal wear and tear',
          'Power surge protection',
          'Labor and parts included',
        ],
        'icon': Icons.shield,
        'rating': 4.8,
        'reviewCount': 2847,
        'trustBadges': ['BBB A+', 'Verified Provider', 'Fast Response'],
      },
      {
        'id': AppStrings.planPremiumSlug,
        'name': 'Premium Protection',
        'description':
            'Popular plan with accidental damage and priority service',
        'provider': AppStrings.brandProvider,
        'badge': 'Popular',
        'pricing': {'monthly': 29.99, 'yearly': 299, 'oneTime': 299},
        'duration': {'years': 1},
        'deductible': 0,
        'serviceCallFee': 0,
        'responseTime': '12-24 hours',
        'features': [
          'No service call fees',
          'No service fees',
          'Parts and labor included',
          'Parts & labor',
          'Accidental damage coverage',
          'Accidental damage',
          '24/7 live chat and phone support',
          '24/7 phone support',
          'Same-day service available',
          'Food spoilage coverage (\$300)',
          'Loaner equipment',
        ],
        'coverage': [
          'Mechanical and electrical failures',
          'Accidental damage (drops, spills)',
          'Power surge damage',
          'Parts & labor',
          'Unlimited service calls',
        ],
        'icon': Icons.star,
        'rating': 4.9,
        'reviewCount': 4521,
        'trustBadges': ['BBB A+', 'Top Rated', 'Same-Day Service'],
      },
      {
        'id': AppStrings.planUltimateSlug,
        'name': 'Ultimate Protection',
        'description':
            'Best value: full coverage, same-day service, replacement guarantee',
        'provider': AppStrings.brandProvider,
        'badge': 'Best Value',
        'pricing': {'monthly': 39.99, 'yearly': 399, 'oneTime': 399},
        'duration': {'years': 1},
        'deductible': 0,
        'serviceCallFee': 0,
        'responseTime': 'Same day',
        'features': [
          'No service call fees',
          'No service fees',
          'Parts and labor included',
          'Parts & labor',
          'Full accidental damage',
          'Accidental damage coverage',
          '24/7 concierge support',
          '24/7 phone support',
          'Same-day service',
          'Replacement guarantee',
          'Food spoilage (\$500)',
        ],
        'coverage': [
          'All failures and damages',
          'Full accidental damage',
          'Theft protection (\$1,000)',
          'Water damage',
          'Parts & labor',
          'Unlimited everything',
          'Immediate replacement if unrepairable',
        ],
        'icon': Icons.bolt,
        'rating': 5.0,
        'reviewCount': 3892,
        'trustBadges': ['BBB A+', 'Premium Choice', 'Instant Response'],
      },
    ];
  }

  // Other provider plans â€” American Home Shield, Choice Total, Asurion Home+
  List<Map<String, dynamic>> _getOtherPlans() {
    return [
      {
        'id': 'ahs-shieldsilver',
        'name': 'AHS ShieldSilver',
        'description':
            'Basic appliance plan with \$75 service trade call fee; no accidental',
        'provider': 'other',
        'providerName': 'American Home Shield',
        'pricing': {'monthly': 29.99, 'yearly': 299, 'oneTime': 299},
        'duration': {'years': 1},
        'deductible': 75,
        'serviceCallFee': 75,
        'responseTime': '3-5 days',
        'features': [
          'Parts replacement',
          'Parts and labor',
          'Phone support 24/7',
        ],
        'coverage': [
          'Mechanical failures only',
          'Electrical issues',
          'Parts and labor',
          'Service trade call fee per visit',
        ],
        'icon': Icons.shield,
        'rating': 3.8,
        'reviewCount': 14582,
      },
      {
        'id': 'choice-home-warranty',
        'name': 'Choice Total',
        'description': '\$85 deductible and \$85 service fee per visit',
        'provider': 'other',
        'providerName': 'Choice Home Warranty',
        'pricing': {'monthly': 34.99, 'yearly': 399, 'oneTime': 399},
        'duration': {'years': 1},
        'deductible': 85,
        'serviceCallFee': 85,
        'responseTime': '2-3 days',
        'features': ['Parts and labor', 'Phone support', 'Appliance coverage'],
        'coverage': [
          'Major appliances',
          'Mechanical and electrical failures',
          'Parts and labor',
          'Service call fee applies',
          'No accidental damage',
        ],
        'icon': Icons.home,
        'rating': 3.6,
        'reviewCount': 5621,
      },
      {
        'id': 'asurion-home-plus',
        'name': 'Asurion Home+',
        'description': 'Tech and appliance plan; \$99 deductible; 24/7 support',
        'provider': 'other',
        'providerName': 'Asurion',
        'pricing': {'monthly': 49.99, 'yearly': 549, 'oneTime': 549},
        'duration': {'years': 1},
        'deductible': 99,
        'serviceCallFee': 0,
        'responseTime': '1-2 days',
        'features': [
          'No service call fees',
          'No service fees',
          'Parts and labor included',
          'Parts & labor',
          '24/7 tech support',
          '24/7 phone support',
        ],
        'coverage': [
          'Electronics and appliances',
          'Mechanical failures',
          'Power surge damage',
          'Parts & labor',
        ],
        'icon': Icons.build,
        'rating': 4.1,
        'reviewCount': 12453,
      },
    ];
  }

  String _getAssetCategory() {
    // Category is used for filtering plans by asset type
    final type = (widget.asset['type'] as String? ?? '').toLowerCase();
    if (type.contains('refrigerator') ||
        type.contains('dishwasher') ||
        type.contains('oven') ||
        type.contains('microwave')) {
      return 'Kitchen Appliances';
    } else if (type.contains('air conditioner') ||
        type.contains('heater') ||
        type.contains('hvac')) {
      return 'HVAC';
    } else if (type.contains('washing machine') || type.contains('dryer')) {
      return 'Home Appliances';
    } else if (type.contains('tv') || type.contains('television')) {
      return 'Electronics';
    }
    return 'Home Appliances';
  }

  List<Map<String, dynamic>> _getSortedPlans(List<Map<String, dynamic>> plans) {
    final sorted = List<Map<String, dynamic>>.from(plans);
    sorted.sort((a, b) {
      switch (_sortBy) {
        case 'price-low':
          return (a['pricing'] as Map)['monthly'].compareTo(
            (b['pricing'] as Map)['monthly'],
          );
        case 'price-high':
          return (b['pricing'] as Map)['monthly'].compareTo(
            (a['pricing'] as Map)['monthly'],
          );
        case 'coverage':
          return (b['features'] as List).length.compareTo(
            (a['features'] as List).length,
          );
        default:
          return 0;
      }
    });
    return sorted;
  }

  void _showSortMenu(BuildContext context) {
    final RenderBox? box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = topLeft & box.size;
    final overlayRect = Offset.zero & overlay.size;
    final position = RelativeRect.fromRect(rect, overlayRect);
    showMenu<String>(
      context: context,
      position: position,
      color: Colors.white,
      elevation: 8,
      items: [
        PopupMenuItem(
          value: 'price-low',
          child: Text(
            'Price: Low to High',
            style: TextStyle(
              fontSize: 14,
              fontWeight: _sortBy == 'price-low'
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'price-high',
          child: Text(
            'Price: High to Low',
            style: TextStyle(
              fontSize: 14,
              fontWeight: _sortBy == 'price-high'
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'coverage',
          child: Text(
            'Best Coverage',
            style: TextStyle(
              fontSize: 14,
              fontWeight: _sortBy == 'coverage'
                  ? FontWeight.w600
                  : FontWeight.w500,
              color: _textPrimary,
            ),
          ),
        ),
      ],
    ).then((value) {
      if (value != null) setState(() => _sortBy = value);
    });
  }

  void _handleCompareToggle(String planId, bool checked) {
    setState(() {
      if (checked) {
        if (_selectedForCompare.length < 3) {
          _selectedForCompare.add(planId);
        }
      } else {
        _selectedForCompare.remove(planId);
      }
    });
  }

  void _handlePlanSelect(Map<String, dynamic> plan) {
    // Navigate to plan detail screen
    try {
      context.pushNamed(
        'protection-plan-detail',
        extra: {
          'plan': plan,
          'asset': widget.asset,
          'billingPeriod': _billingPeriod, // Pass selected billing period
        },
      );
    } on Object catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Navigation error. Please restart the app.'),
          backgroundColor: _headerColor,
        ),
      );
    }
  }

  void _showCompareModal(
    BuildContext context,
    List<Map<String, dynamic>> squaretradePlans,
    List<Map<String, dynamic>> otherPlans,
  ) {
    final comparePlans =
        squaretradePlans
            .where((p) => _selectedForCompare.contains(p['id']))
            .toList()
          ..addAll(
            otherPlans.where((p) => _selectedForCompare.contains(p['id'])),
          );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => WarrantyCompareDrawer(
          plans: comparePlans,
          scrollController: scrollController,
          assetName: widget.asset['name'] as String?,
          onRemovePlan: (planId) {
            setState(() {
              _selectedForCompare.remove(planId);
            });
            Navigator.of(context).pop();
            if (_selectedForCompare.length >= 2) {
              _showCompareModal(context, squaretradePlans, otherPlans);
            }
          },
          onSelectPlan: (planId) {
            final selectedPlan = [...squaretradePlans, ...otherPlans]
                .firstWhere(
                  (p) => p['id'] == planId,
                  orElse: () => <String, dynamic>{},
                );
            if (selectedPlan.isNotEmpty) {
              _handlePlanSelect(selectedPlan);
            }
            Navigator.of(context).pop();
          },
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final squaretradePlans = _getSortedPlans(_getSquareTradePlans());
    final otherPlans = _getSortedPlans(_getOtherPlans());

    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: AppHeaderConfig.buildStandardAppBar(
        context: context,
        title: 'Protection Plans',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Builder(
        builder: (context) {
          final responsive = ResponsiveUtils(context);
          return Column(
            children: [
              // Filter/Sort Bar - Reduced height with responsive design
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(12.0),
                  vertical: responsive.spacing(8.0),
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: _borderColor, width: 1),
                  ),
                ),
                child: Row(
                  children: [
                    // Price Sort - PopupMenu for reliable open position (no dropdown clip)
                    Expanded(
                      child: Builder(
                        builder: (btnContext) {
                          return Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(10.0),
                            ),
                            elevation: 1.5,
                            shadowColor: Colors.black.withValues(alpha: 0.08),
                            child: InkWell(
                              onTap: () => _showSortMenu(btnContext),
                              borderRadius: BorderRadius.circular(
                                responsive.borderRadius(10.0),
                              ),
                              child: Container(
                                height: responsive.buttonHeight(44.0),
                                padding: EdgeInsets.symmetric(
                                  horizontal: responsive.spacing(12.0),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sort,
                                      size: responsive.iconSize(18.0),
                                      color: _textPrimary,
                                    ),
                                    SizedBox(width: responsive.spacing(8.0)),
                                    Expanded(
                                      child: Text(
                                        _sortBy == 'price-low'
                                            ? 'Price: Low to High'
                                            : _sortBy == 'price-high'
                                            ? 'Price: High to Low'
                                            : 'Best Coverage',
                                        style: TextStyle(
                                          fontSize: responsive.fontSize(13.0),
                                          color: _textPrimary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: responsive.iconSize(20.0),
                                      color: _textPrimary,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: responsive.spacing(10.0)),
                    // Compare Button - styled as proper button
                    Material(
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(10.0),
                      ),
                      elevation: 1.5,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(10.0),
                          ),
                          gradient: _compareMode
                              ? LinearGradient(
                                  colors: [
                                    _headerColor,
                                    _headerColor.withValues(alpha: 0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                )
                              : null,
                          color: _compareMode ? null : Colors.white,
                          border: Border.all(
                            color: _compareMode ? _headerColor : _borderColor,
                            width: 1.5,
                          ),
                        ),
                        child: InkWell(
                          onTap: () {
                            if (_selectedForCompare.length >= 2) {
                              _showCompareModal(
                                context,
                                squaretradePlans,
                                otherPlans,
                              );
                            } else {
                              setState(() {
                                _compareMode = !_compareMode;
                                if (!_compareMode) {
                                  _selectedForCompare.clear();
                                }
                              });
                            }
                          },
                          borderRadius: BorderRadius.circular(
                            responsive.borderRadius(10.0),
                          ),
                          child: Container(
                            height: responsive.buttonHeight(44.0),
                            padding: EdgeInsets.symmetric(
                              horizontal: responsive.spacing(14.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.compare_arrows,
                                  size: responsive.iconSize(18.0),
                                  color: _compareMode
                                      ? Colors.white
                                      : _textPrimary,
                                ),
                                SizedBox(width: responsive.spacing(6.0)),
                                Text(
                                  'Compare',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(13.0),
                                    fontWeight: FontWeight.w600,
                                    color: _compareMode
                                        ? Colors.white
                                        : _textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Horizontal Scrollable Plan Cards
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly / Yearly Toggle - compact size with responsive design
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.fromLTRB(
                          responsive.spacing(16.0),
                          responsive.spacing(8.0),
                          responsive.spacing(16.0),
                          responsive.spacing(10.0),
                        ),
                        color: AppColors.backgroundGray50,
                        child: Container(
                          height: responsive.buttonHeight(42.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12.0),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(12.0),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildToggleButton(
                                    responsive,
                                    'Monthly',
                                    'monthly',
                                  ),
                                ),
                                Expanded(
                                  child: _buildToggleButton(
                                    responsive,
                                    'Yearly',
                                    'yearly',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // SquareTrade Plans Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: Text(
                          AppStrings.brandProtectionPlans,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: squaretradePlans.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: EdgeInsets.only(
                              bottom: index < squaretradePlans.length - 1
                                  ? 16
                                  : 0,
                            ),
                            child: _buildPlanCard(squaretradePlans[index]),
                          );
                        },
                      ),

                      // Compare with Other Providers Button
                      if (!_showOtherPlans) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _showOtherPlans = true;
                                });
                              },
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 16,
                              ),
                              label: const Text('Compare with Other Providers'),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _borderColor),
                                foregroundColor: _textPrimary,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                textStyle: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Other Provider Plans Section
                      if (_showOtherPlans) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          child: Text(
                            'Other Provider Plans',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPrimary,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: otherPlans.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: EdgeInsets.only(
                                bottom: index < otherPlans.length - 1 ? 16 : 0,
                              ),
                              child: _buildPlanCard(otherPlans[index]),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan) {
    final isSquareTrade = plan['provider'] == AppStrings.brandProvider;
    final isComparing = _selectedForCompare.contains(plan['id']);
    final pricing = plan['pricing'] as Map<String, dynamic>;
    final features = plan['features'] as List<dynamic>;
    final rating = plan['rating'] as double?;

    return InkWell(
      onTap: _compareMode
          ? () {
              if (_selectedForCompare.length < 3 || isComparing) {
                _handleCompareToggle(plan['id'], !isComparing);
              }
            }
          : null,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isComparing && _compareMode
              ? AppColors.primary10
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: isComparing && _compareMode
              ? Border.all(color: AppColors.primary, width: 2)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadowMedium,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Provider Logo - Top Right (Row 1)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isSquareTrade ? _headerColor : _textSecondary,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                ),
                child: Text(
                  isSquareTrade
                      ? AppStrings.brandProviderUpper
                      : (plan['providerName'] as String? ?? 'OTHER'),
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),

            // Rating - Top Right (Row 2) - Normal text format
            if (rating != null)
              Positioned(
                top: 30,
                right: 12,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      size: 14,
                      color: AppColors.warningAmber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

            // Content with proper padding structure
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content area (with right padding for rating)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 80, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Plan Name
                      Text(
                        plan['name'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),

                      // Description - Fixed to prevent overlap
                      Text(
                        plan['description'] as String,
                        style: TextStyle(
                          fontSize: 11,
                          color: _textSecondary,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Pricing
                      Text(
                        _billingPeriod == 'monthly'
                            ? '\$${(pricing['monthly'] as num).toStringAsFixed(2)}/mo'
                            : '\$${(pricing['yearly'] as num).toStringAsFixed(0)}/year',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _textPrimary,
                        ),
                      ),
                      if (_billingPeriod == 'yearly' &&
                          pricing['monthly'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            'Save \$${((pricing['monthly'] as num) * 12 - (pricing['yearly'] as num)).toStringAsFixed(0)}/year',
                            style: const TextStyle(
                              fontSize: 10,
                              color: AppColors.success,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const SizedBox(height: 10),

                      // Features (only 2 shown to fit smaller card)
                      ...features.take(2).map((feature) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  feature as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: _textPrimary,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),

                // View Details Button - Full width with card padding
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _compareMode
                          ? null
                          : () => _handlePlanSelect(plan),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Widget _buildToggleButton(
    ResponsiveUtils responsive,
    String label,
    String value,
  ) {
    final isSelected = _billingPeriod == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _billingPeriod = value;
          });
        },
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(12.0)),
          decoration: BoxDecoration(
            color: isSelected ? _headerColor : Colors.transparent,
            borderRadius: value == 'monthly'
                ? BorderRadius.only(
                    topLeft: Radius.circular(responsive.borderRadius(12.0)),
                    bottomLeft: Radius.circular(responsive.borderRadius(12.0)),
                  )
                : BorderRadius.only(
                    topRight: Radius.circular(responsive.borderRadius(12.0)),
                    bottomRight: Radius.circular(responsive.borderRadius(12.0)),
                  ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _headerColor.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(14.0),
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : _textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
