import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';

/// Stub attendance repository that returns a controlled stream.
class FakeAttendanceRepository implements AttendanceRepository {
  FakeAttendanceRepository({required this.recordsStream});

  final Stream<List<AttendanceRecord>> recordsStream;

  @override
  Stream<List<AttendanceRecord>> watchRecordsForStudent(String studentUid) =>
      recordsStream;

  @override
  Future<bool> hasMarkedAttendance({
    required String studentUid,
    required String sessionId,
  }) async => false;

  @override
  Future<List<AttendanceRecord>> getRecordsForStudent(
    String studentUid,
  ) async => [];

  @override
  Future<AttendanceRecord> markAttendance({
    required String studentUid,
    required String sessionId,
    required String qrToken,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) => throw UnimplementedError();

  @override
  Future<AttendanceSession> createSession({
    required String courseId,
    required String lecturerId,
    required DateTime startTime,
    required DateTime endTime,
    required double latitude,
    required double longitude,
    required double locationRadiusMeters,
  }) => throw UnimplementedError();

  @override
  Future<void> refreshQrToken(String sessionId) async {}

  @override
  Future<AttendanceSession?> getSession(String sessionId) async => null;

  @override
  Stream<AttendanceSession?> watchSession(String sessionId) =>
      Stream.value(null);

  @override
  Future<void> endSession(String sessionId, {String? courseName}) async {}

  @override
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId) =>
      Stream.value([]);

  @override
  Future<void> logSuspiciousActivity({
    required String userId,
    required String action,
    required String details,
    String? sessionId,
  }) async {}

  @override
  Future<Map<String, int>> getSessionStats(String sessionId) async =>
      {'present': 0, 'late': 0, 'absent': 0, 'total': 0};
}

/// Stub notification repository that returns a controlled stream.
class FakeNotificationRepository implements NotificationRepository {
  FakeNotificationRepository({required this.notificationsStream});

  final Stream<List<AppNotification>> notificationsStream;

  @override
  Stream<List<AppNotification>> watchForUser(String userId) =>
      notificationsStream;

  @override
  Stream<int> watchUnreadCount(String userId) => Stream.value(0);

  @override
  Future<void> markAsRead(String notificationId) async {}

  @override
  Future<void> markAllAsRead(String userId) async {}

  @override
  Future<void> send({
    required String recipientId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
    Map<String, String>? metadata,
  }) async {}
}
