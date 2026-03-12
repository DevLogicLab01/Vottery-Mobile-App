import 'notification_service_web.dart'
    if (dart.library.io) 'notification_service_io.dart';

abstract class NotificationService {
  Future<void> initialize();

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  });

  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  });
}

NotificationService createNotificationService() => getNotificationService();
