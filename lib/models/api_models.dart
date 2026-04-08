/// Data model representing a Home from the backend API.
///
/// Maps to the Prisma `Home` model in backend-client.
class HomeDto {
  final String id;
  final String? name;
  final String address;
  final String city;
  final String state;
  final String zip;
  final String country;
  final int? yearBuilt;
  final int? sqft;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Assets that belong to this home (only populated when fetching a single home).
  final List<AssetDto>? assets;

  /// 'owner' or 'family_member' — set by the backend when listing homes.
  final String? accessRole;

  /// 'owner', 'member', or 'viewer' — fine-grained role within the home.
  /// Null for home owners (they are always full-access owners).
  final String? memberRole;

  /// Service type keys this family member has been granted access to.
  /// Null for owners (owners have access to everything).
  /// e.g. ['maintenance', 'bookings', 'warranty']
  final List<String>? grantedServiceTypes;

  const HomeDto({
    required this.id,
    this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zip,
    required this.country,
    this.yearBuilt,
    this.sqft,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.assets,
    this.accessRole,
    this.memberRole,
    this.grantedServiceTypes,
  });

  factory HomeDto.fromJson(Map<String, dynamic> json) {
    return HomeDto(
      id: json['id'] as String,
      name: json['name'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zip: json['zip'] as String,
      country: json['country'] as String? ?? 'US',
      yearBuilt: json['yearBuilt'] as int?,
      sqft: json['sqft'] as int?,
      imageUrl: json['imageUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      assets: json['assets'] != null
          ? (json['assets'] as List)
                .map((a) => AssetDto.fromJson(a as Map<String, dynamic>))
                .toList()
          : null,
      accessRole: json['accessRole'] as String?,
      memberRole: json['memberRole'] as String?,
      grantedServiceTypes: json['grantedServiceTypes'] != null
          ? List<String>.from(json['grantedServiceTypes'] as List)
          : null,
    );
  }

  /// Whether the current user is the owner of this home.
  bool get isOwner => accessRole == null || accessRole == 'owner';

  /// Whether the current user is a family member of this home.
  bool get isFamilyMember => accessRole == 'family_member';

  /// Whether this family member has viewer-only access (cannot write).
  bool get isViewer => memberRole == 'viewer';

  /// Whether this family member has a specific service type granted.
  bool hasServiceAccess(String serviceType) {
    if (isOwner) return true;
    return grantedServiceTypes?.contains(serviceType) ?? false;
  }

  Map<String, dynamic> toJson() => {
    'address': address,
    'city': city,
    'state': state,
    'zip': zip,
    'country': country,
    if (yearBuilt != null) 'yearBuilt': yearBuilt,
    if (sqft != null) 'sqft': sqft,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  /// A display-friendly label — uses the home name if set, else "address, city".
  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : '$address, $city';
}

/// Data model representing an Asset from the backend API.
///
/// Maps to the Prisma `Asset` model in backend-client.
class AssetDto {
  final String id;
  final String homeId;
  final String name;
  final String category;
  final String? brand;
  final String? model;
  final String? serialNumber;
  final DateTime? purchasedAt;
  final DateTime? warrantyExpiresAt;
  final String? imageUrl;
  final String? notes;

  // ── Enriched fields from barcode / ChatGPT scan pipeline ─────────────
  final String? productTitle;
  final String? productDescription;
  final String? productCategory;
  final String? subCategory;
  final String? manufacturer;
  final String? mpn;
  final String? barcode;
  final String? productImageUrl;
  final String? productColor;
  final String? enrichmentSource;

  // ── Purchase & location metadata ──────────────────────────────────────
  final String? location;
  final int? purchaseYear;
  final int? purchaseMonth;

  // ── Network / WiFi metadata ───────────────────────────────────────────
  final String? networkMac;
  final String? networkIp;

  // ── Computed by backend: last maintenance service date ────────────────
  final DateTime? lastServiceDate;

  // ── Computed by backend: active protection plan ───────────────────────
  /// True when the asset has a protection plan with isActive=true and
  /// coverageEnd still in the future.  Populated by the backend so the
  /// list screen shows the correct warranty badge without a separate call.
  final bool hasActiveProtectionPlan;

  /// Coverage end date of the active protection plan, if any.
  final DateTime? protectionPlanExpiresAt;

  final DateTime createdAt;
  final DateTime updatedAt;

  const AssetDto({
    required this.id,
    required this.homeId,
    required this.name,
    required this.category,
    this.brand,
    this.model,
    this.serialNumber,
    this.purchasedAt,
    this.warrantyExpiresAt,
    this.imageUrl,
    this.notes,
    this.productTitle,
    this.productDescription,
    this.productCategory,
    this.subCategory,
    this.manufacturer,
    this.mpn,
    this.barcode,
    this.productImageUrl,
    this.productColor,
    this.enrichmentSource,
    this.location,
    this.purchaseYear,
    this.purchaseMonth,
    this.networkMac,
    this.networkIp,
    this.lastServiceDate,
    this.hasActiveProtectionPlan = false,
    this.protectionPlanExpiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AssetDto.fromJson(Map<String, dynamic> json) {
    return AssetDto(
      id: json['id'] as String,
      homeId: json['homeId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      brand: json['brand'] as String?,
      model: json['model'] as String?,
      serialNumber: json['serialNumber'] as String?,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.tryParse(json['purchasedAt'] as String)
          : null,
      warrantyExpiresAt: json['warrantyExpiresAt'] != null
          ? DateTime.tryParse(json['warrantyExpiresAt'] as String)
          : null,
      imageUrl: json['imageUrl'] as String?,
      notes: json['notes'] as String?,
      productTitle: json['productTitle'] as String?,
      productDescription: json['productDescription'] as String?,
      productCategory: json['productCategory'] as String?,
      subCategory: json['subCategory'] as String?,
      manufacturer: json['manufacturer'] as String?,
      mpn: json['mpn'] as String?,
      barcode: json['barcode'] as String?,
      productImageUrl: json['productImageUrl'] as String?,
      productColor: json['productColor'] as String?,
      enrichmentSource: json['enrichmentSource'] as String?,
      location: json['location'] as String?,
      purchaseYear: json['purchaseYear'] as int?,
      purchaseMonth: json['purchaseMonth'] as int?,
      networkMac: json['networkMac'] as String?,
      networkIp: json['networkIp'] as String?,
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.tryParse(json['lastServiceDate'] as String)
          : null,
      hasActiveProtectionPlan:
          json['hasActiveProtectionPlan'] as bool? ?? false,
      protectionPlanExpiresAt: json['protectionPlanExpiresAt'] != null
          ? DateTime.tryParse(json['protectionPlanExpiresAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'homeId': homeId,
    'name': name,
    'category': category,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    if (serialNumber != null) 'serialNumber': serialNumber,
    if (purchasedAt != null) 'purchasedAt': purchasedAt!.toIso8601String(),
    if (warrantyExpiresAt != null)
      'warrantyExpiresAt': warrantyExpiresAt!.toIso8601String(),
    if (imageUrl != null) 'imageUrl': imageUrl,
    if (notes != null) 'notes': notes,
    if (productTitle != null) 'productTitle': productTitle,
    if (productDescription != null) 'productDescription': productDescription,
    if (productCategory != null) 'productCategory': productCategory,
    if (subCategory != null) 'subCategory': subCategory,
    if (manufacturer != null) 'manufacturer': manufacturer,
    if (mpn != null) 'mpn': mpn,
    if (barcode != null) 'barcode': barcode,
    if (productImageUrl != null) 'productImageUrl': productImageUrl,
    if (productColor != null) 'productColor': productColor,
    if (enrichmentSource != null) 'enrichmentSource': enrichmentSource,
    if (location != null) 'location': location,
    if (purchaseYear != null) 'purchaseYear': purchaseYear,
    if (purchaseMonth != null) 'purchaseMonth': purchaseMonth,
    if (networkMac != null) 'networkMac': networkMac,
    if (networkIp != null) 'networkIp': networkIp,
  };

  /// Whether the warranty (manufacturer OR active protection plan) is active.
  bool get isWarrantyActive =>
      hasActiveProtectionPlan ||
      (warrantyExpiresAt != null && warrantyExpiresAt!.isAfter(DateTime.now()));

  /// Warranty status as human-readable text.
  String get warrantyStatus => isWarrantyActive ? 'Active' : 'Expired';

  /// The effective warranty expiry date — uses the protection plan's
  /// coverage end if a plan is active and extends past the original warranty.
  DateTime? get effectiveWarrantyExpiry {
    if (hasActiveProtectionPlan && protectionPlanExpiresAt != null) {
      if (warrantyExpiresAt == null ||
          protectionPlanExpiresAt!.isAfter(warrantyExpiresAt!)) {
        return protectionPlanExpiresAt;
      }
    }
    return warrantyExpiresAt;
  }

  /// Converts this typed DTO to the legacy `Map<String, dynamic>` format
  /// that existing UI widgets (AssetDetailCard, AssetDetailScreen, etc.) expect.
  ///
  /// This is a bridge so we can start showing real data without rewriting every widget.
  Map<String, dynamic> toLegacyMap() {
    final now = DateTime.now();

    // ── Health Score Calculation (1–10) ─────────────────────────────────────
    // Uses a multi-factor model based on real asset data:
    //   1. Age vs typical lifespan (category-aware)
    //   2. Warranty status
    //   3. Time since last maintenance service
    double healthScore = 10.0;

    // 1. Age factor — compare actual age against the expected lifespan for this category.
    final int typicalLifespan = _typicalLifespanYears(category);
    final ageYears = purchasedAt != null
        ? now.difference(purchasedAt!).inDays / 365.25
        : (purchaseYear != null ? (now.year - purchaseYear!).toDouble() : 0.0);

    if (ageYears > 0) {
      // usedLifeFraction: 0 = brand new, 1 = at end of typical life, >1 = past lifespan
      final usedLifeFraction = ageYears / typicalLifespan;
      // Deduct up to 5.0 points over the full expected lifespan (0.5 per 10%)
      final agePenalty = (usedLifeFraction * 5.0).clamp(0.0, 7.0);
      healthScore -= agePenalty;
    }

    // 2. Warranty status
    if (!isWarrantyActive) {
      healthScore -= 1.0;
    }

    // 3. Maintenance recency — penalise for assets that have never been serviced
    //    or were last serviced a long time ago.
    if (lastServiceDate == null) {
      // Never serviced: small penalty (0.5) — not catastrophic but notable
      healthScore -= 0.5;
    } else {
      final daysSinceService = now.difference(lastServiceDate!).inDays;
      // Penalty increases linearly from 0 (just serviced) to 1.0 (2+ years without service)
      final servicePenalty = (daysSinceService / 730.0).clamp(0.0, 1.0);
      healthScore -= servicePenalty;
    }

    // Clamp to valid range and round to 1 decimal
    healthScore = healthScore.clamp(1.0, 10.0);
    healthScore = (healthScore * 10).round() / 10;

    // Last service date from backend — formatted as "12 Mar 2026"
    String lastService = 'Never';
    if (lastServiceDate != null) {
      lastService =
          '${lastServiceDate!.day} ${_monthName(lastServiceDate!.month)} ${lastServiceDate!.year}';
    }

    // Build a formatted warranty end date string for display.
    // Use effectiveWarrantyExpiry so the plan end date is shown when active.
    String warrantyEndDateStr = '';
    final displayExpiry = effectiveWarrantyExpiry;
    if (displayExpiry != null) {
      warrantyEndDateStr =
          '${_monthName(displayExpiry.month)} ${displayExpiry.day}, ${displayExpiry.year}';
    }

    return {
      'id': id,
      'homeId': homeId,
      'name': name,
      'brand': brand ?? 'Unknown',
      'type': category,
      'location': location ?? '',
      'model': model ?? '',
      'serial': serialNumber ?? '',
      'healthScore': healthScore,
      'lastService': lastService,
      'warranty': warrantyStatus,
      // Use effective expiry (plan takes precedence when it extends coverage)
      'warrantyEndDate': effectiveWarrantyExpiry?.toIso8601String() ?? '',
      'warrantyEndDateDisplay': warrantyEndDateStr,
      // Expose plan flag so computeWarrantyStatus() in the list card works
      // without a separate per-asset protection-plan API call.
      'hasActiveProtectionPlan': hasActiveProtectionPlan,
      'purchaseYear': purchaseYear ?? (purchasedAt?.year ?? now.year),
      'purchaseDate': purchasedAt != null
          ? '${_monthName(purchasedAt!.month)} ${purchasedAt!.year}'
          : 'Unknown',
      'pastRepairs': 0,
      'status': healthScore >= 8
          ? 'Good'
          : healthScore >= 6
          ? 'Need Attention'
          : 'Critical',
      'image': _categoryToImage(category),
      'lifecycleStatus': 'active',
      // Enriched fields — used by asset detail screens
      'productTitle': productTitle ?? name,
      'description': productDescription ?? '',
      'productCategory': productCategory ?? '',
      'subCategory': subCategory ?? '',
      'manufacturer': manufacturer ?? brand ?? '',
      'mpn': mpn ?? '',
      'barcode': barcode ?? '',
      'productImageUrl': productImageUrl ?? imageUrl ?? '',
      'productColor': productColor ?? '',
      'enrichmentSource': enrichmentSource ?? '',
      // Used to sort assets newest-first in the assets tab.
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Returns the typical expected lifespan (in years) for a given appliance category.
  static int _typicalLifespanYears(String category) {
    final c = category.toLowerCase();
    if (c.contains('hvac') ||
        c.contains('air conditioner') ||
        c.contains('heat pump')) {
      return 15;
    }
    if (c.contains('refrigerator') || c.contains('fridge')) return 13;
    if (c.contains('washer') || c.contains('washing machine')) return 10;
    if (c.contains('dryer')) return 10;
    if (c.contains('dishwasher')) return 10;
    if (c.contains('water heater')) return 10;
    if (c.contains('oven') || c.contains('stove') || c.contains('range')) {
      return 13;
    }
    if (c.contains('microwave')) return 9;
    if (c.contains('television') || c.contains(' tv')) return 7;
    if (c.contains('furnace') || c.contains('boiler')) return 18;
    if (c.contains('roof')) return 25;
    if (c.contains('window') || c.contains('door')) return 20;
    if (c.contains('plumbing') || c.contains('pipe')) return 20;
    if (c.contains('electrical') || c.contains('panel')) return 25;
    return 10; // default for unknown categories
  }

  static String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }

  /// Best-effort mapping from backend category string to local asset image key.
  static String _categoryToImage(String category) {
    final c = category.toLowerCase();
    if (c.contains('hvac') || c.contains('air')) return 'air_conditioner';
    if (c.contains('refrigerator') || c.contains('fridge')) {
      return 'refrigerator';
    }
    if (c.contains('washer') || c.contains('washing')) return 'washing_machine';
    if (c.contains('dryer')) return 'dryer';
    if (c.contains('dishwasher')) return 'dishwasher';
    if (c.contains('oven') || c.contains('stove') || c.contains('range')) {
      return 'oven';
    }
    if (c.contains('microwave')) return 'microwave';
    if (c.contains('tv') || c.contains('television')) return 'tv';
    if (c.contains('water heater')) return 'water_heater';
    if (c.contains('plumbing')) return 'plumbing';
    if (c.contains('electrical')) return 'electrical';
    return 'appliance';
  }
}
