import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';

class UpgradeBuyNewFilterScreen extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final Set<String> selectedBrands;
  final Set<String> selectedFeatures;
  final Set<String> selectedPriceRanges;
  final Set<String> selectedTypes;
  final Set<String> selectedCapacities;
  final Set<String> selectedRatings;
  final Set<String> selectedColors;
  final String selectedFilterCategory;
  final Function(Map<String, dynamic>) onApply;

  const UpgradeBuyNewFilterScreen({
    super.key,
    required this.products,
    required this.selectedBrands,
    required this.selectedFeatures,
    required this.selectedPriceRanges,
    required this.selectedTypes,
    required this.selectedCapacities,
    required this.selectedRatings,
    required this.selectedColors,
    required this.selectedFilterCategory,
    required this.onApply,
  });

  @override
  State<UpgradeBuyNewFilterScreen> createState() =>
      _UpgradeBuyNewFilterScreenState();
}

class _UpgradeBuyNewFilterScreenState extends State<UpgradeBuyNewFilterScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Color get _headerColor => AppColors.headerBackground;
  late Set<String> _selectedBrands;
  late Set<String> _selectedFeatures;
  late Set<String> _selectedPriceRanges;
  late Set<String> _selectedTypes;
  late Set<String> _selectedCapacities;
  late Set<String> _selectedRatings;
  late Set<String> _selectedColors;
  late String _selectedFilterCategory;

  @override
  void initState() {
    super.initState();
    _selectedBrands = Set.from(widget.selectedBrands);
    _selectedFeatures = Set.from(widget.selectedFeatures);
    _selectedPriceRanges = Set.from(widget.selectedPriceRanges);
    _selectedTypes = Set.from(widget.selectedTypes);
    _selectedCapacities = Set.from(widget.selectedCapacities);
    _selectedRatings = Set.from(widget.selectedRatings);
    _selectedColors = Set.from(widget.selectedColors);
    _selectedFilterCategory = widget.selectedFilterCategory;
  }

  List<String> _getFilterCategories() {
    return ['Price', 'Brand', 'Capacity', 'Star Rating', 'Features', 'Color'];
  }

  List<String> _getPriceRanges() {
    // Build dynamic price ranges based on actual product prices
    if (widget.products.isEmpty) return [];

    final prices =
        widget.products
            .map((p) => (p['discountPrice'] as num).toDouble())
            .toList()
          ..sort();

    final minPrice = prices.first;
    final maxPrice = prices.last;

    if (minPrice == maxPrice) {
      final value = minPrice.round();
      return ['Under \$$value', '\$$value and Above'];
    }

    final step = ((maxPrice - minPrice) / 3).clamp(1, double.infinity);
    final r1Max = (minPrice + step).round();
    final r2Max = (minPrice + 2 * step).round();
    final r3Min = r2Max;

    return [
      'Under \$$r1Max',
      '\$$r1Max to \$$r2Max',
      '\$$r2Max to \$${maxPrice.round()}',
      '\$$r3Min and Above',
    ];
  }

  List<String> _getBrands() {
    return widget.products.map((p) => p['brand'] as String).toSet().toList()
      ..sort();
  }

  List<String> _getTypes() {
    return widget.products
        .map((p) => p['type'] as String? ?? 'Standard')
        .toSet()
        .toList()
      ..sort();
  }

  List<String> _getCapacities() {
    return ['Small', 'Medium', 'Large', 'Extra Large'];
  }

  List<String> _getRatings() {
    return ['4.5 & Above', '4.0 & Above', '3.5 & Above', '3.0 & Above'];
  }

  List<String> _getFeatures() {
    return [
      'Energy Star Rated',
      'Smart Features',
      'Free Installation',
      'Warranty Included',
    ];
  }

  List<String> _getColors() {
    return ['White', 'Black', 'Silver', 'Stainless Steel', 'Custom'];
  }

  int _getFilteredCount() {
    // Calculate filtered count based on current selections
    var result = List<Map<String, dynamic>>.from(widget.products);

    if (_selectedBrands.isNotEmpty) {
      result = result
          .where((p) => _selectedBrands.contains(p['brand'] as String))
          .toList();
    }

    if (_selectedPriceRanges.isNotEmpty) {
      result = result.where((p) {
        final price = (p['discountPrice'] as num).toDouble();
        for (final range in _selectedPriceRanges) {
          final lower = range.toLowerCase();
          if (lower.contains('under')) {
            // Format: "Under $X"
            final valueStr = lower.split('\$').last.trim();
            final max =
                double.tryParse(valueStr.replaceAll(',', '')) ??
                double.infinity;
            if (price < max) return true;
          } else if (lower.contains('above')) {
            // Format: "$X and Above"
            final valueStr = lower.split('\$').last.split('and').first.trim();
            final min = double.tryParse(valueStr.replaceAll(',', '')) ?? 0;
            if (price >= min) return true;
          } else if (range.contains('to')) {
            // Format: "$A to $B"
            final parts = range
                .replaceAll('\$', '')
                .replaceAll(',', '')
                .split(' to ');
            if (parts.length == 2) {
              final min = double.tryParse(parts[0].trim()) ?? 0;
              final max = double.tryParse(parts[1].trim()) ?? double.infinity;
              if (price >= min && price <= max) return true;
            }
          }
        }
        return false;
      }).toList();
    }

    if (_selectedTypes.isNotEmpty) {
      result = result
          .where(
            (p) => _selectedTypes.contains(p['type'] as String? ?? 'Standard'),
          )
          .toList();
    }

    if (_selectedRatings.isNotEmpty) {
      result = result.where((p) {
        final rating = (p['rating'] as num?)?.toDouble() ?? 0;
        for (final ratingFilter in _selectedRatings) {
          if (ratingFilter.contains('4.5') && rating >= 4.5) return true;
          if (ratingFilter.contains('4.0') && rating >= 4.0) return true;
          if (ratingFilter.contains('3.5') && rating >= 3.5) return true;
          if (ratingFilter.contains('3.0') && rating >= 3.0) return true;
        }
        return false;
      }).toList();
    }

    if (_selectedFeatures.isNotEmpty) {
      for (final feature in _selectedFeatures) {
        if (feature == 'Energy Star Rated') {
          result = result.where((p) {
            final features = ((p['features'] as List?) ?? []).cast<String>();
            return features.any(
              (f) =>
                  f.toLowerCase().contains('energy') ||
                  f.toLowerCase().contains('star'),
            );
          }).toList();
        } else if (feature == 'Smart Features') {
          result = result.where((p) {
            final features = ((p['features'] as List?) ?? []).cast<String>();
            return features.any(
              (f) =>
                  f.toLowerCase().contains('smart') ||
                  f.toLowerCase().contains('wifi') ||
                  f.toLowerCase().contains('app') ||
                  f.toLowerCase().contains('thinq') ||
                  f.toLowerCase().contains('connect'),
            );
          }).toList();
        }
      }
    }

    return result.length;
  }

  Widget _buildFilterOption(
    String option,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: responsive.spacing(12)),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.gray300,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                color: isSelected ? AppColors.primary : Colors.white,
              ),
              child: isSelected
                  ? Icon(Icons.check, size: responsive.iconSize(14), color: AppColors.textOnPrimary)
                  : null,
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: Text(
                option,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  color: AppColors.textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brands = _getBrands();
    final priceRanges = _getPriceRanges();
    final types = _getTypes();
    final capacities = _getCapacities();
    final ratings = _getRatings();
    final features = _getFeatures();
    final colors = _getColors();
    final categories = _getFilterCategories();

    List<String> currentOptions = [];
    Set<String> currentSelection = {};

    switch (_selectedFilterCategory) {
      case 'Price':
        currentOptions = priceRanges;
        currentSelection = _selectedPriceRanges;
        break;
      case 'Brand':
        currentOptions = brands;
        currentSelection = _selectedBrands;
        break;
      case 'Type':
        currentOptions = types;
        currentSelection = _selectedTypes;
        break;
      case 'Capacity':
        currentOptions = capacities;
        currentSelection = _selectedCapacities;
        break;
      case 'Star Rating':
        currentOptions = ratings;
        currentSelection = _selectedRatings;
        break;
      case 'Features':
        currentOptions = features;
        currentSelection = _selectedFeatures;
        break;
      case 'Color':
        currentOptions = colors;
        currentSelection = _selectedColors;
        break;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 2,
        centerTitle: false,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Filters',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: AppColors.headerForeground,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _selectedBrands.clear();
                _selectedFeatures.clear();
                _selectedPriceRanges.clear();
                _selectedTypes.clear();
                _selectedCapacities.clear();
                _selectedRatings.clear();
                _selectedColors.clear();
              });
            },
            child: Text(
              'Clear Filters',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w600,
                color: AppColors.headerForeground.withValues(alpha: 0.95),
              ),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          // Left Panel - Filter Categories
          Container(
            width: 140,
            color: AppColors.background,
            child: ListView.builder(
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedFilterCategory == category;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedFilterCategory = category;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Right Panel - Filter Options
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(responsive.spacing(20)),
              children: [
                ...currentOptions.map((option) {
                  final isSelected = currentSelection.contains(option);
                  return _buildFilterOption(option, isSelected, () {
                    setState(() {
                      switch (_selectedFilterCategory) {
                        case 'Price':
                          if (isSelected) {
                            _selectedPriceRanges.remove(option);
                          } else {
                            _selectedPriceRanges.add(option);
                          }
                          break;
                        case 'Brand':
                          if (isSelected) {
                            _selectedBrands.remove(option);
                          } else {
                            _selectedBrands.add(option);
                          }
                          break;
                        case 'Type':
                          if (isSelected) {
                            _selectedTypes.remove(option);
                          } else {
                            _selectedTypes.add(option);
                          }
                          break;
                        case 'Capacity':
                          if (isSelected) {
                            _selectedCapacities.remove(option);
                          } else {
                            _selectedCapacities.add(option);
                          }
                          break;
                        case 'Star Rating':
                          if (isSelected) {
                            _selectedRatings.remove(option);
                          } else {
                            _selectedRatings.add(option);
                          }
                          break;
                        case 'Features':
                          if (isSelected) {
                            _selectedFeatures.remove(option);
                          } else {
                            _selectedFeatures.add(option);
                          }
                          break;
                        case 'Color':
                          if (isSelected) {
                            _selectedColors.remove(option);
                          } else {
                            _selectedColors.add(option);
                          }
                          break;
                      }
                    });
                  });
                }),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(responsive.spacing(16)),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${_getFilteredCount()} products found',
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                color: AppColors.textSecondary,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                widget.onApply({
                  'brands': _selectedBrands,
                  'features': _selectedFeatures,
                  'priceRanges': _selectedPriceRanges,
                  'types': _selectedTypes,
                  'capacities': _selectedCapacities,
                  'ratings': _selectedRatings,
                  'colors': _selectedColors,
                });
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Apply',
                style: TextStyle(fontSize: responsive.fontSize(16), fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}