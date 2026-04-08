import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../utils/responsive_utils.dart';
import '../models/claim_model.dart';

/// Full-screen Claim Detail Screen
///
/// Displays all information about a single claim in a dedicated page,
/// matching the style of OrderDetailScreen. Sections include:
/// - Status + progress banner
/// - Asset information
/// - Claim overview (category, type, description)
/// - Coverage details (warranty, plan, deductible)
/// - Service details (technician — if assigned)
/// - Claim timeline
/// - Resolution (if resolved/denied)
/// - Cost & payment (if cost data present)
class ClaimDetailScreen extends StatelessWidget {
  final Claim claim;

  const ClaimDetailScreen({super.key, required this.claim});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, responsive),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.wp(4)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusCard(context, responsive),
                    SizedBox(height: responsive.hp(2)),
                    _buildAssetCard(context, responsive),
                    SizedBox(height: responsive.hp(2)),
                    _buildClaimOverviewCard(context, responsive),
                    SizedBox(height: responsive.hp(2)),
                    _buildCoverageCard(context, responsive),
                    if (claim.technicianName != null) ...[
                      SizedBox(height: responsive.hp(2)),
                      _buildServiceCard(context, responsive),
                    ],
                    SizedBox(height: responsive.hp(2)),
                    _buildTimelineCard(context, responsive),
                    if (claim.resolutionNotes != null) ...[
                      SizedBox(height: responsive.hp(2)),
                      _buildResolutionCard(context, responsive),
                    ],
                    if (claim.estimatedCost != null) ...[
                      SizedBox(height: responsive.hp(2)),
                      _buildCostCard(context, responsive),
                    ],
                    SizedBox(height: responsive.hp(4)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // HEADER
  // =========================================================================

  Widget _buildHeader(BuildContext context, ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.wp(4),
        responsive.hp(1),
        responsive.wp(4),
        responsive.hp(2),
      ),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: Icon(
              Icons.arrow_back_ios_new,
              color: AppColors.headerForeground,
              size: 22,
            ),
          ),
          SizedBox(width: responsive.wp(4)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Claim Details',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w700,
                    color: AppColors.headerForeground,
                  ),
                ),
                Text(
                  claim.claimNumber,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w400,
                    color: AppColors.headerForeground.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          _buildStatusBadge(responsive),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(ResponsiveUtils responsive) {
    final Color badgeColor;
    final Color badgeBg;
    switch (claim.status) {
      case ClaimStatus.resolved:
      case ClaimStatus.closed:
        badgeColor = AppColors.success;
        badgeBg = AppColors.successLight;
        break;
      case ClaimStatus.denied:
        badgeColor = AppColors.error;
        badgeBg = AppColors.errorLight;
        break;
      default:
        badgeColor = AppColors.primary;
        badgeBg = AppColors.primary10;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(12),
        vertical: responsive.spacing(5),
      ),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
      ),
      child: Text(
        claim.getStatusLabel(),
        style: TextStyle(
          fontSize: responsive.fontSize(11),
          fontWeight: FontWeight.w700,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // =========================================================================
  // STATUS CARD
  // =========================================================================

  Widget _buildStatusCard(BuildContext context, ResponsiveUtils responsive) {
    final statusColor = claim.getStatusColor();
    final statusBg = claim.getStatusBackgroundColor();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status icon + label + description
          Row(
            children: [
              Container(
                width: responsive.wp(12),
                height: responsive.wp(12),
                decoration: BoxDecoration(
                  color: statusBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  claim.getCategoryIcon(),
                  color: statusColor,
                  size: responsive.wp(6),
                ),
              ),
              SizedBox(width: responsive.wp(3)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(15),
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: responsive.hp(0.4)),
                    Text(
                      'Filed ${claim.formatDate(claim.submittedAt)}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Progress bar (for non-terminal statuses)
          if (claim.status != ClaimStatus.resolved &&
              claim.status != ClaimStatus.denied &&
              claim.status != ClaimStatus.closed) ...[
            SizedBox(height: responsive.hp(2)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Claim Progress',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  '${(claim.getProgress() * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.hp(0.5)),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: claim.getProgress(),
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            ),
          ],
          // Resolved/denied banner
          if (claim.status == ClaimStatus.resolved ||
              claim.status == ClaimStatus.closed) ...[
            SizedBox(height: responsive.hp(2)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(10)),
              decoration: BoxDecoration(
                color: AppColors.successLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: responsive.iconSize(16),
                    color: AppColors.success,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Text(
                    'This claim has been successfully resolved.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (claim.status == ClaimStatus.denied) ...[
            SizedBox(height: responsive.hp(2)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(10)),
              decoration: BoxDecoration(
                color: AppColors.errorLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel,
                    size: responsive.iconSize(16),
                    color: AppColors.error,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Text(
                    'This claim was denied.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      fontWeight: FontWeight.w500,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // ASSET CARD
  // =========================================================================

  Widget _buildAssetCard(BuildContext context, ResponsiveUtils responsive) {
    return _buildSectionCard(
      context,
      responsive,
      title: 'Asset Information',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          _buildDetailRow(
            responsive,
            'Asset',
            '${claim.assetBrand} ${claim.assetName}',
          ),
          _buildDetailRow(responsive, 'Type', claim.assetType),
          _buildDetailRow(responsive, 'Location', claim.assetLocation),
          if (claim.linkedBookingId != null)
            _buildDetailRow(
              responsive,
              'Booking ID',
              claim.linkedBookingId!,
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // CLAIM OVERVIEW CARD
  // =========================================================================

  Widget _buildClaimOverviewCard(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    return _buildSectionCard(
      context,
      responsive,
      title: 'Claim Overview',
      icon: Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(responsive, 'Category', claim.issueCategory),
          _buildDetailRow(responsive, 'Type', claim.getClaimTypeLabel()),
          // Claim type chip row
          Padding(
            padding: EdgeInsets.only(bottom: responsive.hp(1.5)),
            child: Row(
              children: [
                SizedBox(width: responsive.wp(25)),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(8),
                    vertical: responsive.spacing(3),
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary05,
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        claim.getClaimTypeIcon(),
                        size: responsive.iconSize(12),
                        color: AppColors.primary,
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Text(
                        claim.getClaimTypeLabel(),
                        style: TextStyle(
                          fontSize: responsive.fontSize(11),
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Description
          SizedBox(height: responsive.spacing(4)),
          Text(
            'Description',
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacing(6)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              claim.description,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // COVERAGE CARD
  // =========================================================================

  Widget _buildCoverageCard(BuildContext context, ResponsiveUtils responsive) {
    return _buildSectionCard(
      context,
      responsive,
      title: 'Coverage Details',
      icon: Icons.shield_outlined,
      child: Column(
        children: [
          _buildDetailRow(responsive, 'Warranty', claim.warrantyStatus),
          if (claim.planName != null)
            _buildDetailRow(
              responsive,
              AppStrings.protectionPlan,
              claim.planName!,
            ),
          _buildDetailRow(
            responsive,
            'Coverage',
            claim.isCovered ? 'Yes — Fully Covered' : 'No — Out of Pocket',
          ),
          if (claim.deductible != null)
            _buildDetailRow(
              responsive,
              'Deductible',
              '\$${claim.deductible!.toStringAsFixed(2)}',
            ),
          // Coverage badge
          SizedBox(height: responsive.spacing(4)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(10)),
            decoration: BoxDecoration(
              color: claim.isCovered
                  ? AppColors.primary05
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: claim.isCovered
                    ? AppColors.primary.withValues(alpha: 0.2)
                    : AppColors.border,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  claim.isCovered
                      ? Icons.verified_outlined
                      : Icons.info_outline,
                  size: responsive.iconSize(16),
                  color: claim.isCovered
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                SizedBox(width: responsive.spacing(8)),
                Expanded(
                  child: Text(
                    claim.isCovered
                        ? 'This claim is covered under your protection plan.'
                        : 'This claim is not covered. Out-of-pocket costs may apply.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w500,
                      color: claim.isCovered
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SERVICE / TECHNICIAN CARD
  // =========================================================================

  Widget _buildServiceCard(BuildContext context, ResponsiveUtils responsive) {
    return _buildSectionCard(
      context,
      responsive,
      title: 'Service Details',
      icon: Icons.engineering_outlined,
      child: Column(
        children: [
          _buildDetailRow(responsive, 'Technician', claim.technicianName!),
          if (claim.linkedBookingId != null)
            _buildDetailRow(responsive, 'Booking', claim.linkedBookingId!),
        ],
      ),
    );
  }

  // =========================================================================
  // TIMELINE CARD
  // =========================================================================

  Widget _buildTimelineCard(BuildContext context, ResponsiveUtils responsive) {
    return _buildSectionCard(
      context,
      responsive,
      title: 'Claim Timeline',
      icon: Icons.timeline,
      child: Column(
        children: [
          _buildTimelineItem(
            responsive,
            'Submitted',
            claim.formatDate(claim.submittedAt),
            true,
            icon: Icons.send_outlined,
            isFirst: true,
          ),
          _buildTimelineItem(
            responsive,
            'Under Review',
            claim.reviewedAt != null
                ? claim.formatDate(claim.reviewedAt)
                : 'Pending',
            claim.reviewedAt != null,
            icon: Icons.manage_search_outlined,
          ),
          _buildTimelineItem(
            responsive,
            claim.status == ClaimStatus.denied ? 'Denied' : 'Approved',
            claim.status == ClaimStatus.denied
                ? claim.formatDate(claim.closedAt)
                : claim.formatDate(claim.approvedAt),
            claim.approvedAt != null || claim.status == ClaimStatus.denied,
            icon: claim.status == ClaimStatus.denied
                ? Icons.cancel_outlined
                : Icons.thumb_up_outlined,
            isError: claim.status == ClaimStatus.denied,
          ),
          _buildTimelineItem(
            responsive,
            'In Progress',
            claim.inProgressAt != null
                ? claim.formatDate(claim.inProgressAt)
                : 'Pending',
            claim.inProgressAt != null,
            icon: Icons.build_outlined,
          ),
          _buildTimelineItem(
            responsive,
            'Resolved',
            claim.resolvedAt != null
                ? claim.formatDate(claim.resolvedAt)
                : 'Pending',
            claim.resolvedAt != null,
            icon: Icons.check_circle_outline,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    ResponsiveUtils responsive,
    String title,
    String dateLabel,
    bool isCompleted, {
    IconData icon = Icons.circle_outlined,
    bool isFirst = false,
    bool isLast = false,
    bool isError = false,
  }) {
    final Color lineColor = isError
        ? AppColors.error
        : isCompleted
        ? AppColors.primary
        : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline track
        SizedBox(
          width: 28,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 14,
                  color: isCompleted ? AppColors.primary : AppColors.border,
                ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? lineColor : Colors.white,
                  border: Border.all(color: lineColor, width: 2),
                ),
                child: Icon(
                  isCompleted ? icon : Icons.circle_outlined,
                  size: 14,
                  color: isCompleted ? Colors.white : lineColor,
                ),
              ),
              if (!isLast)
                Container(width: 2, height: 14, color: lineColor),
            ],
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        // Text content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: isLast ? 0 : responsive.spacing(4),
              top: 6,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight:
                        isCompleted ? FontWeight.w600 : FontWeight.w400,
                    color: isCompleted
                        ? isError
                            ? AppColors.error
                            : AppColors.textPrimary
                        : AppColors.textHint,
                  ),
                ),
                Text(
                  dateLabel,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: isCompleted
                        ? AppColors.textSecondary
                        : AppColors.textHint,
                    fontWeight:
                        isCompleted ? FontWeight.w500 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // RESOLUTION CARD
  // =========================================================================

  Widget _buildResolutionCard(
    BuildContext context,
    ResponsiveUtils responsive,
  ) {
    final isDenied = claim.status == ClaimStatus.denied;
    return _buildSectionCard(
      context,
      responsive,
      title: isDenied ? 'Denial Reason' : 'Resolution',
      icon: isDenied ? Icons.cancel_outlined : Icons.check_circle_outline,
      accentColor: isDenied ? AppColors.error : AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (claim.resolutionType != null) ...[
            _buildDetailRow(
              responsive,
              'Outcome',
              _formatResolutionType(claim.resolutionType!),
            ),
            SizedBox(height: responsive.spacing(6)),
          ],
          Text(
            isDenied ? 'Reason' : 'Notes',
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: responsive.spacing(6)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: isDenied ? AppColors.errorLight : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDenied
                    ? AppColors.error.withValues(alpha: 0.2)
                    : AppColors.border,
              ),
            ),
            child: Text(
              claim.resolutionNotes!,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // COST CARD
  // =========================================================================

  Widget _buildCostCard(BuildContext context, ResponsiveUtils responsive) {
    return _buildSectionCard(
      context,
      responsive,
      title: 'Cost & Payment',
      icon: Icons.payments_outlined,
      child: Column(
        children: [
          if (claim.estimatedCost != null)
            _buildPriceRow(
              responsive,
              'Estimated Cost',
              '\$${claim.estimatedCost!.toStringAsFixed(2)}',
            ),
          if (claim.approvedAmount != null)
            _buildPriceRow(
              responsive,
              'Approved Amount',
              '\$${claim.approvedAmount!.toStringAsFixed(2)}',
            ),
          if (claim.deductible != null)
            _buildPriceRow(
              responsive,
              'Your Deductible',
              '\$${claim.deductible!.toStringAsFixed(2)}',
            ),
          // Divider before total if enough rows
          if (claim.estimatedCost != null || claim.approvedAmount != null) ...[
            SizedBox(height: responsive.hp(0.5)),
            Container(height: 1, color: AppColors.border),
            SizedBox(height: responsive.hp(0.5)),
          ],
          // Coverage notice
          if (claim.isCovered) ...[
            SizedBox(height: responsive.spacing(4)),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(responsive.spacing(10)),
              decoration: BoxDecoration(
                color: AppColors.primary05,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified,
                    size: responsive.iconSize(16),
                    color: AppColors.primary,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Expanded(
                    child: Text(
                      'This claim is covered under warranty. No out-of-pocket cost.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // =========================================================================
  // SHARED HELPERS
  // =========================================================================

  /// Reusable white card with a titled section header.
  Widget _buildSectionCard(
    BuildContext context,
    ResponsiveUtils responsive, {
    required String title,
    required IconData icon,
    required Widget child,
    Color? accentColor,
  }) {
    final color = accentColor ?? AppColors.primary;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.wp(4)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: responsive.wp(8),
                height: responsive.wp(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: responsive.wp(4), color: color),
              ),
              SizedBox(width: responsive.spacing(10)),
              Text(
                title,
                style: TextStyle(
                  fontSize: responsive.fontSize(15),
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.hp(2)),
          child,
        ],
      ),
    );
  }

  /// Two-column label + value row.
  Widget _buildDetailRow(
    ResponsiveUtils responsive,
    String label,
    String value,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.hp(1.2)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: responsive.wp(28),
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Label + right-aligned value row for cost section.
  Widget _buildPriceRow(
    ResponsiveUtils responsive,
    String label,
    String value, {
    bool isTotal = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.hp(0.8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(isTotal ? 14 : 13),
              color:
                  isTotal ? AppColors.textPrimary : AppColors.textSecondary,
              fontWeight: isTotal ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(isTotal ? 14 : 13),
              color: AppColors.textPrimary,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatResolutionType(String type) {
    return type
        .split('-')
        .map(
          (word) => word.isNotEmpty
              ? word[0].toUpperCase() + word.substring(1)
              : word,
        )
        .join(' ');
  }
}
