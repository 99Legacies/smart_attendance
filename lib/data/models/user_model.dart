import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';

class UserModel extends AppUser {
  const UserModel({
    required super.id,
    required super.name,
    required super.email,
    required super.department,
    required super.role,
    required super.roleId,
    required super.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data()! as Map<String, dynamic>;
    final createdAtRaw = data['createdAt'];
    DateTime createdAt;
    if (createdAtRaw is Timestamp) {
      createdAt = createdAtRaw.toDate();
    } else if (createdAtRaw is DateTime) {
      createdAt = createdAtRaw;
    } else {
      createdAt = DateTime.now();
    }

    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      department: data['department'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'student'),
      roleId: data['roleId'] as String? ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'email': email,
        'department': department,
        'role': role.name,
        'roleId': roleId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
