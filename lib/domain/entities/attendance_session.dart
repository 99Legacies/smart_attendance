import 'package:equatable/equatable.dart';

class AttendanceSession extends Equatable {
  const AttendanceSession({
    required this.id,
    required this.courseId,
    required this.lecturerId,
    required this.startTime,
    required this.endTime,
    required this.qrToken,
    required this.qrExpiresAt,
    required this.latitude,
    required this.longitude,
    required this.locationRadiusMeters,
    required this.isActive,
  });

  final String id;
  final String courseId;
  final String lecturerId;
  final DateTime startTime;
  final DateTime endTime;
  final String qrToken;
  final DateTime qrExpiresAt;
  final double latitude;
  final double longitude;
  final double locationRadiusMeters;
  final bool isActive;

  bool get isExpired => DateTime.now().isAfter(endTime);
  bool get isQrExpired => DateTime.now().isAfter(qrExpiresAt);

  @override
  List<Object?> get props => [
        id,
        courseId,
        lecturerId,
        startTime,
        endTime,
        qrToken,
        qrExpiresAt,
        latitude,
        longitude,
        locationRadiusMeters,
        isActive,
      ];
}
