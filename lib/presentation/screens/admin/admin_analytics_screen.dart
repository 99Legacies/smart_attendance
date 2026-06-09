import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/navigation/app_navigation.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/core/widgets/app_card.dart';
import 'package:smart_attendance/domain/entities/user_role.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/screens/admin/admin_detail_screens.dart';
import 'package:smart_attendance/presentation/widgets/report_export_sheet.dart';

class AdminAnalyticsScreen extends ConsumerWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(_systemAnalyticsProvider);
    final uid = ref.watch(authStateProvider).value?.uid ?? '';

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'System analytics',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'A modern view of attendance, course activity, and security events.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: uid.isEmpty
                  ? null
                  : () => showReportExportSheet(
                      context,
                      role: UserRole.admin,
                      userId: uid,
                    ),
              icon: const Icon(Icons.download_outlined),
              label: const Text('Export report'),
            ),
          ),
          const SizedBox(height: 12),
          analyticsAsync.when(
            data: (stats) {
              final cards = [
                _AnalyticsStatCard(
                  label: 'Students',
                  value: stats.students,
                  icon: Icons.people,
                  color: Colors.indigo,
                  onTap: () => AppNavigation.pushSecondary(
                    context,
                    title: 'Students',
                    body: const AdminStudentsDetailScreen(),
                  ),
                ),
                _AnalyticsStatCard(
                  label: 'Lecturers',
                  value: stats.lecturers,
                  icon: Icons.person,
                  color: Colors.cyan,
                  onTap: () => AppNavigation.pushSecondary(
                    context,
                    title: 'Lecturers',
                    body: const AdminLecturersDetailScreen(),
                  ),
                ),
                _AnalyticsStatCard(
                  label: 'Courses',
                  value: stats.courses,
                  icon: Icons.school,
                  color: Colors.deepPurple,
                  onTap: () => AppNavigation.pushSecondary(
                    context,
                    title: 'Courses',
                    body: const AdminCoursesDetailScreen(),
                  ),
                ),
                _AnalyticsStatCard(
                  label: 'Sessions',
                  value: stats.sessions,
                  icon: Icons.event,
                  color: Colors.teal,
                  onTap: () => AppNavigation.pushSecondary(
                    context,
                    title: 'Sessions',
                    body: const AdminSessionsDetailScreen(),
                  ),
                ),
                _AnalyticsStatCard(
                  label: 'Records',
                  value: stats.records,
                  icon: Icons.fact_check,
                  color: Colors.amber,
                  onTap: () => AppNavigation.pushSecondary(
                    context,
                    title: 'Attendance records',
                    body: const AdminRecordsDetailScreen(),
                  ),
                ),
                _AnalyticsStatCard(
                  label: 'Security Logs',
                  value: stats.securityLogs,
                  icon: Icons.security,
                  color: Colors.redAccent,
                  onTap: () => AppNavigation.pushSecondary(
                    context,
                    title: 'Security logs',
                    body: const AdminSecurityLogsScreen(),
                  ),
                ),
              ];

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: MediaQuery.of(context).size.width > 1000
                    ? 3
                    : MediaQuery.of(context).size.width > 640
                    ? 2
                    : 1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.4,
                children: cards,
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsStatCard extends StatelessWidget {
  const _AnalyticsStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.14),
                child: Icon(icon, color: color, size: 24),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(label, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    '$value',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View details',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: color),
                  ),
                  Icon(Icons.arrow_forward, color: color, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SystemStats {
  const _SystemStats({
    required this.students,
    required this.lecturers,
    required this.courses,
    required this.sessions,
    required this.records,
    required this.securityLogs,
  });

  final int students;
  final int lecturers;
  final int courses;
  final int sessions;
  final int records;
  final int securityLogs;
}

final _systemAnalyticsProvider = FutureProvider<_SystemStats>((ref) async {
  final db = FirebaseFirestore.instance;

  Future<int> count(String col) async {
    final snap = await db.collection(col).count().get();
    return snap.count ?? 0;
  }

  return _SystemStats(
    students: await count(AppConstants.studentsCollection),
    lecturers: await count(AppConstants.lecturersCollection),
    courses: await count(AppConstants.coursesCollection),
    sessions: await count(AppConstants.sessionsCollection),
    records: await count(AppConstants.recordsCollection),
    securityLogs: await count(AppConstants.securityLogsCollection),
  );
});
