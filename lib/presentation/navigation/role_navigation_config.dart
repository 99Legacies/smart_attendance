import 'package:flutter/material.dart';
import 'package:smart_attendance/presentation/navigation/role_nav_item.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_analytics_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_users_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_analytics_screen.dart';
import 'package:smart_attendance/presentation/screens/lecturer/lecturer_courses_screen.dart';
import 'package:smart_attendance/presentation/screens/student/student_history_screen.dart';
import 'package:smart_attendance/presentation/screens/student/student_scan_screen.dart';

/// Role-specific bottom navigation (max 3 items). Drawer holds secondary routes.
abstract final class RoleNavigationConfig {
  static const int maxBottomNavItems = 3;

  static List<RoleNavItem> admin({
    required Widget homePage,
  }) {
    return [
      RoleNavItem(
        label: 'Home',
        page: homePage,
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
      ),
      const RoleNavItem(
        label: 'User Management',
        page: AdminUsersScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.manage_accounts_outlined),
          selectedIcon: Icon(Icons.manage_accounts),
          label: 'Users',
        ),
      ),
      const RoleNavItem(
        label: 'Analytics',
        page: AdminAnalyticsScreen(),
        destination: NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
      ),
    ];
  }

  static List<RoleNavItem> lecturer({
    required Widget homePage,
    required String lecturerId,
  }) {
    return [
      RoleNavItem(
        label: 'Home',
        page: homePage,
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
      ),
      RoleNavItem(
        label: 'Courses',
        page: LecturerCoursesScreen(lecturerId: lecturerId),
        destination: const NavigationDestination(
          icon: Icon(Icons.school_outlined),
          selectedIcon: Icon(Icons.school),
          label: 'Courses',
        ),
      ),
      RoleNavItem(
        label: 'Analytics',
        page: LecturerAnalyticsScreen(lecturerId: lecturerId),
        destination: const NavigationDestination(
          icon: Icon(Icons.analytics_outlined),
          selectedIcon: Icon(Icons.analytics),
          label: 'Analytics',
        ),
      ),
    ];
  }

  static List<RoleNavItem> student({
    required Widget homePage,
    required String studentUid,
  }) {
    return [
      RoleNavItem(
        label: 'Home',
        page: homePage,
        destination: const NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
      ),
      RoleNavItem(
        label: 'Scan',
        page: StudentScanScreen(studentUid: studentUid),
        destination: const NavigationDestination(
          icon: Icon(Icons.qr_code_scanner),
          label: 'Scan',
        ),
      ),
      RoleNavItem(
        label: 'History',
        page: StudentHistoryScreen(studentUid: studentUid),
        destination: const NavigationDestination(
          icon: Icon(Icons.history_outlined),
          selectedIcon: Icon(Icons.history),
          label: 'History',
        ),
      ),
    ];
  }

  static void assertValidItemCount(List<RoleNavItem> items, String roleName) {
    assert(
      items.length <= maxBottomNavItems,
      '$roleName navigation has ${items.length} items; max is $maxBottomNavItems',
    );
  }
}
