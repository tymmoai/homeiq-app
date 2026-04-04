import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../shared/models/home_models.dart';

/// Horizontal scrolling list of active service / claim cards shown on the
/// Home tab.
class ActiveServicesSection extends StatelessWidget {
  /// All user bookings (already loaded from the service layer).
  final List<ActiveService> userBookings;

  /// Current search query to filter cards.
  final String homeSearchQuery;

  /// The currently selected home ID for filtering.
  final String? selectedHomeId;

  const ActiveServicesSection({
    super.key,
    required this.userBookings,
    required this.homeSearchQuery,
    this.selectedHomeId,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    // Use only real user bookings — no mock/hardcoded data.
    final filteredUserBookings = userBookings
        .where((b) => selectedHomeId == null || b.homeId == selectedHomeId)
        .toList();
    var services = [...filteredUserBookings];

    // Filter by search query
    if (homeSearchQuery.isNotEmpty) {
      services = services.where((service) {
        final assetName = service.assetName.toLowerCase();
        final issueSummary = service.issueSummary.toLowerCase();
        final statusLabel = service.getStatusLabel().toLowerCase();
        final technicianName = service.technicianName.toLowerCase();
        final assetLocation = service.assetLocation.toLowerCase();
        return assetName.contains(homeSearchQuery) ||
            issueSummary.contains(homeSearchQuery) ||
            statusLabel.contains(homeSearchQuery) ||
            technicianName.contains(homeSearchQuery) ||
            assetLocation.contains(homeSearchQuery);
      }).toList();
    }

    // Limit to 2 items for home tab display
    if (services.length > 2) {
      services = services.take(2).toList();
    }

    if (services.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: responsive.spacing(32)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: responsive.iconSize(48),
                color: AppColors.gray300,
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'No Active Claims',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                'Everything is running smoothly',
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Responsive card dimensions
    final cardWidth = responsive.isSmallMobile
        ? 240.0
        : responsive.isMediumMobile
        ? 260.0
        : 280.0;
    final cardHeight = responsive.isSmallMobile ? 110.0 : 120.0;

    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return Container(
            width: cardWidth,
            margin: EdgeInsets.only(
              right: index < services.length - 1 ? responsive.spacing(12) : 0,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: responsive.spacing(8),
                  offset: Offset(0, responsive.spacing(2)),
                ),
              ],
            ),
            child: ActiveServiceCard(service: service),
          );
        },
      ),
    );
  }
}

/// A single active-service / claim card, used inside [ActiveServicesSection].
class ActiveServiceCard extends StatelessWidget {
  /// The service data to display.
  final ActiveService service;

  const ActiveServiceCard({super.key, required this.service});

  // Helper method to get badge background color based on service status
  Color _getStatusBadgeColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return AppColors.infoLight;
      case ServiceStatus.inProgress:
        return AppColors.warningBackground;
      case ServiceStatus.completed:
        return AppColors.successBackground;
      case ServiceStatus.canceled:
        return AppColors.errorLight;
      default:
        return AppColors.borderLight;
    }
  }

  // Helper method to get badge text color based on service status
  Color _getStatusBadgeTextColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return AppColors.info;
      case ServiceStatus.inProgress:
        return AppColors.warning;
      case ServiceStatus.completed:
        return AppColors.success;
      case ServiceStatus.canceled:
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final displayTitle = '${service.assetName} ${service.issueCategory}';
    final progress = service.getProgressPercent();
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Navigate to specific booking detail screen
          context.push('/booking/${service.id}');
        },
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(14),
            vertical: responsive.spacing(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title - matching screenshot style
              Text(
                displayTitle,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              SizedBox(height: responsive.spacing(12)),

              // Progress bar with percentage - always shown
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(
                        responsive.borderRadius(4),
                      ),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.warning, // Orange/amber progress bar
                        ),
                        minHeight: responsive.spacing(6),
                      ),
                    ),
                  ),
                  SizedBox(width: responsive.spacing(10)),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(16)),

              // Status and time row - matching screenshot layout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status badge
                  Flexible(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.spacing(8),
                        vertical: responsive.spacing(4),
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusBadgeColor(service.status),
                        borderRadius: BorderRadius.circular(
                          AppDimensions.radiusBadge,
                        ),
                        border: service.status == ServiceStatus.scheduled
                            ? Border.all(color: AppColors.border)
                            : null,
                      ),
                      child: Text(
                        service.getStatusLabel(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(10),
                          fontWeight: FontWeight.w600,
                          color: _getStatusBadgeTextColor(service.status),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Time
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: responsive.iconSize(14),
                        color: AppColors.iconSecondary,
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Text(
                        service.getDisplayTime(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
