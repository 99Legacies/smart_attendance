import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';

class AttendanceSessionModel extends AttendanceSession {
  const AttendanceSessionModel({
    required super.id,
    required super.courseId,
    required super.lecturerId,
    required super.startTime,
    required super.endTime,
    required super.qrToken,
    required super.qrExpiresAt,
    required super.latitude,
    required super.longitude,
    required super.locationRadiusMeters,
    required super.isActive,
  });

  factory AttendanceSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AttendanceSessionModel(
      id: doc.id,
      courseId: data['courseId'] as String? ?? '',
      lecturerId: data['lecturerId'] as String? ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      qrToken: data['qrToken'] as String? ?? '',
      qrExpiresAt: (data['qrExpiresAt'] as Timestamp).toDate(),
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0,
      locationRadiusMeters:
          (data['locationRadiusMeters'] as num?)?.toDouble() ?? 100,
      isActive: data['isActive'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'courseId': courseId,
        'lecturerId': lecturerId,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'qrToken': qrToken,
        'qrExpiresAt': Timestamp.fromDate(qrExpiresAt),
        'latitude': latitude,
        'longitude': longitude,
        'locationRadiusMeters': locationRadiusMeters,
        'isActive': isActive,
      };
}
