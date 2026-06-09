import 'package:equatable/equatable.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';

class AppUser extends Equatable {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.role,
    required this.roleId,
    required this.createdAt,
    this.localImagePath,
    this.remoteImageUrl,
  });

  final String id;
  final String name;
  final String email;
  final String department;
  final UserRole role;
  final String roleId;
  final DateTime createdAt;
  final String? localImagePath;
  final String? remoteImageUrl;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    department,
    role,
    roleId,
    createdAt,
    localImagePath,
    remoteImageUrl,
  ];
}
