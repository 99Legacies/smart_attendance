import 'package:equatable/equatable.dart';

enum CourseProposalStatus { pending, approved, rejected }

class CourseProposal extends Equatable {
  const CourseProposal({
    required this.id,
    required this.proposedCourseId,
    required this.name,
    required this.description,
    required this.departmentId,
    required this.lecturerId,
    required this.lecturerName,
    required this.status,
    required this.createdAt,
    this.adminFeedback,
    this.approvedCourseDocId,
    this.reviewedAt,
  });

  final String id;
  final String proposedCourseId;
  final String name;
  final String description;
  final String departmentId;
  final String lecturerId;
  final String lecturerName;
  final CourseProposalStatus status;
  final DateTime createdAt;
  final String? adminFeedback;
  final String? approvedCourseDocId;
  final DateTime? reviewedAt;

  @override
  List<Object?> get props => [
        id,
        proposedCourseId,
        name,
        description,
        departmentId,
        lecturerId,
        lecturerName,
        status,
        createdAt,
        adminFeedback,
        approvedCourseDocId,
        reviewedAt,
      ];
}
