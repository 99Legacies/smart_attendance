import 'package:smart_attendance/domain/entities/enrollment.dart';

abstract class EnrollmentRepository {
  Future<void> enroll({required String studentId, required String courseId});

  Future<List<Enrollment>> getEnrollmentsForStudent(String studentId);

  /// Live stream of enrollments for [studentId] from Firestore.
  Stream<List<Enrollment>> watchEnrollmentsForStudent(String studentId);
}
