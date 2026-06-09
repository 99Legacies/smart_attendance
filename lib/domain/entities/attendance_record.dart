import 'package:equatable/equatable.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';

class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.timestamp,
    required this.deviceId,
    required this.status,
    this.courseId,
  });

  final String id;
  final String studentId;
  final String sessionId;
  final DateTime timestamp;
  final String deviceId;
  final AttendanceStatus status;
  final String? courseId;

  @override
  List<Object?> get props =>
      [id, studentId, sessionId, timestamp, deviceId, status, courseId];
}
