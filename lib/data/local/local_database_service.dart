import 'dart:developer' as developer;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:smart_attendance/data/local/hive_models.dart';

/// Service for managing Hive local database
/// Initializes and provides access to all Hive boxes
class LocalDatabaseService {
  static late Box<HiveAppUser> _usersBox;
  static late Box<HiveStudent> _studentsBox;
  static late Box<HiveLecturer> _lecturersBox;
  static late Box<HiveCourse> _coursesBox;
  static late Box<HiveDepartment> _departmentsBox;
  static late Box<HiveAttendanceSession> _sessionsBox;
  static late Box<HiveAttendanceRecord> _recordsBox;
  static late Box<HiveAppNotification> _notificationsBox;
  static late Box<HiveAbsenceRequest> _absenceRequestsBox;
  static late Box<HiveCourseProposal> _courseProposalsBox;
  static late Box<HiveOfflineQueueItem> _offlineQueueBox;
  static late Box<HiveEnrollment> _enrollmentsBox;
  static late Box<HiveUserProfile> _userProfilesBox;
  static late Box<HiveSessionCache> _sessionCacheBox;
  static late Box<String> _preferencesBox;

  static bool _initialized = false;

  /// Initialize Hive and register adapters
  /// Must be called before app startup
  static Future<void> initialize() async {
    if (_initialized) {
      developer.log(
        'LocalDatabaseService already initialized',
        name: 'LocalDB',
      );
      return;
    }

    try {
      developer.log('Initializing Hive database...', name: 'LocalDB');

      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters
      Hive.registerAdapter(HiveAppUserAdapter());
      Hive.registerAdapter(HiveStudentAdapter());
      Hive.registerAdapter(HiveLecturerAdapter());
      Hive.registerAdapter(HiveCourseAdapter());
      Hive.registerAdapter(HiveDepartmentAdapter());
      Hive.registerAdapter(HiveAttendanceSessionAdapter());
      Hive.registerAdapter(HiveAttendanceRecordAdapter());
      Hive.registerAdapter(HiveAppNotificationAdapter());
      Hive.registerAdapter(HiveAbsenceRequestAdapter());
      Hive.registerAdapter(HiveCourseProposalAdapter());
      Hive.registerAdapter(HiveOfflineQueueItemAdapter());
      Hive.registerAdapter(HiveSessionCacheAdapter());
      Hive.registerAdapter(HiveEnrollmentAdapter());
      Hive.registerAdapter(HiveUserProfileAdapter());

      // Open boxes
      _usersBox = await Hive.openBox<HiveAppUser>('users');
      _studentsBox = await Hive.openBox<HiveStudent>('students');
      _lecturersBox = await Hive.openBox<HiveLecturer>('lecturers');
      _coursesBox = await Hive.openBox<HiveCourse>('courses');
      _departmentsBox = await Hive.openBox<HiveDepartment>('departments');
      _sessionsBox = await Hive.openBox<HiveAttendanceSession>('sessions');
      _recordsBox = await Hive.openBox<HiveAttendanceRecord>('records');
      _notificationsBox = await Hive.openBox<HiveAppNotification>(
        'notifications',
      );
      _absenceRequestsBox = await Hive.openBox<HiveAbsenceRequest>(
        'absence_requests',
      );
      _courseProposalsBox = await Hive.openBox<HiveCourseProposal>(
        'course_proposals',
      );
      _offlineQueueBox = await Hive.openBox<HiveOfflineQueueItem>(
        'offline_queue',
      );
      _enrollmentsBox = await Hive.openBox<HiveEnrollment>('enrollments');
      _userProfilesBox = await Hive.openBox<HiveUserProfile>('user_profiles');
      _sessionCacheBox = await Hive.openBox<HiveSessionCache>('session_cache');
      _preferencesBox = await Hive.openBox<String>('preferences');

      _initialized = true;
      developer.log('Hive database initialized successfully', name: 'LocalDB');
    } catch (error, stack) {
      developer.log(
        'Failed to initialize Hive: $error',
        name: 'LocalDB',
        error: error,
        stackTrace: stack,
      );
      rethrow;
    }
  }

  /// Get users box
  static Box<HiveAppUser> get usersBox {
    _checkInitialized();
    return _usersBox;
  }

  /// Get students box
  static Box<HiveStudent> get studentsBox {
    _checkInitialized();
    return _studentsBox;
  }

  /// Get lecturers box
  static Box<HiveLecturer> get lecturersBox {
    _checkInitialized();
    return _lecturersBox;
  }

  /// Get courses box
  static Box<HiveCourse> get coursesBox {
    _checkInitialized();
    return _coursesBox;
  }

  /// Get departments box
  static Box<HiveDepartment> get departmentsBox {
    _checkInitialized();
    return _departmentsBox;
  }

  /// Get attendance sessions box
  static Box<HiveAttendanceSession> get sessionsBox {
    _checkInitialized();
    return _sessionsBox;
  }

  /// Get attendance records box
  static Box<HiveAttendanceRecord> get recordsBox {
    _checkInitialized();
    return _recordsBox;
  }

  /// Get notifications box
  static Box<HiveAppNotification> get notificationsBox {
    _checkInitialized();
    return _notificationsBox;
  }

  /// Get absence requests box
  static Box<HiveAbsenceRequest> get absenceRequestsBox {
    _checkInitialized();
    return _absenceRequestsBox;
  }

  /// Get course proposals box
  static Box<HiveCourseProposal> get courseProposalsBox {
    _checkInitialized();
    return _courseProposalsBox;
  }

  /// Get offline queue box
  static Box<HiveOfflineQueueItem> get offlineQueueBox {
    _checkInitialized();
    return _offlineQueueBox;
  }

  /// Get session cache box
  static Box<HiveSessionCache> get sessionCacheBox {
    _checkInitialized();
    return _sessionCacheBox;
  }

  /// Get preferences box
  static Box<String> get preferencesBox {
    _checkInitialized();
    return _preferencesBox;
  }

  static void _checkInitialized() {
    if (!_initialized) {
      throw StateError(
        'LocalDatabaseService not initialized. Call initialize() first.',
      );
    }
  }

  /// Clear all data (for testing or logout)
  static Future<void> clearAll() async {
    _checkInitialized();
    developer.log('Clearing all local data...', name: 'LocalDB');
    await Future.wait([
      _usersBox.clear(),
      _studentsBox.clear(),
      _lecturersBox.clear(),
      _coursesBox.clear(),
      _departmentsBox.clear(),
      _sessionsBox.clear(),
      _recordsBox.clear(),
      _notificationsBox.clear(),
      _absenceRequestsBox.clear(),
      _courseProposalsBox.clear(),
      _preferencesBox.clear(),
    ]);
    developer.log('All local data cleared', name: 'LocalDB');
  }

  /// Clear offline queue (after successful sync)
  static Future<void> clearOfflineQueue() async {
    _checkInitialized();
    await _offlineQueueBox.clear();
  }

  /// Get database stats for debugging
  static Map<String, int> getStats() {
    _checkInitialized();
    return {
      'users': _usersBox.length,
      'students': _studentsBox.length,
      'lecturers': _lecturersBox.length,
      'courses': _coursesBox.length,
      'departments': _departmentsBox.length,
      'sessions': _sessionsBox.length,
      'records': _recordsBox.length,
      'notifications': _notificationsBox.length,
      'absenceRequests': _absenceRequestsBox.length,
      'courseProposals': _courseProposalsBox.length,
      'offlineQueue': _offlineQueueBox.length,
      'enrollments': _enrollmentsBox.length,
    };
  }

  /// Get enrollments box
  static Box<HiveEnrollment> get enrollmentsBox {
    _checkInitialized();
    return _enrollmentsBox;
  }

  /// Get user profiles box
  static Box<HiveUserProfile> get userProfilesBox {
    _checkInitialized();
    return _userProfilesBox;
  }
}
