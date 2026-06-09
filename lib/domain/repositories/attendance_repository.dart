import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';
abstract class AttendanceRepository {
  Future<AttendanceSession> createSession({
    required String courseId,
    required String lecturerId,
    required DateTime startTime,
    required DateTime endTime,
    required double latitude,
    required double longitude,
    required double locationRadiusMeters,
  });

  Future<void> refreshQrToken(String sessionId);

  Future<AttendanceSession?> getSession(String sessionId);

  Stream<AttendanceSession?> watchSession(String sessionId);

  Future<void> endSession(String sessionId, {String? courseName});

  Future<AttendanceRecord> markAttendance({
    required String studentUid,
    required String sessionId,
    required String qrToken,
    required double latitude,
    required double longitude,
    required String deviceId,
  });

  Future<bool> hasMarkedAttendance({
    required String studentUid,
    required String sessionId,
  });

  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId);

  Stream<List<AttendanceRecord>> watchRecordsForStudent(String studentUid);

  Future<List<AttendanceRecord>> getRecordsForStudent(String studentUid);

  Future<void> logSuspiciousActivity({
    required String userId,
    required String action,
    required String details,
    String? sessionId,
  });

  Future<Map<String, int>> getSessionStats(String sessionId);
}

/// Result of parsing a scanned QR payload.
class QrPayload {
  const QrPayload({
    required this.sessionId,
    required this.token,
  });

  final String sessionId;
  final String token;

  static QrPayload? tryParse(String raw) {
    try {
      final parts = raw.split('|');
      if (parts.length != 2) return null;
      return QrPayload(sessionId: parts[0], token: parts[1]);
    } catch (_) {
      return null;
    }
  }

  String encode() => '$sessionId|$token';
}
