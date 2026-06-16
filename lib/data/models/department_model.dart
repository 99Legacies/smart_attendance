import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({required super.id, required super.name});

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    // Prefer the stored departmentId field; fall back to doc.id for documents
    // that pre-date the backfill migration.
    final storedId = data['departmentId'] as String?;
    return DepartmentModel(
      id: (storedId != null && storedId.isNotEmpty) ? storedId : doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'departmentId': id,
      };
}
