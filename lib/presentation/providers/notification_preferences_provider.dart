import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      NotificationPreferencesNotifier.new,
    );

class NotificationPreferences {
  const NotificationPreferences({
    this.missedSessionAlerts = true,
    this.attendanceConfirmationAlerts = true,
    this.absenceUpdateAlerts = true,
    this.upcomingSessionReminders = false,
    this.sessionChangeAlerts = false,
    this.announcementsAlerts = false,
  });

  final bool missedSessionAlerts;
  final bool attendanceConfirmationAlerts;
  final bool absenceUpdateAlerts;
  final bool upcomingSessionReminders;
  final bool sessionChangeAlerts;
  final bool announcementsAlerts;

  NotificationPreferences copyWith({
    bool? missedSessionAlerts,
    bool? attendanceConfirmationAlerts,
    bool? absenceUpdateAlerts,
    bool? upcomingSessionReminders,
    bool? sessionChangeAlerts,
    bool? announcementsAlerts,
  }) {
    return NotificationPreferences(
      missedSessionAlerts: missedSessionAlerts ?? this.missedSessionAlerts,
      attendanceConfirmationAlerts:
          attendanceConfirmationAlerts ?? this.attendanceConfirmationAlerts,
      absenceUpdateAlerts: absenceUpdateAlerts ?? this.absenceUpdateAlerts,
      upcomingSessionReminders:
          upcomingSessionReminders ?? this.upcomingSessionReminders,
      sessionChangeAlerts: sessionChangeAlerts ?? this.sessionChangeAlerts,
      announcementsAlerts: announcementsAlerts ?? this.announcementsAlerts,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  static const _missedSessionKey = 'notif_missed_session';
  static const _attendanceConfirmationKey = 'notif_attendance_confirmation';
  static const _absenceUpdateKey = 'notif_absence_update';
  static const _upcomingSessionKey = 'notif_upcoming_session';
  static const _sessionChangeKey = 'notif_session_change';
  static const _announcementsKey = 'notif_announcements';

  @override
  NotificationPreferences build() {
    _load();
    return const NotificationPreferences();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = NotificationPreferences(
      missedSessionAlerts: prefs.getBool(_missedSessionKey) ?? true,
      attendanceConfirmationAlerts:
          prefs.getBool(_attendanceConfirmationKey) ?? true,
      absenceUpdateAlerts: prefs.getBool(_absenceUpdateKey) ?? true,
      upcomingSessionReminders: prefs.getBool(_upcomingSessionKey) ?? false,
      sessionChangeAlerts: prefs.getBool(_sessionChangeKey) ?? false,
      announcementsAlerts: prefs.getBool(_announcementsKey) ?? false,
    );
  }

  Future<void> setMissedSessionAlerts(bool value) async {
    state = state.copyWith(missedSessionAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_missedSessionKey, value);
  }

  Future<void> setAttendanceConfirmationAlerts(bool value) async {
    state = state.copyWith(attendanceConfirmationAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_attendanceConfirmationKey, value);
  }

  Future<void> setAbsenceUpdateAlerts(bool value) async {
    state = state.copyWith(absenceUpdateAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_absenceUpdateKey, value);
  }

  Future<void> setUpcomingSessionReminders(bool value) async {
    state = state.copyWith(upcomingSessionReminders: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_upcomingSessionKey, value);
  }

  Future<void> setSessionChangeAlerts(bool value) async {
    state = state.copyWith(sessionChangeAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sessionChangeKey, value);
  }

  Future<void> setAnnouncementsAlerts(bool value) async {
    state = state.copyWith(announcementsAlerts: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_announcementsKey, value);
  }
}
