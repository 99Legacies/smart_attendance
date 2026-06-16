import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/data/models/attendance_record_model.dart';
import 'package:smart_attendance/data/models/attendance_session_model.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_session.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';
import 'package:uuid/uuid.dart';

class FirebaseAttendanceRepository implements AttendanceRepository {
  FirebaseAttendanceRepository({
    FirebaseFirestore? firestore,
    this._notifications,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final NotificationRepository? _notifications;
  final _uuid = const Uuid();

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection(AppConstants.sessionsCollection);

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection(AppConstants.recordsCollection);

  @override
  Future<AttendanceSession> createSession({
    required String courseId,
    required String lecturerId,
    required DateTime startTime,
    required DateTime endTime,
    required double latitude,
    required double longitude,
    required double locationRadiusMeters,
  }) async {
    final token = _uuid.v4();
    final now = DateTime.now();
    final session = AttendanceSessionModel(
      id: '',
      courseId: courseId,
      lecturerId: lecturerId,
      startTime: startTime,
      endTime: endTime,
      qrToken: token,
      qrExpiresAt: now.add(
        const Duration(seconds: AppConstants.qrValiditySeconds),
      ),
      latitude: latitude,
      longitude: longitude,
      locationRadiusMeters: locationRadiusMeters,
      isActive: true,
    );

    final ref = await _sessions.add(session.toFirestore());
    final doc = await ref.get();
    return AttendanceSessionModel.fromFirestore(doc);
  }

  @override
  Future<void> refreshQrToken(String sessionId) async {
    final token = _uuid.v4();
    final expires = DateTime.now().add(
      const Duration(seconds: AppConstants.qrValiditySeconds),
    );
    await _sessions.doc(sessionId).update({
      'qrToken': token,
      'qrExpiresAt': Timestamp.fromDate(expires),
    });
  }

  @override
  Future<AttendanceSession?> getSession(String sessionId) async {
    final doc = await _sessions.doc(sessionId).get();
    if (!doc.exists) return null;
    return AttendanceSessionModel.fromFirestore(doc);
  }

  @override
  Stream<AttendanceSession?> watchSession(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return AttendanceSessionModel.fromFirestore(doc);
    });
  }

  @override
  Future<void> endSession(String sessionId, {String? courseName}) async {
    final sessionRef = _sessions.doc(sessionId);
    final sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) {
      throw const AppException('Session not found.', code: 'session_not_found');
    }

    final session = AttendanceSessionModel.fromFirestore(sessionSnap);

    // End the session first so UI updates immediately
    await sessionRef.update({
      'isActive': false,
      'endTime': Timestamp.fromDate(DateTime.now()),
    });

    // Process missed attendance in the background — don't await so UI isn't blocked
    _processMissedAttendance(
      session: session,
      sessionId: sessionId,
      courseName: courseName,
    ).catchError((error, stack) {
      // Log but don't rethrow — session is already ended
      developer.log(
        'processMissedAttendance error: $error',
        name: 'FirebaseAttendance',
        error: error,
        stackTrace: stack,
      );
    });
  }

  Future<void> _processMissedAttendance({
    required AttendanceSession session,
    required String sessionId,
    String? courseName,
  }) async {
    if (_notifications == null) return;

    // Query students directly from Firestore instead of going through
    // the hybrid catalog (which may return empty from local cache)
    final studentsSnap = await _firestore
        .collection(AppConstants.studentsCollection)
        .where('courseIds', arrayContains: session.courseId)
        .get();

    if (studentsSnap.docs.isEmpty) return;

    final recordsSnap = await _records
        .where('sessionId', isEqualTo: sessionId)
        .get();
    final attendedIds = recordsSnap.docs
        .map((d) => d.data()['studentId'] as String? ?? '')
        .toSet();

    final displayCourseName = courseName ?? session.courseId;
    final batch = _firestore.batch();
    var notifyCount = 0;

    for (final studentDoc in studentsSnap.docs) {
      final studentId = studentDoc.id;
      if (attendedIds.contains(studentId)) continue;

      final recordRef = _records.doc();
      final record = AttendanceRecordModel(
        id: recordRef.id,
        studentId: studentId,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        deviceId: 'system',
        status: AttendanceStatus.absent,
        courseId: session.courseId,
      );
      batch.set(recordRef, record.toFirestore());

      final notifRef = _firestore
          .collection(AppConstants.notificationsCollection)
          .doc();
      batch.set(notifRef, {
        'recipientId': studentId,
        'type': NotificationType.missedClass.name,
        'title': 'Missed class',
        'body':
            'You were marked absent for $displayCourseName. No attendance was recorded for the session on ${_formatDate(session.startTime)}.',
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
        'relatedId': sessionId,
        'metadata': {'courseId': session.courseId, 'sessionId': sessionId},
      });
      notifyCount++;
    }

    if (notifyCount > 0) {
      await batch.commit();
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Future<AttendanceRecord> markAttendance({
    required String studentUid,
    required String sessionId,
    required String qrToken,
    required double latitude,
    required double longitude,
    required String deviceId,
  }) async {
    return _firestore.runTransaction((tx) async {
      final sessionRef = _sessions.doc(sessionId);
      final sessionSnap = await tx.get(sessionRef);
      if (!sessionSnap.exists) {
        throw const AppException(
          'Session not found.',
          code: 'session_not_found',
        );
      }

      final session = AttendanceSessionModel.fromFirestore(sessionSnap);
      if (!session.isActive || session.isExpired) {
        throw const AppException(
          'Session is no longer accepting attendance.',
          code: 'session_closed',
        );
      }
      if (session.isQrExpired || session.qrToken != qrToken) {
        throw const AppException('QR code has expired.', code: 'qr_expired');
      }

      final existing = await _records
          .where('sessionId', isEqualTo: sessionId)
          .where('studentId', isEqualTo: studentUid)
          .limit(1)
          .get();

      if (existing.docs.isNotEmpty) {
        throw const AppException(
          'Attendance already recorded.',
          code: 'duplicate',
        );
      }

      final minutesLate = DateTime.now()
          .difference(session.startTime)
          .inMinutes;
      final status = minutesLate > AppConstants.lateThresholdMinutes
          ? AttendanceStatus.late
          : AttendanceStatus.present;

      final recordRef = _records.doc();
      final record = AttendanceRecordModel(
        id: recordRef.id,
        studentId: studentUid,
        sessionId: sessionId,
        timestamp: DateTime.now(),
        deviceId: deviceId,
        status: status,
        courseId: session.courseId,
      );

      tx.set(recordRef, record.toFirestore());

      // Invalidate used token (one-time use per scan window)
      tx.update(sessionRef, {
        'qrToken': _uuid.v4(),
        'qrExpiresAt': Timestamp.fromDate(
          DateTime.now().add(
            const Duration(seconds: AppConstants.qrValiditySeconds),
          ),
        ),
      });

      return record;
    });
  }

  @override
  Future<bool> hasMarkedAttendance({
    required String studentUid,
    required String sessionId,
  }) async {
    final snap = await _records
        .where('sessionId', isEqualTo: sessionId)
        .where('studentId', isEqualTo: studentUid)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Stream<List<AttendanceRecord>> watchRecordsForSession(String sessionId) {
    return _records
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AttendanceRecordModel.fromFirestore(d))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
  }

  @override
  Stream<List<AttendanceRecord>> watchRecordsForStudent(String studentUid) {
    return _records
        .where('studentId', isEqualTo: studentUid)
        .snapshots()
        .map(
          (s) => s.docs
              .map((d) => AttendanceRecordModel.fromFirestore(d))
              .toList()
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp)),
        );
  }

  @override
  Future<List<AttendanceRecord>> getRecordsForStudent(String studentUid) async {
    final snap = await _records
        .where('studentId', isEqualTo: studentUid)
        .get();
    return snap.docs
        .map((d) => AttendanceRecordModel.fromFirestore(d))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  @override
  Future<void> logSuspiciousActivity({
    required String userId,
    required String action,
    required String details,
    String? sessionId,
  }) async {
    await _firestore.collection(AppConstants.securityLogsCollection).add({
      'userId': userId,
      'action': action,
      'details': details,
      'sessionId': sessionId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<Map<String, int>> getSessionStats(String sessionId) async {
    final snap = await _records.where('sessionId', isEqualTo: sessionId).get();
    var present = 0, late = 0, absent = 0;
    for (final doc in snap.docs) {
      final status = doc.data()['status'] as String? ?? '';
      switch (status) {
        case 'present':
          present++;
        case 'late':
          late++;
        case 'absent':
          absent++;
      }
    }
    return {
      'present': present,
      'late': late,
      'absent': absent,
      'total': snap.docs.length,
    };
  }
}
