import 'dart:developer' as developer;

import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';

/// Local data source for attendance sessions using Hive
class LocalAttendanceSessionDataSource {
  /// Get session by ID
  Future<AttendanceSession?> getSessionById(String sessionId) async {
    try {
      final hiveSession = LocalDatabaseService.sessionsBox.get(sessionId);
      if (hiveSession != null) {
        developer.log(
          'Found session in local DB: $sessionId',
          name: 'LocalData',
        );
        return _hiveToSession(hiveSession);
      }
      return null;
    } catch (error, stack) {
      developer.log(
        'Failed to get session from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get active sessions
  Future<List<AttendanceSession>> getActiveSessions() async {
    try {
      return LocalDatabaseService.sessionsBox.values
          .where((s) => s.isActive)
          .map(_hiveToSession)
          .toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get active sessions from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save session
  Future<void> saveSession(AttendanceSession session) async {
    try {
      final hiveSession = _sessionToHive(session);
      await LocalDatabaseService.sessionsBox.put(session.id, hiveSession);
      developer.log(
        'Saved session to local DB: ${session.id}',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save session to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Clear old sessions
  Future<void> clearOldSessions(Duration olderThan) async {
    try {
      final cutoff = DateTime.now().subtract(olderThan);
      final keysToDelete = <String>[];

      for (var i = 0; i < LocalDatabaseService.sessionsBox.length; i++) {
        final session = LocalDatabaseService.sessionsBox.getAt(i);
        if (session != null && session.endTime.isBefore(cutoff)) {
          keysToDelete.add(session.id);
        }
      }

      for (final key in keysToDelete) {
        await LocalDatabaseService.sessionsBox.delete(key);
      }

      developer.log(
        'Cleared ${keysToDelete.length} old sessions from local DB',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to clear old sessions: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  static AttendanceSession _hiveToSession(HiveAttendanceSession hive) {
    return AttendanceSession(
      id: hive.id,
      courseId: hive.courseId,
      lecturerId: hive.lecturerId,
      startTime: hive.startTime,
      endTime: hive.endTime,
      qrToken: hive.qrToken,
      qrExpiresAt: hive.qrExpiresAt,
      latitude: hive.latitude,
      longitude: hive.longitude,
      locationRadiusMeters: hive.locationRadiusMeters,
      isActive: hive.isActive,
    );
  }

  static HiveAttendanceSession _sessionToHive(AttendanceSession session) {
    return HiveAttendanceSession(
      id: session.id,
      courseId: session.courseId,
      lecturerId: session.lecturerId,
      startTime: session.startTime,
      endTime: session.endTime,
      qrToken: session.qrToken,
      qrExpiresAt: session.qrExpiresAt,
      latitude: session.latitude,
      longitude: session.longitude,
      locationRadiusMeters: session.locationRadiusMeters,
      isActive: session.isActive,
      syncedAt: DateTime.now(),
    );
  }
}

/// Local data source for attendance records using Hive
class LocalAttendanceRecordDataSource {
  /// Get record by ID
  Future<AttendanceRecord?> getRecordById(String recordId) async {
    try {
      final hiveRecord = LocalDatabaseService.recordsBox.get(recordId);
      if (hiveRecord != null) {
        return _hiveToRecord(hiveRecord);
      }
      return null;
    } catch (error, stack) {
      developer.log(
        'Failed to get record from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get records for student
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentId) async {
    try {
      return LocalDatabaseService.recordsBox.values
          .where((r) => r.studentId == studentId)
          .map(_hiveToRecord)
          .toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get student records from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get records for session
  Future<List<AttendanceRecord>> getRecordsForSession(String sessionId) async {
    try {
      return LocalDatabaseService.recordsBox.values
          .where((r) => r.sessionId == sessionId)
          .map(_hiveToRecord)
          .toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get session records from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save record
  Future<void> saveRecord(AttendanceRecord record) async {
    try {
      final hiveRecord = _recordToHive(record);
      await LocalDatabaseService.recordsBox.put(record.id, hiveRecord);
      developer.log(
        'Saved attendance record to local DB: ${record.id}',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save attendance record to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Save multiple records
  Future<void> saveRecords(List<AttendanceRecord> records) async {
    try {
      final map = {
        for (final record in records) record.id: _recordToHive(record),
      };
      await LocalDatabaseService.recordsBox.putAll(map);
      developer.log(
        'Saved ${records.length} attendance records to local DB',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save attendance records to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  static AttendanceRecord _hiveToRecord(HiveAttendanceRecord hive) {
    return AttendanceRecord(
      id: hive.id,
      studentId: hive.studentId,
      sessionId: hive.sessionId,
      timestamp: hive.timestamp,
      deviceId: hive.deviceId,
      status: hive.status,
      courseId: hive.courseId,
    );
  }

  static HiveAttendanceRecord _recordToHive(AttendanceRecord record) {
    return HiveAttendanceRecord(
      id: record.id,
      studentId: record.studentId,
      sessionId: record.sessionId,
      timestamp: record.timestamp,
      deviceId: record.deviceId,
      status: record.status,
      courseId: record.courseId,
      syncedAt: DateTime.now(),
    );
  }
}
