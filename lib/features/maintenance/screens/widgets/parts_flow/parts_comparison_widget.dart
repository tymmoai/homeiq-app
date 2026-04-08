import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/widgets/expandable_text_widget.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../ai_fix_models.dart';

class PartsComparisonWidget extends StatelessWidget {
  final String assetName;
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final double encompassTotal;
  // marconeTotal, localTotal, selectedProvider, showComparison, onSelectProvider,
  // onShowComparison are kept for API compatibility but are no longer displayed.
  final double marconeTotal;
  final double localTotal;
  final String selectedProvider;
  final bool showComparison;
  final void Function(int index, bool isSelected) onTogglePart;
  final void Function(String provider) onSelectProvider;
  final VoidCallback onShowComparison;
  final VoidCallback onContinue;

  const PartsComparisonWidget({
    super.key,
    required this.assetName,
    required this.parts,
    required this.selectedPartsIndexes,
    required this.encompassTotal,
    required this.marconeTotal,
    required this.localTotal,
    required this.selectedProvider,
    required this.showComparison,
    required this.onTogglePart,
    required this.onSelectProvider,
    required this.onShowComparison,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final anySelected = selectedPartsIndexes.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parts needed',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Based on your issue, here are the likely parts for $assetName.',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Container(
          padding: EdgeInsets.all(responsive.spacing(14)),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var i = 0; i < parts.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: selectedPartsIndexes.contains(i),
                        onChanged: (v) => onTogglePart(i, v == true),
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                      ),
                      SizedBox(width: responsive.spacing(4)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${parts[i].name} ×${parts[i].quantity}',
                              style: TextStyle(
                                fontSize: responsive.fontSize(13),
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(height: responsive.spacing(4)),
                            ExpandableText(
                              text: parts[i].description,
                              maxLines: 2,
                              style: TextStyle(
                                fontSize: responsive.fontSize(11),
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: responsive.spacing(6)),
                      Text(
                        '\$${parts[i].priceEncompass.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // ── Encompass order summary ──────────────────────────────────────
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: responsive.spacing(14),
            vertical: responsive.spacing(12),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Encompass',
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(width: responsive.spacing(8)),
              Text(
                'Authorized Parts Provider',
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: responsive.fontSize(11),
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    encompassTotal > 0
                        ? '\$${encompassTotal.toStringAsFixed(2)}'
                        : '--',
                    style: TextStyle(
                      fontSize: responsive.fontSize(16),
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        // ── Validation warning ───────────────────────────────────────────
        if (!anySelected)
          Padding(
            padding: EdgeInsets.only(bottom: responsive.spacing(12)),
            child: Container(
              padding: EdgeInsets.all(responsive.spacing(12)),
              decoration: BoxDecoration(
                color: AppColors.warningLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.warningOrange,
                  ),
                  SizedBox(width: responsive.spacing(8)),
                  Text(
                    'Select at least one part to continue',
                    style: TextStyle(
                      fontSize: responsive.fontSize(12),
                      color: AppColors.warningOrange,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // ── Buy Parts button ─────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: anySelected ? onContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor:
                  AppColors.primary.withValues(alpha: 0.4),
              foregroundColor: Colors.white,
              elevation: anySelected ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              anySelected && encompassTotal > 0
                  ? 'Buy Parts  ·  \$${encompassTotal.toStringAsFixed(2)}'
                  : 'Buy Parts',
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        SizedBox(height: responsive.spacing(24)),
      ],
    );
  }
}
