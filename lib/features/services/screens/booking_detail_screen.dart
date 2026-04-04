import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../services/claims_service.dart';
import '../../../utils/responsive_utils.dart';
import '../../claims/models/claim_model.dart';
import '../../shared/models/home_models.dart';
import '../services/booking_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final String bookingId;

  const BookingDetailScreen({super.key, required this.bookingId});

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  ActiveService? booking;
  Claim? linkedClaim;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  Future<void> _loadBooking() async {
    final userBooking = await BookingService.getBookingById(widget.bookingId);

    if (mounted) {
      setState(() {
        booking = userBooking;
        _isLoading = false;
      });
    }

    if (userBooking != null) {
      _loadLinkedClaim(userBooking.bookingId);
    }
  }

  Future<void> _loadLinkedClaim(String bookingId) async {
    // Find the claim linked to this booking from the backend claims
    final allClaims = await ClaimsService.getAllClaims();
    Claim? found;
    try {
      found = allClaims.firstWhere(
        (claim) => claim.linkedBookingId == bookingId,
      );
    } on Object catch (_) {
      found = null;
    }
    if (mounted) {
      setState(() {
        linkedClaim = found;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(responsive),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (booking == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(responsive),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(responsive.spacing(24)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: responsive.iconSize(64),
                  color: AppColors.gray400,
                ),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  'Claim not found',
                  style: TextStyle(
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(8)),
                Text(
                  'The claim you are looking for could not be found.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.gray600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(responsive),
      body: RefreshIndicator(
        onRefresh: _loadBooking,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.all(responsive.spacing(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero Section
                _buildHeroSection(responsive),
                SizedBox(height: responsive.spacing(12)),

                // Claim Info (synced from Claims data)
                if (linkedClaim != null) ...[
                  _buildClaimSyncCard(responsive),
                  SizedBox(height: responsive.spacing(12)),
                ],

                // Service Details Card
                _buildServiceDetailsCard(responsive),
                SizedBox(height: responsive.spacing(12)),

                // Schedule Card
                _buildScheduleCard(responsive),
                SizedBox(height: responsive.spacing(12)),

                // Technician Card
                _buildTechnicianCard(responsive),
                SizedBox(height: responsive.spacing(12)),

                // Payment Card
                _buildPaymentCard(responsive),
                SizedBox(height: responsive.spacing(12)),

                // Timeline/Progress
                _buildTimelineCard(responsive),
                SizedBox(height: responsive.spacing(20)),

                // Action Buttons
                _buildActionButtons(responsive),
                SizedBox(height: responsive.spacing(24)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ResponsiveUtils responsive) {
    return AppBar(
      backgroundColor: AppColors.headerBackground,
      elevation: 2,
      systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
          ? SystemUiOverlayStyle.dark
          : SystemUiOverlayStyle.light,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: AppColors.headerForeground,
          size: responsive.iconSize(24),
        ),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home');
          }
        },
      ),
      title: Text(
        'Claim Details',
        style: TextStyle(
          color: AppColors.headerForeground,
          fontSize: responsive.fontSize(18),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Hero Section — Status badge, title, location, issue summary
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildHeroSection(ResponsiveUtils responsive) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: responsive.spacing(8),
            offset: Offset(0, responsive.spacing(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + Booking ID row
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(12),
                    vertical: responsive.spacing(6),
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusBadgeBackgroundColor(booking!.status),
                    borderRadius: BorderRadius.circular(
                      AppDimensions.radiusBadge,
                    ),
                    border: booking!.status == ServiceStatus.scheduled
                        ? Border.all(color: AppColors.border)
                        : null,
                  ),
                  child: Text(
                    booking!.getStatusLabel(),
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w700,
                      color: _getStatusBadgeTextColor(booking!.status),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(8)),
              Flexible(
                child: Text(
                  booking!.bookingId,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textQuaternary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(14)),

          // Title
          Text(
            '${booking!.assetName} ${booking!.issueCategory}',
            style: TextStyle(
              fontSize: responsive.fontSize(20),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: responsive.spacing(6)),

          // Location
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: responsive.iconSize(16),
                color: AppColors.textLight,
              ),
              SizedBox(width: responsive.spacing(4)),
              Expanded(
                child: Text(
                  booking!.assetLocation,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    color: AppColors.textLight,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),

          // Issue summary box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  size: responsive.iconSize(20),
                  color: AppColors.warning,
                ),
                SizedBox(width: responsive.spacing(8)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking!.issueCategory,
                        style: TextStyle(
                          fontSize: responsive.fontSize(12),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textQuaternary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: responsive.spacing(2)),
                      Text(
                        booking!.issueSummary,
                        style: TextStyle(
                          fontSize: responsive.fontSize(14),
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Progress bar
          SizedBox(height: responsive.spacing(14)),
          _buildServiceProgressBar(responsive),
        ],
      ),
    );
  }

  Widget _buildServiceProgressBar(ResponsiveUtils responsive) {
    final progress = booking!.getProgressPercent();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Service Progress',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w600,
                color: AppColors.textQuaternary,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(6)),
        ClipRRect(
          borderRadius: BorderRadius.circular(responsive.borderRadius(4)),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: responsive.spacing(6),
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(
              progress >= 1.0 ? AppColors.success : AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Synced Claim Card — shows linked claim data from ClaimsDataService
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildClaimSyncCard(ResponsiveUtils responsive) {
    final claim = linkedClaim!;
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: responsive.spacing(8),
            offset: Offset(0, responsive.spacing(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(
                Icons.assignment_outlined,
                size: responsive.iconSize(20),
                color: AppColors.primary,
              ),
              SizedBox(width: responsive.spacing(8)),
              Expanded(
                child: Text(
                  'Linked Claim',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              // Claim status badge
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.spacing(10),
                  vertical: responsive.spacing(4),
                ),
                decoration: BoxDecoration(
                  color: claim.getStatusBackgroundColor(),
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                ),
                child: Text(
                  claim.getStatusLabel(),
                  style: TextStyle(
                    fontSize: responsive.fontSize(10),
                    fontWeight: FontWeight.w700,
                    color: claim.getStatusColor(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(12)),

          // Claim number + type
          _buildSyncDetailRow(
            responsive,
            'Claim #',
            claim.claimNumber,
            Icons.tag,
          ),
          _buildSyncDetailRow(
            responsive,
            'Type',
            claim.getClaimTypeLabel(),
            claim.getClaimTypeIcon(),
          ),
          _buildSyncDetailRow(
            responsive,
            'Category',
            claim.issueCategory,
            claim.getCategoryIcon(),
          ),
          _buildSyncDetailRow(
            responsive,
            'Asset',
            '${claim.assetBrand} ${claim.assetName}',
            Icons.inventory_2_outlined,
          ),

          // Coverage row
          SizedBox(height: responsive.spacing(8)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(10)),
            decoration: BoxDecoration(
              color: claim.isCovered
                  ? AppColors.successBackground
                  : AppColors.warningBackground,
              borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
            ),
            child: Row(
              children: [
                Icon(
                  claim.isCovered
                      ? Icons.verified_outlined
                      : Icons.info_outline,
                  size: responsive.iconSize(16),
                  color: claim.isCovered
                      ? AppColors.success
                      : AppColors.warning,
                ),
                SizedBox(width: responsive.spacing(8)),
                Expanded(
                  child: Text(
                    claim.isCovered
                        ? 'Covered under ${claim.warrantyStatus} warranty — No out-of-pocket cost'
                        : 'Warranty ${claim.warrantyStatus} — May require out-of-pocket payment',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: claim.isCovered
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Claim progress
          if (claim.status != ClaimStatus.resolved &&
              claim.status != ClaimStatus.denied &&
              claim.status != ClaimStatus.closed) ...[
            SizedBox(height: responsive.spacing(12)),
            _buildClaimProgressBar(responsive, claim),
          ],

          // Description
          SizedBox(height: responsive.spacing(12)),
          Text(
            claim.description,
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncDetailRow(
    ResponsiveUtils responsive,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.spacing(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: responsive.iconSize(14),
            color: AppColors.textSecondary,
          ),
          SizedBox(width: responsive.spacing(6)),
          SizedBox(
            width: responsive.spacing(70),
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClaimProgressBar(ResponsiveUtils responsive, Claim claim) {
    final progress = claim.getProgress();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Claim Progress',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w600,
                color: AppColors.textQuaternary,
              ),
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(4)),
        ClipRRect(
          borderRadius: BorderRadius.circular(responsive.borderRadius(4)),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: responsive.spacing(5),
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Service Details Card
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildServiceDetailsCard(ResponsiveUtils responsive) {
    return _buildCard(
      responsive,
      title: 'Service Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (booking!.issueDescription != null) ...[
            Text(
              'Issue Description',
              style: TextStyle(
                fontSize: responsive.fontSize(13),
                fontWeight: FontWeight.w600,
                color: AppColors.textQuaternary,
              ),
            ),
            SizedBox(height: responsive.spacing(6)),
            Text(
              booking!.issueDescription!,
              style: TextStyle(
                fontSize: responsive.fontSize(14),
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            SizedBox(height: responsive.spacing(16)),
          ],
          // Use LayoutBuilder + Wrap to avoid overflow on narrow screens
          LayoutBuilder(
            builder: (context, constraints) {
              final halfWidth =
                  (constraints.maxWidth - responsive.spacing(12)) / 2;
              return Wrap(
                spacing: responsive.spacing(12),
                runSpacing: responsive.spacing(12),
                children: [
                  SizedBox(
                    width: halfWidth,
                    child: _buildDetailItem(
                      responsive,
                      'Category',
                      booking!.issueCategory,
                      Icons.category,
                    ),
                  ),
                  SizedBox(
                    width: halfWidth,
                    child: _buildDetailItem(
                      responsive,
                      'Severity',
                      booking!.severity.toUpperCase(),
                      Icons.priority_high,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Schedule Card
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildScheduleCard(ResponsiveUtils responsive) {
    final dateStr = booking!.getFormattedDate();
    return _buildCard(
      responsive,
      title: 'Schedule',
      child: Row(
        children: [
          Container(
            width: responsive.spacing(48),
            height: responsive.spacing(48),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
            ),
            child: Icon(
              Icons.calendar_today,
              color: AppColors.info,
              size: responsive.iconSize(24),
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: responsive.spacing(2)),
                Text(
                  booking!.scheduledTimeSlot,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    color: AppColors.textQuaternary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (booking!.isToday)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.spacing(10),
                vertical: responsive.spacing(6),
              ),
              decoration: BoxDecoration(
                color: AppColors.successBackground,
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(12),
                ),
              ),
              child: Text(
                'TODAY',
                style: TextStyle(
                  fontSize: responsive.fontSize(11),
                  fontWeight: FontWeight.bold,
                  color: AppColors.success,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Technician Card
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTechnicianCard(ResponsiveUtils responsive) {
    return _buildCard(
      responsive,
      title: 'Technician',
      child: Row(
        children: [
          Container(
            width: responsive.spacing(50),
            height: responsive.spacing(50),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(responsive.spacing(25)),
            ),
            child: Icon(
              Icons.person,
              color: AppColors.info,
              size: responsive.iconSize(28),
            ),
          ),
          SizedBox(width: responsive.spacing(14)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking!.technicianName,
                  style: TextStyle(
                    fontSize: responsive.fontSize(15),
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: responsive.spacing(4)),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: responsive.spacing(4),
                  children: [
                    Icon(
                      Icons.star,
                      size: responsive.iconSize(14),
                      color: AppColors.amber,
                    ),
                    Text(
                      '${booking!.technicianRating}',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textQuaternary,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textQuaternary,
                      ),
                    ),
                    Text(
                      '${booking!.technicianExperience ?? 0}y exp',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textQuaternary,
                      ),
                    ),
                    Text(
                      '•',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textQuaternary,
                      ),
                    ),
                    Text(
                      '${booking!.technicianReviews ?? 0} reviews',
                      style: TextStyle(
                        fontSize: responsive.fontSize(12),
                        color: AppColors.textQuaternary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.spacing(8)),
          // Call button
          Container(
            width: responsive.spacing(40),
            height: responsive.spacing(40),
            decoration: BoxDecoration(
              color: AppColors.success,
              borderRadius: BorderRadius.circular(responsive.spacing(20)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.phone,
                color: AppColors.white,
                size: responsive.iconSize(18),
              ),
              onPressed: _callTechnician,
              padding: EdgeInsets.zero,
              tooltip: 'Call Technician',
            ),
          ),
          SizedBox(width: responsive.spacing(8)),
          // Message button
          Container(
            width: responsive.spacing(40),
            height: responsive.spacing(40),
            decoration: BoxDecoration(
              color: AppColors.info,
              borderRadius: BorderRadius.circular(responsive.spacing(20)),
            ),
            child: IconButton(
              icon: Icon(
                Icons.message_outlined,
                color: AppColors.white,
                size: responsive.iconSize(18),
              ),
              onPressed: _messageTechnician,
              padding: EdgeInsets.zero,
              tooltip: 'Message Technician',
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Payment Card
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildPaymentCard(ResponsiveUtils responsive) {
    return _buildCard(
      responsive,
      title: 'Payment',
      child: Column(
        children: [
          _buildPaymentRow(
            responsive,
            'Visit Fee',
            '\$${booking!.visitFee.toStringAsFixed(2)}',
          ),
          SizedBox(height: responsive.spacing(10)),
          _buildPaymentRow(
            responsive,
            'Payment Mode',
            null,
            badge: booking!.paymentMode == PaymentMode.payOnVisit
                ? 'Pay on Visit'
                : 'Pay Now',
            badgeColor: AppColors.textPrimary,
            badgeBg: AppColors.borderLight,
          ),
          SizedBox(height: responsive.spacing(10)),
          _buildPaymentRow(
            responsive,
            'Payment Status',
            null,
            badge: booking!.paymentStatus == PaymentStatus.paid
                ? 'Paid'
                : 'Outstanding',
            badgeColor: booking!.paymentStatus == PaymentStatus.paid
                ? AppColors.success
                : AppColors.warning,
            badgeBg: booking!.paymentStatus == PaymentStatus.paid
                ? AppColors.successBackground
                : AppColors.warningBackground,
          ),
          // Show costs from linked claim if available
          if (linkedClaim != null && linkedClaim!.estimatedCost != null) ...[
            SizedBox(height: responsive.spacing(10)),
            Divider(color: AppColors.border, height: responsive.spacing(1)),
            SizedBox(height: responsive.spacing(10)),
            _buildPaymentRow(
              responsive,
              'Estimated Repair Cost',
              '\$${linkedClaim!.estimatedCost!.toStringAsFixed(2)}',
            ),
            if (linkedClaim!.approvedAmount != null) ...[
              SizedBox(height: responsive.spacing(8)),
              _buildPaymentRow(
                responsive,
                'Approved Amount',
                '\$${linkedClaim!.approvedAmount!.toStringAsFixed(2)}',
              ),
            ],
            if (linkedClaim!.deductible != null) ...[
              SizedBox(height: responsive.spacing(8)),
              _buildPaymentRow(
                responsive,
                'Your Deductible',
                '\$${linkedClaim!.deductible!.toStringAsFixed(2)}',
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    ResponsiveUtils responsive,
    String label,
    String? value, {
    String? badge,
    Color? badgeColor,
    Color? badgeBg,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textQuaternary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(width: responsive.spacing(8)),
        if (value != null)
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(15),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          )
        else if (badge != null)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.spacing(10),
              vertical: responsive.spacing(4),
            ),
            decoration: BoxDecoration(
              color: badgeBg ?? AppColors.borderLight,
              borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
            ),
            child: Text(
              badge,
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w600,
                color: badgeColor ?? AppColors.textPrimary,
              ),
            ),
          ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Timeline / Service Progress Card
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildTimelineCard(ResponsiveUtils responsive) {
    final steps = _getTimelineSteps();

    return _buildCard(
      responsive,
      title: 'Service Progress',
      child: Column(
        children: steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;

          return _buildTimelineStep(
            responsive,
            step['label'] as String,
            step['description'] as String,
            step['completed'] as bool,
            step['active'] as bool? ?? false,
            isLast,
            step['time'] as String?,
          );
        }).toList(),
      ),
    );
  }

  List<Map<String, dynamic>> _getTimelineSteps() {
    // Build timeline from booking status and linked claim timestamps
    final hasLinkedClaim = linkedClaim != null;

    return [
      {
        'label': 'Claim Submitted',
        'description': hasLinkedClaim
            ? 'Claim ${linkedClaim!.claimNumber} filed'
            : 'Service request submitted',
        'completed': true,
        'active': false,
        'time': hasLinkedClaim
            ? linkedClaim!.formatDate(linkedClaim!.submittedAt)
            : null,
      },
      {
        'label': 'Under Review',
        'description': hasLinkedClaim && linkedClaim!.reviewedAt != null
            ? 'Reviewed and assessed'
            : 'Awaiting review',
        'completed': hasLinkedClaim ? linkedClaim!.reviewedAt != null : true,
        'active':
            hasLinkedClaim && linkedClaim!.status == ClaimStatus.underReview,
        'time': hasLinkedClaim
            ? linkedClaim!.formatDate(linkedClaim!.reviewedAt)
            : null,
      },
      {
        'label': 'Approved',
        'description': hasLinkedClaim && linkedClaim!.approvedAt != null
            ? 'Claim approved for service'
            : 'Pending approval',
        'completed': hasLinkedClaim
            ? linkedClaim!.approvedAt != null
            : booking!.status != ServiceStatus.scheduled,
        'active': hasLinkedClaim && linkedClaim!.status == ClaimStatus.approved,
        'time': hasLinkedClaim
            ? linkedClaim!.formatDate(linkedClaim!.approvedAt)
            : null,
      },
      {
        'label': 'Technician Assigned',
        'description': '${booking!.technicianName} assigned',
        'completed': booking!.status != ServiceStatus.scheduled,
        'active': booking!.status == ServiceStatus.technicianAssigned,
        'time': null,
      },
      {
        'label': 'On the Way',
        'description': 'Technician en route to your location',
        'completed': [
          ServiceStatus.technicianOnWay,
          ServiceStatus.inProgress,
          ServiceStatus.completed,
        ].contains(booking!.status),
        'active': booking!.status == ServiceStatus.technicianOnWay,
        'time': null,
      },
      {
        'label': 'Service In Progress',
        'description': 'Working on your ${booking!.assetName}',
        'completed': [
          ServiceStatus.inProgress,
          ServiceStatus.completed,
        ].contains(booking!.status),
        'active': booking!.status == ServiceStatus.inProgress,
        'time': null,
      },
      {
        'label': 'Completed',
        'description': hasLinkedClaim && linkedClaim!.resolutionNotes != null
            ? linkedClaim!.resolutionNotes!
            : 'Service finished',
        'completed': booking!.status == ServiceStatus.completed,
        'active': false,
        'time': hasLinkedClaim
            ? linkedClaim!.formatDate(linkedClaim!.resolvedAt)
            : null,
      },
    ];
  }

  Widget _buildTimelineStep(
    ResponsiveUtils responsive,
    String label,
    String description,
    bool completed,
    bool active,
    bool isLast,
    String? time,
  ) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator column
          SizedBox(
            width: responsive.spacing(32),
            child: Column(
              children: [
                Container(
                  width: responsive.spacing(28),
                  height: responsive.spacing(28),
                  decoration: BoxDecoration(
                    color: completed
                        ? AppColors.primary
                        : active
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.background,
                    borderRadius: BorderRadius.circular(responsive.spacing(14)),
                    border: Border.all(
                      color: completed || active
                          ? AppColors.primary
                          : AppColors.border,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: completed
                        ? Icon(
                            Icons.check,
                            color: AppColors.white,
                            size: responsive.iconSize(16),
                          )
                        : active
                        ? Container(
                            width: responsive.spacing(8),
                            height: responsive.spacing(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          )
                        : null,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      constraints: BoxConstraints(
                        minHeight: responsive.spacing(30),
                      ),
                      color: completed ? AppColors.primary : AppColors.border,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          // Text content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: isLast ? 0 : responsive.spacing(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            fontWeight: completed || active
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: completed || active
                                ? AppColors.textPrimary
                                : AppColors.textLight,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (time != null && time != '—') ...[
                        SizedBox(width: responsive.spacing(8)),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: responsive.spacing(2)),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: completed || active
                          ? AppColors.textQuaternary
                          : AppColors.textLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Action Buttons
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildActionButtons(ResponsiveUtils responsive) {
    final isScheduled =
        booking!.status == ServiceStatus.scheduled ||
        booking!.status == ServiceStatus.rescheduled;
    final isActive =
        booking!.status == ServiceStatus.technicianAssigned ||
        booking!.status == ServiceStatus.technicianOnWay ||
        booking!.status == ServiceStatus.inProgress;

    return Column(
      children: [
        // View Claims button — always available
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/my-claims'),
            icon: Icon(
              Icons.assignment_outlined,
              size: responsive.iconSize(20),
            ),
            label: Text(
              'View All Claims',
              style: TextStyle(
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
              side: BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  responsive.borderRadius(10),
                ),
              ),
            ),
          ),
        ),

        // Reschedule + Cancel for scheduled bookings
        if (isScheduled) ...[
          SizedBox(height: responsive.spacing(12)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showRescheduleDialog(),
              icon: Icon(Icons.calendar_month, size: responsive.iconSize(20)),
              label: Text(
                'Reschedule',
                style: TextStyle(
                  fontSize: responsive.fontSize(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(10),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.spacing(10)),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showCancelDialog(),
              icon: Icon(Icons.cancel_outlined, size: responsive.iconSize(20)),
              label: Text(
                'Cancel Booking',
                style: TextStyle(
                  fontSize: responsive.fontSize(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(10),
                  ),
                ),
              ),
            ),
          ),
        ],

        // Contact support for active services
        if (isActive) ...[
          SizedBox(height: responsive.spacing(12)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _callTechnician,
              icon: Icon(Icons.phone, size: responsive.iconSize(20)),
              label: Text(
                'Contact Technician',
                style: TextStyle(
                  fontSize: responsive.fontSize(15),
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: AppColors.textOnPrimary,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    responsive.borderRadius(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared Card Builder
  // ══════════════════════════════════════════════════════════════════════════

  Widget _buildCard(
    ResponsiveUtils responsive, {
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowDark,
            blurRadius: responsive.spacing(8),
            offset: Offset(0, responsive.spacing(2)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: responsive.fontSize(17),
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(14)),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailItem(
    ResponsiveUtils responsive,
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(responsive.spacing(12)),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(responsive.borderRadius(8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: responsive.iconSize(18),
            color: AppColors.textQuaternary,
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(11),
              fontWeight: FontWeight.w600,
              color: AppColors.textQuaternary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: responsive.spacing(2)),
          Text(
            value,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dialogs & Actions
  // ══════════════════════════════════════════════════════════════════════════

  void _callTechnician() async {
    final uri = Uri(scheme: 'tel', path: '+18779272683');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to make phone call'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _messageTechnician() async {
    final uri = Uri(scheme: 'sms', path: '+18779272683');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open messaging'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Cancel Booking',
          style: TextStyle(fontSize: responsive.fontSize(18)),
        ),
        content: Text(
          'Are you sure you want to cancel this booking? This action cannot be undone.',
          style: TextStyle(fontSize: responsive.fontSize(14)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Keep Booking',
              style: TextStyle(fontSize: responsive.fontSize(14)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              final success = await BookingService.cancelBooking(
                booking!.bookingId,
              );

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Booking canceled successfully'),
                    backgroundColor: AppColors.success,
                  ),
                );
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/home');
                }
              } else if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Failed to cancel booking'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(
              'Cancel Booking',
              style: TextStyle(
                color: AppColors.white,
                fontSize: responsive.fontSize(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRescheduleDialog() {
    DateTime selectedDate = booking!.scheduledDate;
    String selectedTime = booking!.scheduledTimeSlot;
    final timeSlots = [
      '9 AM - 12 PM',
      '12 PM - 3 PM',
      '3 PM - 6 PM',
      '6 PM - 9 PM',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            'Reschedule Booking',
            style: TextStyle(fontSize: responsive.fontSize(18)),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select new date:',
                  style: TextStyle(fontSize: responsive.fontSize(14)),
                ),
                SizedBox(height: responsive.spacing(8)),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 60)),
                      );
                      if (picked != null) {
                        setDialogState(() => selectedDate = picked);
                      }
                    },
                    icon: Icon(
                      Icons.calendar_today,
                      size: responsive.iconSize(18),
                    ),
                    label: Text(
                      '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                      style: TextStyle(fontSize: responsive.fontSize(14)),
                    ),
                  ),
                ),
                SizedBox(height: responsive.spacing(16)),
                Text(
                  'Select time slot:',
                  style: TextStyle(fontSize: responsive.fontSize(14)),
                ),
                SizedBox(height: responsive.spacing(8)),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButton<String>(
                    value: timeSlots.contains(selectedTime)
                        ? selectedTime
                        : timeSlots.first,
                    isExpanded: true,
                    items: timeSlots
                        .map(
                          (slot) => DropdownMenuItem(
                            value: slot,
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() => selectedTime = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(fontSize: responsive.fontSize(14)),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                final success = await BookingService.rescheduleBooking(
                  booking!.bookingId,
                  selectedDate,
                  selectedTime,
                );

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Booking rescheduled successfully'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                  _loadBooking(); // Reload booking data
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reschedule booking'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              },
              child: Text(
                'Confirm',
                style: TextStyle(fontSize: responsive.fontSize(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Status Color Helpers
  // ══════════════════════════════════════════════════════════════════════════

  Color _getStatusBadgeBackgroundColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return AppColors.infoLight;
      case ServiceStatus.technicianAssigned:
        return AppColors.infoLight;
      case ServiceStatus.technicianOnWay:
        return AppColors.primary;
      case ServiceStatus.inProgress:
        return AppColors.warningBackground;
      case ServiceStatus.completed:
        return AppColors.successBackground;
      case ServiceStatus.canceled:
        return AppColors.errorLight;
      case ServiceStatus.rescheduled:
        return AppColors.infoLight;
    }
  }

  Color _getStatusBadgeTextColor(ServiceStatus status) {
    switch (status) {
      case ServiceStatus.scheduled:
        return AppColors.info;
      case ServiceStatus.technicianAssigned:
        return AppColors.info;
      case ServiceStatus.technicianOnWay:
        return AppColors.white;
      case ServiceStatus.inProgress:
        return AppColors.warning;
      case ServiceStatus.completed:
        return AppColors.success;
      case ServiceStatus.canceled:
        return AppColors.error;
      case ServiceStatus.rescheduled:
        return AppColors.info;
    }
  }
}