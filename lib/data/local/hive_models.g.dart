// GENERATED CODE - MANUAL STUB
part of 'hive_models.dart';
// This file is a minimal, hand-written adapter stub to satisfy the analyzer
// and enable running until build_runner is used to generate proper adapters.

class UserRoleAdapter extends TypeAdapter<UserRole> {
  @override
  final int typeId = 20;

  @override
  UserRole read(BinaryReader reader) {
    final value = reader.read() as String;
    return UserRole.fromString(value);
  }

  @override
  void write(BinaryWriter writer, UserRole obj) {
    writer.write(obj.name);
  }
}

class AttendanceStatusAdapter extends TypeAdapter<AttendanceStatus> {
  @override
  final int typeId = 21;

  @override
  AttendanceStatus read(BinaryReader reader) {
    final value = reader.read() as String;
    return AttendanceStatus.fromString(value);
  }

  @override
  void write(BinaryWriter writer, AttendanceStatus obj) {
    writer.write(obj.name);
  }
}

class HiveAppUserAdapter extends TypeAdapter<HiveAppUser> {
  @override
  final int typeId = 0;

  @override
  HiveAppUser read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final email = reader.read() as String;
    final department = reader.read() as String;
    final role = reader.read() as String;
    final roleId = reader.read() as String;
    final createdAt = reader.read() as DateTime?;
    final syncedAt = reader.read() as DateTime?;
    return HiveAppUser(
      id: id,
      name: name,
      email: email,
      department: department,
      role: UserRole.fromString(role),
      roleId: roleId,
      createdAt: createdAt,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAppUser obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.email);
    writer.write(obj.department);
    writer.write(obj.role.name);
    writer.write(obj.roleId);
    writer.write(obj.createdAt);
    writer.write(obj.syncedAt);
  }
}

class HiveStudentAdapter extends TypeAdapter<HiveStudent> {
  @override
  final int typeId = 1;

  @override
  HiveStudent read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final studentId = reader.read() as String;
    final email = reader.read() as String;
    final departmentId = reader.read() as String;
    final courseIds = (reader.read() as List).cast<String>();
    final deviceId = reader.read() as String?;
    final syncedAt = reader.read() as DateTime?;
    return HiveStudent(
      id: id,
      name: name,
      studentId: studentId,
      email: email,
      departmentId: departmentId,
      courseIds: courseIds,
      deviceId: deviceId,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveStudent obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.studentId);
    writer.write(obj.email);
    writer.write(obj.departmentId);
    writer.write(obj.courseIds);
    writer.write(obj.deviceId);
    writer.write(obj.syncedAt);
  }
}

class HiveLecturerAdapter extends TypeAdapter<HiveLecturer> {
  @override
  final int typeId = 2;

  @override
  HiveLecturer read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final lecturerId = reader.read() as String;
    final email = reader.read() as String;
    final departmentId = reader.read() as String;
    final courseIds = (reader.read() as List).cast<String>();
    final syncedAt = reader.read() as DateTime?;
    return HiveLecturer(
      id: id,
      name: name,
      lecturerId: lecturerId,
      email: email,
      departmentId: departmentId,
      courseIds: courseIds,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveLecturer obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.lecturerId);
    writer.write(obj.email);
    writer.write(obj.departmentId);
    writer.write(obj.courseIds);
    writer.write(obj.syncedAt);
  }
}

class HiveCourseAdapter extends TypeAdapter<HiveCourse> {
  @override
  final int typeId = 3;

  @override
  HiveCourse read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final departmentId = reader.read() as String;
    final courseCode = reader.read() as String?;
    final description = reader.read() as String?;
    final createdBy = reader.read() as String?;
    final createdByName = reader.read() as String?;
    final createdByRole = reader.read() as String?;
    final createdAt = reader.read() as DateTime?;
    final syncedAt = reader.read() as DateTime?;
    List<String>? allowedDepartmentIds;
    try {
      allowedDepartmentIds = reader.read() as List<String>?;
    } catch (_) {
      allowedDepartmentIds = null;
    }
    return HiveCourse(
      id: id,
      name: name,
      departmentId: departmentId,
      allowedDepartmentIds: allowedDepartmentIds,
      courseCode: courseCode,
      description: description,
      createdBy: createdBy,
      createdByName: createdByName,
      createdByRole: createdByRole,
      createdAt: createdAt,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCourse obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.departmentId);
    writer.write(obj.courseCode);
    writer.write(obj.description);
    writer.write(obj.createdBy);
    writer.write(obj.createdByName);
    writer.write(obj.createdByRole);
    writer.write(obj.createdAt);
    writer.write(obj.syncedAt);
    writer.write(obj.allowedDepartmentIds);
  }
}

class HiveDepartmentAdapter extends TypeAdapter<HiveDepartment> {
  @override
  final int typeId = 4;

  @override
  HiveDepartment read(BinaryReader reader) {
    final id = reader.read() as String;
    final name = reader.read() as String;
    final syncedAt = reader.read() as DateTime?;
    return HiveDepartment(id: id, name: name, syncedAt: syncedAt);
  }

  @override
  void write(BinaryWriter writer, HiveDepartment obj) {
    writer.write(obj.id);
    writer.write(obj.name);
    writer.write(obj.syncedAt);
  }
}

class HiveAttendanceSessionAdapter extends TypeAdapter<HiveAttendanceSession> {
  @override
  final int typeId = 5;

  @override
  HiveAttendanceSession read(BinaryReader reader) {
    final id = reader.read() as String;
    final courseId = reader.read() as String;
    final lecturerId = reader.read() as String;
    final startTime = reader.read() as DateTime;
    final endTime = reader.read() as DateTime;
    final qrToken = reader.read() as String;
    final qrExpiresAt = reader.read() as DateTime;
    final latitude = reader.read() as double;
    final longitude = reader.read() as double;
    final locationRadiusMeters = reader.read() as double;
    final isActive = reader.read() as bool;
    final syncedAt = reader.read() as DateTime?;
    return HiveAttendanceSession(
      id: id,
      courseId: courseId,
      lecturerId: lecturerId,
      startTime: startTime,
      endTime: endTime,
      qrToken: qrToken,
      qrExpiresAt: qrExpiresAt,
      latitude: latitude,
      longitude: longitude,
      locationRadiusMeters: locationRadiusMeters,
      isActive: isActive,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAttendanceSession obj) {
    writer.write(obj.id);
    writer.write(obj.courseId);
    writer.write(obj.lecturerId);
    writer.write(obj.startTime);
    writer.write(obj.endTime);
    writer.write(obj.qrToken);
    writer.write(obj.qrExpiresAt);
    writer.write(obj.latitude);
    writer.write(obj.longitude);
    writer.write(obj.locationRadiusMeters);
    writer.write(obj.isActive);
    writer.write(obj.syncedAt);
  }
}

class HiveAttendanceRecordAdapter extends TypeAdapter<HiveAttendanceRecord> {
  @override
  final int typeId = 6;

  @override
  HiveAttendanceRecord read(BinaryReader reader) {
    final id = reader.read() as String;
    final studentId = reader.read() as String;
    final sessionId = reader.read() as String;
    final timestamp = reader.read() as DateTime;
    final deviceId = reader.read() as String;
    final status = reader.read() as String;
    final courseId = reader.read() as String?;
    final syncedAt = reader.read() as DateTime?;
    return HiveAttendanceRecord(
      id: id,
      studentId: studentId,
      sessionId: sessionId,
      timestamp: timestamp,
      deviceId: deviceId,
      status: AttendanceStatus.fromString(status),
      courseId: courseId,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAttendanceRecord obj) {
    writer.write(obj.id);
    writer.write(obj.studentId);
    writer.write(obj.sessionId);
    writer.write(obj.timestamp);
    writer.write(obj.deviceId);
    writer.write(obj.status.name);
    writer.write(obj.courseId);
    writer.write(obj.syncedAt);
  }
}

class HiveAppNotificationAdapter extends TypeAdapter<HiveAppNotification> {
  @override
  final int typeId = 7;

  @override
  HiveAppNotification read(BinaryReader reader) {
    final id = reader.read() as String;
    final recipientId = reader.read() as String;
    final type = reader.read() as String;
    final title = reader.read() as String;
    final body = reader.read() as String;
    final createdAt = reader.read() as DateTime;
    final read = reader.read() as bool;
    final relatedId = reader.read() as String?;
    final metadata = reader.read() as String?;
    final syncedAt = reader.read() as DateTime?;
    return HiveAppNotification(
      id: id,
      recipientId: recipientId,
      type: type,
      title: title,
      body: body,
      createdAt: createdAt,
      read: read,
      relatedId: relatedId,
      metadata: metadata,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAppNotification obj) {
    writer.write(obj.id);
    writer.write(obj.recipientId);
    writer.write(obj.type);
    writer.write(obj.title);
    writer.write(obj.body);
    writer.write(obj.createdAt);
    writer.write(obj.read);
    writer.write(obj.relatedId);
    writer.write(obj.metadata);
    writer.write(obj.syncedAt);
  }
}

class HiveAbsenceRequestAdapter extends TypeAdapter<HiveAbsenceRequest> {
  @override
  final int typeId = 8;

  @override
  HiveAbsenceRequest read(BinaryReader reader) {
    final id = reader.read() as String;
    final studentId = reader.read() as String;
    final courseId = reader.read() as String;
    final reason = reader.read() as String;
    final createdAt = reader.read() as DateTime;
    final status = reader.read() as String;
    final fileUrl = reader.read() as String?;
    final studentName = reader.read() as String?;
    final courseName = reader.read() as String?;
    final lecturerFeedback = reader.read() as String?;
    final reviewedAt = reader.read() as DateTime?;
    final reviewedBy = reader.read() as String?;
    final syncedAt = reader.read() as DateTime?;
    return HiveAbsenceRequest(
      id: id,
      studentId: studentId,
      courseId: courseId,
      reason: reason,
      createdAt: createdAt,
      status: status,
      fileUrl: fileUrl,
      studentName: studentName,
      courseName: courseName,
      lecturerFeedback: lecturerFeedback,
      reviewedAt: reviewedAt,
      reviewedBy: reviewedBy,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveAbsenceRequest obj) {
    writer.write(obj.id);
    writer.write(obj.studentId);
    writer.write(obj.courseId);
    writer.write(obj.reason);
    writer.write(obj.createdAt);
    writer.write(obj.status);
    writer.write(obj.fileUrl);
    writer.write(obj.studentName);
    writer.write(obj.courseName);
    writer.write(obj.lecturerFeedback);
    writer.write(obj.reviewedAt);
    writer.write(obj.reviewedBy);
    writer.write(obj.syncedAt);
  }
}

class HiveCourseProposalAdapter extends TypeAdapter<HiveCourseProposal> {
  @override
  final int typeId = 9;

  @override
  HiveCourseProposal read(BinaryReader reader) {
    final id = reader.read() as String;
    final proposedCourseId = reader.read() as String;
    final name = reader.read() as String;
    final description = reader.read() as String;
    final departmentId = reader.read() as String;
    final lecturerId = reader.read() as String;
    final lecturerName = reader.read() as String;
    final status = reader.read() as String;
    final createdAt = reader.read() as DateTime;
    final adminFeedback = reader.read() as String?;
    final approvedCourseDocId = reader.read() as String?;
    final reviewedAt = reader.read() as DateTime?;
    final syncedAt = reader.read() as DateTime?;
    return HiveCourseProposal(
      id: id,
      proposedCourseId: proposedCourseId,
      name: name,
      description: description,
      departmentId: departmentId,
      lecturerId: lecturerId,
      lecturerName: lecturerName,
      status: status,
      createdAt: createdAt,
      adminFeedback: adminFeedback,
      approvedCourseDocId: approvedCourseDocId,
      reviewedAt: reviewedAt,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveCourseProposal obj) {
    writer.write(obj.id);
    writer.write(obj.proposedCourseId);
    writer.write(obj.name);
    writer.write(obj.description);
    writer.write(obj.departmentId);
    writer.write(obj.lecturerId);
    writer.write(obj.lecturerName);
    writer.write(obj.status);
    writer.write(obj.createdAt);
    writer.write(obj.adminFeedback);
    writer.write(obj.approvedCourseDocId);
    writer.write(obj.reviewedAt);
    writer.write(obj.syncedAt);
  }
}

class HiveOfflineQueueItemAdapter extends TypeAdapter<HiveOfflineQueueItem> {
  @override
  final int typeId = 10;

  @override
  HiveOfflineQueueItem read(BinaryReader reader) {
    final id = reader.read() as String;
    final operation = reader.read() as String;
    final collection = reader.read() as String;
    final documentId = reader.read() as String;
    final data = reader.read() as String;
    final createdAt = reader.read() as DateTime;
    final status = reader.read() as String;
    final retryCount = reader.read() as int?;
    final lastRetryAt = reader.read() as DateTime?;
    final error = reader.read() as String?;
    return HiveOfflineQueueItem(
      id: id,
      operation: operation,
      collection: collection,
      documentId: documentId,
      data: data,
      createdAt: createdAt,
      status: status,
      retryCount: retryCount,
      lastRetryAt: lastRetryAt,
      error: error,
    );
  }

  @override
  void write(BinaryWriter writer, HiveOfflineQueueItem obj) {
    writer.write(obj.id);
    writer.write(obj.operation);
    writer.write(obj.collection);
    writer.write(obj.documentId);
    writer.write(obj.data);
    writer.write(obj.createdAt);
    writer.write(obj.status);
    writer.write(obj.retryCount);
    writer.write(obj.lastRetryAt);
    writer.write(obj.error);
  }
}

class HiveSessionCacheAdapter extends TypeAdapter<HiveSessionCache> {
  @override
  final int typeId = 11;

  @override
  HiveSessionCache read(BinaryReader reader) {
    final uid = reader.read() as String;
    final email = reader.read() as String;
    final role = reader.read() as String;
    final name = reader.read() as String?;
    final department = reader.read() as String?;
    final cachedAt = reader.read() as DateTime;
    final expiresAt = reader.read() as DateTime;
    return HiveSessionCache(
      uid: uid,
      email: email,
      role: UserRole.fromString(role),
      name: name,
      department: department,
      cachedAt: cachedAt,
      expiresAt: expiresAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveSessionCache obj) {
    writer.write(obj.uid);
    writer.write(obj.email);
    writer.write(obj.role.name);
    writer.write(obj.name);
    writer.write(obj.department);
    writer.write(obj.cachedAt);
    writer.write(obj.expiresAt);
  }
}

class HiveEnrollmentAdapter extends TypeAdapter<HiveEnrollment> {
  @override
  final int typeId = 12;

  @override
  HiveEnrollment read(BinaryReader reader) {
    final id = reader.read() as String;
    final studentId = reader.read() as String;
    final courseId = reader.read() as String;
    final createdAt = reader.read() as DateTime;
    final syncedAt = reader.read() as DateTime?;
    return HiveEnrollment(
      id: id,
      studentId: studentId,
      courseId: courseId,
      createdAt: createdAt,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveEnrollment obj) {
    writer.write(obj.id);
    writer.write(obj.studentId);
    writer.write(obj.courseId);
    writer.write(obj.createdAt);
    writer.write(obj.syncedAt);
  }
}

// Helper function to register all adapters
void registerManualHiveAdapters() {
  Hive.registerAdapter(UserRoleAdapter());
  Hive.registerAdapter(AttendanceStatusAdapter());
  Hive.registerAdapter(HiveAppUserAdapter());
  Hive.registerAdapter(HiveStudentAdapter());
  Hive.registerAdapter(HiveLecturerAdapter());
  Hive.registerAdapter(HiveCourseAdapter());
  Hive.registerAdapter(HiveDepartmentAdapter());
  Hive.registerAdapter(HiveAttendanceSessionAdapter());
  Hive.registerAdapter(HiveAttendanceRecordAdapter());
  Hive.registerAdapter(HiveAppNotificationAdapter());
  Hive.registerAdapter(HiveAbsenceRequestAdapter());
  Hive.registerAdapter(HiveCourseProposalAdapter());
  Hive.registerAdapter(HiveOfflineQueueItemAdapter());
  Hive.registerAdapter(HiveSessionCacheAdapter());
  Hive.registerAdapter(HiveEnrollmentAdapter());
  Hive.registerAdapter(HiveUserProfileAdapter());
}

class HiveUserProfileAdapter extends TypeAdapter<HiveUserProfile> {
  @override
  final int typeId = 13;

  @override
  HiveUserProfile read(BinaryReader reader) {
    final userId = reader.read() as String;
    final localImagePath = reader.read() as String?;
    final remoteImageUrl = reader.read() as String?;
    final localImageUpdatedAt = reader.read() as DateTime?;
    final pendingSync = reader.read() as bool;
    final syncedAt = reader.read() as DateTime?;
    return HiveUserProfile(
      userId: userId,
      localImagePath: localImagePath,
      remoteImageUrl: remoteImageUrl,
      localImageUpdatedAt: localImageUpdatedAt,
      pendingSync: pendingSync,
      syncedAt: syncedAt,
    );
  }

  @override
  void write(BinaryWriter writer, HiveUserProfile obj) {
    writer.write(obj.userId);
    writer.write(obj.localImagePath);
    writer.write(obj.remoteImageUrl);
    writer.write(obj.localImageUpdatedAt);
    writer.write(obj.pendingSync);
    writer.write(obj.syncedAt);
  }
}
