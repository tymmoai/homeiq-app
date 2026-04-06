import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../widgets/upgrade_buy_new_filter_screen.dart';
import '../widgets/upgrade_mock_products.dart';
import '../widgets/upgrade_product_card.dart';

class UpgradeBuyNewScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final int tradeInValue;

  const UpgradeBuyNewScreen({
    super.key,
    required this.asset,
    required this.tradeInValue,
  });

  @override
  State<UpgradeBuyNewScreen> createState() => _UpgradeBuyNewScreenState();
}

class _UpgradeBuyNewScreenState extends State<UpgradeBuyNewScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Color get _headerColor => AppColors.headerBackground;
  final TextEditingController _searchController = TextEditingController();
  late final List<Map<String, dynamic>> _products;
  late List<Map<String, dynamic>> _filteredProducts;
  String _sortBy = 'Top Rated';
  final Set<String> _selectedBrands = {};
  final Set<String> _selectedFeatures = {};
  final Set<String> _selectedPriceRanges = {};
  final Set<String> _selectedTypes = {};
  final Set<String> _selectedCapacities = {};
  final Set<String> _selectedRatings = {};
  final Set<String> _selectedColors = {};
  double _maxPrice = 3299;
  double _minPrice = 0;
  String _category = 'All';
  final String _selectedFilterCategory = 'Price';

  @override
  void initState() {
    super.initState();
    _category = (widget.asset['type'] as String?)?.trim() ?? 'All';
    final baseProducts = buildUpgradeMockProducts();
    final filteredByCategory = baseProducts.where((p) {
      if (_category == 'All') return true;
      final type = (p['type'] as String?)?.toLowerCase() ?? '';
      return type.contains(_category.toLowerCase());
    }).toList();

    // Fallback to all products if no match for category
    _products = filteredByCategory.isEmpty ? baseProducts : filteredByCategory;
    _maxPrice = _products.fold<double>(
      3299,
      (prev, p) => p['discountPrice'] > prev
          ? (p['discountPrice'] as num).toDouble()
          : prev,
    );
    _filteredProducts = List.from(_products);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_products);

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      result = result.where((p) {
        return (p['name'] as String).toLowerCase().contains(query) ||
            (p['brand'] as String).toLowerCase().contains(query);
      }).toList();
    }

    // Brand filter
    if (_selectedBrands.isNotEmpty) {
      result = result
          .where((p) => _selectedBrands.contains(p['brand'] as String))
          .toList();
    }

    // Price filter (from price ranges)
    if (_selectedPriceRanges.isNotEmpty) {
      result = result.where((p) {
        final price = (p['discountPrice'] as num).toDouble();
        for (final range in _selectedPriceRanges) {
          final lower = range.toLowerCase();
          if (lower.contains('under')) {
            // Format: "Under $500"
            final valueStr = lower.split('\$').last.trim();
            final max =
                double.tryParse(valueStr.replaceAll(',', '')) ??
                double.infinity;
            if (price < max) return true;
          } else if (lower.contains('above')) {
            // Format: "$2,000 and Above"
            final valueStr = lower.split('\$').last.split('and').first.trim();
            final min = double.tryParse(valueStr.replaceAll(',', '')) ?? 0;
            if (price >= min) return true;
          } else if (range.contains('to')) {
            // Format: "$500 to $1,000"
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
    } else {
      // Fallback to slider-based filter
      result = result.where((p) {
        final price = (p['discountPrice'] as num).toDouble();
        return price >= _minPrice && price <= _maxPrice;
      }).toList();
    }

    // Rating filter
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

    // Features filter
    if (_selectedFeatures.contains('Energy Star Rated')) {
      result = result.where((p) {
        final features = ((p['features'] as List?) ?? []).cast<String>();
        return features.any(
          (f) =>
              f.toLowerCase().contains('energy') ||
              f.toLowerCase().contains('star'),
        );
      }).toList();
    }

    if (_selectedFeatures.contains('Smart Features')) {
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

    if (_selectedFeatures.contains('Free Installation')) {
      // Assume all products have free installation for now
      // In real app, this would check a product property
    }

    // Sort
    if (_sortBy == 'Price: Low to High') {
      result.sort(
        (a, b) => (a['discountPrice'] as int) - (b['discountPrice'] as int),
      );
    } else if (_sortBy == 'Price: High to Low') {
      result.sort(
        (a, b) => (b['discountPrice'] as int) - (a['discountPrice'] as int),
      );
    } else {
      result.sort((a, b) => (b['rating'] as num).compareTo(a['rating'] as num));
    }

    setState(() {
      _filteredProducts = result;
    });
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
          onPressed: () => Navigator.of(context).pop(),
        ),
        leadingWidth: 40,
        title: Text(
          'Buy New Asset',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: AppColors.headerForeground,
          ),
        ),
        centerTitle: false,
        titleSpacing: 0,
        actions: const [],
      ),
      body: Column(
        children: [
          // Menu bar (Filter, Sort, Credit Score)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(16),
              vertical: responsive.spacing(4),
            ),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showFilterScreen();
                    },
                    icon: Icon(Icons.tune, size: responsive.iconSize(18)),
                    label: const Text('Filter'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showSortDialog();
                    },
                    icon: Icon(
                      Icons.arrow_drop_down,
                      size: responsive.iconSize(18),
                    ),
                    label: const Text('Sort'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary.withValues(
                        alpha: 0.08,
                      ),
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Product list (scrollable, includes product count)
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: responsive.iconSize(64),
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Text(
                          'Try adjusting your filters',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            color: AppColors.textSecondary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedBrands.clear();
                              _selectedFeatures.clear();
                              _minPrice = 0;
                              _maxPrice = _products.fold<double>(
                                3299,
                                (prev, p) => p['discountPrice'] > prev
                                    ? (p['discountPrice'] as num).toDouble()
                                    : prev,
                              );
                            });
                            _applyFilters();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                          child: const Text('Clear Filters'),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.all(responsive.spacing(16)),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () {
                            context.push(
                              '/product-detail',
                              extra: {
                                'product': product,
                                'tradeInValue': widget.tradeInValue,
                                'asset': widget.asset,
                              },
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: UpgradeProductCard(
                            product: product,
                            tradeInValue: widget.tradeInValue,
                            asset: widget.asset,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sort By',
              style: TextStyle(
                fontSize: responsive.fontSize(18),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: responsive.spacing(20)),
            _buildSortOption('Top Rated', 'Top Rated', Icons.star),
            _buildSortOption(
              'Price: Low to High',
              'Price: Low to High',
              Icons.arrow_upward,
            ),
            _buildSortOption(
              'Price: High to Low',
              'Price: High to Low',
              Icons.arrow_downward,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon) {
    final isSelected = _sortBy == value;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: responsive.fontSize(16),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        _applyFilters();
        Navigator.pop(context);
      },
    );
  }

  void _showFilterScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpgradeBuyNewFilterScreen(
          products: _products,
          selectedBrands: _selectedBrands,
          selectedFeatures: _selectedFeatures,
          selectedPriceRanges: _selectedPriceRanges,
          selectedTypes: _selectedTypes,
          selectedCapacities: _selectedCapacities,
          selectedRatings: _selectedRatings,
          selectedColors: _selectedColors,
          selectedFilterCategory: _selectedFilterCategory,
          onApply: (filters) {
            setState(() {
              _selectedBrands.clear();
              _selectedBrands.addAll(filters['brands'] as Set<String>);
              _selectedFeatures.clear();
              _selectedFeatures.addAll(filters['features'] as Set<String>);
              _selectedPriceRanges.clear();
              _selectedPriceRanges.addAll(
                filters['priceRanges'] as Set<String>,
              );
              _selectedTypes.clear();
              _selectedTypes.addAll(filters['types'] as Set<String>);
              _selectedCapacities.clear();
              _selectedCapacities.addAll(filters['capacities'] as Set<String>);
              _selectedRatings.clear();
              _selectedRatings.addAll(filters['ratings'] as Set<String>);
              _selectedColors.clear();
              _selectedColors.addAll(filters['colors'] as Set<String>);
            });
            _applyFilters();
          },
        ),
      ),
    );
  }
}
