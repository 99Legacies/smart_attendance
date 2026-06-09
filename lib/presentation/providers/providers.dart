import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/data/repositories/firebase_absence_repository.dart';
import 'package:smart_attendance/data/repositories/firebase_attendance_repository.dart';
import 'package:smart_attendance/data/repositories/firebase_auth_repository.dart';
import 'package:smart_attendance/data/repositories/firebase_catalog_repository.dart';
import 'package:smart_attendance/data/repositories/hybrid_catalog_repository.dart';
import 'package:smart_attendance/data/repositories/hybrid_enrollment_repository.dart';
import 'package:smart_attendance/data/local/local_catalog_data_source.dart';
import 'package:smart_attendance/data/repositories/firebase_course_proposal_repository.dart';
import 'package:smart_attendance/data/repositories/firebase_notification_repository.dart';
import 'package:smart_attendance/data/repositories/firebase_user_repository.dart';
import 'package:smart_attendance/data/services/device_service.dart';
import 'package:smart_attendance/data/services/location_service.dart';
import 'package:smart_attendance/domain/repositories/absence_repository.dart';
import 'package:smart_attendance/domain/repositories/attendance_repository.dart';
import 'package:smart_attendance/domain/repositories/auth_repository.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';
import 'package:smart_attendance/domain/repositories/course_proposal_repository.dart';
import 'package:smart_attendance/domain/repositories/notification_repository.dart';
import 'package:smart_attendance/domain/repositories/user_repository.dart';
import 'package:smart_attendance/domain/entities/app_notification.dart';
import 'package:smart_attendance/domain/usecases/mark_attendance_usecase.dart';

final deviceServiceProvider = Provider<DeviceService>(
  (ref) => DeviceService(),
);

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

// Use keepAlive so this is never recreated after first build
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  ref.keepAlive();
  return HybridCatalogRepository(
    local: LocalCatalogDataSource(),
    remote: FirebaseCatalogRepository(),
  );
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  ref.keepAlive();
  return FirebaseNotificationRepository();
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  ref.keepAlive();
  return FirebaseUserRepository();
});

// Use ref.read instead of ref.watch so catalog rebuilds don't
// recreate FirebaseAuthRepository and restart authStateChanges
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  ref.keepAlive();
  return FirebaseAuthRepository(catalog: ref.read(catalogRepositoryProvider));
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  ref.keepAlive();
  return FirebaseAttendanceRepository(
    catalog: ref.read(catalogRepositoryProvider),
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final absenceRepositoryProvider = Provider<AbsenceRepository>((ref) {
  ref.keepAlive();
  return FirebaseAbsenceRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final courseProposalRepositoryProvider =
    Provider<CourseProposalRepository>((ref) {
  ref.keepAlive();
  return FirebaseCourseProposalRepository(
    catalog: ref.read(catalogRepositoryProvider),
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final enrollmentRepositoryProvider = Provider((ref) {
  ref.keepAlive();
  return HybridEnrollmentRepository();
});

final markAttendanceUseCaseProvider = Provider<MarkAttendanceUseCase>((ref) {
  ref.keepAlive();
  return MarkAttendanceUseCase(
    attendanceRepository: ref.read(attendanceRepositoryProvider),
    catalogRepository: ref.read(catalogRepositoryProvider),
  );
});

// authStateProvider is a StreamProvider — it holds the single auth stream
// for the lifetime of the app. keepAlive prevents it from restarting.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  ref.keepAlive();
  return ref.read(authRepositoryProvider).authStateChanges;
});

final deviceIdProvider = FutureProvider<String>((ref) async {
  return ref.read(deviceServiceProvider).getDeviceId();
});

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
  return ref.read(notificationRepositoryProvider).watchForUser(userId);
});

final unreadNotificationCountProvider =
    StreamProvider.family<int, String>((ref, userId) {
  return ref.read(notificationRepositoryProvider).watchUnreadCount(userId);
});
