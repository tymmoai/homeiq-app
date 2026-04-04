import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Painting service types, area/size options, surface conditions and add-ons.
/// Matches the web app's Painting service flow exactly.
///
/// 5 service types with size multipliers, surface conditions, and 6 add-ons.
class PaintingServiceData {
  PaintingServiceData._();

  static const String serviceName = 'Painting Services';
  static const String bookingIdPrefix = 'PT';
  static const double basePrice = 100.0;

  /// Estimate visit fee.
  static const double estimateVisitFee = 49.0;

  // ── Service Types (Step 1 — 5 options) ────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. Interior Room – base $150
    const ServiceCategory(
      name: 'Interior Room',
      icon: Icons.format_paint_outlined,
      description: 'Single room painting',
      items: [
        ServiceItem(name: 'Small Room (≤100 sqft)', price: 150, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Medium Room (100-200 sqft)', price: 225, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Large Room (200-350 sqft)', price: 300, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Extra Large Room (350+ sqft)', price: 375, icon: Icons.crop_square_outlined),
      ],
      addons: addons,
    ),

    // 2. Full Interior – base $600
    const ServiceCategory(
      name: 'Full Interior',
      icon: Icons.home_outlined,
      description: 'Complete home interior',
      items: [
        ServiceItem(name: '1 Bedroom Home', price: 600, icon: Icons.apartment_outlined),
        ServiceItem(name: '2 Bedroom Home', price: 900, icon: Icons.apartment_outlined),
        ServiceItem(name: '3 Bedroom Home', price: 1200, icon: Icons.house_outlined),
        ServiceItem(name: '4+ Bedroom Home', price: 1680, icon: Icons.house_outlined),
      ],
      addons: addons,
    ),

    // 3. Exterior – base $800
    const ServiceCategory(
      name: 'Exterior',
      icon: Icons.house_outlined,
      description: 'Outside walls & trim',
      items: [
        ServiceItem(name: '1 Story Home', price: 800, icon: Icons.house_outlined),
        ServiceItem(name: '2 Story Home', price: 1200, icon: Icons.house_outlined),
        ServiceItem(name: '3+ Story Home', price: 1600, icon: Icons.house_outlined),
      ],
      addons: addons,
    ),

    // 4. Cabinets – base $400
    const ServiceCategory(
      name: 'Cabinets',
      icon: Icons.kitchen_outlined,
      description: 'Kitchen & bath cabinets',
      items: [
        ServiceItem(name: 'Small Kitchen (≤10 cabinets)', price: 400, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Medium Kitchen (10-20 cabinets)', price: 640, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Large Kitchen (20-30 cabinets)', price: 880, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Full Kitchen (30+ cabinets)', price: 1200, icon: Icons.kitchen_outlined),
      ],
      addons: addons,
    ),

    // 5. Touch-ups – base $75
    const ServiceCategory(
      name: 'Touch-ups',
      icon: Icons.brush_outlined,
      description: 'Minor repairs & fixes',
      items: [
        ServiceItem(name: 'Minor (1-2 areas)', price: 75, icon: Icons.brush_outlined),
        ServiceItem(name: 'Moderate (3-5 areas)', price: 113, icon: Icons.brush_outlined),
        ServiceItem(name: 'Extensive (6+ areas)', price: 150, icon: Icons.brush_outlined),
      ],
      addons: addons,
    ),
  ];

  // ── Surface Condition (Step 3 — multiplier) ───────────────────────────
  static const Map<String, double> surfaceConditionMultipliers = {
    'Good Condition': 1.0,
    'Minor Damage': 1.2,
    'Heavy Prep Needed': 1.5,
  };

  static const Map<String, String> surfaceConditionDescriptions = {
    'Good Condition': 'Clean, smooth, ready to paint',
    'Minor Damage': 'Small cracks, nail holes',
    'Heavy Prep Needed': 'Peeling paint, major repairs',
  };

  // ── Add-ons (Step 4 — 6 options from web) ─────────────────────────────
  static const List<ServiceAddon> addons = [
    ServiceAddon(name: 'Minor Wall Repair', price: 35, icon: Icons.construction_outlined, description: 'Fix small holes and cracks'),
    ServiceAddon(name: 'Putty Application', price: 25, icon: Icons.auto_fix_high_outlined, description: 'Fill and smooth imperfections'),
    ServiceAddon(name: 'Primer Coat', price: 45, icon: Icons.format_paint_outlined, description: 'Premium primer for better coverage'),
    ServiceAddon(name: 'Furniture Covering', price: 20, icon: Icons.layers_outlined, description: 'Protect furniture and floors'),
    ServiceAddon(name: 'Old Paint Removal', price: 75, icon: Icons.layers_clear_outlined, description: 'Strip old paint before new coat'),
    ServiceAddon(name: 'Ceiling Painting', price: 60, icon: Icons.crop_square_outlined, description: 'Include ceiling in the job'),
  ];

  static Map<String, List<Map<String, dynamic>>> get serviceItemsMap {
    return {
      for (final cat in categories)
        cat.name: cat.items
            .map((item) => {
                  'name': item.name,
                  'price': item.price.toInt(),
                  'icon': item.icon,
                })
            .toList(),
    };
  }
}
