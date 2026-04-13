// DIY Maintenance Screen

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../services/api_client.dart';
import '../../../services/diy_steps_service.dart' show DiyStep;
import '../../../utils/responsive_utils.dart';
import '../../shared/models/maintenance_models.dart';
import '../widgets/diy_loading_animation.dart';

class DIYMaintenanceScreen extends StatefulWidget {
  final Reminder reminder;
  final VoidCallback onMarkComplete;

  const DIYMaintenanceScreen({
    super.key,
    required this.reminder,
    required this.onMarkComplete,
  });

  @override
  State<DIYMaintenanceScreen> createState() => _DIYMaintenanceScreenState();
}

class _DIYMaintenanceScreenState extends State<DIYMaintenanceScreen> {
  ResponsiveUtils get responsive => ResponsiveUtils(context);
  int _currentStep = 0;
  List<DiyStep> _diySteps = [];
  bool _isLoading = false;
  String? _error;
  List<String> _allToolsNeeded = [];
  String _overallDuration = '';
  String _overallRiskLevel = '';

  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = _getVideoIdForTask(widget.reminder.taskName);
    _generateDIYSteps();
  }

  Future<void> _openYouTubeVideo() async {
    if (_videoId == null) return;

    final youtubeUrl = 'https://www.youtube.com/watch?v=$_videoId';
    final uri = Uri.parse(youtubeUrl);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: try in-app browser
        await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } on Object catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to open video. Please try again.'),
          ),
        );
      }
    }
  }

  String? _getVideoIdForTask(String taskName) {
    final map = <String, String>{
      'AC Filter Replacement': 'UXv8pKiMWvQ',
      'Evaporator Coil Cleaning': 'e-LQe4ToRcg',
      'Filter Cleaning': 'ngQuIKpd064',
      'Door Gasket Cleaning': 'p5Acm_MaEF4',
      'Tank Flushing': 'FzbtXh0qRLg',
      'Heating Element Check': 'PVOJRWceWp0',
      'Interior Deep Cleaning': 'kEwvNgWIZAU',
      'Vent Filter Inspection': 'OMlKdK6YHZw',
    };
    return map[taskName];
  }

  final _apiClient = ApiClient();

  Future<void> _generateDIYSteps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Generate AI-powered DIY steps via backend
      final response = await _apiClient.post(
        '/ai/generate-diy-steps',
        body: {
          'taskName': widget.reminder.taskName,
          'assetName': widget.reminder.assetName,
          'assetLocation': widget.reminder.assetLocation ?? 'home',
          'whyItMatters': widget.reminder.whyItMatters,
          'estimatedEffort': widget.reminder.estimatedEffort,
        },
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch DIY steps from backend');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['data'] ?? data;
      final stepsJson = content['steps'] as List<dynamic>? ?? [];

      final parsedSteps = <DiyStep>[];
      final allTools = <String>{};

      for (final step in stepsJson) {
        final s = step as Map<String, dynamic>;
        final tools = s['tools'] != null
            ? List<String>.from(s['tools'])
            : <String>[];
        allTools.addAll(tools);

        parsedSteps.add(
          DiyStep(
            title: s['title'] as String? ?? '',
            description: s['description'] as String? ?? '',
            instructions: List<String>.from(s['instructions'] ?? []),
            safetyNote: (s['safety'] as String?)?.isEmpty == true
                ? null
                : s['safety'] as String?,
            duration: s['duration'] as String?,
            riskLevel: s['risk'] as String?,
            toolsNeeded: tools.isEmpty ? null : tools,
          ),
        );
      }

      // Ensure we have exactly 3 steps
      if (parsedSteps.isEmpty) {
        throw Exception('Failed to parse DIY steps');
      }

      final finalSteps = parsedSteps.length < 3
          ? [
              ...parsedSteps,
              ..._getEnhancedFallbackSteps().take(3 - parsedSteps.length),
            ]
          : parsedSteps.take(3).toList();

      // Calculate overall duration and risk
      _overallDuration = _calculateOverallDuration(finalSteps);
      _overallRiskLevel = _calculateOverallRisk(finalSteps);

      setState(() {
        _diySteps = finalSteps;
        _allToolsNeeded = allTools.toList();
        _isLoading = false;
      });

      AppLogger.info(
        'DIY Steps Generated Successfully! ${finalSteps.length} steps',
        tag: 'DiyMaintenance',
      );
    } on Object catch (e) {
      AppLogger.error(
        'DIY Steps API Error: $e',
        tag: 'DiyMaintenance',
        error: e,
      );
      setState(() {
        _error = 'Using enhanced maintenance guide';
        _isLoading = false;
        _setFallbackSteps();
      });
    }
  }

  void _setFallbackSteps() {
    _diySteps = _getEnhancedFallbackSteps();
    _allToolsNeeded = [
      'Screwdriver',
      'Cleaning cloth',
      'Gloves',
      'Vacuum cleaner',
    ];
  }

  List<DiyStep> _getEnhancedFallbackSteps() {
    // Task-specific fallback steps
    final taskName = widget.reminder.taskName.toLowerCase();

    if (taskName.contains('filter')) {
      return [
        DiyStep(
          title: 'Locate and Access Filter',
          description: 'Find and safely access the filter compartment.',
          instructions: [
            'Turn off power to the appliance at the circuit breaker or unplug it completely.',
            'Locate the filter access panel (typically front-facing or top-mounted on AC units).',
            'Remove the access panel by lifting or unscrewing (refer to your model\'s manual).',
            'Note the filter orientation before removal for proper reinstallation.',
          ],
          toolsNeeded: ['Screwdriver (if needed)', 'Flashlight'],
          duration: '5-10 minutes',
          riskLevel: 'Low',
          safetyNote:
              'Always ensure power is completely off before accessing internal components.',
        ),
        DiyStep(
          title: 'Remove and Clean Filter',
          description: 'Carefully remove the filter and clean it thoroughly.',
          instructions: [
            'Gently slide or pull the filter out of its housing.',
            'Vacuum both sides of the filter using a soft brush attachment to remove loose debris.',
            'If washable, rinse the filter with lukewarm water in the direction opposite to airflow.',
            'For stubborn dirt, use mild dish soap and a soft brush, then rinse thoroughly.',
            'Allow the filter to air dry completely (2-3 hours) before reinstallation.',
          ],
          toolsNeeded: [
            'Vacuum cleaner',
            'Soft brush',
            'Mild soap',
            'Clean water',
          ],
          duration: '10-15 minutes (plus drying time)',
          riskLevel: 'Low',
        ),
        DiyStep(
          title: 'Reinstall and Test',
          description: 'Properly reinstall the filter and verify operation.',
          instructions: [
            'Ensure the filter is completely dry before reinstallation.',
            'Insert the filter back into the housing in the correct orientation (check airflow arrows).',
            'Secure the access panel back in place.',
            'Restore power to the appliance.',
            'Run the appliance for 5 minutes and check for proper airflow and any unusual noises.',
          ],
          toolsNeeded: ['Screwdriver (if needed)'],
          duration: '5 minutes',
          riskLevel: 'Low',
        ),
      ];
    } else if (taskName.contains('coil') || taskName.contains('condenser')) {
      return [
        DiyStep(
          title: 'Prepare and Access Coils',
          description: 'Safely access the evaporator or condenser coils.',
          instructions: [
            'Turn off power at the circuit breaker and unplug the unit.',
            'Remove the access panel using appropriate screwdriver.',
            'Take photos before starting for reference during reassembly.',
            'Locate the coils (usually behind the filter or on the exterior unit).',
          ],
          toolsNeeded: ['Phillips screwdriver', 'Camera/phone', 'Flashlight'],
          duration: '10-15 minutes',
          riskLevel: 'Medium',
          safetyNote:
              'Wear safety glasses and gloves. Coil fins are sharp and can cause cuts.',
        ),
        DiyStep(
          title: 'Clean the Coils',
          description: 'Remove debris and buildup from coils.',
          instructions: [
            'Use a soft brush or coil brush to gently remove visible debris between fins.',
            'Vacuum the coils using a brush attachment to remove loose dirt.',
            'Apply coil cleaner spray following manufacturer instructions (available at hardware stores).',
            'Let the cleaner sit for the recommended time (usually 5-10 minutes).',
            'Rinse gently with water or wipe with damp cloth if accessible.',
          ],
          toolsNeeded: [
            'Coil cleaning brush',
            'Vacuum',
            'Coil cleaner spray',
            'Spray bottle',
          ],
          duration: '20-30 minutes',
          riskLevel: 'Medium',
        ),
        DiyStep(
          title: 'Reassemble and Test',
          description: 'Put everything back together and verify operation.',
          instructions: [
            'Allow coils to dry completely (30-60 minutes).',
            'Reinstall access panels using your reference photos.',
            'Restore power and run the appliance.',
            'Monitor for 10-15 minutes, checking for proper cooling and airflow.',
            'Schedule professional service if performance doesn\'t improve.',
          ],
          toolsNeeded: ['Screwdriver'],
          duration: '10 minutes',
          riskLevel: 'Low',
        ),
      ];
    }

    // Default generic but enhanced fallback
    return [
      DiyStep(
        title: 'Safety First and Preparation',
        description: 'Ensure safe working conditions before starting.',
        instructions: [
          'Turn off power to the appliance at the circuit breaker or unplug from outlet.',
          'Wait 5 minutes for any electrical charge to dissipate.',
          'Gather all necessary tools and materials listed above.',
          'Clear a 3-foot radius around the appliance for safe working space.',
          'Read your appliance manual\'s maintenance section if available.',
        ],
        toolsNeeded: ['Screwdriver', 'Flashlight', 'Gloves'],
        duration: '5-10 minutes',
        riskLevel: 'Low',
        safetyNote: 'Never work on an appliance while it\'s powered on.',
      ),
      DiyStep(
        title: 'Perform ${widget.reminder.taskName}',
        description: 'Complete the specific maintenance task.',
        instructions: [
          'Follow the manufacturer\'s recommended procedure for ${widget.reminder.taskName}.',
          'Work carefully and methodically, taking photos if disassembly is required.',
          'Clean or replace components as needed using appropriate cleaning materials.',
          'Inspect for any signs of wear, damage, or unusual buildup.',
          'Make note of any issues that may require professional attention.',
        ],
        toolsNeeded: ['Task-specific tools', 'Cleaning supplies'],
        duration: '15-30 minutes',
        riskLevel: 'Low',
      ),
      DiyStep(
        title: 'Reassemble and Verify',
        description: 'Complete the task and ensure proper operation.',
        instructions: [
          'Reinstall any removed components in reverse order of removal.',
          'Double-check all connections and fasteners are secure.',
          'Clean the work area and properly dispose of any waste materials.',
          'Restore power to the appliance.',
          'Run the appliance through a test cycle and monitor for 10-15 minutes.',
          'Verify normal operation with no unusual sounds, smells, or behaviors.',
        ],
        toolsNeeded: ['Screwdriver', 'Cleaning cloth'],
        duration: '10-15 minutes',
        riskLevel: 'Low',
      ),
    ];
  }

  void _handleNext() {
    if (_currentStep < _diySteps.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _handlePrevious() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _handleComplete() {
    widget.onMarkComplete();
    context.pop();
  }

  void _handleBookTechnician() {
    // Gather DIY context and navigate directly to technician booking
    final completedStepsTitles = _diySteps
        .take(_currentStep)
        .map((s) => s.title)
        .toList();
    final currentStepTitle = _diySteps.isNotEmpty
        ? _diySteps[_currentStep].title
        : '';

    context.pushNamed(
      'ai-fix-problem',
      extra: {
        'name': widget.reminder.assetName,
        'assetId': widget.reminder.assetId,
        'type': widget.reminder.taskName,
        'fromDiy': true,
        'diyContext': {
          'taskName': widget.reminder.taskName,
          'taskDescription': widget.reminder.taskDescription,
          'currentStep': _currentStep + 1,
          'totalSteps': _diySteps.length,
          'currentStepTitle': currentStepTitle,
          'completedSteps': completedStepsTitles,
          'toolsUsed': _allToolsNeeded,
          'overallDuration': _overallDuration,
          'overallRiskLevel': _overallRiskLevel,
          'stepsDetail': _diySteps.map((s) => s.toJson()).toList(),
        },
      },
    );
  }

  double get _progressPercentage {
    if (_diySteps.isEmpty) return 0;
    return ((_currentStep + 1) / _diySteps.length) * 100;
  }

  String _calculateOverallDuration(List<DiyStep> steps) {
    if (steps.isEmpty) return '';
    // Return first step's duration or calculate total
    if (steps.first.duration != null) {
      return steps.first.duration!;
    }
    return '';
  }

  String _calculateOverallRisk(List<DiyStep> steps) {
    if (steps.isEmpty) return '';
    // Find highest risk level
    int highestRisk = 0;
    for (final step in steps) {
      if (step.riskLevel != null) {
        final risk = step.riskLevel!.toLowerCase();
        if (risk.contains('high')) {
          return 'High Risk';
        } else if (risk.contains('medium') && highestRisk < 2) {
          highestRisk = 2;
        } else if (risk.contains('low') && highestRisk < 1) {
          highestRisk = 1;
        }
      }
    }
    if (highestRisk == 2) return 'Medium Risk';
    if (highestRisk == 1) return 'Low Risk';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final step = _diySteps.isNotEmpty ? _diySteps[_currentStep] : null;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray200,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.reminder.taskName,
              style: TextStyle(
                fontSize: responsive.fontSize(16),
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: responsive.spacing(2)),
            Text(
              '${widget.reminder.assetName} • ${widget.reminder.assetLocation ?? 'Home'}',
              style: TextStyle(
                fontSize: responsive.fontSize(12),
                color: Colors.white.withValues(alpha: 0.85),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(responsive.spacing(20)),
                child: DIYLoadingAnimation(
                  taskName: widget.reminder.taskName,
                  assetName: widget.reminder.assetName,
                ),
              ),
            )
          : Column(
              children: [
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(responsive.spacing(20)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: responsive.spacing(4)),
                        // Duration & Risk cards row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(responsive.spacing(12)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
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
                                          Icons.access_time,
                                          size: responsive.iconSize(16),
                                          color: Colors.grey.shade600,
                                        ),
                                        SizedBox(width: responsive.spacing(4)),
                                        Text(
                                          'Duration',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: responsive.spacing(4)),
                                    Text(
                                      _overallDuration.isEmpty
                                          ? widget.reminder.estimatedEffort
                                          : _overallDuration,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(14),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: responsive.spacing(12)),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.all(responsive.spacing(12)),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.08,
                                      ),
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
                                          Icons.warning_amber_outlined,
                                          size: responsive.iconSize(16),
                                          color: Colors.grey.shade700,
                                        ),
                                        SizedBox(width: responsive.spacing(4)),
                                        Text(
                                          'Risk Level',
                                          style: TextStyle(
                                            fontSize: responsive.fontSize(12),
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: responsive.spacing(4)),
                                    Text(
                                      _overallRiskLevel.isEmpty
                                          ? '${widget.reminder.riskLevel}/10'
                                          : _overallRiskLevel,
                                      style: TextStyle(
                                        fontSize: responsive.fontSize(14),
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        // Video Tutorial
                        Container(
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
                              Row(
                                children: [
                                  Icon(
                                    Icons.video_library,
                                    size: responsive.iconSize(20),
                                    color: AppColors.textPrimary,
                                  ),
                                  SizedBox(width: responsive.spacing(8)),
                                  Text(
                                    'Video Tutorial',
                                    style: TextStyle(
                                      fontSize: responsive.fontSize(16),
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: responsive.spacing(12)),
                              if (_videoId != null)
                                GestureDetector(
                                  onTap: _openYouTubeVideo,
                                  child: Stack(
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              'https://img.youtube.com/vi/$_videoId/maxresdefault.jpg',
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Image.network(
                                                  'https://img.youtube.com/vi/$_videoId/0.jpg',
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          color: Colors
                                                              .grey
                                                              .shade200,
                                                          child: const Center(
                                                            child: Icon(
                                                              Icons
                                                                  .play_circle_outline,
                                                              size: 48,
                                                              color:
                                                                  Colors.grey,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      // Play button overlay
                                      Positioned.fill(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            color: Colors.black.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                          child: Center(
                                            child: Container(
                                              width: 64,
                                              height: 64,
                                              decoration: const BoxDecoration(
                                                color: Colors.red,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.play_arrow,
                                                color: Colors.white,
                                                size: 32,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Text(
                                  'Video coming soon for this task.',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(13),
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        SizedBox(height: responsive.spacing(16)),
                        // Tools needed
                        if (_allToolsNeeded.isNotEmpty)
                          Container(
                            padding: EdgeInsets.all(responsive.spacing(12)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
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
                                  'Tools You Will Need',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(8)),
                                ..._allToolsNeeded.map(
                                  (t) => Padding(
                                    padding: EdgeInsets.symmetric(
                                      vertical: responsive.spacing(4),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          margin: const EdgeInsets.only(
                                            top: 6,
                                            right: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            t,
                                            style: TextStyle(
                                              fontSize: responsive.fontSize(13),
                                              color: AppColors.inputDark,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        SizedBox(height: responsive.spacing(16)),
                        // Step progress header
                        if (_diySteps.isNotEmpty) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Step ${_currentStep + 1} of ${_diySteps.length}',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              Text(
                                '${_progressPercentage.round()}% Complete',
                                style: TextStyle(
                                  fontSize: responsive.fontSize(12),
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: responsive.spacing(6)),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_currentStep + 1) / _diySteps.length,
                              minHeight: 4,
                              backgroundColor: AppColors.divider,
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          SizedBox(height: responsive.spacing(16)),
                        ],
                        // Step card
                        if (_error != null && _diySteps.isEmpty)
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: responsive.fontSize(13),
                            ),
                          )
                        else if (step != null)
                          Container(
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
                                // Step title only (no pill)
                                Text(
                                  step.title,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(18),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(8)),
                                // Step description
                                Text(
                                  step.description,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                // Step instructions
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: step.instructions
                                      .asMap()
                                      .entries
                                      .map(
                                        (e) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10.0,
                                          ),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    '${e.key + 1}',
                                                    style: TextStyle(
                                                      fontSize: responsive
                                                          .fontSize(13),
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              SizedBox(
                                                width: responsive.spacing(12),
                                              ),
                                              Expanded(
                                                child: Padding(
                                                  padding: EdgeInsets.only(
                                                    top: responsive.spacing(2),
                                                  ),
                                                  child: Text(
                                                    e.value,
                                                    style: TextStyle(
                                                      fontSize: responsive
                                                          .fontSize(15),
                                                      color:
                                                          AppColors.textPrimary,
                                                      height: 1.6,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                      .toList(),
                                ),
                                if (step.safetyNote != null) ...[
                                  SizedBox(height: responsive.spacing(16)),
                                  Container(
                                    padding: EdgeInsets.all(
                                      responsive.spacing(12),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.warningYellowBg,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.warningMaterial,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.warning_amber_rounded,
                                          size: 20,
                                          color: AppColors.warningMaterialDark,
                                        ),
                                        SizedBox(width: responsive.spacing(10)),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Safety Warning',
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize(
                                                    14,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors
                                                      .warningMaterialDark,
                                                ),
                                              ),
                                              SizedBox(
                                                height: responsive.spacing(4),
                                              ),
                                              Text(
                                                step.safetyNote!,
                                                style: TextStyle(
                                                  fontSize: responsive.fontSize(
                                                    14,
                                                  ),
                                                  color: AppColors.brown,
                                                  height: 1.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        // Step dots indicator
                        if (_diySteps.length > 1) ...[
                          SizedBox(height: responsive.spacing(16)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_diySteps.length, (index) {
                              final isActive = index == _currentStep;
                              return Container(
                                width: isActive ? 20 : 8,
                                height: 4,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? AppColors.textPrimary
                                      : AppColors.textDisabled,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ],
                        // Book Technician â€” only on last step
                        if (_diySteps.isNotEmpty &&
                            _currentStep == _diySteps.length - 1) ...[
                          SizedBox(height: responsive.spacing(28)),
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(responsive.spacing(20)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.06,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                  spreadRadius: 0,
                                ),
                              ],
                              border: Border.all(
                                color: AppColors.primary.withValues(
                                  alpha: 0.08,
                                ),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Technician icon
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary10,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    Icons.engineering_rounded,
                                    size: responsive.iconSize(32),
                                    color: AppColors.primary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(16)),
                                // Title
                                Text(
                                  'Book a Technician',
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(20),
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                SizedBox(height: responsive.spacing(8)),
                                // Description
                                Text(
                                  'Can\'t fix "${widget.reminder.taskName}" yourself? '
                                  'No worries! We\'ll connect you with a certified technician '
                                  'who can handle it for you.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: responsive.fontSize(14),
                                    color: Colors.grey[600],
                                    height: 1.5,
                                  ),
                                ),
                                // DIY progress card
                                if (_currentStep > 0) ...[
                                  SizedBox(height: responsive.spacing(16)),
                                  Container(
                                    width: double.infinity,
                                    padding: EdgeInsets.all(
                                      responsive.spacing(14),
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.backgroundGray200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Your DIY progress will be shared:',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.inputDark,
                                          ),
                                        ),
                                        SizedBox(
                                          height: responsive.spacing(10),
                                        ),
                                        ..._diySteps
                                            .take(_currentStep)
                                            .map(
                                              (s) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 6,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons.check_circle,
                                                      size: 18,
                                                      color: AppColors
                                                          .successMaterial,
                                                    ),
                                                    SizedBox(
                                                      width: responsive.spacing(
                                                        8,
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        s.title,
                                                        style: TextStyle(
                                                          fontSize: responsive
                                                              .fontSize(14),
                                                          color: AppColors
                                                              .inputDark,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 2,
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.radio_button_unchecked,
                                                size: 18,
                                                color: AppColors.primary,
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  'Stuck on: ${_diySteps[_currentStep].title}',
                                                  style: TextStyle(
                                                    fontSize: responsive
                                                        .fontSize(14),
                                                    fontWeight: FontWeight.w500,
                                                    color: AppColors.primary,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                SizedBox(height: responsive.spacing(20)),
                                // Find & Book button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _handleBookTechnician,
                                    icon: const Icon(
                                      Icons.calendar_month_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Find & Book a Technician',
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(
                                        vertical: responsive.spacing(14),
                                      ),
                                      textStyle: TextStyle(
                                        fontSize: responsive.fontSize(15),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        SizedBox(height: responsive.spacing(80)),
                      ],
                    ),
                  ),
                ),
                // Bottom controls
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: responsive.spacing(20),
                    vertical: responsive.spacing(12),
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 4,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentStep > 0 ? _handlePrevious : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: EdgeInsets.symmetric(
                              vertical: responsive.spacing(12),
                            ),
                          ),
                          child: const Text('Back'),
                        ),
                      ),
                      SizedBox(width: responsive.spacing(12)),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentStep < _diySteps.length - 1
                              ? _handleNext
                              : _handleComplete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: responsive.spacing(12),
                            ),
                          ),
                          child: Text(
                            _currentStep < _diySteps.length - 1
                                ? 'Next Step'
                                : 'Mark as Complete',
                          ),
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
