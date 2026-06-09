import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';

class LecturerModel extends Lecturer {
  const LecturerModel({
    required super.id,
    required super.name,
    required super.lecturerId,
    required super.email,
    required super.departmentId,
    required super.courseIds,
  });

  factory LecturerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return LecturerModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      lecturerId: data['lecturerId'] as String? ?? '',
      email: data['email'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      courseIds: List<String>.from(data['courseIds'] as List? ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'lecturerId': lecturerId,
        'email': email,
        'departmentId': departmentId,
        'courseIds': courseIds,
      };
}
