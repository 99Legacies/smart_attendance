import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/widgets/gradient_scaffold.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/navigation/role_navigation_config.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_navigation.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_scaffold.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/shared/notifications_screen.dart';
import 'package:smart_attendance/presentation/screens/student/student_home_screen.dart';
import 'package:smart_attendance/presentation/screens/student/student_profile_screen.dart';
import 'package:smart_attendance/presentation/screens/student/my_courses_screen.dart';
import 'package:smart_attendance/core/navigation/app_navigation.dart';
import 'package:smart_attendance/presentation/widgets/concise_role_drawer.dart';
import 'package:smart_attendance/presentation/widgets/notifications_panel.dart';
import 'package:smart_attendance/data/local/background_sync_service.dart';

class StudentShellScreen extends ConsumerStatefulWidget {
  const StudentShellScreen({super.key});

  @override
  ConsumerState<StudentShellScreen> createState() => _StudentShellScreenState();
}

class _StudentShellScreenState extends ConsumerState<StudentShellScreen> {
  final _navigation = RoleShellNavigation(logTag: 'StudentShell');
  final _shellKey = GlobalKey<RoleShellScaffoldState>();
  bool _syncStartQueued = false;

  void _openDrawerScreen(BuildContext context, Widget screen, String title) {
    AppNavigation.pushSecondary(context, title: title, body: screen);
  }

  void _startBackgroundSyncOnce() {
    if (_syncStartQueued) return;
    _syncStartQueued = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final svc = BackgroundSyncService();
      if (!svc.isRunning) {
        svc.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    // Resolve UID early so we can stream the name before authAsync settles.
    final uid = authAsync.asData?.value?.uid ?? '';
    final liveName = uid.isNotEmpty
        ? ref.watch(studentLiveNameProvider(uid)).asData?.value
        : null;

    return authAsync.when(
      loading: () => const GradientScaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      ),
      error: (_, _) => const GradientScaffold(
        body: Center(child: Text('Unable to load profile')),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.student) {
          return const GradientScaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        final uid = user.uid;

        void openProfile() => _openDrawerScreen(
          context,
          StudentProfileScreen(studentUid: uid),
          'Profile',
        );

        final navItems = RoleNavigationConfig.student(
          studentUid: uid,
          homePage: StudentHomeScreen(
            studentUid: uid,
            onScan: () => _shellKey.currentState?.navigateToTab(1),
            onHistory: () => _shellKey.currentState?.navigateToTab(2),
            onProfile: openProfile,
            onCourses: () => _openDrawerScreen(
              context,
              MyCoursesScreen(studentUid: uid),
              'My Courses',
            ),
          ),
        );
        RoleNavigationConfig.assertValidItemCount(navItems, 'Student');

        _startBackgroundSyncOnce();

        return RoleShellScaffold(
          key: _shellKey,
          role: UserRole.student,
          navigation: _navigation,
          navItems: navItems,
          drawer: ConciseRoleDrawer(
            role: UserRole.student,
            userName: liveName?.isNotEmpty == true
                ? liveName!
                : (user.name?.isNotEmpty == true ? user.name! : 'Student'),
            userEmail: user.email,
            userId: uid,
            menuItems: [
              DrawerMenuItem(
                icon: Icons.person_outline,
                label: 'Profile & absences',
                onTap: (_) => openProfile(),
              ),
              DrawerMenuItem(
                icon: Icons.school,
                label: 'My Courses',
                onTap: (_) => _openDrawerScreen(
                  context,
                  MyCoursesScreen(studentUid: uid),
                  'My Courses',
                ),
              ),
            ],
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
