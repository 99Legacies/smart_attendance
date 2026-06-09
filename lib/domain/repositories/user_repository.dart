import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';

abstract class UserRepository {
  Stream<List<AppUser>> watchUsers();

  Stream<AppUser?> watchUser(String uid);

  Future<AppUser?> getUser(String uid);

  Future<void> updateUserRole({
    required String uid,
    required UserRole role,
  });

  Future<void> deleteUser(String uid);

  Future<void> updateUserProfile({
    required String uid,
    required String name,
    required String department,
  });
}
