import 'package:equatable/equatable.dart';

class Enrollment extends Equatable {
  const Enrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.createdAt,
  });

  final String id;
  final String studentId;
  final String courseId;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, studentId, courseId, createdAt];
}
