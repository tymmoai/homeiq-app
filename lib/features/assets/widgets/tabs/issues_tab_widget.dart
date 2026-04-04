import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../services/asset_api_service.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../../maintenance/screens/issue_detail_screen.dart';

class IssuesTabWidget extends StatelessWidget {
  final Map<String, dynamic> asset;
  final ScrollController scrollController;

  /// Real issues loaded from the backend. When provided, sample data is NOT used.
  final List<Map<String, dynamic>> issues;

  /// Whether the issues are currently being loaded.
  final bool isLoading;

  /// Called after a new issue is successfully reported so the parent can
  /// refresh the list.
  final VoidCallback? onIssueCreated;

  const IssuesTabWidget({
    super.key,
    required this.asset,
    required this.scrollController,
    this.issues = const [],
    this.isLoading = false,
    this.onIssueCreated,
  });

  // ── Helpers ────────────────────────────────────────────────────────────────

  /// Normalize a backend issue status string to a human-readable label.
  static String _statusLabel(String? raw) {
    switch (raw) {
      case 'open':        return 'Open';
      case 'in_progress': return 'In Progress';
      case 'resolved':    return 'Resolved';
      case 'closed':      return 'Closed';
      default:            return raw ?? 'Open';
    }
  }

  /// Format an ISO date string to "MMM D, YYYY".
  static String _formatDate(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final assetParts = asset['partsBought'] as List<dynamic>? ?? [];

    final List<Map<String, dynamic>> partsBought = assetParts.isNotEmpty
        ? assetParts.map((e) => e as Map<String, dynamic>).toList()
        : [];

    return Container(
      color: AppColors.backgroundGray50,
      child: SingleChildScrollView(
        controller: scrollController,
        padding: EdgeInsets.all(responsive.spacing(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row: "Issue History" + "Report Issue" button ──────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(context, 'Issue History'),
                TextButton.icon(
                  onPressed: () => _showReportIssueSheet(context),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Report Issue'),
                  style: TextButton.styleFrom(
                    foregroundColor: AssetDetailColors.primaryDark,
                    textStyle: TextStyle(
                      fontSize: responsive.fontSize(13),
                      fontWeight: FontWeight.w600,
                    ),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(16)),

            // ── Issues list ─────────────────────────────────────────────────
            if (isLoading)
              Container(
                padding: EdgeInsets.all(responsive.spacing(32)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (issues.isNotEmpty)
              Container(
                padding: EdgeInsets.all(responsive.spacing(20)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: issues.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final issue = entry.value;
                    final statusLabel = _statusLabel(issue['status']?.toString());
                    final dateStr = _formatDate(issue['createdAt']?.toString());
                    return Column(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => IssueDetailScreen(
                                  issue: {
                                    ...issue,
                                    'status': statusLabel,
                                    'date': dateStr,
                                  },
                                  asset: asset,
                                ),
                              ),
                            );
                          },
                          child: _buildIssueDetailItem(context,
                            issue['title'] ?? '',
                            statusLabel,
                            issue['description'] ?? '',
                            dateStr,
                          ),
                        ),
                        if (idx < issues.length - 1) const Divider(height: 24),
                      ],
                    );
                  }).toList(),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(responsive.spacing(32)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.check_circle_outline, size: responsive.iconSize(48), color: AppColors.gray300),
                      SizedBox(height: responsive.spacing(16)),
                      Text(
                        'No issues reported for this asset',
                        style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.gray500),
                      ),
                      SizedBox(height: responsive.spacing(8)),
                      TextButton(
                        onPressed: () => _showReportIssueSheet(context),
                        child: Text(
                          'Report your first issue',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: AssetDetailColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            SizedBox(height: responsive.spacing(24)),
            _buildSectionHeader(context, 'Parts Bought'),
            SizedBox(height: responsive.spacing(16)),
            if (partsBought.isNotEmpty)
              Container(
                padding: EdgeInsets.all(responsive.spacing(20)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  children: partsBought.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final part = entry.value;
                    return Column(
                      children: [
                        _buildPartItem(context, part['name'] ?? '', part['date'] ?? '', part['price'] ?? '', orderId: part['orderId']?.toString()),
                        if (idx < partsBought.length - 1) const Divider(height: 16),
                      ],
                    );
                  }).toList(),
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(responsive.spacing(32)),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.shopping_cart_outlined, size: responsive.iconSize(48), color: AppColors.gray300),
                      SizedBox(height: responsive.spacing(16)),
                      Text('No parts purchased for this asset', style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.gray500)),
                    ],
                  ),
                ),
              ),
            SizedBox(height: responsive.spacing(20)),
          ],
        ),
      ),
    );
  }

  // ── Report Issue bottom sheet ───────────────────────────────────────────────

  void _showReportIssueSheet(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String severity = 'medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Report an Issue',
                          style: TextStyle(fontSize: responsive.fontSize(18), fontWeight: FontWeight.bold, color: AssetDetailColors.textPrimary)),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close), padding: EdgeInsets.zero, constraints: const BoxConstraints()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleCtrl,
                    decoration: InputDecoration(
                      labelText: 'Issue title *',
                      hintText: 'e.g. Making loud noise',
                      filled: true,
                      fillColor: AppColors.backgroundGray50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (optional)',
                      hintText: 'Describe the problem...',
                      filled: true,
                      fillColor: AppColors.backgroundGray50,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text('Severity', style: TextStyle(fontSize: responsive.fontSize(13), fontWeight: FontWeight.w600, color: AssetDetailColors.textPrimary)),
                  const SizedBox(height: 8),
                  Row(
                    children: ['low', 'medium', 'high', 'critical'].map((s) {
                      final isSelected = severity == s;
                      final color = s == 'low' ? Colors.green : s == 'medium' ? Colors.orange : s == 'high' ? Colors.deepOrange : Colors.red;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setSheet(() => severity = s),
                          child: Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? color.withValues(alpha: 0.15) : AppColors.backgroundGray50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? color : AppColors.gray200),
                            ),
                            child: Center(
                              child: Text(
                                s[0].toUpperCase() + s.substring(1),
                                style: TextStyle(fontSize: responsive.fontSize(11), fontWeight: FontWeight.w600, color: isSelected ? color : AppColors.gray500),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final title = titleCtrl.text.trim();
                        if (title.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter an issue title')),
                          );
                          return;
                        }
                        final assetId = asset['id']?.toString() ?? '';
                        final homeId = asset['homeId']?.toString() ?? '';
                        try {
                          await AssetApiService.instance.createIssue(
                            homeId: homeId,
                            assetId: assetId,
                            title: title,
                            description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                            severity: severity,
                          );
                          if (ctx.mounted) Navigator.pop(ctx);
                          onIssueCreated?.call();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Issue reported successfully'),
                                backgroundColor: Color(0xFF2E7D32),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        } on Object catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Failed to report issue: $e')),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AssetDetailColors.primaryDark,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      child: Text('Submit Issue', style: TextStyle(fontSize: responsive.fontSize(15), fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final responsive = ResponsiveUtils(context);
    return Text(
      title,
      style: TextStyle(
        fontSize: responsive.fontSize(18),
        fontWeight: FontWeight.bold,
        color: AssetDetailColors.textPrimary,
      ),
    );
  }

  Widget _buildIssueDetailItem(BuildContext context, 
    String issue,
    String status,
    String solution,
    String date,
  ) {
    final responsive = ResponsiveUtils(context);
    final isResolved = status.toLowerCase() == 'resolved';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title and Status
        Row(
          children: [
            Expanded(
              child: Text(
                issue,
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: responsive.spacing(8), vertical: responsive.spacing(4)),
              decoration: BoxDecoration(
                color: isResolved
                    ? AssetDetailColors.successColor.withValues(alpha: 0.1)
                    : AppColors.warningLight,
                borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
              ),
              child: Text(
                status,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: isResolved
                      ? AssetDetailColors.successColor
                      : AppColors.warningOrange,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(10)),
        // Date and View button row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: responsive.iconSize(14),
                  color: AssetDetailColors.textSecondary,
                ),
                SizedBox(width: responsive.spacing(4)),
                Text(
                  date,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AssetDetailColors.textSecondary,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'view',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: AssetDetailColors.primaryDark,
                  ),
                ),
                SizedBox(width: responsive.spacing(2)),
                Icon(
                  Icons.chevron_right,
                  size: responsive.iconSize(18),
                  color: AssetDetailColors.primaryDark,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPartItem(
    BuildContext context,
    String partName,
    String date,
    String price, {
    String? orderId,
  }) {
    final responsive = ResponsiveUtils(context);
    final content = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                partName,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w600,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: responsive.iconSize(12),
                    color: AssetDetailColors.textSecondary,
                  ),
                  SizedBox(width: responsive.spacing(4)),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AssetDetailColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              price,
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.bold,
                color: AssetDetailColors.primaryDark,
              ),
            ),
            SizedBox(width: responsive.spacing(8)),
            Icon(
              Icons.chevron_right,
              size: responsive.iconSize(20),
              color: AssetDetailColors.textSecondary,
            ),
          ],
        ),
      ],
    );

    return GestureDetector(
      onTap: () {
        // Show part order summary bottom sheet
        _showPartOrderSummary(context, partName, date, price);
      },
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }

  void _showPartOrderSummary(
    BuildContext context,
    String partName,
    String date,
    String price,
  ) {
    final responsive = ResponsiveUtils(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(responsive.spacing(24)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: responsive.fontSize(20),
                    fontWeight: FontWeight.bold,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(20)),

            // Part Details Card
            Container(
              padding: EdgeInsets.all(responsive.spacing(16)),
              decoration: BoxDecoration(
                color: AppColors.backgroundGray50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AssetDetailColors.primaryDark.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
                        ),
                        child: Icon(
                          Icons.settings,
                          color: AssetDetailColors.primaryDark,
                          size: responsive.iconSize(24),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              partName,
                              style: TextStyle(
                                fontSize: responsive.fontSize(16),
                                fontWeight: FontWeight.w600,
                                color: AssetDetailColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            Text(
                              'For ${asset['name'] ?? 'Asset'}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(13),
                                color: AppColors.gray500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.spacing(16)),

            // Order Details
            _buildOrderDetailRow(context, 'Order Date', date),
            _buildOrderDetailRow(context, 'Status', 'Delivered', isStatus: true),
            _buildOrderDetailRow(context, 'Shipping', 'Free'),
            const Divider(height: 24),
            _buildOrderDetailRow(context, 'Total', price, isBold: true),

            SizedBox(height: responsive.spacing(24)),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      // Reorder functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Reordering $partName...'),
                          backgroundColor: AssetDetailColors.primaryDark,
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                      side: BorderSide(color: AssetDetailColors.primaryDark),
                    ),
                    child: Text(
                      'Reorder',
                      style: TextStyle(
                        color: AssetDetailColors.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: responsive.spacing(12)),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AssetDetailColors.primaryDark,
                      padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: responsive.spacing(12)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailRow(BuildContext context, 
    String label,
    String value, {
    bool isBold = false,
    bool isStatus = false,
  }) {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.spacing(8)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.gray500),
          ),
          isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      fontWeight: FontWeight.w600,
                      color: AppColors.successMaterialDark,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: responsive.fontSize(14),
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                    color: AssetDetailColors.textPrimary,
                  ),
                ),
        ],
      ),
    );
  }
}