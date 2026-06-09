import 'package:equatable/equatable.dart';

class Student extends Equatable {
  const Student({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.departmentId,
    required this.courseIds,
    this.deviceId,
  });

  final String id;
  final String name;
  final String studentId;
  final String email;
  final String departmentId;
  final List<String> courseIds;
  final String? deviceId;

  @override
  List<Object?> get props =>
      [id, name, studentId, email, departmentId, courseIds, deviceId];
}
