// Models for Family Members & Access Control.
//
// Maps to the Prisma models: FamilyMember, FamilyInvite,
// FamilyMemberAssetAccess, FamilyMemberServiceAccess.

// ─── Shared sub-models ──────────────────────────────────────────────────────

/// Minimal user info returned by the backend includes.
class FamilyUserDto {
  final String id;
  final String email;
  final String? name;
  final String? avatarUrl;

  const FamilyUserDto({
    required this.id,
    required this.email,
    this.name,
    this.avatarUrl,
  });

  factory FamilyUserDto.fromJson(Map<String, dynamic> json) {
    return FamilyUserDto(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }
}

/// Minimal home info for member detail views.
class FamilyHomeDto {
  final String id;
  final String? name;
  final String address;
  final String city;
  final String state;
  final String? zip;
  final String? imageUrl;

  const FamilyHomeDto({
    required this.id,
    this.name,
    required this.address,
    required this.city,
    required this.state,
    this.zip,
    this.imageUrl,
  });

  factory FamilyHomeDto.fromJson(Map<String, dynamic> json) {
    return FamilyHomeDto(
      id: json['id'] as String,
      name: json['name'] as String?,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zip: json['zip'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Uses home name if set, otherwise falls back to address.
  String get displayName =>
      (name != null && name!.isNotEmpty) ? name! : '$address, $city';
}

/// Asset info attached to asset-access grants.
class FamilyAssetDto {
  final String id;
  final String name;
  final String? category;
  final String? imageUrl;
  final String? homeId;

  const FamilyAssetDto({
    required this.id,
    required this.name,
    this.category,
    this.imageUrl,
    this.homeId,
  });

  factory FamilyAssetDto.fromJson(Map<String, dynamic> json) {
    return FamilyAssetDto(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String?,
      imageUrl: json['imageUrl'] as String?,
      homeId: json['homeId'] as String?,
    );
  }
}

/// A single asset-access entry (may include nested asset info).
class AssetAccessEntry {
  final String assetId;
  final FamilyAssetDto? asset;

  const AssetAccessEntry({required this.assetId, this.asset});

  factory AssetAccessEntry.fromJson(Map<String, dynamic> json) {
    return AssetAccessEntry(
      assetId: json['assetId'] as String,
      asset: json['asset'] != null
          ? FamilyAssetDto.fromJson(json['asset'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// A single service-access entry.
class ServiceAccessEntry {
  final String? id;
  final String serviceType;

  const ServiceAccessEntry({this.id, required this.serviceType});

  factory ServiceAccessEntry.fromJson(Map<String, dynamic> json) {
    return ServiceAccessEntry(
      id: json['id'] as String?,
      serviceType: json['serviceType'] as String,
    );
  }
}

// ─── Primary DTOs ───────────────────────────────────────────────────────────

/// Family member as returned by `GET /family` (owner view — list).
class FamilyMemberDto {
  final String id;
  final String homeId;
  final String userId;
  final String role;
  final String? relation;
  final bool grantFutureAssets;
  final FamilyUserDto? user;
  final List<AssetAccessEntry> assetAccess;
  final List<ServiceAccessEntry> serviceAccess;

  const FamilyMemberDto({
    required this.id,
    required this.homeId,
    required this.userId,
    required this.role,
    this.relation,
    this.grantFutureAssets = false,
    this.user,
    this.assetAccess = const [],
    this.serviceAccess = const [],
  });

  factory FamilyMemberDto.fromJson(Map<String, dynamic> json) {
    return FamilyMemberDto(
      id: json['id'] as String,
      homeId: json['homeId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String? ?? 'member',
      relation: json['relation'] as String?,
      grantFutureAssets: json['grantFutureAssets'] as bool? ?? false,
      user: json['user'] != null
          ? FamilyUserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      assetAccess:
          (json['assetAccess'] as List?)
              ?.map((a) => AssetAccessEntry.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      serviceAccess:
          (json['serviceAccess'] as List?)
              ?.map(
                (s) => ServiceAccessEntry.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  /// Convenience: list of granted asset IDs.
  List<String> get grantedAssetIds =>
      assetAccess.map((a) => a.assetId).toList();

  /// Convenience: list of granted service type strings.
  List<String> get grantedServiceTypes =>
      serviceAccess.map((s) => s.serviceType).toList();
}

/// Pending invite as returned by `GET /family/pending-invites` (owner view).
class FamilyInviteDto {
  final String id;
  final String email;
  final String homeId;
  final String role;
  final String? relation;
  final String? inviteeName;
  final bool grantFutureAssets;
  final List<String> assetIds;
  final List<String> serviceTypes;
  final DateTime createdAt;
  final DateTime expiresAt;

  const FamilyInviteDto({
    required this.id,
    required this.email,
    required this.homeId,
    required this.role,
    this.relation,
    this.inviteeName,
    this.grantFutureAssets = false,
    this.assetIds = const [],
    this.serviceTypes = const [],
    required this.createdAt,
    required this.expiresAt,
  });

  factory FamilyInviteDto.fromJson(Map<String, dynamic> json) {
    return FamilyInviteDto(
      id: json['id'] as String,
      email: json['email'] as String,
      homeId: json['homeId'] as String,
      role: json['role'] as String? ?? 'member',
      relation: json['relation'] as String?,
      inviteeName: json['inviteeName'] as String?,
      grantFutureAssets: json['grantFutureAssets'] as bool? ?? false,
      assetIds:
          (json['assetIds'] as List?)?.map((e) => e as String).toList() ?? [],
      serviceTypes:
          (json['serviceTypes'] as List?)?.map((e) => e as String).toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());

  Duration get timeRemaining => expiresAt.difference(DateTime.now());
}

/// Full access details for a single member (owner detail view).
/// Returned by `GET /family/:memberId/access`.
class FamilyMemberAccessDto {
  final String id;
  final String homeId;
  final String userId;
  final String role;
  final String? relation;
  final bool grantFutureAssets;
  final FamilyUserDto? user;
  final FamilyHomeDto? home;
  final List<AssetAccessEntry> assetAccess;
  final List<ServiceAccessEntry> serviceAccess;

  const FamilyMemberAccessDto({
    required this.id,
    required this.homeId,
    required this.userId,
    required this.role,
    this.relation,
    this.grantFutureAssets = false,
    this.user,
    this.home,
    this.assetAccess = const [],
    this.serviceAccess = const [],
  });

  factory FamilyMemberAccessDto.fromJson(Map<String, dynamic> json) {
    return FamilyMemberAccessDto(
      id: json['id'] as String,
      homeId: json['homeId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String? ?? 'member',
      relation: json['relation'] as String?,
      grantFutureAssets: json['grantFutureAssets'] as bool? ?? false,
      user: json['user'] != null
          ? FamilyUserDto.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      home: json['home'] != null
          ? FamilyHomeDto.fromJson(json['home'] as Map<String, dynamic>)
          : null,
      assetAccess:
          (json['assetAccess'] as List?)
              ?.map((a) => AssetAccessEntry.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      serviceAccess:
          (json['serviceAccess'] as List?)
              ?.map(
                (s) => ServiceAccessEntry.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  List<String> get grantedAssetIds =>
      assetAccess.map((a) => a.assetId).toList();

  List<String> get grantedServiceTypes =>
      serviceAccess.map((s) => s.serviceType).toList();
}

/// My own membership as returned by `GET /family/my-access` (member view).
class MyMembershipDto {
  final String id;
  final String homeId;
  final String role;
  final String? relation;
  final bool grantFutureAssets;
  final FamilyHomeDto? home;
  final List<AssetAccessEntry> assetAccess;
  final List<ServiceAccessEntry> serviceAccess;

  const MyMembershipDto({
    required this.id,
    required this.homeId,
    required this.role,
    this.relation,
    this.grantFutureAssets = false,
    this.home,
    this.assetAccess = const [],
    this.serviceAccess = const [],
  });

  factory MyMembershipDto.fromJson(Map<String, dynamic> json) {
    return MyMembershipDto(
      id: json['id'] as String,
      homeId: json['homeId'] as String,
      role: json['role'] as String? ?? 'member',
      relation: json['relation'] as String?,
      grantFutureAssets: json['grantFutureAssets'] as bool? ?? false,
      home: json['home'] != null
          ? FamilyHomeDto.fromJson(json['home'] as Map<String, dynamic>)
          : null,
      assetAccess:
          (json['assetAccess'] as List?)
              ?.map((a) => AssetAccessEntry.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      serviceAccess:
          (json['serviceAccess'] as List?)
              ?.map(
                (s) => ServiceAccessEntry.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }

  List<String> get grantedAssetIds =>
      assetAccess.map((a) => a.assetId).toList();

  List<String> get grantedServiceTypes =>
      serviceAccess.map((s) => s.serviceType).toList();
}

/// My pending invite as returned by `GET /family/my-invites`.
class MyInviteDto {
  final String id;
  final String email;
  final String homeId;
  final String token;
  final String role;
  final String? relation;
  final DateTime expiresAt;
  final FamilyHomeDto? home;
  final FamilyUserDto? invitedBy;

  const MyInviteDto({
    required this.id,
    required this.email,
    required this.homeId,
    required this.token,
    required this.role,
    this.relation,
    required this.expiresAt,
    this.home,
    this.invitedBy,
  });

  factory MyInviteDto.fromJson(Map<String, dynamic> json) {
    return MyInviteDto(
      id: json['id'] as String,
      email: json['email'] as String,
      homeId: json['homeId'] as String,
      token: json['token'] as String? ?? '',
      role: json['role'] as String? ?? 'member',
      relation: json['relation'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      home: json['home'] != null
          ? FamilyHomeDto.fromJson(json['home'] as Map<String, dynamic>)
          : null,
      invitedBy: json['invitedBy'] != null
          ? FamilyUserDto.fromJson(json['invitedBy'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isExpired => expiresAt.isBefore(DateTime.now());
}

/// Invite preview returned by `GET /family/validate-invite?token=`.
/// Allows showing invite details before accepting.
class InvitePreviewDto {
  final String id;
  final String homeId;
  final String role;
  final String? relation;
  final bool grantFutureAssets;
  final List<String> assetIds;
  final List<String> serviceTypes;
  final DateTime expiresAt;
  final DateTime createdAt;
  final FamilyHomeDto? home;
  final FamilyUserDto? invitedBy;
  final String status; // 'pending' | 'accepted' | 'expired'
  final bool emailMatch;

  const InvitePreviewDto({
    required this.id,
    required this.homeId,
    required this.role,
    this.relation,
    this.grantFutureAssets = false,
    this.assetIds = const [],
    this.serviceTypes = const [],
    required this.expiresAt,
    required this.createdAt,
    this.home,
    this.invitedBy,
    required this.status,
    required this.emailMatch,
  });

  factory InvitePreviewDto.fromJson(Map<String, dynamic> json) {
    return InvitePreviewDto(
      id: json['id'] as String,
      homeId: json['homeId'] as String,
      role: json['role'] as String? ?? 'member',
      relation: json['relation'] as String?,
      grantFutureAssets: json['grantFutureAssets'] as bool? ?? false,
      assetIds:
          (json['assetIds'] as List?)?.map((e) => e as String).toList() ?? [],
      serviceTypes:
          (json['serviceTypes'] as List?)?.map((e) => e as String).toList() ??
          [],
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      home: json['home'] != null
          ? FamilyHomeDto.fromJson(json['home'] as Map<String, dynamic>)
          : null,
      invitedBy: json['invitedBy'] != null
          ? FamilyUserDto.fromJson(json['invitedBy'] as Map<String, dynamic>)
          : null,
      status: json['status'] as String? ?? 'pending',
      emailMatch: json['emailMatch'] as bool? ?? false,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isExpired => status == 'expired';
}
// ─── Constants ──────────────────────────────────────────────────────────────

/// All valid service types matching the backend.
class FamilyServiceTypes {
  FamilyServiceTypes._();

  static const maintenance = 'maintenance';
  static const warranty = 'warranty';
  static const bookings = 'bookings';
  static const issues = 'issues';
  static const orders = 'orders';
  static const protectionPlans = 'protection_plans';

  static const all = [
    maintenance,
    warranty,
    bookings,
    issues,
    orders,
    protectionPlans,
  ];

  /// Human-readable labels for each service type.
  static String label(String type) {
    switch (type) {
      case maintenance:
        return 'Maintenance';
      case warranty:
        return 'Warranty';
      case bookings:
        return 'Bookings';
      case issues:
        return 'Issues';
      case orders:
        return 'Orders';
      case protectionPlans:
        return 'Protection Plans';
      default:
        return type;
    }
  }

  /// Icon for each service type.
  static String icon(String type) {
    switch (type) {
      case maintenance:
        return 'build';
      case warranty:
        return 'verified_user';
      case bookings:
        return 'calendar_today';
      case issues:
        return 'report_problem';
      case orders:
        return 'shopping_cart';
      case protectionPlans:
        return 'security';
      default:
        return 'help';
    }
  }
}
