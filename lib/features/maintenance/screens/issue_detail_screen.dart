import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../services/pdf_generator_service.dart';
import '../../../theme/asset_detail_colors.dart';
import '../../../utils/responsive_utils.dart';

class IssueDetailScreen extends StatelessWidget {
  final Map<String, dynamic> issue;
  final Map<String, dynamic> asset;
  const IssueDetailScreen({
    super.key,
    required this.issue,
    required this.asset,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final status = issue['status'] ?? 'Open';
    final isResolved = status.toLowerCase() == 'resolved';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: AppColors.headerBackground,
        statusBarIconBrightness:
            AppColors.headerBackground.computeLuminance() > 0.5
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: AppColors.headerBackground.computeLuminance() > 0.5
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppColors.backgroundGray50,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context, status, isResolved),
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(responsive.spacing(16)),
                  child: Column(
                    children: [
                      _buildAssetInformation(context),
                      SizedBox(height: responsive.spacing(16)),
                      _buildServiceDetails(context),
                      SizedBox(height: responsive.spacing(16)),
                      _buildWarrantyClaim(context),
                      SizedBox(height: responsive.spacing(0)),
                      _buildProblemDescription(context),
                      SizedBox(height: responsive.spacing(4)),
                      _buildSolution(context),
                      SizedBox(height: responsive.spacing(4)),
                      _buildCostAndImpact(context),
                      SizedBox(height: responsive.spacing(16)),
                      _buildClaimProgress(context, isResolved),
                    ],
                  ),
                ),
              ),
              // Bottom Action Buttons
              _buildBottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String status, bool isResolved) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: const EdgeInsets.only(
        top: 12,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.headerBackground,
        boxShadow: [
          BoxShadow(
            color: AppColors.shadowHeavy,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: responsive.iconSize(20),
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  issue['title'] ?? 'Issue Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: responsive.fontSize(18),
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Issue #${issue['id'] ?? '1'} • Reported on ${_formatDate(issue['date']?.toString() ?? issue['createdAt']?.toString())}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: responsive.fontSize(12),
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildClaimOverview(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final status = issue['status'] ?? 'Open';
    final isResolved = status.toLowerCase() == 'resolved';

    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Claim Overview',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: AssetDetailColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isResolved
                      ? AppColors.successLight
                      : AppColors.backgroundGray100,
                  borderRadius: BorderRadius.circular(
                    AppDimensions.radiusBadge,
                  ),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isResolved
                        ? AppColors.successDark
                        : AppColors.slate800,
                    fontSize: responsive.fontSize(11),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(16)),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  'ASSET',
                  asset['name'] ?? 'N/A',
                  asset['model'] ?? '',
                  isPrimary: true,
                ),
              ),
              Expanded(
                child: _buildPriorityBadge(
                  context,
                  issue['priority'] ?? issue['severity'] ?? 'Medium',
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(16)),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  context,
                  'ISSUE TYPE',
                  issue['category'] ?? 'N/A',
                  null,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  context,
                  'WARRANTY',
                  issue['warranty'] ?? 'Not Covered',
                  null,
                  isSecondary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    String label,
    String value,
    String? subtitle, {
    bool isPrimary = false,
    bool isSecondary = false,
  }) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: responsive.fontSize(10),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          value,
          style: TextStyle(
            color: isPrimary
                ? AppColors.primary
                : isSecondary
                ? AppColors.slate500
                : AppColors.textDark,
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          SizedBox(height: responsive.spacing(2)),
          Text(
            subtitle,
            style: TextStyle(
              color: AppColors.gray400,
              fontSize: responsive.fontSize(11),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPriorityBadge(BuildContext context, String priority) {
    final responsive = ResponsiveUtils(context);
    Color bgColor = AppColors.gray100;
    Color textColor = AppColors.gray700;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PRIORITY',
          style: TextStyle(
            color: AppColors.gray600,
            fontSize: responsive.fontSize(10),
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(8),
            vertical: responsive.spacing(4),
          ),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppDimensions.radiusBadge),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.circle,
                color: textColor,
                size: responsive.iconSize(8),
              ),
              SizedBox(width: responsive.spacing(4)),
              Text(
                priority,
                style: TextStyle(
                  color: textColor,
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimProgress(BuildContext context, bool isResolved) {
    final responsive = ResponsiveUtils(context);
    final steps = [
      {
        'icon': Icons.report_problem_outlined,
        'title': 'Issue Reported',
        'description': 'Issue was reported and logged in the system',
        'date': issue['date'] ?? 'N/A',
        'isCompleted': true,
      },
      {
        'icon': Icons.assignment_ind_outlined,
        'title': 'Under Review',
        'description': 'Issue is being reviewed by the team',
        'date': issue['status']?.toLowerCase() != 'open'
            ? 'Complete'
            : 'Pending',
        'isCompleted': issue['status']?.toLowerCase() != 'open',
      },
      {
        'icon': Icons.engineering_outlined,
        'title': 'In Progress',
        'description': 'Work is actively being done on the issue',
        'date': issue['status']?.toLowerCase() == 'in_progress'
            ? 'Active'
            : 'Pending',
        'isCompleted':
            issue['status']?.toLowerCase() == 'in_progress' ||
            issue['status']?.toLowerCase() == 'resolved' ||
            issue['status']?.toLowerCase() == 'closed',
      },
      {
        'icon': Icons.check_circle_outlined,
        'title': 'Issue Resolved',
        'description': isResolved
            ? 'Issue has been resolved successfully'
            : 'Awaiting resolution',
        'date': issue['resolvedAt'] != null
            ? _formatDate(issue['resolvedAt'].toString())
            : (isResolved ? 'Completed' : 'Pending'),
        'isCompleted': isResolved,
      },
    ];

    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CLAIM PROGRESS',
            style: TextStyle(
              fontSize: responsive.fontSize(11),
              fontWeight: FontWeight.w600,
              color: AssetDetailColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: responsive.spacing(16)),
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final isLast = index == steps.length - 1;
            return _buildTimelineItem(
              context,
              icon: step['icon'] as IconData,
              title: step['title'] as String,
              description: step['description'] as String,
              date: step['date'] as String,
              isCompleted: step['isCompleted'] as bool,
              isLast: isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required String date,
    required bool isCompleted,
    required bool isLast,
  }) {
    final responsive = ResponsiveUtils(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline Indicator
        Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.primary : AppColors.gray200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isCompleted ? Icons.check : icon,
                size: responsive.iconSize(16),
                color: isCompleted ? Colors.white : AppColors.gray500,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: isCompleted ? AppColors.primary : AppColors.gray200,
              ),
          ],
        ),
        SizedBox(width: responsive.spacing(12)),
        // Timeline Content
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: responsive.fontSize(14),
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AssetDetailColors.textPrimary
                            : AppColors.gray500,
                      ),
                    ),
                    Text(
                      date,
                      style: TextStyle(
                        fontSize: responsive.fontSize(11),
                        fontWeight: FontWeight.w500,
                        color: isCompleted
                            ? AppColors.primary
                            : AppColors.gray400,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: responsive.spacing(4)),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.gray600,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildProgressStep(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String date,
    required bool isCompleted,
  }) {
    final responsive = ResponsiveUtils(context);
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? AssetDetailColors.primaryDark
                : AppColors.gray300,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isCompleted
                ? AppColors.textOnPrimary
                : AppColors.textSecondary,
            size: responsive.iconSize(20),
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(9),
            fontWeight: FontWeight.bold,
            color: AppColors.gray500,
          ),
        ),
        SizedBox(height: responsive.spacing(2)),
        Text(
          date,
          style: TextStyle(
            fontSize: responsive.fontSize(9),
            fontWeight: FontWeight.w600,
            color: isCompleted
                ? AssetDetailColors.primaryDark
                : AppColors.gray400,
          ),
        ),
      ],
    );
  }

  Widget _buildProblemDescription(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Problem Description',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.bold,
              color: AssetDetailColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            issue['description'] ?? 'No description available.',
            style: TextStyle(
              color: AppColors.gray700,
              fontSize: responsive.fontSize(13),
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolution(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final isResolved =
        (issue['status']?.toString().toLowerCase() == 'resolved' ||
        issue['status']?.toString().toLowerCase() == 'closed');
    final resolvedAt = issue['resolvedAt']?.toString();
    // Only show this section when resolved or when there's meaningful content
    if (!isResolved && resolvedAt == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resolution',
            style: TextStyle(
              color: AssetDetailColors.textPrimary,
              fontSize: responsive.fontSize(14),
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: responsive.spacing(8)),
          Text(
            'Issue has been resolved successfully.',
            style: TextStyle(
              color: AppColors.gray700,
              fontSize: responsive.fontSize(13),
              height: 1.5,
            ),
          ),
          if (resolvedAt != null) ...[
            SizedBox(height: responsive.spacing(8)),
            Text(
              'Resolved on: ${_formatDate(resolvedAt)}',
              style: TextStyle(
                color: AppColors.gray500,
                fontSize: responsive.fontSize(12),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Cost and health impact are not stored in the backend model — section is hidden.
  Widget _buildCostAndImpact(BuildContext context) => const SizedBox.shrink();

  Widget _buildAssetInformation(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
              Icon(
                Icons.inventory_2_outlined,
                color: AppColors.gray600,
                size: responsive.iconSize(20),
              ),
              SizedBox(width: responsive.spacing(8)),
              Text(
                'Asset Information',
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.spacing(16)),
          _buildDetailRow(
            context,
            'Serial Number',
            asset['serialNumber'] ?? 'N/A',
          ),
          _buildDetailRow(
            context,
            'Purchase Date',
            asset['purchaseDate'] ?? 'N/A',
          ),
          _buildDetailRow(context, 'Location', asset['location'] ?? 'N/A'),
          _buildDetailRow(
            context,
            'Current Health',
            '${asset['health'] ?? '0'}/10',
            valueColor: AssetDetailColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDetails(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Service Details',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.bold,
              color: AssetDetailColors.textPrimary,
            ),
          ),
          SizedBox(height: responsive.spacing(16)),
          _buildDetailRow(
            context,
            'Severity',
            _capitalized(issue['severity']?.toString() ?? 'Medium'),
            valueColor: _severityColor(issue['severity']?.toString()),
          ),
          _buildDetailRow(
            context,
            'Reported On',
            _formatDate(
              issue['date']?.toString() ?? issue['createdAt']?.toString(),
            ),
          ),
          _buildDetailRow(
            context,
            'Last Updated',
            _formatDate(issue['updatedAt']?.toString()),
          ),
        ],
      ),
    );
  }

  /// Warranty details are not stored per-issue in the backend — section hidden.
  Widget _buildWarrantyClaim(BuildContext context) => const SizedBox.shrink();

  // ── Utility helpers ──────────────────────────────────────────────────────

  static String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return 'N/A';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
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
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static String _capitalized(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static Color _severityColor(String? severity) {
    switch (severity?.toLowerCase()) {
      case 'critical':
        return AppColors.errorDark;
      case 'high':
        return AssetDetailColors.errorColor;
      case 'medium':
        return AppColors.warningDark;
      case 'low':
        return AppColors.successDark;
      default:
        return AppColors.gray600;
    }
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value, {
    Color? labelColor,
    Color? valueColor,
  }) {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: labelColor ?? AppColors.gray600,
              fontSize: responsive.fontSize(13),
            ),
          ),
          SizedBox(width: responsive.spacing(16)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? Colors.black,
                fontSize: responsive.fontSize(13),
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Container(
      padding: EdgeInsets.all(responsive.spacing(16)),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _downloadIssueReport(context),
              icon: Icon(
                Icons.file_download_outlined,
                size: responsive.iconSize(20),
              ),
              label: const Text('Download'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AssetDetailColors.primaryDark,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                side: BorderSide(
                  color: AssetDetailColors.primaryDark,
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _shareIssueReport(context),
              icon: Icon(Icons.share_outlined, size: responsive.iconSize(20)),
              label: const Text('Share'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AssetDetailColors.primaryDark,
                padding: EdgeInsets.symmetric(vertical: responsive.spacing(14)),
                side: BorderSide(
                  color: AssetDetailColors.primaryDark,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _downloadIssueReport(BuildContext context) async {
    // Show a persistent loading snackbar while generating
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12),
            Text('Generating PDF...'),
          ],
        ),
        duration: Duration(seconds: 30),
      ),
    );

    try {
      final file = await PdfGeneratorService().generateIssueReportPdf(
        issue: issue,
        asset: asset,
      );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (Platform.isAndroid) {
        // Save to external storage — visible under Files > Internal storage > Android/data/…
        final dir = await getExternalStorageDirectory();
        final saveDir = dir ?? await getApplicationDocumentsDirectory();
        final name =
            'issue_report_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final saved = await file.copy('${saveDir.path}/$name');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('PDF saved: ${saved.path}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Share',
                textColor: Colors.white,
                onPressed: () => Share.shareXFiles(
                  [XFile(saved.path, mimeType: 'application/pdf')],
                  subject:
                      'Issue Report - ${issue['title'] ?? 'Issue Details'}',
                ),
              ),
            ),
          );
        }
      } else {
        // iOS — save to Files via share sheet
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'Issue Report - ${issue['title'] ?? 'Issue Details'}',
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _shareIssueReport(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF for sharing...'),
          duration: Duration(seconds: 2),
        ),
      );

      final file = await PdfGeneratorService().generateIssueReportPdf(
        issue: issue,
        asset: asset,
      );

      if (context.mounted) {
        await PdfGeneratorService.sharePdf(
          file,
          subject: 'Issue Report - ${issue['title'] ?? 'Issue Details'}',
        );
      }
    } on Object catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share PDF: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
