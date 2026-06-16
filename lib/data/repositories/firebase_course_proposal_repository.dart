import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/data/models/course_proposal_model.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/entities/course_proposal.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';
import 'package:smart_attendance/domain/repositories/course_proposal_repository.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';

class FirebaseCourseProposalRepository implements CourseProposalRepository {
  FirebaseCourseProposalRepository({
    FirebaseFirestore? firestore,
    this._catalog,
    this._notifications,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final CatalogRepository? _catalog;
  final NotificationRepository? _notifications;

  CollectionReference<Map<String, dynamic>> get _proposals =>
      _firestore.collection(AppConstants.courseProposalsCollection);

  @override
  Future<void> submitProposal({
    required String proposedCourseId,
    required String name,
    required String description,
    required String departmentId,
    required String lecturerId,
    required String lecturerName,
  }) async {
    final code = proposedCourseId.trim().toUpperCase();
    if (code.isEmpty) {
      throw const AppException('Course ID is required.', code: 'invalid_course_id');
    }
    if (name.trim().isEmpty) {
      throw const AppException('Course name is required.', code: 'invalid_name');
    }
    if (description.trim().isEmpty) {
      throw const AppException(
        'Course description is required.',
        code: 'invalid_description',
      );
    }

    if (_catalog != null) {
      final existing = await _catalog.findCourseByCode(code);
      if (existing != null) {
        throw const AppException(
          'A course with this ID already exists.',
          code: 'duplicate_course_id',
        );
      }
    }

    final pending = await _proposals
        .where('proposedCourseId', isEqualTo: code)
        .where('status', isEqualTo: CourseProposalStatus.pending.name)
        .limit(1)
        .get();
    if (pending.docs.isNotEmpty) {
      throw const AppException(
        'A pending proposal with this Course ID already exists.',
        code: 'duplicate_proposal',
      );
    }

    await _proposals.add({
      'proposedCourseId': code,
      'name': name.trim(),
      'description': description.trim(),
      'departmentId': departmentId,
      'lecturerId': lecturerId,
      'lecturerName': lecturerName,
      'status': CourseProposalStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<List<CourseProposal>> watchPendingProposals() {
    return _proposals
        .where('status', isEqualTo: CourseProposalStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CourseProposalModel.fromFirestore(d))
              .toList(),
        );
  }

  @override
  Stream<List<CourseProposal>> watchProposalsForLecturer(String lecturerId) {
    return _proposals
        .where('lecturerId', isEqualTo: lecturerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CourseProposalModel.fromFirestore(d))
              .toList(),
        );
  }

  @override
  Future<void> approveProposal({
    required String proposalId,
    required String adminId,
  }) async {
    if (_catalog == null) {
      throw const AppException(
        'Catalog service unavailable.',
        code: 'catalog_unavailable',
      );
    }

    final proposalRef = _proposals.doc(proposalId);
    final proposalSnap = await proposalRef.get();
    if (!proposalSnap.exists) {
      throw const AppException('Proposal not found.', code: 'not_found');
    }

    final proposal = CourseProposalModel.fromFirestore(proposalSnap);
    if (proposal.status != CourseProposalStatus.pending) {
      throw const AppException(
        'This proposal has already been reviewed.',
        code: 'already_reviewed',
      );
    }

    final allowedDepts = proposal.departmentId.isNotEmpty
        ? [proposal.departmentId]
        : <String>[];
    final courseRef = await _firestore
        .collection(AppConstants.coursesCollection)
        .add({
      'name': proposal.name,
      'departmentId': proposal.departmentId,
      'allowedDepartmentIds': allowedDepts,
      'courseCode': proposal.proposedCourseId,
      'description': proposal.description,
      'createdBy': proposal.lecturerId,
      'createdByName': proposal.lecturerName,
      'createdByRole': 'lecturer',
      'createdAt': FieldValue.serverTimestamp(),
    });

    final batch = _firestore.batch();
    batch.update(proposalRef, {
      'status': CourseProposalStatus.approved.name,
      'approvedCourseDocId': courseRef.id,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });

    final lecturerRef =
        _firestore.collection(AppConstants.lecturersCollection).doc(
              proposal.lecturerId,
            );
    final lecturerSnap = await lecturerRef.get();
    if (lecturerSnap.exists) {
      final data = lecturerSnap.data()!;
      final courseIds = List<String>.from(data['courseIds'] as List? ?? []);
      if (!courseIds.contains(courseRef.id)) {
        courseIds.add(courseRef.id);
        batch.update(lecturerRef, {'courseIds': courseIds});
      }
    }

    await batch.commit();

    if (_notifications != null) {
      await _notifications.send(
        recipientId: proposal.lecturerId,
        type: NotificationType.courseProposalApproved,
        title: 'Course approved',
        body:
            'Your course "${proposal.name}" (${proposal.proposedCourseId}) has been approved and added to the catalog.',
        relatedId: proposalId,
        metadata: {'courseId': courseRef.id},
      );
    }
  }

  @override
  Future<void> rejectProposal({
    required String proposalId,
    required String adminId,
    required String feedback,
  }) async {
    final proposalRef = _proposals.doc(proposalId);
    final proposalSnap = await proposalRef.get();
    if (!proposalSnap.exists) {
      throw const AppException('Proposal not found.', code: 'not_found');
    }

    final proposal = CourseProposalModel.fromFirestore(proposalSnap);
    if (proposal.status != CourseProposalStatus.pending) {
      throw const AppException(
        'This proposal has already been reviewed.',
        code: 'already_reviewed',
      );
    }

    await proposalRef.update({
      'status': CourseProposalStatus.rejected.name,
      'adminFeedback': feedback.trim(),
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': adminId,
    });

    if (_notifications != null) {
      await _notifications.send(
        recipientId: proposal.lecturerId,
        type: NotificationType.courseProposalRejected,
        title: 'Course proposal declined',
        body:
            'Your course "${proposal.name}" was not approved. Feedback: ${feedback.trim()}',
        relatedId: proposalId,
      );
    }
  }
}
