import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../utils/responsive_utils.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final int tradeInValuePerItem;

  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _borderColor = AppColors.divider;
  static final Color _backgroundColor = AppColors.background;

  const CartScreen({
    super.key,
    required this.items,
    required this.tradeInValuePerItem,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  late List<Map<String, dynamic>> _items;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy of incoming items
    _items = widget.items.map((e) => {...e}).toList();
  }

  int get _totalQuantity =>
      _items.fold<int>(0, (sum, item) => sum + (item['quantity'] as int));

  double get _subtotal => _items.fold<double>(
    0,
    (sum, item) =>
        sum +
        ((item['product']['discountPrice'] as int) * (item['quantity'] as int)),
  );

  double get _tradeInTotal =>
      (widget.tradeInValuePerItem * _totalQuantity).toDouble();

  double get _tax => _subtotal * 0.08;

  double get _totalAmount => _subtotal - _tradeInTotal + _tax;

  void _updateQuantity(int index, int delta) {
    setState(() {
      int qty = _items[index]['quantity'] as int;
      qty += delta;
      if (qty <= 0) {
        _items.removeAt(index);
      } else {
        _items[index]['quantity'] = qty;
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    if (_items.isEmpty) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          Navigator.of(context).pop([]);
        },
        child: Scaffold(
          backgroundColor: AppColors.backgroundGray50,
          appBar: AppBar(
            backgroundColor: _headerColor,
            elevation: 0,
            centerTitle: false,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop([]),
            ),
            title: Text(
              'Shopping Cart',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.fontSize(18.0),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          body: Center(
            child: Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: responsive.fontSize(16.0),
                color: CartScreen._textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_items);
      },
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray50,
        appBar: AppBar(
          backgroundColor: _headerColor,
          elevation: 0,
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(_items),
          ),
          title: Text(
            'Shopping Cart',
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.fontSize(18.0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: Padding(
          padding: responsive.padding(all: 16),
          child: Column(
            children: [
              // Items list
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, _) => responsive.heightBox(12.0),
                  itemBuilder: (context, index) {
                    final product =
                        _items[index]['product'] as Map<String, dynamic>;
                    final quantity = _items[index]['quantity'] as int;
                    final price = product['discountPrice'] as int;
                    final lineTotal = price * quantity;
                    return Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(
                          responsive.borderRadius(12.0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: responsive.spacing(8.0),
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: responsive.padding(all: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail with asset image filling the left area
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              responsive.borderRadius(8.0),
                            ),
                            child: Container(
                              width: responsive.spacing(80.0),
                              height: responsive.spacing(80.0),
                              color: CartScreen._backgroundColor,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                child: _buildProductImage(product),
                              ),
                            ),
                          ),
                          responsive.widthBox(12.0),
                          // Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product['brand'] as String,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(11.0),
                                    fontWeight: FontWeight.w600,
                                    color: CartScreen._textSecondary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                responsive.heightBox(4.0),
                                Text(
                                  product['name'] as String,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14.0),
                                    fontWeight: FontWeight.w700,
                                    color: CartScreen._textPrimary,
                                  ),
                                ),
                                responsive.heightBox(8.0),
                                Row(
                                  children: [
                                    Text(
                                      'Quantity:',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        color: CartScreen._textSecondary,
                                      ),
                                    ),
                                    responsive.widthBox(6.0),
                                    Container(
                                      height: responsive.spacing(32.0),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                          responsive.borderRadius(20.0),
                                        ),
                                        border: Border.all(
                                          color: CartScreen._borderColor,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () =>
                                                _updateQuantity(index, -1),
                                            child: Container(
                                              width: responsive.spacing(32.0),
                                              height: responsive.spacing(32.0),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.remove,
                                                size: responsive.iconSize(16.0),
                                                color: CartScreen._textPrimary,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: responsive.padding(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '$quantity',
                                              style: TextStyle(
                                                fontSize: responsive.fontSize(
                                                  14,
                                                ),
                                                fontWeight: FontWeight.w600,
                                                color: CartScreen._textPrimary,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () =>
                                                _updateQuantity(index, 1),
                                            child: Container(
                                              width: responsive.spacing(32.0),
                                              height: responsive.spacing(32.0),
                                              alignment: Alignment.center,
                                              child: Icon(
                                                Icons.add,
                                                size: responsive.iconSize(16.0),
                                                color: CartScreen._textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                responsive.heightBox(8.0),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Price:',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12.0),
                                            color: CartScreen._textSecondary,
                                          ),
                                        ),
                                        Text(
                                          '\$$price x $quantity',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(13.0),
                                            fontWeight: FontWeight.w600,
                                            color: CartScreen._textPrimary,
                                          ),
                                        ),
                                        if (widget.tradeInValuePerItem > 0)
                                          Text(
                                            'Trade-in Discount: -\$${widget.tradeInValuePerItem * quantity}',
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(
                                                12.0,
                                              ),
                                              color: CartScreen._textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                    Text(
                                      '\$${lineTotal.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(16.0),
                                        fontWeight: FontWeight.w700,
                                        color: CartScreen._textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          responsive.widthBox(8.0),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: CartScreen._textSecondary,
                              size: responsive.iconSize(24.0),
                            ),
                            onPressed: () => _removeItem(index),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              responsive.heightBox(16.0),
              // Order summary
              Container(
                width: double.infinity,
                padding: responsive.padding(all: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(12.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: responsive.spacing(8.0),
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: responsive.fontSize(16.0),
                        fontWeight: FontWeight.w700,
                        color: CartScreen._textPrimary,
                      ),
                    ),
                    responsive.heightBox(12.0),
                    _buildSummaryRow(
                      'Subtotal ($_totalQuantity items)',
                      _subtotal,
                    ),
                    _buildSummaryRow('Trade-in Credit', -_tradeInTotal),
                    _buildSummaryRow('Sales Tax (8%)', _tax),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Total Amount',
                      _totalAmount,
                      isBold: true,
                    ),
                    responsive.heightBox(12.0),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_items.isEmpty) {
                            return;
                          }

                          try {
                            final result = await context.push<dynamic>(
                              '/checkout-address',
                              extra: {
                                'items': _items,
                                'tradeInValuePerItem':
                                    widget.tradeInValuePerItem,
                                'subtotal': _subtotal,
                                'tradeInTotal': _tradeInTotal,
                                'tax': _tax,
                                'totalAmount': _totalAmount,
                              },
                            );

                            if (!context.mounted) return;
                            // Payment done: address returned confirmation data â†’ show order summary
                            if (result is Map<String, dynamic>) {
                              final backFromConfirmation = await context
                                  .push<bool>(
                                    '/checkout-confirmation',
                                    extra: result,
                                  );
                              if (!context.mounted) return;
                              if (backFromConfirmation == true) {
                                setState(() => _items.clear());
                                Navigator.of(context).pop(true);
                              }
                              return;
                            }
                            if (result == true) {
                              setState(() => _items.clear());
                              Navigator.of(context).pop(true);
                            }
                          } on Object catch (_) {
                            if (!context.mounted) return;
                            // Show a nonâ€‘crashing error message instead of throwing
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Checkout screen is not available. Please restart the app and try again.',
                                ),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _headerColor,
                          foregroundColor: Colors.white,
                          padding: responsive.padding(vertical: 14),
                        ),
                        child: Text(
                          'Proceed to Checkout',
                          style: TextStyle(
                            fontSize: responsive.fontSize(15.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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

  Widget _buildSummaryRow(String label, double value, {bool isBold = false}) {
    final responsive = context.responsive;
    return Padding(
      padding: responsive.padding(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: CartScreen._textSecondary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
          Text(
            (value >= 0 ? '\$' : '-\$') + value.abs().toStringAsFixed(2),
            style: TextStyle(
              fontSize: responsive.fontSize(14.0),
              color: CartScreen._textPrimary,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Returns a representative image for the product, filling the thumbnail area.
  /// Falls back to a generic icon if no specific asset is available.
  Widget _buildProductImage(Map<String, dynamic> product) {
    final name = (product['name'] as String? ?? '').toLowerCase();
    final type = (product['type'] as String? ?? '').toLowerCase();

    String? assetPath;

    // Refrigerators
    if (type.contains('refrigerator')) {
      if (name.contains('samsung') &&
          name.contains('4-door') &&
          name.contains('flex')) {
        assetPath = 'lib/asset_img/samsung 4-door flex refrigerator.jpg';
      } else if (name.contains('lg') && name.contains('instaview')) {
        assetPath = 'lib/asset_img/lg instaview door-in-door refrigerator.jpg';
      } else if (name.contains('ge') && name.contains('french door')) {
        assetPath = 'lib/asset_img/GE French door refri refrigerator.jpg';
      } else if (name.contains('whirlpool') && name.contains('french door')) {
        assetPath = 'lib/asset_img/Whirlpool French Door Refrigerator.jpg';
      } else if (name.contains('frigidaire') && name.contains('gallery')) {
        assetPath =
            'lib/asset_img/Frrigidaire Gallery French Door Refrigerator.jpg';
      } else {
        assetPath = 'lib/asset_img/Refrigerator.jpg';
      }
    }
    // Washing machines
    else if (type.contains('washing machine')) {
      if (name.contains('lg') &&
          name.contains('front load') &&
          name.contains('4.5')) {
        assetPath = 'lib/asset_img/LG Front Load Washer (4.5 cu ft).jpg';
      } else if (name.contains('samsung') &&
          name.contains('top load') &&
          name.contains('5.0')) {
        assetPath = 'lib/asset_img/Samsung top load washer(5.0 cu ft).jpg';
      } else {
        assetPath = 'lib/asset_img/Washing_Machine.jpg';
      }
    }
    // Dishwashers
    else if (type.contains('dishwasher')) {
      if (name.contains('bosch') && name.contains('300')) {
        assetPath = 'lib/asset_img/bosch 300 series dishwasher.jpg';
      } else if (name.contains('ge') && name.contains('profile')) {
        assetPath = 'lib/asset_img/GE profile Dshwasher with Microban.jpg';
      } else {
        assetPath = 'lib/asset_img/bosch_dishwasher.jpg';
      }
    }
    // Air conditioners
    else if (type.contains('air conditioner')) {
      if (name.contains('daikin') && name.contains('12,000')) {
        assetPath = 'lib/asset_img/Daikin 12,000 BTU Mini Split AC.jpg';
      } else if (name.contains('carrier')) {
        assetPath = 'lib/asset_img/carrier 12,000 BTU Window AC.jpg';
      }
    }

    if (assetPath != null) {
      return Image.asset(assetPath, fit: BoxFit.contain);
    }

    // Fallback generic icon
    return Icon(Icons.kitchen, color: CartScreen._textSecondary, size: 48);
  }
}
