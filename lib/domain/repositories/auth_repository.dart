import 'package:smart_attendance/domain/entities/user_role.dart';

abstract class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<AuthUser> signIn({
    required String email,
    required String password,
    required String deviceId,
    bool enforceSingleDevice = false,
  });

  /// Unified registration: creates Firebase Auth user + Firestore profile.
  /// User is automatically signed in after registration.
  Future<AuthUser> registerUser({
    required String fullName,
    required String email,
    required String password,
    required String department,
    UserRole role = UserRole.student,
    required String deviceId,
    String roleId = '',
  });

  Future<AuthUser> registerStudent({
    required String fullName,
    required String studentId,
    required String email,
    required String password,
    required String departmentName,
    required List<String> courseIds,
    required String deviceId,
  });

  Future<AuthUser> registerLecturer({
    required String fullName,
    required String lecturerId,
    required String email,
    required String password,
    required String departmentName,
    required List<String> courseIds,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserRole> resolveRole(String uid);
}

class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.role,
    this.name,
    this.department,
  });

  final String uid;
  final String email;
  final UserRole role;
  final String? name;
  final String? department;
}
