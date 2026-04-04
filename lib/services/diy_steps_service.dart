import 'dart:convert';
import '../core/utils/logger.dart';
import '../services/api_client.dart';

/// Service for AI-powered DIY maintenance instructions
/// Uses secure backend API instead of direct OpenAI calls
class DiyStepsService {
  static final DiyStepsService _instance = DiyStepsService._internal();
  factory DiyStepsService() => _instance;
  DiyStepsService._internal();

  final _apiClient = ApiClient();

  /// Generate DIY maintenance steps for a specific task
  ///
  /// Parameters:
  /// - [taskName]: Name of the maintenance task
  /// - [assetName]: Name of the asset (e.g., "Water Heater")
  /// - [assetLocation]: Location of the asset (e.g., "Basement")
  /// - [whyItMatters]: Why this maintenance is important
  /// - [estimatedEffort]: Estimated time/effort required
  ///
  /// Returns: DiyStepsResponse with generated steps
  Future<DiyStepsResponse> generateDiySteps({
    required String taskName,
    required String assetName,
    String? assetLocation,
    String? whyItMatters,
    String? estimatedEffort,
  }) async {
    try {
      final response = await _apiClient.post(
        '/ai/generate-diy-steps',
        body: {
          'taskName': taskName,
          'assetName': assetName,
          'assetLocation': assetLocation,
          'whyItMatters': whyItMatters,
          'estimatedEffort': estimatedEffort,
        },
        timeout: const Duration(seconds: 45), // AI generation may take longer
      );

      final raw = jsonDecode(response.body) as Map<String, dynamic>;
      final data = (raw['data'] ?? raw) as Map<String, dynamic>;
      return DiyStepsResponse.fromJson(data);
    } on ApiException catch (e) {
      throw DiyStepsException(
        'Failed to generate DIY steps: ${e.message}',
        statusCode: e.statusCode,
      );
    } on Object catch (e) {
      throw DiyStepsException('Unexpected error: $e');
    }
  }

  /// Get cached DIY steps if available (optional backend feature)
  Future<DiyStepsResponse?> getCachedSteps({
    required String taskName,
    required String assetName,
  }) async {
    try {
      final response = await _apiClient.get(
        '/ai/diy-steps',
        queryParameters: {'taskName': taskName, 'assetName': assetName},
      );

      if (response.statusCode == 200) {
        final raw = jsonDecode(response.body) as Map<String, dynamic>;
        final data = (raw['data'] ?? raw) as Map<String, dynamic>;
        return DiyStepsResponse.fromJson(data);
      }
      return null;
    } on Object catch (e) {
      // Return null if cache not found, don't throw error
      AppLogger.warning('No cached steps found: $e', tag: 'DiyStepsService', error: e);
      return null;
    }
  }
}

/// Response model for DIY steps
class DiyStepsResponse {
  final List<DiyStep> steps;
  final List<String> allToolsNeeded;
  final String? estimatedTime;
  final String? difficultyLevel;

  DiyStepsResponse({
    required this.steps,
    required this.allToolsNeeded,
    this.estimatedTime,
    this.difficultyLevel,
  });

  factory DiyStepsResponse.fromJson(Map<String, dynamic> json) {
    return DiyStepsResponse(
      steps: (json['steps'] as List)
          .map((step) => DiyStep.fromJson(step))
          .toList(),
      allToolsNeeded: (json['allTools'] as List? ?? []).cast<String>(),
      estimatedTime: json['estimatedTime'] as String?,
      difficultyLevel: json['difficultyLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'steps': steps.map((step) => step.toJson()).toList(),
      'allTools': allToolsNeeded,
      'estimatedTime': estimatedTime,
      'difficultyLevel': difficultyLevel,
    };
  }
}

/// Model for a single DIY step
class DiyStep {
  final String title;
  final String description;
  final List<String> instructions;
  final String? safetyNote;
  final List<String>? toolsNeeded;
  final String? imageUrl;
  final String? duration;
  final String? riskLevel;

  DiyStep({
    required this.title,
    required this.description,
    required this.instructions,
    this.safetyNote,
    this.toolsNeeded,
    this.imageUrl,
    this.duration,
    this.riskLevel,
  });

  factory DiyStep.fromJson(Map<String, dynamic> json) {
    return DiyStep(
      title: json['title'] as String,
      description: json['description'] as String,
      instructions: (json['instructions'] as List).cast<String>(),
      safetyNote: json['safetyNote'] as String?,
      toolsNeeded: json['toolsNeeded'] != null
          ? (json['toolsNeeded'] as List).cast<String>()
          : null,
      imageUrl: json['imageUrl'] as String?,
      duration: json['duration'] as String?,
      riskLevel: json['riskLevel'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'instructions': instructions,
      'safetyNote': safetyNote,
      'toolsNeeded': toolsNeeded,
      'imageUrl': imageUrl,
      'duration': duration,
      'riskLevel': riskLevel,
    };
  }
}

/// Custom exception for DIY steps service
class DiyStepsException implements Exception {
  final String message;
  final int? statusCode;

  DiyStepsException(this.message, {this.statusCode});

  @override
  String toString() => 'DiyStepsException: $message';
}
