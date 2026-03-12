import '../services/notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  @override
  Future<void> initialize() async {
    // Web doesn't support local notifications
    // Notifications would be handled via browser notifications API if needed
  }

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Web implementation - could use browser Notification API
    // For now, we'll skip as it requires user permission
  }

  @override
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    // Web doesn't support scheduled notifications
  }
}

NotificationService getNotificationService() => NotificationServiceImpl();
