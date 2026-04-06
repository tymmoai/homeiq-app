import 'package:flutter/material.dart';
import '../models/service_booking_form_data.dart';

/// Home Repairs service categories and issues data.
/// Matches the web app's Home Repairs service flow exactly.
///
/// 6 categories with diagnostic fees, price ranges, and urgency modifiers.
class HomeRepairsServiceData {
  HomeRepairsServiceData._();

  static const String serviceName = 'Home Repairs';
  static const String bookingIdPrefix = 'HR';
  static const double basePrice = 65.0;

  // ── Categories (Step 1 — 6 options) ───────────────────────────────────
  static final List<ServiceCategory> categories = [
    // 1. Water Leak / Clog – diagnostic $89, 9 issues
    const ServiceCategory(
      name: 'Water Leak / Clog',
      icon: Icons.water_drop_outlined,
      description: 'Leaky pipes, clogged drains, toilet issues',
      items: [
        ServiceItem(
          name: 'Leaky Faucet',
          price: 75,
          icon: Icons.water_drop_outlined,
        ),
        ServiceItem(
          name: 'Clogged Drain',
          price: 100,
          icon: Icons.plumbing_outlined,
        ),
        ServiceItem(
          name: 'Clogged Toilet',
          price: 100,
          icon: Icons.wc_outlined,
        ),
        ServiceItem(name: 'Running Toilet', price: 75, icon: Icons.wc_outlined),
        ServiceItem(
          name: 'Pipe Leak',
          price: 150,
          icon: Icons.water_damage_outlined,
        ),
        ServiceItem(
          name: 'Water Heater Issue',
          price: 150,
          icon: Icons.hot_tub_outlined,
        ),
        ServiceItem(
          name: 'Garbage Disposal',
          price: 100,
          icon: Icons.delete_sweep_outlined,
        ),
        ServiceItem(
          name: 'Sump Pump Issue',
          price: 150,
          icon: Icons.plumbing_outlined,
        ),
        ServiceItem(
          name: 'Other Water Issue',
          price: 89,
          icon: Icons.help_outline_outlined,
        ),
      ],
    ),

    // 2. Electrical Not Working – diagnostic $99, 9 issues
    const ServiceCategory(
      name: 'Electrical Not Working',
      icon: Icons.electrical_services_outlined,
      description: 'Outlets, lights, switches, circuits',
      items: [
        ServiceItem(
          name: 'Outlet Not Working',
          price: 75,
          icon: Icons.outlet_outlined,
        ),
        ServiceItem(
          name: 'Light Not Working',
          price: 75,
          icon: Icons.lightbulb_outlined,
        ),
        ServiceItem(
          name: 'Circuit Breaker Tripping',
          price: 100,
          icon: Icons.power_outlined,
        ),
        ServiceItem(
          name: 'Switch Not Working',
          price: 50,
          icon: Icons.toggle_on_outlined,
        ),
        ServiceItem(
          name: 'Ceiling Fan Issue',
          price: 100,
          icon: Icons.mode_fan_off_outlined,
        ),
        ServiceItem(
          name: 'Flickering Lights',
          price: 100,
          icon: Icons.lightbulb_outlined,
        ),
        ServiceItem(
          name: 'No Power in Area',
          price: 100,
          icon: Icons.power_off_outlined,
        ),
        ServiceItem(
          name: 'Sparking Outlet',
          price: 100,
          icon: Icons.warning_outlined,
        ),
        ServiceItem(
          name: 'Other Electrical Issue',
          price: 99,
          icon: Icons.help_outline_outlined,
        ),
      ],
    ),

    // 3. Wall / Ceiling Damage – diagnostic $69, 8 issues
    const ServiceCategory(
      name: 'Wall / Ceiling Damage',
      icon: Icons.construction_outlined,
      description: 'Holes, cracks, water stains, drywall',
      items: [
        ServiceItem(
          name: 'Hole in Wall',
          price: 75,
          icon: Icons.construction_outlined,
        ),
        ServiceItem(
          name: 'Crack in Wall',
          price: 100,
          icon: Icons.auto_fix_high_outlined,
        ),
        ServiceItem(
          name: 'Water Stain',
          price: 150,
          icon: Icons.water_damage_outlined,
        ),
        ServiceItem(
          name: 'Ceiling Damage',
          price: 200,
          icon: Icons.roofing_outlined,
        ),
        ServiceItem(
          name: 'Drywall Repair',
          price: 100,
          icon: Icons.grid_3x3_outlined,
        ),
        ServiceItem(
          name: 'Paint Touch-up',
          price: 75,
          icon: Icons.format_paint_outlined,
        ),
        ServiceItem(
          name: 'Texture Repair',
          price: 100,
          icon: Icons.texture_outlined,
        ),
        ServiceItem(
          name: 'Other Wall/Ceiling Issue',
          price: 69,
          icon: Icons.help_outline_outlined,
        ),
      ],
    ),

    // 4. Door / Window Issue – diagnostic $59, 8 issues
    const ServiceCategory(
      name: 'Door / Window Issue',
      icon: Icons.door_sliding_outlined,
      description: 'Stuck doors, broken locks, windows',
      items: [
        ServiceItem(
          name: 'Door Not Closing',
          price: 75,
          icon: Icons.door_sliding_outlined,
        ),
        ServiceItem(
          name: 'Door Lock Issue',
          price: 75,
          icon: Icons.lock_outlined,
        ),
        ServiceItem(
          name: 'Squeaky Door / Hinges',
          price: 50,
          icon: Icons.door_sliding_outlined,
        ),
        ServiceItem(
          name: 'Window Stuck',
          price: 75,
          icon: Icons.window_outlined,
        ),
        ServiceItem(
          name: 'Broken Window',
          price: 150,
          icon: Icons.warning_outlined,
        ),
        ServiceItem(
          name: 'Screen Repair',
          price: 50,
          icon: Icons.window_outlined,
        ),
        ServiceItem(
          name: 'Weatherstripping',
          price: 75,
          icon: Icons.thermostat_outlined,
        ),
        ServiceItem(
          name: 'Other Door/Window Issue',
          price: 59,
          icon: Icons.help_outline_outlined,
        ),
      ],
    ),

    // 5. Appliance Issue – diagnostic $89, 10 issues
    const ServiceCategory(
      name: 'Appliance Issue',
      icon: Icons.kitchen_outlined,
      description: 'Fridge, washer, dryer, HVAC',
      items: [
        ServiceItem(
          name: 'Refrigerator',
          price: 150,
          icon: Icons.kitchen_outlined,
        ),
        ServiceItem(
          name: 'Washing Machine',
          price: 150,
          icon: Icons.local_laundry_service_outlined,
        ),
        ServiceItem(name: 'Dryer', price: 150, icon: Icons.dry_outlined),
        ServiceItem(
          name: 'Dishwasher',
          price: 150,
          icon: Icons.countertops_outlined,
        ),
        ServiceItem(
          name: 'Oven / Stove',
          price: 150,
          icon: Icons.microwave_outlined,
        ),
        ServiceItem(
          name: 'Microwave',
          price: 100,
          icon: Icons.microwave_outlined,
        ),
        ServiceItem(
          name: 'Garbage Disposal',
          price: 100,
          icon: Icons.delete_sweep_outlined,
        ),
        ServiceItem(
          name: 'HVAC / AC',
          price: 150,
          icon: Icons.ac_unit_outlined,
        ),
        ServiceItem(
          name: 'Water Heater',
          price: 150,
          icon: Icons.hot_tub_outlined,
        ),
        ServiceItem(
          name: 'Other Appliance',
          price: 89,
          icon: Icons.help_outline_outlined,
        ),
      ],
    ),

    // 6. Something Else – diagnostic $79
    const ServiceCategory(
      name: 'Something Else',
      icon: Icons.handyman_outlined,
      description: 'Other - add photo & description',
      items: [
        ServiceItem(
          name: 'Custom Repair Request',
          price: 79,
          icon: Icons.handyman_outlined,
        ),
      ],
    ),
  ];

  // ── Diagnostic Fees per category ──────────────────────────────────────
  static const Map<String, double> diagnosticFees = {
    'Water Leak / Clog': 89.0,
    'Electrical Not Working': 99.0,
    'Wall / Ceiling Damage': 69.0,
    'Door / Window Issue': 59.0,
    'Appliance Issue': 89.0,
    'Something Else': 79.0,
  };

  // ── Urgency Options ───────────────────────────────────────────────────
  static const Map<String, double> urgencyMultipliers = {
    'Emergency (2-4 hrs)': 1.5,
    'Same Day': 1.25,
    'Flexible (1-3 days)': 1.0,
  };

  static const Map<String, double> urgencyFees = {
    'Emergency (2-4 hrs)': 75.0,
    'Same Day': 35.0,
    'Flexible (1-3 days)': 0.0,
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
