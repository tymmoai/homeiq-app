// Maintenance Models for SquareTrade App

enum MaintenanceFrequency {
  monthly,
  quarterly,
  biAnnual,
  annual,
  seasonal,
  usageBased,
}

enum MaintenanceCategory {
  cleaning,
  inspection,
  replacement,
  service,
}

enum MaintenanceStatus {
  pending,
  completed,
  snoozed,
  skipped,
}

enum ReminderStatus {
  upcoming,
  overdue,
  snoozed,
  completed,
  skipped,
}

enum ReminderPriority {
  low,
  medium,
  high,
}

enum SkipReason {
  dontKnowHow,
  notNeeded,
  willDoLater,
}

class MaintenanceTask {
  final String id;
  final String name;
  final String description;
  final MaintenanceFrequency frequency;
  final String estimatedEffort;
  final String? safetyNote;
  final String whyItMatters;
  final MaintenanceCategory category;

  MaintenanceTask({
    required this.id,
    required this.name,
    required this.description,
    required this.frequency,
    required this.estimatedEffort,
    this.safetyNote,
    required this.whyItMatters,
    required this.category,
  });
}

class MaintenanceTemplate {
  final String id;
  final String assetType;
  final String? brand;
  final String? model;
  final List<MaintenanceTask> tasks;
  final String? lifecycleStage;

  MaintenanceTemplate({
    required this.id,
    required this.assetType,
    this.brand,
    this.model,
    required this.tasks,
    this.lifecycleStage,
  });
}

class MaintenanceRecord {
  final String id;
  final String assetId;
  final String taskId;
  final String taskName;
  final DateTime scheduledDate;
  final DateTime? completedDate;
  final MaintenanceStatus status;
  final SkipReason? skipReason;
  final DateTime? snoozedUntil;
  final String? evidence;
  final DateTime createdAt;
  final DateTime updatedAt;

  MaintenanceRecord({
    required this.id,
    required this.assetId,
    required this.taskId,
    required this.taskName,
    required this.scheduledDate,
    this.completedDate,
    required this.status,
    this.skipReason,
    this.snoozedUntil,
    this.evidence,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'taskId': taskId,
      'taskName': taskName,
      'scheduledDate': scheduledDate.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'status': status.name,
      'skipReason': skipReason?.name,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
      'evidence': evidence,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String,
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      status: MaintenanceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MaintenanceStatus.pending,
      ),
      skipReason: json['skipReason'] != null
          ? SkipReason.values.firstWhere(
              (e) => e.name == json['skipReason'],
              orElse: () => SkipReason.willDoLater,
            )
          : null,
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
      evidence: json['evidence'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class Reminder {
  final String id;
  final String assetId;
  final String assetName;
  final String? assetLocation;
  final String taskId;
  final String taskName;
  final String taskDescription;
  final String whyItMatters;
  final String estimatedEffort;
  final String? safetyNote;
  final DateTime dueDate;
  final ReminderStatus status;
  final ReminderPriority priority;
  final int riskLevel;
  final DateTime? snoozedUntil;
  final DateTime? completedDate;
  final SkipReason? skipReason;

  Reminder({
    required this.id,
    required this.assetId,
    required this.assetName,
    this.assetLocation,
    required this.taskId,
    required this.taskName,
    required this.taskDescription,
    required this.whyItMatters,
    required this.estimatedEffort,
    this.safetyNote,
    required this.dueDate,
    required this.status,
    required this.priority,
    required this.riskLevel,
    this.snoozedUntil,
    this.completedDate,
    this.skipReason,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetId': assetId,
      'assetName': assetName,
      'assetLocation': assetLocation,
      'taskId': taskId,
      'taskName': taskName,
      'taskDescription': taskDescription,
      'whyItMatters': whyItMatters,
      'estimatedEffort': estimatedEffort,
      'safetyNote': safetyNote,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'priority': priority.name,
      'riskLevel': riskLevel,
      'snoozedUntil': snoozedUntil?.toIso8601String(),
      'completedDate': completedDate?.toIso8601String(),
      'skipReason': skipReason?.name,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      assetId: json['assetId'] as String,
      assetName: json['assetName'] as String,
      assetLocation: json['assetLocation'] as String?,
      taskId: json['taskId'] as String,
      taskName: json['taskName'] as String,
      taskDescription: json['taskDescription'] as String,
      whyItMatters: json['whyItMatters'] as String,
      estimatedEffort: json['estimatedEffort'] as String,
      safetyNote: json['safetyNote'] as String?,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: ReminderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ReminderStatus.upcoming,
      ),
      priority: ReminderPriority.values.firstWhere(
        (e) => e.name == json['priority'],
        orElse: () => ReminderPriority.medium,
      ),
      riskLevel: json['riskLevel'] as int,
      snoozedUntil: json['snoozedUntil'] != null
          ? DateTime.parse(json['snoozedUntil'] as String)
          : null,
      completedDate: json['completedDate'] != null
          ? DateTime.parse(json['completedDate'] as String)
          : null,
      skipReason: json['skipReason'] != null
          ? SkipReason.values.firstWhere(
              (e) => e.name == json['skipReason'],
              orElse: () => SkipReason.willDoLater,
            )
          : null,
    );
  }
}

class AssetHealthScore {
  final String assetId;
  final double healthScore; // 1-10
  final double riskScore; // 1-10
  final DateTime lastUpdated;
  final HealthScoreFactors factors;

  AssetHealthScore({
    required this.assetId,
    required this.healthScore,
    required this.riskScore,
    required this.lastUpdated,
    required this.factors,
  });

  Map<String, dynamic> toJson() {
    return {
      'assetId': assetId,
      'healthScore': healthScore,
      'riskScore': riskScore,
      'lastUpdated': lastUpdated.toIso8601String(),
      'factors': factors.toJson(),
    };
  }

  factory AssetHealthScore.fromJson(Map<String, dynamic> json) {
    return AssetHealthScore(
      assetId: json['assetId'] as String,
      healthScore: (json['healthScore'] as num).toDouble(),
      riskScore: (json['riskScore'] as num).toDouble(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      factors: HealthScoreFactors.fromJson(json['factors'] as Map<String, dynamic>),
    );
  }
}

class HealthScoreFactors {
  final double age;
  final double maintenanceCompletionRate;
  final double issueHistory;
  final double brandReliability;

  HealthScoreFactors({
    required this.age,
    required this.maintenanceCompletionRate,
    required this.issueHistory,
    required this.brandReliability,
  });

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'maintenanceCompletionRate': maintenanceCompletionRate,
      'issueHistory': issueHistory,
      'brandReliability': brandReliability,
    };
  }

  factory HealthScoreFactors.fromJson(Map<String, dynamic> json) {
    return HealthScoreFactors(
      age: (json['age'] as num).toDouble(),
      maintenanceCompletionRate: (json['maintenanceCompletionRate'] as num).toDouble(),
      issueHistory: (json['issueHistory'] as num).toDouble(),
      brandReliability: (json['brandReliability'] as num).toDouble(),
    );
  }
}

class HomeHealthScore {
  final double overallHealth;
  final double overallRisk;
  final Map<String, CategoryScore> categoryScores;
  final DateTime lastUpdated;

  HomeHealthScore({
    required this.overallHealth,
    required this.overallRisk,
    required this.categoryScores,
    required this.lastUpdated,
  });
}

class CategoryScore {
  final double health;
  final double risk;
  final int assetCount;

  CategoryScore({
    required this.health,
    required this.risk,
    required this.assetCount,
  });
}

class ReplacementRecommendation {
  final String assetId;
  final String recommendation; // 'maintain' | 'repair' | 'replace'
  final int confidence; // 0-100
  final String reasoning;
  final String? estimatedFailureWindow;
  final String replacementUrgency; // 'low' | 'medium' | 'high'

  ReplacementRecommendation({
    required this.assetId,
    required this.recommendation,
    required this.confidence,
    required this.reasoning,
    this.estimatedFailureWindow,
    required this.replacementUrgency,
  });
}


