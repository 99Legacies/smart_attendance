import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
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

final deviceServiceProvider = Provider<DeviceService>((ref) => DeviceService());

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
  return FirebaseAuthRepository(
    catalog: Firebase.apps.isEmpty ? null : ref.read(catalogRepositoryProvider),
  );
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  ref.keepAlive();
  return FirebaseAttendanceRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final absenceRepositoryProvider = Provider<AbsenceRepository>((ref) {
  ref.keepAlive();
  return FirebaseAbsenceRepository(
    notifications: ref.read(notificationRepositoryProvider),
  );
});

final courseProposalRepositoryProvider = Provider<CourseProposalRepository>((
  ref,
) {
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

// authStateProvider — single auth stream for the lifetime of the app.
// keepAlive prevents the StreamProvider from restarting on widget rebuilds.
//
// The repository stream (FirebaseAuthRepository.authStateChanges) already
// handles all stabilisation internally:
//   - Never emits null while a Firebase Auth user exists and a Firestore
//     fetch is in progress.
//   - On timeout or error, emits the last known good user as a fallback.
//   - Uses a broadcast StreamController so multiple listeners (Riverpod +
//     GoRouter's refreshListenable) can subscribe without conflicts.
//
// Do NOT wrap this in a secondary StreamController or debounce layer —
// non-broadcast wrappers break when GoRouter adds its own subscription.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  ref.keepAlive();
  AuthUser? previous;
  bool hasSeenFirst = false;
  return ref.read(authRepositoryProvider).authStateChanges.where((next) {
    // Always pass through the very first value (even null) so the router
    // transitions out of loading state when auth resolves with no user.
    if (!hasSeenFirst) {
      hasSeenFirst = true;
      previous = next;
      return true;
    }
    final changed = !_sameAuthUser(previous, next);
    previous = next;
    return changed;
  });
});

bool _sameAuthUser(AuthUser? a, AuthUser? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return a == b;
  return a.sameIdentity(b);
}

final deviceIdProvider = FutureProvider<String>((ref) async {
  return ref.read(deviceServiceProvider).getDeviceId();
});

final notificationsProvider =
    StreamProvider.family<List<AppNotification>, String>((ref, userId) {
      return ref.read(notificationRepositoryProvider).watchForUser(userId);
    });

final unreadNotificationCountProvider = StreamProvider.family<int, String>((
  ref,
  userId,
) {
  return ref.read(notificationRepositoryProvider).watchUnreadCount(userId);
});

/// Enrollment count for the home screen greeting card.
///
/// Emits the local Hive count immediately (optimistic, so self-enrollments
/// appear before background sync writes to Firestore), then streams the
/// authoritative count from the Firestore student document's `courseIds`
/// field (which admin writes also update in real time).
final studentEnrollmentCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, studentId) async* {
  // Optimistic seed: Hive is updated immediately on self-enroll.
  try {
    final hiveStudent = LocalDatabaseService.studentsBox.get(studentId);
    if (hiveStudent != null) {
      yield hiveStudent.courseIds.length;
    }
  } catch (_) {
    // Box not ready — skip the optimistic seed and wait for Firestore.
  }

  // Authoritative stream: single source of truth for both self-enrolled
  // and admin-assigned courses.
  yield* FirebaseFirestore.instanceFor(app: Firebase.app())
      .collection(AppConstants.studentsCollection)
      .doc(studentId)
      .snapshots()
      .map((doc) {
        final ids = doc.data()?['courseIds'];
        return ids is List ? ids.length : 0;
      });
});
