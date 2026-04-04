import 'dart:convert';

import '../core/utils/logger.dart';

import '../services/api_client.dart';

/// Service for AI-powered problem analysis and troubleshooting
/// Uses secure backend API instead of direct OpenAI calls
class AiTroubleshootingService {
  static final AiTroubleshootingService _instance =
      AiTroubleshootingService._internal();
  factory AiTroubleshootingService() => _instance;
  AiTroubleshootingService._internal();

  final _apiClient = ApiClient();

  /// Generate common issue options for an asset
  Future<List<String>> generateIssueOptions({
    required String assetName,
    required String assetBrand,
    String? assetModel,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/generate-issue-options',
        body: {
          'assetName': assetName,
          'assetBrand': assetBrand,
          'assetModel': assetModel,
        },
      );

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      return (data['issues'] as List).cast<String>();
    } on ApiException catch (e) {
      AppLogger.error('Failed to generate issue options: ${e.message}', tag: 'AiTroubleshooting', error: e);
      // Return fallback options
      return _getFallbackIssues(assetName);
    } on Object catch (e) {
      AppLogger.error('Unexpected error generating issues: $e', tag: 'AiTroubleshooting', error: e);
      return _getFallbackIssues(assetName);
    }
  }

  /// Analyze a reported issue and provide solutions
  Future<IssueAnalysisResponse> analyzeIssue({
    required String assetName,
    required String assetBrand,
    String? assetModel,
    required String issue,
    String? additionalDescription,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/analyze-issue',
        body: {
          'assetName': assetName,
          'assetBrand': assetBrand,
          'assetModel': assetModel,
          'issue': issue,
          'additionalDescription': additionalDescription,
        },
        timeout: const Duration(seconds: 45),
      );

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      return IssueAnalysisResponse.fromJson(data);
    } on ApiException catch (e) {
      throw AiTroubleshootingException(
        'Failed to analyze issue: ${e.message}',
        statusCode: e.statusCode,
      );
    } on Object catch (e) {
      throw AiTroubleshootingException('Unexpected error: $e');
    }
  }

  /// Generate DIY troubleshooting steps for a specific issue
  Future<DiyTroubleshootingResponse> generateDiyTroubleshooting({
    required String assetName,
    required String assetBrand,
    String? assetModel,
    required String issue,
    String? additionalDescription,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/generate-diy-troubleshooting',
        body: {
          'assetName': assetName,
          'assetBrand': assetBrand,
          'assetModel': assetModel,
          'issue': issue,
          'additionalDescription': additionalDescription,
        },
        timeout: const Duration(seconds: 45),
      );

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      return DiyTroubleshootingResponse.fromJson(data);
    } on ApiException catch (e) {
      throw AiTroubleshootingException(
        'Failed to generate DIY steps: ${e.message}',
        statusCode: e.statusCode,
      );
    } on Object catch (e) {
      throw AiTroubleshootingException('Unexpected error: $e');
    }
  }

  /// Get fallback issue options when API is unavailable
  List<String> _getFallbackIssues(String assetName) {
    return [
      'Not working properly',
      'Making unusual noise',
      'Not turning on',
      'Performance issues',
      'Temperature problems',
      'Strange smells',
    ];
  }
}

/// Response model for issue analysis
class IssueAnalysisResponse {
  final String diagnosis;
  final String severity; // 'low', 'medium', 'high', 'critical'
  final bool requiresProfessional;
  final List<String> possibleCauses;
  final List<String> quickChecks;
  final String? estimatedCost;

  IssueAnalysisResponse({
    required this.diagnosis,
    required this.severity,
    required this.requiresProfessional,
    required this.possibleCauses,
    required this.quickChecks,
    this.estimatedCost,
  });

  factory IssueAnalysisResponse.fromJson(Map<String, dynamic> json) {
    return IssueAnalysisResponse(
      diagnosis: json['diagnosis'] as String,
      severity: json['severity'] as String,
      requiresProfessional: json['requiresProfessional'] as bool,
      possibleCauses: (json['possibleCauses'] as List).cast<String>(),
      quickChecks: (json['quickChecks'] as List).cast<String>(),
      estimatedCost: json['estimatedCost'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'diagnosis': diagnosis,
      'severity': severity,
      'requiresProfessional': requiresProfessional,
      'possibleCauses': possibleCauses,
      'quickChecks': quickChecks,
      'estimatedCost': estimatedCost,
    };
  }
}

/// Response model for DIY troubleshooting
class DiyTroubleshootingResponse {
  final List<TroubleshootingStep> steps;
  final List<String> toolsNeeded;
  final String estimatedTime;
  final String difficultyLevel; // 'easy', 'moderate', 'difficult'
  final List<String> safetyWarnings;
  final String? whenToCallProfessional;

  DiyTroubleshootingResponse({
    required this.steps,
    required this.toolsNeeded,
    required this.estimatedTime,
    required this.difficultyLevel,
    required this.safetyWarnings,
    this.whenToCallProfessional,
  });

  factory DiyTroubleshootingResponse.fromJson(Map<String, dynamic> json) {
    return DiyTroubleshootingResponse(
      steps: (json['steps'] as List)
          .map((step) => TroubleshootingStep.fromJson(step))
          .toList(),
      toolsNeeded: (json['toolsNeeded'] as List).cast<String>(),
      estimatedTime: json['estimatedTime'] as String,
      difficultyLevel: json['difficultyLevel'] as String,
      safetyWarnings: (json['safetyWarnings'] as List).cast<String>(),
      whenToCallProfessional: json['whenToCallProfessional'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((step) => step.toJson()).toList(),
      'toolsNeeded': toolsNeeded,
      'estimatedTime': estimatedTime,
      'difficultyLevel': difficultyLevel,
      'safetyWarnings': safetyWarnings,
      'whenToCallProfessional': whenToCallProfessional,
    };
  }
}

/// Model for a troubleshooting step
class TroubleshootingStep {
  final int stepNumber;
  final String title;
  final String description;
  final List<String> actions;
  final String? expectedResult;
  final String? ifProblemPersists;

  TroubleshootingStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.actions,
    this.expectedResult,
    this.ifProblemPersists,
  });

  factory TroubleshootingStep.fromJson(Map<String, dynamic> json) {
    return TroubleshootingStep(
      stepNumber: json['stepNumber'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      actions: (json['actions'] as List).cast<String>(),
      expectedResult: json['expectedResult'] as String?,
      ifProblemPersists: json['ifProblemPersists'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stepNumber': stepNumber,
      'title': title,
      'description': description,
      'actions': actions,
      'expectedResult': expectedResult,
      'ifProblemPersists': ifProblemPersists,
    };
  }
}

/// Custom exception for AI troubleshooting service
class AiTroubleshootingException implements Exception {
  final String message;
  final int? statusCode;

  AiTroubleshootingException(this.message, {this.statusCode});

  @override
  String toString() => 'AiTroubleshootingException: $message';
}
