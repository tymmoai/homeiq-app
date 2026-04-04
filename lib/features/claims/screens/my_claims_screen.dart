import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../services/claims_service.dart';
import '../../../utils/responsive_utils.dart';
import '../models/claim_model.dart';

/// My Claims Screen
///
/// Shows all claims across all assets for the user.
/// Features:
/// - Summary stats bar (Active / Resolved / Denied)
/// - Tab-based filtering (All, Active, Resolved, Denied)
/// - Each claim card shows asset info, status badge, claim type, coverage
/// - Tap a claim to see full detail in a bottom sheet
class MyClaimsScreen extends StatefulWidget {
  const MyClaimsScreen({super.key});

  @override
  State<MyClaimsScreen> createState() => _MyClaimsScreenState();
}

class _MyClaimsScreenState extends State<MyClaimsScreen>
    with SingleTickerProviderStateMixin {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  late TabController _tabController;
  List<Claim> _allClaims = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadClaims();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload claims when screen becomes visible again
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    final claims = await ClaimsService.getAllClaims();
    // Filter out invalid test claims with generic names
    final validClaims = claims.where((claim) => 
      claim.assetName != 'Unknown Asset' && 
      claim.assetName.isNotEmpty
    ).toList();
    if (mounted) {
      setState(() {
        _allClaims = validClaims;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Claim> _getFilteredClaims(int tabIndex) {
    switch (tabIndex) {
      case 1:
        return _allClaims
            .where((c) => [
                  ClaimStatus.submitted,
                  ClaimStatus.underReview,
                  ClaimStatus.approved,
                  ClaimStatus.inProgress,
                ].contains(c.status))
            .toList();
      case 2:
        return _allClaims
            .where((c) => [ClaimStatus.resolved, ClaimStatus.closed].contains(c.status))
            .toList();
      case 3:
        return _allClaims.where((c) => c.status == ClaimStatus.denied).toList();
      default:
        return _allClaims;
    }
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.headerBackground,
        elevation: 2,
        systemOverlayStyle: AppColors.headerBackground.computeLuminance() > 0.5
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.headerForeground),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'My Claims',
          style: TextStyle(
            fontSize: responsive.fontSize(18),
            fontWeight: FontWeight.w700,
            color: AppColors.headerForeground,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: AppColors.headerBackground,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.headerForeground,
              indicatorWeight: 3,
              labelColor: AppColors.headerForeground,
              unselectedLabelColor: AppColors.headerForeground.withValues(alpha: 0.6),
              labelPadding: EdgeInsets.symmetric(horizontal: responsive.spacing(16)),
              labelStyle: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: TextStyle(
                fontSize: responsive.fontSize(14),
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: 'All'),
                Tab(text: 'Active'),
                Tab(text: 'Resolved'),
                Tab(text: 'Denied'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: List.generate(4, (tabIndex) {
          final claims = _getFilteredClaims(tabIndex);
          if (claims.isEmpty) {
            return _buildEmptyState(context, tabIndex);
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: claims.length,
            itemBuilder: (context, index) =>
                _buildClaimCard(context, claims[index]),
          );
        }),
      ),
    );
  }

  // ======================== EMPTY STATE ========================

  Widget _buildEmptyState(BuildContext context, int tabIndex) {
    final responsive = ResponsiveUtils(context);
    final messages = [
      'No claims found',
      'No active claims',
      'No resolved claims yet',
      'No denied claims',
    ];
    final subtitles = [
      'When you file a claim for any asset, it will appear here.',
      'All your active claims have been resolved.',
      'Resolved claims will appear here once completed.',
      'Great news! None of your claims have been denied.',
    ];
    return Center(
      child: Padding(
        padding: EdgeInsets.all(responsive.spacing(40)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: responsive.iconSize(64),
              color: AppColors.textHint,
            ),
            SizedBox(height: responsive.spacing(16)),
            Text(
              messages[tabIndex],
              style: AppTextStyles.h4,
            ),
            SizedBox(height: responsive.spacing(8)),
            Text(
              subtitles[tabIndex],
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMediumSecondary,
            ),
          ],
        ),
      ),
    );
  }

  // ======================== CLAIM CARD ========================

  Widget _buildClaimCard(BuildContext context, Claim claim) {
    final responsive = ResponsiveUtils(context);
    return GestureDetector(
      onTap: () => _showClaimDetail(claim),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
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
            // Card Header — Claim Number + Status Badge
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              decoration: BoxDecoration(
                color: AppColors.primary05,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    claim.getCategoryIcon(),
                    size: 20,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Text(
                    claim.claimNumber,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusBadge(context, claim),
                ],
              ),
            ),
            // Card Body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    claim.title,
                    style: AppTextStyles.h5,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: responsive.spacing(8)),
                  // Asset Info Row
                  Row(
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: responsive.iconSize(14),
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Flexible(
                        child: Text(
                          '${claim.assetBrand} ${claim.assetName}',
                          style: AppTextStyles.bodySmallSecondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Icon(
                        Icons.location_on_outlined,
                        size: responsive.iconSize(14),
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: responsive.spacing(2)),
                      Flexible(
                        child: Text(
                          claim.assetLocation,
                          style: AppTextStyles.bodySmallSecondary,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.spacing(10)),
                  // Meta Row — Type, Coverage, Date
                  Row(
                    children: [
                      // Claim Type Chip
                      _buildChip(context, 
                        claim.getClaimTypeIcon(),
                        claim.getClaimTypeLabel(),
                        AppColors.primary,
                        AppColors.primary05,
                      ),
                      SizedBox(width: responsive.spacing(8)),
                      // Coverage Chip
                      _buildChip(context, 
                        claim.isCovered
                            ? Icons.verified_outlined
                            : Icons.info_outline,
                        claim.isCovered ? 'Covered' : 'Not Covered',
                        claim.isCovered ? AppColors.primary : AppColors.textSecondary,
                        claim.isCovered
                            ? AppColors.primary05
                            : AppColors.surfaceVariant,
                      ),
                      const Spacer(),
                      // Date
                      Text(
                        claim.getTimeElapsed(),
                        style: AppTextStyles.bodySmallSecondary,
                      ),
                    ],
                  ),
                  // Progress Bar (for active claims only)
                  if (claim.status != ClaimStatus.resolved &&
                      claim.status != ClaimStatus.denied &&
                      claim.status != ClaimStatus.closed) ...[
                    SizedBox(height: responsive.spacing(12)),
                    _buildProgressBar(context, claim),
                  ],
                  // Linked Booking
                  if (claim.linkedBookingId != null) ...[
                    SizedBox(height: responsive.spacing(10)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary05,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.link,
                            size: responsive.iconSize(14),
                            color: AppColors.primary,
                          ),
                          SizedBox(width: responsive.spacing(4)),
                          Text(
                            'Booking: ${claim.linkedBookingId}',
                            style: AppTextStyles.captionBold.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, Claim claim) {
    final responsive = ResponsiveUtils(context);
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
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(10), vertical: responsive.spacing(4)),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
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

  Widget _buildChip(BuildContext context, IconData icon, String label, Color color, Color bgColor) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(4)),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: responsive.iconSize(13), color: color),
          SizedBox(width: responsive.spacing(4)),
          Text(
            label,
            style: TextStyle(
              fontSize: responsive.fontSize(12),
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, Claim claim) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Claim Progress',
              style: AppTextStyles.captionBold,
            ),
            Text(
              '${(claim.getProgress() * 100).toInt()}%',
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
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: claim.getProgress(),
            minHeight: 5,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }

  // ======================== CLAIM DETAIL BOTTOM SHEET ========================

  void _showClaimDetail(Claim claim) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ClaimDetailSheet(claim: claim),
    );
  }
}

// ============================================================================
// Claim Detail Bottom Sheet
// ============================================================================

class _ClaimDetailSheet extends StatelessWidget {
  final Claim claim;

  const _ClaimDetailSheet({required this.claim});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              _buildDetailHeader(context),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  children: [
                    _buildAssetSection(context),
                    SizedBox(height: responsive.spacing(16)),
                    _buildClaimOverview(context),
                    SizedBox(height: responsive.spacing(16)),
                    _buildCoverageSection(context),
                    if (claim.technicianName != null) ...[
                      SizedBox(height: responsive.spacing(16)),
                      _buildTechnicianSection(context),
                    ],
                    SizedBox(height: responsive.spacing(16)),
                    _buildTimelineSection(context),
                    if (claim.resolutionNotes != null) ...[
                      SizedBox(height: responsive.spacing(16)),
                      _buildResolutionSection(context),
                    ],
                    if (claim.estimatedCost != null) ...[
                      SizedBox(height: responsive.spacing(16)),
                      _buildCostSection(context),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- Detail Header ----
  Widget _buildDetailHeader(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.claimNumber,
                      style: AppTextStyles.bodySmallSecondary.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: responsive.spacing(4)),
                    Text(
                      claim.title,
                      style: AppTextStyles.h4,
                    ),
                  ],
                ),
              ),
              _buildDetailStatusBadge(context),
            ],
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Filed ${claim.formatDate(claim.submittedAt)}',
            style: AppTextStyles.bodySmallSecondary,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailStatusBadge(BuildContext context) {
    final responsive = ResponsiveUtils(context);
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
      padding: EdgeInsets.symmetric(horizontal: responsive.spacing(12), vertical: responsive.spacing(6)),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        claim.getStatusLabel(),
        style: TextStyle(
          fontSize: responsive.fontSize(12),
          fontWeight: FontWeight.w700,
          color: badgeColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ---- Asset Section ----
  Widget _buildAssetSection(BuildContext context) {
    return _buildSection(context, 
      'Asset Information',
      Icons.inventory_2_outlined,
      child: Column(
        children: [
          _buildDetailRow('Asset', '${claim.assetBrand} ${claim.assetName}'),
          _buildDetailRow('Type', claim.assetType),
          _buildDetailRow('Location', claim.assetLocation),
          if (claim.linkedBookingId != null)
            _buildDetailRow('Booking ID', claim.linkedBookingId!),
        ],
      ),
    );
  }

  // ---- Claim Overview ----
  Widget _buildClaimOverview(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return _buildSection(context, 
      'Claim Overview',
      Icons.description_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Category', claim.issueCategory),
          _buildDetailRow('Type', claim.getClaimTypeLabel()),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Description',
            style: AppTextStyles.captionBold,
          ),
          SizedBox(height: responsive.spacing(4)),
          Text(
            claim.description,
            style: AppTextStyles.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ---- Coverage Section ----
  Widget _buildCoverageSection(BuildContext context) {
    return _buildSection(context, 
      'Coverage Details',
      Icons.shield_outlined,
      child: Column(
        children: [
          _buildDetailRow('Warranty Status', claim.warrantyStatus),
          if (claim.planName != null)
            _buildDetailRow(AppStrings.protectionPlan, claim.planName!),
          _buildDetailRow(
            'Covered',
            claim.isCovered ? 'Yes — Fully Covered' : 'No — Out of Pocket',
          ),
          if (claim.deductible != null)
            _buildDetailRow(
              'Deductible',
              '\$${claim.deductible!.toStringAsFixed(2)}',
            ),
        ],
      ),
    );
  }

  // ---- Technician Section ----
  Widget _buildTechnicianSection(BuildContext context) {
    return _buildSection(context, 
      'Service Details',
      Icons.engineering_outlined,
      child: Column(
        children: [
          _buildDetailRow('Technician', claim.technicianName!),
          if (claim.linkedBookingId != null)
            _buildDetailRow('Booking', claim.linkedBookingId!),
        ],
      ),
    );
  }

  // ---- Timeline Section ----
  Widget _buildTimelineSection(BuildContext context) {
    return _buildSection(context, 
      'Claim Progress',
      Icons.timeline,
      child: Column(
        children: [
          _buildTimelineStep(context, 
            'Submitted',
            claim.formatDate(claim.submittedAt),
            true,
            isFirst: true,
          ),
          _buildTimelineStep(context, 
            'Under Review',
            claim.formatDate(claim.reviewedAt),
            claim.reviewedAt != null,
          ),
          _buildTimelineStep(context, 
            claim.status == ClaimStatus.denied ? 'Denied' : 'Approved',
            claim.status == ClaimStatus.denied
                ? claim.formatDate(claim.closedAt)
                : claim.formatDate(claim.approvedAt),
            claim.approvedAt != null || claim.status == ClaimStatus.denied,
            isError: claim.status == ClaimStatus.denied,
          ),
          _buildTimelineStep(context, 
            'In Progress',
            claim.formatDate(claim.inProgressAt),
            claim.inProgressAt != null,
          ),
          _buildTimelineStep(context, 
            'Resolved',
            claim.formatDate(claim.resolvedAt),
            claim.resolvedAt != null,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(BuildContext context, 
    String title,
    String date,
    bool isCompleted, {
    bool isFirst = false,
    bool isLast = false,
    bool isError = false,
  }) {
    final responsive = ResponsiveUtils(context);
    final color = isError
        ? AppColors.error
        : isCompleted
            ? AppColors.primary
            : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        SizedBox(
          width: 24,
          child: Column(
            children: [
              if (!isFirst)
                Container(
                  width: 2,
                  height: 12,
                  color: color,
                ),
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? color : Colors.white,
                  border: Border.all(color: color, width: 2),
                ),
                child: isCompleted
                    ? Icon(
                        isError ? Icons.close : Icons.check,
                        size: responsive.iconSize(8),
                        color: Colors.white,
                      )
                    : null,
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 12,
                  color: isCompleted ? color : AppColors.border,
                ),
            ],
          ),
        ),
        SizedBox(width: responsive.spacing(12)),
        // Text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: isCompleted
                      ? AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600)
                      : AppTextStyles.bodySmallSecondary,
                ),
                Text(
                  date,
                  style: isCompleted
                      ? AppTextStyles.bodySmallSecondary
                      : AppTextStyles.caption.copyWith(color: AppColors.textHint),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- Resolution Section ----
  Widget _buildResolutionSection(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isDenied = claim.status == ClaimStatus.denied;

    return _buildSection(context, 
      isDenied ? 'Denial Reason' : 'Resolution',
      isDenied ? Icons.cancel_outlined : Icons.check_circle_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (claim.resolutionType != null)
            _buildDetailRow(
              'Outcome',
              claim.resolutionType!.replaceAll('-', ' ').toUpperCase(),
            ),
          SizedBox(height: responsive.spacing(6)),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: isDenied
                  ? AppColors.errorLight
                  : AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              claim.resolutionNotes!,
              style: AppTextStyles.bodySmall.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Cost Section ----
  Widget _buildCostSection(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return _buildSection(context, 
      'Cost & Payment',
      Icons.attach_money,
      child: Column(
        children: [
          if (claim.estimatedCost != null)
            _buildDetailRow(
              'Estimated Cost',
              '\$${claim.estimatedCost!.toStringAsFixed(2)}',
            ),
          if (claim.approvedAmount != null)
            _buildDetailRow(
              'Approved Amount',
              '\$${claim.approvedAmount!.toStringAsFixed(2)}',
            ),
          if (claim.deductible != null)
            _buildDetailRow(
              'Your Deductible',
              '\$${claim.deductible!.toStringAsFixed(2)}',
            ),
          if (claim.isCovered)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: EdgeInsets.all(responsive.spacing(10)),
              decoration: BoxDecoration(
                color: AppColors.primary05,
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
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
                      style: AppTextStyles.captionBold.copyWith(
                        color: AppColors.primary,
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

  // ---- Shared Section Builder ----
  Widget _buildSection(BuildContext context, String title, IconData icon, {required Widget child}) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: responsive.iconSize(18), color: AppColors.primary),
            SizedBox(width: responsive.spacing(8)),
            Text(
              title,
              style: AppTextStyles.h5,
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(10)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(14)),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: child,
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: AppTextStyles.captionBold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}