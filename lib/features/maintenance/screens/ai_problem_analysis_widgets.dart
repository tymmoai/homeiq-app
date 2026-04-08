import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/asset_image_widget.dart';
import '../../../core/constants/app_strings.dart';
import '../../../utils/responsive_utils.dart';
import 'ai_fix_models.dart';

/// Widget for issue selection step - displays issue options and description input
class IssueSelectionWidget extends StatelessWidget {
  final String assetName;
  final List<String> issueOptions;
  final Set<String> selectedIssues;
  final String additionalDescription;
  final TextEditingController descriptionController;
  final bool isLoading;
  final VoidCallback onGenerateSolution;
  final Function(String) onIssueToggle;
  final Function(String) onDescriptionChanged;
  final VoidCallback onBookTechnician;
  final Function(String) onVoiceInput;

  const IssueSelectionWidget({
    super.key,
    required this.assetName,
    required this.issueOptions,
    required this.selectedIssues,
    required this.additionalDescription,
    required this.descriptionController,
    required this.isLoading,
    required this.onGenerateSolution,
    required this.onIssueToggle,
    required this.onDescriptionChanged,
    required this.onBookTechnician,
    required this.onVoiceInput,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main Question
        Text(
          "What's wrong with your $assetName?",
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(8)),
        // Instruction
        Text(
          'Select the issue from common problems below',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        // Loading state
        if (isLoading && issueOptions.isEmpty)
          Center(
            child: Column(
              children: [
                SizedBox(height: responsive.spacing(24)),
                CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
                Text(
                  AppStrings.aiPreparingSuggestions,
                  style: TextStyle(
                    fontSize: responsive.fontSize(12),
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          )
        else ...[
          // Vertical list of issue buttons
          Column(
            children: issueOptions.asMap().entries.map((entry) {
              final index = entry.key;
              final issue = entry.value;
              final isSelected = selectedIssues.contains(issue);
              return Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  bottom: index < issueOptions.length - 1 ? 12 : 0,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onIssueToggle(issue),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Text(
                        issue,
                        style: TextStyle(
                          fontSize: responsive.fontSize(15),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
        SizedBox(height: responsive.spacing(24)),
        // Describe in your own words section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Describe in your own words',
              style: TextStyle(
                fontSize: responsive.fontSize(15),
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            VoiceIconButton(assetName: assetName, onVoiceInput: onVoiceInput),
          ],
        ),
        SizedBox(height: responsive.spacing(6)),
        Text(
          "Can't find your issue? Tell us what's happening",
          style: TextStyle(
            fontSize: responsive.fontSize(13),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Container(
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
          child: TextField(
            maxLines: 4,
            minLines: 3,
            cursorColor: AppColors.primary,
            style: TextStyle(
              fontSize: responsive.fontSize(14),
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              hintText:
                  'Example: The $assetName is making a loud humming noise and the back panel feels very hot...',
              hintStyle: TextStyle(
                fontSize: responsive.fontSize(13),
                color: AppColors.textSecondary,
              ),
            ),
            controller: descriptionController,
            onChanged: onDescriptionChanged,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        // Emergency Warning Section with Book Technician integrated
        Container(
          padding: EdgeInsets.all(responsive.spacing(16)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    size: responsive.iconSize(20),
                    color: AppColors.warning,
                  ),
                  SizedBox(width: responsive.spacing(12)),
                  Expanded(
                    child: Text(
                      'Is this an emergency? Gas leak, electrical sparks, or immediate danger to property or person.',
                      style: TextStyle(
                        fontSize: responsive.fontSize(13),
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: responsive.spacing(12)),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: onBookTechnician,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 0,
                  ),
                  child: Text(
                    'Book Technician',
                    style: TextStyle(
                      fontSize: responsive.fontSize(14),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        // Continue Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed:
                (selectedIssues.isEmpty && additionalDescription.trim().isEmpty)
                ? null
                : isLoading
                ? null
                : onGenerateSolution,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
              elevation: 2,
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textOnPrimary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// Widget for analysis loading state
class AnalysisWidget extends StatelessWidget {
  const AnalysisWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(
            top: responsive.spacing(16),
            bottom: responsive.spacing(8),
          ),
          child: Text(
            'Analyzing your issue…',
            style: TextStyle(
              fontSize: responsive.fontSize(16),
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Text(
          AppStrings.aiReviewingDescription,
          style: TextStyle(
            fontSize: responsive.fontSize(12),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        const AiResponseSkeleton(),
      ],
    );
  }
}

/// Widget for displaying AI solution
class SolutionWidget extends StatelessWidget {
  final String aiSolution;
  final bool isLoading;
  final VoidCallback onGenerateDiySteps;
  final VoidCallback onBookTechnician;

  const SolutionWidget({
    super.key,
    required this.aiSolution,
    required this.isLoading,
    required this.onGenerateDiySteps,
    required this.onBookTechnician,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    final lines = aiSolution
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Possible issues',
          style: TextStyle(
            fontSize: responsive.fontSize(24),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(4)),
        Text(
          'Based on your description, here are the likely root causes.',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: responsive.spacing(16)),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(responsive.spacing(16)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final line in lines)
                if (line.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '• ',
                          style: TextStyle(
                            fontSize: responsive.fontSize(14),
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            line.replaceFirst(RegExp(r'^[•\-\*]+\s*'), ''),
                            style: TextStyle(
                              fontSize: responsive.fontSize(14),
                              color: AppColors.textPrimary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(24)),
        Text(
          'How would you like to proceed?',
          style: TextStyle(
            fontSize: responsive.fontSize(15),
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(12)),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : onGenerateDiySteps,
                icon: isLoading
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      )
                    : Icon(Icons.build_rounded, size: responsive.iconSize(18)),
                label: Text(
                  isLoading ? 'Loading...' : 'DIY Guide',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(18),
                  ),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onBookTechnician,
                icon: Icon(
                  Icons.shield_outlined,
                  size: responsive.iconSize(18),
                ),
                label: Text(
                  'Book Technician',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(17),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Widget for DIY guide step display
class DiyGuideWidget extends StatelessWidget {
  final List<DiyStep> diySteps;
  final int currentDiyStepIndex;
  final bool isNotWorkingLoading;
  final VoidCallback onYesNextStep;
  final VoidCallback onNotWorking;
  final VoidCallback? onPreviousStep;

  const DiyGuideWidget({
    super.key,
    required this.diySteps,
    required this.currentDiyStepIndex,
    required this.isNotWorkingLoading,
    required this.onYesNextStep,
    required this.onNotWorking,
    this.onPreviousStep,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);
    if (diySteps.isEmpty) {
      return const SizedBox.shrink();
    }

    final step = diySteps[currentDiyStepIndex];
    final total = diySteps.length;
    final index = currentDiyStepIndex + 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Troubleshooting guide',
              style: TextStyle(
                fontSize: responsive.fontSize(24),
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(12)),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: index / total,
            minHeight: 6,
            backgroundColor: AppColors.gray400,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        Container(
          padding: EdgeInsets.all(responsive.spacing(16)),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: TextStyle(
                  fontSize: responsive.fontSize(16),
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              // Duration and Risk Level Row
              if (step.duration != null || step.riskLevel != null) ...[
                Row(
                  children: [
                    if (step.duration != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: responsive.iconSize(14),
                              color: AppColors.primary,
                            ),
                            SizedBox(width: responsive.spacing(4)),
                            Text(
                              step.duration!,
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: responsive.spacing(8)),
                    ],
                    if (step.riskLevel != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getRiskColor(
                            step.riskLevel!,
                          ).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusBadge,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              size: responsive.iconSize(14),
                              color: _getRiskColor(step.riskLevel!),
                            ),
                            SizedBox(width: responsive.spacing(4)),
                            Text(
                              '${step.riskLevel} Risk',
                              style: TextStyle(
                                fontSize: responsive.fontSize(12),
                                fontWeight: FontWeight.w600,
                                color: _getRiskColor(step.riskLevel!),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: responsive.spacing(12)),
              ],
              // Tools Needed Section
              if (step.toolsNeeded != null && step.toolsNeeded!.isNotEmpty) ...[
                Container(
                  padding: EdgeInsets.all(responsive.spacing(12)),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundGray50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gray200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.build_outlined,
                            size: responsive.iconSize(16),
                            color: AppColors.textPrimary,
                          ),
                          SizedBox(width: responsive.spacing(6)),
                          Text(
                            'Tools You\'ll Need',
                            style: TextStyle(
                              fontSize: responsive.fontSize(13),
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.spacing(8)),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: step.toolsNeeded!
                            .map(
                              (tool) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusBadge,
                                  ),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(
                                      alpha: 0.3,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  tool,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(11),
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: responsive.spacing(12)),
              ],
              Text(
                step.description,
                style: TextStyle(
                  fontSize: responsive.fontSize(13),
                  color: AppColors.textSecondary,
                ),
              ),
              SizedBox(height: responsive.spacing(12)),
              if (step.instructions.isNotEmpty) ...[
                Text(
                  'Do this:',
                  style: TextStyle(
                    fontSize: responsive.fontSize(13),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: responsive.spacing(6)),
                for (final item in step.instructions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Icon(
                            Icons.circle,
                            size: responsive.iconSize(6),
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(width: responsive.spacing(8)),
                        Expanded(
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: responsive.fontSize(13),
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (step.safetyNote != null &&
                  step.safetyNote!.trim().isNotEmpty) ...[
                SizedBox(height: responsive.spacing(12)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: responsive.iconSize(18),
                      color: AppColors.warning,
                    ),
                    SizedBox(width: responsive.spacing(8)),
                    Expanded(
                      child: Text(
                        step.safetyNote!,
                        style: TextStyle(
                          fontSize: responsive.fontSize(13),
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: responsive.spacing(20)),
        Text(
          'Did this step help?',
          style: TextStyle(
            fontSize: responsive.fontSize(14),
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: responsive.spacing(10)),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onYesNextStep,
                icon: Icon(Icons.check, size: responsive.iconSize(20)),
                label: Text(
                  index < total ? 'Yes, next step' : 'Issue resolved',
                  style: TextStyle(
                    fontSize: responsive.fontSize(16),
                    fontWeight: FontWeight.w600,
                    color: AppColors.textOnPrimary,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textOnPrimary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(14),
                  ),
                  minimumSize: const Size(0, 48),
                  elevation: 0,
                ),
              ),
            ),
            SizedBox(width: responsive.spacing(12)),
            Expanded(
              child: ElevatedButton(
                onPressed: isNotWorkingLoading ? null : onNotWorking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.symmetric(
                    vertical: responsive.spacing(14),
                  ),
                  minimumSize: const Size(0, 48),
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                  elevation: 0,
                ),
                child: isNotWorkingLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: responsive.spacing(8)),
                          Text(
                            'Loading...',
                            style: TextStyle(
                              fontSize: responsive.fontSize(16),
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Not working',
                        style: TextStyle(
                          fontSize: responsive.fontSize(16),
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
              ),
            ),
          ],
        ),
        SizedBox(height: responsive.spacing(10)),
        if (onPreviousStep != null)
          TextButton.icon(
            onPressed: onPreviousStep,
            icon: Icon(
              Icons.chevron_left,
              size: responsive.iconSize(20),
              color: AppColors.textPrimary,
            ),
            label: Text(
              'Previous step',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: responsive.fontSize(16),
              ),
            ),
          ),
      ],
    );
  }

  Color _getRiskColor(String riskLevel) {
    final risk = riskLevel.toLowerCase();
    if (risk.contains('low')) {
      return AppColors.success;
    } else if (risk.contains('medium')) {
      return AppColors.warningOrange;
    } else if (risk.contains('high')) {
      return AppColors.error;
    }
    return AppColors.textSecondary;
  }
}

/// Voice input button widget with animation
class VoiceIconButton extends StatefulWidget {
  final Function(String) onVoiceInput;
  final String assetName;

  const VoiceIconButton({
    super.key,
    required this.onVoiceInput,
    required this.assetName,
  });

  @override
  State<VoiceIconButton> createState() => _VoiceIconButtonState();
}

class _VoiceIconButtonState extends State<VoiceIconButton>
    with TickerProviderStateMixin {
  // ── Animation controllers ──────────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _ring1Controller;
  late AnimationController _ring2Controller;
  late AnimationController _ring3Controller;
  late Animation<double> _pulseAnimation;
  late Animation<double> _ring1Animation;
  late Animation<double> _ring2Animation;
  late Animation<double> _ring3Animation;

  // ── State ─────────────────────────────────────────────────────────────
  bool _isInitializing = false; // brief period while STT is setting up
  bool _isRecording = false;
  double _soundLevel = 0.0; // 0.0–1.0 normalised sound level

  // ── Speech-to-Text ─────────────────────────────────────────────────────
  final SpeechToText _speech = SpeechToText();
  bool _speechInitialized = false;

  // ── Ring sizes ─────────────────────────────────────────────────────────
  static const double _btnSize = 44.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    // Three rings staggered in phase so they all look independent
    _ring1Controller = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    );
    _ring2Controller = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    );
    _ring3Controller = AnimationController(
      duration: const Duration(milliseconds: 1700),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _ring1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ring1Controller, curve: Curves.easeOut),
    );
    _ring2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ring2Controller, curve: Curves.easeOut),
    );
    _ring3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ring3Controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _pulseController.dispose();
    _ring1Controller.dispose();
    _ring2Controller.dispose();
    _ring3Controller.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  void _startAnimations() {
    _pulseController.repeat(reverse: true);
    _ring1Controller.repeat();
    // Stagger ring 2 & 3 so they feel organic, not all starting together
    Future<void>.delayed(const Duration(milliseconds: 350), () {
      if (mounted && _isRecording) _ring2Controller.repeat();
    });
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (mounted && _isRecording) _ring3Controller.repeat();
    });
  }

  void _stopAnimations() {
    _pulseController
      ..stop()
      ..reset();
    _ring1Controller
      ..stop()
      ..reset();
    _ring2Controller
      ..stop()
      ..reset();
    _ring3Controller
      ..stop()
      ..reset();
  }

  void _stopListening() {
    _speech.stop();
    if (!mounted) return;
    setState(() {
      _isRecording = false;
      _soundLevel = 0.0;
    });
    _stopAnimations();
  }

  Future<void> _startListening() async {
    setState(() => _isInitializing = true);

    // speech_to_text.initialize() handles mic + speech-recognition permissions
    // internally on both Android and iOS — no double-prompt risk.
    if (!_speechInitialized) {
      _speechInitialized = await _speech.initialize(
        onStatus: (status) {
          // Platform signals "done" or "notListening" when it naturally stops
          if ((status == 'done' || status == 'notListening') && _isRecording) {
            _stopListening();
          }
        },
        onError: (error) {
          if (_isRecording) _stopListening();
        },
      );
    }

    if (!mounted) return;

    if (!_speechInitialized) {
      setState(() => _isInitializing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Speech recognition is not available. '
            'Please check your microphone permissions in Settings.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() {
      _isInitializing = false;
      _isRecording = true;
    });
    _startAnimations();

    await _speech.listen(
      onResult: (result) {
        if (!mounted) return;
        if (result.recognizedWords.isNotEmpty) {
          widget.onVoiceInput(result.recognizedWords);
        }
        // Auto-stop once the platform signals a final recognised result
        if (result.finalResult) {
          _stopListening();
        }
      },
      onSoundLevelChange: (level) {
        if (!mounted) return;
        // Platform emits roughly –2 dB (silence) to +10 dB (loud speech)
        final normalised = ((level + 2) / 12).clamp(0.0, 1.0);
        setState(() => _soundLevel = normalised);
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3), // auto-stops 3 s after silence
      // omit localeId → uses device's active speech-recognition locale
      listenOptions: SpeechListenOptions(partialResults: true),
    );
  }

  Future<void> _handleVoiceInput() async {
    if (_isInitializing) return; // swallow double-taps during setup
    if (_isRecording) {
      _stopListening();
      return;
    }
    await _startListening();
  }

  // ── Animated ring helper ───────────────────────────────────────────────

  Widget _buildRing(Animation<double> anim, Color color, double maxExpand) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final t = anim.value;
        // Sound level makes rings expand further when user is actually speaking
        final expand = maxExpand * (0.5 + _soundLevel * 0.5);
        return Opacity(
          opacity: (1.0 - t).clamp(0.0, 1.0),
          child: Container(
            width: _btnSize + expand * t,
            height: _btnSize + expand * t,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveUtils(context);

    final Color activeColor = AppColors.errorMaterialAccent;
    final Color idleColor = AppColors.primary;
    final Color btnColor = _isInitializing
        ? idleColor.withValues(alpha: 0.6)
        : _isRecording
            ? activeColor
            : idleColor;

    return GestureDetector(
      onTap: _handleVoiceInput,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        // Extra room for ripple rings so they don't clip the gesture detector
        width: _btnSize + 40,
        height: _btnSize + 40,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Sound-reactive concentric rings (visible only while recording)
            if (_isRecording) ...[
              _buildRing(
                _ring1Animation,
                activeColor.withValues(alpha: 0.9),
                36,
              ),
              _buildRing(
                _ring2Animation,
                activeColor.withValues(alpha: 0.6),
                52,
              ),
              _buildRing(
                _ring3Animation,
                activeColor.withValues(alpha: 0.35),
                68,
              ),
            ],

            // ── Main circular button ───────────────────────────────────────
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (_, __) {
                return Transform.scale(
                  scale: _isRecording ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: _btnSize,
                    height: _btnSize,
                    decoration: BoxDecoration(
                      color: btnColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: btnColor.withValues(
                            alpha: _isRecording ? 0.55 : 0.25,
                          ),
                          blurRadius: _isRecording
                              ? 14 + _soundLevel * 10
                              : 8,
                          spreadRadius: _isRecording ? 2 : 0,
                        ),
                      ],
                    ),
                    child: _isInitializing
                        // Spinner while permissions are being requested / STT inits
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Icon(
                            _isRecording ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: responsive.iconSize(20),
                          ),
                  ),
                );
              },
            ),

            // ── "Listening…" label below the button ───────────────────────
            if (_isRecording)
              Positioned(
                bottom: 0,
                child: Text(
                  'Listening…',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: activeColor,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
