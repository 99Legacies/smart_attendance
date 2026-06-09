import 'package:equatable/equatable.dart';

enum NotificationType {
  absenceSubmitted,
  absenceReviewed,
  missedClass,
  courseProposalApproved,
  courseProposalRejected,
}

class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.relatedId,
    this.metadata,
  });

  final String id;
  final String recipientId;
  final NotificationType type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? relatedId;
  final Map<String, String>? metadata;

  @override
  List<Object?> get props =>
      [id, recipientId, type, title, body, createdAt, read, relatedId];
}
