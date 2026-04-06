import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Outdoor service types, area/size options, conditions and service-specific add-ons.
/// Matches the web app's Outdoor service flow exactly.
///
/// 7 service types with area/condition modifiers + 18 service-specific add-ons.
class OutdoorServiceData {
  OutdoorServiceData._();

  static const String serviceName = 'Outdoor Services';
  static const String bookingIdPrefix = 'OH';
  static const double basePrice = 50.0;

  // ── Service Types (Step 1 — 7 options) ────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. Lawn & Yard Care – base $35
    const ServiceCategory(
      name: 'Lawn & Yard Care',
      icon: Icons.grass_outlined,
      description: 'Mowing, trimming, edging',
      items: [
        ServiceItem(
          name: 'Small Yard (<2,500 sqft)',
          price: 35,
          icon: Icons.grass_outlined,
        ),
        ServiceItem(
          name: 'Medium Yard (2,500-5,000 sqft)',
          price: 50,
          icon: Icons.grass_outlined,
        ),
        ServiceItem(
          name: 'Large Yard (5,000-10,000 sqft)',
          price: 65,
          icon: Icons.grass_outlined,
        ),
        ServiceItem(
          name: 'Acreage (1+ acre)',
          price: 85,
          icon: Icons.grass_outlined,
        ),
      ],
      addons: _lawnAddons,
    ),

    // 2. Garden & Planting – base $45
    const ServiceCategory(
      name: 'Garden & Planting',
      icon: Icons.yard_outlined,
      description: 'Planting, mulching, weeding',
      items: [
        ServiceItem(
          name: 'Small Garden (1-3 beds)',
          price: 45,
          icon: Icons.yard_outlined,
        ),
        ServiceItem(
          name: 'Medium Garden (4-6 beds)',
          price: 65,
          icon: Icons.yard_outlined,
        ),
        ServiceItem(
          name: 'Large Garden (7+ beds)',
          price: 85,
          icon: Icons.yard_outlined,
        ),
        ServiceItem(
          name: 'Full Yard Landscaping',
          price: 105,
          icon: Icons.yard_outlined,
        ),
      ],
      addons: _gardenAddons,
    ),

    // 3. Pressure Washing – base $75
    const ServiceCategory(
      name: 'Pressure Washing',
      icon: Icons.water_outlined,
      description: 'High-pressure cleaning',
      items: [
        ServiceItem(
          name: 'Driveway Only',
          price: 75,
          icon: Icons.garage_outlined,
        ),
        ServiceItem(name: 'Patio/Deck', price: 100, icon: Icons.deck_outlined),
        ServiceItem(
          name: 'Sidewalks & Paths',
          price: 105,
          icon: Icons.directions_walk_outlined,
        ),
        ServiceItem(
          name: 'Whole Exterior',
          price: 175,
          icon: Icons.home_outlined,
        ),
      ],
      addons: _pressureWashAddons,
    ),

    // 4. Gutter Cleaning – base $85
    const ServiceCategory(
      name: 'Gutter Cleaning',
      icon: Icons.roofing_outlined,
      description: 'Debris removal, downspouts',
      items: [
        ServiceItem(
          name: 'Single Story',
          price: 85,
          icon: Icons.roofing_outlined,
        ),
        ServiceItem(
          name: 'Two Story',
          price: 125,
          icon: Icons.roofing_outlined,
        ),
        ServiceItem(
          name: 'Multi-Level',
          price: 155,
          icon: Icons.roofing_outlined,
        ),
      ],
      addons: _gutterAddons,
    ),

    // 5. Deck & Patio Work – base $60
    const ServiceCategory(
      name: 'Deck & Patio Work',
      icon: Icons.deck_outlined,
      description: 'Staining, sealing, repairs',
      items: [
        ServiceItem(
          name: 'Small (<200 sqft)',
          price: 60,
          icon: Icons.deck_outlined,
        ),
        ServiceItem(
          name: 'Medium (200-400 sqft)',
          price: 90,
          icon: Icons.deck_outlined,
        ),
        ServiceItem(
          name: 'Large (400+ sqft)',
          price: 120,
          icon: Icons.deck_outlined,
        ),
      ],
      addons: _deckAddons,
    ),

    // 6. Outdoor Installations – base $80
    const ServiceCategory(
      name: 'Outdoor Installations',
      icon: Icons.fence_outlined,
      description: 'Fences, sheds, playsets',
      items: [
        ServiceItem(name: '1 Item', price: 80, icon: Icons.fence_outlined),
        ServiceItem(name: '2-3 Items', price: 140, icon: Icons.fence_outlined),
        ServiceItem(name: '4+ Items', price: 200, icon: Icons.fence_outlined),
      ],
    ),

    // 7. Seasonal Services – base $50
    const ServiceCategory(
      name: 'Seasonal Services',
      icon: Icons.wb_sunny_outlined,
      description: 'Snow removal, holiday lights',
      items: [
        ServiceItem(
          name: 'Driveway Only',
          price: 50,
          icon: Icons.ac_unit_outlined,
        ),
        ServiceItem(
          name: 'Walkways & Steps',
          price: 70,
          icon: Icons.directions_walk_outlined,
        ),
        ServiceItem(
          name: 'Full Property',
          price: 90,
          icon: Icons.home_outlined,
        ),
      ],
      addons: _seasonalAddons,
    ),
  ];

  // ── Condition Options (Step 3 — multiplier) ───────────────────────────
  static const Map<String, double> conditionMultipliers = {
    'Regular Maintenance': 1.0,
    'Moderate Buildup (1-2 months)': 1.3,
    'Heavy / Overgrown (3+ months)': 1.6,
  };

  static const Map<String, String> conditionDescriptions = {
    'Regular Maintenance': 'Well-maintained, routine service',
    'Moderate Buildup (1-2 months)': '1-2 months since last service',
    'Heavy / Overgrown (3+ months)': '3+ months, significant work needed',
  };

  // ── Service-Specific Add-ons (Step 4) ─────────────────────────────────
  static const List<ServiceAddon> _lawnAddons = [
    ServiceAddon(
      name: 'Leaf Cleanup',
      price: 25,
      icon: Icons.nature_outlined,
      description: 'Rake and bag all leaves',
    ),
    ServiceAddon(
      name: 'Hedge Trimming',
      price: 35,
      icon: Icons.park_outlined,
      description: 'Shape and trim hedges',
    ),
    ServiceAddon(
      name: 'Fertilizer Application',
      price: 40,
      icon: Icons.eco_outlined,
      description: 'Premium lawn fertilizer',
    ),
    ServiceAddon(
      name: 'Weed Control',
      price: 35,
      icon: Icons.spa_outlined,
      description: 'Herbicide application',
    ),
  ];

  static const List<ServiceAddon> _gardenAddons = [
    ServiceAddon(
      name: 'Mulch Delivery',
      price: 50,
      icon: Icons.inventory_2_outlined,
      description: 'Mulch delivered and spread',
    ),
    ServiceAddon(
      name: 'Weed Barrier',
      price: 30,
      icon: Icons.layers_outlined,
      description: 'Landscape fabric installation',
    ),
    ServiceAddon(
      name: 'Soil Amendment',
      price: 35,
      icon: Icons.grass_outlined,
      description: 'Enrich soil with compost',
    ),
    ServiceAddon(
      name: 'Weed Control',
      price: 35,
      icon: Icons.spa_outlined,
      description: 'Herbicide application',
    ),
  ];

  static const List<ServiceAddon> _pressureWashAddons = [
    ServiceAddon(
      name: 'Fence Cleaning',
      price: 40,
      icon: Icons.fence_outlined,
      description: 'Pressure wash fence',
    ),
    ServiceAddon(
      name: 'Driveway Sealing',
      price: 80,
      icon: Icons.garage_outlined,
      description: 'Seal driveway after cleaning',
    ),
    ServiceAddon(
      name: 'Window Wash',
      price: 50,
      icon: Icons.window_outlined,
      description: 'Clean exterior windows',
    ),
  ];

  static const List<ServiceAddon> _gutterAddons = [
    ServiceAddon(
      name: 'Gutter Guards',
      price: 100,
      icon: Icons.shield_outlined,
      description: 'Install gutter guard screens',
    ),
    ServiceAddon(
      name: 'Downspout Extension',
      price: 25,
      icon: Icons.south_outlined,
      description: 'Extend downspout drainage',
    ),
    ServiceAddon(
      name: 'Minor Gutter Repair',
      price: 45,
      icon: Icons.build_outlined,
      description: 'Fix leaks and loose joints',
    ),
  ];

  static const List<ServiceAddon> _deckAddons = [
    ServiceAddon(
      name: 'Furniture Moving',
      price: 30,
      icon: Icons.weekend_outlined,
      description: 'Move deck furniture',
    ),
    ServiceAddon(
      name: 'Stain Application',
      price: 75,
      icon: Icons.format_paint_outlined,
      description: 'Apply deck stain/sealant',
    ),
    ServiceAddon(
      name: 'Minor Repairs',
      price: 50,
      icon: Icons.build_outlined,
      description: 'Fix loose boards/rails',
    ),
  ];

  static const List<ServiceAddon> _seasonalAddons = [
    ServiceAddon(
      name: 'Salt/De-icer',
      price: 20,
      icon: Icons.grain_outlined,
      description: 'Apply salt or de-icer',
    ),
    ServiceAddon(
      name: 'Roof Line Lights',
      price: 75,
      icon: Icons.lightbulb_outlined,
      description: 'Holiday lights along roofline',
    ),
    ServiceAddon(
      name: 'Tree Wrapping',
      price: 50,
      icon: Icons.forest_outlined,
      description: 'Wrap trees with lights',
    ),
  ];

  // ── Recurring Options ─────────────────────────────────────────────────
  static const Map<String, double> recurringDiscounts = {
    'Weekly': 0.15,
    'Bi-weekly': 0.12,
    'Monthly': 0.10,
  };

  static Map<String, List<Map<String, dynamic>>> get serviceItemsMap {
    return {
      for (final cat in categories)
        cat.name: cat.items
            .map(
              (item) => {
                'name': item.name,
                'price': item.price.toInt(),
                'icon': item.icon,
              },
            )
            .toList(),
    };
  }
}
