import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';

void main() {
  group('AttendanceStatus.fromString', () {
    test('parses "present"', () {
      expect(AttendanceStatus.fromString('present'), AttendanceStatus.present);
    });

    test('parses "late"', () {
      expect(AttendanceStatus.fromString('late'), AttendanceStatus.late);
    });

    test('parses "absent"', () {
      expect(AttendanceStatus.fromString('absent'), AttendanceStatus.absent);
    });

    test('defaults to absent for unknown value', () {
      expect(AttendanceStatus.fromString('unknown'), AttendanceStatus.absent);
    });

    test('defaults to absent for empty string', () {
      expect(AttendanceStatus.fromString(''), AttendanceStatus.absent);
    });

    test('is case-insensitive', () {
      expect(AttendanceStatus.fromString('PRESENT'), AttendanceStatus.present);
      expect(AttendanceStatus.fromString('Late'), AttendanceStatus.late);
    });
  });

  group('AttendanceStatus.label', () {
    test('present label is "Present"', () {
      expect(AttendanceStatus.present.label, 'Present');
    });

    test('late label is "Late"', () {
      expect(AttendanceStatus.late.label, 'Late');
    });

    test('absent label is "Absent"', () {
      expect(AttendanceStatus.absent.label, 'Absent');
    });
  });

  group('AttendanceStatus round-trip via name', () {
    test('name serialises back to the same value', () {
      for (final status in AttendanceStatus.values) {
        expect(AttendanceStatus.fromString(status.name), status);
      }
    });
  });
}
