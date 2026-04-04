import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../utils/responsive_utils.dart';
import '../../ai_fix_models.dart';

class TechnicianSelectionWidget extends StatefulWidget {
  final List<TechnicianOption> technicians;
  final bool isCombinedFlow;
  final TechnicianOption? selectedTechnician;
  final void Function(TechnicianOption) onSelectTechnician;
  final VoidCallback? onContinue; // For combined flow

  const TechnicianSelectionWidget({
    super.key,
    required this.technicians,
    required this.isCombinedFlow,
    this.selectedTechnician,
    required this.onSelectTechnician,
    this.onContinue,
  });

  @override
  State<TechnicianSelectionWidget> createState() =>
      _TechnicianSelectionWidgetState();
}

class _TechnicianSelectionWidgetState extends State<TechnicianSelectionWidget> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  TechnicianOption? _localSelectedTechnician;

  @override
  void initState() {
    super.initState();
    _localSelectedTechnician = widget.selectedTechnician;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Technician',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          widget.isCombinedFlow
              ? 'Choose a certified professional to install the parts.'
              : 'Choose a certified professional for your service.',
          style: TextStyle(fontSize: responsive.fontSize(14), color: AppColors.textSecondary),
        ),
        SizedBox(height: responsive.spacing(20)),
        for (final tech in widget.technicians)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _localSelectedTechnician = tech;
                });
                widget.onSelectTechnician(tech);
                // If not combined flow, auto-navigate
                if (!widget.isCombinedFlow) {
                  // Navigation is handled by parent
                }
              },
              child: Container(
                padding: EdgeInsets.all(responsive.spacing(16)),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: _localSelectedTechnician == tech
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Center(
                        child: Text(
                          tech.name.substring(0, 1),
                          style: TextStyle(
                            fontSize: responsive.fontSize(20),
                            fontWeight: FontWeight.w600,
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
                            tech.name,
                            style: TextStyle(
                              fontSize: responsive.fontSize(15),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: responsive.spacing(4)),
                          Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: responsive.iconSize(14),
                                color: AppColors.warningGold,
                              ),
                              SizedBox(width: responsive.spacing(4)),
                              Text(
                                '${tech.rating} • ${tech.experienceYears} yrs experience',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: responsive.spacing(12)),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${tech.fee.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: responsive.fontSize(16),
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: responsive.spacing(2)),
                        Text(
                          'Service Fee',
                          style: TextStyle(
                            fontSize: responsive.fontSize(11),
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    if (_localSelectedTechnician == tech) ...[
                      SizedBox(width: responsive.spacing(8)),
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primary,
                        size: responsive.iconSize(24),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        // Add spacing for combined flow positioned button
        if (widget.isCombinedFlow)
          SizedBox(height: responsive.spacing(80)),
        ],
      ),
    );
  }
}