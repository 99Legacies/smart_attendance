import 'package:hive_flutter/hive_flutter.dart';

// Hive model definitions for offline-first architecture
// No code generation needed - using standard Hive storage without custom adapters

/// Local Hive models for offline-first architecture
/// Each model mirrors the domain entity structure

class HiveAppUser {
  final String id;
  final String name;
  final String email;
  final String department;
  final String role;
  final String roleId;
  final DateTime? createdAt;
  final DateTime? syncedAt;

  HiveAppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.roleId,
    this.createdAt,
    this.syncedAt,
  });
}

class HiveStudent {
  final String id;
  final String name;
  final String studentId;
  final String email;
  final String departmentId;
  final List<String> courseIds;
  final String? deviceId;
  final DateTime? syncedAt;

  HiveStudent({
    required this.id,
    required this.name,
    required this.studentId,
    required this.email,
    required this.departmentId,
    required this.courseIds,
    this.deviceId,
    this.syncedAt,
  });
}

class HiveLecturer {
  final String id;
  final String name;
  final String lecturerId;
  final String email;
  final String departmentId;
  final List<String> courseIds;
  final DateTime? syncedAt;

  HiveLecturer({
    required this.id,
    required this.name,
    required this.lecturerId,
    required this.email,
    required this.departmentId,
    required this.courseIds,
    this.syncedAt,
  });
}

class HiveCourse {
  final String id;
  final String name;
  final String departmentId;
  final String? courseCode;
  final String? description;
  final String? createdBy;
  final String? createdByName;
  final String? createdByRole;
  final DateTime? createdAt;
  final DateTime? syncedAt;

  HiveCourse({
    required this.id,
    required this.name,
    required this.departmentId,
    this.courseCode,
    this.description,
    this.createdBy,
    this.createdByName,
    this.createdByRole,
    this.createdAt,
    this.syncedAt,
  });
}

class HiveDepartment {
  final String id;
  final String name;
  final DateTime? syncedAt;

  HiveDepartment({required this.id, required this.name, this.syncedAt});
}

class HiveAttendanceSession {
  final String id;
  final String courseId;
  final String lecturerId;
  final DateTime startTime;
  final DateTime endTime;
  final String qrToken;
  final DateTime qrExpiresAt;
  final double latitude;
  final double longitude;
  final double locationRadiusMeters;
  final bool isActive;
  final DateTime? syncedAt;

  HiveAttendanceSession({
    required this.id,
    required this.courseId,
    required this.lecturerId,
    required this.startTime,
    required this.endTime,
    required this.qrToken,
    required this.qrExpiresAt,
    required this.latitude,
    required this.longitude,
    required this.locationRadiusMeters,
    required this.isActive,
    this.syncedAt,
  });
}

class HiveAttendanceRecord {
  final String id;
  final String studentId;
  final String sessionId;
  final DateTime timestamp;
  final String deviceId;
  final String status;
  final String? courseId;
  final DateTime? syncedAt;

  HiveAttendanceRecord({
    required this.id,
    required this.studentId,
    required this.sessionId,
    required this.timestamp,
    required this.deviceId,
    required this.status,
    this.courseId,
    this.syncedAt,
  });
}

class HiveAppNotification {
  final String id;
  final String recipientId;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;
  final String? relatedId;
  final String? metadata;
  final DateTime? syncedAt;

  HiveAppNotification({
    required this.id,
    required this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    this.relatedId,
    this.metadata,
    this.syncedAt,
  });
}

class HiveAbsenceRequest {
  final String id;
  final String studentId;
  final String courseId;
  final String reason;
  final DateTime createdAt;
  final String status;
  final String? fileUrl;
  final String? studentName;
  final String? courseName;
  final String? lecturerFeedback;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final DateTime? syncedAt;

  HiveAbsenceRequest({
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
    this.syncedAt,
  });
}

class HiveCourseProposal {
  final String id;
  final String proposedCourseId;
  final String name;
  final String description;
  final String departmentId;
  final String lecturerId;
  final String lecturerName;
  final String status;
  final DateTime createdAt;
  final String? adminFeedback;
  final String? approvedCourseDocId;
  final DateTime? reviewedAt;
  final DateTime? syncedAt;

  HiveCourseProposal({
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
    this.syncedAt,
  });
}

/// Offline queue item for tracking unsynced writes
class HiveOfflineQueueItem {
  final String id;
  final String operation; // 'create', 'update', 'delete'
  final String collection; // users, attendance_records, etc.
  final String documentId;
  final String data; // JSON string
  final DateTime createdAt;
  final String status; // 'pending', 'syncing', 'failed'
  final int? retryCount;
  final DateTime? lastRetryAt;
  final String? error;

  HiveOfflineQueueItem({
    required this.id,
    required this.operation,
    required this.collection,
    required this.documentId,
    required this.data,
    required this.createdAt,
    required this.status,
    this.retryCount,
    this.lastRetryAt,
    this.error,
  });
}

/// Session cache for offline login support
class HiveSessionCache {
  final String uid;
  final String email;
  final String role;
  final String? name;
  final String? department;
  final DateTime cachedAt;
  final DateTime expiresAt;

  HiveSessionCache({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.department,
    required this.cachedAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}
