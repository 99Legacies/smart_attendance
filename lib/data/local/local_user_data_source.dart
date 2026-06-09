import 'dart:developer' as developer;

import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/domain/entities/app_user.dart';

/// Local data source for users using Hive
class LocalUserDataSource {
  /// Get user by ID from local database
  Future<AppUser?> getUserById(String userId) async {
    try {
      final hiveUser = LocalDatabaseService.usersBox.get(userId);
      if (hiveUser != null) {
        developer.log('Found user in local DB: $userId', name: 'LocalData');
        return _hiveToAppUser(hiveUser);
      }
      return null;
    } catch (error, stack) {
      developer.log(
        'Failed to get user from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Get all cached users
  Future<List<AppUser>> getAllUsers() async {
    try {
      return LocalDatabaseService.usersBox.values.map(_hiveToAppUser).toList();
    } catch (error, stack) {
      developer.log(
        'Failed to get all users from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
      return [];
    }
  }

  /// Save user to local database
  Future<void> saveUser(AppUser user) async {
    try {
      final hiveUser = _appUserToHive(user);
      await LocalDatabaseService.usersBox.put(user.id, hiveUser);
      developer.log('Saved user to local DB: ${user.id}', name: 'LocalData');
    } catch (error, stack) {
      developer.log(
        'Failed to save user to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Save multiple users
  Future<void> saveUsers(List<AppUser> users) async {
    try {
      final map = {for (final user in users) user.id: _appUserToHive(user)};
      await LocalDatabaseService.usersBox.putAll(map);
      developer.log(
        'Saved ${users.length} users to local DB',
        name: 'LocalData',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to save users to local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Delete user from local database
  Future<void> deleteUser(String userId) async {
    try {
      await LocalDatabaseService.usersBox.delete(userId);
      developer.log('Deleted user from local DB: $userId', name: 'LocalData');
    } catch (error, stack) {
      developer.log(
        'Failed to delete user from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Clear all users
  Future<void> clearUsers() async {
    try {
      await LocalDatabaseService.usersBox.clear();
      developer.log('Cleared all users from local DB', name: 'LocalData');
    } catch (error, stack) {
      developer.log(
        'Failed to clear users from local DB: $error',
        name: 'LocalData',
        error: error,
        stackTrace: stack,
      );
    }
  }

  static AppUser _hiveToAppUser(HiveAppUser hive) {
    return AppUser(
      id: hive.id,
      name: hive.name,
      email: hive.email,
      department: hive.department,
      role: hive.role,
      roleId: hive.roleId,
      createdAt: hive.createdAt ?? DateTime.now(),
    );
  }

  static HiveAppUser _appUserToHive(AppUser user) {
    return HiveAppUser(
      id: user.id,
      name: user.name,
      email: user.email,
      department: user.department,
      role: user.role,
      roleId: user.roleId,
      createdAt: user.createdAt,
      syncedAt: DateTime.now(),
    );
  }
}
