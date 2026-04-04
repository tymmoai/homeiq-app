import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../services/api_usage_tracker.dart';

/// Compact card showing API usage statistics.
///
/// Displays used / limit and a progress bar for each API:
///   - OpenAI (ChatGPT + Vision + DALL-E combined)
///   - Barcode Lookup API
///
/// Usage:
/// ```dart
/// ApiUsageWidget()              // default card
/// ApiUsageWidget(compact: true) // single-line summary
/// ```
class ApiUsageWidget extends StatelessWidget {
  /// If true, shows a minimal single-line summary instead of the full card.
  final bool compact;

  const ApiUsageWidget({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final tracker = ApiUsageTracker();
    final snap = tracker.snapshot;

    if (compact) {
      return _buildCompactView(snap);
    }
    return _buildFullCard(snap);
  }

  // ═════════════════════════════════════════════════════════════
  //  COMPACT VIEW — single line, for inline use
  // ═════════════════════════════════════════════════════════════

  Widget _buildCompactView(ApiUsageSnapshot snap) {
    final openAiColor = _ratioColor(snap.openAiRatio);
    final barcodeColor = _ratioColor(snap.barcodeApiRatio);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.analytics_outlined, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(
          'AI: ${snap.openAiUsed}/${snap.openAiLimit}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: openAiColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Barcode: ${snap.barcodeApiUsed}/${snap.barcodeApiLimit}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: barcodeColor,
          ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  FULL CARD — detailed view with progress bars
  // ═════════════════════════════════════════════════════════════

  Widget _buildFullCard(ApiUsageSnapshot snap) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary10),
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
          // Header
          Row(
            children: [
              Icon(
                Icons.analytics_rounded,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'API Usage This Month',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.backgroundSlate100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _formatMonth(snap.trackingMonth),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // OpenAI Section
          _buildApiSection(
            icon: Icons.auto_awesome,
            label: 'OpenAI (ChatGPT)',
            used: snap.openAiUsed,
            limit: snap.openAiLimit,
            ratio: snap.openAiRatio,
            details: [
              if (snap.openAiVisionUsed > 0)
                _DetailItem('Vision', snap.openAiVisionUsed),
              if (snap.dalleUsed > 0)
                _DetailItem('DALL-E', snap.dalleUsed),
              _DetailItem(
                'Text',
                snap.openAiUsed - snap.openAiVisionUsed - snap.dalleUsed,
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Barcode API Section
          _buildApiSection(
            icon: Icons.qr_code_scanner,
            label: 'Barcode Lookup API',
            used: snap.barcodeApiUsed,
            limit: snap.barcodeApiLimit,
            ratio: snap.barcodeApiRatio,
          ),
        ],
      ),
    );
  }

  Widget _buildApiSection({
    required IconData icon,
    required String label,
    required int used,
    required int limit,
    required double ratio,
    List<_DetailItem>? details,
  }) {
    final remaining = (limit - used).clamp(0, limit);
    final color = _ratioColor(ratio);
    final barColor = _barColor(ratio);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label row
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.textSecondary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Text(
              '$used / $limit',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.backgroundSlate100,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),

        // Remaining + details
        Row(
          children: [
            Text(
              '$remaining remaining',
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            if (details != null && details.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text('•', style: TextStyle(fontSize: 10, color: AppColors.textSecondary)),
              const SizedBox(width: 4),
              ...details.map((d) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Text(
                      '${d.label}: ${d.count}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════
  //  HELPERS
  // ═════════════════════════════════════════════════════════════

  Color _ratioColor(double ratio) {
    if (ratio >= 1.0) return const Color(0xFFDC2626); // Red — over limit
    if (ratio >= 0.8) return const Color(0xFFF59E0B); // Amber — near limit
    return const Color(0xFF059669); // Green — healthy
  }

  Color _barColor(double ratio) {
    if (ratio >= 1.0) return const Color(0xFFDC2626);
    if (ratio >= 0.8) return const Color(0xFFF59E0B);
    if (ratio >= 0.5) return const Color(0xFF3B82F6); // Blue — moderate
    return const Color(0xFF059669); // Green
  }

  String _formatMonth(String monthKey) {
    // monthKey is "YYYY-MM"
    final parts = monthKey.split('-');
    if (parts.length != 2) return monthKey;
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final monthIdx = int.tryParse(parts[1]);
    if (monthIdx == null || monthIdx < 1 || monthIdx > 12) return monthKey;
    return '${months[monthIdx - 1]} ${parts[0]}';
  }
}

class _DetailItem {
  final String label;
  final int count;
  const _DetailItem(this.label, this.count);
}
