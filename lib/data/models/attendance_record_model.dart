import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';

class AttendanceRecordModel extends AttendanceRecord {
  const AttendanceRecordModel({
    required super.id,
    required super.studentId,
    required super.sessionId,
    required super.timestamp,
    required super.deviceId,
    required super.status,
    super.courseId,
  });

  factory AttendanceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AttendanceRecordModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      sessionId: data['sessionId'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      deviceId: data['deviceId'] as String? ?? '',
      status: AttendanceStatus.fromString(data['status'] as String? ?? ''),
      courseId: data['courseId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'sessionId': sessionId,
        'timestamp': Timestamp.fromDate(timestamp),
        'deviceId': deviceId,
        'status': status.name,
        if (courseId != null) 'courseId': courseId,
      };
}
