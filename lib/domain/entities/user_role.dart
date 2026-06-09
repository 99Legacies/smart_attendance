import 'package:hive/hive.dart';

part 'user_role.g.dart';

@HiveType(typeId: 20)
enum UserRole {
  @HiveField(0)
  admin,
  @HiveField(1)
  lecturer,
  @HiveField(2)
  student;

  String get label {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.lecturer:
        return 'Lecturer';
      case UserRole.student:
        return 'Student';
    }
  }

  static UserRole fromString(String value) {
    return UserRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => UserRole.student,
    );
  }
}
