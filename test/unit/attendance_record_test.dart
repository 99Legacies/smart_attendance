import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';

void main() {
  final ts = DateTime(2025, 6, 15, 9, 0);

  AttendanceRecord makeRecord({
    String id = 'rec1',
    String studentId = 'stu1',
    String sessionId = 'ses1',
    AttendanceStatus status = AttendanceStatus.present,
    String? courseId = 'course1',
  }) => AttendanceRecord(
    id: id,
    studentId: studentId,
    sessionId: sessionId,
    timestamp: ts,
    deviceId: 'device1',
    status: status,
    courseId: courseId,
  );

  group('AttendanceRecord construction', () {
    test('stores all required fields', () {
      final r = makeRecord();
      expect(r.id, 'rec1');
      expect(r.studentId, 'stu1');
      expect(r.sessionId, 'ses1');
      expect(r.timestamp, ts);
      expect(r.status, AttendanceStatus.present);
      expect(r.courseId, 'course1');
    });

    test('courseId may be null', () {
      final r = makeRecord(courseId: null);
      expect(r.courseId, isNull);
    });
  });

  group('AttendanceRecord equality (Equatable)', () {
    test('two records with same fields are equal', () {
      expect(makeRecord(), equals(makeRecord()));
    });

    test('records differ when id differs', () {
      expect(makeRecord(id: 'rec1'), isNot(equals(makeRecord(id: 'rec2'))));
    });

    test('records differ when status differs', () {
      expect(
        makeRecord(status: AttendanceStatus.present),
        isNot(equals(makeRecord(status: AttendanceStatus.absent))),
      );
    });
  });

  group('AttendanceRecord props', () {
    test('props list has correct length', () {
      // id, studentId, sessionId, timestamp, deviceId, status, courseId
      expect(makeRecord().props.length, 7);
    });
  });
}
