import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/student.dart';

class StudentModel extends Student {
  const StudentModel({
    required super.id,
    required super.name,
    required super.studentId,
    required super.email,
    required super.departmentId,
    required super.courseIds,
    super.deviceId,
  });

  factory StudentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return StudentModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      studentId: data['studentId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      courseIds: List<String>.from(data['courseIds'] as List? ?? []),
      deviceId: data['deviceId'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'studentId': studentId,
        'email': email,
        'departmentId': departmentId,
        'courseIds': courseIds,
        if (deviceId != null) 'deviceId': deviceId,
      };
}
