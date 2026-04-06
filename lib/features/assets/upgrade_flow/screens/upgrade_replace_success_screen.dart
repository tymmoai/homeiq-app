import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../services/claims_service.dart';
import '../../../../utils/responsive_utils.dart';

class UpgradeReplaceSuccessScreen extends StatefulWidget {
  final String assetName;
  final String assetType;
  final String problemDescription;
  final String inspectionDate;
  final int photosCount;

  const UpgradeReplaceSuccessScreen({
    super.key,
    required this.assetName,
    this.assetType = 'Appliance',
    this.problemDescription = 'Replacement claim submitted',
    this.inspectionDate = 'To be scheduled',
    this.photosCount = 0,
  });

  @override
  State<UpgradeReplaceSuccessScreen> createState() =>
      _UpgradeReplaceSuccessScreenState();
}

class _UpgradeReplaceSuccessScreenState
    extends State<UpgradeReplaceSuccessScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  Color get _headerColor => AppColors.primary;
  static final Color _textPrimary = AppColors.textPrimary;
  static final Color _textSecondary = AppColors.textSecondary;
  static final Color _backgroundColor = AppColors.backgroundGray200;

  // Generate claim ID and date once so all references are consistent
  late final String _claimId;
  late final DateTime _submittedDate;

  @override
  void initState() {
    super.initState();
    _claimId =
        'RPL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _submittedDate = DateTime.now();
    _saveClaim();
  }

  Future<void> _saveClaim() async {
    await ClaimsService.saveReplacementClaim(
      assetName: widget.assetName,
      assetId: 'asset-${_submittedDate.millisecondsSinceEpoch}',
      description: 'Replacement claim submitted for ${widget.assetName}.',
    );
  }

  void _showReceiptSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Replacement Receipt',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(8)),
              Text(
                widget.assetName,
                style: TextStyle(
                  fontSize: responsive.fontSize(14),
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                widget.assetType,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'Claim ID: $_claimId',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                'Submitted: ${_submittedDate.month}/${_submittedDate.day}/${_submittedDate.year}',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                'Inspection: ${widget.inspectionDate}',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _headerColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              const Divider(),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'Problem Reported',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Text(
                widget.problemDescription,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _textSecondary,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'Photos Attached: ${widget.photosCount}',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(16)),
              const Divider(),
              SizedBox(height: responsive.spacing(12)),
              Text(
                'Status',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  color: _textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(4)),
              Row(
                children: [
                  Icon(
                    Icons.hourglass_top,
                    size: responsive.iconSize(18),
                    color: _headerColor,
                  ),
                  SizedBox(width: responsive.spacing(6)),
                  Text(
                    'Submitted â€¢ Under review',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: _textPrimary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(16)),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.textOnPrimary,
                    padding: EdgeInsets.symmetric(
                      vertical: responsive.spacing(12),
                    ),
                  ),
                  child: Text(
                    'Close',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.all(responsive.spacing(20)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(height: responsive.spacing(60)),
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.successLight,
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.successMaterialAccent,
                      size: responsive.iconSize(48),
                    ),
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  Text(
                    'Replacement Claim Submitted!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.fontSize(22),
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(12)),
                  Text(
                    'Your replacement request for ${widget.assetName} has been successfully submitted. '
                    'Our team will review it and contact you within 24-48 hours.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      color: _textSecondary,
                    ),
                  ),
                  SizedBox(height: responsive.spacing(24)),

                  // Claim Summary Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(18)),
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
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(responsive.spacing(8)),
                              decoration: BoxDecoration(
                                color: _headerColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusBadge,
                                ),
                              ),
                              child: Icon(
                                Icons.assignment_outlined,
                                color: _headerColor,
                                size: responsive.iconSize(20),
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Text(
                              'Claim Summary',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        _InfoRow('Asset', widget.assetName),
                        _InfoRow('Type', widget.assetType),
                        _InfoRow('Claim ID', _claimId),
                        _InfoRow(
                          'Submitted',
                          '${_submittedDate.month}/${_submittedDate.day}/${_submittedDate.year}',
                        ),
                        _InfoRow('Inspection Date', widget.inspectionDate),
                        _InfoRow(
                          'Photos Attached',
                          '${widget.photosCount} file(s)',
                        ),
                        SizedBox(height: responsive.spacing(12)),
                        const Divider(),
                        SizedBox(height: responsive.spacing(12)),
                        Text(
                          'Problem Description',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            fontWeight: FontWeight.w600,
                            color: _textPrimary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(6)),
                        Text(
                          widget.problemDescription,
                          style: TextStyle(
                            fontSize: responsive.fontSize(13),
                            color: _textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),

                  // What's Next Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(18)),
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
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(responsive.spacing(8)),
                              decoration: BoxDecoration(
                                color: AppColors.successLight,
                                borderRadius: BorderRadius.circular(
                                  AppDimensions.radiusBadge,
                                ),
                              ),
                              child: Icon(
                                Icons.schedule_outlined,
                                color: AppColors.successMaterialAccent,
                                size: responsive.iconSize(20),
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Text(
                              'What Happens Next?',
                              style: TextStyle(
                                fontSize: responsive.fontSize(16),
                                fontWeight: FontWeight.w700,
                                color: _textPrimary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        _StepItem(
                          number: '1',
                          title: 'Technician Inspection',
                          subtitle: 'On ${widget.inspectionDate}',
                        ),
                        const _StepItem(
                          number: '2',
                          title: 'Eligibility Verification',
                          subtitle: '1-2 business days',
                        ),
                        const _StepItem(
                          number: '3',
                          title: 'Approval & Scheduling',
                          subtitle: 'We\'ll contact you',
                        ),
                        const _StepItem(
                          number: '4',
                          title: 'Replacement & Installation',
                          subtitle: 'Free installation included',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(16)),

                  // Contact Support Card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(responsive.spacing(18)),
                    decoration: BoxDecoration(
                      color: AppColors.warningLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.warningOrangeLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: AppColors.warningOrange,
                              size: responsive.iconSize(20),
                            ),
                            SizedBox(width: responsive.spacing(8)),
                            Text(
                              'Need Help?',
                              style: TextStyle(
                                fontSize: responsive.fontSize(14),
                                fontWeight: FontWeight.w700,
                                color: AppColors.warningOrange,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Text(
                          'Questions about your claim? Contact our support team:',
                          style: TextStyle(
                            fontSize: responsive.fontSize(12),
                            color: AppColors.warningDark,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(8)),
                        Row(
                          children: [
                            Icon(
                              Icons.phone,
                              size: responsive.iconSize(14),
                              color: AppColors.warningOrange,
                            ),
                            SizedBox(width: responsive.spacing(6)),
                            Text(
                              '1-888-BRANDSMART (272-6376)',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Row(
                          children: [
                            Icon(
                              Icons.email,
                              size: responsive.iconSize(14),
                              color: AppColors.warningOrange,
                            ),
                            SizedBox(width: responsive.spacing(6)),
                            Text(
                              'support@brandsmartusa.com',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.warningDark,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(4)),
                        Text(
                          'Mon-Fri: 8AM-8PM EST, Sat-Sun: 9AM-5PM EST',
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            color: AppColors.warningDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: responsive.spacing(24)),
                  // Action Buttons
                  Column(
                    children: [
                      // View Full Details button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => _showReceiptSheet(context),
                          icon: Icon(
                            Icons.receipt_long,
                            size: responsive.iconSize(20),
                          ),
                          label: Text(
                            'View Full Details',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      // Track My Claims button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/my-claims'),
                          icon: Icon(
                            Icons.track_changes,
                            size: responsive.iconSize(20),
                          ),
                          label: Text(
                            'Track My Claims',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.08,
                            ),
                            foregroundColor: _headerColor,
                            side: BorderSide(color: _headerColor, width: 1.5),
                          ),
                        ),
                      ),
                      SizedBox(height: responsive.spacing(12)),
                      // Back to Asset button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).popUntil((route) => route.isFirst);
                          },
                          icon: Icon(
                            Icons.arrow_back,
                            size: responsive.iconSize(20),
                          ),
                          label: Text(
                            'Back to Asset',
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Close button at top right
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: AppColors.textPrimary,
                  size: responsive.iconSize(28),
                ),
                onPressed: () {
                  // Navigate back to upgrade offer screen (pop twice)
                  Navigator.of(context).pop(); // Pop success screen
                  Navigator.of(context).pop(); // Pop replace form screen
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Helper Widgets
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepItem extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;
  final bool isLast;

  const _StepItem({
    required this.number,
    required this.title,
    required this.subtitle,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          SizedBox(width: responsive.spacing(12)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(2)),
                Text(
                  subtitle,
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
    );
  }
}
