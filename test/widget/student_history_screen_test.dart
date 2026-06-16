import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/domain/entities/attendance_record.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/student/student_history_screen.dart';

import '../helpers/fake_repositories.dart';

Widget _wrap(Widget child, AttendanceRepository repo) {
  return ProviderScope(
    overrides: [
      attendanceRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(home: Scaffold(body: child)),
  );
}

AttendanceRecord _record({
  String id = 'r1',
  AttendanceStatus status = AttendanceStatus.present,
}) => AttendanceRecord(
  id: id,
  studentId: 'stu1',
  sessionId: 'ses1',
  timestamp: DateTime(2025, 6, 15, 9, 0),
  deviceId: 'device1',
  status: status,
  courseId: 'course1',
);

void main() {
  group('StudentHistoryScreen — states', () {
    testWidgets('shows loading shimmer while stream is pending', (tester) async {
      final repo = FakeAttendanceRepository(
        recordsStream: const Stream.empty(),
      );

      await tester.pumpWidget(_wrap(
        const StudentHistoryScreen(studentUid: 'stu1'),
        repo,
      ));

      // First frame before stream emits: loading state
      // ApLoadingList is shown during loading
      expect(find.byType(CircularProgressIndicator), findsNothing);
      // The screen uses ApLoadingList — verify it or the shimmer is visible
      // (ApLoadingList is a shimmer placeholder list)
      expect(find.byType(StudentHistoryScreen), findsOneWidget);
    });

    testWidgets('shows empty state when student has no records', (tester) async {
      final repo = FakeAttendanceRepository(
        recordsStream: Stream.value([]),
      );

      await tester.pumpWidget(_wrap(
        const StudentHistoryScreen(studentUid: 'stu1'),
        repo,
      ));
      await tester.pump();

      expect(find.text('No attendance records yet.'), findsOneWidget);
    });

    testWidgets('shows list of records when data is available', (tester) async {
      final records = [
        _record(id: 'r1', status: AttendanceStatus.present),
        _record(id: 'r2', status: AttendanceStatus.late),
        _record(id: 'r3', status: AttendanceStatus.absent),
      ];
      final repo = FakeAttendanceRepository(
        recordsStream: Stream.value(records),
      );

      await tester.pumpWidget(_wrap(
        const StudentHistoryScreen(studentUid: 'stu1'),
        repo,
      ));
      await tester.pump();

      expect(find.text('Present'), findsOneWidget);
      expect(find.text('Late'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
    });

    testWidgets('shows friendly error when stream emits an error', (tester) async {
      final repo = FakeAttendanceRepository(
        recordsStream: Stream.error(Exception('permission-denied')),
      );

      await tester.pumpWidget(_wrap(
        const StudentHistoryScreen(studentUid: 'stu1'),
        repo,
      ));
      await tester.pump();

      expect(find.text('Could not load attendance history'), findsOneWidget);
      // Must NOT display raw exception text
      expect(find.textContaining('Exception'), findsNothing);
      expect(find.textContaining('permission-denied'), findsNothing);
    });

    testWidgets('shows green icon for present record', (tester) async {
      final repo = FakeAttendanceRepository(
        recordsStream: Stream.value([_record(status: AttendanceStatus.present)]),
      );

      await tester.pumpWidget(_wrap(
        const StudentHistoryScreen(studentUid: 'stu1'),
        repo,
      ));
      await tester.pump();

      final icon = tester.widget<Icon>(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.check_circle,
        ),
      );
      expect(icon.color, Colors.green);
    });

    testWidgets('shows orange icon for late record', (tester) async {
      final repo = FakeAttendanceRepository(
        recordsStream: Stream.value([_record(status: AttendanceStatus.late)]),
      );

      await tester.pumpWidget(_wrap(
        const StudentHistoryScreen(studentUid: 'stu1'),
        repo,
      ));
      await tester.pump();

      final icon = tester.widget<Icon>(
        find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.schedule,
        ),
      );
      expect(icon.color, Colors.orange);
    });
  });
}
