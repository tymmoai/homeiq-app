import 'package:flutter/foundation.dart';

/// Push notifications stub — Firebase removed.
/// Re-implement with new credentials when ready.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  static NotificationService get instance => _instance;

  /// No-op initialize — push notifications disabled until new credentials are set up.
  Future<void> initialize() async {
    if (kDebugMode) {
      debugPrint('ℹ️ Push notifications disabled (Firebase removed). Re-add credentials to enable.');
    }
  }

  /// No-op getToken — returns null until Firebase is configured
  Future<String?> getToken() async {
    if (kDebugMode) {
      debugPrint('ℹ️ getToken not available (Firebase removed)');
    }
    return null;
  }

  Future<void> subscribeToTopic(String topic) async {}

  Future<void> unsubscribeFromTopic(String topic) async {}
}

/// Background message handler (called when app is terminated)
/// This MUST be a top-level function for Firebase to call it
/// Uncomment and use in main.dart: FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundMessageHandler);
// @pragma('vm:entry-point')
// Future<void> _firebaseBackgroundMessageHandler(RemoteMessage message) async {
//   debugPrint('🔕 Handling background message');
//   debugPrint('Title: ${message.notification?.title}');
//   debugPrint('Body: ${message.notification?.body}');
//   // TODO: Handle background notification (e.g., sync data, update badge)
// }
