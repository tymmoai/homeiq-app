import '../models/claim_model.dart';

/// Claims Data Service
///
/// Provides mock claim data that is **fully synced** with existing app data:
/// - Asset IDs match _allAssets in home_screen.dart
/// - Booking IDs match ActiveService data in home_data_service.dart
/// - Technician names match those in home_data_service.dart
/// - Warranty statuses match asset warranty fields
/// - Issue categories match those used across the app
class ClaimsDataService {
  /// Get all claims for the user across all assets and homes.
  ///
  /// The mock data here reflects real scenarios:
  /// 1. Asset #2 (AC Unit/Living Room) — active claim linked to booking HQ2026-1234
  /// 2. Asset #1 (Samsung Refrigerator) — active claim linked to booking HQ2026-1235
  /// 3. Asset #3 (Microwave Oven) — in-progress claim linked to booking HQ2026-1236
  /// 4. Asset #4 (LG AC Living Room) — resolved past claim (covered under warranty)
  /// 5. Asset #1 (Samsung Refrigerator) — old resolved claim (ice build-up fix)
  /// 6. Asset #4 (LG AC Living Room) — resolved past claim (covered under warranty)
  static List<Claim> getAllClaims() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return [
      // ----------------------------------------------------------------
      // CLAIM 1: AC Bedroom not cooling — linked to ActiveService booking HQ2026-1234
      // Asset #7 in home_screen (AC Bedroom, Bedroom) — warranty ACTIVE
      // This is the "EN ROUTE" booking — technician John Mitchell is on the way
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-1',
        claimNumber: 'CLM-2026-0001',
        assetId: '7',
        assetName: 'AC Bedroom',
        assetBrand: 'LG',
        assetLocation: 'Bedroom',
        assetType: 'Air Conditioner',
        title: 'Not cooling properly',
        description:
            'AC is making loud noise and not cooling. Temperature not dropping below 82°F.',
        issueCategory: 'Cooling Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.inProgress,
        warrantyStatus: 'Active',
        planName: null,
        isCovered: true,
        linkedBookingId: 'HQ2026-1234',
        technicianName: 'John Mitchell',
        estimatedCost: 150.0,
        approvedAmount: 150.0,
        deductible: 0.0,
        submittedAt: today.subtract(const Duration(days: 3)),
        reviewedAt: today.subtract(const Duration(days: 2)),
        approvedAt: today.subtract(const Duration(days: 2)),
        inProgressAt: today.subtract(const Duration(days: 1)),
      ),

      // ----------------------------------------------------------------
      // CLAIM 2: Refrigerator water leaking — linked to ActiveService HQ2026-1235
      // Asset #1 (Samsung Refrigerator, Kitchen) — warranty EXPIRED
      // This is the "SCHEDULED" booking with Michael Anderson
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-2',
        claimNumber: 'CLM-2026-0002',
        assetId: '1',
        assetName: 'Refrigerator',
        assetBrand: 'Samsung',
        assetLocation: 'Kitchen',
        assetType: 'Refrigerator',
        title: 'Water leaking from bottom',
        description:
            'Water is leaking from the bottom of the refrigerator. Puddle forms on kitchen floor overnight.',
        issueCategory: 'Leakage Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.approved,
        warrantyStatus: 'Expired',
        planName: null,
        isCovered: false,
        linkedBookingId: 'HQ2026-1235',
        technicianName: 'Michael Anderson',
        estimatedCost: 120.0,
        approvedAmount: null,
        deductible: null,
        submittedAt: today.subtract(const Duration(days: 4)),
        reviewedAt: today.subtract(const Duration(days: 2)),
        approvedAt: today.subtract(const Duration(days: 1)),
      ),

      // ----------------------------------------------------------------
      // CLAIM 3: Microwave not heating — linked to ActiveService HQ2026-1236
      // Asset #3 (Whirlpool Microwave, Kitchen) — warranty EXPIRED
      // This is the "IN PROGRESS" booking with Robert Johnson
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-3',
        claimNumber: 'CLM-2026-0003',
        assetId: '3',
        assetName: 'Microwave Oven',
        assetBrand: 'Whirlpool',
        assetLocation: 'Kitchen',
        assetType: 'Microwave',
        title: 'Not heating food properly',
        description:
            'Microwave is running but not heating food. Turntable still spins normally.',
        issueCategory: 'Heating Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.inProgress,
        warrantyStatus: 'Expired',
        planName: null,
        isCovered: false,
        linkedBookingId: 'HQ2026-1236',
        technicianName: 'Robert Johnson',
        estimatedCost: 85.0,
        approvedAmount: null,
        deductible: null,
        submittedAt: today.subtract(const Duration(days: 5)),
        reviewedAt: today.subtract(const Duration(days: 3)),
        approvedAt: today.subtract(const Duration(days: 2)),
        inProgressAt: today,
      ),

      // ----------------------------------------------------------------
      // CLAIM 4: LG AC — RESOLVED repair claim (past issue)
      // Asset #4 (LG AC Living Room) — warranty active, covered under warranty
      // This matches the "pastRepairs: 3" on that asset
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-4',
        claimNumber: 'CLM-2025-0018',
        assetId: '4',
        assetName: 'AC Living',
        assetBrand: 'LG',
        assetLocation: 'Living Room',
        assetType: 'Air Conditioner',
        title: 'Compressor making loud noise',
        description:
            'AC compressor was making grinding noise. Unit would shut off after 10 minutes of running.',
        issueCategory: 'Noise Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.resolved,
        warrantyStatus: 'Active',
        planName: null,
        isCovered: true,
        linkedBookingId: null,
        technicianName: 'David Chen',
        estimatedCost: 320.0,
        approvedAmount: 320.0,
        deductible: 0.0,
        submittedAt: DateTime(2025, 9, 10),
        reviewedAt: DateTime(2025, 9, 11),
        approvedAt: DateTime(2025, 9, 12),
        inProgressAt: DateTime(2025, 9, 14),
        resolvedAt: DateTime(2025, 9, 16),
        resolutionNotes:
            'Compressor bearings replaced. Refrigerant recharged. System tested for 2 hours — operating normally. Fully covered under manufacturer warranty.',
        resolutionType: 'repaired',
      ),

      // ----------------------------------------------------------------
      // CLAIM 5: Refrigerator ice build-up — RESOLVED (old issue)
      // Asset #1 (Samsung Refrigerator) — this matches the sample issue
      // in issues_tab_widget.dart: "Fixed ice build-up in freezer"
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-5',
        claimNumber: 'CLM-2023-0042',
        assetId: '1',
        assetName: 'Refrigerator',
        assetBrand: 'Samsung',
        assetLocation: 'Kitchen',
        assetType: 'Refrigerator',
        title: 'Fixed ice build-up in freezer',
        description:
            'Ice was accumulating in the freezer compartment causing the door not to close properly.',
        issueCategory: 'Cooling Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.resolved,
        warrantyStatus: 'Active',
        planName: null,
        isCovered: true,
        linkedBookingId: null,
        technicianName: 'John Smith - Samsung Certified',
        estimatedCost: 85.0,
        approvedAmount: 85.0,
        deductible: 0.0,
        submittedAt: DateTime(2023, 11, 15),
        reviewedAt: DateTime(2023, 11, 16),
        approvedAt: DateTime(2023, 11, 16),
        inProgressAt: DateTime(2023, 11, 18),
        resolvedAt: DateTime(2023, 11, 18),
        resolutionNotes:
            'Defrosted the unit and cleaned the drain tube. Replaced the defrost thermostat. Tested for 24 hours — no recurrence.',
        resolutionType: 'repaired',
      ),

      // ----------------------------------------------------------------
      // CLAIM 6: LG AC — RESOLVED claim (warranty active, covered)
      // Asset #4 (LG AC Living Room) — warranty active until Mar 2029
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-6',
        claimNumber: 'CLM-2025-0005',
        assetId: '4',
        assetName: 'AC Living',
        assetBrand: 'LG',
        assetLocation: 'Living Room',
        assetType: 'Air Conditioner',
        title: 'Refrigerant leak suspected',
        description:
            'AC not cooling effectively. Suspected refrigerant leak. Unit blows warm air after 5 minutes.',
        issueCategory: 'Cooling Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.resolved,
        warrantyStatus: 'Active',
        planName: null,
        isCovered: true,
        linkedBookingId: null,
        technicianName: 'David Chen',
        estimatedCost: 450.0,
        approvedAmount: 450.0,
        deductible: 0.0,
        submittedAt: DateTime(2025, 6, 1),
        reviewedAt: DateTime(2025, 6, 3),
        approvedAt: DateTime(2025, 6, 4),
        inProgressAt: DateTime(2025, 6, 6),
        resolvedAt: DateTime(2025, 6, 8),
        resolutionNotes:
            'Refrigerant leak located and sealed. System recharged and tested for 4 hours — cooling normally. Fully covered under manufacturer warranty (valid until Mar 2029).',
        resolutionType: 'repaired',
      ),

      // ----------------------------------------------------------------
      // CLAIM 7: AC Bedroom — SUBMITTED (new claim, just filed)
      // Asset #7 (LG AC Bedroom) — warranty ACTIVE until Jun 2027
      // ----------------------------------------------------------------
      Claim(
        id: 'claim-7',
        claimNumber: 'CLM-2026-0004',
        assetId: '7',
        assetName: 'AC Bedroom',
        assetBrand: 'LG',
        assetLocation: 'Bedroom',
        assetType: 'Air Conditioner',
        title: 'Unusual rattling sound during operation',
        description:
            'AC started making a rattling sound when switching between cooling modes. No temperature issues yet but concerning noise.',
        issueCategory: 'Noise Issue',
        claimType: ClaimType.repair,
        status: ClaimStatus.submitted,
        warrantyStatus: 'Active',
        planName: null,
        isCovered: true,
        linkedBookingId: null,
        technicianName: null,
        estimatedCost: null,
        approvedAmount: null,
        deductible: null,
        submittedAt: today,
      ),
    ];
  }

  /// Get claims filtered by status category
  static List<Claim> getActiveClaims() {
    return getAllClaims()
        .where(
          (c) =>
              c.status == ClaimStatus.submitted ||
              c.status == ClaimStatus.underReview ||
              c.status == ClaimStatus.approved ||
              c.status == ClaimStatus.inProgress,
        )
        .toList();
  }

  static List<Claim> getResolvedClaims() {
    return getAllClaims()
        .where(
          (c) =>
              c.status == ClaimStatus.resolved ||
              c.status == ClaimStatus.closed,
        )
        .toList();
  }

  static List<Claim> getDeniedClaims() {
    return getAllClaims().where((c) => c.status == ClaimStatus.denied).toList();
  }

  /// Get claims for a specific asset
  static List<Claim> getClaimsForAsset(String assetId) {
    return getAllClaims().where((c) => c.assetId == assetId).toList();
  }

  /// Get summary counts
  static Map<String, int> getClaimsSummary() {
    final all = getAllClaims();
    return {
      'total': all.length,
      'active': all
          .where(
            (c) =>
                c.status != ClaimStatus.resolved &&
                c.status != ClaimStatus.denied &&
                c.status != ClaimStatus.closed,
          )
          .length,
      'resolved': all.where((c) => c.status == ClaimStatus.resolved).length,
      'denied': all.where((c) => c.status == ClaimStatus.denied).length,
      'covered': all.where((c) => c.isCovered).length,
    };
  }
}
