import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/enrollment.dart';

class EnrollmentModel extends Enrollment {
  const EnrollmentModel({
    required super.id,
    required super.studentId,
    required super.courseId,
    required super.createdAt,
  });

  factory EnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return EnrollmentModel(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'courseId': courseId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
