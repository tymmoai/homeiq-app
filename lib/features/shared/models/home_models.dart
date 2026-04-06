import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

// ============================================================================
// Critical Alert Models
// ============================================================================

enum AlertSeverity { critical, warning, info }

enum AlertCategory { warranty, service, maintenance, safety }

class CriticalAlert {
  final String id;
  final String homeId;
  final String assetId;
  final String assetName;
  final String category;
  final String? location; // e.g. "Kitchen", "Living Room"
  final String issue;
  final AlertSeverity severity;
  final AlertCategory alertCategory;
  final IconData iconData;
  final DateTime? alertDate;
  final bool isExpired;
  final bool isOverdue;
  final String? actionLabel;
  final String? actionRoute;

  CriticalAlert({
    required this.id,
    required this.homeId,
    required this.assetId,
    required this.assetName,
    required this.category,
    this.location,
    required this.issue,
    required this.severity,
    required this.alertCategory,
    required this.iconData,
    this.alertDate,
    this.isExpired = false,
    this.isOverdue = false,
    this.actionLabel,
    this.actionRoute,
  });

  Color getSeverityColor() {
    // Icons use primary color on light background
    return AppColors.primary;
  }

  Color getSeverityBackgroundColor() {
    // Light primary background with colored icon for consistency
    return AppColors.primary.withValues(alpha: 0.1);
  }

  String getSeverityBadge() {
    if (isExpired) return 'EXPIRED';
    if (isOverdue) return 'OVERDUE';
    switch (severity) {
      case AlertSeverity.critical:
        return 'CRITICAL';
      case AlertSeverity.warning:
        return 'WARNING';
      case AlertSeverity.info:
        return 'INFO';
    }
  }
}

// ============================================================================
// Active Service (Booking) Models
// ============================================================================

enum ServiceStatus {
  scheduled,
  technicianAssigned,
  technicianOnWay,
  inProgress,
  completed,
  canceled,
  rescheduled,
}

enum PaymentStatus { pending, paid, failed, refunded }

enum PaymentMode { payNow, payOnVisit }

class ActiveService {
  final String id;
  final String bookingId; // Display ID (e.g., "HQ2026-1234")
  final String homeId;
  final String userId;
  final String assetId;
  final String assetName;
  final String assetLocation;

  // Issue Information
  final String issueSummary;
  final String? issueDescription;
  final String issueCategory;
  final String severity; // 'low', 'medium', 'high'

  // Technician Information
  final String technicianId;
  final String technicianName;
  final double technicianRating;
  final String? technicianPhoto;
  final int? technicianExperience;
  final int? technicianReviews;

  // Schedule
  final DateTime scheduledDate;
  final String scheduledTimeSlot;
  final DateTime? estimatedArrival;
  final DateTime? actualArrival;
  final DateTime? serviceStartTime;
  final DateTime? serviceEndTime;

  // Status
  final ServiceStatus status;
  final DateTime statusUpdatedAt;

  // Payment
  final PaymentMode paymentMode;
  final PaymentStatus paymentStatus;
  final double visitFee;
  final double? partsCost;
  final double? serviceCharge;
  final double? totalAmount;

  // Metadata
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed properties
  final bool isToday;
  final bool isUpcoming;

  ActiveService({
    required this.id,
    required this.bookingId,
    required this.homeId,
    required this.userId,
    required this.assetId,
    required this.assetName,
    required this.assetLocation,
    required this.issueSummary,
    this.issueDescription,
    required this.issueCategory,
    required this.severity,
    required this.technicianId,
    required this.technicianName,
    required this.technicianRating,
    this.technicianPhoto,
    this.technicianExperience,
    this.technicianReviews,
    required this.scheduledDate,
    required this.scheduledTimeSlot,
    this.estimatedArrival,
    this.actualArrival,
    this.serviceStartTime,
    this.serviceEndTime,
    required this.status,
    required this.statusUpdatedAt,
    required this.paymentMode,
    required this.paymentStatus,
    required this.visitFee,
    this.partsCost,
    this.serviceCharge,
    this.totalAmount,
    required this.createdAt,
    required this.updatedAt,
    this.isToday = false,
    this.isUpcoming = false,
  });

  Null get estimatedCost => null;

  String getStatusLabel() {
    switch (status) {
      case ServiceStatus.scheduled:
        return 'SCHEDULED';
      case ServiceStatus.technicianAssigned:
        return 'ASSIGNED';
      case ServiceStatus.technicianOnWay:
        return 'EN ROUTE';
      case ServiceStatus.inProgress:
        return 'IN PROGRESS';
      case ServiceStatus.completed:
        return 'COMPLETED';
      case ServiceStatus.canceled:
        return 'CANCELED';
      case ServiceStatus.rescheduled:
        return 'RESCHEDULED';
    }
  }

  /// Progress 0.0–1.0 for display (e.g. EN ROUTE = 50%).
  double getProgressPercent() {
    switch (status) {
      case ServiceStatus.scheduled:
        return 0.0;
      case ServiceStatus.technicianAssigned:
        return 0.25;
      case ServiceStatus.technicianOnWay:
        return 0.5;
      case ServiceStatus.inProgress:
        return 0.75;
      case ServiceStatus.completed:
        return 1.0;
      default:
        return 0.0;
    }
  }

  /// Time string for card (e.g. "9:00 AM").
  String getDisplayTime() {
    final dt = estimatedArrival ?? serviceStartTime ?? scheduledDate;
    final hour = dt.hour;
    final minute = dt.minute;
    final am = hour < 12;
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h:${minute.toString().padLeft(2, '0')} ${am ? 'AM' : 'PM'}';
  }

  Color getStatusColor() {
    switch (status) {
      case ServiceStatus.scheduled:
        return AppColors.textSecondary; // Gray text for outlined style
      case ServiceStatus.technicianAssigned:
        return AppColors.info; // Blue
      case ServiceStatus.technicianOnWay:
        return Colors.white; // White text on dark background
      case ServiceStatus.inProgress:
        return Colors.white; // White text on dark background
      case ServiceStatus.completed:
        return AppColors.success; // Green
      case ServiceStatus.canceled:
        return AppColors.error; // Red
      case ServiceStatus.rescheduled:
        return AppColors.info; // Blue
    }
  }

  Color getStatusBackgroundColor() {
    switch (status) {
      case ServiceStatus.scheduled:
        return Colors.transparent; // Outlined style
      case ServiceStatus.technicianAssigned:
        return AppColors.infoLight;
      case ServiceStatus.technicianOnWay:
        return AppColors.primary; // Dark navy
      case ServiceStatus.inProgress:
        return AppColors.primary; // Dark navy
      case ServiceStatus.completed:
        return AppColors.successLight;
      case ServiceStatus.canceled:
        return AppColors.errorLight;
      case ServiceStatus.rescheduled:
        return AppColors.infoLight;
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final schedDate = DateTime(
      scheduledDate.year,
      scheduledDate.month,
      scheduledDate.day,
    );

    if (schedDate == today) {
      return 'Today';
    } else if (schedDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final months = [
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
      return '${months[scheduledDate.month - 1]} ${scheduledDate.day}, ${scheduledDate.year}';
    }
  }
}

// ============================================================================
// Pending Delivery Models (extends Order models)
// ============================================================================

class PendingDelivery {
  final String id;
  final String homeId;
  final String orderId;
  final String productName;
  final String productImage;
  final double totalAmount;
  final String status;
  final String statusLabel;
  final Color statusColor;
  final Color statusBackgroundColor;
  final DateTime? estimatedDelivery;
  final String? trackingNumber;
  final bool isUrgent;
  // Maintenance parts delivery fields
  final bool isMaintenancePart;
  final String? maintenanceTaskName;
  final String? forAssetName;

  PendingDelivery({
    required this.id,
    required this.homeId,
    required this.orderId,
    required this.productName,
    required this.productImage,
    required this.totalAmount,
    required this.status,
    required this.statusLabel,
    required this.statusColor,
    required this.statusBackgroundColor,
    this.estimatedDelivery,
    this.trackingNumber,
    this.isUrgent = false,
    this.isMaintenancePart = false,
    this.maintenanceTaskName,
    this.forAssetName,
  });

  String getFormattedETA() {
    if (estimatedDelivery == null) return 'Processing';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final deliveryDate = DateTime(
      estimatedDelivery!.year,
      estimatedDelivery!.month,
      estimatedDelivery!.day,
    );

    if (deliveryDate == today) {
      return 'Today';
    } else if (deliveryDate == tomorrow) {
      return 'Tomorrow';
    } else {
      final months = [
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
      return '${months[estimatedDelivery!.month - 1]} ${estimatedDelivery!.day}';
    }
  }
}
