import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/constants/preset_departments.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/data/models/course_model.dart';
import 'package:smart_attendance/data/models/department_model.dart';
import 'package:smart_attendance/data/models/lecturer_model.dart';
import 'package:smart_attendance/data/models/student_model.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/domain/entities/student.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseCatalogRepository implements CatalogRepository {
  FirebaseCatalogRepository({FirebaseFirestore? firestore})
    : _firestore =
          firestore ?? FirebaseFirestore.instanceFor(app: Firebase.app());

  final FirebaseFirestore _firestore;

  @override
  Stream<List<Department>> watchDepartments() {
    return _firestore
        .collection(AppConstants.departmentsCollection)
        .orderBy('name')
        .snapshots()
        .map(
          (s) => s.docs.map((d) => DepartmentModel.fromFirestore(d)).toList(),
        );
  }

  @override
  Future<List<Department>> getDepartments() async {
    final snap = await _firestore
        .collection(AppConstants.departmentsCollection)
        .orderBy('name')
        .get();
    return snap.docs.map((d) => DepartmentModel.fromFirestore(d)).toList();
  }

  @override
  Stream<List<Course>> watchCourses({String? departmentId}) {
    final query = _firestore.collection(AppConstants.coursesCollection);
    return query.orderBy('name').snapshots().map((s) {
      final courses = s.docs.map((d) => CourseModel.fromFirestore(d)).toList();
      if (departmentId == null) return courses;
      return courses.where((c) => c.allowsDepartment(departmentId)).toList();
    });
  }

  @override
  Future<List<Course>> getCourses({String? departmentId}) async {
    final snap = await _firestore
        .collection(AppConstants.coursesCollection)
        .orderBy('name')
        .get();
    final courses = snap.docs.map((d) => CourseModel.fromFirestore(d)).toList();
    if (departmentId == null) return courses;
    return courses.where((c) => c.allowsDepartment(departmentId)).toList();
  }

  @override
  Future<void> createDepartment(String name) async {
    // Pre-generate a document reference so we can include departmentId in the
    // initial write (a single atomic set instead of add + update).
    final ref = _firestore.collection(AppConstants.departmentsCollection).doc();
    await ref.set({'name': name.trim(), 'departmentId': ref.id});
  }

  @override
  Future<void> updateDepartment(String id, String name) async {
    await _firestore
        .collection(AppConstants.departmentsCollection)
        .doc(id)
        .update({'name': name.trim(), 'departmentId': id});
  }

  @override
  Future<void> deleteDepartment(String id) async {
    await _firestore
        .collection(AppConstants.departmentsCollection)
        .doc(id)
        .delete();
  }

  @override
  Future<String> ensureDepartmentByName(String name) async {
    final trimmed = name.trim();
    final existing = await _firestore
        .collection(AppConstants.departmentsCollection)
        .where('name', isEqualTo: trimmed)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      return existing.docs.first.id;
    }
    final ref = _firestore.collection(AppConstants.departmentsCollection).doc();
    await ref.set({'name': trimmed, 'departmentId': ref.id});
    return ref.id;
  }

  @override
  Future<int> seedPresetDepartments() async {
    var created = 0;
    for (final deptName in PresetDepartments.allNames) {
      final existing = await _firestore
          .collection(AppConstants.departmentsCollection)
          .where('name', isEqualTo: deptName)
          .limit(1)
          .get();
      if (existing.docs.isEmpty) {
        final ref =
            _firestore.collection(AppConstants.departmentsCollection).doc();
        await ref.set({'name': deptName, 'departmentId': ref.id});
        created++;
      }
    }
    return created;
  }

  @override
  Future<void> createCourse({
    required String name,
    required String departmentId,
    List<String>? allowedDepartmentIds,
    String? courseCode,
    String? description,
    required String createdBy,
    required String createdByName,
    required String createdByRole,
  }) async {
    if (name.trim().isEmpty) {
      throw const AppException(
        'Course name is required.',
        code: 'invalid_name',
      );
    }

    final allowedDepartments =
        allowedDepartmentIds ??
        (departmentId.trim().isEmpty ? <String>[] : [departmentId.trim()]);
    if (allowedDepartments.any((id) => id.trim().isEmpty)) {
      throw const AppException(
        'Invalid department selection.',
        code: 'invalid_department',
      );
    }

    final code = courseCode?.trim().toUpperCase();
    if (code != null && code.isNotEmpty) {
      final existing = await findCourseByCode(code);
      if (existing != null) {
        throw const AppException(
          'A course with this ID already exists.',
          code: 'duplicate_course_id',
        );
      }
    }

    await _firestore.collection(AppConstants.coursesCollection).add({
      'name': name.trim(),
      'allowedDepartmentIds': allowedDepartments,
      if (allowedDepartments.isNotEmpty)
        'departmentId': allowedDepartments.first,
      if (code != null && code.isNotEmpty) 'courseCode': code,
      if (description != null && description.trim().isNotEmpty)
        'description': description.trim(),
      'createdBy': createdBy,
      'createdByName': createdByName.trim(),
      'createdByRole': createdByRole,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<String?> findCourseByCode(String courseCode) async {
    final snap = await _firestore
        .collection(AppConstants.coursesCollection)
        .where('courseCode', isEqualTo: courseCode.trim().toUpperCase())
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  @override
  Future<Course?> getCourse(String id) async {
    final doc = await _firestore
        .collection(AppConstants.coursesCollection)
        .doc(id)
        .get();
    if (!doc.exists) return null;
    return CourseModel.fromFirestore(doc);
  }

  @override
  Stream<List<Student>> watchStudentsByCourse(String courseId) {
    return _firestore
        .collection(AppConstants.studentsCollection)
        .where('courseIds', arrayContains: courseId)
        .snapshots()
        .map((s) => s.docs.map((d) => StudentModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> updateCourse(
    String id, {
    required String name,
    required String departmentId,
    List<String>? allowedDepartmentIds,
  }) async {
    final allowedDepartments =
        allowedDepartmentIds ??
        (departmentId.trim().isEmpty ? <String>[] : [departmentId.trim()]);
    await _firestore.collection(AppConstants.coursesCollection).doc(id).update({
      'name': name.trim(),
      'allowedDepartmentIds': allowedDepartments,
      if (allowedDepartments.isNotEmpty)
        'departmentId': allowedDepartments.first,
      if (allowedDepartments.isEmpty) 'departmentId': FieldValue.delete(),
    });
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _firestore
        .collection(AppConstants.coursesCollection)
        .doc(id)
        .delete();
  }

  @override
  Stream<List<Student>> watchStudents() {
    return _firestore
        .collection(AppConstants.studentsCollection)
        .snapshots()
        .map((s) => s.docs.map((d) => StudentModel.fromFirestore(d)).toList());
  }

  @override
  Future<Student?> getStudent(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return StudentModel.fromFirestore(doc);
  }

  @override
  Future<bool> isStudentIdTaken(String studentId) async {
    final snap = await _firestore
        .collection(AppConstants.studentsCollection)
        .where('studentId', isEqualTo: studentId.trim())
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  @override
  Future<void> createStudentProfile(Student student, String authUid) async {
    final data = student is StudentModel
        ? student.toFirestore()
        : {
            'name': student.name,
            'studentId': student.studentId,
            'email': student.email,
            'departmentId': student.departmentId,
            'courseIds': student.courseIds,
            'deviceId': student.deviceId,
          };
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(authUid)
        .set({...data, 'role': UserRole.student.name});
  }

  @override
  Future<void> updateStudent(Student student) async {
    final data = student is StudentModel
        ? student.toFirestore()
        : {
            'name': student.name,
            'studentId': student.studentId,
            'email': student.email,
            'departmentId': student.departmentId,
            'courseIds': student.courseIds,
            'deviceId': student.deviceId,
          };
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(student.id)
        .update(data);
  }

  @override
  Future<void> deleteStudent(String uid) async {
    await _firestore
        .collection(AppConstants.studentsCollection)
        .doc(uid)
        .delete();
  }

  @override
  Stream<List<Lecturer>> watchLecturers() {
    return _firestore
        .collection(AppConstants.lecturersCollection)
        .snapshots()
        .map((s) => s.docs.map((d) => LecturerModel.fromFirestore(d)).toList());
  }

  @override
  Future<void> createLecturer({
    required String name,
    required String email,
    required String password,
    required List<String> courseIds,
  }) async {
    throw const AppException(
      'Lecturers register in the app via Sign In > Register as Lecturer.',
      code: 'lecturer_self_register',
    );
  }

  @override
  Future<void> updateLecturer(Lecturer lecturer) async {
    final data = lecturer is LecturerModel
        ? lecturer.toFirestore()
        : {
            'name': lecturer.name,
            'lecturerId': lecturer.lecturerId,
            'email': lecturer.email,
            'departmentId': lecturer.departmentId,
            'courseIds': lecturer.courseIds,
          };
    await _firestore
        .collection(AppConstants.lecturersCollection)
        .doc(lecturer.id)
        .update(data);
  }

  @override
  Future<void> deleteLecturer(String uid) async {
    await _firestore
        .collection(AppConstants.lecturersCollection)
        .doc(uid)
        .delete();
  }

  @override
  Future<Lecturer?> getLecturer(String uid) async {
    developer.log('getLecturer uid: $uid', name: 'FirebaseCatalog');
    final doc = await _firestore
        .collection(AppConstants.lecturersCollection)
        .doc(uid)
        .get();
    developer.log(
      'getLecturer doc.exists=${doc.exists}, doc.id=${doc.id}',
      name: 'FirebaseCatalog',
    );
    if (!doc.exists) return null;
    return LecturerModel.fromFirestore(doc);
  }
}
