import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../utils/responsive_utils.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final int tradeInValue;
  final Map<String, dynamic>? asset;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.tradeInValue,
    this.asset,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // App theme colors
  Color get _headerColor => Theme.of(context).colorScheme.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getBadgeColor(String badgeText) {
    final badgeLower = badgeText.toLowerCase();
    if (badgeLower.contains('top rated')) {
      return AppColors.warning;
    } else if (badgeLower.contains('best seller')) {
      return AppColors.info;
    } else if (badgeLower.contains('recommended')) {
      return AppColors.primaryLight;
    } else if (badgeLower.contains('new arrival')) {
      return AppColors.success;
    }
    return _headerColor;
  }

  Widget _getProductImage(String productName, String type) {
    String? imagePath;
    final nameLower = productName.toLowerCase();
    final typeLower = type.toLowerCase();

    if (typeLower == 'refrigerator') {
      if (nameLower.contains('samsung') &&
          nameLower.contains('4-door') &&
          nameLower.contains('flex')) {
        imagePath = 'lib/asset_img/samsung 4-door flex refrigerator.jpg';
      } else if (nameLower.contains('lg') && nameLower.contains('instaview')) {
        imagePath = 'lib/asset_img/lg instaview door-in-door refrigerator.jpg';
      } else if (nameLower.contains('ge') &&
          nameLower.contains('french door')) {
        imagePath = 'lib/asset_img/GE French door refri refrigerator.jpg';
      } else if (nameLower.contains('whirlpool') &&
          nameLower.contains('french door')) {
        imagePath = 'lib/asset_img/Whirlpool French Door Refrigerator.jpg';
      } else if (nameLower.contains('frigidaire') &&
          nameLower.contains('gallery')) {
        imagePath =
            'lib/asset_img/Frrigidaire Gallery French Door Refrigerator.jpg';
      } else if (nameLower.contains('bosch') &&
          nameLower.contains('french door')) {
        imagePath = 'lib/asset_img/Refrigerator.jpg';
      }
    } else if (typeLower == 'air conditioner') {
      if (nameLower.contains('daikin') && nameLower.contains('12,000')) {
        imagePath = 'lib/asset_img/Daikin 12,000 BTU Mini Split AC.jpg';
      } else if (nameLower.contains('carrier')) {
        imagePath = 'lib/asset_img/carrier 12,000 BTU Window AC.jpg';
      } else {
        imagePath = 'lib/asset_img/AC.webp';
      }
    } else if (typeLower == 'dishwasher') {
      if (nameLower.contains('bosch') && nameLower.contains('300')) {
        imagePath = 'lib/asset_img/bosch 300 series dishwasher.jpg';
      } else if (nameLower.contains('ge') && nameLower.contains('profile')) {
        imagePath = 'lib/asset_img/GE profile Dshwasher with Microban.jpg';
      } else {
        imagePath = 'lib/asset_img/bosch_dishwasher.jpg';
      }
    } else if (typeLower == 'washing machine') {
      if (nameLower.contains('lg') && nameLower.contains('front load')) {
        imagePath = 'lib/asset_img/LG Front Load Washer (4.5 cu ft).jpg';
      } else if (nameLower.contains('samsung') &&
          nameLower.contains('top load')) {
        imagePath = 'lib/asset_img/Samsung top load washer(5.0 cu ft).jpg';
      } else {
        imagePath = 'lib/asset_img/Washing_Machine.jpg';
      }
    }

    if (imagePath != null) {
      return Image.asset(
        imagePath,
        width: double.infinity,
        height: double.infinity,
        // Use contain and center so the full, highâ€‘detail asset image is visible
        fit: BoxFit.contain,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: AppColors.white,
            child: Icon(
              Icons.devices_other,
              size: 80,
              color: _textSecondary,
            ),
          );
        },
      );
    }

    return Container(
      color: AppColors.white,
      child: Icon(Icons.devices_other, size: 80, color: _textSecondary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = context.responsive;
    final screenHeight = MediaQuery.of(context).size.height;

    final product = widget.product;
    final badges = ((product['badges'] as List?) ?? []).cast<String>();
    final features = ((product['features'] as List?) ?? []).cast<String>();
    final discountPrice = product['discountPrice'] as int;
    final originalPrice = product['price'] as int;
    final discount = product['discount'] as int;
    final monthlyPayment = product['monthlyPayment'] as int;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: AppColors.white,
            size: responsive.iconSize(24.0),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        leadingWidth: responsive.spacing(48.0),
        titleSpacing: 0,
        centerTitle: false,
        title: Text(
          (product['name'] as String?) ?? 'Product Details',
          style: TextStyle(
            color: AppColors.white,
            fontSize: responsive.fontSize(18.0),
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        actions: const [],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Section
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: screenHeight * 0.35,
                  color: AppColors.white,
                  child: _getProductImage(
                    product['name'] as String,
                    product['type'] as String? ?? '',
                  ),
                ),
                // Top-left badge
                if (badges.isNotEmpty)
                  Positioned(
                    top: responsive.spacing(12.0),
                    left: responsive.spacing(12.0),
                    child: Container(
                      padding: responsive.padding(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(badges[0]),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                      ),
                      child: Text(
                        badges[0],
                        style: TextStyle(
                          fontSize: responsive.fontSize(11.0),
                          fontWeight: FontWeight.w700,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                // Top-right badge (Save X%)
                Positioned(
                  top: responsive.spacing(12.0),
                  right: responsive.spacing(12.0),
                  child: Container(
                    padding: responsive.padding(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _headerColor.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                    ),
                    child: Text(
                      badges.length > 1 ? badges[1] : 'Save $discount%',
                      style: TextStyle(
                        fontSize: responsive.fontSize(11.0),
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Info Section
            Padding(
              padding: responsive.padding(all: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand
                  Text(
                    product['brand'] as String,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12.0),
                      fontWeight: FontWeight.w600,
                      color: _textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  responsive.heightBox(4.0),
                  // Product Name
                  Text(
                    product['name'] as String,
                    style: TextStyle(
                      fontSize: responsive.fontSize(20.0),
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  responsive.heightBox(8.0),
                  // Rating and Model
                  Row(
                    children: [
                      Icon(
                        Icons.star,
                        size: responsive.iconSize(18.0),
                        color: AppColors.amber,
                      ),
                      responsive.widthBox(4.0),
                      Text(
                        '${product['rating']}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(14.0),
                          fontWeight: FontWeight.w600,
                          color: _textPrimary,
                        ),
                      ),
                      responsive.widthBox(16.0),
                      Flexible(
                        child: Text(
                          'Model: ${product['name'] as String}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13.0),
                            color: _textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  responsive.heightBox(16.0),

                  // Pricing Card (highlighted, like Amazon/Croma)
                  Container(
                    width: double.infinity,
                    padding: responsive.padding(all: 12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(12.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: responsive.spacing(8.0),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '\$$originalPrice',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                color: _textSecondary,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            responsive.widthBox(8.0),
                            Text(
                              '-$discount% OFF',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14.0),
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        responsive.heightBox(4.0),
                        Text(
                          '\$$discountPrice',
                          style: TextStyle(
                            fontSize: responsive.fontSize(28.0),
                            fontWeight: FontWeight.w700,
                            color: _textPrimary,
                          ),
                        ),
                        if (widget.tradeInValue > 0) ...[
                          responsive.heightBox(4.0),
                          Text(
                            'After trade-in',
                            style: TextStyle(
                              fontSize: responsive.fontSize(14.0),
                              color: _textSecondary,
                            ),
                          ),
                          responsive.heightBox(8.0),
                          OutlinedButton.icon(
                            onPressed: () {},
                            icon: Icon(
                              Icons.lock,
                              size: responsive.iconSize(16.0),
                            ),
                            label: Text(
                              'Trade-in Credit: \$${widget.tradeInValue}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(13.0),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: _headerColor),
                              foregroundColor: _textPrimary,
                              padding: responsive.padding(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ],
                        responsive.heightBox(8.0),
                        Text(
                          'or \$$monthlyPayment/month with 0% APR for 12 months',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13.0),
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  responsive.heightBox(20.0),

                  // Key Features Card
                  Container(
                    width: double.infinity,
                    padding: responsive.padding(all: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(12.0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadowMedium,
                          blurRadius: responsive.spacing(8.0),
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.star_outline,
                              size: responsive.iconSize(18.0),
                              color: _headerColor,
                            ),
                            responsive.widthBox(8.0),
                            Text(
                              'Key Features',
                              style: TextStyle(
                                fontSize: responsive.fontSize(17.0),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        responsive.heightBox(12.0),
                        ...features.map(
                          (feature) => Padding(
                            padding: responsive.padding(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  size: responsive.iconSize(18.0),
                                  color: AppColors.success,
                                ),
                                responsive.widthBox(8.0),
                                Expanded(
                                  child: Text(
                                    feature,
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(14.0),
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  responsive.heightBox(20.0),

                  // Buy Now Button
                  SizedBox(
                    width: double.infinity,
                    height: responsive.buttonHeight(48.0),
                    child: ElevatedButton(
                      onPressed: () {
                        context.push(
                          '/checkout-address',
                          extra: {
                            'product': widget.product,
                            'tradeInValue': widget.tradeInValue,
                            'quantity': 1,
                            'asset': widget.asset,
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _headerColor,
                        foregroundColor: AppColors.white,
                        padding: responsive.padding(vertical: 12),
                        elevation: 0,
                      ),
                      child: Text(
                        'Buy Now',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16.0),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  responsive.heightBox(16.0),

                  // Information Cards (2x2 Grid)
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          responsive,
                          icon: Icons.local_shipping_outlined,
                          text: 'Free Delivery',
                        ),
                      ),
                      responsive.widthBox(8.0),
                      Expanded(
                        child: _buildInfoCard(
                          responsive,
                          icon: Icons.bolt_outlined,
                          text: '0% APR Financing',
                        ),
                      ),
                    ],
                  ),
                  responsive.heightBox(12.0),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          responsive,
                          icon: Icons.verified_outlined,
                          text: '10-Year Warranty',
                        ),
                      ),
                      responsive.widthBox(12.0),
                      Expanded(
                        child: _buildInfoCard(
                          responsive,
                          icon: Icons.assignment_return_outlined,
                          text: '7-Day Return Policy',
                        ),
                      ),
                    ],
                  ),
                  responsive.heightBox(20.0),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: _headerColor,
                    unselectedLabelColor: _textSecondary,
                    indicatorColor: _headerColor,
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    labelStyle: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w600,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: 'All Features'),
                      Tab(text: 'Specifications'),
                      Tab(text: 'Warranty & Delivery'),
                    ],
                  ),
                  const SizedBox(height: 0),

                  // Tab Content
                  SizedBox(
                    height: screenHeight * 0.4,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // All Features Tab
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...features
                                  .take(3)
                                  .map(
                                    (feature) => Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            size: 20,
                                            color: AppColors.success,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              feature,
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: _textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Smart home integration support',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      size: 20,
                                      color: AppColors.success,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Ultra-quiet operation below 40dB',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _textPrimary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Specifications Tab
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildSpecRow(
                                'Capacity',
                                '1.5 Ton (18,000 BTU/hr)',
                              ),
                              _buildSpecRow('Energy Rating', '5 Star (A++)'),
                              _buildSpecRow('Power Consumption', '1.2 kW'),
                              _buildSpecRow('Refrigerant', 'R32 Eco-friendly'),
                              _buildSpecRow('Coverage Area', 'Up to 180 sq ft'),
                              _buildSpecRow('Noise Level', '38dB (Indoor)'),
                            ],
                          ),
                        ),
                        // Warranty & Delivery Tab
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInfoSection(
                                'Warranty Coverage',
                                '10 years on compressor, 5 years on parts',
                              ),
                              _buildInfoSection(
                                'Delivery & Installation',
                                'Free delivery in 7-10 days with professional installation',
                              ),
                              _buildInfoSection(
                                'Returns Policy',
                                '7 days hassle-free returns with full refund',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    ResponsiveUtils responsive, {
    required IconData icon,
    required String text,
  }) {
    return Container(
      constraints: BoxConstraints(minHeight: responsive.spacing(75.0)),
      padding: responsive.padding(horizontal: 8, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(8.0)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowMedium,
            blurRadius: responsive.spacing(8.0),
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsive.iconSize(24.0), color: _headerColor),
          responsive.heightBox(6.0),
          Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: responsive.fontSize(11.0),
              fontWeight: FontWeight.w600,
              color: _textPrimary,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(fontSize: 14, color: _textSecondary),
          ),
        ],
      ),
    );
  }
}