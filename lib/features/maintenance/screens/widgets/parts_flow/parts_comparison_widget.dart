import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_dimensions.dart';
import '../../../../../core/widgets/expandable_text_widget.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../ai_fix_models.dart';

class PartsComparisonWidget extends StatelessWidget {
  final String assetName;
  final List<PartOption> parts;
  final Set<int> selectedPartsIndexes;
  final double encompassTotal;
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
        Container(
          padding: EdgeInsets.all(responsive.spacing(12)),
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
              _buildProviderRow(
                context,
                'Encompass',
                encompassTotal,
                'Recommended',
              ),
              if (showComparison) ...[
                const Divider(height: 16),
                _buildProviderRow(context, 'Marcone', marconeTotal, null),
                const Divider(height: 16),
                _buildProviderRow(context, 'Reliable Parts', localTotal, null),
              ],
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        if (!anySelected)
          Container(
            padding: EdgeInsets.all(responsive.spacing(12)),
            decoration: BoxDecoration(
              color: AppColors.warningLight,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              'Select at least one part to continue',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                color: AppColors.warningOrange,
              ),
            ),
          ),
        // Bottom spacing for floating button
        SizedBox(height: responsive.spacing(80)),
      ],
    );
  }

  Widget _buildProviderRow(
    BuildContext context,
    String name,
    double total,
    String? tag,
  ) {
    final responsive = ResponsiveUtils(context);
    final isSelected = selectedProvider == name;
    final isEncompass = name == 'Encompass';
    return InkWell(
      onTap: () => onSelectProvider(name),
      child: Row(
        children: [
          Icon(
            isSelected
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            size: responsive.iconSize(18),
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          SizedBox(width: responsive.spacing(8)),
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontSize: responsive.fontSize(13),
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (tag != null) ...[
                  SizedBox(width: responsive.spacing(6)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(
                        AppDimensions.radiusBadge,
                      ),
                    ),
                    child: Text(
                      'Recommended',
                      style: TextStyle(
                        fontSize: responsive.fontSize(10),
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            total > 0 ? '\$${total.toStringAsFixed(0)}' : '--',
            style: TextStyle(
              fontSize: responsive.fontSize(13),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          if (isEncompass && !showComparison) ...[
            SizedBox(width: responsive.spacing(8)),
            TextButton(
              onPressed: onShowComparison,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Compare',
                style: TextStyle(
                  fontSize: responsive.fontSize(12),
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
