import 'package:equatable/equatable.dart';

enum AbsenceRequestStatus { pending, approved, rejected }

class AbsenceRequest extends Equatable {
  const AbsenceRequest({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.reason,
    required this.createdAt,
    required this.status,
    this.fileUrl,
    this.studentName,
    this.courseName,
    this.lecturerFeedback,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String studentId;
  final String courseId;
  final String reason;
  final DateTime createdAt;
  final AbsenceRequestStatus status;
  final String? fileUrl;
  final String? studentName;
  final String? courseName;
  final String? lecturerFeedback;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  @override
  List<Object?> get props => [
        id,
        studentId,
        courseId,
        reason,
        createdAt,
        status,
        fileUrl,
        studentName,
        courseName,
        lecturerFeedback,
        reviewedAt,
        reviewedBy,
      ];
}
