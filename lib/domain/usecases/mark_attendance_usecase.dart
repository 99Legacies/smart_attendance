import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/core/utils/location_utils.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';

/// Business logic for marking attendance with anti-cheating checks.
class MarkAttendanceUseCase {
  MarkAttendanceUseCase({
    required AttendanceRepository attendanceRepository,
    required CatalogRepository catalogRepository,
  })  : _attendance = attendanceRepository,
        _catalog = catalogRepository;

  final AttendanceRepository _attendance;
  final CatalogRepository _catalog;

  Future<AttendanceRecord> execute({
    required String studentUid,
    required QrPayload qrPayload,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    final student = await _catalog.getStudent(studentUid);
    if (student == null) {
      throw const AppException(
        'Student profile not found. Contact administration.',
        code: 'student_not_found',
      );
    }

    await _validateDevice(student, deviceId);

    final session = await _attendance.getSession(qrPayload.sessionId);
    if (session == null) {
      throw const AppException(
        'Invalid QR code: session does not exist.',
        code: 'session_not_found',
      );
    }

    if (!session.isActive) {
      await _log(studentUid, 'inactive_session_scan', session.id);
      throw const AppException(
        'This attendance session is not active.',
        code: 'session_inactive',
      );
    }

    if (session.isExpired) {
      await _log(studentUid, 'expired_session_scan', session.id);
      throw const AppException(
        'This attendance session has ended. Attendance is locked.',
        code: 'session_ended',
      );
    }

    if (session.isQrExpired || session.qrToken != qrPayload.token) {
      await _log(studentUid, 'invalid_or_expired_qr', session.id);
      throw const AppException(
        'QR code has expired. Ask your lecturer to display a new code.',
        code: 'qr_expired',
      );
    }

    final course = await _catalog.getCourse(session.courseId);
    if (course == null || course.id != session.courseId) {
      await _log(studentUid, 'invalid_session_course', session.id);
      throw const AppException(
        'This attendance session is invalid. Contact administration.',
        code: 'session_invalid',
      );
    }

    if (!student.courseIds.contains(session.courseId)) {
      await _log(studentUid, 'unregistered_course_scan', session.id);
      throw const AppException(
        'You are not registered for this course.',
        code: 'not_enrolled',
      );
    }

    if (!course.allowsDepartment(student.departmentId)) {
      await _log(studentUid, 'department_not_allowed', session.id);
      throw const AppException(
        'Your department is not allowed to mark attendance for this course.',
        code: 'department_not_allowed',
      );
    }

    final alreadyMarked = await _attendance.hasMarkedAttendance(
      studentUid: studentUid,
      sessionId: session.id,
    );
    if (alreadyMarked) {
      throw const AppException(
        'You have already marked attendance for this session.',
        code: 'duplicate_attendance',
      );
    }

    final distance = LocationUtils.distanceInMeters(
      latitude,
      longitude,
      session.latitude,
      session.longitude,
    );
    if (distance > session.locationRadiusMeters) {
      await _log(
        studentUid,
        'location_mismatch',
        session.id,
        'Distance: ${distance.toStringAsFixed(0)}m, allowed: ${session.locationRadiusMeters}m',
      );
      throw AppException(
        'You are too far from the class location (${distance.toStringAsFixed(0)}m away). '
        'Move within ${session.locationRadiusMeters.toInt()}m to mark attendance.',
        code: 'location_out_of_range',
      );
    }

    return _attendance.markAttendance(
      studentUid: studentUid,
      sessionId: session.id,
      qrToken: qrPayload.token,
      latitude: latitude,
      longitude: longitude,
      deviceId: deviceId,
    );
  }

  Future<void> _validateDevice(Student student, String deviceId) async {
    final storedDevice = student.deviceId;
    if (storedDevice != null && storedDevice != deviceId) {
      // Skip device mismatch for web devices — web IDs change per browser/session
      // and are not reliable for device enforcement
      final isWebDevice = storedDevice.startsWith('web-') ||
          deviceId.startsWith('web-') ||
          storedDevice == 'unknown-device' ||
          deviceId == 'unknown-device';

      if (isWebDevice) return; // Allow web logins without mismatch error

      await _log(
        student.id,
        'device_mismatch',
        null,
        'Registered: $storedDevice, Attempt: $deviceId',
      );
      throw const AppException(
        'This account is registered on another device. '
        'Contact admin to reset your device.',
        code: 'device_mismatch',
      );
    }
  }

  Future<void> _log(
    String userId,
    String action,
    String? sessionId, [
    String? extra,
  ]) async {
    await _attendance.logSuspiciousActivity(
      userId: userId,
      action: action,
      details: extra ?? action,
      sessionId: sessionId,
    );
  }
}
