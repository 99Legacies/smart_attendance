import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:uuid/uuid.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/data/local/local_enrollment_data_source.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/offline_queue_service.dart';
import 'package:smart_attendance/domain/entities/enrollment.dart';
import 'package:smart_attendance/domain/repositories/enrollment_repository.dart';

class HybridEnrollmentRepository implements EnrollmentRepository {
  final _local = LocalEnrollmentDataSource();
  final _uuid = const Uuid();

  @override
  Future<void> enroll({
    required String studentId,
    required String courseId,
  }) async {
    // Check existing
    final hiveStudent = LocalDatabaseService.studentsBox.get(studentId);
    if (hiveStudent == null) {
      throw Exception('Student not found locally');
    }

    final existing = (hiveStudent.courseIds).contains(courseId);
    if (existing) {
      developer.log(
        'Student already enrolled: $studentId -> $courseId',
        name: 'Enrollment',
      );
      return;
    }

    // Create enrollment record locally
    final id = _uuid.v4();
    final enrollment = Enrollment(
      id: id,
      studentId: studentId,
      courseId: courseId,
      createdAt: DateTime.now(),
    );
    await _local.saveEnrollment(enrollment);

    // Update student's course list locally
    final updatedCourseIds = List<String>.from(hiveStudent.courseIds);
    updatedCourseIds.add(courseId);
    // Build updated HiveStudent using existing fields
    final newHive = HiveStudent(
      id: hiveStudent.id,
      name: hiveStudent.name,
      studentId: hiveStudent.studentId,
      email: hiveStudent.email,
      departmentId: hiveStudent.departmentId,
      courseIds: updatedCourseIds,
      deviceId: hiveStudent.deviceId,
      syncedAt: DateTime.now(),
    );
    await LocalDatabaseService.studentsBox.put(studentId, newHive);

    // Queue sync: create enrollment and update student
    await OfflineQueueService.enqueue(
      operation: 'create',
      collection: AppConstants.enrollmentsCollection,
      documentId: id,
      data: {
        'id': enrollment.id,
        'studentId': enrollment.studentId,
        'courseId': enrollment.courseId,
        'createdAt': enrollment.createdAt.toIso8601String(),
      },
    );

    await OfflineQueueService.enqueue(
      operation: 'update',
      collection: AppConstants.studentsCollection,
      documentId: studentId,
      data: {
        'id': newHive.id,
        'name': newHive.name,
        'studentId': newHive.studentId,
        'email': newHive.email,
        'departmentId': newHive.departmentId,
        'courseIds': newHive.courseIds,
        'deviceId': newHive.deviceId,
      },
    );

    developer.log(
      'Enrolled student locally and queued sync: $studentId -> $courseId',
      name: 'Enrollment',
    );
  }

  @override
  Future<List<Enrollment>> getEnrollmentsForStudent(String studentId) async {
    return _local.getEnrollmentsForStudent(studentId);
  }

  @override
  Stream<List<Enrollment>> watchEnrollmentsForStudent(String studentId) {
    return FirebaseFirestore.instanceFor(app: Firebase.app())
        .collection(AppConstants.enrollmentsCollection)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return Enrollment(
                id: d.id,
                studentId: data['studentId'] as String? ?? '',
                courseId: data['courseId'] as String? ?? '',
                createdAt:
                    (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
              );
            }).toList());
  }
}
