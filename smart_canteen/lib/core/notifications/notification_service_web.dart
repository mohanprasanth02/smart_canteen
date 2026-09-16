import 'package:flutter/foundation.dart';

// Stub: on web, all notification calls are no-ops at compile time.
class LocalNotificationService {
  static Future<void> initialize() async {
    // No-op on web
    debugPrint('[LocalNotificationService] Web: notifications skipped');
  }

  static Future<void> requestPermissions() async {
    // No-op on web
  }

  static Future<void> showNotification({
    required String title,
    required String body,
    int id = 0,
    String? payload,
  }) async {
    // No-op on web – in-app UI handles notification display
    debugPrint('[Notification stub] $title: $body');
  }
}
