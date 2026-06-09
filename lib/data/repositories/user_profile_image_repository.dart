import 'dart:developer' as developer;
import 'package:smart_attendance/core/utils/image_utils.dart';
import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';

/// Repository for managing user profile images with offline-first support.
class UserProfileImageRepository {
  /// Update user profile image locally.
  /// Returns the local image path after compression.
  Future<String> updateProfileImageLocally({
    required String userId,
    required String imagePath,
  }) async {
    try {
      // Compress image
      final compressedPath = await ImageUtils.compressAndSave(imagePath);

      // Save profile image info to Hive
      final profile = HiveUserProfile(
        userId: userId,
        localImagePath: compressedPath,
        remoteImageUrl: null,
        localImageUpdatedAt: DateTime.now(),
        pendingSync: true,
        syncedAt: null,
      );

      await LocalDatabaseService.userProfilesBox.put(userId, profile);

      developer.log(
        'Profile image updated locally: $userId → $compressedPath',
        name: 'UserProfileImage',
      );

      return compressedPath;
    } catch (e) {
      developer.log(
        'Failed to update profile image: $e',
        name: 'UserProfileImage',
        error: e,
      );
      rethrow;
    }
  }

  /// Get user profile image info (local or remote).
  /// Prefers local if available, falls back to remote URL.
  HiveUserProfile? getProfileImage(String userId) {
    return LocalDatabaseService.userProfilesBox.get(userId);
  }

  /// Mark profile image as synced with remote.
  Future<void> markImageSynced({
    required String userId,
    required String? remoteImageUrl,
  }) async {
    try {
      final profile = LocalDatabaseService.userProfilesBox.get(userId);
      if (profile == null) return;

      final updated = HiveUserProfile(
        userId: profile.userId,
        localImagePath: profile.localImagePath,
        remoteImageUrl: remoteImageUrl,
        localImageUpdatedAt: profile.localImageUpdatedAt,
        pendingSync: false,
        syncedAt: DateTime.now(),
      );

      await LocalDatabaseService.userProfilesBox.put(userId, updated);

      developer.log(
        'Profile image marked as synced: $userId',
        name: 'UserProfileImage',
      );
    } catch (e) {
      developer.log(
        'Failed to mark image as synced: $e',
        name: 'UserProfileImage',
        error: e,
      );
    }
  }

  /// Get the best available image path (local preferred, fallback to remote).
  String? getBestImagePath(String userId) {
    final profile = getProfileImage(userId);
    if (profile == null) return null;
    return profile.localImagePath ?? profile.remoteImageUrl;
  }
}
