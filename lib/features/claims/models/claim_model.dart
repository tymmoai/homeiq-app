import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ============================================================================
// Claim Status - tracks the lifecycle of a claim
// ============================================================================

enum ClaimStatus {
  submitted,    // User submitted the claim
  underReview,  // Team is reviewing the claim
  approved,     // Claim approved
  inProgress,   // Repair/replacement in progress
  resolved,     // Claim completed successfully
  denied,       // Claim was denied
  closed,       // Claim closed (after resolution or denial)
}

// ============================================================================
// Claim Type - what kind of claim it is
// ============================================================================

enum ClaimType {
  repair,       // Something needs fixing
  replacement,  // Full replacement under warranty
  maintenance,  // Covered maintenance
}

// ============================================================================
// Claim Model - represents a warranty/service claim on an asset
// ============================================================================

/// A Claim represents a formal request by the user to get an issue resolved
/// under warranty or protection plan coverage. Claims are linked to:
/// - An asset (the product with the problem)
/// - Optionally a service booking (ActiveService)
/// - A warranty/protection plan (if covered)
///
/// In this app, "claims" are essentially issues that have been formally filed
/// for resolution — they track the full lifecycle from submission to resolution.
class Claim {
  final String id;
  final String claimNumber;  // Display ID e.g. "CLM-2026-0001"

  // Asset linkage (synced with _allAssets in home_screen.dart)
  final String assetId;
  final String assetName;
  final String assetBrand;
  final String assetLocation;
  final String assetType;

  // Claim details
  final String title;
  final String description;
  final String issueCategory;    // e.g. 'Cooling Issue', 'Leakage Issue'
  final ClaimType claimType;
  final ClaimStatus status;

  // Coverage info
  final String warrantyStatus;   // 'Active', 'Expired', 'Protection Plan'
  final String? planName;        // e.g. 'BrandsMart Essential', null if manufacturer warranty
  final bool isCovered;

  // Service linkage (synced with ActiveService bookings)
  final String? linkedBookingId; // Links to ActiveService.bookingId
  final String? technicianName;

  // Financial
  final double? estimatedCost;
  final double? approvedAmount;
  final double? deductible;

  // Timeline
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final DateTime? approvedAt;
  final DateTime? inProgressAt;
  final DateTime? resolvedAt;
  final DateTime? closedAt;

  // Resolution
  final String? resolutionNotes;
  final String? resolutionType;  // 'repaired', 'replaced', 'denied', 'pending-parts'

  Claim({
    required this.id,
    required this.claimNumber,
    required this.assetId,
    required this.assetName,
    required this.assetBrand,
    required this.assetLocation,
    required this.assetType,
    required this.title,
    required this.description,
    required this.issueCategory,
    required this.claimType,
    required this.status,
    required this.warrantyStatus,
    this.planName,
    required this.isCovered,
    this.linkedBookingId,
    this.technicianName,
    this.estimatedCost,
    this.approvedAmount,
    this.deductible,
    required this.submittedAt,
    this.reviewedAt,
    this.approvedAt,
    this.inProgressAt,
    this.resolvedAt,
    this.closedAt,
    this.resolutionNotes,
    this.resolutionType,
  });

  // ---- Computed properties ----

  String getStatusLabel() {
    switch (status) {
      case ClaimStatus.submitted:
        return 'SUBMITTED';
      case ClaimStatus.underReview:
        return 'UNDER REVIEW';
      case ClaimStatus.approved:
        return 'APPROVED';
      case ClaimStatus.inProgress:
        return 'IN PROGRESS';
      case ClaimStatus.resolved:
        return 'RESOLVED';
      case ClaimStatus.denied:
        return 'DENIED';
      case ClaimStatus.closed:
        return 'CLOSED';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case ClaimStatus.submitted:
        return AppColors.info;
      case ClaimStatus.underReview:
        return AppColors.warning;
      case ClaimStatus.approved:
        return AppColors.success;
      case ClaimStatus.inProgress:
        return AppColors.primary;
      case ClaimStatus.resolved:
        return AppColors.success;
      case ClaimStatus.denied:
        return AppColors.error;
      case ClaimStatus.closed:
        return AppColors.textSecondary;
    }
  }

  Color getStatusBackgroundColor() {
    switch (status) {
      case ClaimStatus.submitted:
        return AppColors.infoLight;
      case ClaimStatus.underReview:
        return AppColors.warningBackground;
      case ClaimStatus.approved:
        return AppColors.successLight;
      case ClaimStatus.inProgress:
        return AppColors.primary10;
      case ClaimStatus.resolved:
        return AppColors.successBackground;
      case ClaimStatus.denied:
        return AppColors.errorLight;
      case ClaimStatus.closed:
        return AppColors.backgroundGray100;
    }
  }

  IconData getClaimTypeIcon() {
    switch (claimType) {
      case ClaimType.repair:
        return Icons.build;
      case ClaimType.replacement:
        return Icons.swap_horiz;
      case ClaimType.maintenance:
        return Icons.home_repair_service;
    }
  }

  String getClaimTypeLabel() {
    switch (claimType) {
      case ClaimType.repair:
        return 'Repair';
      case ClaimType.replacement:
        return 'Replacement';
      case ClaimType.maintenance:
        return 'Maintenance';
    }
  }

  IconData getCategoryIcon() {
    switch (issueCategory) {
      case 'Cooling Issue':
        return Icons.ac_unit;
      case 'Leakage Issue':
        return Icons.water_drop;
      case 'Heating Issue':
        return Icons.whatshot;
      case 'Electrical Issue':
        return Icons.electrical_services;
      case 'Noise Issue':
        return Icons.volume_up;
      case 'Mechanical Issue':
        return Icons.settings;
      case 'Performance Issue':
        return Icons.speed;
      case 'Maintenance':
        return Icons.home_repair_service;
      default:
        return Icons.report_problem;
    }
  }

  /// Progress value 0.0–1.0 for the claim lifecycle
  double getProgress() {
    switch (status) {
      case ClaimStatus.submitted:
        return 0.15;
      case ClaimStatus.underReview:
        return 0.30;
      case ClaimStatus.approved:
        return 0.50;
      case ClaimStatus.inProgress:
        return 0.75;
      case ClaimStatus.resolved:
        return 1.0;
      case ClaimStatus.denied:
        return 1.0;
      case ClaimStatus.closed:
        return 1.0;
    }
  }

  /// Formatted date string
  String formatDate(DateTime? date) {
    if (date == null) return '—';
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Time elapsed since submitted
  String getTimeElapsed() {
    final diff = DateTime.now().difference(submittedAt);
    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} months ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} days ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hours ago';
    } else {
      return 'Just now';
    }
  }

  /// Serialize to JSON for SharedPreferences storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'claimNumber': claimNumber,
      'assetId': assetId,
      'assetName': assetName,
      'assetBrand': assetBrand,
      'assetLocation': assetLocation,
      'assetType': assetType,
      'title': title,
      'description': description,
      'issueCategory': issueCategory,
      'claimType': claimType.index,
      'status': status.index,
      'warrantyStatus': warrantyStatus,
      'planName': planName,
      'isCovered': isCovered,
      'linkedBookingId': linkedBookingId,
      'technicianName': technicianName,
      'estimatedCost': estimatedCost,
      'approvedAmount': approvedAmount,
      'deductible': deductible,
      'submittedAt': submittedAt.toIso8601String(),
      'reviewedAt': reviewedAt?.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'inProgressAt': inProgressAt?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'resolutionNotes': resolutionNotes,
      'resolutionType': resolutionType,
    };
  }

  /// Deserialize from JSON
  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'] ?? '',
      claimNumber: json['claimNumber'] ?? '',
      assetId: json['assetId'] ?? '',
      assetName: json['assetName'] ?? '',
      assetBrand: json['assetBrand'] ?? '',
      assetLocation: json['assetLocation'] ?? '',
      assetType: json['assetType'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      issueCategory: json['issueCategory'] ?? '',
      claimType: ClaimType.values[json['claimType'] ?? 0],
      status: ClaimStatus.values[json['status'] ?? 0],
      warrantyStatus: json['warrantyStatus'] ?? '',
      planName: json['planName'],
      isCovered: json['isCovered'] ?? false,
      linkedBookingId: json['linkedBookingId'],
      technicianName: json['technicianName'],
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      approvedAmount: (json['approvedAmount'] as num?)?.toDouble(),
      deductible: (json['deductible'] as num?)?.toDouble(),
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
      reviewedAt: json['reviewedAt'] != null ? DateTime.parse(json['reviewedAt']) : null,
      approvedAt: json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      inProgressAt: json['inProgressAt'] != null ? DateTime.parse(json['inProgressAt']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      resolutionNotes: json['resolutionNotes'],
      resolutionType: json['resolutionType'],
    );
  }
}
