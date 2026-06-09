/// Application-wide constants (no hardcoded business data).
class AppConstants {
  AppConstants._();

  static const int qrValiditySeconds = 45;
  static const int lateThresholdMinutes = 15;
  static const double defaultLocationRadiusMeters = 100.0;
  static const int minPasswordLength = 8;

  static const String usersCollection = 'users';
  static const String studentsCollection = 'students';
  static const String lecturersCollection = 'lecturers';
  static const String adminsCollection = 'admins';
  static const String coursesCollection = 'courses';
  static const String departmentsCollection = 'departments';
  static const String sessionsCollection = 'attendance_sessions';
  static const String recordsCollection = 'attendance_records';
  static const String absenceRequestsCollection = 'absence_requests';
  static const String securityLogsCollection = 'security_logs';
  static const String settingsCollection = 'settings';
  static const String courseProposalsCollection = 'course_proposals';
  static const String notificationsCollection = 'notifications';
  static const String enrollmentsCollection = 'enrollments';
}
