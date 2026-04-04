// Maintenance Service for SquareTrade App
import 'dart:async' show unawaited;
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/utils/logger.dart';
import '../../../services/api_client.dart';
import '../../home/data/home_mock_data.dart';
import '../../shared/models/maintenance_models.dart';

class MaintenanceService {
  static const String _maintenanceRecordsKey = 'maintenance_records';
  static const String _remindersKey = 'maintenance_reminders';
  static const String _healthScoresKey = 'health_scores';
  static const String _dataVersionKey = 'maintenance_data_version';

  /// Bump this whenever sample-data logic changes so stale caches are cleared.
  static const int _currentDataVersion = 6;

  /// Whether sample data has been checked during this app session.
  static bool _sampleDataEnsured = false;

  /// Allows resetting the session-level flag, e.g. after a hot-reload.
  static void resetSampleDataFlag() => _sampleDataEnsured = false;

  /// Force-regenerates all sample maintenance data regardless of version.
  /// Useful when the underlying asset list changes or for debugging.
  static Future<void> forceRegenerateData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_maintenanceRecordsKey);
    await prefs.remove(_remindersKey);
    await prefs.remove(_dataVersionKey);
    _sampleDataEnsured = false;
    await _ensureSampleDataExists();
  }

  // Get all maintenance records
  static Future<List<MaintenanceRecord>> getAllMaintenanceRecords() async {
    try {
      // Ensure sample data exists before reading
      await _ensureSampleDataExists();

      final prefs = await SharedPreferences.getInstance();
      final recordsJson = prefs.getStringList(_maintenanceRecordsKey) ?? [];
      return recordsJson
          .map((json) => MaintenanceRecord.fromJson(jsonDecode(json)))
          .toList();
    } on Object catch (_) {
      return [];
    }
  }

  // Get maintenance records for a specific asset
  static Future<List<MaintenanceRecord>> getAssetMaintenanceRecords(
    String assetId,
  ) async {
    final allRecords = await getAllMaintenanceRecords();
    return allRecords.where((record) => record.assetId == assetId).toList();
  }

  // Get completed maintenance records
  static Future<List<MaintenanceRecord>> getCompletedMaintenance({
    int days = 90,
  }) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    final allRecords = await getAllMaintenanceRecords();

    return allRecords.where((record) {
      if (record.status != MaintenanceStatus.completed) return false;
      if (record.completedDate == null) return false;
      return record.completedDate!.isAfter(cutoffDate);
    }).toList()..sort((a, b) => b.completedDate!.compareTo(a.completedDate!));
  }

  // Save maintenance records
  static Future<void> saveMaintenanceRecords(
    List<MaintenanceRecord> records,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = records
        .map((record) => jsonEncode(record.toJson()))
        .toList();
    await prefs.setStringList(_maintenanceRecordsKey, recordsJson);
  }

  // Mark maintenance as completed (for MaintenanceRecord) and sync with Reminders
  static Future<void> markAsCompleted(String recordId) async {
    final records = await getAllMaintenanceRecords();
    MaintenanceRecord? completedRecord;

    final updatedRecords = records.map((record) {
      if (record.id == recordId) {
        completedRecord = MaintenanceRecord(
          id: record.id,
          assetId: record.assetId,
          taskId: record.taskId,
          taskName: record.taskName,
          scheduledDate: record.scheduledDate,
          completedDate: DateTime.now(),
          status: MaintenanceStatus.completed,
          skipReason: record.skipReason,
          snoozedUntil: record.snoozedUntil,
          evidence: record.evidence,
          createdAt: record.createdAt,
          updatedAt: DateTime.now(),
        );
        return completedRecord!;
      }
      return record;
    }).toList();

    await saveMaintenanceRecords(updatedRecords);

    // SYNC: Also update corresponding Reminder if it exists
    if (completedRecord != null) {
      final reminders = await getAllReminders();
      final reminderIndex = reminders.indexWhere(
        (r) =>
            r.assetId == completedRecord!.assetId &&
            r.taskId == completedRecord!.taskId,
      );

      if (reminderIndex >= 0) {
        final reminder = reminders[reminderIndex];
        reminders[reminderIndex] = Reminder(
          id: reminder.id,
          assetId: reminder.assetId,
          assetName: reminder.assetName,
          assetLocation: reminder.assetLocation,
          taskId: reminder.taskId,
          taskName: reminder.taskName,
          taskDescription: reminder.taskDescription,
          whyItMatters: reminder.whyItMatters,
          estimatedEffort: reminder.estimatedEffort,
          safetyNote: reminder.safetyNote,
          dueDate: reminder.dueDate,
          status: ReminderStatus.completed,
          priority: reminder.priority,
          riskLevel: reminder.riskLevel,
          snoozedUntil: reminder.snoozedUntil,
          completedDate: DateTime.now(),
          skipReason: reminder.skipReason,
        );
        await saveReminders(reminders);
      }

      // Fire-and-forget: push completed record to backend as a maintenance log entry
      unawaited(_syncCompletedRecordToBackend(completedRecord!));
    }
  }

  /// Pushes a completed maintenance record to the backend [POST /api/v1/assets/:id/service-history].
  /// Silently ignored if assetId/homeId is unavailable or network fails.
  static Future<void> _syncCompletedRecordToBackend(
    MaintenanceRecord record,
  ) async {
    try {
      // Can only sync if we have a real assetId (not a sample/placeholder)
      final assetId = record.assetId;
      if (assetId.isEmpty) return;

      final api = ApiClient();
      await api.post(
        '/assets/$assetId/service-history',
        body: {
          'title': record.taskName,
          'description': 'Completed via HomeIQ app',
          'performedAt': (record.completedDate ?? DateTime.now())
              .toIso8601String(),
        },
      );
      AppLogger.info(
        'Maintenance record synced to backend: ${record.id}',
        tag: 'MaintenanceService',
      );
    } on Object catch (e) {
      AppLogger.warning(
        'Backend maintenance sync failed (non-fatal): $e',
        tag: 'MaintenanceService',
        error: e,
      );
    }
  }

  // Mark reminder as completed (for Reminder) and sync with MaintenanceRecords
  static Future<void> markReminderAsCompleted(String reminderId) async {
    final reminders = await getAllReminders();
    Reminder? completedReminder;

    final updatedReminders = reminders.map((reminder) {
      if (reminder.id == reminderId) {
        completedReminder = Reminder(
          id: reminder.id,
          assetId: reminder.assetId,
          assetName: reminder.assetName,
          assetLocation: reminder.assetLocation,
          taskId: reminder.taskId,
          taskName: reminder.taskName,
          taskDescription: reminder.taskDescription,
          whyItMatters: reminder.whyItMatters,
          estimatedEffort: reminder.estimatedEffort,
          safetyNote: reminder.safetyNote,
          dueDate: reminder.dueDate,
          status: ReminderStatus.completed,
          priority: reminder.priority,
          riskLevel: reminder.riskLevel,
          snoozedUntil: reminder.snoozedUntil,
          completedDate: DateTime.now(),
          skipReason: reminder.skipReason,
        );
        return completedReminder!;
      }
      return reminder;
    }).toList();

    await saveReminders(updatedReminders);

    // SYNC: Also create/update corresponding MaintenanceRecord
    if (completedReminder != null) {
      final records = await getAllMaintenanceRecords();
      final recordId =
          'mr_${completedReminder!.assetId}_${completedReminder!.taskId}';
      final existingIndex = records.indexWhere((r) => r.id == recordId);

      final maintenanceRecord = MaintenanceRecord(
        id: recordId,
        assetId: completedReminder!.assetId,
        taskId: completedReminder!.taskId,
        taskName: completedReminder!.taskName,
        scheduledDate: completedReminder!.dueDate,
        completedDate: DateTime.now(),
        status: MaintenanceStatus.completed,
        createdAt: existingIndex >= 0
            ? records[existingIndex].createdAt
            : DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (existingIndex >= 0) {
        records[existingIndex] = maintenanceRecord;
      } else {
        records.add(maintenanceRecord);
      }

      await saveMaintenanceRecords(records);
    }
  }

  // Snooze maintenance reminder (for MaintenanceRecord)
  static Future<void> snoozeReminder(
    String recordId,
    DateTime snoozeUntil,
  ) async {
    final records = await getAllMaintenanceRecords();
    final updatedRecords = records.map((record) {
      if (record.id == recordId) {
        return MaintenanceRecord(
          id: record.id,
          assetId: record.assetId,
          taskId: record.taskId,
          taskName: record.taskName,
          scheduledDate: record.scheduledDate,
          completedDate: record.completedDate,
          status: MaintenanceStatus.snoozed,
          skipReason: record.skipReason,
          snoozedUntil: snoozeUntil,
          evidence: record.evidence,
          createdAt: record.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return record;
    }).toList();

    await saveMaintenanceRecords(updatedRecords);
  }

  // Snooze reminder (for Reminder) and sync with MaintenanceRecords
  static Future<void> snoozeReminderById(
    String reminderId,
    DateTime snoozeUntil,
  ) async {
    final reminders = await getAllReminders();
    Reminder? snoozedReminder;

    final updatedReminders = reminders.map((reminder) {
      if (reminder.id == reminderId) {
        snoozedReminder = Reminder(
          id: reminder.id,
          assetId: reminder.assetId,
          assetName: reminder.assetName,
          assetLocation: reminder.assetLocation,
          taskId: reminder.taskId,
          taskName: reminder.taskName,
          taskDescription: reminder.taskDescription,
          whyItMatters: reminder.whyItMatters,
          estimatedEffort: reminder.estimatedEffort,
          safetyNote: reminder.safetyNote,
          dueDate: reminder.dueDate,
          status: ReminderStatus.snoozed,
          priority: reminder.priority,
          riskLevel: reminder.riskLevel,
          snoozedUntil: snoozeUntil,
          completedDate: reminder.completedDate,
          skipReason: reminder.skipReason,
        );
        return snoozedReminder!;
      }
      return reminder;
    }).toList();

    await saveReminders(updatedReminders);

    // SYNC: Also update corresponding MaintenanceRecord
    if (snoozedReminder != null) {
      final records = await getAllMaintenanceRecords();
      final recordId =
          'mr_${snoozedReminder!.assetId}_${snoozedReminder!.taskId}';
      final recordIndex = records.indexWhere((r) => r.id == recordId);

      if (recordIndex >= 0) {
        final record = records[recordIndex];
        records[recordIndex] = MaintenanceRecord(
          id: record.id,
          assetId: record.assetId,
          taskId: record.taskId,
          taskName: record.taskName,
          scheduledDate: record.scheduledDate,
          completedDate: record.completedDate,
          status: MaintenanceStatus.snoozed,
          skipReason: record.skipReason,
          snoozedUntil: snoozeUntil,
          evidence: record.evidence,
          createdAt: record.createdAt,
          updatedAt: DateTime.now(),
        );
        await saveMaintenanceRecords(records);
      }
    }
  }

  // Skip maintenance reminder (for MaintenanceRecord)
  static Future<void> skipReminder(String recordId, SkipReason reason) async {
    final records = await getAllMaintenanceRecords();
    final updatedRecords = records.map((record) {
      if (record.id == recordId) {
        return MaintenanceRecord(
          id: record.id,
          assetId: record.assetId,
          taskId: record.taskId,
          taskName: record.taskName,
          scheduledDate: record.scheduledDate,
          completedDate: record.completedDate,
          status: MaintenanceStatus.skipped,
          skipReason: reason,
          snoozedUntil: record.snoozedUntil,
          evidence: record.evidence,
          createdAt: record.createdAt,
          updatedAt: DateTime.now(),
        );
      }
      return record;
    }).toList();

    await saveMaintenanceRecords(updatedRecords);
  }

  // Skip reminder (for Reminder) and sync with MaintenanceRecords
  static Future<void> skipReminderById(
    String reminderId,
    SkipReason reason,
  ) async {
    final reminders = await getAllReminders();
    Reminder? skippedReminder;

    final updatedReminders = reminders.map((reminder) {
      if (reminder.id == reminderId) {
        skippedReminder = Reminder(
          id: reminder.id,
          assetId: reminder.assetId,
          assetName: reminder.assetName,
          assetLocation: reminder.assetLocation,
          taskId: reminder.taskId,
          taskName: reminder.taskName,
          taskDescription: reminder.taskDescription,
          whyItMatters: reminder.whyItMatters,
          estimatedEffort: reminder.estimatedEffort,
          safetyNote: reminder.safetyNote,
          dueDate: reminder.dueDate,
          status: ReminderStatus.skipped,
          priority: reminder.priority,
          riskLevel: reminder.riskLevel,
          snoozedUntil: reminder.snoozedUntil,
          completedDate: reminder.completedDate,
          skipReason: reason,
        );
        return skippedReminder!;
      }
      return reminder;
    }).toList();

    await saveReminders(updatedReminders);

    // SYNC: Also update corresponding MaintenanceRecord
    if (skippedReminder != null) {
      final records = await getAllMaintenanceRecords();
      final recordId =
          'mr_${skippedReminder!.assetId}_${skippedReminder!.taskId}';
      final recordIndex = records.indexWhere((r) => r.id == recordId);

      if (recordIndex >= 0) {
        final record = records[recordIndex];
        records[recordIndex] = MaintenanceRecord(
          id: record.id,
          assetId: record.assetId,
          taskId: record.taskId,
          taskName: record.taskName,
          scheduledDate: record.scheduledDate,
          completedDate: record.completedDate,
          status: MaintenanceStatus.skipped,
          skipReason: reason,
          snoozedUntil: record.snoozedUntil,
          evidence: record.evidence,
          createdAt: record.createdAt,
          updatedAt: DateTime.now(),
        );
        await saveMaintenanceRecords(records);
      }
    }
  }

  // Get all reminders
  static Future<List<Reminder>> getAllReminders() async {
    try {
      // Ensure sample data exists before reading
      await _ensureSampleDataExists();

      final prefs = await SharedPreferences.getInstance();
      final remindersJson = prefs.getStringList(_remindersKey) ?? [];

      if (remindersJson.isEmpty) {
        return [];
      }

      return remindersJson
          .map((json) => Reminder.fromJson(jsonDecode(json)))
          .toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    } on Object catch (_) {
      return [];
    }
  }

  // Save reminders
  static Future<void> saveReminders(List<Reminder> reminders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remindersJson = reminders
          .map((reminder) => jsonEncode(reminder.toJson()))
          .toList();
      await prefs.setStringList(_remindersKey, remindersJson);
    } on Object catch (_) {
      // Handle error silently
    }
  }

  // Get reminders for a specific asset
  static Future<List<Reminder>> getAssetReminders(String assetId) async {
    final allReminders = await getAllReminders();
    return allReminders
        .where((reminder) => reminder.assetId == assetId)
        .toList();
  }

  // Sync MaintenanceRecord to create/update corresponding Reminder
  // This ensures that maintenance records created from asset detail screens
  // appear in the main maintenance dashboard
  static Future<void> syncRecordToReminder(
    MaintenanceRecord record, {
    String? assetName,
    String? assetLocation,
    required String taskDescription,
    required String whyItMatters,
    required String estimatedEffort,
    String? safetyNote,
    required ReminderPriority priority,
    required int riskLevel,
  }) async {
    final reminders = await getAllReminders();

    // Try to find existing reminder by assetId and taskId
    final reminderIndex = reminders.indexWhere(
      (r) => r.assetId == record.assetId && r.taskId == record.taskId,
    );

    // Map MaintenanceStatus to ReminderStatus
    ReminderStatus reminderStatus;
    switch (record.status) {
      case MaintenanceStatus.completed:
        reminderStatus = ReminderStatus.completed;
        break;
      case MaintenanceStatus.snoozed:
        reminderStatus = ReminderStatus.snoozed;
        break;
      case MaintenanceStatus.skipped:
        reminderStatus = ReminderStatus.skipped;
        break;
      case MaintenanceStatus.pending:
        // Check if overdue
        if (record.scheduledDate.isBefore(DateTime.now())) {
          reminderStatus = ReminderStatus.overdue;
        } else {
          reminderStatus = ReminderStatus.upcoming;
        }
    }

    final reminder = Reminder(
      id: reminderIndex >= 0 ? reminders[reminderIndex].id : 'r_${record.id}',
      assetId: record.assetId,
      assetName:
          assetName ??
          (reminderIndex >= 0 ? reminders[reminderIndex].assetName : 'Asset'),
      assetLocation:
          assetLocation ??
          (reminderIndex >= 0 ? reminders[reminderIndex].assetLocation : null),
      taskId: record.taskId,
      taskName: record.taskName,
      taskDescription: taskDescription,
      whyItMatters: whyItMatters,
      estimatedEffort: estimatedEffort,
      safetyNote: safetyNote,
      dueDate: record.scheduledDate,
      status: reminderStatus,
      priority: priority,
      riskLevel: riskLevel,
      snoozedUntil: record.snoozedUntil,
      completedDate: record.completedDate,
      skipReason: record.skipReason,
    );

    if (reminderIndex >= 0) {
      reminders[reminderIndex] = reminder;
    } else {
      reminders.add(reminder);
    }

    await saveReminders(reminders);
  }

  // Get health score for asset
  static Future<AssetHealthScore?> getAssetHealthScore(String assetId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = prefs.getString(_healthScoresKey);
      if (scoresJson == null) return null;

      final scores = jsonDecode(scoresJson) as Map<String, dynamic>;
      final scoreData = scores[assetId];
      if (scoreData == null) return null;

      return AssetHealthScore.fromJson(scoreData as Map<String, dynamic>);
    } on Object catch (_) {
      return null;
    }
  }

  // Save health score
  static Future<void> saveHealthScore(AssetHealthScore score) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final scoresJson = prefs.getString(_healthScoresKey);
      Map<String, dynamic> scores = {};

      if (scoresJson != null) {
        scores = jsonDecode(scoresJson) as Map<String, dynamic>;
      }

      scores[score.assetId] = score.toJson();
      await prefs.setString(_healthScoresKey, jsonEncode(scores));
    } on Object catch (_) {
      // Handle error
    }
  }

  // Initialize and sync all maintenance data
  // This ensures reminders and records are in sync when the app starts
  static Future<void> initializeMaintenanceData() async {
    try {
      // Ensure sample records & reminders exist for all known assets
      await _ensureSampleDataExists();

      // Get both data sources
      final reminders = await getAllReminders();
      final records = await getAllMaintenanceRecords();

      // Create a map of existing reminders by assetId+taskId for quick lookup
      final reminderMap = <String, Reminder>{};
      for (final reminder in reminders) {
        final key = '${reminder.assetId}_${reminder.taskId}';
        reminderMap[key] = reminder;
      }

      // For each maintenance record, ensure there's a corresponding reminder
      final updatedReminders = List<Reminder>.from(reminders);
      bool changed = false;
      for (final record in records) {
        final key = '${record.assetId}_${record.taskId}';

        // Convert MaintenanceStatus to ReminderStatus
        ReminderStatus reminderStatus;
        switch (record.status) {
          case MaintenanceStatus.completed:
            reminderStatus = ReminderStatus.completed;
            break;
          case MaintenanceStatus.snoozed:
            reminderStatus = ReminderStatus.snoozed;
            break;
          case MaintenanceStatus.skipped:
            reminderStatus = ReminderStatus.skipped;
            break;
          case MaintenanceStatus.pending:
            // Check if overdue
            if (record.scheduledDate.isBefore(DateTime.now())) {
              reminderStatus = ReminderStatus.overdue;
            } else {
              reminderStatus = ReminderStatus.upcoming;
            }
        }

        if (!reminderMap.containsKey(key)) {
          // Create new reminder from record
          final meta = _getTaskMeta(record.taskId);
          final assetInfo = _findAssetInfo(record.assetId);
          final newReminder = Reminder(
            id: 'r_${record.id}',
            assetId: record.assetId,
            assetName: assetInfo?['name'] ?? 'Asset',
            assetLocation: assetInfo?['location'],
            taskId: record.taskId,
            taskName: record.taskName,
            taskDescription: meta['description']!,
            whyItMatters: meta['whyItMatters']!,
            estimatedEffort: meta['effort']!,
            safetyNote: meta['safetyNote'],
            dueDate: record.scheduledDate,
            status: reminderStatus,
            priority: _parsePriority(meta['priority']!),
            riskLevel: int.tryParse(meta['riskLevel']!) ?? 3,
            snoozedUntil: record.snoozedUntil,
            completedDate: record.completedDate,
            skipReason: record.skipReason,
          );
          updatedReminders.add(newReminder);
          changed = true;
        } else {
          // Update existing reminder to match record status
          final existingReminder = reminderMap[key]!;
          if (existingReminder.status != reminderStatus ||
              existingReminder.completedDate != record.completedDate ||
              existingReminder.snoozedUntil != record.snoozedUntil ||
              existingReminder.skipReason != record.skipReason) {
            // Update the reminder
            final index = updatedReminders.indexWhere(
              (r) => r.id == existingReminder.id,
            );
            if (index >= 0) {
              updatedReminders[index] = Reminder(
                id: existingReminder.id,
                assetId: existingReminder.assetId,
                assetName: existingReminder.assetName,
                assetLocation: existingReminder.assetLocation,
                taskId: existingReminder.taskId,
                taskName: existingReminder.taskName,
                taskDescription: existingReminder.taskDescription,
                whyItMatters: existingReminder.whyItMatters,
                estimatedEffort: existingReminder.estimatedEffort,
                safetyNote: existingReminder.safetyNote,
                dueDate: record.scheduledDate,
                status: reminderStatus,
                priority: existingReminder.priority,
                riskLevel: existingReminder.riskLevel,
                snoozedUntil: record.snoozedUntil,
                completedDate: record.completedDate,
                skipReason: record.skipReason,
              );
              changed = true;
            }
          }
        }
      }

      // Save updated reminders only if something changed
      if (changed) {
        await saveReminders(updatedReminders);
      }
    } on Object catch (_) {
      // Handle error silently - initialization is best effort
    }
  }

  // ─── Sample Data Generation ────────────────────────────────────────

  /// Ensures sample maintenance records and reminders exist for **every**
  /// known asset. Uses a version key in SharedPreferences so that stale data
  /// from an older version is automatically regenerated.
  ///
  /// Called lazily on first access so both the main Maintenance dashboard
  /// and individual asset-detail maintenance tabs see the same data.
  static Future<void> _ensureSampleDataExists() async {
    if (_sampleDataEnsured) return;
    _sampleDataEnsured = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedVersion = prefs.getInt(_dataVersionKey) ?? 0;

      if (storedVersion < _currentDataVersion) {
        // Version mismatch → wipe old data and regenerate from scratch so the
        // user always sees the latest, consistent sample data.
        await prefs.remove(_maintenanceRecordsKey);
        await prefs.remove(_remindersKey);
      }

      final existingRecords = prefs.getStringList(_maintenanceRecordsKey) ?? [];
      final existingReminders = prefs.getStringList(_remindersKey) ?? [];

      if (existingRecords.isNotEmpty || existingReminders.isNotEmpty) {
        return;
      }

      // No mock data is auto-generated anymore.
      // Maintenance records are only created when the user adds assets
      // via addMaintenanceForAsset() or the asset detail flow.
      await prefs.setInt(_dataVersionKey, _currentDataVersion);
    } on Object catch (_) {
      // Ignore – best effort
    }
  }

  /// Generates maintenance records and reminders for a specific user-added asset.
  /// Call this when the user adds a new asset so maintenance tasks appear.
  static Future<void> addMaintenanceForAsset({
    required String assetId,
    required String assetName,
    required String assetType,
    String? assetLocation,
  }) async {
    final existingRecords = await getAllMaintenanceRecords();
    final existingAssetIds = existingRecords.map((r) => r.assetId).toSet();

    // Skip if this asset already has maintenance records
    if (existingAssetIds.contains(assetId)) return;

    final records = generateSampleRecordsForAsset(
      assetId,
      assetName,
      assetType,
    );
    if (records.isEmpty) return;

    final newReminders = <Reminder>[];
    for (final record in records) {
      newReminders.add(
        _createReminderFromRecord(record, assetName, assetLocation),
      );
    }

    final allRecords = await getAllMaintenanceRecords();
    allRecords.addAll(records);
    await saveMaintenanceRecords(allRecords);

    final allReminders = await getAllReminders();
    allReminders.addAll(newReminders);
    await saveReminders(allReminders);
  }

  /// Looks up asset info from [HomeScreenMockData.assets] by ID.
  static Map<String, dynamic>? _findAssetInfo(String assetId) {
    try {
      return HomeScreenMockData.assets.firstWhere(
        (a) => a['id'].toString() == assetId,
      );
    } on Object catch (_) {
      return null;
    }
  }

  /// Generates sample [MaintenanceRecord]s for a single asset based on its
  /// type. Uses the SAME task IDs, names and schedule logic that the asset
  /// detail maintenance-tab used to generate locally.
  ///
  /// Public so that [MaintenanceTabWidget] can use it as a fallback for
  /// user-added assets not in the initial mock set, eliminating duplicate
  /// generation code.
  static List<MaintenanceRecord> generateSampleRecordsForAsset(
    String assetId,
    String assetName,
    String assetType,
  ) {
    final now = DateTime.now();
    final List<MaintenanceRecord> records = [];
    final type = assetType.toLowerCase();

    // ── Refrigerator ──
    if (type.contains('refrigerator') || type.contains('fridge')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'fridge-gasket-cleaning',
          taskName: 'Door Gasket Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 1),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'fridge-coil-cleaning',
          taskName: 'Condenser Coil Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 14),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now.subtract(const Duration(days: 45)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'fridge-filter-change',
          taskName: 'Water Filter Replacement',
          scheduledDate: DateTime(now.year, now.month - 1, 10),
          completedDate: DateTime(now.year, now.month - 1, 10),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 70)),
          updatedAt: now.subtract(const Duration(days: 50)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'fridge-ice-maker',
          taskName: 'Ice Maker Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 20),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 40)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'fridge-defrost',
          taskName: 'Freezer Defrost',
          scheduledDate: DateTime(now.year, now.month, 5),
          snoozedUntil: DateTime(now.year, now.month, 12),
          status: MaintenanceStatus.snoozed,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
      ]);
    }
    // ── Air Conditioner ──
    else if (type.contains('air conditioner') ||
        type.contains('ac unit') ||
        type.contains('ac living') ||
        type.contains('ac bedroom')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'ac-filter-replacement',
          taskName: 'Air Filter Replacement',
          scheduledDate: now.subtract(const Duration(days: 150)),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 180)),
          updatedAt: now.subtract(const Duration(days: 150)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'ac-coil-cleaning',
          taskName: 'Evaporator Coil Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 14),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now.subtract(const Duration(days: 45)),
        ),
      ]);
    }
    // ── Microwave ──
    else if (type.contains('microwave')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'microwave-interior-clean',
          taskName: 'Interior Deep Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 7),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'microwave-turntable-clean',
          taskName: 'Turntable & Roller Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 12),
          completedDate: DateTime(now.year, now.month - 1, 12),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 50)),
          updatedAt: now.subtract(const Duration(days: 38)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'microwave-vent-filter',
          taskName: 'Vent Filter Inspection',
          scheduledDate: DateTime(now.year, now.month, 18),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month + 1, 2),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'microwave-door-seal',
          taskName: 'Door Seal Check',
          scheduledDate: DateTime(now.year, now.month - 2, 5),
          completedDate: DateTime(now.year, now.month - 2, 6),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 80)),
          updatedAt: now.subtract(const Duration(days: 62)),
        ),
      ]);
    }
    // ── Television ──
    else if (type.contains('television') || type.contains('tv')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'tv-screen-clean',
          taskName: 'Screen Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 5),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 22)),
          updatedAt: now.subtract(const Duration(days: 22)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'tv-vent-dust',
          taskName: 'Ventilation Dusting',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 15),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 52)),
          updatedAt: now.subtract(const Duration(days: 38)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'tv-firmware-update',
          taskName: 'Firmware Update Check',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'tv-cable-check',
          taskName: 'Cable Connection Check',
          scheduledDate: DateTime(now.year, now.month - 2, 28),
          completedDate: DateTime(now.year, now.month - 2, 28),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 72)),
          updatedAt: now.subtract(const Duration(days: 48)),
        ),
      ]);
    }
    // ── Washing Machine ──
    else if (type.contains('washing machine') || type.contains('washer')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'washer-drum-cleaning',
          taskName: 'Drum Cleaning Cycle',
          scheduledDate: DateTime(now.year, now.month + 1, 3),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'washer-filter-clean',
          taskName: 'Drain Filter Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 8),
          completedDate: DateTime(now.year, now.month - 1, 8),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'washer-hose-inspection',
          taskName: 'Inlet Hose Inspection',
          scheduledDate: DateTime(now.year, now.month, 12),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 22),
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'washer-gasket-wipe',
          taskName: 'Door Gasket Wipe Down',
          scheduledDate: DateTime(now.year, now.month - 2, 15),
          completedDate: DateTime(now.year, now.month - 2, 16),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 75)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'washer-dispenser-clean',
          taskName: 'Detergent Dispenser Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 28),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 40)),
          updatedAt: now.subtract(const Duration(days: 18)),
        ),
      ]);
    }
    // ── Dishwasher ──
    else if (type.contains('dishwasher')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'dishwasher-spray-arms',
          taskName: 'Spray Arm Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 10),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'dishwasher-filter-clean',
          taskName: 'Filter Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 5),
          completedDate: DateTime(now.year, now.month - 1, 5),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'dishwasher-descale',
          taskName: 'Descaling Treatment',
          scheduledDate: DateTime(now.year, now.month, 15),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 25),
          createdAt: now.subtract(const Duration(days: 40)),
          updatedAt: now.subtract(const Duration(days: 7)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'dishwasher-door-gasket',
          taskName: 'Door Gasket Inspection',
          scheduledDate: DateTime(now.year, now.month - 2, 20),
          completedDate: DateTime(now.year, now.month - 2, 21),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 85)),
          updatedAt: now.subtract(const Duration(days: 58)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'dishwasher-drain-check',
          taskName: 'Drain Hose Check',
          scheduledDate: DateTime(now.year, now.month - 1, 22),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 48)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
      ]);
    }
    // ── Water Heater ──
    else if (type.contains('water heater')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'heater-anode-rod',
          taskName: 'Anode Rod Inspection',
          scheduledDate: DateTime(now.year, now.month + 1, 15),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 35)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'heater-tank-flush',
          taskName: 'Tank Sediment Flush',
          scheduledDate: DateTime(now.year, now.month - 1, 10),
          completedDate: DateTime(now.year, now.month - 1, 10),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 65)),
          updatedAt: now.subtract(const Duration(days: 48)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'heater-pressure-valve',
          taskName: 'Pressure Relief Valve Test',
          scheduledDate: DateTime(now.year, now.month, 8),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 18),
          createdAt: now.subtract(const Duration(days: 42)),
          updatedAt: now.subtract(const Duration(days: 12)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'heater-thermostat',
          taskName: 'Thermostat Calibration',
          scheduledDate: DateTime(now.year, now.month - 2, 25),
          completedDate: DateTime(now.year, now.month - 2, 25),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 95)),
          updatedAt: now.subtract(const Duration(days: 65)),
        ),
      ]);
    }
    // ── HVAC System ──
    else if (type.contains('hvac') ||
        type.contains('air condition') ||
        type.contains('split system')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'hvac-filter-change',
          taskName: 'HVAC Filter Replacement',
          scheduledDate: DateTime(now.year, now.month + 1, 1),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'hvac-duct-inspection',
          taskName: 'Ductwork Inspection',
          scheduledDate: DateTime(now.year, now.month - 1, 18),
          completedDate: DateTime(now.year, now.month - 1, 18),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 58)),
          updatedAt: now.subtract(const Duration(days: 35)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'hvac-blower-clean',
          taskName: 'Blower Motor Cleaning',
          scheduledDate: DateTime(now.year, now.month, 22),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month + 1, 5),
          createdAt: now.subtract(const Duration(days: 38)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'hvac-refrigerant',
          taskName: 'Refrigerant Check',
          scheduledDate: DateTime(now.year, now.month - 2, 12),
          completedDate: DateTime(now.year, now.month - 2, 13),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 82)),
          updatedAt: now.subtract(const Duration(days: 52)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'hvac-thermostat',
          taskName: 'Thermostat Battery Change',
          scheduledDate: DateTime(now.year, now.month - 1, 30),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 45)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
      ]);
    }
    // ── Plumbing ──
    else if (type.contains('plumbing')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'plumbing-drain-clean',
          taskName: 'Drain Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 12),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 32)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'plumbing-leak-check',
          taskName: 'Leak Inspection',
          scheduledDate: DateTime(now.year, now.month - 1, 22),
          completedDate: DateTime(now.year, now.month - 1, 22),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 62)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'plumbing-faucet-clean',
          taskName: 'Faucet Aerator Cleaning',
          scheduledDate: DateTime(now.year, now.month, 5),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 15),
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'plumbing-valve-test',
          taskName: 'Shut-off Valve Test',
          scheduledDate: DateTime(now.year, now.month - 2, 8),
          completedDate: DateTime(now.year, now.month - 2, 9),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 78)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
      ]);
    }
    // ── Computer / Laptop ──
    else if (type.contains('computer') || type.contains('laptop')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'computer-disk-cleanup',
          taskName: 'Disk Cleanup & Optimization',
          scheduledDate: DateTime(now.year, now.month + 1, 8),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'computer-dust-clean',
          taskName: 'Fan & Vent Dusting',
          scheduledDate: DateTime(now.year, now.month - 1, 20),
          completedDate: DateTime(now.year, now.month - 1, 20),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 38)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'computer-backup',
          taskName: 'Data Backup Verification',
          scheduledDate: DateTime(now.year, now.month, 15),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 25),
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'computer-software-update',
          taskName: 'Software Update Check',
          scheduledDate: DateTime(now.year, now.month - 2, 10),
          completedDate: DateTime(now.year, now.month - 2, 11),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 75)),
          updatedAt: now.subtract(const Duration(days: 52)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'computer-antivirus',
          taskName: 'Antivirus Scan',
          scheduledDate: DateTime(now.year, now.month - 1, 28),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 42)),
          updatedAt: now.subtract(const Duration(days: 18)),
        ),
      ]);
    }
    // ── Audio / Speaker ──
    else if (type.contains('audio') || type.contains('speaker')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'audio-dust-clean',
          taskName: 'Speaker Dust Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 10),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'audio-cable-check',
          taskName: 'Cable Connection Check',
          scheduledDate: DateTime(now.year, now.month - 1, 18),
          completedDate: DateTime(now.year, now.month - 1, 18),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 58)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'audio-firmware',
          taskName: 'Firmware Update Check',
          scheduledDate: DateTime(now.year, now.month, 12),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 22),
          createdAt: now.subtract(const Duration(days: 38)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'audio-woofer-check',
          taskName: 'Subwoofer Inspection',
          scheduledDate: DateTime(now.year, now.month - 2, 15),
          completedDate: DateTime(now.year, now.month - 2, 16),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 72)),
          updatedAt: now.subtract(const Duration(days: 50)),
        ),
      ]);
    }
    // ── Smart Device ──
    else if (type.contains('smart device') || type.contains('smart home')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'smart-firmware-update',
          taskName: 'Firmware Update',
          scheduledDate: DateTime(now.year, now.month + 1, 3),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'smart-connection-check',
          taskName: 'WiFi Connection Check',
          scheduledDate: DateTime(now.year, now.month - 1, 12),
          completedDate: DateTime(now.year, now.month - 1, 12),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 52)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'smart-device-clean',
          taskName: 'Device Cleaning',
          scheduledDate: DateTime(now.year, now.month, 8),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 18),
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'smart-privacy-review',
          taskName: 'Privacy Settings Review',
          scheduledDate: DateTime(now.year, now.month - 2, 22),
          completedDate: DateTime(now.year, now.month - 2, 22),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 68)),
          updatedAt: now.subtract(const Duration(days: 48)),
        ),
      ]);
    }
    // ── Lighting ──
    else if (type.contains('lighting') || type.contains('light')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'light-bulb-check',
          taskName: 'Bulb Replacement Check',
          scheduledDate: DateTime(now.year, now.month + 1, 6),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'light-fixture-clean',
          taskName: 'Fixture Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 15),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'light-dimmer-check',
          taskName: 'Dimmer Switch Test',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 12)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'light-app-update',
          taskName: 'Smart App Update',
          scheduledDate: DateTime(now.year, now.month - 2, 18),
          completedDate: DateTime(now.year, now.month - 2, 19),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 70)),
          updatedAt: now.subtract(const Duration(days: 52)),
        ),
      ]);
    }
    // ── Dryer ──
    else if (type.contains('dryer')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'dryer-lint-trap',
          taskName: 'Lint Trap Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 2),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 20)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'dryer-vent-cleaning',
          taskName: 'Exhaust Vent Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 10),
          completedDate: DateTime(now.year, now.month - 1, 10),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'dryer-drum-wipe',
          taskName: 'Drum Interior Wipe Down',
          scheduledDate: DateTime(now.year, now.month, 14),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 22),
          createdAt: now.subtract(const Duration(days: 33)),
          updatedAt: now.subtract(const Duration(days: 7)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'dryer-moisture-sensor',
          taskName: 'Moisture Sensor Cleaning',
          scheduledDate: DateTime(now.year, now.month - 2, 20),
          completedDate: DateTime(now.year, now.month - 2, 21),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 82)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'dryer-hose-inspect',
          taskName: 'Duct Hose Inspection',
          scheduledDate: DateTime(now.year, now.month - 1, 28),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 48)),
          updatedAt: now.subtract(const Duration(days: 18)),
        ),
      ]);
    }
    // ── Range / Stove / Oven ──
    else if (type.contains('range') ||
        type.contains('stove') ||
        type.contains('oven') ||
        type.contains('cooktop')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'oven-self-clean',
          taskName: 'Oven Interior Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 6),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'oven-burner-check',
          taskName: 'Burner / Heating Element Check',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 15),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 58)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'oven-drip-pan',
          taskName: 'Drip Pan & Grate Cleaning',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 9)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'oven-door-seal',
          taskName: 'Door Gasket & Seal Inspection',
          scheduledDate: DateTime(now.year, now.month - 2, 8),
          completedDate: DateTime(now.year, now.month - 2, 9),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 80)),
          updatedAt: now.subtract(const Duration(days: 58)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'oven-vent-hood',
          taskName: 'Range Hood & Filter Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 22),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 48)),
          updatedAt: now.subtract(const Duration(days: 20)),
        ),
      ]);
    }
    // ── Heating & Cooling / Furnace / Heat Pump ──
    else if (type.contains('heating') ||
        type.contains('furnace') ||
        type.contains('heat pump') ||
        type.contains('mini split') ||
        type.contains('cooling')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'furnace-filter-replace',
          taskName: 'Air Filter Replacement',
          scheduledDate: DateTime(now.year, now.month + 1, 1),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'furnace-annual-tune',
          taskName: 'Annual Tune-Up & Inspection',
          scheduledDate: DateTime(now.year, now.month - 1, 18),
          completedDate: DateTime(now.year, now.month - 1, 18),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 62)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'furnace-thermostat-battery',
          taskName: 'Thermostat Battery Check',
          scheduledDate: DateTime(now.year, now.month, 15),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month + 1, 2),
          createdAt: now.subtract(const Duration(days: 38)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'furnace-carbon-check',
          taskName: 'Carbon Monoxide Detector Test',
          scheduledDate: DateTime(now.year, now.month - 2, 5),
          completedDate: DateTime(now.year, now.month - 2, 6),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 75)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_5',
          assetId: assetId,
          taskId: 'furnace-vent-blower',
          taskName: 'Blower & Vent Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 28),
          status: MaintenanceStatus.skipped,
          createdAt: now.subtract(const Duration(days: 45)),
          updatedAt: now.subtract(const Duration(days: 22)),
        ),
      ]);
    }
    // ── Garbage Disposal ──
    else if (type.contains('garbage disposal') ||
        type.contains('disposal') ||
        type.contains('disposer')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'disposal-deodorize',
          taskName: 'Disposal Deodorizing',
          scheduledDate: DateTime(now.year, now.month + 1, 5),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 22)),
          updatedAt: now.subtract(const Duration(days: 22)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'disposal-blade-clean',
          taskName: 'Grinding Chamber Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 12),
          completedDate: DateTime(now.year, now.month - 1, 12),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'disposal-splash-guard',
          taskName: 'Splash Guard Cleaning',
          scheduledDate: DateTime(now.year, now.month, 18),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month + 1, 3),
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'disposal-drain-check',
          taskName: 'Drain Pipe Inspection',
          scheduledDate: DateTime(now.year, now.month - 2, 22),
          completedDate: DateTime(now.year, now.month - 2, 23),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 78)),
          updatedAt: now.subtract(const Duration(days: 58)),
        ),
      ]);
    }
    // ── Water Softener ──
    else if (type.contains('water softener') ||
        type.contains('water filter') ||
        type.contains('softener')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'softener-salt-refill',
          taskName: 'Salt Tank Refill',
          scheduledDate: DateTime(now.year, now.month + 1, 8),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 26)),
          updatedAt: now.subtract(const Duration(days: 26)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'softener-resin-clean',
          taskName: 'Resin Bed Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 15),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 58)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'softener-brine-tank',
          taskName: 'Brine Tank Cleanout',
          scheduledDate: DateTime(now.year, now.month, 12),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 22),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'softener-hardness-test',
          taskName: 'Water Hardness Test',
          scheduledDate: DateTime(now.year, now.month - 2, 10),
          completedDate: DateTime(now.year, now.month - 2, 11),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 80)),
          updatedAt: now.subtract(const Duration(days: 58)),
        ),
      ]);
    }
    // ── Garage Door Opener ──
    else if (type.contains('garage door') ||
        type.contains('garage opener') ||
        type.contains('door opener')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'garage-lubricate',
          taskName: 'Spring & Track Lubrication',
          scheduledDate: DateTime(now.year, now.month + 1, 4),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 24)),
          updatedAt: now.subtract(const Duration(days: 24)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'garage-balance-test',
          taskName: 'Door Balance Test',
          scheduledDate: DateTime(now.year, now.month - 1, 12),
          completedDate: DateTime(now.year, now.month - 1, 12),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 58)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'garage-safety-reverse',
          taskName: 'Auto-Reverse Safety Test',
          scheduledDate: DateTime(now.year, now.month, 8),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 18),
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'garage-remote-battery',
          taskName: 'Remote Battery Replacement',
          scheduledDate: DateTime(now.year, now.month - 2, 20),
          completedDate: DateTime(now.year, now.month - 2, 21),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 78)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
      ]);
    }
    // ── Sump Pump ──
    else if (type.contains('sump pump')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'sump-float-test',
          taskName: 'Float Switch Test',
          scheduledDate: DateTime(now.year, now.month + 1, 3),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 22)),
          updatedAt: now.subtract(const Duration(days: 22)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'sump-pit-clean',
          taskName: 'Sump Pit Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 18),
          completedDate: DateTime(now.year, now.month - 1, 18),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 60)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'sump-discharge-check',
          taskName: 'Discharge Pipe Inspection',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'sump-backup-battery',
          taskName: 'Backup Battery Check',
          scheduledDate: DateTime(now.year, now.month - 2, 8),
          completedDate: DateTime(now.year, now.month - 2, 9),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 75)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
      ]);
    }
    // ── Gaming Console ──
    else if (type.contains('gaming console') ||
        type.contains('playstation') ||
        type.contains('xbox') ||
        type.contains('nintendo') ||
        type.contains('game console')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'console-vent-dust',
          taskName: 'Vent & Fan Dust Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 5),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'console-system-update',
          taskName: 'System Software Update',
          scheduledDate: DateTime(now.year, now.month - 1, 14),
          completedDate: DateTime(now.year, now.month - 1, 14),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 52)),
          updatedAt: now.subtract(const Duration(days: 38)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'console-storage-clean',
          taskName: 'Storage Space Cleanup',
          scheduledDate: DateTime(now.year, now.month, 15),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 25),
          createdAt: now.subtract(const Duration(days: 38)),
          updatedAt: now.subtract(const Duration(days: 12)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'console-controller-clean',
          taskName: 'Controller Cleaning & Check',
          scheduledDate: DateTime(now.year, now.month - 2, 12),
          completedDate: DateTime(now.year, now.month - 2, 13),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 78)),
          updatedAt: now.subtract(const Duration(days: 52)),
        ),
      ]);
    }
    // ── Printer ──
    else if (type.contains('printer')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'printer-head-clean',
          taskName: 'Printhead Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 7),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'printer-ink-check',
          taskName: 'Ink / Toner Level Check',
          scheduledDate: DateTime(now.year, now.month - 1, 10),
          completedDate: DateTime(now.year, now.month - 1, 10),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'printer-roller-clean',
          taskName: 'Paper Feed Roller Cleaning',
          scheduledDate: DateTime(now.year, now.month, 12),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 22),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'printer-firmware-update',
          taskName: 'Firmware Update Check',
          scheduledDate: DateTime(now.year, now.month - 2, 18),
          completedDate: DateTime(now.year, now.month - 2, 19),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 70)),
          updatedAt: now.subtract(const Duration(days: 52)),
        ),
      ]);
    }
    // ── Router / Network Gateway ──
    else if (type.contains('router') ||
        type.contains('gateway') ||
        type.contains('network device') ||
        type.contains('modem')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'router-firmware-update',
          taskName: 'Firmware Update',
          scheduledDate: DateTime(now.year, now.month + 1, 5),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'router-reboot',
          taskName: 'Scheduled Reboot',
          scheduledDate: DateTime(now.year, now.month - 1, 1),
          completedDate: DateTime(now.year, now.month - 1, 1),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'router-password-review',
          taskName: 'Password & Security Review',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'router-dust-clean',
          taskName: 'Vent & Casing Dust Cleaning',
          scheduledDate: DateTime(now.year, now.month - 2, 15),
          completedDate: DateTime(now.year, now.month - 2, 16),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 72)),
          updatedAt: now.subtract(const Duration(days: 50)),
        ),
      ]);
    }
    // ── Phone / Smartphone ──
    else if (type.contains('phone') ||
        type.contains('iphone') ||
        type.contains('smartphone') ||
        type.contains('android')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'phone-software-update',
          taskName: 'Software Update Check',
          scheduledDate: DateTime(now.year, now.month + 1, 8),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 28)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'phone-storage-cleanup',
          taskName: 'Storage Cleanup',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 15),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 58)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'phone-battery-check',
          taskName: 'Battery Health Check',
          scheduledDate: DateTime(now.year, now.month, 12),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 22),
          createdAt: now.subtract(const Duration(days: 38)),
          updatedAt: now.subtract(const Duration(days: 12)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'phone-screen-clean',
          taskName: 'Screen & Port Cleaning',
          scheduledDate: DateTime(now.year, now.month - 2, 20),
          completedDate: DateTime(now.year, now.month - 2, 21),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 78)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
      ]);
    }
    // ── Tablet ──
    else if (type.contains('tablet') || type.contains('ipad')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'tablet-software-update',
          taskName: 'Software Update Check',
          scheduledDate: DateTime(now.year, now.month + 1, 6),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 25)),
          updatedAt: now.subtract(const Duration(days: 25)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'tablet-battery-check',
          taskName: 'Battery Health Check',
          scheduledDate: DateTime(now.year, now.month - 1, 12),
          completedDate: DateTime(now.year, now.month - 1, 12),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'tablet-screen-clean',
          taskName: 'Screen & Case Cleaning',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'tablet-app-cleanup',
          taskName: 'App & Storage Cleanup',
          scheduledDate: DateTime(now.year, now.month - 2, 18),
          completedDate: DateTime(now.year, now.month - 2, 19),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 72)),
          updatedAt: now.subtract(const Duration(days: 52)),
        ),
      ]);
    }
    // ── Smart Thermostat ──
    else if (type.contains('thermostat')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'thermostat-battery',
          taskName: 'Battery Replacement',
          scheduledDate: DateTime(now.year, now.month + 1, 5),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 22)),
          updatedAt: now.subtract(const Duration(days: 22)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'thermostat-calibration',
          taskName: 'Temperature Calibration Check',
          scheduledDate: DateTime(now.year, now.month - 1, 10),
          completedDate: DateTime(now.year, now.month - 1, 10),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'thermostat-firmware',
          taskName: 'Firmware Update Check',
          scheduledDate: DateTime(now.year, now.month, 14),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 24),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 8)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'thermostat-schedule-review',
          taskName: 'Schedule & Settings Review',
          scheduledDate: DateTime(now.year, now.month - 2, 20),
          completedDate: DateTime(now.year, now.month - 2, 21),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 75)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
      ]);
    }
    // ── Furniture ──
    else if (type.contains('furniture') ||
        type.contains('sofa') ||
        type.contains('chair')) {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'furniture-fabric-clean',
          taskName: 'Upholstery Cleaning',
          scheduledDate: DateTime(now.year, now.month + 1, 12),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 32)),
          updatedAt: now.subtract(const Duration(days: 32)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'furniture-cushion-flip',
          taskName: 'Cushion Rotation',
          scheduledDate: DateTime(now.year, now.month - 1, 8),
          completedDate: DateTime(now.year, now.month - 1, 8),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 40)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'furniture-leg-check',
          taskName: 'Leg & Hardware Tightening',
          scheduledDate: DateTime(now.year, now.month, 5),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 15),
          createdAt: now.subtract(const Duration(days: 28)),
          updatedAt: now.subtract(const Duration(days: 5)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'furniture-stain-treatment',
          taskName: 'Stain Treatment',
          scheduledDate: DateTime(now.year, now.month - 2, 20),
          completedDate: DateTime(now.year, now.month - 2, 21),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 75)),
          updatedAt: now.subtract(const Duration(days: 55)),
        ),
      ]);
    }
    // ── Generic / fallback ──
    else {
      records.addAll([
        MaintenanceRecord(
          id: 'mr_${assetId}_1',
          assetId: assetId,
          taskId: 'general-inspection',
          taskName: 'General Inspection',
          scheduledDate: DateTime(now.year, now.month + 1, 1),
          status: MaintenanceStatus.pending,
          createdAt: now.subtract(const Duration(days: 30)),
          updatedAt: now.subtract(const Duration(days: 30)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_2',
          assetId: assetId,
          taskId: 'general-cleaning',
          taskName: 'Routine Cleaning',
          scheduledDate: DateTime(now.year, now.month - 1, 15),
          completedDate: DateTime(now.year, now.month - 1, 15),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 55)),
          updatedAt: now.subtract(const Duration(days: 42)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_3',
          assetId: assetId,
          taskId: 'general-check',
          taskName: 'Performance Check',
          scheduledDate: DateTime(now.year, now.month, 10),
          status: MaintenanceStatus.snoozed,
          snoozedUntil: DateTime(now.year, now.month, 20),
          createdAt: now.subtract(const Duration(days: 35)),
          updatedAt: now.subtract(const Duration(days: 10)),
        ),
        MaintenanceRecord(
          id: 'mr_${assetId}_4',
          assetId: assetId,
          taskId: 'general-maintenance',
          taskName: 'Scheduled Maintenance',
          scheduledDate: DateTime(now.year, now.month - 2, 18),
          completedDate: DateTime(now.year, now.month - 2, 19),
          status: MaintenanceStatus.completed,
          createdAt: now.subtract(const Duration(days: 68)),
          updatedAt: now.subtract(const Duration(days: 48)),
        ),
      ]);
    }

    return records;
  }

  /// Task metadata keyed by taskId – descriptions, importance, effort,
  /// priority, and risk level. Used when building [Reminder]s from records.
  static Map<String, String> _getTaskMeta(String taskId) {
    const meta = <String, Map<String, String>>{
      // Refrigerator
      'fridge-gasket-cleaning': {
        'description': 'Clean door gaskets to maintain seal',
        'whyItMatters': 'Prevents air leaks and reduces energy consumption',
        'effort': '5 minutes',
        'priority': 'medium',
        'riskLevel': '3',
      },
      'fridge-coil-cleaning': {
        'description': 'Clean condenser coils behind/under the fridge',
        'whyItMatters':
            'Dirty coils cause the compressor to overwork, shortening lifespan',
        'effort': '15 minutes',
        'priority': 'medium',
        'riskLevel': '4',
      },
      'fridge-filter-change': {
        'description': 'Replace the water filter cartridge',
        'whyItMatters': 'Ensures clean drinking water and ice',
        'effort': '5 minutes',
        'priority': 'medium',
        'riskLevel': '2',
      },
      'fridge-ice-maker': {
        'description': 'Clean ice maker bin and water lines',
        'whyItMatters': 'Prevents mineral buildup and keeps ice fresh',
        'effort': '10 minutes',
        'priority': 'low',
        'riskLevel': '2',
      },
      'fridge-defrost': {
        'description': 'Manually defrost freezer if ice builds up',
        'whyItMatters': 'Excess frost reduces cooling efficiency',
        'effort': '30 minutes',
        'priority': 'low',
        'riskLevel': '2',
      },
      // AC
      'ac-filter-replacement': {
        'description': 'Replace or clean the AC air filter',
        'whyItMatters': 'Improves air quality and AC cooling efficiency',
        'effort': '10 minutes',
        'priority': 'high',
        'riskLevel': '7',
        'safetyNote': 'Turn off AC before replacing filter',
      },
      'ac-coil-cleaning': {
        'description': 'Clean AC evaporator and condenser coils',
        'whyItMatters': 'Improves cooling efficiency and reduces energy bills',
        'effort': '20 minutes',
        'priority': 'medium',
        'riskLevel': '3',
      },
      // Microwave
      'microwave-interior-clean': {
        'description': 'Deep clean microwave interior and turntable',
        'whyItMatters':
            'Prevents buildup, maintains hygiene, and ensures even heating',
        'effort': '15 minutes',
        'priority': 'low',
        'riskLevel': '2',
        'safetyNote': 'Unplug before cleaning',
      },
      'microwave-turntable-clean': {
        'description': 'Remove and wash turntable and roller ring',
        'whyItMatters': 'Ensures even cooking and prevents odor',
        'effort': '5 minutes',
        'priority': 'low',
        'riskLevel': '1',
      },
      'microwave-vent-filter': {
        'description': 'Inspect and clean the vent filter',
        'whyItMatters': 'Blocked vents can cause overheating',
        'effort': '10 minutes',
        'priority': 'medium',
        'riskLevel': '3',
      },
      'microwave-door-seal': {
        'description': 'Check door seal for damage or wear',
        'whyItMatters': 'A damaged seal can leak microwave radiation',
        'effort': '5 minutes',
        'priority': 'medium',
        'riskLevel': '4',
        'safetyNote': 'Do not use if seal is damaged',
      },
      // Television
      'tv-screen-clean': {
        'description': 'Clean screen with microfiber cloth and screen cleaner',
        'whyItMatters': 'Removes dust and smudges for better picture quality',
        'effort': '5 minutes',
        'priority': 'low',
        'riskLevel': '1',
      },
      'tv-vent-dust': {
        'description': 'Dust ventilation openings on the TV',
        'whyItMatters': 'Prevents overheating and extends TV life',
        'effort': '5 minutes',
        'priority': 'low',
        'riskLevel': '2',
      },
      'tv-firmware-update': {
        'description': 'Check for and install firmware updates',
        'whyItMatters': 'Fixes bugs and adds new features',
        'effort': '10 minutes',
        'priority': 'low',
        'riskLevel': '1',
      },
      'tv-cable-check': {
        'description': 'Inspect all cable connections',
        'whyItMatters': 'Loose cables cause signal issues',
        'effort': '5 minutes',
        'priority': 'low',
        'riskLevel': '1',
      },
      // Generic
      'general-inspection': {
        'description': 'General inspection of the asset',
        'whyItMatters': 'Catches issues early before they become costly',
        'effort': '15 minutes',
        'priority': 'medium',
        'riskLevel': '3',
      },
      'general-cleaning': {
        'description': 'Routine cleaning and dusting',
        'whyItMatters': 'Keeps the asset in good condition',
        'effort': '10 minutes',
        'priority': 'low',
        'riskLevel': '1',
      },
      'general-check': {
        'description': 'Check performance and operation',
        'whyItMatters': 'Ensures the asset is working correctly',
        'effort': '10 minutes',
        'priority': 'low',
        'riskLevel': '2',
      },
      'general-maintenance': {
        'description': 'Scheduled general maintenance',
        'whyItMatters': 'Regular maintenance prevents breakdowns',
        'effort': '15 minutes',
        'priority': 'medium',
        'riskLevel': '3',
      },
    };

    return meta[taskId] ??
        {
          'description': 'Maintenance task',
          'whyItMatters': 'Keeps your asset in good condition',
          'effort': '15 minutes',
          'priority': 'medium',
          'riskLevel': '3',
        };
  }

  static ReminderPriority _parsePriority(String p) {
    switch (p) {
      case 'high':
        return ReminderPriority.high;
      case 'low':
        return ReminderPriority.low;
      default:
        return ReminderPriority.medium;
    }
  }

  /// Creates a [Reminder] from a [MaintenanceRecord] using the task metadata
  /// lookup and the given asset info.
  static Reminder _createReminderFromRecord(
    MaintenanceRecord record,
    String assetName,
    String? assetLocation,
  ) {
    final meta = _getTaskMeta(record.taskId);

    ReminderStatus status;
    switch (record.status) {
      case MaintenanceStatus.completed:
        status = ReminderStatus.completed;
        break;
      case MaintenanceStatus.snoozed:
        status = ReminderStatus.snoozed;
        break;
      case MaintenanceStatus.skipped:
        status = ReminderStatus.skipped;
        break;
      case MaintenanceStatus.pending:
        status = record.scheduledDate.isBefore(DateTime.now())
            ? ReminderStatus.overdue
            : ReminderStatus.upcoming;
    }

    return Reminder(
      id: 'r_${record.id}',
      assetId: record.assetId,
      assetName: assetName,
      assetLocation: assetLocation,
      taskId: record.taskId,
      taskName: record.taskName,
      taskDescription: meta['description']!,
      whyItMatters: meta['whyItMatters']!,
      estimatedEffort: meta['effort']!,
      safetyNote: meta['safetyNote'],
      dueDate: record.scheduledDate,
      status: status,
      priority: _parsePriority(meta['priority']!),
      riskLevel: int.tryParse(meta['riskLevel']!) ?? 3,
      snoozedUntil: record.snoozedUntil,
      completedDate: record.completedDate,
      skipReason: record.skipReason,
    );
  }
}