import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';

import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/providers/notification_preferences_provider.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/providers/user_profile_image_provider.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPreferencesProvider);
    final notifier = ref.read(notificationPreferencesProvider.notifier);
    final auth = ref.watch(authStateProvider);
    final imageRepo = ref.read(userProfileImageRepositoryProvider);

    final enabledCount = [
      prefs.missedSessionAlerts,
      prefs.attendanceConfirmationAlerts,
      prefs.absenceUpdateAlerts,
      prefs.upcomingSessionReminders,
      prefs.sessionChangeAlerts,
      prefs.announcementsAlerts,
    ].where((v) => v).length;

    return Column(
      children: [
        // Header with gradient
        Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withAlpha(200),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                transform: const GradientRotation(math.pi / 8),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((0.05 * 255).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  auth.when(
                    data: (u) {
                      final path = u == null
                          ? null
                          : imageRepo.getBestImagePath(u.uid);
                      return CircleAvatar(
                        radius: 34,
                        backgroundColor: Colors.white24,
                        backgroundImage: path != null
                            ? FileImage(File(path))
                            : null,
                        child: path == null
                            ? Icon(
                                Icons.notifications_active,
                                size: 32,
                                color: Colors.white,
                              )
                            : null,
                      );
                    },
                    loading: () => const CircleAvatar(radius: 34),
                    error: (e, st) => const CircleAvatar(radius: 34),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alert Settings',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Control which alerts you receive. Critical alerts are enabled by default.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$enabledCount enabled',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: AppTheme.screenPadding,
              children: [
                const SizedBox(height: 8),
                _sectionCard(
                  context,
                  title: 'Attendance',
                  children: [
                    _toggleItem(
                      context,
                      icon: Icons.event_busy,
                      title: 'Missed session alerts',
                      description:
                          'Notify me when I miss a session without marking attendance.',
                      value: prefs.missedSessionAlerts,
                      onChanged: notifier.setMissedSessionAlerts,
                    ),
                    const Divider(height: 1),
                    _toggleItem(
                      context,
                      icon: Icons.check_circle,
                      title: 'Attendance confirmation alerts',
                      description:
                          'Notify me when my attendance is successfully recorded.',
                      value: prefs.attendanceConfirmationAlerts,
                      onChanged: notifier.setAttendanceConfirmationAlerts,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  context,
                  title: 'Requests',
                  children: [
                    _toggleItem(
                      context,
                      icon: Icons.request_page,
                      title: 'Absence request updates',
                      description:
                          'Get updates when your absence requests are approved or rejected.',
                      value: prefs.absenceUpdateAlerts,
                      onChanged: notifier.setAbsenceUpdateAlerts,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  context,
                  title: 'Schedule',
                  children: [
                    _toggleItem(
                      context,
                      icon: Icons.alarm,
                      title: 'Upcoming session reminders',
                      description:
                          'Receive reminders before your next scheduled session.',
                      value: prefs.upcomingSessionReminders,
                      onChanged: notifier.setUpcomingSessionReminders,
                    ),
                    const Divider(height: 1),
                    _toggleItem(
                      context,
                      icon: Icons.swap_horiz,
                      title: 'Session change alerts',
                      description:
                          'Notify me of changes to session time or venue.',
                      value: prefs.sessionChangeAlerts,
                      onChanged: notifier.setSessionChangeAlerts,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  context,
                  title: 'General',
                  children: [
                    _toggleItem(
                      context,
                      icon: Icons.announcement,
                      title: 'Announcements',
                      description:
                          'Receive general announcements and campus updates.',
                      value: prefs.announcementsAlerts,
                      onChanged: notifier.setAnnouncementsAlerts,
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _toggleItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                key: ValueKey<bool>(value),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
