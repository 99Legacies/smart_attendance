import 'dart:typed_data';

import 'package:smart_attendance/domain/entities/absence_request.dart';

abstract class AbsenceRepository {
  Future<String> submitRequest({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseName,
    required String reason,
    Uint8List? fileBytes,
    String? fileName,
  });

  Stream<List<AbsenceRequest>> watchRequestsForStudent(String studentId);

  Stream<List<AbsenceRequest>> watchPendingForLecturerCourses(
    List<String> courseIds,
  );

  Future<void> respondToRequest({
    required String requestId,
    required String lecturerId,
    required AbsenceRequestStatus status,
    required String feedback,
  });
}
