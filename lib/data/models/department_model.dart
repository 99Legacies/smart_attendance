import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/department.dart';

class DepartmentModel extends Department {
  const DepartmentModel({required super.id, required super.name});

  factory DepartmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return DepartmentModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {'name': name};
}
