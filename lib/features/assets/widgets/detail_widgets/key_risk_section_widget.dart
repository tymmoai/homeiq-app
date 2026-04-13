import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../theme/asset_detail_colors.dart';
import '../../../../utils/responsive_utils.dart';

/// Widget that displays key risks for an asset based on health score, age,
/// and the specific asset type (e.g. "Dryer", "Refrigerator", "Router").
class KeyRiskSectionWidget extends StatelessWidget {
  final double healthScore;
  final int ageYears;
  final String assetType;

  const KeyRiskSectionWidget({
    super.key,
    required this.healthScore,
    required this.ageYears,
    this.assetType = '',
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    // Determine key risks based on asset health, age, and type
    final List<Map<String, dynamic>> keyRisks = _getKeyRisks(
      healthScore,
      ageYears,
      assetType,
    );

    // Single card container for all risks
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.spacing(20.0)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(responsive.borderRadius(12.0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: responsive.spacing(8.0),
            offset: Offset(0, responsive.spacing(2.0)),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Key Risks',
            style: TextStyle(
              fontSize: responsive.fontSize(18.0),
              fontWeight: FontWeight.bold,
              color: AssetDetailColors.textPrimary,
            ),
          ),
          if (keyRisks.isEmpty) ...[
            SizedBox(height: responsive.spacing(12.0)),
            Row(
              children: [
                Icon(
                  Icons.check_circle_outline,
                  color: AssetDetailColors.textSecondary,
                  size: responsive.iconSize(18.0),
                ),
                SizedBox(width: responsive.spacing(10.0)),
                Expanded(
                  child: Text(
                    'No major risks identified. Your asset is in good condition.',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14.0),
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            SizedBox(height: responsive.spacing(16.0)),
            // All risks in single list
            ...keyRisks.asMap().entries.map((entry) {
              final index = entry.key;
              final risk = entry.value;
              final isLast = index == keyRisks.length - 1;

              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: responsive.spacing(12.0)),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Outline icon (no color)
                        Padding(
                          padding: EdgeInsets.only(
                            top: responsive.spacing(2.0),
                          ),
                          child: Icon(
                            risk['icon'] as IconData,
                            color: AssetDetailColors.textSecondary,
                            size: responsive.iconSize(21.0),
                          ),
                        ),
                        SizedBox(width: responsive.spacing(12.0)),
                        // Risk content
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      risk['title'] as String,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(15.0),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: responsive.spacing(8.0)),
                                  // Severity badge (only colored element)
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: responsive.spacing(8.0),
                                      vertical: responsive.spacing(3.0),
                                    ),
                                    decoration: BoxDecoration(
                                      color: (risk['severityColor'] as Color)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppDimensions.radiusBadge,
                                      ),
                                    ),
                                    child: Text(
                                      risk['severity'] as String,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(13.0),
                                        fontWeight: FontWeight.w600,
                                        color: risk['severityColor'] as Color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.spacing(4.0)),
                              Text(
                                risk['description'] as String,
                                style: TextStyle(
                                  fontSize: responsive.fontSize(13.0),
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Faded divider between risks (not after last risk)
                  if (!isLast)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: responsive.spacing(12.0),
                      ),
                      child: Divider(
                        color: Colors.grey.withValues(alpha: 0.2),
                        thickness: 1.0,
                        height: 0,
                      ),
                    ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }

  /// Determine key risks based on health score, age and asset type.
  List<Map<String, dynamic>> _getKeyRisks(
    double healthScore,
    int ageYears,
    String assetType,
  ) {
    final risks = <Map<String, dynamic>>[];
    final type = assetType.toLowerCase();

    // ── 1. Health-score based risks ──────────────────────────────────────
    if (healthScore < 4.0) {
      risks.add({
        'title': 'Critical Health Alert',
        'description':
            'Your asset\'s health score is critically low. Immediate service may be required to prevent failure.',
        'icon': Icons.warning_rounded,
        'severity': 'Critical',
        'severityColor': AppColors.error,
      });
    } else if (healthScore < 6.0) {
      risks.add({
        'title': 'Low Health Score',
        'description':
            'Your asset shows signs of wear. Consider scheduling preventive maintenance soon.',
        'icon': Icons.error_outline,
        'severity': 'High',
        'severityColor': AppColors.warning,
      });
    }

    // ── 2. Age-based risks ───────────────────────────────────────────────
    if (ageYears >= 8) {
      risks.add({
        'title': 'Aging Asset',
        'description':
            'This asset is $ageYears years old. Consider replacement planning to avoid unexpected failure.',
        'icon': Icons.schedule,
        'severity': 'Medium',
        'severityColor': AppColors.info,
      });
    } else if (ageYears >= 5) {
      risks.add({
        'title': 'Mid-Lifespan Wear',
        'description':
            'At $ageYears years old, this asset may start needing more frequent maintenance.',
        'icon': Icons.info_outline,
        'severity': 'Low',
        'severityColor': AppColors.info,
      });
    }

    // ── 3. Asset-type-specific risks ─────────────────────────────────────
    if (type.contains('dryer')) {
      risks.add({
        'title': 'Lint Fire Hazard',
        'description':
            'Lint buildup in the exhaust vent is a leading cause of home fires. Clean the vent annually or sooner if drying takes longer than usual.',
        'icon': Icons.local_fire_department_outlined,
        'severity': 'High',
        'severityColor': AppColors.errorDark,
      });
    } else if (type.contains('washer') || type.contains('washing')) {
      risks.add({
        'title': 'Mold & Mildew Risk',
        'description':
            'Front-load washers are prone to mold in the door gasket if not cleaned regularly. Run a drum-clean cycle monthly.',
        'icon': Icons.water_drop_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('refrigerator') || type.contains('fridge')) {
      risks.add({
        'title': 'Compressor Overheating',
        'description':
            'Dirty condenser coils force the compressor to work harder and can shorten its life by years. Clean coils every 6–12 months.',
        'icon': Icons.device_thermostat_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('water heater') || type.contains('heater')) {
      risks.add({
        'title': 'Sediment Buildup',
        'description':
            'Mineral sediment accumulates at the tank bottom, reducing efficiency and risking early failure. Flush annually.',
        'icon': Icons.grain_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
      if (ageYears >= 10) {
        risks.add({
          'title': 'Failure & Flood Risk',
          'description':
              'At $ageYears years, this water heater is past its typical 8–12 year lifespan. A tank failure can cause significant water damage.',
          'icon': Icons.water_damage_outlined,
          'severity': 'High',
          'severityColor': AppColors.error,
        });
      }
    } else if (type.contains('hvac') ||
        type.contains('heating') ||
        type.contains('cooling') ||
        type.contains('furnace') ||
        type.contains('heat pump')) {
      risks.add({
        'title': 'Restricted Airflow',
        'description':
            'A clogged air filter forces the system to overwork, raising energy bills and risking heat exchanger cracks. Replace filter every 1–3 months.',
        'icon': Icons.air_outlined,
        'severity': 'High',
        'severityColor': AppColors.warning,
      });
      if (ageYears >= 15) {
        risks.add({
          'title': 'End-of-Life System',
          'description':
              'HVAC systems typically last 15–20 years. At $ageYears years, budget for replacement to avoid a mid-season failure.',
          'icon': Icons.schedule,
          'severity': 'Medium',
          'severityColor': AppColors.info,
        });
      }
    } else if (type.contains('dishwasher')) {
      risks.add({
        'title': 'Clogged Filter & Spray Arms',
        'description':
            'Food debris clogs the filter and spray arm holes, leading to poor cleaning and potential drain backup. Clean the filter monthly.',
        'icon': Icons.filter_alt_outlined,
        'severity': 'Low',
        'severityColor': AppColors.info,
      });
    } else if (type.contains('range') ||
        type.contains('stove') ||
        type.contains('oven') ||
        type.contains('cooktop')) {
      risks.add({
        'title': 'Grease Fire Risk',
        'description':
            'Grease buildup around burners and inside the oven can ignite. Clean drip pans and interior regularly.',
        'icon': Icons.local_fire_department_outlined,
        'severity': 'High',
        'severityColor': AppColors.error,
      });
    } else if (type.contains('sump pump')) {
      risks.add({
        'title': 'Basement Flood Risk',
        'description':
            'A failed or stuck float switch will let groundwater flood your basement. Test monthly by pouring water into the pit.',
        'icon': Icons.water_damage_outlined,
        'severity': 'High',
        'severityColor': AppColors.error,
      });
    } else if (type.contains('garage door') || type.contains('door opener')) {
      risks.add({
        'title': 'Spring Snap Hazard',
        'description':
            'Worn torsion springs can snap under tension. Lubricate and inspect annually; replace springs before they fail.',
        'icon': Icons.report_problem_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('router') ||
        type.contains('gateway') ||
        type.contains('modem') ||
        type.contains('network')) {
      risks.add({
        'title': 'Security Vulnerability',
        'description':
            'Outdated router firmware exposes your home network to known exploits. Apply firmware updates promptly.',
        'icon': Icons.security_outlined,
        'severity': 'High',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('computer') || type.contains('laptop')) {
      risks.add({
        'title': 'Overheating Risk',
        'description':
            'Dust-clogged fans cause thermal throttling and hardware damage. Clean vents every 6 months.',
        'icon': Icons.thermostat_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('printer')) {
      risks.add({
        'title': 'Printhead Clogging',
        'description':
            'Ink dries in unused printheads, causing streaking and permanent damage. Run a cleaning cycle if unused for 2+ weeks.',
        'icon': Icons.print_outlined,
        'severity': 'Low',
        'severityColor': AppColors.info,
      });
    } else if (type.contains('television') ||
        type.contains('smart tv') ||
        type.endsWith(' tv')) {
      risks.add({
        'title': 'Overheating from Blocked Vents',
        'description':
            'Dust in the rear vents can cause the TV to overheat. Ensure adequate clearance and clean vents periodically.',
        'icon': Icons.air_outlined,
        'severity': 'Low',
        'severityColor': AppColors.info,
      });
    } else if (type.contains('phone') ||
        type.contains('iphone') ||
        type.contains('smartphone') ||
        type.contains('android')) {
      risks.add({
        'title': 'Battery Degradation',
        'description':
            'Lithium-ion batteries lose capacity over time. Avoid extreme temperatures and keep charge between 20–80% to extend lifespan.',
        'icon': Icons.battery_alert_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('tablet') || type.contains('ipad')) {
      risks.add({
        'title': 'Battery Degradation',
        'description':
            'Tablets lose battery capacity with age. Avoid leaving plugged in at 100% for extended periods and keep away from heat.',
        'icon': Icons.battery_alert_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('speaker') ||
        type.contains('audio') ||
        type.contains('soundbar') ||
        type.contains('sound bar')) {
      risks.add({
        'title': 'Driver Wear & Distortion',
        'description':
            'Prolonged high-volume use can degrade speaker drivers. Keep volume reasonable and avoid moisture exposure.',
        'icon': Icons.volume_up_outlined,
        'severity': 'Low',
        'severityColor': AppColors.info,
      });
    } else if (type.contains('smart') ||
        type.contains('alexa') ||
        type.contains('echo') ||
        type.contains('nest') ||
        type.contains('hub')) {
      risks.add({
        'title': 'Firmware & Privacy Risk',
        'description':
            'Smart devices with outdated firmware can be exploited. Enable auto-updates and review connected permissions regularly.',
        'icon': Icons.security_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('gaming') ||
        type.contains('console') ||
        type.contains('playstation') ||
        type.contains('xbox') ||
        type.contains('nintendo')) {
      risks.add({
        'title': 'Overheating & Dust Buildup',
        'description':
            'Gaming consoles generate significant heat. Keep vents clear, clean dust every 3–6 months, and ensure proper ventilation.',
        'icon': Icons.thermostat_outlined,
        'severity': 'Medium',
        'severityColor': AppColors.warning,
      });
    } else if (type.contains('thermostat')) {
      risks.add({
        'title': 'Calibration Drift',
        'description':
            'Thermostat sensors can drift over time, causing inaccurate readings and wasted energy. Verify temperature accuracy annually.',
        'icon': Icons.device_thermostat_outlined,
        'severity': 'Low',
        'severityColor': AppColors.info,
      });
    }

    // ── 4. Overdue service fallback (only if no type-specific risk was added) ──
    if (risks.length < 2 && healthScore < 5.0 && ageYears > 3) {
      risks.add({
        'title': 'Service Overdue',
        'description':
            'Based on the asset\'s age and condition, preventive maintenance is highly recommended.',
        'icon': Icons.build_circle_outlined,
        'severity': 'High',
        'severityColor': AppColors.errorDark,
      });
    }

    return risks;
  }
}

/// A simple grid detail item widget showing a label and value.
class GridDetailItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const GridDetailItem({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: responsive.fontSize(11.5),
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: responsive.spacing(1.5)),
        Text(
          value,
          style: TextStyle(
            fontSize: responsive.fontSize(12.5),
            fontWeight: FontWeight.w600,
            color: valueColor ?? AssetDetailColors.textPrimary,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
