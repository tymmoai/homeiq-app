import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Cleaning service types, size options, conditions and add-ons.
/// Matches the web app's Cleaning service flow exactly.
///
/// 5 service types with size/condition modifiers.
class CleaningServiceData {
  CleaningServiceData._();

  static const String serviceName = 'Cleaning Services';
  static const String bookingIdPrefix = 'CL';
  static const double basePrice = 50.0;

  // ── Service Types (Step 1 — each type has its own size options) ────────
  static final List<ServiceCategory> categories = [
    // 1. Full Home Cleaning – base $99
    const ServiceCategory(
      name: 'Full Home Cleaning',
      icon: Icons.home_outlined,
      description: 'Complete home deep cleaning',
      items: [
        ServiceItem(name: '1 RK / Studio (up to 400 sq ft)', price: 99, icon: Icons.apartment_outlined),
        ServiceItem(name: '1 BHK (400-600 sq ft)', price: 129, icon: Icons.apartment_outlined),
        ServiceItem(name: '2 BHK (600-1000 sq ft)', price: 159, icon: Icons.house_outlined),
        ServiceItem(name: '3 BHK+ (1000+ sq ft)', price: 199, icon: Icons.house_outlined),
      ],
      addons: addons,
    ),

    // 2. Kitchen Cleaning – base $49
    const ServiceCategory(
      name: 'Kitchen Cleaning',
      icon: Icons.kitchen_outlined,
      description: 'Kitchen and appliances',
      items: [
        ServiceItem(name: 'Small Kitchen', price: 49, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Medium Kitchen', price: 69, icon: Icons.kitchen_outlined),
        ServiceItem(name: 'Large Kitchen', price: 89, icon: Icons.kitchen_outlined),
      ],
      addons: addons,
    ),

    // 3. Bathroom Cleaning – base $39
    const ServiceCategory(
      name: 'Bathroom Cleaning',
      icon: Icons.bathtub_outlined,
      description: 'Deep bathroom sanitization',
      items: [
        ServiceItem(name: '1 Bathroom', price: 39, icon: Icons.bathtub_outlined),
        ServiceItem(name: '2 Bathrooms', price: 69, icon: Icons.bathtub_outlined),
        ServiceItem(name: '3+ Bathrooms', price: 94, icon: Icons.bathtub_outlined),
      ],
      addons: addons,
    ),

    // 4. Sofa & Mattress – base $59
    const ServiceCategory(
      name: 'Sofa & Mattress',
      icon: Icons.weekend_outlined,
      description: 'Upholstery cleaning',
      items: [
        ServiceItem(name: '1 Seater (Chair/Recliner)', price: 59, icon: Icons.weekend_outlined),
        ServiceItem(name: '3 Seater (Standard Sofa)', price: 89, icon: Icons.weekend_outlined),
        ServiceItem(name: 'L-Shape Sofa', price: 119, icon: Icons.weekend_outlined),
        ServiceItem(name: '5+ Seater (Large Set)', price: 149, icon: Icons.weekend_outlined),
      ],
      addons: addons,
    ),

    // 5. Other / Custom – base $45
    const ServiceCategory(
      name: 'Other / Custom',
      icon: Icons.cleaning_services_outlined,
      description: 'Specific area cleaning',
      items: [
        ServiceItem(name: 'Single Room', price: 45, icon: Icons.crop_square_outlined),
        ServiceItem(name: 'Balcony Only', price: 60, icon: Icons.balcony_outlined),
        ServiceItem(name: 'Storage Area', price: 70, icon: Icons.inventory_2_outlined),
      ],
      addons: addons,
    ),
  ];

  // ── Condition Options (Step 3 — multiplier on size price) ─────────────
  static const Map<String, double> conditionMultipliers = {
    'Regular Cleaning': 1.0,
    'Deep Cleaning': 1.5,
    'Post-Renovation': 2.0,
  };

  static const Map<String, String> conditionDescriptions = {
    'Regular Cleaning': 'Light dust & dirt',
    'Deep Cleaning': 'Thorough with sanitization',
    'Post-Renovation': 'Heavy dust, debris cleanup',
  };

  // ── Add-ons (Step 5 — 5 options from web) ─────────────────────────────
  static const List<ServiceAddon> addons = [
    ServiceAddon(name: 'Fridge Interior', price: 25, icon: Icons.kitchen_outlined, description: 'Deep clean inside refrigerator'),
    ServiceAddon(name: 'Chimney Exterior', price: 20, icon: Icons.roofing_outlined, description: 'Clean chimney hood & filters'),
    ServiceAddon(name: 'Balcony', price: 15, icon: Icons.balcony_outlined, description: 'Mop & clean balcony area'),
    ServiceAddon(name: 'Pet Hair Removal', price: 30, icon: Icons.pets_outlined, description: 'Special vacuum for pet hair'),
    ServiceAddon(name: 'Hard Stain Treatment', price: 35, icon: Icons.water_drop_outlined, description: 'Stubborn stain removal'),
  ];

  // ── Recurring Options ─────────────────────────────────────────────────
  static const Map<String, double> recurringDiscounts = {
    'Weekly': 0.15,
    'Bi-weekly': 0.12,
    'Monthly': 0.10,
    'Quarterly': 0.08,
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
