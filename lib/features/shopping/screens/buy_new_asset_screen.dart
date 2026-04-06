import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../utils/responsive_utils.dart';

class BuyNewAssetScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const BuyNewAssetScreen({super.key, required this.data});

  @override
  State<BuyNewAssetScreen> createState() => _BuyNewAssetScreenState();
}

class _BuyNewAssetScreenState extends State<BuyNewAssetScreen> {
  String _sortBy = 'rating';
  final List<String> _selectedBrands = [];
  final RangeValues _priceRange = const RangeValues(0, 100000);
  bool _energyStarFilter = false;
  bool _smartFeaturesFilter = false;
  bool _freeInstallationFilter = false;
  final Set<String> _addedToCart = {}; // Track added products

  late List<Map<String, dynamic>> _products;
  late List<Map<String, dynamic>> _filteredProducts;

  @override
  void initState() {
    super.initState();
    _products = _getMockProducts();
    _filteredProducts = List.from(_products);
    _applyFilters();
  }

  List<Map<String, dynamic>> _getMockProducts() {
    // Mock products based on category
    return [
      {
        'id': '1',
        'name': 'Samsung French Door Refrigerator',
        'brand': 'Samsung',
        'model': 'RF28T5001SR',
        'price': 1899,
        'originalPrice': 2299,
        'rating': 4.8,
        'reviews': 245,
        'energyStar': true,
        'smartFeatures': true,
        'freeInstallation': true,
        'features': [
          'French Door Design',
          'WiFi Connectivity',
          'Twin Cooling Plus',
          'Energy Star Certified',
        ],
        'warranty': '2 years comprehensive',
      },
      {
        'id': '2',
        'name': 'LG InstaView Refrigerator',
        'brand': 'LG',
        'model': 'LRFVS3006S',
        'price': 2499,
        'originalPrice': 2999,
        'rating': 4.7,
        'reviews': 189,
        'energyStar': true,
        'smartFeatures': true,
        'freeInstallation': true,
        'features': [
          'InstaView Door-in-Door',
          'SmartThinQ Technology',
          'Dual Ice Maker',
          'Energy Efficient',
        ],
        'warranty': '1 year + 10 years on compressor',
      },
      {
        'id': '3',
        'name': 'Whirlpool Side-by-Side Refrigerator',
        'brand': 'Whirlpool',
        'model': 'WRS325SDHZ',
        'price': 1399,
        'originalPrice': 1699,
        'rating': 4.5,
        'reviews': 312,
        'energyStar': true,
        'smartFeatures': false,
        'freeInstallation': true,
        'features': [
          'Side-by-Side Design',
          'Adaptive Defrost',
          'LED Lighting',
          'Fingerprint Resistant',
        ],
        'warranty': '1 year limited',
      },
      {
        'id': '4',
        'name': 'GE Profile Smart Refrigerator',
        'brand': 'GE',
        'model': 'PFE28PYNFS',
        'price': 2199,
        'originalPrice': 2599,
        'rating': 4.6,
        'reviews': 156,
        'energyStar': true,
        'smartFeatures': true,
        'freeInstallation': false,
        'features': [
          'Built-in WiFi',
          'Hands-Free Autofill',
          'TwinChill Evaporators',
          'Energy Star',
        ],
        'warranty': '2 years comprehensive',
      },
      {
        'id': '5',
        'name': 'Frigidaire Gallery Refrigerator',
        'brand': 'Frigidaire',
        'model': 'FRSS2623AS',
        'price': 1299,
        'originalPrice': 1599,
        'rating': 4.4,
        'reviews': 278,
        'energyStar': false,
        'smartFeatures': false,
        'freeInstallation': true,
        'features': [
          'Side-by-Side',
          'PurePour Water Filter',
          'Store-More Shelves',
          'LED Lighting',
        ],
        'warranty': '1 year',
      },
    ];
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_products);

    // Brand filter
    if (_selectedBrands.isNotEmpty) {
      filtered = filtered
          .where((p) => _selectedBrands.contains(p['brand']))
          .toList();
    }

    // Price range filter
    filtered = filtered
        .where(
          (p) =>
              p['price'] >= _priceRange.start && p['price'] <= _priceRange.end,
        )
        .toList();

    // Energy Star filter
    if (_energyStarFilter) {
      filtered = filtered.where((p) => p['energyStar'] == true).toList();
    }

    // Smart Features filter
    if (_smartFeaturesFilter) {
      filtered = filtered.where((p) => p['smartFeatures'] == true).toList();
    }

    // Free Installation filter
    if (_freeInstallationFilter) {
      filtered = filtered.where((p) => p['freeInstallation'] == true).toList();
    }

    // Sort
    if (_sortBy == 'price-low') {
      filtered.sort((a, b) => a['price'].compareTo(b['price']));
    } else if (_sortBy == 'price-high') {
      filtered.sort((a, b) => b['price'].compareTo(a['price']));
    } else if (_sortBy == 'rating') {
      filtered.sort((a, b) => b['rating'].compareTo(a['rating']));
    }

    setState(() {
      _filteredProducts = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final tradeInValue = widget.data['tradeInValue'] ?? 0;
    final availableBrands = _products
        .map((p) => p['brand'] as String)
        .toSet()
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
            size: responsive.iconSize(24.0),
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Buy New Asset',
          style: TextStyle(
            color: Colors.white,
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          // Trade-in Badge
          if (tradeInValue > 0)
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: EdgeInsets.all(responsive.spacing(16.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Trade-in Credit',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.spacing(16.0),
                      vertical: responsive.spacing(8.0),
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(20.0),
                      ),
                    ),
                    child: Text(
                      '\$$tradeInValue',
                      style: TextStyle(
                        fontSize: responsive.fontSize(18.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortBy,
                        isExpanded: true,
                        items: const [
                          DropdownMenuItem(
                            value: 'rating',
                            child: Text('Top Rated'),
                          ),
                          DropdownMenuItem(
                            value: 'price-low',
                            child: Text('Price: Low to High'),
                          ),
                          DropdownMenuItem(
                            value: 'price-high',
                            child: Text('Price: High to Low'),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value ?? 'rating';
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () => _showFilterSheet(context, availableBrands),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.tune,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Products List
          Expanded(
            child: _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.search_off,
                          size: 64,
                          color: AppColors.gray400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = _filteredProducts[index];
                      return _buildProductCard(context, product, tradeInValue);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(
    BuildContext context,
    Map<String, dynamic> product,
    int tradeInValue,
  ) {
    final finalPrice = (product['price'] as int) - tradeInValue;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Placeholder
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: const Center(
              child: Icon(Icons.kitchen, size: 80, color: AppColors.gray400),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Brand and Model
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                      ),
                      child: Text(
                        product['brand'],
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product['model'],
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Product Name
                Text(
                  product['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Rating
                Row(
                  children: [
                    const Icon(Icons.star, color: AppColors.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${product['rating']}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${product['reviews']} reviews)',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Features
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (product['features'] as List<String>)
                      .take(3)
                      .map(
                        (feature) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(
                              AppDimensions.radiusBadge,
                            ),
                          ),
                          child: Text(
                            feature,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),

                // Price Section
                if (tradeInValue > 0) ...[
                  Row(
                    children: [
                      Text(
                        '\$${product['originalPrice']}',
                        style: TextStyle(
                          fontSize: 14,
                          decoration: TextDecoration.lineThrough,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Text(
                          '-\$$tradeInValue',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '\$$finalPrice',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (tradeInValue > 0)
                            Text(
                              'After trade-in',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _addedToCart.contains(product['id'])
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              borderRadius: BorderRadius.circular(
                                AppDimensions.radiusBadge,
                              ),
                            ),
                            child: const Text(
                              'Added',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _addedToCart.add(product['id']);
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product['name']} added to cart!',
                                  ),
                                  duration: const Duration(seconds: 2),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, List<String> availableBrands) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedBrands.clear();
                            _energyStarFilter = false;
                            _smartFeaturesFilter = false;
                            _freeInstallationFilter = false;
                          });
                          setState(() {
                            _applyFilters();
                          });
                        },
                        child: const Text('Clear All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Brand Filter
                  Text(
                    'Brand',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableBrands.map((brand) {
                      final isSelected = _selectedBrands.contains(brand);
                      return FilterChip(
                        label: Text(brand),
                        selected: isSelected,
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              _selectedBrands.add(brand);
                            } else {
                              _selectedBrands.remove(brand);
                            }
                          });
                          setState(() {
                            _applyFilters();
                          });
                        },
                        selectedColor: AppColors.primary.withValues(alpha: 0.2),
                        checkmarkColor: AppColors.primary,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Feature Filters
                  Text(
                    'Features',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  CheckboxListTile(
                    title: const Text('Energy Star Certified'),
                    value: _energyStarFilter,
                    onChanged: (value) {
                      setModalState(() {
                        _energyStarFilter = value ?? false;
                      });
                      setState(() {
                        _applyFilters();
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Smart Features'),
                    value: _smartFeaturesFilter,
                    onChanged: (value) {
                      setModalState(() {
                        _smartFeaturesFilter = value ?? false;
                      });
                      setState(() {
                        _applyFilters();
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    title: const Text('Free Installation'),
                    value: _freeInstallationFilter,
                    onChanged: (value) {
                      setModalState(() {
                        _freeInstallationFilter = value ?? false;
                      });
                      setState(() {
                        _applyFilters();
                      });
                    },
                    activeColor: AppColors.primary,
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
