import 'package:smart_attendance/domain/entities/user_role.dart';

/// Dashboard routes resolved from Firestore user role.
class RoleRoutes {
  RoleRoutes._();

  static String homeFor(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return '/admin-dashboard';
      case UserRole.lecturer:
        return '/lecturer';
      case UserRole.student:
        return '/student-dashboard';
    }
  }
}
