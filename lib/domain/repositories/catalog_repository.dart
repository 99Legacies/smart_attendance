import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart';
import 'package:smart_attendance/domain/entities/lecturer.dart';
import 'package:smart_attendance/domain/entities/student.dart';

abstract class CatalogRepository {
  Stream<List<Department>> watchDepartments();
  Future<List<Department>> getDepartments();

  Stream<List<Course>> watchCourses({String? departmentId});
  Future<List<Course>> getCourses({String? departmentId});

  Future<void> createDepartment(String name);
  Future<void> updateDepartment(String id, String name);
  Future<void> deleteDepartment(String id);

  /// Returns existing department id or creates one with [name].
  Future<String> ensureDepartmentByName(String name);

  /// Creates any preset departments that are not yet in Firestore.
  Future<int> seedPresetDepartments();

  Future<void> createCourse({
    required String name,
    required String departmentId,
    List<String>? allowedDepartmentIds,
    String? courseCode,
    String? description,
    required String createdBy,
    required String createdByName,
    required String createdByRole,
  });

  Future<String?> findCourseByCode(String courseCode);

  Future<Course?> getCourse(String id);

  Stream<List<Student>> watchStudentsByCourse(String courseId);
  Future<void> updateCourse(
    String id, {
    required String name,
    required String departmentId,
    List<String>? allowedDepartmentIds,
  });
  Future<void> deleteCourse(String id);

  Stream<List<Student>> watchStudents();
  Future<Student?> getStudent(String uid);
  Future<bool> isStudentIdTaken(String studentId);
  Future<void> createStudentProfile(Student student, String authUid);
  Future<void> updateStudent(Student student);
  Future<void> deleteStudent(String uid);

  Stream<List<Lecturer>> watchLecturers();
  Future<void> createLecturer({
    required String name,
    required String email,
    required String password,
    required List<String> courseIds,
  });
  Future<void> updateLecturer(Lecturer lecturer);
  Future<void> deleteLecturer(String uid);

  Future<Lecturer?> getLecturer(String uid);
}
