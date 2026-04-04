import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Smart Home & Security device types, installation options, and add-ons.
/// Matches the web app's Security service flow exactly.
///
/// 4 device types with installation type multipliers, device details, and 6 add-ons.
class SecurityServiceData {
  SecurityServiceData._();

  static const String serviceName = 'Smart Home & Security';
  static const String bookingIdPrefix = 'SC';
  static const double basePrice = 75.0;

  // ── Device Types (Step 1 — 4 options) ─────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. Security Camera – base $149
    const ServiceCategory(
      name: 'Security Camera',
      icon: Icons.videocam_outlined,
      description: 'Indoor/outdoor surveillance',
      items: [
        ServiceItem(name: 'Security Camera', price: 149, icon: Icons.videocam_outlined),
      ],
      addons: addons,
    ),

    // 2. Smart Lock – base $199
    const ServiceCategory(
      name: 'Smart Lock',
      icon: Icons.lock_outlined,
      description: 'Keyless door entry',
      items: [
        ServiceItem(name: 'Smart Lock', price: 199, icon: Icons.lock_outlined),
      ],
      addons: addons,
    ),

    // 3. Alarm System – base $249
    const ServiceCategory(
      name: 'Alarm System',
      icon: Icons.security_outlined,
      description: 'Home security alerts',
      items: [
        ServiceItem(name: 'Alarm System', price: 249, icon: Icons.security_outlined),
      ],
      addons: addons,
    ),

    // 4. Full Security Setup – base $499
    const ServiceCategory(
      name: 'Full Security Setup',
      icon: Icons.verified_user_outlined,
      description: 'Complete home security',
      items: [
        ServiceItem(name: 'Full Security Setup', price: 499, icon: Icons.verified_user_outlined),
      ],
      addons: addons,
    ),
  ];

  // ── Installation Types (Step 2 — multiplier) ─────────────────────────
  static const Map<String, double> installationTypeMultipliers = {
    'New Installation': 1.0,
    'Replace Existing': 1.2,
    'Need Recommendation': 1.1,
  };

  static const Map<String, String> installationTypeDescriptions = {
    'New Installation': 'Fresh install from scratch',
    'Replace Existing': 'Remove old & install new',
    'Need Recommendation': 'Expert consultation included',
  };

  // ── Device Details Options (Step 3) ───────────────────────────────────
  static const List<String> locationOptions = ['Indoor', 'Outdoor', 'Both'];
  static const List<String> powerTypeOptions = ['Wired', 'Battery', 'Solar'];

  // ── Add-ons (Step 4 — 6 options from web) ─────────────────────────────
  static const List<ServiceAddon> addons = [
    ServiceAddon(name: 'App Setup & Configuration', price: 25, icon: Icons.phone_android_outlined, description: 'Connect to phone app'),
    ServiceAddon(name: 'Wi-Fi Integration', price: 20, icon: Icons.wifi_outlined, description: 'Connect to home network'),
    ServiceAddon(name: 'Wall Drilling', price: 35, icon: Icons.construction_outlined, description: 'Professional mounting'),
    ServiceAddon(name: 'Cable Concealment', price: 45, icon: Icons.cable_outlined, description: 'Hide cables neatly'),
    ServiceAddon(name: 'User Training', price: 30, icon: Icons.school_outlined, description: '30-min walkthrough'),
    ServiceAddon(name: 'Smart Hub Setup', price: 40, icon: Icons.hub_outlined, description: 'Central control integration'),
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
