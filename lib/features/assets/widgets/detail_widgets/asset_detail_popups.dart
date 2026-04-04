import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';
import '../../helpers/asset_detail_helpers.dart';

/// Show the Protection Plan expired popup modal.
void showProtectionPlanModal({
  required BuildContext dialogContext,
  required BuildContext mainContext,
  required String? warrantyEndDate,
  required bool showUpgradeNext,
  required double healthScore,
  required int ageYears,
  required Map<String, dynamic> asset,
  required VoidCallback onCheckProtectionPlan,
}) {
  final responsive = ResponsiveUtils(dialogContext);
  showDialog(
    context: dialogContext,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20.0),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: responsive.spacing(400.0)),
        decoration: BoxDecoration(
          color: AppColors.popupBackground,
          borderRadius: BorderRadius.circular(responsive.borderRadius(20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: responsive.spacing(20.0),
              offset: Offset(0, responsive.spacing(10.0)),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section with Icon
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(24.0),
                  responsive.spacing(32.0),
                  responsive.spacing(24.0),
                  responsive.spacing(24.0),
                ),
                child: Column(
                  children: [
                    // Large circular shield icon with app theme color
                    Container(
                      width: responsive.iconSize(90.0),
                      height: responsive.iconSize(90.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AssetDetailColors.primaryDark.withValues(
                            alpha: 0.5,
                          ),
                          width: 3,
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(responsive.spacing(8.0)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AssetDetailColors.primaryDark,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Shield icon
                            Icon(
                              Icons.shield,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: responsive.iconSize(42.0),
                            ),
                            // Heart icon inside shield
                            Positioned(
                              bottom: responsive.spacing(10.0),
                              child: Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: responsive.iconSize(18.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24.0)),
                    // Title
                    Text(
                      'Protection Ended',
                      style: TextStyle(
                        fontSize: responsive.fontSize(24.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.spacing(8.0)),
                    // Expiry Date
                    if (warrantyEndDate != null &&
                        warrantyEndDate.isNotEmpty &&
                        warrantyEndDate != 'null')
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.spacing(12.0),
                          vertical: responsive.spacing(6.0),
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Expired on: ${formatDateDisplay(warrantyEndDate)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(13.0),
                            color: Colors.red.shade300,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    SizedBox(height: responsive.spacing(12.0)),
                    // Body Text
                    Text(
                      'Your appliance protection plan has expired. Renew now to avoid high repair costs and ensure 24/7 support for your devices.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(24.0),
                  0,
                  responsive.spacing(24.0),
                  responsive.spacing(32.0),
                ),
                child: Column(
                  children: [
                    // Protection Plan Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Navigate to warranties flow and refresh state on return
                          mainContext.push(
                            '/warranties',
                            extra: asset,
                          ).then((_) {
                            // When returning from protection plan flow, re-check plan status
                            onCheckProtectionPlan();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AssetDetailColors
                              .primaryDark, // App theme color
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.spacing(14.0),
                          ),
                          textStyle: TextStyle(
                            fontSize: responsive.fontSize(15.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Get Extended Protection'),
                      ),
                    ),

                    SizedBox(height: responsive.spacing(24.0)),

                    // Maybe Later - Just text, not a button (less space)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        // If upgrade should be shown next, show it after closing this
                        if (showUpgradeNext) {
                          // Use a small delay to ensure the first dialog is fully closed
                          Future.delayed(const Duration(milliseconds: 200), () {
                            // Check if context is still valid before showing next popup
                            if (mainContext.mounted) {
                              showUpgradeModal(
                                context: mainContext,
                                healthScore: healthScore,
                                ageYears: ageYears,
                                asset: asset,
                              );
                            }
                          });
                        }
                      },
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Show the Upgrade Available popup modal.
void showUpgradeModal({
  required BuildContext context,
  required double healthScore,
  required int ageYears,
  required Map<String, dynamic> asset,
}) {
  final responsive = ResponsiveUtils(context);
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    barrierDismissible: false,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(
        horizontal: responsive.spacing(20.0),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: responsive.spacing(400.0)),
        decoration: BoxDecoration(
          color: AppColors.popupBackground,
          borderRadius: BorderRadius.circular(responsive.borderRadius(20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: responsive.spacing(20.0),
              offset: Offset(0, responsive.spacing(10.0)),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Section with Icon
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(24.0),
                  responsive.spacing(32.0),
                  responsive.spacing(24.0),
                  responsive.spacing(24.0),
                ),
                child: Column(
                  children: [
                    // Large circular gift icon with app theme color
                    Container(
                      width: responsive.iconSize(90.0),
                      height: responsive.iconSize(90.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AssetDetailColors.primaryDark.withValues(
                            alpha: 0.5,
                          ),
                          width: responsive.spacing(3.0),
                        ),
                      ),
                      child: Container(
                        margin: EdgeInsets.all(responsive.spacing(8.0)),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AssetDetailColors.primaryDark,
                        ),
                        child: Icon(
                          Icons.card_giftcard,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: responsive.iconSize(42.0),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.spacing(24.0)),
                    // Title
                    Text(
                      'Upgrade Available',
                      style: TextStyle(
                        fontSize: responsive.fontSize(24.0),
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: responsive.spacing(12.0)),
                    // Body Text
                    Text(
                      'Your appliance\'s health score is low. Consider upgrading for better performance and reliability.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(14.0),
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // Content Section
              Padding(
                padding: EdgeInsets.fromLTRB(
                  responsive.spacing(24.0),
                  0,
                  responsive.spacing(24.0),
                  responsive.spacing(32.0),
                ),
                child: Column(
                  children: [
                    // Upgrade Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          context.push('/upgrade-offer', extra: asset);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AssetDetailColors
                              .primaryDark, // App theme color
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.symmetric(
                            vertical: responsive.spacing(16.0),
                          ),
                          textStyle: TextStyle(
                            fontSize: responsive.fontSize(15.0),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('View Upgrade Options'),
                      ),
                    ),

                    SizedBox(height: responsive.spacing(24.0)),

                    // Maybe Later - Just text, not a button (less space)
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Maybe Later',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13.0),
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
