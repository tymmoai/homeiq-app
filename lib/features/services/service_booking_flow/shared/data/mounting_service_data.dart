import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Mounting service categories and items data.
/// Matches the web app's Mounting service flow exactly.
///
/// 6 sub-services, 36 items total.
class MountingServiceData {
  MountingServiceData._();

  static const String serviceName = 'Mounting Services';
  static const String bookingIdPrefix = 'MNT';
  static const double basePrice = 49.0;

  // ── Add-ons (from web) ────────────────────────────────────────────────
  static const List<ServiceAddon> addons = [
    ServiceAddon(name: 'Heavy-Duty Wall Anchoring', price: 25, icon: Icons.shield_outlined, description: 'Secure anchoring for heavy items'),
    ServiceAddon(name: 'Existing Item Removal', price: 35, icon: Icons.delete_sweep_outlined, description: 'Remove old mount/item from wall'),
    ServiceAddon(name: 'Cable Concealment', price: 75, icon: Icons.cable_outlined, description: 'Hide cables neatly (TV Mounting)'),
    ServiceAddon(name: 'Extra Hardware Kit', price: 20, icon: Icons.hardware_outlined, description: 'Additional screws, anchors, brackets'),
    ServiceAddon(name: 'Extra Helper', price: 45, icon: Icons.group_add_outlined, description: 'Additional person for heavy items'),
    ServiceAddon(name: 'Multi-Point Level Alignment', price: 30, icon: Icons.straighten_outlined, description: 'Precision leveling across multiple points'),
  ];

  // ── Categories ─────────────────────────────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. TV Wall Mounting – 6 items
    const ServiceCategory(
      name: 'TV Wall Mounting',
      icon: Icons.tv_outlined,
      description: 'Any size, any wall type',
      items: [
        ServiceItem(name: '32" TV', price: 75, icon: Icons.tv_outlined),
        ServiceItem(name: '43" TV', price: 89, icon: Icons.tv_outlined),
        ServiceItem(name: '55" TV', price: 109, icon: Icons.tv_outlined),
        ServiceItem(name: '65" TV', price: 129, icon: Icons.tv_outlined),
        ServiceItem(name: '75" TV', price: 159, icon: Icons.tv_outlined),
        ServiceItem(name: '85"+ TV', price: 199, icon: Icons.tv_outlined),
      ],
      addons: addons,
    ),

    // 2. Picture & Frame Mounting – 6 items
    const ServiceCategory(
      name: 'Picture & Frame Mounting',
      icon: Icons.photo_outlined,
      description: 'Photos, frames, art, gallery walls',
      items: [
        ServiceItem(name: 'Small Frame (up to 11x14")', price: 15, icon: Icons.photo_outlined),
        ServiceItem(name: 'Medium Frame (16x20 to 24x36")', price: 25, icon: Icons.photo_outlined),
        ServiceItem(name: 'Large Frame (over 24x36")', price: 40, icon: Icons.photo_outlined),
        ServiceItem(name: 'Canvas Art', price: 35, icon: Icons.palette_outlined),
        ServiceItem(name: 'Gallery Wall (3-5 pieces)', price: 75, icon: Icons.grid_view_outlined),
        ServiceItem(name: 'Gallery Wall (6-10 pieces)', price: 125, icon: Icons.grid_view_outlined),
      ],
      addons: addons,
    ),

    // 3. Mirror Mounting – 6 items
    const ServiceCategory(
      name: 'Mirror Mounting',
      icon: Icons.crop_square_outlined,
      description: 'Small to full length mirrors',
      items: [
        ServiceItem(name: 'Small Mirror (up to 24")', price: 45, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Medium Mirror (24-36")', price: 65, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Large Mirror (36-48")', price: 89, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Bathroom Mirror', price: 75, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Full Length Mirror', price: 99, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Heavy Decorative Mirror', price: 129, icon: Icons.crop_square_outlined),
      ],
      addons: addons,
    ),

    // 4. Shelf Mounting – 6 items
    const ServiceCategory(
      name: 'Shelf Mounting',
      icon: Icons.shelves,
      description: 'Floating, bracket, decorative shelves',
      items: [
        ServiceItem(name: 'Floating Shelf Small (up to 24")', price: 29, icon: Icons.shelves),
        ServiceItem(name: 'Floating Shelf Medium (24-36")', price: 39, icon: Icons.shelves),
        ServiceItem(name: 'Floating Shelf Large (36"+)', price: 49, icon: Icons.shelves),
        ServiceItem(name: 'Bracket Shelf', price: 35, icon: Icons.shelves),
        ServiceItem(name: 'Corner Shelf', price: 45, icon: Icons.shelves),
        ServiceItem(name: 'Heavy-Duty Shelf', price: 65, icon: Icons.shelves),
      ],
      addons: addons,
    ),

    // 5. Curtain & Blinds Installation – 6 items
    const ServiceCategory(
      name: 'Curtain & Blinds Installation',
      icon: Icons.window_outlined,
      description: 'Curtain rods, blinds, shades',
      items: [
        ServiceItem(name: 'Standard Curtain Rod', price: 35, icon: Icons.window_outlined),
        ServiceItem(name: 'Double Curtain Rod', price: 49, icon: Icons.window_outlined),
        ServiceItem(name: 'Extra Long Curtain Rod', price: 59, icon: Icons.window_outlined),
        ServiceItem(name: 'Standard Blinds', price: 39, icon: Icons.blinds_outlined),
        ServiceItem(name: 'Roller Shades', price: 45, icon: Icons.window_outlined),
        ServiceItem(name: 'Motorized Blinds', price: 79, icon: Icons.blinds_outlined),
      ],
      addons: addons,
    ),

    // 6. Kitchen Cabinet Mounting – 6 items
    const ServiceCategory(
      name: 'Kitchen Cabinet Mounting',
      icon: Icons.kitchen_outlined,
      description: 'Wall, base, tall cabinets',
      items: [
        ServiceItem(name: 'Wall Cabinet Small', price: 75, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Wall Cabinet Large', price: 99, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Base Cabinet Small', price: 89, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Base Cabinet Large', price: 119, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Tall/Pantry Cabinet', price: 149, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Corner Cabinet', price: 129, icon: Icons.kitchen_outlined),
      ],
      addons: addons,
    ),
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
