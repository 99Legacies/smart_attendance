import 'dart:developer' as developer;

import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/domain/entities/course.dart';
import 'package:smart_attendance/domain/entities/department.dart'
    as domain_dept;

/// Local data source for courses using Hive
class LocalCatalogDataSource {
  /// Get course by ID
  Future<Course?> getCourseById(String courseId) async {
    try {
      final hiveCourse = LocalDatabaseService.coursesBox.get(courseId);
      if (hiveCourse != null) {
        developer.log('Found course in local DB: $courseId', name: 'LocalData');
        return _hiveToCourse(hiveCourse);
      }
      return null;
    } catch (error, stack) {
      developer.log(
        'Failed to get course from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get all cached courses
  Future<List<Course>> getAllCourses() async {
    try {
      return LocalDatabaseService.coursesBox.values.map(_hiveToCourse).toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get all courses from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Get courses for department
  Future<List<Course>> getCoursesByDepartment(String departmentId) async {
    try {
      return LocalDatabaseService.coursesBox.values
          .map(_hiveToCourse)
          .where((c) {
            if (departmentId.isEmpty) return true;
            return c.allowsDepartment(departmentId);
          })
          .toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get courses for department from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save course to local database
  Future<void> saveCourse(Course course) async {
    try {
      final hiveCourse = _courseToHive(course);
      await LocalDatabaseService.coursesBox.put(course.id, hiveCourse);
      developer.log(
        'Saved course to local DB: ${course.id}',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save course to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Save multiple courses
  Future<void> saveCourses(List<Course> courses) async {
    try {
      final map = {
        for (final course in courses) course.id: _courseToHive(course),
      };
      await LocalDatabaseService.coursesBox.putAll(map);
      developer.log(
        'Saved ${courses.length} courses to local DB',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save courses to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Delete course
  Future<void> deleteCourse(String courseId) async {
    try {
      await LocalDatabaseService.coursesBox.delete(courseId);
      developer.log(
        'Deleted course from local DB: $courseId',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to delete course from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Clear all courses
  Future<void> clearCourses() async {
    try {
      await LocalDatabaseService.coursesBox.clear();
      developer.log('Cleared all courses from local DB', name: 'LocalData');
    } catch (error, stack) {
      developer.log(
        'Failed to clear courses from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  static Course _hiveToCourse(HiveCourse hive) {
    final allowedDepartments = (hive.allowedDepartmentIds ?? []).isNotEmpty
        ? List<String>.from(hive.allowedDepartmentIds!)
        : (hive.departmentId.isNotEmpty ? [hive.departmentId] : <String>[]);
    return Course(
      id: hive.id,
      name: hive.name,
      allowedDepartmentIds: allowedDepartments,
      courseCode: hive.courseCode,
      description: hive.description,
      createdBy: hive.createdBy,
      createdByName: hive.createdByName,
      createdByRole: hive.createdByRole,
      createdAt: hive.createdAt,
    );
  }

  static HiveCourse _courseToHive(Course course) {
    return HiveCourse(
      id: course.id,
      name: course.name,
      departmentId: course.departmentId,
      allowedDepartmentIds: course.allowedDepartmentIds,
      courseCode: course.courseCode,
      description: course.description,
      createdBy: course.createdBy,
      createdByName: course.createdByName,
      createdByRole: course.createdByRole,
      createdAt: course.createdAt,
      syncedAt: DateTime.now(),
    );
  }
}

/// Local data source for departments using Hive
class LocalDepartmentDataSource {
  /// Get department by ID
  Future<domain_dept.Department?> getDepartmentById(String deptId) async {
    try {
      final hiveDept = LocalDatabaseService.departmentsBox.get(deptId);
      if (hiveDept != null) {
        return _hiveToDepartment(hiveDept);
      }
      return null;
    } catch (error, stack) {
      developer.log(
        'Failed to get department from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get all cached departments
  Future<List<domain_dept.Department>> getAllDepartments() async {
    try {
      return LocalDatabaseService.departmentsBox.values
          .map(_hiveToDepartment)
          .toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get all departments from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save department
  Future<void> saveDepartment(domain_dept.Department department) async {
    try {
      final hiveDept = _departmentToHive(department);
      await LocalDatabaseService.departmentsBox.put(department.id, hiveDept);
      developer.log(
        'Saved department to local DB: ${department.id}',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save department to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Save multiple departments
  Future<void> saveDepartments(List<domain_dept.Department> departments) async {
    try {
      final map = {
        for (final dept in departments) dept.id: _departmentToHive(dept),
      };
      await LocalDatabaseService.departmentsBox.putAll(map);
      developer.log(
        'Saved ${departments.length} departments to local DB',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save departments to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  static domain_dept.Department _hiveToDepartment(HiveDepartment hive) {
    return domain_dept.Department(id: hive.id, name: hive.name);
  }

  static HiveDepartment _departmentToHive(domain_dept.Department dept) {
    return HiveDepartment(
      id: dept.id,
      name: dept.name,
      syncedAt: DateTime.now(),
    );
  }
}
