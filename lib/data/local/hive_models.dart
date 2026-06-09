import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';

// Generate with: flutter pub run build_runner build

part 'hive_models.g.dart';

/// Local Hive models for offline-first architecture
/// Each model mirrors the domain entity structure

@HiveType(typeId: 0)
class HiveAppUser {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String department;
  @HiveField(4)
  final UserRole role;
  @HiveField(5)
  final String roleId;
  @HiveField(6)
  final DateTime? createdAt;
  @HiveField(7)
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

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'email': email,
    'department': department,
    'role': role.name,
    'roleId': roleId,
    'createdAt': createdAt?.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
  };

  factory HiveAppUser.fromMap(Map<String, dynamic> map) => HiveAppUser(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    department: map['department'],
    role: UserRole.fromString(map['role'] ?? 'student'),
    roleId: map['roleId'],
    createdAt: map['createdAt'] != null
        ? DateTime.parse(map['createdAt'])
        : null,
    syncedAt: map['syncedAt'] != null ? DateTime.parse(map['syncedAt']) : null,
  );
}

@HiveType(typeId: 1)
class HiveStudent {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String studentId;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String departmentId;
  @HiveField(5)
  final List<String> courseIds;
  @HiveField(6)
  final String? deviceId;
  @HiveField(7)
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

@HiveType(typeId: 2)
class HiveLecturer {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String lecturerId;
  @HiveField(3)
  final String email;
  @HiveField(4)
  final String departmentId;
  @HiveField(5)
  final List<String> courseIds;
  @HiveField(6)
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

@HiveType(typeId: 3)
class HiveCourse {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String departmentId;
  @HiveField(3)
  final List<String>? allowedDepartmentIds;
  @HiveField(4)
  final String? courseCode;
  @HiveField(5)
  final String? description;
  @HiveField(6)
  final String? createdBy;
  @HiveField(7)
  final String? createdByName;
  @HiveField(8)
  final String? createdByRole;
  @HiveField(9)
  final DateTime? createdAt;
  @HiveField(10)
  final DateTime? syncedAt;

  HiveCourse({
    required this.id,
    required this.name,
    required this.departmentId,
    this.allowedDepartmentIds,
    this.courseCode,
    this.description,
    this.createdBy,
    this.createdByName,
    this.createdByRole,
    this.createdAt,
    this.syncedAt,
  });
}

@HiveType(typeId: 4)
class HiveDepartment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final DateTime? syncedAt;

  HiveDepartment({required this.id, required this.name, this.syncedAt});
}

@HiveType(typeId: 5)
class HiveAttendanceSession {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String courseId;
  @HiveField(2)
  final String lecturerId;
  @HiveField(3)
  final DateTime startTime;
  @HiveField(4)
  final DateTime endTime;
  @HiveField(5)
  final String qrToken;
  @HiveField(6)
  final DateTime qrExpiresAt;
  @HiveField(7)
  final double latitude;
  @HiveField(8)
  final double longitude;
  @HiveField(9)
  final double locationRadiusMeters;
  @HiveField(10)
  final bool isActive;
  @HiveField(11)
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

@HiveType(typeId: 6)
class HiveAttendanceRecord {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final String sessionId;
  @HiveField(3)
  final DateTime timestamp;
  @HiveField(4)
  final String deviceId;
  @HiveField(5)
  final AttendanceStatus status;
  @HiveField(6)
  final String? courseId;
  @HiveField(7)
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

@HiveType(typeId: 7)
class HiveAppNotification {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String recipientId;
  @HiveField(2)
  final String type;
  @HiveField(3)
  final String title;
  @HiveField(4)
  final String body;
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final bool read;
  @HiveField(7)
  final String? relatedId;
  @HiveField(8)
  final String? metadata;
  @HiveField(9)
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

@HiveType(typeId: 8)
class HiveAbsenceRequest {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final String courseId;
  @HiveField(3)
  final String reason;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final String status;
  @HiveField(6)
  final String? fileUrl;
  @HiveField(7)
  final String? studentName;
  @HiveField(8)
  final String? courseName;
  @HiveField(9)
  final String? lecturerFeedback;
  @HiveField(10)
  final DateTime? reviewedAt;
  @HiveField(11)
  final String? reviewedBy;
  @HiveField(12)
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

@HiveType(typeId: 9)
class HiveCourseProposal {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String proposedCourseId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String description;
  @HiveField(4)
  final String departmentId;
  @HiveField(5)
  final String lecturerId;
  @HiveField(6)
  final String lecturerName;
  @HiveField(7)
  final String status;
  @HiveField(8)
  final DateTime createdAt;
  @HiveField(9)
  final String? adminFeedback;
  @HiveField(10)
  final String? approvedCourseDocId;
  @HiveField(11)
  final DateTime? reviewedAt;
  @HiveField(12)
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
@HiveType(typeId: 10)
class HiveOfflineQueueItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String operation; // 'create', 'update', 'delete'
  @HiveField(2)
  final String collection; // users, attendance_records, etc.
  @HiveField(3)
  final String documentId;
  @HiveField(4)
  final String data; // JSON string
  @HiveField(5)
  final DateTime createdAt;
  @HiveField(6)
  final String status; // 'pending', 'syncing', 'failed'
  @HiveField(7)
  final int? retryCount;
  @HiveField(8)
  final DateTime? lastRetryAt;
  @HiveField(9)
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
@HiveType(typeId: 11)
class HiveSessionCache {
  @HiveField(0)
  final String uid;
  @HiveField(1)
  final String email;
  @HiveField(2)
  final UserRole role;
  @HiveField(3)
  final String? name;
  @HiveField(4)
  final String? department;
  @HiveField(5)
  final DateTime cachedAt;
  @HiveField(6)
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

@HiveType(typeId: 12)
class HiveEnrollment {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final String courseId;
  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final DateTime? syncedAt;

  HiveEnrollment({
    required this.id,
    required this.studentId,
    required this.courseId,
    required this.createdAt,
    this.syncedAt,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'studentId': studentId,
    'courseId': courseId,
    'createdAt': createdAt.toIso8601String(),
    'syncedAt': syncedAt?.toIso8601String(),
  };

  factory HiveEnrollment.fromMap(Map<String, dynamic> m) => HiveEnrollment(
    id: m['id'],
    studentId: m['studentId'],
    courseId: m['courseId'],
    createdAt: DateTime.parse(m['createdAt']),
    syncedAt: m['syncedAt'] != null ? DateTime.parse(m['syncedAt']) : null,
  );
}

@HiveType(typeId: 13)
class HiveUserProfile {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final String? localImagePath;
  @HiveField(2)
  final String? remoteImageUrl;
  @HiveField(3)
  final DateTime? localImageUpdatedAt;
  @HiveField(4)
  final bool pendingSync;
  @HiveField(5)
  final DateTime? syncedAt;

  HiveUserProfile({
    required this.userId,
    this.localImagePath,
    this.remoteImageUrl,
    this.localImageUpdatedAt,
    this.pendingSync = false,
    this.syncedAt,
  });
}
