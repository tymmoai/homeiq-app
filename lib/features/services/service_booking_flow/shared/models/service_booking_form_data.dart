import 'package:flutter/material.dart';

/// Unified service item model
class ServiceItem {
  final String name;
  final double price;
  final IconData icon;
  final String? description;
  final String? duration;

  const ServiceItem({
    required this.name,
    required this.price,
    required this.icon,
    this.description,
    this.duration,
  });
}

/// Service addon model
class ServiceAddon {
  final String name;
  final double price;
  final IconData icon;
  final String? description;

  const ServiceAddon({
    required this.name,
    required this.price,
    required this.icon,
    this.description,
  });
}

/// Service category (sub-service type) model
class ServiceCategory {
  final String name;
  final IconData icon;
  final String? description;
  final List<ServiceItem> items;
  final List<ServiceAddon> addons;

  const ServiceCategory({
    required this.name,
    required this.icon,
    this.description,
    required this.items,
    this.addons = const [],
  });
}

/// Unified form data model for all service booking flows.
///
/// Each service flow creates one instance and passes it by reference to all steps.
/// This eliminates the need for duplicate FormData classes per service.
class ServiceBookingFormData {
  // ── Service Selection ──
  String? selectedService;
  String? serviceIcon;

  // ── Item Selection ──
  Map<String, int> selectedItems = {};
  double totalPrice = 0.0;

  // ── Addons ──
  Set<String> selectedAddons = {};

  // ── Size / Condition (for services like Moving, Cleaning) ──
  String? propertyType;
  String? propertySize;
  String? condition;

  // ── Moving-specific ──
  String? homeType;
  String? homeSize;
  int? numberOfRooms;
  int? floorLevel;
  bool? hasElevator;
  String? furnitureType;
  bool? isWithinHome;
  String? officeSize;
  String? heavyItemType;
  String? pickupAddress;
  String? dropoffAddress;
  double? distance;

  // ── Cleaning-specific ──
  String? cleaningFrequency;
  String? cleaningIntensity;
  String? preferredTiming;
  String? constructionType;
  String? buildingType;
  String? windowCoverage;
  String? carpetScope;

  // ── Mounting-specific ──
  String? wallType;
  String? mountingHeight;

  // ── Painting-specific ──
  String? paintType;
  String? surfaceCondition;

  // ── Security-specific ──
  String? deviceBrand;
  String? existingSystem;

  // ── Special Requirements ──
  String? specialRequirements;

  // ── Scheduling ──
  DateTime? selectedDate;
  String? selectedTimeSlot;
  String? dateSelectionType; // 'today', 'tomorrow', 'custom'

  // ── Terms & Booking ──
  bool termsAccepted = false;
  String? bookingId;

  // ── Contact Information ──
  String? customerName;
  String? customerEmail;
  String? customerPhone;

  // ── Service Address ──
  String? serviceAddress;
  String? serviceCity;
  String? serviceState;
  String? serviceZipCode;
  String? serviceApartmentUnit;

  // ── Photo Upload (Home Repairs) ──
  List<String> photoUrls = [];

  /// Computed total of all selected items based on the service category items.
  double calculateItemsTotal(List<ServiceItem> availableItems) {
    double total = 0;
    selectedItems.forEach((itemName, quantity) {
      final item = availableItems.firstWhere(
        (i) => i.name == itemName,
        orElse: () => const ServiceItem(
          name: '',
          price: 0,
          icon: Icons.error,
        ),
      );
      total += item.price * quantity;
    });
    return total;
  }

  /// Computed total of all selected addons.
  double calculateAddonsTotal(List<ServiceAddon> availableAddons) {
    double total = 0;
    for (final addonName in selectedAddons) {
      final addon = availableAddons.firstWhere(
        (a) => a.name == addonName,
        orElse: () => const ServiceAddon(
          name: '',
          price: 0,
          icon: Icons.error,
        ),
      );
      total += addon.price;
    }
    return total;
  }

  /// Total selected item count.
  int get totalItemCount {
    int count = 0;
    selectedItems.forEach((_, qty) => count += qty);
    return count;
  }

  /// Reset all service-specific fields when changing service type.
  void clearServiceSpecificData() {
    selectedItems.clear();
    selectedAddons.clear();
    totalPrice = 0.0;
    propertyType = null;
    propertySize = null;
    condition = null;
    homeType = null;
    homeSize = null;
    numberOfRooms = null;
    floorLevel = null;
    hasElevator = null;
    furnitureType = null;
    isWithinHome = null;
    officeSize = null;
    heavyItemType = null;
    pickupAddress = null;
    dropoffAddress = null;
    distance = null;
    cleaningFrequency = null;
    cleaningIntensity = null;
    preferredTiming = null;
    constructionType = null;
    buildingType = null;
    windowCoverage = null;
    carpetScope = null;
    wallType = null;
    mountingHeight = null;
    paintType = null;
    surfaceCondition = null;
    deviceBrand = null;
    existingSystem = null;
    specialRequirements = null;
    photoUrls.clear();
  }
}
