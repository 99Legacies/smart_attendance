import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/domain/entities/absence_request.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/repositories/absence_repository.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';

class FirebaseAbsenceRepository implements AbsenceRepository {
  FirebaseAbsenceRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    this._notifications,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final NotificationRepository? _notifications;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(AppConstants.absenceRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _records =>
      _firestore.collection(AppConstants.recordsCollection);

  AbsenceRequest _fromDoc(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    return AbsenceRequest(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      courseId: data['courseId'] as String? ?? '',
      reason: data['reason'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AbsenceRequestStatus.values.firstWhere(
        (s) => s.name == (data['status'] as String? ?? 'pending'),
        orElse: () => AbsenceRequestStatus.pending,
      ),
      fileUrl: data['fileUrl'] as String?,
      studentName: data['studentName'] as String?,
      courseName: data['courseName'] as String?,
      lecturerFeedback: data['lecturerFeedback'] as String?,
      reviewedAt: (data['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: data['reviewedBy'] as String?,
    );
  }

  @override
  Future<String> submitRequest({
    required String studentId,
    required String studentName,
    required String courseId,
    required String courseName,
    required String reason,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    String? fileUrl;
    if (fileBytes != null && fileName != null) {
      final ref = _storage.ref(
        'absence_files/$studentId/${DateTime.now().millisecondsSinceEpoch}_$fileName',
      );
      await ref.putData(fileBytes);
      fileUrl = await ref.getDownloadURL();
    }

    final doc = await _requests.add({
      'studentId': studentId,
      'studentName': studentName,
      'courseId': courseId,
      'courseName': courseName,
      'reason': reason.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'status': AbsenceRequestStatus.pending.name,
      'fileUrl': ?fileUrl,
    });

    await _notifyLecturersForCourse(
      courseId: courseId,
      courseName: courseName,
      studentName: studentName,
      requestId: doc.id,
    );

    return doc.id;
  }

  Future<void> _notifyLecturersForCourse({
    required String courseId,
    required String courseName,
    required String studentName,
    required String requestId,
  }) async {
    if (_notifications == null) return;

    final lecturers = await _firestore
        .collection(AppConstants.lecturersCollection)
        .where('courseIds', arrayContains: courseId)
        .get();

    for (final doc in lecturers.docs) {
      await _notifications.send(
        recipientId: doc.id,
        type: NotificationType.absenceSubmitted,
        title: 'New absence request',
        body:
            '$studentName submitted an absence request for $courseName. Tap to review.',
        relatedId: requestId,
        metadata: {'courseId': courseId},
      );
    }
  }

  @override
  Stream<List<AbsenceRequest>> watchRequestsForStudent(String studentId) {
    return _requests
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map(
          (snap) => snap.docs.map(_fromDoc).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
        );
  }

  @override
  Stream<List<AbsenceRequest>> watchPendingForLecturerCourses(
    List<String> courseIds,
  ) {
    if (courseIds.isEmpty) {
      return Stream.value([]);
    }

    return _requests
        .where('status', isEqualTo: AbsenceRequestStatus.pending.name)
        .snapshots()
        .map((snap) {
          final courseSet = courseIds.toSet();
          return snap.docs
              .map(_fromDoc)
              .where((r) => courseSet.contains(r.courseId))
              .toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
  }

  @override
  Future<void> respondToRequest({
    required String requestId,
    required String lecturerId,
    required AbsenceRequestStatus status,
    required String feedback,
  }) async {
    if (feedback.trim().isEmpty) {
      throw const AppException(
        'Please provide feedback for the student.',
        code: 'missing_feedback',
      );
    }

    final docRef = _requests.doc(requestId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw const AppException('Request not found.', code: 'not_found');
    }

    final request = _fromDoc(snap);
    if (request.status != AbsenceRequestStatus.pending) {
      throw const AppException(
        'This request has already been reviewed.',
        code: 'already_reviewed',
      );
    }

    final now = Timestamp.now();
    final batch = _firestore.batch();

    // Update the absence request status
    batch.update(docRef, {
      'status': status.name,
      'lecturerFeedback': feedback.trim(),
      'reviewedAt': now,
      'reviewedBy': lecturerId,
    });

    // If APPROVED: find the student's absence record for this session
    // and update it from absent → present with correction metadata
    if (status == AbsenceRequestStatus.approved) {
      final existingRecords = await _records
          .where('studentId', isEqualTo: request.studentId)
          .where('courseId', isEqualTo: request.courseId)
          .where('status', isEqualTo: 'absent')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (existingRecords.docs.isNotEmpty) {
        // Update existing absent record → present with correction metadata
        batch.update(existingRecords.docs.first.reference, {
          'status': 'present',
          'source': 'CORRECTION',
          'approvedBy': lecturerId,
          'approvedAt': now,
        });
      }
    }
    // If REJECTED: no changes to attendance record — only update request status

    await batch.commit();

    // Send notification to student
    if (_notifications != null) {
      final approved = status == AbsenceRequestStatus.approved;
      await _notifications.send(
        recipientId: request.studentId,
        type: NotificationType.absenceReviewed,
        title: approved ? 'Absence approved' : 'Absence declined',
        body: approved
            ? 'Your absence request for ${request.courseName ?? "the course"} was approved. Your attendance has been updated. Feedback: ${feedback.trim()}'
            : 'Your absence request for ${request.courseName ?? "the course"} was declined. Feedback: ${feedback.trim()}',
        relatedId: requestId,
        metadata: {'status': status.name},
      );
    }
  }
}
