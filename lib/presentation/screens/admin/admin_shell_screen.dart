import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/navigation/role_nav_item.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_navigation.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_scaffold.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/providers/theme_provider.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_courses_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_departments_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_students_screen.dart';

/// Legacy admin shell — uses the same safe navigation as [AdminDashboardScreen].
class AdminShellScreen extends ConsumerStatefulWidget {
  const AdminShellScreen({super.key});

  @override
  ConsumerState<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends ConsumerState<AdminShellScreen> {
  final _navigation = RoleShellNavigation(logTag: 'AdminLegacyShell');

  @override
  Widget build(BuildContext context) {
    final navItems = [
      const RoleNavItem(
        label: 'Departments',
        page: AdminDepartmentsScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.business),
          label: 'Depts',
        ),
      ),
      const RoleNavItem(
        label: 'Courses',
        page: AdminCoursesScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.school),
          label: 'Courses',
        ),
      ),
      const RoleNavItem(
        label: 'Students',
        page: AdminStudentsScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.people),
          label: 'Students',
        ),
      ),
      const RoleNavItem(
        label: 'Analytics',
        page: AdminAnalyticsScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
      ),
    ];

    return RoleShellScaffold(
      role: UserRole.admin,
      navigation: _navigation,
      navItems: navItems,
      appBarActions: [
        IconButton(
          icon: Icon(
            ref.watch(themeModeProvider) ? Icons.light_mode : Icons.dark_mode,
          ),
          onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () => ref.read(authRepositoryProvider).signOut(),
        ),
      ],
    );
  }
}
