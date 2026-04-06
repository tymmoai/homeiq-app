import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../core/utils/logger.dart';
import '../../../services/api_client.dart';
import '../../../services/order_service.dart';
import '../../../services/user_service.dart';
import '../../profile/payment_methods/widgets/unified_payment_content.dart';
import '../../services/services/booking_service.dart';
import 'ai_combined_flow_widgets.dart';
import 'ai_fix_models.dart';
import 'ai_parts_flow_widgets.dart';
import 'ai_problem_analysis_widgets.dart';
import 'ai_technician_flow_widgets.dart';
import 'technician_confirmation_widget.dart';
import 'widgets/ai_fix/ai_fix_fallback_data.dart';
import 'widgets/ai_fix/ai_fix_floating_button_widget.dart';
import 'widgets/ai_fix/ai_fix_header_widget.dart';
import 'widgets/ai_fix/ai_fix_loading_overlay.dart';

typedef _AiStep = AiStep;
typedef _DiyStep = DiyStep;
typedef _PartOption = PartOption;

class AiFixProblemScreen extends StatefulWidget {
  final Map<String, dynamic> asset;
  final bool fromDiy;
  final Map<String, dynamic>? diyContext;

  const AiFixProblemScreen({
    super.key,
    required this.asset,
    this.fromDiy = false,
    this.diyContext,
  });

  @override
  State<AiFixProblemScreen> createState() => _AiFixProblemScreenState();
}

class _AiFixProblemScreenState extends State<AiFixProblemScreen> {
  AiStep _currentStep = AiStep.issueSelection;
  bool _isLoading = false;
  bool _isNotWorkingLoading = false;

  final List<String> _issueOptions = [];
  final Set<String> _selectedIssues =
      {}; // Changed to Set for multiple selection
  String _additionalDescription = '';
  final TextEditingController _descriptionController = TextEditingController();

  String _aiSolution = '';
  final List<DiyStep> _diySteps = [];
  int _currentDiyStepIndex = 0;

  /// DIY step index when user tapped "Not working" to go to parts; restored when back from parts.
  int? _diyStepIndexBeforeParts;

  // Parts & checkout
  final List<PartOption> _parts = [];
  final Set<int> _selectedPartsIndexes = {};
  double _encompassTotal = 0;
  double _marconeTotal = 0;
  double _localTotal = 0;
  String _selectedProvider = 'Encompass';
  bool _showComparison = false;

  // Technician booking
  final List<TechnicianOption> _technicians = [
    TechnicianOption(
      name: 'Robert "Bob" Fixit',
      rating: 4.9,
      experienceYears: 15,
      fee: 125,
    ),
    TechnicianOption(
      name: 'Mike Hammer',
      rating: 4.8,
      experienceYears: 5,
      fee: 95,
    ),
  ];
  TechnicianOption? _selectedTechnician;
  String? _selectedSlot;
  DateTime? _selectedDate;
  DateTime _calendarMonth = DateTime.now();
  String? _bookingId;
  String? _trackingId;
  String? _dispatchId;

  // Address & Payment
  late final Map<String, String> _deliveryAddress = {
    'name': UserService.instance.getUserName(),
    'phone': UserService.instance.getUserPhone(),
    'street': UserService.instance.getUserAddress(),
    'city': UserService.instance.getUserCity(),
    'state': UserService.instance.getUserState(),
    'zip': UserService.instance.getUserZipCode(),
  };
  bool _useNewCard = false;
  final Map<String, String> _newCard = {
    'name': '',
    'number': '',
    'expiry': '',
    'cvv': '',
  };
  bool _agreePayment = false;
  bool _isProcessing = false;
  String? _expectedDelivery;

  // Flow tracking
  bool _isCombinedFlow = false;
  bool _isStandaloneBooking = false;
  AiStep? _previousStep; // ignore: unused_field
  AiStep?
  _bookTechnicianEntryStep; // Track where user entered Book Technician flow

  Map<String, dynamic> get _asset => widget.asset;

  String get _assetName => (_asset['name'] as String?) ?? 'Asset';
  String get _assetBrand => (_asset['brand'] as String?) ?? 'Unknown';
  String get _assetModel =>
      (_asset['model'] as String?) ?? (_asset['modelNumber'] as String?) ?? '';

  /// Minimal display name for UI — uses asset type (e.g. "Refrigerator") instead
  /// of the full barcode product name. Full name (_assetName) is still used for
  /// AI API calls so the model has accurate product context.
  String get _assetDisplayName {
    final type = (_asset['type'] as String?)?.trim() ?? '';
    if (type.isNotEmpty) return type;
    // Fallback: first meaningful word of the full name
    final words = _assetName.split(RegExp(r'\s+'));
    return words.isNotEmpty ? words.first : _assetName;
  }

  /// Format date to US standard format: MM/DD/YYYY
  String _formatDateToUS(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Parse US-formatted date string (MM/DD/YYYY) to DateTime
  // ignore: unused_element
  DateTime? _parseUSDate(String dateString) {
    try {
      final parts = dateString.split('/');
      if (parts.length != 3) return null;
      final month = int.parse(parts[0]);
      final day = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } on Object catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _descriptionController.text = _additionalDescription;
    if (widget.fromDiy) {
      // Coming from DIY flow — skip AI diagnosis, go straight to technician booking
      _isStandaloneBooking = true;
      _bookTechnicianEntryStep = null; // No entry step to go back to
      _currentStep = AiStep.technicianSelection;
    } else {
      _generateIssueOptions();
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  final _apiClient = ApiClient();

  Future<void> _generateIssueOptions() async {
    setState(() {
      _isLoading = true;
      _issueOptions.clear();
    });

    try {
      final response = await _apiClient.post(
        '/ai/generate-issue-options',
        body: {
          'assetName': _assetName,
          'assetBrand': _assetBrand,
          'assetModel': _assetModel,
        },
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch issue options: ${response.statusCode}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['data'] ?? data;
      final issues = List<String>.from(content['issues'] ?? []);

      setState(() {
        _issueOptions.addAll(
          issues.isEmpty ? ['Not working properly'] : issues.take(6).toList(),
        );
        _isLoading = false;
      });
    } on Object catch (e) {
      AppLogger.error(
        'Issue generation error: $e',
        tag: 'AiFixProblem',
        error: e,
      );
      setState(() {
        _isLoading = false;
        _issueOptions.addAll(
          AiFixFallbackData.getIssueOptions(_asset, _assetName),
        );
      });
    }
  }

  Future<void> _generateSolution() async {
    if (_selectedIssues.isEmpty && _additionalDescription.trim().isEmpty) {
      return;
    }

    setState(() {
      _currentStep = _AiStep.analysis;
      _isLoading = true;
      _aiSolution = '';
    });

    final problemDescription = [
      _selectedIssues.join(', '),
      if (_additionalDescription.trim().isNotEmpty)
        'Additional details: ${_additionalDescription.trim()}',
    ].where((e) => e.isNotEmpty).join('. ');

    try {
      final response = await _apiClient.post(
        '/ai/analyze-issue',
        body: {
          'assetName': _assetName,
          'assetBrand': _assetBrand,
          'assetModel': _assetModel,
          'issue': problemDescription,
        },
        timeout: const Duration(seconds: 20),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch solution from backend');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['data'] ?? data;
      // Build bullet-point solution from structured response.
      // Backend returns: { diagnosis, severity, possibleCauses[], quickChecks[],
      //                    estimatedCost, requiresProfessional }
      final possibleCauses = List<String>.from(content['possibleCauses'] ?? []);
      final quickChecks = List<String>.from(content['quickChecks'] ?? []);
      final diagnosis = content['diagnosis'] as String? ?? '';

      final buffer = StringBuffer();
      if (diagnosis.isNotEmpty) {
        buffer.writeln(diagnosis);
        buffer.writeln();
      }
      if (possibleCauses.isNotEmpty) {
        for (final c in possibleCauses) {
          buffer.writeln('• $c');
        }
      }
      if (quickChecks.isNotEmpty) {
        buffer.writeln();
        buffer.writeln('Quick checks:');
        for (final q in quickChecks) {
          buffer.writeln('• $q');
        }
      }
      final solution = buffer.toString().trim().isNotEmpty
          ? buffer.toString().trim()
          : AiFixFallbackData.getSolution(_asset, _assetName);

      setState(() {
        _aiSolution = solution;
        _isLoading = false;
        _currentStep = _AiStep.solution;
      });
    } on Object catch (_) {
      // Use fallback solution instead of going back
      setState(() {
        _isLoading = false;
        _currentStep = _AiStep.solution;
        _aiSolution = AiFixFallbackData.getSolution(_asset, _assetName);
      });
    }
  }

  Future<void> _generateDiySteps() async {
    if (_selectedIssues.isEmpty && _additionalDescription.trim().isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _diySteps.clear();
      _currentDiyStepIndex = 0;
    });

    final problemDescription = [
      _selectedIssues.join(', '),
      if (_additionalDescription.trim().isNotEmpty)
        _additionalDescription.trim(),
    ].where((e) => e.isNotEmpty).join('. ');

    try {
      final response = await _apiClient.post(
        '/ai/generate-diy-troubleshooting',
        body: {
          'assetName': _assetName,
          'assetBrand': _assetBrand,
          'assetModel': _assetModel,
          'issue': problemDescription,
        },
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to fetch DIY steps');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['data'] ?? data;
      final stepsJson = content['steps'] as List<dynamic>? ?? [];

      final parsedSteps = <_DiyStep>[];
      for (final step in stepsJson) {
        final s = step as Map<String, dynamic>;
        parsedSteps.add(
          _DiyStep(
            title: s['title'] as String? ?? '',
            description: s['description'] as String? ?? '',
            instructions: List<String>.from(s['instructions'] ?? []),
            safetyNote: (s['safety'] as String?)?.isEmpty == true
                ? null
                : s['safety'] as String?,
            duration: s['duration'] as String?,
            riskLevel: s['risk'] as String?,
            toolsNeeded: s['tools'] != null
                ? List<String>.from(s['tools'])
                : null,
          ),
        );
      }

      if (parsedSteps.isEmpty) {
        throw Exception('No DIY steps returned');
      }

      // Ensure we have exactly 3 steps
      final finalSteps = parsedSteps.length < 3
          ? [
              ...parsedSteps,
              ...AiFixFallbackData.getDiySteps(
                _asset,
                _assetName,
              ).take(3 - parsedSteps.length),
            ]
          : parsedSteps.take(3).toList();

      setState(() {
        _diySteps.addAll(finalSteps);
        _isLoading = false;
        _currentStep = _AiStep.diyGuide;
      });
    } on Object catch (_) {
      // Use fallback steps on error to ensure flow works effortlessly
      setState(() {
        _isLoading = false;
        _diySteps.clear();
        _currentDiyStepIndex = 0;
        _diySteps.addAll(
          AiFixFallbackData.getDiySteps(_asset, _assetName).take(3),
        );
        _currentStep = _AiStep.diyGuide;
      });
    }
  }

  void _goBackFromDiy() {
    if (_currentDiyStepIndex > 0) {
      setState(() {
        _currentDiyStepIndex -= 1;
      });
    } else {
      setState(() {
        _currentStep = _AiStep.solution;
      });
    }
  }

  /// Check if current step widget has its own SingleChildScrollView
  bool _hasOwnScrollView() {
    return _currentStep == _AiStep.combinedTechnicianSelection ||
        _currentStep == _AiStep.combinedTimeSlot ||
        _currentStep == _AiStep.combinedConfirmation ||
        _currentStep == _AiStep.combinedPayment ||
        _currentStep == _AiStep.combinedOrderBookingConfirmation ||
        _currentStep == _AiStep.technicianTimeSlot;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final buttonBottomMargin = screenHeight * 0.03;

    return Scaffold(
      backgroundColor: AppColors.backgroundGray50,
      appBar: null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header: show close-only for success step, stepper for others
                AiFixHeaderWidget(
                  currentStep: _currentStep,
                  onBack: _handleBackNavigation,
                  onClose: () => context.pop(),
                  isCombinedFlow: _isCombinedFlow,
                  isStandaloneBooking: _isStandaloneBooking,
                ),
                Expanded(
                  child: _isPaymentStep()
                      ? _buildUnifiedPaymentForCurrentStep()
                      : _hasOwnScrollView()
                      ? Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: _buildStepContent(),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 5,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [_buildStepContent()],
                          ),
                        ),
                ),
              ],
            ),
            // Positioned floating action button at 3% from bottom
            if (AiFixFloatingButtonWidget.shouldShow(_currentStep))
              Positioned(
                bottom: buttonBottomMargin,
                left: 20,
                right: 20,
                child: AiFixFloatingButtonWidget(
                  currentStep: _currentStep,
                  selectedPartsIndexes: _selectedPartsIndexes,
                  selectedTechnician: _selectedTechnician,
                  selectedSlot: _selectedSlot,
                  isCombinedFlow: _isCombinedFlow,
                  onStepChange: (step) => setState(() => _currentStep = step),
                ),
              ),
            // Loading overlay for DIY steps generation
            if (_isLoading && _currentStep == _AiStep.solution)
              const Positioned.fill(child: AiFixLoadingOverlay()),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  int _getCurrentStepNumber() {
    switch (_currentStep) {
      case _AiStep.issueSelection:
        return 1;
      case _AiStep.analysis:
        return 2;
      case _AiStep.solution:
        return 3;
      case _AiStep.diyGuide:
        return 4;
      case _AiStep.partsComparison:
        return 4;
      case _AiStep.partsActionSelection:
        return 4;
      case _AiStep.partsOrderConfirmation:
      case _AiStep.partsPaymentInfo:
      case _AiStep.partsOrderSummary:
        return 5;
      case _AiStep.technicianAddressConfirmation:
      case _AiStep.technicianSelection:
      case _AiStep.technicianTimeSlot:
      case _AiStep.technicianConfirmation:
        return 4;
      case _AiStep.technicianPaymentConfirmation:
      case _AiStep.technicianBookingConfirmation:
        return 5;
      // Combined flow: 5 steps (Tech Selection → Time Slot → Confirmation → Payment → Success)
      case _AiStep.combinedTechnicianSelection:
        return 1; // Step 1: Technician Selection
      case _AiStep.combinedTimeSlot:
        return 2; // Step 2: Time Slot
      case _AiStep.combinedConfirmation:
        return 3; // Step 3: Review All
      case _AiStep.combinedPayment:
        return 4; // Step 4: Payment
      case _AiStep.combinedOrderBookingConfirmation:
        return 5; // Step 5: Success
    }
  }

  void _handleBackNavigation() {
    if (_currentStep == _AiStep.analysis) {
      setState(() {
        _currentStep = _AiStep.issueSelection;
      });
    } else if (_currentStep == _AiStep.solution) {
      setState(() {
        _currentStep = _AiStep.issueSelection;
      });
    } else if (_currentStep == _AiStep.diyGuide) {
      setState(() {
        _currentStep = _AiStep.solution;
        _currentDiyStepIndex = 0;
      });
    } else if (_currentStep == _AiStep.partsComparison) {
      setState(() {
        _currentStep = _AiStep.diyGuide;
        _currentDiyStepIndex = _diyStepIndexBeforeParts ?? 0;
      });
    } else if (_currentStep == _AiStep.partsActionSelection) {
      setState(() {
        _currentStep = _AiStep.partsComparison;
      });
    } else if (_currentStep == _AiStep.partsOrderConfirmation) {
      setState(() {
        _currentStep = _AiStep.partsActionSelection;
      });
    } else if (_currentStep == _AiStep.partsPaymentInfo) {
      setState(() {
        _currentStep = _AiStep.partsOrderConfirmation;
      });
    } else if (_currentStep == _AiStep.partsOrderSummary) {
      setState(() {
        _currentStep = _AiStep.partsPaymentInfo;
      });
    } else if (_currentStep == _AiStep.technicianSelection) {
      // Standalone booking: back to entry point
      setState(() {
        if (widget.fromDiy) {
          // Coming from DIY flow — go back to DIY screen
          context.pop();
          return;
        }
        if (_isStandaloneBooking) {
          if (_bookTechnicianEntryStep == _AiStep.issueSelection) {
            _currentStep = _AiStep.issueSelection;
          } else if (_bookTechnicianEntryStep == _AiStep.solution) {
            _currentStep = _AiStep.solution;
          } else if (_bookTechnicianEntryStep == _AiStep.partsActionSelection) {
            _currentStep = _AiStep.partsActionSelection;
          } else {
            _currentStep = _AiStep.issueSelection;
          }
        }
      });
    } else if (_currentStep == _AiStep.technicianTimeSlot) {
      setState(() {
        _currentStep = _AiStep.technicianSelection;
      });
    } else if (_currentStep == _AiStep.technicianConfirmation) {
      setState(() {
        _currentStep = _AiStep.technicianTimeSlot;
      });
    } else if (_currentStep == _AiStep.technicianPaymentConfirmation) {
      setState(() {
        _currentStep = _AiStep.technicianConfirmation;
      });
    } else if (_currentStep == _AiStep.combinedTechnicianSelection) {
      // Combined flow: Step 1 goes back to parts action selection
      setState(() {
        _currentStep = _AiStep.partsActionSelection;
      });
    } else if (_currentStep == _AiStep.combinedTimeSlot) {
      // Combined flow: Step 2 goes back to technician selection
      setState(() {
        _currentStep = _AiStep.combinedTechnicianSelection;
      });
    } else if (_currentStep == _AiStep.combinedConfirmation) {
      // Combined flow: Step 3 goes back to time slot
      setState(() {
        _currentStep = _AiStep.combinedTimeSlot;
      });
    } else if (_currentStep == _AiStep.combinedPayment) {
      // Combined flow: Step 4 goes back to confirmation
      setState(() {
        _currentStep = _AiStep.combinedConfirmation;
      });
    } else if (_currentStep == _AiStep.technicianBookingConfirmation) {
      setState(() {
        if (_bookTechnicianEntryStep == _AiStep.issueSelection) {
          _currentStep = _AiStep.issueSelection;
        } else if (_bookTechnicianEntryStep == _AiStep.solution) {
          _currentStep = _AiStep.solution;
        } else if (_bookTechnicianEntryStep == _AiStep.partsActionSelection) {
          _currentStep = _AiStep.partsActionSelection;
        } else {
          _currentStep = _AiStep.solution;
        }
      });
    } else if (_currentStep == _AiStep.combinedOrderBookingConfirmation) {
      setState(() {
        _currentStep = _AiStep.combinedPayment;
      });
    }
  }

  /// Calculate total steps for current flow (after decision point)
  // ignore: unused_element
  int _getTotalFlowSteps() {
    if (_isCombinedFlow) {
      return 5; // Tech Selection → Time Slot → Confirmation → Payment → Success
    } else if (_isStandaloneBooking && _currentStep != _AiStep.issueSelection) {
      return 5; // Address → Selection → TimeSlot → Confirmation → Payment → Success (hidden flow)
    } else if (_currentStep == _AiStep.partsComparison ||
        _currentStep == _AiStep.partsActionSelection ||
        _currentStep == _AiStep.partsOrderConfirmation ||
        _currentStep == _AiStep.partsPaymentInfo ||
        _currentStep == _AiStep.partsOrderSummary) {
      return 5; // Comparison → Action → Confirmation → Payment → Summary
    }
    return 0;
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case _AiStep.issueSelection:
        return IssueSelectionWidget(
          assetName: _assetDisplayName,
          issueOptions: _issueOptions,
          selectedIssues: _selectedIssues,
          additionalDescription: _additionalDescription,
          descriptionController: _descriptionController,
          isLoading: _isLoading,
          onGenerateSolution: _generateSolution,
          onIssueToggle: (issue) {
            setState(() {
              if (_selectedIssues.contains(issue)) {
                _selectedIssues.remove(issue);
              } else {
                _selectedIssues.add(issue);
              }
            });
          },
          onDescriptionChanged: (value) {
            setState(() {
              _additionalDescription = value;
            });
          },
          onBookTechnician: () {
            setState(() {
              _bookTechnicianEntryStep = _AiStep.issueSelection;
              _isStandaloneBooking = true;
              _currentStep = _AiStep.technicianSelection;
            });
          },
          onVoiceInput: (text) {
            setState(() {
              _additionalDescription = text;
              _descriptionController.text = text;
              _descriptionController.selection = TextSelection.fromPosition(
                TextPosition(offset: text.length),
              );
            });
          },
        );
      case _AiStep.analysis:
        return const AnalysisWidget();
      case _AiStep.solution:
        return SolutionWidget(
          aiSolution: _aiSolution,
          isLoading: _isLoading,
          onGenerateDiySteps: _generateDiySteps,
          onBookTechnician: () {
            setState(() {
              _bookTechnicianEntryStep = _AiStep.solution;
              _isStandaloneBooking = true;
              _currentStep = _AiStep.technicianSelection;
            });
          },
        );
      case _AiStep.diyGuide:
        return DiyGuideWidget(
          diySteps: _diySteps,
          currentDiyStepIndex: _currentDiyStepIndex,
          isNotWorkingLoading: _isNotWorkingLoading,
          onYesNextStep: () {
            final total = _diySteps.length;
            final index = _currentDiyStepIndex + 1;
            if (index < total) {
              setState(() {
                _currentDiyStepIndex += 1;
              });
            } else {
              context.pop();
            }
          },
          onNotWorking: _generatePartsAndPrices,
          onPreviousStep: _currentDiyStepIndex > 0 ? _goBackFromDiy : null,
        );
      case _AiStep.partsComparison:
        return PartsComparisonWidget(
          assetName: _assetDisplayName,
          parts: _parts,
          selectedPartsIndexes: _selectedPartsIndexes,
          encompassTotal: _encompassTotal,
          marconeTotal: _marconeTotal,
          localTotal: _localTotal,
          selectedProvider: _selectedProvider,
          showComparison: _showComparison,
          onTogglePart: (index, selected) {
            setState(() {
              if (selected) {
                _selectedPartsIndexes.add(index);
              } else {
                _selectedPartsIndexes.remove(index);
              }
              _recalculateProviderTotals();
            });
          },
          onSelectProvider: (provider) {
            setState(() {
              _selectedProvider = provider;
            });
          },
          onShowComparison: () {
            setState(() {
              _showComparison = true;
            });
          },
          onContinue: () {
            setState(() {
              _currentStep = _AiStep.partsActionSelection;
            });
          },
        );
      case _AiStep.partsActionSelection:
        return PartsActionSelectionWidget(
          onBuyParts: () {
            _isCombinedFlow = false;
            _isStandaloneBooking = false;
            _trackingId ??=
                'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
            final deliveryDate = DateTime.now().add(const Duration(days: 6));
            _expectedDelivery = _formatDateToUS(deliveryDate);
            setState(() {
              _currentStep = _AiStep.partsOrderConfirmation;
            });
          },
          onBookTechnician: () {
            _isCombinedFlow = false;
            _isStandaloneBooking = true;
            _bookTechnicianEntryStep = _AiStep.partsActionSelection;
            setState(() {
              _currentStep = _AiStep.technicianSelection;
            });
          },
          onBuyPartsAndBookTechnician: () {
            _isCombinedFlow = true;
            _isStandaloneBooking = false;
            _trackingId ??=
                'TRK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
            final deliveryDate = DateTime.now().add(const Duration(days: 6));
            _expectedDelivery = _formatDateToUS(deliveryDate);
            setState(() {
              _currentStep = _AiStep.combinedTechnicianSelection;
            });
          },
        );
      case _AiStep.partsOrderConfirmation:
        final subtotal = _getSelectedProviderTotal();
        final expectedDeliveryDate =
            _expectedDelivery ??
            _formatDateToUS(DateTime.now().add(const Duration(days: 6)));
        return PartsOrderConfirmationWidget(
          parts: _parts,
          selectedPartsIndexes: _selectedPartsIndexes,
          subtotal: subtotal,
          deliveryAddress: _deliveryAddress,
          expectedDeliveryDate: expectedDeliveryDate,
          onUpdateAddressField: (field, value) {
            setState(() {
              _deliveryAddress[field] = value;
            });
          },
          onContinue: () {
            setState(() {
              _currentStep = _AiStep.partsPaymentInfo;
            });
          },
        );
      case _AiStep.partsPaymentInfo:
        final subtotal = _getSelectedProviderTotal();
        return PartsPaymentInfoWidget(
          subtotal: subtotal,
          useNewCard: _useNewCard,
          isProcessing: _isProcessing,
          isNewCardValid: _isNewCardValid(),
          onSelectExistingCard: () {
            setState(() {
              _useNewCard = false;
            });
          },
          onSelectNewCard: () {
            setState(() {
              _useNewCard = true;
            });
          },
          onCardholderChanged: (value) {
            setState(() {
              _newCard['name'] = value;
            });
          },
          onCardNumberChanged: (value) {
            final digits = value.replaceAll(' ', '');
            String formatted = '';
            for (int i = 0; i < digits.length; i++) {
              if (i > 0 && i % 4 == 0) {
                formatted += ' ';
              }
              formatted += digits[i];
            }
            setState(() {
              _newCard['number'] = formatted;
            });
          },
          onExpiryChanged: (value) {
            setState(() {
              _newCard['expiry'] = value;
            });
          },
          onCvvChanged: (value) {
            setState(() {
              _newCard['cvv'] = value;
            });
          },
          onConfirmPayment: () async {
            setState(() {
              _isProcessing = true;
            });

            try {
              await Future.delayed(const Duration(milliseconds: 800));

              if (!mounted) return;

              // Persist the parts order via OrderService
              final subtotal = _getSelectedProviderTotal();
              const shipping = 9.99;
              final tax = subtotal * 0.08;
              final total = subtotal + shipping + tax;
              final partsData = _selectedPartsIndexes
                  .map(
                    (i) => {
                      'name': _parts[i].name,
                      'provider': _selectedProvider,
                      'price': _parts[i].priceEncompass,
                      'id': 'PART-$i',
                    },
                  )
                  .toList();

              try {
                await OrderService.savePartsOrder(
                  trackingId: _trackingId ?? 'TRK-UNKNOWN',
                  parts: partsData,
                  subtotal: subtotal,
                  total: total,
                  reminderName: _assetDisplayName,
                  expectedDelivery: _expectedDelivery,
                );
                AppLogger.info(
                  'Parts order saved: $_trackingId',
                  tag: 'AiFixProblem',
                );
              } on Object catch (e) {
                AppLogger.warning(
                  'Failed to save parts order: $e',
                  tag: 'AiFixProblem',
                  error: e,
                );
              }

              setState(() {
                _currentStep = _AiStep.partsOrderSummary;
                _isProcessing = false;
              });
            } on Object catch (_) {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            }
          },
        );
      case _AiStep.partsOrderSummary:
        final subtotal = _getSelectedProviderTotal();
        const shipping = 9.99;
        final tax = subtotal * 0.08;
        final total = subtotal + shipping + tax;
        return PartsOrderSummaryWidget(
          parts: _parts,
          selectedPartsIndexes: _selectedPartsIndexes,
          trackingId: _trackingId,
          expectedDelivery: _expectedDelivery,
          subtotal: total,
          onBackToHome: () => context.pop(),
        );
      case _AiStep.technicianAddressConfirmation:
        return TechnicianAddressConfirmationWidget(
          deliveryAddress: _deliveryAddress,
          onUpdateAddressField: (field, value) {
            setState(() {
              _deliveryAddress[field] = value;
            });
          },
          onContinue: () {
            setState(() {
              _currentStep = _AiStep.technicianSelection;
            });
          },
        );
      case _AiStep.technicianSelection:
        return TechnicianSelectionWidget(
          technicians: _technicians,
          isCombinedFlow: _isCombinedFlow,
          onSelectTechnician: (tech) {
            setState(() {
              _selectedTechnician = tech;
              // Don't navigate - let floating button handle it
            });
          },
        );
      case _AiStep.combinedTechnicianSelection:
        // Combined flow: Step 1 - Technician Selection with Continue button
        return TechnicianSelectionWidget(
          technicians: _technicians,
          isCombinedFlow: true,
          selectedTechnician: _selectedTechnician,
          onSelectTechnician: (tech) {
            setState(() {
              _selectedTechnician = tech;
            });
          },
          onContinue: () {
            setState(() {
              _currentStep = _AiStep.combinedTimeSlot;
            });
          },
        );
      case _AiStep.combinedTimeSlot:
        // Combined flow: Step 2 - Time Slot Selection
        return TechnicianTimeSlotWidget(
          selectedTechnician: _selectedTechnician,
          calendarMonth: _calendarMonth,
          selectedDate: _selectedDate,
          selectedSlot: _selectedSlot,
          isCombinedFlow: true,
          isStandaloneBooking: false,
          expectedDelivery: _expectedDelivery,
          onMonthChanged: (newMonth) {
            setState(() {
              _calendarMonth = newMonth;
            });
          },
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          onSelectSlot: (slot) {
            setState(() {
              _selectedSlot = slot;
            });
          },
          onContinue: () {
            setState(() {
              _currentStep = _AiStep.combinedConfirmation;
            });
          },
        );
      case _AiStep.combinedConfirmation:
        // Combined flow: Step 3 - Review All (Parts + Technician + Address)
        final subtotal = _getSelectedProviderTotal();
        return CombinedConfirmationWidget(
          parts: _parts,
          selectedPartsIndexes: _selectedPartsIndexes,
          partsSubtotal: subtotal,
          expectedDelivery: _expectedDelivery ?? 'TBD',
          technician: _selectedTechnician!,
          selectedSlot: _selectedSlot ?? 'TBD',
          deliveryAddress: _deliveryAddress,
          agreeTerms: _agreePayment,
          isProcessing: _isProcessing,
          onAgreeChanged: (value) {
            setState(() {
              _agreePayment = value ?? false;
            });
          },
          onUpdateAddress: (field, value) {
            setState(() {
              _deliveryAddress[field] = value;
            });
          },
          onConfirmPayment: () {
            setState(() {
              _currentStep = _AiStep.combinedPayment;
            });
          },
        );
      case _AiStep.technicianTimeSlot:
        return TechnicianTimeSlotWidget(
          selectedTechnician: _selectedTechnician,
          calendarMonth: _calendarMonth,
          selectedDate: _selectedDate,
          selectedSlot: _selectedSlot,
          isCombinedFlow: _isCombinedFlow,
          isStandaloneBooking: _isStandaloneBooking,
          expectedDelivery: _expectedDelivery,
          onMonthChanged: (newMonth) {
            setState(() {
              _calendarMonth = newMonth;
            });
          },
          onSelectDate: (date) {
            setState(() {
              _selectedDate = date;
            });
          },
          onSelectSlot: (slot) {
            setState(() {
              _selectedSlot = slot;
            });
          },
          onContinue: () {
            setState(() {
              _currentStep = _isCombinedFlow
                  ? _AiStep.combinedPayment
                  : _AiStep.technicianPaymentConfirmation;
            });
          },
        );
      case _AiStep.technicianConfirmation:
        return TechnicianConfirmationWidget(
          selectedTechnician: _selectedTechnician,
          selectedSlot: _selectedSlot,
          deliveryAddress: _deliveryAddress,
          onUpdateAddressField: (field, value) {
            setState(() {
              _deliveryAddress[field] = value;
            });
          },
          onContinuePayment: () {
            setState(() {
              _currentStep = _AiStep.technicianPaymentConfirmation;
            });
          },
        );
      case _AiStep.technicianPaymentConfirmation:
        return TechnicianPaymentConfirmationWidget(
          selectedTechnician: _selectedTechnician!,
          useNewCard: _useNewCard,
          isProcessing: _isProcessing,
          isNewCardValid: _isNewCardValid(),
          onSelectExistingCard: () {
            setState(() {
              _useNewCard = false;
            });
          },
          onSelectNewCard: () {
            setState(() {
              _useNewCard = true;
            });
          },
          onCardholderChanged: (value) {
            setState(() {
              _newCard['name'] = value;
            });
          },
          onCardNumberChanged: (value) {
            final digits = value.replaceAll(' ', '');
            String formatted = '';
            for (int i = 0; i < digits.length; i++) {
              if (i > 0 && i % 4 == 0) {
                formatted += ' ';
              }
              formatted += digits[i];
            }
            setState(() {
              _newCard['number'] = formatted;
            });
          },
          onExpiryChanged: (value) {
            setState(() {
              _newCard['expiry'] = value;
            });
          },
          onCvvChanged: (value) {
            setState(() {
              _newCard['cvv'] = value;
            });
          },
          onConfirmPayment: () async {
            setState(() {
              _isProcessing = true;
            });

            try {
              await Future.delayed(const Duration(milliseconds: 800));

              if (!mounted) return;

              _bookingId ??=
                  'BB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
              _dispatchId ??=
                  'DSP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 11)}';

              // Persist technician booking via BookingService
              try {
                final techFee = _selectedTechnician?.fee ?? 0;
                final techTax = techFee * 0.08;
                final techTotal = techFee + techTax;
                final scheduledDate =
                    _selectedDate ??
                    DateTime.now().add(const Duration(days: 2));
                String scheduledTime = '';
                if (_selectedSlot != null) {
                  final slotParts = _selectedSlot!.split(' at ');
                  if (slotParts.length == 2) {
                    scheduledTime = slotParts[1];
                  }
                }

                await BookingService.saveLifestyleBooking(
                  serviceType: 'Asset Repair',
                  serviceName: '$_assetDisplayName Repair',
                  scheduledDate: scheduledDate,
                  scheduledTime: scheduledTime,
                  total: techTotal,
                  bookingId: _bookingId,
                  contactName: _deliveryAddress['name'],
                  contactPhone: _deliveryAddress['phone'],
                  address:
                      '${_deliveryAddress['street']}, ${_deliveryAddress['city']}, ${_deliveryAddress['state']}',
                  specialRequirements:
                      'Technician: ${_selectedTechnician?.name ?? "TBD"} | Dispatch: $_dispatchId',
                );
                AppLogger.info(
                  'Technician booking saved: $_bookingId',
                  tag: 'AiFixProblem',
                );
              } on Object catch (e) {
                AppLogger.warning(
                  'Failed to save technician booking: $e',
                  tag: 'AiFixProblem',
                  error: e,
                );
              }

              setState(() {
                _currentStep = _AiStep.technicianBookingConfirmation;
                _isProcessing = false;
              });
            } on Object catch (_) {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            }
          },
        );
      case _AiStep.technicianBookingConfirmation:
        return TechnicianBookingConfirmationWidget(
          selectedTechnician: _selectedTechnician!,
          bookingId: _bookingId ?? 'N/A',
          dispatchId: _dispatchId ?? 'N/A',
          deliveryAddress: _deliveryAddress,
          selectedSlot: _selectedSlot ?? '',
          onBackToAsset: () => context.pop(),
        );
      case _AiStep.combinedPayment:
        // NEW: Step 4 - Payment only (order review is in combinedConfirmation)
        final subtotal = _getSelectedProviderTotal();
        return CombinedPaymentWidget(
          partsSubtotal: subtotal,
          technicianFee: _selectedTechnician!.fee,
          isProcessing: _isProcessing,
          onConfirmPayment: () async {
            setState(() {
              _isProcessing = true;
            });

            try {
              await Future.delayed(const Duration(milliseconds: 800));

              if (!mounted) return;

              _bookingId ??=
                  'BB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
              _dispatchId ??=
                  'DSP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7, 11)}';

              // Persist BOTH parts order + technician booking for combined flow
              // 1) Save parts order
              try {
                final subtotal = _getSelectedProviderTotal();
                const shipping = 9.99;
                final tax = subtotal * 0.08;
                final total = subtotal + shipping + tax;
                final partsData = _selectedPartsIndexes
                    .map(
                      (i) => {
                        'name': _parts[i].name,
                        'provider': _selectedProvider,
                        'price': _parts[i].priceEncompass,
                        'id': 'PART-$i',
                      },
                    )
                    .toList();

                await OrderService.savePartsOrder(
                  trackingId: _trackingId ?? 'TRK-UNKNOWN',
                  parts: partsData,
                  subtotal: subtotal,
                  total: total,
                  reminderName: _assetDisplayName,
                  expectedDelivery: _expectedDelivery,
                );
                AppLogger.info(
                  'Combined: parts order saved: $_trackingId',
                  tag: 'AiFixProblem',
                );
              } on Object catch (e) {
                AppLogger.warning(
                  'Combined: failed to save parts order: $e',
                  tag: 'AiFixProblem',
                  error: e,
                );
              }

              // 2) Save technician booking
              try {
                final techFee = _selectedTechnician?.fee ?? 0;
                final techTax = techFee * 0.08;
                final techTotal = techFee + techTax;
                final scheduledDate =
                    _selectedDate ??
                    DateTime.now().add(const Duration(days: 2));
                String scheduledTime = '';
                if (_selectedSlot != null) {
                  final slotParts = _selectedSlot!.split(' at ');
                  if (slotParts.length == 2) {
                    scheduledTime = slotParts[1];
                  }
                }

                await BookingService.saveLifestyleBooking(
                  serviceType: 'Asset Repair',
                  serviceName: '$_assetDisplayName Repair',
                  scheduledDate: scheduledDate,
                  scheduledTime: scheduledTime,
                  total: techTotal,
                  bookingId: _bookingId,
                  contactName: _deliveryAddress['name'],
                  contactPhone: _deliveryAddress['phone'],
                  address:
                      '${_deliveryAddress['street']}, ${_deliveryAddress['city']}, ${_deliveryAddress['state']}',
                  specialRequirements:
                      'Technician: ${_selectedTechnician?.name ?? "TBD"} | Dispatch: $_dispatchId',
                );
                AppLogger.info(
                  'Combined: technician booking saved: $_bookingId',
                  tag: 'AiFixProblem',
                );
              } on Object catch (e) {
                AppLogger.warning(
                  'Combined: failed to save technician booking: $e',
                  tag: 'AiFixProblem',
                  error: e,
                );
              }

              setState(() {
                _currentStep = _AiStep.combinedOrderBookingConfirmation;
                _isProcessing = false;
              });
            } on Object catch (_) {
              if (mounted) {
                setState(() {
                  _isProcessing = false;
                });
              }
            }
          },
        );
      case _AiStep.combinedOrderBookingConfirmation:
        return CombinedOrderBookingConfirmationWidget(
          technician: _selectedTechnician!,
          parts: _parts,
          selectedPartsIndexes: _selectedPartsIndexes,
          trackingId: _trackingId ?? 'N/A',
          bookingId: _bookingId ?? 'N/A',
          dispatchId: _dispatchId ?? 'N/A',
          expectedDelivery: _expectedDelivery ?? 'N/A',
          selectedSlot: _selectedSlot ?? '',
          deliveryAddress: _deliveryAddress,
          onBackToAsset: () => context.pop(),
        );
    }
  }

  bool _isPaymentStep() {
    return _currentStep == _AiStep.partsPaymentInfo ||
        _currentStep == _AiStep.technicianPaymentConfirmation;
  }

  Widget _buildUnifiedPaymentForCurrentStep() {
    if (_currentStep == _AiStep.partsPaymentInfo) {
      final subtotal = _getSelectedProviderTotal();
      const shipping = 9.99;
      final tax = subtotal * 0.08;
      final total = subtotal + shipping + tax;
      return UnifiedPaymentContent(
        amount: total.toDouble(),
        serviceName: 'Parts Order',
        bookingId: null,
        orderSummaryItems: [
          OrderSummaryItem(
            label: 'Parts Subtotal',
            amount: subtotal.toDouble(),
          ),
          const OrderSummaryItem(label: 'Shipping', amount: shipping),
          OrderSummaryItem(label: 'Sales Tax (8%)', amount: tax),
        ],
        onPaymentComplete: (result) {
          if (result != null && result.success) {
            setState(() => _currentStep = _AiStep.partsOrderSummary);
          } else if (result != null && !result.success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Payment failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      );
    }

    if (_currentStep == _AiStep.technicianPaymentConfirmation) {
      final tech = _selectedTechnician;
      if (tech == null) return const SizedBox.shrink();
      final techFee = tech.fee;
      final techTax = techFee * 0.08;
      final total = techFee + techTax;
      return UnifiedPaymentContent(
        amount: total,
        serviceName: 'Technician Booking',
        bookingId: null,
        orderSummaryItems: [
          OrderSummaryItem(label: 'Technician Fee', amount: techFee),
          OrderSummaryItem(label: 'Tax (8%)', amount: techTax),
        ],
        onPaymentComplete: (result) {
          if (result != null && result.success) {
            setState(
              () => _currentStep = _AiStep.technicianBookingConfirmation,
            );
          } else if (result != null && !result.success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Payment failed'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
      );
    }

    // Note: combinedPayment step uses CombinedPaymentWidget directly, not UnifiedPaymentContent

    return const SizedBox.shrink();
  }

  // Generate parts and pricing from problem description
  Future<void> _generatePartsAndPrices() async {
    setState(() {
      _isNotWorkingLoading = true;
    });

    try {
      final problemDescription = [
        _selectedIssues.join(', '),
        if (_additionalDescription.trim().isNotEmpty)
          _additionalDescription.trim(),
      ].where((e) => e.isNotEmpty).join('. ');

      AppLogger.debug(
        'Generating parts for: $_assetBrand $_assetName - Problem: $problemDescription',
        tag: 'AiFixProblem',
      );

      final response = await _apiClient.post(
        '/ai/generate-parts',
        body: {
          'assetName': _assetName,
          'assetBrand': _assetBrand,
          'problem': problemDescription,
        },
        timeout: const Duration(seconds: 20),
      );

      AppLogger.debug(
        'Parts API response status: ${response.statusCode}',
        tag: 'AiFixProblem',
      );

      if (response.statusCode != 200) {
        AppLogger.error(
          'Parts API error body: ${response.body}',
          tag: 'AiFixProblem',
        );
        throw Exception('Failed to fetch parts: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final content = data['data'] ?? data;
      final partsJson = content['parts'] as List<dynamic>? ?? [];

      final parsed = <Map<String, dynamic>>[];
      for (final p in partsJson) {
        final part = p as Map<String, dynamic>;
        parsed.add({
          'name': part['name'] as String? ?? 'Part',
          'quantity': (part['qty'] as num?)?.toInt() ?? 1,
          'description': part['description'] as String? ?? '',
        });
      }

      // Fallback minimal if parsing fails
      final finalParts = parsed.isEmpty
          ? [
              {
                'name': 'General replacement part',
                'quantity': 1,
                'description': 'Likely component based on issue',
              },
            ]
          : parsed.take(5).toList();

      // Compute per-part Encompass prices such that total ~ $95-$105
      final baseMin = (95 + (10 * (finalParts.isNotEmpty ? 1 : 0))).round();
      final weights = List.generate(
        finalParts.length,
        (_) => 0.5 + (0.5 * (finalParts.isNotEmpty ? 1 : 0)),
      );
      final sumW = weights.fold(0.0, (a, b) => a + b);
      final encPrices = weights
          .map((w) => (w / sumW * baseMin).round().clamp(12, 200))
          .toList();

      // Adjust rounding drift to match baseMin
      final drift = baseMin - encPrices.fold(0, (a, b) => a + b);
      if (drift != 0 && encPrices.isNotEmpty) {
        encPrices[0] = (encPrices[0] + drift).clamp(12, 200).toInt();
      }

      final partsWithPrices = <_PartOption>[];
      for (var i = 0; i < finalParts.length; i++) {
        final p = finalParts[i];
        partsWithPrices.add(
          _PartOption(
            name: p['name'] as String,
            quantity: (p['quantity'] as num).toInt(),
            description: p['description'] as String,
            priceEncompass: encPrices[i].toDouble(),
            priceMarcone:
                (encPrices[i] + 3 + (7 * (finalParts.isNotEmpty ? 1 : 0)))
                    .toDouble(),
            priceLocal:
                (encPrices[i] + 8 + (12 * (finalParts.isNotEmpty ? 1 : 0)))
                    .toDouble(),
          ),
        );
      }

      setState(() {
        _parts.clear();
        _parts.addAll(partsWithPrices);
        _selectedPartsIndexes.clear();
        _selectedPartsIndexes.addAll(List.generate(_parts.length, (i) => i));
        _recalculateProviderTotals();
        _diyStepIndexBeforeParts = _currentDiyStepIndex;
        _isNotWorkingLoading = false;
        _currentStep = _AiStep.partsComparison;
      });
    } on Object catch (e) {
      AppLogger.error(
        'Parts generation error: $e',
        tag: 'AiFixProblem',
        error: e,
      );
      // On error, use asset-specific fallback data
      if (_parts.isEmpty) {
        _parts.addAll(AiFixFallbackData.getPartsDemoData(_asset, _assetName));
        _selectedPartsIndexes
          ..clear()
          ..addAll(List.generate(_parts.length, (i) => i));
      }
      _recalculateProviderTotals();
      setState(() {
        _diyStepIndexBeforeParts = _currentDiyStepIndex;
        _isNotWorkingLoading = false;
        _currentStep = _AiStep.partsComparison;
      });
    }
  }

  // --- Parts comparison & checkout ---
  // Note: This function is kept for future parts ordering feature
  // ignore: unused_element
  void _preparePartsDemoData() {
    if (_parts.isNotEmpty) {
      _recalculateProviderTotals();
      return;
    }

    final assetType =
        (_asset['type'] as String?)?.toLowerCase() ?? _assetName.toLowerCase();

    if (assetType.contains('refrigerator') || assetType.contains('fridge')) {
      _parts.addAll([
        _PartOption(
          name: 'Door gasket seal',
          quantity: 1,
          description: 'Main door rubber seal for better cooling efficiency.',
          priceEncompass: 65,
          priceMarcone: 72,
          priceLocal: 88,
        ),
        _PartOption(
          name: 'Thermostat sensor',
          quantity: 1,
          description: 'Temperature sensing probe / assembly.',
          priceEncompass: 42,
          priceMarcone: 48,
          priceLocal: 55,
        ),
        _PartOption(
          name: 'Condenser fan motor',
          quantity: 1,
          description: 'OEM condenser fan motor unit.',
          priceEncompass: 95,
          priceMarcone: 102,
          priceLocal: 118,
        ),
      ]);
    } else if (assetType.contains('tv') || assetType.contains('television')) {
      _parts.addAll([
        _PartOption(
          name: 'LED backlight strip',
          quantity: 1,
          description: 'Replacement LED backlight strip set.',
          priceEncompass: 45,
          priceMarcone: 52,
          priceLocal: 60,
        ),
        _PartOption(
          name: 'Power supply board',
          quantity: 1,
          description: 'Main power supply / inverter board.',
          priceEncompass: 78,
          priceMarcone: 85,
          priceLocal: 98,
        ),
        _PartOption(
          name: 'HDMI port module',
          quantity: 1,
          description: 'HDMI input connector board assembly.',
          priceEncompass: 35,
          priceMarcone: 42,
          priceLocal: 50,
        ),
      ]);
    } else if (assetType.contains('ac') ||
        assetType.contains('air conditioner')) {
      _parts.addAll([
        _PartOption(
          name: 'Air filter',
          quantity: 2,
          description: 'Replacement HEPA air filter set.',
          priceEncompass: 28,
          priceMarcone: 35,
          priceLocal: 42,
        ),
        _PartOption(
          name: 'Capacitor',
          quantity: 1,
          description: 'Run/start capacitor for compressor motor.',
          priceEncompass: 38,
          priceMarcone: 45,
          priceLocal: 55,
        ),
        _PartOption(
          name: 'Thermistor sensor',
          quantity: 1,
          description: 'Room temperature sensing thermistor.',
          priceEncompass: 22,
          priceMarcone: 28,
          priceLocal: 35,
        ),
      ]);
    } else if (assetType.contains('microwave')) {
      _parts.addAll([
        _PartOption(
          name: 'Turntable motor',
          quantity: 1,
          description: 'Microwave turntable drive motor.',
          priceEncompass: 32,
          priceMarcone: 38,
          priceLocal: 45,
        ),
        _PartOption(
          name: 'Door latch assembly',
          quantity: 1,
          description: 'Door switch and latch mechanism kit.',
          priceEncompass: 28,
          priceMarcone: 35,
          priceLocal: 42,
        ),
        _PartOption(
          name: 'Waveguide cover',
          quantity: 1,
          description: 'Interior microwave waveguide mica cover.',
          priceEncompass: 12,
          priceMarcone: 15,
          priceLocal: 18,
        ),
      ]);
    } else if (assetType.contains('washer') || assetType.contains('washing')) {
      _parts.addAll([
        _PartOption(
          name: 'Drain pump',
          quantity: 1,
          description: 'Washer drain pump motor assembly.',
          priceEncompass: 55,
          priceMarcone: 62,
          priceLocal: 72,
        ),
        _PartOption(
          name: 'Door boot seal',
          quantity: 1,
          description: 'Front load washer door gasket/boot.',
          priceEncompass: 68,
          priceMarcone: 75,
          priceLocal: 88,
        ),
        _PartOption(
          name: 'Water inlet valve',
          quantity: 1,
          description: 'Cold/hot water inlet solenoid valve.',
          priceEncompass: 35,
          priceMarcone: 42,
          priceLocal: 50,
        ),
      ]);
    } else {
      _parts.addAll([
        _PartOption(
          name: 'Control board',
          quantity: 1,
          description: 'Main electronic control board.',
          priceEncompass: 85,
          priceMarcone: 95,
          priceLocal: 110,
        ),
        _PartOption(
          name: 'Power cord',
          quantity: 1,
          description: 'Replacement power supply cord.',
          priceEncompass: 18,
          priceMarcone: 22,
          priceLocal: 28,
        ),
        _PartOption(
          name: 'Thermal fuse',
          quantity: 1,
          description: 'Safety thermal cutoff fuse.',
          priceEncompass: 12,
          priceMarcone: 15,
          priceLocal: 20,
        ),
      ]);
    }

    _selectedPartsIndexes
      ..clear()
      ..addAll(List.generate(_parts.length, (i) => i));
    _recalculateProviderTotals();
  }

  void _recalculateProviderTotals() {
    double enc = 0;
    double marc = 0;
    double loc = 0;
    for (var i = 0; i < _parts.length; i++) {
      if (_selectedPartsIndexes.contains(i)) {
        final p = _parts[i];
        enc += p.priceEncompass * p.quantity;
        marc += p.priceMarcone * p.quantity;
        loc += p.priceLocal * p.quantity;
      }
    }
    setState(() {
      _encompassTotal = enc;
      _marconeTotal = marc;
      _localTotal = loc;
    });
  }

  double _getSelectedProviderTotal() {
    switch (_selectedProvider) {
      case 'Marcone':
        return _marconeTotal;
      case 'Reliable Parts':
        return _localTotal;
      case 'Encompass':
      default:
        return _encompassTotal;
    }
  }

  bool _isNewCardValid() {
    return _newCard['name']?.isNotEmpty == true &&
        _newCard['number']?.isNotEmpty == true &&
        _newCard['expiry']?.isNotEmpty == true &&
        _newCard['cvv']?.isNotEmpty == true;
  }
}
