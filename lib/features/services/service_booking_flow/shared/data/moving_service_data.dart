import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Moving service types, inventory items and packing options.
/// Matches the web app's Moving service flow exactly.
///
/// 4 service types with shared inventory (15 items in 3 groups).
class MovingServiceData {
  MovingServiceData._();

  static const String serviceName = 'Moving Services';
  static const String bookingIdPrefix = 'MOV';
  static const double basePrice = 60.0;

  // ── Service Types (Step 1 selection) ──────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. Within City
    const ServiceCategory(
      name: 'Within City',
      icon: Icons.location_city_outlined,
      description: 'Local moves within city limits',
      items: _inventoryItems,
    ),

    // 2. Intercity
    const ServiceCategory(
      name: 'Intercity',
      icon: Icons.map_outlined,
      description: 'Long distance moving services',
      items: _inventoryItems,
    ),

    // 3. Few Items
    const ServiceCategory(
      name: 'Few Items',
      icon: Icons.inventory_2_outlined,
      description: 'Small moves and single items',
      items: _inventoryItems,
    ),

    // 4. Office Move
    const ServiceCategory(
      name: 'Office Move',
      icon: Icons.business_outlined,
      description: 'Commercial moving services',
      items: _inventoryItems,
    ),
  ];

  // ── Base prices per service type ──────────────────────────────────────
  static const Map<String, double> serviceTypePrices = {
    'Within City': 149.0,
    'Intercity': 499.0,
    'Few Items': 79.0,
    'Office Move': 299.0,
  };

  // ── Inventory Items (shared across all service types) ─────────────────
  // Furniture – 6 items
  static const List<ServiceItem> _furnitureItems = [
    ServiceItem(name: 'Bed', price: 45, icon: Icons.bed_outlined),
    ServiceItem(name: 'Mattress', price: 25, icon: Icons.bed_outlined),
    ServiceItem(name: 'Wardrobe', price: 60, icon: Icons.door_sliding_outlined),
    ServiceItem(name: 'Sofa', price: 55, icon: Icons.weekend_outlined),
    ServiceItem(name: 'Table', price: 30, icon: Icons.table_restaurant_outlined),
    ServiceItem(name: 'Chairs', price: 15, icon: Icons.chair_outlined),
  ];

  // Appliances – 6 items
  static const List<ServiceItem> _applianceItems = [
    ServiceItem(name: 'TV', price: 35, icon: Icons.tv_outlined),
    ServiceItem(name: 'Fridge', price: 50, icon: Icons.kitchen_outlined),
    ServiceItem(name: 'Washer', price: 45, icon: Icons.local_laundry_service_outlined),
    ServiceItem(name: 'AC', price: 55, icon: Icons.ac_unit_outlined),
    ServiceItem(name: 'Microwave', price: 20, icon: Icons.microwave_outlined),
    ServiceItem(name: 'Other Appliance', price: 30, icon: Icons.devices_other_outlined),
  ];

  // Boxes – 3 options
  static const List<ServiceItem> _boxItems = [
    ServiceItem(name: 'Few Boxes (1-10)', price: 25, icon: Icons.inventory_2_outlined),
    ServiceItem(name: 'Many Boxes (10-25)', price: 55, icon: Icons.inventory_2_outlined),
    ServiceItem(name: 'Full House Boxes', price: 95, icon: Icons.inventory_2_outlined),
  ];

  static const List<ServiceItem> _inventoryItems = [
    ..._furnitureItems,
    ..._applianceItems,
    ..._boxItems,
  ];

  // ── Packing Options (Step 3 — multiplier on total) ────────────────────
  static const Map<String, double> packingMultipliers = {
    'No Packing': 1.0,
    'Partial Packing': 1.15,
    'Full Packing': 1.3,
  };

  static const Map<String, String> packingDescriptions = {
    'No Packing': 'Transport only',
    'Partial Packing': 'Fragile items only',
    'Full Packing': 'Complete packing service',
  };

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
