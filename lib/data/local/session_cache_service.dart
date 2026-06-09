import 'dart:developer' as developer;

import 'package:smart_attendance/data/local/hive_models.dart';
import 'package:smart_attendance/data/local/local_database_service.dart';
import 'package:smart_attendance/domain/repositories/auth_repository.dart';

/// Manages cached session data for offline login support
/// Allows users to log in with cached credentials even when offline
class SessionCacheService {
  static const String _sessionCacheKey = 'current_session';
  static const Duration _defaultCacheDuration = Duration(days: 7);

  /// Cache current session after login
  static Future<void> cacheSession({
    required AuthUser user,
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    try {
      final now = DateTime.now();
      final session = HiveSessionCache(
        uid: user.uid,
        email: user.email,
        role: user.role,
        name: user.name,
        department: user.department,
        cachedAt: now,
        expiresAt: now.add(cacheDuration),
      );

      // Store in session cache box
      await LocalDatabaseService.sessionCacheBox.put(_sessionCacheKey, session);

      developer.log(
        'Cached session for user: ${user.email} '
        '(expires at ${session.expiresAt})',
        name: 'SessionCache',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to cache session: $error',
        name: 'SessionCache',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Get cached session (if valid)
  static Future<AuthUser?> getCachedSession() async {
    try {
      final cached = LocalDatabaseService.sessionCacheBox.get(_sessionCacheKey);

      if (cached == null) {
        developer.log('No cached session found', name: 'SessionCache');
        return null;
      }

      if (cached.isExpired) {
        developer.log(
          'Cached session expired at ${cached.expiresAt}',
          name: 'SessionCache',
        );
        await clearSession();
        return null;
      }

      developer.log(
        'Retrieved valid cached session for: ${cached.email}',
        name: 'SessionCache',
      );

      return AuthUser(
        uid: cached.uid,
        email: cached.email,
        role: cached.role,
        name: cached.name,
        department: cached.department,
      );
    } catch (error, stack) {
      developer.log(
        'Failed to get cached session: $error',
        name: 'SessionCache',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }

  /// Check if valid session is cached
  static Future<bool> hasValidSession() async {
    try {
      final cached = LocalDatabaseService.sessionCacheBox.get(_sessionCacheKey);
      return cached != null && !cached.isExpired;
    } catch (error, stack) {
      developer.log(
        'Failed to check cached session: $error',
        name: 'SessionCache',
        error: error,
        stackTrace: stack,
      );
      return false;
    }
  }

  /// Clear cached session
  static Future<void> clearSession() async {
    try {
      await LocalDatabaseService.sessionCacheBox.delete(_sessionCacheKey);
      developer.log('Cleared cached session', name: 'SessionCache');
    } catch (error, stack) {
      developer.log(
        'Failed to clear cached session: $error',
        name: 'SessionCache',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Refresh session expiry time
  static Future<void> refreshSession({
    Duration cacheDuration = _defaultCacheDuration,
  }) async {
    try {
      final cached = LocalDatabaseService.sessionCacheBox.get(_sessionCacheKey);

      if (cached == null) {
        developer.log('No session to refresh', name: 'SessionCache');
        return;
      }

      final now = DateTime.now();
      final refreshed = HiveSessionCache(
        uid: cached.uid,
        email: cached.email,
        role: cached.role,
        name: cached.name,
        department: cached.department,
        cachedAt: now,
        expiresAt: now.add(cacheDuration),
      );

      await LocalDatabaseService.sessionCacheBox.put(
        _sessionCacheKey,
        refreshed,
      );

      developer.log(
        'Refreshed session cache (new expiry: ${refreshed.expiresAt})',
        name: 'SessionCache',
      );
    } catch (error, stack) {
      developer.log(
        'Failed to refresh session: $error',
        name: 'SessionCache',
        error: error,
        stackTrace: stack,
      );
    }
  }

  /// Get session info (for UI display)
  static Future<Map<String, dynamic>?> getSessionInfo() async {
    try {
      final cached = LocalDatabaseService.sessionCacheBox.get(_sessionCacheKey);

      if (cached == null) return null;

      return {
        'uid': cached.uid,
        'email': cached.email,
        'role': cached.role,
        'name': cached.name,
        'department': cached.department,
        'cachedAt': cached.cachedAt,
        'expiresAt': cached.expiresAt,
        'isExpired': cached.isExpired,
        'timeRemaining': cached.expiresAt.difference(DateTime.now()),
      };
    } catch (error, stack) {
      developer.log(
        'Failed to get session info: $error',
        name: 'SessionCache',
        error: error,
        stackTrace: stack,
      );
      return null;
    }
  }
}
