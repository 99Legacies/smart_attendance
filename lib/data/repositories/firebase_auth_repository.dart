import 'dart:async';
import 'dart:developer' as developer;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/constants/preset_departments.dart';
import 'package:smart_attendance/core/errors/app_exception.dart';
import 'package:smart_attendance/data/local/local_user_data_source.dart';
import 'package:smart_attendance/data/local/session_cache_service.dart';
import 'package:smart_attendance/data/models/lecturer_model.dart';
import 'package:smart_attendance/data/models/student_model.dart';
import 'package:smart_attendance/data/models/user_model.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/domain/repositories/auth_repository.dart';
import 'package:smart_attendance/domain/repositories/catalog_repository.dart';
import 'package:smart_attendance/features/auth/services/session_guard.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    this._catalog,
    LocalUserDataSource? localUserDataSource,
  }) : _auth = auth ?? (Firebase.apps.isEmpty ? null : FirebaseAuth.instance),
       _firestore =
           firestore ??
           (Firebase.apps.isEmpty ? null : FirebaseFirestore.instance),
       _functions =
           functions ??
           (Firebase.apps.isEmpty
               ? null
               : FirebaseFunctions.instanceFor(region: 'us-central1')),
       _localUserDataSource = localUserDataSource ?? LocalUserDataSource();

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseFunctions? _functions;
  final CatalogRepository? _catalog;
  final LocalUserDataSource _localUserDataSource;

  @override
  Stream<AuthUser?> get authStateChanges {
    final controller = StreamController<AuthUser?>.broadcast();
    AuthUser? lastUser;
    bool fetchInProgress = false;
    bool hasEmitted = false;
    StreamSubscription<User?>? sub;

    void emitDistinct(AuthUser? next) {
      // Always pass through the very first emission (even null), so the router
      // can tell the difference between "still loading" and "no user".
      if (hasEmitted && _areSameUser(lastUser, next)) return;
      hasEmitted = true;
      lastUser = next;
      if (!controller.isClosed) controller.add(next);
    }

    Future<void> start() async {
      final cached = await _loadCachedAuthUser();
      if (cached != null) {
        developer.log(
          'AUTH_STREAM: emitting cached session for ${cached.uid}',
          name: 'FirebaseAuth',
        );
        emitDistinct(cached);
      }

      final auth = _auth;
      if (auth == null) {
        developer.log(
          'AUTH_STREAM: Firebase unavailable; using local session only',
          name: 'FirebaseAuth',
        );
        // Offline with no cached session — emit null so the router can redirect
        // to login instead of staying on splash forever.
        if (!hasEmitted) emitDistinct(null);
        return;
      }

      sub = auth.authStateChanges().listen(
        (firebaseUser) async {
          developer.log(
            'AUTH_STREAM: Firebase user = ${firebaseUser?.uid ?? 'NULL'}',
            name: 'FirebaseAuth',
          );

          if (firebaseUser == null) {
            if (!fetchInProgress) {
              emitDistinct(await _loadCachedAuthUser());
            }
            return;
          }

          fetchInProgress = true;

          try {
            final profile = await _getUserProfile(firebaseUser.uid).timeout(
              const Duration(seconds: 10),
              onTimeout: () {
                developer.log(
                  'AUTH_STREAM: Profile fetch timed out - using fallback',
                  name: 'FirebaseAuth',
                );
                return null;
              },
            );

            late AuthUser authUser;
            if (profile != null) {
              authUser = AuthUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? profile.email,
                role: profile.role,
                name: profile.name,
                department: profile.department,
              );
            } else {
              final role = await resolveRole(firebaseUser.uid).timeout(
                const Duration(seconds: 10),
                onTimeout: () {
                  developer.log(
                    'AUTH_STREAM: resolveRole timed out - using cached role',
                    name: 'FirebaseAuth',
                  );
                  return lastUser?.role ?? UserRole.student;
                },
              );
              authUser = AuthUser(
                uid: firebaseUser.uid,
                email: firebaseUser.email ?? '',
                role: role,
              );
            }

            await _persistUserForOffline(authUser);
            emitDistinct(authUser);
          } catch (error, stack) {
            developer.log(
              'AUTH_STREAM: profile fetch error - emitting cached fallback',
              name: 'FirebaseAuth',
              error: error,
              stackTrace: stack,
            );
            final fallback =
                await _loadCachedAuthUser() ??
                lastUser ??
                AuthUser(
                  uid: firebaseUser.uid,
                  email: firebaseUser.email ?? '',
                  role: UserRole.student,
                );
            emitDistinct(fallback);
          } finally {
            fetchInProgress = false;
          }
        },
        onError: controller.addError,
        onDone: controller.close,
      );
    }

    start();

    controller.onCancel = () async {
      await sub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
    required String deviceId,
    bool enforceSingleDevice = false,
  }) async {
    final auth = _requireAuth();
    final firestore = _requireFirestore();

    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user!.uid;
      final profile = await _getUserProfile(uid);
      final role = profile?.role ?? await resolveRole(uid);

      final authUser = AuthUser(
        uid: uid,
        email: email.trim(),
        role: role,
        name: profile?.name,
        department: profile?.department,
      );

      if (role == UserRole.student && enforceSingleDevice) {
        try {
          final doc = await firestore
              .collection(AppConstants.studentsCollection)
              .doc(uid)
              .get();
          if (doc.exists) {
            final data = doc.data()!;
            final storedDevice = data['deviceId'] as String?;

            if (storedDevice != null &&
                storedDevice != deviceId &&
                !storedDevice.startsWith('web-') &&
                storedDevice != 'unknown-device') {
              await auth.signOut();
              throw const AppException(
                'Account is already logged in on another device.',
                code: 'multi_device',
              );
            }
          }
        } catch (error, stack) {
          if (error is AppException) rethrow;
          developer.log(
            'Device check failed: $error',
            name: 'FirebaseAuth',
            error: error,
            stackTrace: stack,
          );
        }
      }

      await _persistUserForOffline(authUser);

      if (role == UserRole.student) {
        Future.microtask(() async {
          try {
            await firestore
                .collection(AppConstants.studentsCollection)
                .doc(uid)
                .update({'deviceId': deviceId});
          } catch (error, stack) {
            developer.log(
              'Device ID update failed: $error',
              name: 'FirebaseAuth',
              error: error,
              stackTrace: stack,
            );
          }
        });
      }

      return authUser;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<AuthUser> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String department,
    UserRole role = UserRole.student,
    required String deviceId,
    String roleId = '',
  }) async {
    final auth = _requireAuth();
    final firestore = _requireFirestore();
    final catalog = _requireCatalog();
    final trimmedName = fullName.trim();
    final trimmedEmail = email.trim();
    final trimmedDepartment = department.trim();
    final trimmedRoleId = roleId.trim();

    if (trimmedName.isEmpty) {
      throw const AppException('Full name is required.', code: 'invalid_name');
    }
    if (trimmedDepartment.isEmpty ||
        !PresetDepartments.all.contains(trimmedDepartment)) {
      throw const AppException(
        'Select a valid department.',
        code: 'invalid_department',
      );
    }
    if (role != UserRole.student && role != UserRole.admin) {
      throw const AppException(
        'Registration role must be Student or Admin.',
        code: 'invalid_role',
      );
    }

    final existingUser = await firestore
        .collection(AppConstants.usersCollection)
        .where('email', isEqualTo: trimmedEmail)
        .limit(1)
        .get();
    if (existingUser.docs.isNotEmpty) {
      throw const AppException(
        'This email is already registered.',
        code: 'duplicate_email',
      );
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: password.trim(),
      );
      final uid = cred.user!.uid;
      final now = DateTime.now();

      final userModel = UserModel(
        id: uid,
        name: trimmedName,
        email: trimmedEmail,
        department: trimmedDepartment,
        role: role,
        roleId: trimmedRoleId,
        createdAt: now,
      );

      final batch = firestore.batch();
      batch.set(
        firestore.collection(AppConstants.usersCollection).doc(uid),
        userModel.toFirestore(),
      );

      if (role == UserRole.admin) {
        batch
            .set(firestore.collection(AppConstants.adminsCollection).doc(uid), {
              'name': trimmedName,
              'email': trimmedEmail,
              'department': trimmedDepartment,
              'role': role.name,
              'roleId': trimmedRoleId,
            });
      } else {
        final departmentId = await catalog.ensureDepartmentByName(
          trimmedDepartment,
        );
        final student = StudentModel(
          id: uid,
          name: trimmedName,
          studentId: trimmedRoleId.isNotEmpty
              ? trimmedRoleId
              : _studentIdFromUid(uid),
          email: trimmedEmail,
          departmentId: departmentId,
          courseIds: const [],
          deviceId: deviceId,
        );
        batch.set(
          firestore.collection(AppConstants.studentsCollection).doc(uid),
          {...student.toFirestore(), 'role': UserRole.student.name},
        );
      }

      await batch.commit();

      final authUser = AuthUser(
        uid: uid,
        email: trimmedEmail,
        role: role,
        name: trimmedName,
        department: trimmedDepartment,
      );
      await _persistUserForOffline(authUser);
      return authUser;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<AuthUser> registerStudent({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String departmentName,
    required List<String> courseIds,
    required String deviceId,
  }) async {
    final auth = _requireAuth();
    final firestore = _requireFirestore();
    final catalog = _requireCatalog();

    final taken = await firestore
        .collection(AppConstants.studentsCollection)
        .where('studentId', isEqualTo: studentId.trim())
        .limit(1)
        .get();
    if (taken.docs.isNotEmpty) {
      throw const AppException(
        'This Student ID is already registered.',
        code: 'duplicate_student_id',
      );
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user!.uid;
      final departmentId = await catalog.ensureDepartmentByName(departmentName);

      final student = StudentModel(
        id: uid,
        name: fullName.trim(),
        studentId: studentId.trim(),
        email: email.trim(),
        departmentId: departmentId,
        courseIds: courseIds,
        deviceId: deviceId,
      );

      final batch = firestore.batch();
      batch.set(
        firestore.collection(AppConstants.usersCollection).doc(uid),
        UserModel(
          id: uid,
          name: fullName.trim(),
          email: email.trim(),
          department: departmentName,
          role: UserRole.student,
          roleId: studentId.trim(),
          createdAt: DateTime.now(),
        ).toFirestore(),
      );
      batch.set(
        firestore.collection(AppConstants.studentsCollection).doc(uid),
        {...student.toFirestore(), 'role': UserRole.student.name},
      );
      await batch.commit();

      final authUser = AuthUser(
        uid: uid,
        email: email.trim(),
        role: UserRole.student,
        name: fullName.trim(),
        department: departmentName,
      );
      await _persistUserForOffline(authUser);
      return authUser;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<AuthUser> registerLecturer({
    required String fullName,
    required String lecturerId,
    required String email,
    required String password,
    required String departmentName,
    required List<String> courseIds,
  }) async {
    final auth = _requireAuth();
    final firestore = _requireFirestore();
    final catalog = _requireCatalog();

    final taken = await firestore
        .collection(AppConstants.lecturersCollection)
        .where('lecturerId', isEqualTo: lecturerId.trim())
        .limit(1)
        .get();
    if (taken.docs.isNotEmpty) {
      throw const AppException(
        'This Lecturer ID is already registered.',
        code: 'duplicate_lecturer_id',
      );
    }

    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user!.uid;
      final departmentId = await catalog.ensureDepartmentByName(departmentName);

      final lecturer = LecturerModel(
        id: uid,
        name: fullName.trim(),
        lecturerId: lecturerId.trim(),
        email: email.trim(),
        departmentId: departmentId,
        courseIds: courseIds,
      );

      final batch = firestore.batch();
      batch.set(
        firestore.collection(AppConstants.usersCollection).doc(uid),
        UserModel(
          id: uid,
          name: fullName.trim(),
          email: email.trim(),
          department: departmentName,
          role: UserRole.lecturer,
          roleId: lecturerId.trim(),
          createdAt: DateTime.now(),
        ).toFirestore(),
      );
      batch.set(
        firestore.collection(AppConstants.lecturersCollection).doc(uid),
        {...lecturer.toFirestore(), 'role': UserRole.lecturer.name},
      );
      await batch.commit();

      final authUser = AuthUser(
        uid: uid,
        email: email.trim(),
        role: UserRole.lecturer,
        name: fullName.trim(),
        department: departmentName,
      );
      await _persistUserForOffline(authUser);
      return authUser;
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      final uid = _auth?.currentUser?.uid;
      SessionGuard.stop();

      if (uid != null) {
        final prefs = await SharedPreferences.getInstance();
        final localDeviceId = prefs.getString('_sid') ?? '';

        // Only the backend may clear active session fields. It verifies that
        // this device is still the active one before releasing the binding.
        if (localDeviceId.isNotEmpty) {
          try {
            await _functions
                ?.httpsCallable(
                  'releaseSession',
                  options: HttpsCallableOptions(
                    timeout: const Duration(seconds: 10),
                  ),
                )
                .call<void>({'deviceId': localDeviceId});
          } catch (e) {
            developer.log(
              'Failed to clear device binding on logout: $e',
              name: 'FirebaseAuth',
            );
          }
        }

        await prefs.remove('_sid');
        await prefs.remove('_stk');
      }

      await SessionCacheService.clearSession();
      await _auth?.signOut();
    } catch (e) {
      developer.log('Logout error (non-critical): $e', name: 'FirebaseAuth');
      await SessionCacheService.clearSession();
      await _auth?.signOut();
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _requireAuth().sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AppException(_mapAuthError(e), code: e.code);
    }
  }

  @override
  Future<UserRole> resolveRole(String uid) async {
    final profile = await _getUserProfile(uid);
    if (profile != null) return profile.role;

    final firestore = _firestore;
    if (firestore == null) {
      final local = await _localUserDataSource.getUserById(uid);
      return local?.role ?? UserRole.student;
    }

    final admin = await firestore
        .collection(AppConstants.adminsCollection)
        .doc(uid)
        .get();
    if (admin.exists) return UserRole.admin;

    final lecturer = await firestore
        .collection(AppConstants.lecturersCollection)
        .doc(uid)
        .get();
    if (lecturer.exists) return UserRole.lecturer;

    return UserRole.student;
  }

  bool _areSameUser(AuthUser? a, AuthUser? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;
    return a.sameIdentity(b);
  }

  Future<AuthUser?> _loadCachedAuthUser() async {
    final session = await SessionCacheService.getCachedSession();
    if (session == null) return null;

    final local = await _localUserDataSource.getUserById(session.uid);
    if (local == null) return session;

    return AuthUser(
      uid: local.id,
      email: local.email,
      role: local.role,
      name: local.name.isEmpty ? session.name : local.name,
      department: local.department.isEmpty
          ? session.department
          : local.department,
    );
  }

  Future<void> _persistUserForOffline(AuthUser authUser) async {
    try {
      await SessionCacheService.cacheSession(user: authUser);
      final existing = await _localUserDataSource.getUserById(authUser.uid);
      final appUser = AppUser(
        id: authUser.uid,
        name: authUser.name ?? existing?.name ?? '',
        email: authUser.email,
        department: authUser.department ?? existing?.department ?? '',
        role: authUser.role,
        roleId: existing?.roleId ?? authUser.uid,
        createdAt: existing?.createdAt ?? DateTime.now(),
      );
      await _localUserDataSource.saveUser(appUser);
      developer.log(
        'Persisted offline session and local user for ${authUser.uid}',
        name: 'FirebaseAuth',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to persist offline user for ${authUser.uid}: $error',
        name: 'FirebaseAuth',
        error: error,
        stackTrace: stack,
      );
    }
  }

  Future<UserModel?> _getUserProfile(String uid) async {
    final firestore = _firestore;
    if (firestore == null) return null;

    final doc = await firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  FirebaseAuth _requireAuth() {
    final auth = _auth;
    if (auth == null) {
      throw const AppException(
        'Firebase Authentication is unavailable while offline.',
        code: 'firebase_unavailable',
      );
    }
    return auth;
  }

  FirebaseFirestore _requireFirestore() {
    final firestore = _firestore;
    if (firestore == null) {
      throw const AppException(
        'Firebase data services are unavailable while offline.',
        code: 'firebase_unavailable',
      );
    }
    return firestore;
  }

  CatalogRepository _requireCatalog() {
    final catalog = _catalog;
    if (catalog == null) {
      throw const AppException(
        'Course catalog is unavailable while offline.',
        code: 'firebase_unavailable',
      );
    }
    return catalog;
  }

  String _studentIdFromUid(String uid) {
    return uid.length >= 8
        ? uid.substring(0, 8).toUpperCase()
        : uid.toUpperCase();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'weak-password':
        return 'Password is too weak.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
