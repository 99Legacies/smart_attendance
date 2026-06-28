import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/presentation/widgets/design_system/app_card.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_loading.dart';
import 'package:smart_attendance/presentation/widgets/design_system/ap_scaffold.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/navigation/role_navigation_config.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_navigation.dart';
import 'package:smart_attendance/presentation/navigation/role_shell_scaffold.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_courses_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_departments_screen.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_pending_courses_screen.dart';
import 'package:smart_attendance/core/navigation/app_navigation.dart';
import 'package:smart_attendance/presentation/widgets/concise_role_drawer.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _navigation = RoleShellNavigation(logTag: 'AdminShell');
  final _shellKey = GlobalKey<RoleShellScaffoldState>();

  void _openDrawerScreen(BuildContext context, Widget screen, String title) {
    AppNavigation.pushSecondary(context, title: title, body: screen);
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => const ApScaffold(body: ApLoadingList(count: 3)),
      error: (_, _) => const ApScaffold(
        body: ApEmptyState(
          icon: Icons.error_outline,
          title: 'Unable to load profile',
        ),
      ),
      data: (user) {
        if (user == null || user.role != UserRole.admin) {
          _navigation.resolve(role: UserRole.admin, navItems: const []);
          return const ApScaffold(body: ApLoadingList(count: 3));
        }

        final drawerItems = [
          DrawerMenuItem(
            icon: Icons.pending_actions,
            label: 'Pending courses',
            onTap: (ctx) => _openDrawerScreen(
              ctx,
              const AdminPendingCoursesScreen(),
              'Pending courses',
            ),
          ),
          DrawerMenuItem(
            icon: Icons.business,
            label: 'Departments',
            onTap: (ctx) => _openDrawerScreen(
              ctx,
              const AdminDepartmentsScreen(),
              'Departments',
            ),
          ),
          DrawerMenuItem(
            icon: Icons.school,
            label: 'Courses',
            onTap: (ctx) =>
                _openDrawerScreen(ctx, const AdminCoursesScreen(), 'Courses'),
          ),
        ];

        final navItems = RoleNavigationConfig.admin(
          homePage: _HomeTab(
            adminName: user.name ?? 'Admin',
            onUsers: () => _shellKey.currentState?.navigateToTab(1),
            onPending: () => _openDrawerScreen(
              context,
              const AdminPendingCoursesScreen(),
              'Pending courses',
            ),
            onCourses: () => _openDrawerScreen(
              context,
              const AdminCoursesScreen(),
              'Courses',
            ),
          ),
        );
        RoleNavigationConfig.assertValidItemCount(navItems, 'Admin');

        return RoleShellScaffold(
          key: _shellKey,
          role: UserRole.admin,
          navigation: _navigation,
          navItems: navItems,
          titlePrefix: 'Admin — ',
          drawer: ConciseRoleDrawer(
            role: UserRole.admin,
            userName: user.name ?? 'Admin',
            userEmail: user.email,
            userId: user.uid,
            showReportExport: true,
            menuItems: drawerItems,
          ),
        );
      },
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab({
    required this.adminName,
    required this.onUsers,
    required this.onPending,
    required this.onCourses,
  });

  final String adminName;
  final VoidCallback onUsers;
  final VoidCallback onPending;
  final VoidCallback onCourses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $adminName',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Everything you need to manage attendance and university operations at a glance.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: _LiveStatMetric(
                    icon: Icons.school_rounded,
                    label: 'Students',
                    collection: AppConstants.studentsCollection,
                    gradient: AppTheme.successGradient,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: _LiveStatMetric(
                    icon: Icons.person_2_rounded,
                    label: 'Lecturers',
                    collection: AppConstants.lecturersCollection,
                    gradient: AppTheme.primaryGradient,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: AppCard(
                  child: _LiveStatMetric(
                    icon: Icons.menu_book_rounded,
                    label: 'Courses',
                    collection: AppConstants.coursesCollection,
                    gradient: AppTheme.warningGradient,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppCard(
                  child: _LiveStatMetric(
                    icon: Icons.apartment_rounded,
                    label: 'Departments',
                    collection: AppConstants.departmentsCollection,
                    gradient: AppTheme.dangerGradient,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          _QuickActionCard(
            icon: Icons.people_alt_outlined,
            title: 'User Management',
            subtitle: 'View, filter, and manage registered users',
            gradient: AppTheme.primaryGradient,
            onTap: onUsers,
          ),
          const SizedBox(height: 10),
          _QuickActionCard(
            icon: Icons.pending_actions,
            title: 'Pending courses',
            subtitle: 'Review lecturer course proposals',
            gradient: AppTheme.warningGradient,
            onTap: onPending,
          ),
          const SizedBox(height: 10),
          _QuickActionCard(
            icon: Icons.school_outlined,
            title: 'Courses',
            subtitle: 'Add and edit course catalog',
            gradient: AppTheme.successGradient,
            onTap: onCourses,
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withValues(alpha: 0.85)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveStatMetric extends ConsumerWidget {
  const _LiveStatMetric({
    required this.icon,
    required this.label,
    required this.collection,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String collection;
  final Gradient gradient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(collection).snapshots(),
      builder: (context, snap) {
        final count = snap.hasData ? snap.data!.size.toString() : '—';
        return _StatMetric(
          icon: icon,
          label: label,
          value: count,
          gradient: gradient,
        );
      },
    );
  }
}

class _StatMetric extends StatelessWidget {
  const _StatMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.gradient,
  });

  final IconData icon;
  final String label;
  final String value;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

