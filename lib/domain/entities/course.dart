import 'package:equatable/equatable.dart';

class Course extends Equatable {
  const Course({
    required this.id,
    required this.name,
    required this.allowedDepartmentIds,
    this.courseCode,
    this.description,
    this.createdBy,
    this.createdByName,
    this.createdByRole,
    this.createdAt,
  });

  final String id;
  final String name;
  final List<String> allowedDepartmentIds;
  final String? courseCode;
  final String? description;
  final String? createdBy;
  final String? createdByName;
  final String? createdByRole;
  final DateTime? createdAt;

  String get departmentId =>
      allowedDepartmentIds.isNotEmpty ? allowedDepartmentIds.first : '';

  bool get allowsAllDepartments => allowedDepartmentIds.isEmpty;

  bool allowsDepartment(String departmentId) {
    if (allowsAllDepartments) return true;
    return allowedDepartmentIds.contains(departmentId);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        allowedDepartmentIds,
        courseCode,
        description,
        createdBy,
        createdByName,
        createdByRole,
        createdAt,
      ];
}
