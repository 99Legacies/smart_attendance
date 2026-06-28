import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/widgets/gradient_scaffold.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/navigation/role_navigation_config.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_navigation.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_scaffold.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_absence_inbox_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_create_session_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_home_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_profile_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_propose_course_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_sessions_screen.dart';
import 'package:smart_attendance/core/navigation/app_navigation.dart';
import 'package:smart_attendance/presentation/screens/shared/notifications_screen.dart';
import 'package:smart_attendance/presentation/widgets/concise_role_drawer.dart';
import 'package:smart_attendance/presentation/widgets/notifications_panel.dart';
import 'package:smart_attendance/data/local/background_sync_service.dart';

class LecturerShellScreen extends ConsumerStatefulWidget {
  const LecturerShellScreen({super.key});

  @override
  ConsumerState<LecturerShellScreen> createState() =>
      _LecturerShellScreenState();
}

class _LecturerShellScreenState extends ConsumerState<LecturerShellScreen> {
  final _navigation = RoleShellNavigation(logTag: 'LecturerShell');
  final _shellKey = GlobalKey<RoleShellScaffoldState>();
  bool _syncStartQueued = false;

  void _openDrawerScreen(BuildContext context, Widget screen, String title) {
    AppNavigation.pushSecondary(context, title: title, body: screen);
  }

  void _startBackgroundSyncOnce() {
    if (_syncStartQueued) return;
    _syncStartQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final svc = BackgroundSyncService();
      if (!svc.isRunning) svc.start();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const GradientScaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (_, _) => const GradientScaffold(
        body: Center(child: Text('Unable to load profile')),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.lecturer) {
          _navigation.resolve(role: UserRole.lecturer, navItems: const []);
          return const GradientScaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final uid = user.uid;
        final name = user.name ?? 'Lecturer';

        void openSession() => _openDrawerScreen(
          context,
          LecturerCreateSessionScreen(lecturerId: uid),
          'New session',
        );
        void openSessions() => _openDrawerScreen(
          context,
          LecturerSessionsScreen(lecturerId: uid),
          'Sessions',
        );
        void openAbsences() => _openDrawerScreen(
          context,
          LecturerAbsenceInboxScreen(lecturerId: uid),
          'Absence requests',
        );
        void openPropose() => _openDrawerScreen(
          context,
          LecturerProposeCourseScreen(lecturerId: uid, lecturerName: name),
          'Propose course',
        );
        void openProfile() => _openDrawerScreen(
          context,
          LecturerProfileScreen(lecturerId: uid),
          'Profile',
        );

        final drawerItems = [
          DrawerMenuItem(
            icon: Icons.person_outline,
            label: 'My profile',
            onTap: (_) => openProfile(),
          ),
          DrawerMenuItem(
            icon: Icons.add_circle_outline,
            label: 'New session',
            onTap: (_) => openSession(),
          ),
          DrawerMenuItem(
            icon: Icons.list_alt,
            label: 'Session history',
            onTap: (_) => openSessions(),
          ),
          DrawerMenuItem(
            icon: Icons.inbox_outlined,
            label: 'Absence requests',
            onTap: (_) => openAbsences(),
          ),
          DrawerMenuItem(
            icon: Icons.post_add_outlined,
            label: 'Propose course',
            onTap: (_) => openPropose(),
          ),
        ];

        final navItems = RoleNavigationConfig.lecturer(
          lecturerId: uid,
          homePage: LecturerHomeScreen(
            lecturerId: uid,
            lecturerName: name,
            onNewSession: openSession,
            onSessions: openSessions,
            onAbsences: openAbsences,
            onProposeCourse: openPropose,
          ),
        );
        RoleNavigationConfig.assertValidItemCount(navItems, 'Lecturer');

        _startBackgroundSyncOnce();

        return RoleShellScaffold(
          key: _shellKey,
          role: UserRole.lecturer,
          navigation: _navigation,
          navItems: navItems,
          drawer: ConciseRoleDrawer(
            role: UserRole.lecturer,
            userName: name,
            userEmail: user.email,
            userId: uid,
            showReportExport: true,
            menuItems: drawerItems,
          ),
          appBarActions: [
            NotificationBadgeIcon(
              userId: uid,
              onTap: () => AppNavigation.pushRoute(
                context,
                NotificationsScreen(userId: uid),
              ),
            ),
          ],
        );
      },
    );
  }
}
