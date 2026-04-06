import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Assembly service categories and items data.
/// Matches the web app's Assembly service flow exactly.
///
/// 4 sub-services, 42 items total.
class AssemblyServiceData {
  AssemblyServiceData._();

  static const String serviceName = 'Furniture Assembly';
  static const String bookingIdPrefix = 'BK';
  static const double basePrice = 55.0;

  // ── Add-ons (from web) ────────────────────────────────────────────────
  static const List<ServiceAddon> addons = [
    ServiceAddon(
      name: 'Wall Anchoring / Safety Fixing',
      price: 150,
      icon: Icons.shield_outlined,
      description: 'Secure heavy furniture to wall',
    ),
    ServiceAddon(
      name: 'Disassembly of Old Furniture',
      price: 200,
      icon: Icons.construction_outlined,
      description: 'Disassemble old furniture',
    ),
    ServiceAddon(
      name: 'Multi-room Assembly',
      price: 250,
      icon: Icons.meeting_room_outlined,
      description: 'Assembly in multiple rooms',
    ),
    ServiceAddon(
      name: 'Disposal of Packaging',
      price: 100,
      icon: Icons.delete_sweep_outlined,
      description: 'Clean disposal of packaging',
    ),
    ServiceAddon(
      name: 'Extra Helper',
      price: 300,
      icon: Icons.group_add_outlined,
      description: 'Additional person for heavy items',
    ),
  ];

  // ── Categories ─────────────────────────────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. Furniture Assembly – 12 items
    const ServiceCategory(
      name: 'Furniture Assembly',
      icon: Icons.chair_outlined,
      description: 'Tables, chairs, sofas, storage units',
      items: [
        ServiceItem(
          name: 'Dining Chair',
          price: 15,
          icon: Icons.chair_outlined,
        ),
        ServiceItem(
          name: 'Dining Table',
          price: 35,
          icon: Icons.table_restaurant_outlined,
        ),
        ServiceItem(
          name: 'Coffee Table',
          price: 25,
          icon: Icons.table_bar_outlined,
        ),
        ServiceItem(
          name: 'Side Table',
          price: 20,
          icon: Icons.table_restaurant_outlined,
        ),
        ServiceItem(name: 'TV Stand', price: 35, icon: Icons.tv_outlined),
        ServiceItem(
          name: 'Sofa / Couch',
          price: 45,
          icon: Icons.weekend_outlined,
        ),
        ServiceItem(name: 'Bookshelf', price: 30, icon: Icons.shelves),
        ServiceItem(
          name: 'Wardrobe',
          price: 50,
          icon: Icons.door_sliding_outlined,
        ),
        ServiceItem(
          name: 'Dresser',
          price: 45,
          icon: Icons.inventory_2_outlined,
        ),
        ServiceItem(name: 'Bed Frame', price: 55, icon: Icons.bed_outlined),
        ServiceItem(
          name: 'Shoe Rack',
          price: 20,
          icon: Icons.inventory_outlined,
        ),
        ServiceItem(
          name: 'Storage Cabinet',
          price: 40,
          icon: Icons.inventory_outlined,
        ),
      ],
      addons: addons,
    ),

    // 2. Office / Work Setup – 10 items
    const ServiceCategory(
      name: 'Office / Work Setup',
      icon: Icons.desk_outlined,
      description: 'Desks, office chairs, workstations',
      items: [
        ServiceItem(
          name: 'Computer Desk',
          price: 35,
          icon: Icons.desk_outlined,
        ),
        ServiceItem(
          name: 'L-Shaped Desk',
          price: 55,
          icon: Icons.desktop_windows_outlined,
        ),
        ServiceItem(
          name: 'Standing Desk',
          price: 65,
          icon: Icons.desktop_mac_outlined,
        ),
        ServiceItem(
          name: 'Office Chair',
          price: 25,
          icon: Icons.chair_outlined,
        ),
        ServiceItem(
          name: 'Executive Chair',
          price: 35,
          icon: Icons.chair_outlined,
        ),
        ServiceItem(
          name: 'Gaming Chair',
          price: 30,
          icon: Icons.sports_esports_outlined,
        ),
        ServiceItem(
          name: 'Filing Cabinet',
          price: 40,
          icon: Icons.folder_outlined,
        ),
        ServiceItem(
          name: 'Desk with Hutch',
          price: 60,
          icon: Icons.desk_outlined,
        ),
        ServiceItem(
          name: 'Monitor Stand / Riser',
          price: 20,
          icon: Icons.monitor_outlined,
        ),
        ServiceItem(
          name: 'Printer Stand',
          price: 25,
          icon: Icons.print_outlined,
        ),
      ],
      addons: addons,
    ),

    // 3. Kids / Baby Furniture – 10 items
    const ServiceCategory(
      name: 'Kids / Baby Furniture',
      icon: Icons.child_care_outlined,
      description: 'Cribs, bunk beds, kids desks, toy storage',
      items: [
        ServiceItem(
          name: 'Baby Crib',
          price: 55,
          icon: Icons.child_care_outlined,
        ),
        ServiceItem(
          name: 'Convertible Crib',
          price: 65,
          icon: Icons.child_care_outlined,
        ),
        ServiceItem(name: 'Toddler Bed', price: 40, icon: Icons.bed_outlined),
        ServiceItem(name: 'Bunk Bed', price: 70, icon: Icons.layers_outlined),
        ServiceItem(name: 'Loft Bed', price: 75, icon: Icons.layers_outlined),
        ServiceItem(
          name: 'Kids Study Desk',
          price: 35,
          icon: Icons.desk_outlined,
        ),
        ServiceItem(name: 'Kids Chair', price: 15, icon: Icons.chair_outlined),
        ServiceItem(
          name: 'Toy Storage Organizer',
          price: 30,
          icon: Icons.grid_view_outlined,
        ),
        ServiceItem(
          name: 'Changing Table',
          price: 45,
          icon: Icons.baby_changing_station_outlined,
        ),
        ServiceItem(name: 'Kids Bookshelf', price: 25, icon: Icons.shelves),
      ],
      addons: addons,
    ),

    // 4. Outdoor Items – 10 items
    const ServiceCategory(
      name: 'Outdoor Items',
      icon: Icons.deck_outlined,
      description: 'Patio sets, garden furniture, gazebos',
      items: [
        ServiceItem(
          name: 'Patio Dining Set',
          price: 80,
          icon: Icons.deck_outlined,
        ),
        ServiceItem(
          name: 'Patio Chairs (Set)',
          price: 40,
          icon: Icons.chair_outlined,
        ),
        ServiceItem(name: 'Garden Bench', price: 40, icon: Icons.park_outlined),
        ServiceItem(
          name: 'Outdoor Lounge Chair',
          price: 35,
          icon: Icons.chair_outlined,
        ),
        ServiceItem(
          name: 'Hammock Stand',
          price: 45,
          icon: Icons.fence_outlined,
        ),
        ServiceItem(name: 'Pergola', price: 120, icon: Icons.house_outlined),
        ServiceItem(name: 'Gazebo', price: 150, icon: Icons.house_outlined),
        ServiceItem(
          name: 'Outdoor Storage Box',
          price: 50,
          icon: Icons.inventory_2_outlined,
        ),
        ServiceItem(
          name: 'BBQ Grill',
          price: 55,
          icon: Icons.outdoor_grill_outlined,
        ),
        ServiceItem(
          name: 'Patio Umbrella Stand',
          price: 30,
          icon: Icons.beach_access_outlined,
        ),
      ],
      addons: addons,
    ),
  ];

  /// Get a flat Map for backward compatibility with existing common steps.
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
