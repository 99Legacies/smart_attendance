import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/data/models/notification_model.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  FirebaseNotificationRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _notifications =>
      _firestore.collection(AppConstants.notificationsCollection);

  @override
  Future<void> send({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
    Map<String, String>? metadata,
  }) async {
    await _notifications.add(
      NotificationModel(
        id: '',
        recipientId: recipientId,
        type: type,
        title: title,
        body: body,
        createdAt: DateTime.now(),
        read: false,
        relatedId: relatedId,
        metadata: metadata,
      ).toFirestore(),
    );
  }

  @override
  Stream<List<AppNotification>> watchForUser(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => NotificationModel.fromFirestore(d))
              .toList(),
        );
  }

  @override
  Stream<int> watchUnreadCount(String userId) {
    return _notifications
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _notifications.doc(notificationId).update({'read': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final snap = await _notifications
        .where('recipientId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
