import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/course.dart';

class CourseModel extends Course {
  const CourseModel({
    required super.id,
    required super.name,
    required super.allowedDepartmentIds,
    super.courseCode,
    super.description,
    super.createdBy,
    super.createdByName,
    super.createdByRole,
    super.createdAt,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final allowedDepartments = List<String>.from(
      data['allowedDepartmentIds'] as List? ?? [],
    );
    if (allowedDepartments.isEmpty) {
      final legacyDepartment = data['departmentId'] as String?;
      if (legacyDepartment != null && legacyDepartment.isNotEmpty) {
        allowedDepartments.add(legacyDepartment);
      }
    }
    return CourseModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      allowedDepartmentIds: allowedDepartments,
      courseCode: data['courseCode'] as String?,
      description: data['description'] as String?,
      createdBy: data['createdBy'] as String?,
      createdByName: data['createdByName'] as String?,
      createdByRole: data['createdByRole'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final data = {
      'name': name,
      'allowedDepartmentIds': allowedDepartmentIds,
      if (allowedDepartmentIds.isNotEmpty)
        'departmentId': allowedDepartmentIds.first,
      if (courseCode != null) 'courseCode': courseCode,
      if (description != null) 'description': description,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdByName != null) 'createdByName': createdByName,
      if (createdByRole != null) 'createdByRole': createdByRole,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
    return data;
  }
}
