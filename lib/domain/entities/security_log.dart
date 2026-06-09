import 'package:equatable/equatable.dart';

class SecurityLog extends Equatable {
  const SecurityLog({
    required this.id,
    required this.userId,
    required this.action,
    required this.details,
    required this.timestamp,
    this.sessionId,
  });

  final String id;
  final String userId;
  final String action;
  final String details;
  final DateTime timestamp;
  final String? sessionId;

  @override
  List<Object?> get props => [
    id,
    userId,
    action,
    details,
    timestamp,
    sessionId,
  ];
}
