import 'dart:async';
import 'dart:developer' as developer;

import 'package:uuid/uuid.dart';

import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/constants/preset_departments.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/data/local/local_catalog_data_source.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/data/local/offline_queue_service.dart';
import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/repositories/firebase_catalog_repository.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/domain/entities/student.dart';

class HybridCatalogRepository implements CatalogRepository {
  final LocalCatalogDataSource _localCatalog;
  final LocalDepartmentDataSource _localDept;
  final FirebaseCatalogRepository _remote;
  final _uuid = const Uuid();

  HybridCatalogRepository({
    required LocalCatalogDataSource local,
    required this._remote,
  }) : _localCatalog = local,
       _localDept = LocalDepartmentDataSource();

  // Departments
  @override
  Stream<List<Department>> watchDepartments() {
    final controller = StreamController<List<Department>>.broadcast();

    Future<void> emit() async {
      var list = await _localDept.getAllDepartments();
      // If local cache is empty, fetch from Firebase and cache locally
      if (list.isEmpty) {
        list = await _remote.getDepartments();
        for (final dept in list) {
          await _localDept.saveDepartment(dept);
        }
      }
      controller.add(list);
    }

    emit();
    final sub = LocalDatabaseService.departmentsBox.watch().listen((_) async {
      await emit();
    });

    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Future<List<Department>> getDepartments() async {
    var list = await _localDept.getAllDepartments();
    if (list.isEmpty) {
      list = await _remote.getDepartments();
      for (final dept in list) {
        await _localDept.saveDepartment(dept);
      }
    }
    return list;
  }

  @override
  Future<void> createDepartment(String name) async {
    // Write to Firebase first to get the real document ID
    try {
      await _remote.createDepartment(name);
      // Refresh local cache from Firebase after creating
      final list = await _remote.getDepartments();
      for (final dept in list) {
        await _localDept.saveDepartment(dept);
      }
      developer.log('Created department in Firebase: $name', name: 'HybridCatalog');
    } catch (e) {
      // Fallback: save locally with a temp ID and queue
      developer.log('Firebase createDepartment failed, queuing: $e', name: 'HybridCatalog');
      final id = _uuid.v4();
      final dept = Department(id: id, name: name.trim());
      await _localDept.saveDepartment(dept);
      await OfflineQueueService.enqueue(
        operation: 'create',
        collection: AppConstants.departmentsCollection,
        documentId: id,
        data: {'id': id, 'name': name.trim()},
      );
    }
  }

  @override
  Future<void> updateDepartment(String id, String name) async {
    final dept = Department(id: id, name: name.trim());
    await _localDept.saveDepartment(dept);
    await OfflineQueueService.enqueue(
      operation: 'update',
      collection: AppConstants.departmentsCollection,
      documentId: id,
      data: {'id': id, 'name': name.trim()},
    );
  }

  @override
  Future<void> deleteDepartment(String id) async {
    await LocalDatabaseService.departmentsBox.delete(id);
    await OfflineQueueService.enqueue(
      operation: 'delete',
      collection: AppConstants.departmentsCollection,
      documentId: id,
      data: {},
    );
  }

  @override
  Future<String> ensureDepartmentByName(String name) async {
    final list = await _localDept.getAllDepartments();
    for (final d in list) {
      if (d.name.toLowerCase() == name.trim().toLowerCase()) return d.id;
    }

    await createDepartment(name);

    final refreshed = await _localDept.getAllDepartments();
    for (final d in refreshed) {
      if (d.name.toLowerCase() == name.trim().toLowerCase()) return d.id;
    }

    return '';
  }

  @override
  Future<int> seedPresetDepartments() async {
    var created = 0;
    final existing = await _localDept.getAllDepartments();
    for (final deptName in PresetDepartments.allNames) {
      var exists = false;
      for (final d in existing) {
        if (d.name.toLowerCase() == deptName.toLowerCase()) {
          exists = true;
          break;
        }
      }
      if (!exists) {
        await createDepartment(deptName);
        created++;
      }
    }
    return created;
  }

  // Courses
  @override
  Stream<List<Course>> watchCourses({String? departmentId}) {
    final controller = StreamController<List<Course>>.broadcast();

    Future<void> emit() async {
      var list = await _localCatalog.getAllCourses();
      // If local cache is empty, fetch from Firebase and cache locally
      if (list.isEmpty) {
        list = await _remote.getCourses(departmentId: departmentId);
        for (final course in list) {
          await _localCatalog.saveCourse(course);
        }
      }
      controller.add(
        departmentId == null
            ? list
            : list.where((c) => c.allowsDepartment(departmentId)).toList(),
      );
    }

    emit();
    final sub = LocalDatabaseService.coursesBox.watch().listen((_) async {
      await emit();
    });
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Future<List<Course>> getCourses({String? departmentId}) async {
    if (departmentId == null) {
      return _localCatalog.getAllCourses();
    }
    return _localCatalog.getCoursesByDepartment(departmentId);
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
    final allowedDepartments = allowedDepartmentIds ??
        (departmentId.trim().isEmpty ? <String>[] : [departmentId.trim()]);
    final id = _uuid.v4();
    final course = Course(
      id: id,
      name: name.trim(),
      allowedDepartmentIds: allowedDepartments,
      courseCode: courseCode,
      description: description,
      createdBy: createdBy,
      createdByName: createdByName,
      createdByRole: createdByRole,
      createdAt: DateTime.now(),
    );
    await _localCatalog.saveCourse(course);
    await OfflineQueueService.enqueue(
      operation: 'create',
      collection: AppConstants.coursesCollection,
      documentId: id,
      data: {
        'id': id,
        'name': name.trim(),
        'allowedDepartmentIds': allowedDepartments,
        if (allowedDepartments.isNotEmpty)
          'departmentId': allowedDepartments.first,
        'courseCode': courseCode,
        'description': description,
        'createdBy': createdBy,
        'createdByName': createdByName,
        'createdByRole': createdByRole,
      },
    );
  }

  @override
  Future<String?> findCourseByCode(String courseCode) async {
    final all = await _localCatalog.getAllCourses();
    final found = all.firstWhere(
      (c) =>
          (c.courseCode ?? '').toUpperCase() == courseCode.trim().toUpperCase(),
      orElse: () => Course(id: '', name: '', allowedDepartmentIds: []),
    );
    return found.id.isNotEmpty ? found.id : null;
  }

  @override
  Future<Course?> getCourse(String id) async {
    final local = await _localCatalog.getCourseById(id);
    if (local != null) return local;
    final remote = await _remote.getCourse(id);
    if (remote != null) {
      await _localCatalog.saveCourse(remote);
    }
    return remote;
  }

  @override
  Future<void> updateCourse(
    String id, {
    required String name,
    required String departmentId,
    List<String>? allowedDepartmentIds,
  }) async {
    final existing = await _localCatalog.getCourseById(id);
    if (existing == null) throw Exception('Course not found');
    final allowedDepartments = allowedDepartmentIds ??
        (departmentId.trim().isEmpty ? <String>[] : [departmentId.trim()]);
    final updated = Course(
      id: id,
      name: name.trim(),
      allowedDepartmentIds: allowedDepartments,
      courseCode: existing.courseCode,
      description: existing.description,
      createdBy: existing.createdBy,
      createdByName: existing.createdByName,
      createdByRole: existing.createdByRole,
      createdAt: existing.createdAt,
    );
    await _localCatalog.saveCourse(updated);
    await OfflineQueueService.enqueue(
      operation: 'update',
      collection: AppConstants.coursesCollection,
      documentId: id,
      data: {
        'id': id,
        'name': name.trim(),
        'allowedDepartmentIds': allowedDepartments,
        if (allowedDepartments.isNotEmpty)
          'departmentId': allowedDepartments.first,
      },
    );
  }

  @override
  Future<void> deleteCourse(String id) async {
    await _localCatalog.deleteCourse(id);
    await OfflineQueueService.enqueue(
      operation: 'delete',
      collection: AppConstants.coursesCollection,
      documentId: id,
      data: {},
    );
  }

  // Students
  Student _hiveStudentToDomain(dynamic hive) {
    return Student(
      id: hive.id,
      name: hive.name,
      studentId: hive.studentId,
      email: hive.email,
      departmentId: hive.departmentId,
      courseIds: List<String>.from(hive.courseIds ?? []),
      deviceId: hive.deviceId,
    );
  }

  @override
  Stream<List<Student>> watchStudentsByCourse(String courseId) {
    final controller = StreamController<List<Student>>.broadcast();
    Future<void> emit() async {
      final list = LocalDatabaseService.studentsBox.values
          .where((s) => (s.courseIds).contains(courseId))
          .map(_hiveStudentToDomain)
          .toList();
      controller.add(list);
    }

    emit();
    final sub = LocalDatabaseService.studentsBox.watch().listen((_) async {
      await emit();
    });
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  @override
  Future<Student?> getStudent(String uid) async {
    final hive = LocalDatabaseService.studentsBox.get(uid);
    if (hive != null) return _hiveStudentToDomain(hive);
    // Fall back to Firebase if not in local cache
    final remote = await _remote.getStudent(uid);
    if (remote != null) {
      // Cache it locally for next time
      final h = HiveStudent(
        id: remote.id,
        name: remote.name,
        studentId: remote.studentId,
        email: remote.email,
        departmentId: remote.departmentId,
        courseIds: remote.courseIds,
        deviceId: remote.deviceId,
      );
      await LocalDatabaseService.studentsBox.put(uid, h);
    }
    return remote;
  }

  @override
  Future<bool> isStudentIdTaken(String studentId) async {
    final localFound = LocalDatabaseService.studentsBox.values.any(
      (s) => s.studentId == studentId.trim(),
    );
    if (localFound) return true;
    return await _remote.isStudentIdTaken(studentId);
  }

  @override
  Future<void> createStudentProfile(Student student, String authUid) async {
    // store minimal map in Hive
    final hive = HiveStudent(
      id: authUid,
      name: student.name,
      studentId: student.studentId,
      email: student.email,
      departmentId: student.departmentId,
      courseIds: student.courseIds,
      deviceId: student.deviceId,
    );
    await LocalDatabaseService.studentsBox.put(authUid, hive);
    await OfflineQueueService.enqueue(
      operation: 'create',
      collection: AppConstants.studentsCollection,
      documentId: authUid,
      data: {
        'id': authUid,
        'name': student.name,
        'studentId': student.studentId,
        'email': student.email,
        'departmentId': student.departmentId,
        'courseIds': student.courseIds,
        'deviceId': student.deviceId,
      },
    );
  }

  @override
  Future<void> updateStudent(Student student) async {
    final hive = HiveStudent(
      id: student.id,
      name: student.name,
      studentId: student.studentId,
      email: student.email,
      departmentId: student.departmentId,
      courseIds: student.courseIds,
      deviceId: student.deviceId,
    );
    await LocalDatabaseService.studentsBox.put(student.id, hive);
    await OfflineQueueService.enqueue(
      operation: 'update',
      collection: AppConstants.studentsCollection,
      documentId: student.id,
      data: {
        'id': student.id,
        'name': student.name,
        'studentId': student.studentId,
        'email': student.email,
        'departmentId': student.departmentId,
        'courseIds': student.courseIds,
        'deviceId': student.deviceId,
      },
    );
  }

  @override
  Future<void> deleteStudent(String uid) async {
    await LocalDatabaseService.studentsBox.delete(uid);
    await OfflineQueueService.enqueue(
      operation: 'delete',
      collection: AppConstants.studentsCollection,
      documentId: uid,
      data: {},
    );
  }

  @override
  Stream<List<Student>> watchStudents() {
    final controller = StreamController<List<Student>>.broadcast();
    Future<void> emit() async {
      var list = LocalDatabaseService.studentsBox.values
          .map(_hiveStudentToDomain)
          .toList();
      // If local cache is empty, fetch from Firebase and cache locally
      if (list.isEmpty) {
        list = await _remote.watchStudents().first;
        for (final student in list) {
          final h = HiveStudent(
            id: student.id,
            name: student.name,
            studentId: student.studentId,
            email: student.email,
            departmentId: student.departmentId,
            courseIds: student.courseIds,
            deviceId: student.deviceId,
          );
          await LocalDatabaseService.studentsBox.put(student.id, h);
        }
      }
      controller.add(list);
    }

    emit();
    final sub = LocalDatabaseService.studentsBox.watch().listen((_) async {
      await emit();
    });
    controller.onCancel = () => sub.cancel();
    return controller.stream;
  }

  // Lecturers
  Lecturer _hiveLecturerToDomain(dynamic hive) {
    return Lecturer(
      id: hive.id,
      name: hive.name,
      lecturerId: hive.lecturerId,
      email: hive.email,
      departmentId: hive.departmentId,
      courseIds: List<String>.from(hive.courseIds ?? []),
    );
  }

  @override
  Stream<List<Lecturer>> watchLecturers() {
    final controller = StreamController<List<Lecturer>>.broadcast();
    Future<void> emit() async {
      var list = LocalDatabaseService.lecturersBox.values
          .map(_hiveLecturerToDomain)
          .toList();
      // If local cache is empty, fetch from Firebase and cache locally
      if (list.isEmpty) {
        list = await _remote.watchLecturers().first;
        for (final lecturer in list) {
          final h = HiveLecturer(
            id: lecturer.id,
            name: lecturer.name,
            lecturerId: lecturer.lecturerId,
            email: lecturer.email,
            departmentId: lecturer.departmentId,
            courseIds: lecturer.courseIds,
          );
          await LocalDatabaseService.lecturersBox.put(lecturer.id, h);
        }
      }
      controller.add(list);
    }

    emit();
    final sub = LocalDatabaseService.lecturersBox.watch().listen((_) async {
      await emit();
    });
    controller.onCancel = () => sub.cancel();
    return controller.stream;
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
    final hive = HiveLecturer(
      id: lecturer.id,
      name: lecturer.name,
      lecturerId: lecturer.lecturerId,
      email: lecturer.email,
      departmentId: lecturer.departmentId,
      courseIds: lecturer.courseIds,
    );
    await LocalDatabaseService.lecturersBox.put(lecturer.id, hive);
    await OfflineQueueService.enqueue(
      operation: 'update',
      collection: AppConstants.lecturersCollection,
      documentId: lecturer.id,
      data: {
        'id': lecturer.id,
        'name': lecturer.name,
        'lecturerId': lecturer.lecturerId,
        'email': lecturer.email,
        'departmentId': lecturer.departmentId,
        'courseIds': lecturer.courseIds,
      },
    );
  }

  @override
  Future<void> deleteLecturer(String uid) async {
    await LocalDatabaseService.lecturersBox.delete(uid);
    await OfflineQueueService.enqueue(
      operation: 'delete',
      collection: AppConstants.lecturersCollection,
      documentId: uid,
      data: {},
    );
  }

  @override
  Future<Lecturer?> getLecturer(String uid) async {
    final hive = LocalDatabaseService.lecturersBox.get(uid);
    if (hive != null) return _hiveLecturerToDomain(hive);
    // Fall back to Firebase if not in local cache
    final remote = await _remote.getLecturer(uid);
    if (remote != null) {
      // Cache it locally for next time
      final h = HiveLecturer(
        id: remote.id,
        name: remote.name,
        lecturerId: remote.lecturerId,
        email: remote.email,
        departmentId: remote.departmentId,
        courseIds: remote.courseIds,
      );
      await LocalDatabaseService.lecturersBox.put(uid, h);
    }
    return remote;
  }
}
