import 'package:smart_attendance/domain/entities/course_proposal.dart';

abstract class CourseProposalRepository {
  Future<void> submitProposal({
    required String proposedCourseId,
    required String name,
    required String description,
    required String departmentId,
    required String lecturerId,
    required String lecturerName,
  });

  Stream<List<CourseProposal>> watchPendingProposals();

  Stream<List<CourseProposal>> watchProposalsForLecturer(String lecturerId);

  Future<void> approveProposal({
    required String proposalId,
    required String adminId,
  });

  Future<void> rejectProposal({
    required String proposalId,
    required String adminId,
    required String feedback,
  });
}
