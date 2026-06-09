import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/domain/entities/enrollment.dart';

class LocalEnrollmentDataSource {
  Future<void> saveEnrollment(Enrollment e) async {
    final hive = HiveEnrollment(
      id: e.id,
      studentId: e.studentId,
      courseId: e.courseId,
      createdAt: e.createdAt,
      syncedAt: DateTime.now(),
    );
    await LocalDatabaseService.enrollmentsBox.put(e.id, hive);
  }

  Future<List<Enrollment>> getEnrollmentsForStudent(String studentId) async {
    return LocalDatabaseService.enrollmentsBox.values
        .where((h) => h.studentId == studentId)
        .map(
          (h) => Enrollment(
            id: h.id,
            studentId: h.studentId,
            courseId: h.courseId,
            createdAt: h.createdAt,
          ),
        )
        .toList();
  }

  Future<void> deleteEnrollment(String id) async {
    await LocalDatabaseService.enrollmentsBox.delete(id);
  }
}
