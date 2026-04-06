// Health Score Display Widget
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../shared/models/maintenance_models.dart';

class HealthScoreDisplay extends StatelessWidget {
  final AssetHealthScore score;
  final bool showDetails;
  final String size; // 'sm', 'md', 'lg'

  const HealthScoreDisplay({
    super.key,
    required this.score,
    this.showDetails = false,
    this.size = 'md',
  });

  Map<String, dynamic> _getHealthColor(double health) {
    if (health >= 8) {
      return {
        'bg': AppColors.success,
        'text': AppColors.successDark,
        'label': 'Excellent',
      };
    } else if (health >= 6) {
      return {
        'bg': AppColors.warning,
        'text': AppColors.warningAmberDark,
        'label': 'Good',
      };
    } else if (health >= 4) {
      return {
        'bg': AppColors.warningOrange,
        'text': AppColors.warningDark,
        'label': 'Fair',
      };
    } else {
      return {
        'bg': AppColors.error,
        'text': AppColors.errorDark,
        'label': 'Poor',
      };
    }
  }

  double _getSizeMultiplier() {
    switch (size) {
      case 'sm':
        return 1.0;
      case 'lg':
        return 1.5;
      default:
        return 1.2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final healthColor = _getHealthColor(score.healthScore);
    final sizeMultiplier = _getSizeMultiplier();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Health Score
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Health Score',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  healthColor['label'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: healthColor['text'] as Color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  score.healthScore.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 36 * sizeMultiplier,
                    fontWeight: FontWeight.w700,
                    color: healthColor['text'] as Color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  '/10',
                  style: TextStyle(
                    fontSize: 20 * sizeMultiplier,
                    color: AppColors.gray500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score.healthScore / 10,
                minHeight: 12,
                backgroundColor: AppColors.gray100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  healthColor['bg'] as Color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Explanation
        const Text(
          'Based on age, maintenance, and usage patterns',
          style: TextStyle(fontSize: 12, color: AppColors.gray500),
        ),
        // Detailed Factors
        if (showDetails) ...[
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Column(
            children: [
              _buildFactorRow('Age Factor', score.factors.age),
              const SizedBox(height: 8),
              _buildFactorRow(
                'Maintenance Rate',
                score.factors.maintenanceCompletionRate,
              ),
              const SizedBox(height: 8),
              _buildFactorRow('Issue History', score.factors.issueHistory),
              const SizedBox(height: 8),
              _buildFactorRow(
                'Brand Reliability',
                score.factors.brandReliability,
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFactorRow(String label, double value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.gray600),
        ),
        Text(
          '${value.toStringAsFixed(1)}/10',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
