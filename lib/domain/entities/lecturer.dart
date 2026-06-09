import 'package:equatable/equatable.dart';

class Lecturer extends Equatable {
  const Lecturer({
    required this.id,
    required this.name,
    required this.lecturerId,
    required this.email,
    required this.departmentId,
    required this.courseIds,
  });

  final String id;
  final String name;
  final String lecturerId;
  final String email;
  final String departmentId;
  final List<String> courseIds;

  @override
  List<Object?> get props =>
      [id, name, lecturerId, email, departmentId, courseIds];
}
