import 'package:smart_attendance/domain/entities/app_notification.dart';

abstract class NotificationRepository {
  Future<void> send({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
    Map<String, String>? metadata,
  });

  Stream<List<AppNotification>> watchForUser(String userId);

  Stream<int> watchUnreadCount(String userId);

  Future<void> markAsRead(String notificationId);

  Future<void> markAllAsRead(String userId);
}
