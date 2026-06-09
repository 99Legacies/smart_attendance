import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/course_proposal.dart';

class CourseProposalModel extends CourseProposal {
  const CourseProposalModel({
    required super.id,
    required super.proposedCourseId,
    required super.name,
    required super.description,
    required super.departmentId,
    required super.lecturerId,
    required super.lecturerName,
    required super.status,
    required super.createdAt,
    super.adminFeedback,
    super.approvedCourseDocId,
    super.reviewedAt,
  });

  factory CourseProposalModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return CourseProposalModel(
      id: doc.id,
      proposedCourseId: data['proposedCourseId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      lecturerId: data['lecturerId'] as String? ?? '',
      lecturerName: data['lecturerName'] as String? ?? '',
      status: CourseProposalStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'pending'),
        orElse: () => CourseProposalStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      adminFeedback: data['adminFeedback'] as String?,
      approvedCourseDocId: data['approvedCourseDocId'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'proposedCourseId': proposedCourseId,
        'name': name,
        'description': description,
        'departmentId': departmentId,
        'lecturerId': lecturerId,
        'lecturerName': lecturerName,
        'status': status.name,
        'createdAt': Timestamp.fromDate(createdAt),
        if (adminFeedback != null) 'adminFeedback': adminFeedback,
        if (approvedCourseDocId != null)
          'approvedCourseDocId': approvedCourseDocId,
        if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
      };
}
