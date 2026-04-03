import 'notification_service.dart';

class NotificationServiceImpl implements NotificationService {
  @override
  Future<void> initialize() async {}

  @override
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {}

  @override
  Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {}
}

NotificationService getNotificationService() => NotificationServiceImpl();