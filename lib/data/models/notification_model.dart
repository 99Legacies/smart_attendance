import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';

class NotificationModel extends AppNotification {
  const NotificationModel({
    required super.id,
    required super.recipientId,
    required super.type,
    required super.title,
    required super.body,
    required super.createdAt,
    required super.read,
    super.relatedId,
    super.metadata,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final meta = data['metadata'];
    return NotificationModel(
      id: doc.id,
      recipientId: data['recipientId'] as String? ?? '',
      type: NotificationType.values.firstWhere(
        (t) => t.name == (data['type'] as String? ?? ''),
        orElse: () => NotificationType.absenceSubmitted,
      ),
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      read: data['read'] as bool? ?? false,
      relatedId: data['relatedId'] as String?,
      metadata: meta is Map
          ? meta.map((k, v) => MapEntry(k.toString(), v.toString()))
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'recipientId': recipientId,
        'type': type.name,
        'title': title,
        'body': body,
        'createdAt': Timestamp.fromDate(createdAt),
        'read': read,
        if (relatedId != null) 'relatedId': relatedId,
        if (metadata != null) 'metadata': metadata,
      };
}
