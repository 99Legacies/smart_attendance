import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:smart_attendance/core/constants/app_constants.dart';
import 'package:smart_attendance/core/theme/app_theme.dart';
import 'package:smart_attendance/domain/entities/attendance_status.dart';
import 'package:smart_attendance/presentation/providers/providers.dart';
import 'package:smart_attendance/presentation/widgets/design_system/app_card.dart';

/// Streams name + enrolled course count directly from the students/{uid}
/// document — the canonical target that admin enrollment writes to.
/// This ensures the greeting card stays in sync with any admin-side change
/// without depending on the separate enrollments collection.
final _studentLiveDataProvider =
    StreamProvider.autoDispose.family<({String? name, int courseCount}), String>(
  (ref, uid) => FirebaseFirestore.instance
      .collection(AppConstants.studentsCollection)
      .doc(uid)
      .snapshots()
      .map((doc) {
        final data = doc.data();
        return (
          name: data?['name'] as String?,
          courseCount: (data?['courseIds'] as List? ?? []).length,
        );
      }),
);

/// Computes attendance rate (0.0–1.0) from all records for the student.
final _studentAttendanceRateProvider =
    StreamProvider.autoDispose.family<double, String>((ref, uid) {
  return ref
      .watch(attendanceRepositoryProvider)
      .watchRecordsForStudent(uid)
      .map((records) {
    if (records.isEmpty) return 0.0;
    final attended = records
        .where(
          (r) =>
              r.status == AttendanceStatus.present ||
              r.status == AttendanceStatus.late,
        )
        .length;
    return attended / records.length;
  });
});

class _SessionData {
  const _SessionData({
    required this.courseName,
    required this.timestamp,
    required this.status,
  });
  final String courseName;
  final DateTime timestamp;
  final AttendanceStatus status;
}

final _studentRecentSessionsProvider =
    StreamProvider.autoDispose.family<List<_SessionData>, String>((ref, uid) async* {
  final attendance = ref.read(attendanceRepositoryProvider);
  final catalog = ref.read(catalogRepositoryProvider);

  // Load enrolled course IDs once for filtering (Hive-first, works offline)
  final student = await catalog.getStudent(uid).timeout(
    const Duration(seconds: 8),
    onTimeout: () => null,
  );
  final enrolledIds = student?.courseIds.toSet() ?? const <String>{};

  await for (final records in attendance.watchRecordsForStudent(uid)) {
    // Records are already sorted newest-first by watchRecordsForStudent
    final filtered = enrolledIds.isEmpty
        ? records.take(5).toList()
        : records
            .where((r) => r.courseId != null && enrolledIds.contains(r.courseId))
            .take(5)
            .toList();

    // Parallel course name lookups with per-request timeout
    final sessions = await Future.wait(
      filtered.map((record) async {
        var courseName = 'Unknown Course';
        if (record.courseId != null && record.courseId!.isNotEmpty) {
          try {
            final course = await catalog.getCourse(record.courseId!).timeout(
              const Duration(seconds: 5),
              onTimeout: () => null,
            );
            if (course != null) courseName = course.name;
          } catch (_) {}
        }
        return _SessionData(
          courseName: courseName,
          timestamp: record.timestamp,
          status: record.status,
        );
      }),
    );

    yield sessions;
  }
});

class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({
    super.key,
    required this.studentUid,
    required this.onScan,
    required this.onHistory,
    required this.onProfile,
    required this.onCourses,
  });

  final String studentUid;
  final VoidCallback onScan;
  final VoidCallback onHistory;
  final VoidCallback onProfile;
  final VoidCallback onCourses;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(_studentLiveDataProvider(studentUid)).asData?.value;
    final authUser = ref.watch(authStateProvider).asData?.value;

    // Live Firestore name takes priority — auth-state name may be null/empty
    // when the profile fetch timed out during login.
    final name = (live?.name?.isNotEmpty == true)
        ? live!.name!
        : (authUser?.name?.isNotEmpty == true ? authUser!.name! : 'Student');
    final dept = authUser?.department ?? '—';

    final attendanceRate =
        ref.watch(_studentAttendanceRateProvider(studentUid));

    return SingleChildScrollView(
      padding: AppTheme.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primary.withValues(alpha: 0.22),
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primary,
                            ),
                          ),
                        ),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: AppTheme.secondary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _greeting(),
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withValues(alpha: 0.75),
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.secondary.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              dept,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: 'Attendance',
                        value: attendanceRate.when(
                          data: (r) => '${(r * 100).round()}%',
                          loading: () => '—',
                          error: (_, _) => '—',
                        ),
                        color: AppTheme.secondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MiniMetric(
                        label: 'Courses',
                        value: live != null
                            ? '${live.courseCount} enrolled'
                            : '…',
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Quick actions', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: kIsWeb ? 4 : 2,
            mainAxisSpacing: kIsWeb ? 8 : 12,
            crossAxisSpacing: kIsWeb ? 8 : 12,
            childAspectRatio: kIsWeb ? 2.5 : 1.05,
            children: [
              _QuickAction(
                icon: Icons.qr_code_scanner_rounded,
                label: 'Scan QR',
                gradient: AppTheme.primaryGradient,
                onTap: onScan,
                delay: 0,
                compact: kIsWeb,
              ),
              _QuickAction(
                icon: Icons.history_rounded,
                label: 'History',
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF5B6BF8)],
                ),
                onTap: onHistory,
                delay: 50,
                compact: kIsWeb,
              ),
              _QuickAction(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                gradient: AppTheme.successGradient,
                onTap: onProfile,
                delay: 100,
                compact: kIsWeb,
              ),
              _QuickAction(
                icon: Icons.school_outlined,
                label: 'Courses',
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFF43F5E)],
                ),
                onTap: onCourses,
                delay: 150,
                compact: kIsWeb,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Recent sessions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          ref.watch(_studentRecentSessionsProvider(studentUid)).when(
            data: (sessions) {
              if (sessions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: Text('No recent sessions')),
                );
              }
              return SizedBox(
                height: 148,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: sessions.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final Color statusColor;
                    final String statusLabel;
                    switch (s.status) {
                      case AttendanceStatus.present:
                        statusColor = AppTheme.secondary;
                        statusLabel = 'Present';
                      case AttendanceStatus.late:
                        statusColor = AppTheme.warning;
                        statusLabel = 'Late';
                      case AttendanceStatus.absent:
                        statusColor = AppTheme.absent;
                        statusLabel = 'Absent';
                    }
                    return AppCard(
                      padding: const EdgeInsets.all(16),
                      onTap: onHistory,
                      child: SizedBox(
                        width: 220,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              s.courseName,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              DateFormat('dd MMM • HH:mm').format(s.timestamp),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.65),
                                  ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(
              height: 148,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => const SizedBox(
              height: 148,
              child: Center(child: Text('No sessions')),
            ),
          ),
          const SizedBox(height: 24),
          _AttendanceRateCard(studentUid: studentUid),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.onTap,
    required this.delay,
    this.compact = false,
  });

  final IconData icon;
  final String label;
  final Gradient gradient;
  final VoidCallback onTap;
  final int delay;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final iconBox = Container(
      width: compact ? 32 : 48,
      height: compact ? 32 : 48,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
      ),
      child: Icon(icon, color: Colors.white, size: compact ? 18 : 24),
    );
    final actionCard = AppCard(
      padding: EdgeInsets.all(compact ? 10 : 16),
      onTap: onTap,
      animate: false,
      child: compact
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconBox,
                const SizedBox(width: 8),
                Text(label, style: Theme.of(context).textTheme.labelMedium),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconBox,
                const SizedBox(height: 12),
                Text(
                  label,
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
    );

    return (actionCard as Widget)
        .animate()
        .fadeIn(delay: delay.ms, duration: 350.ms)
        .slideY(begin: 0.08, end: 0, duration: 350.ms);
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _AttendanceRateCard extends ConsumerWidget {
  const _AttendanceRateCard({required this.studentUid});

  final String studentUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rateAsync = ref.watch(_studentAttendanceRateProvider(studentUid));
    final rate = rateAsync.value ?? 0.0;
    final pct = '${(rate * 100).round()}%';

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: rate,
                  strokeWidth: 6,
                  backgroundColor: AppTheme.outline.withValues(alpha: 0.3),
                  color: AppTheme.secondary,
                  strokeCap: StrokeCap.round,
                ),
                Center(
                  child: rateAsync.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          pct,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attendance rate',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Based on your recent sessions',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _StatusDot(color: AppTheme.present, label: 'Present'),
                    const SizedBox(width: 12),
                    _StatusDot(color: AppTheme.late, label: 'Late'),
                    const SizedBox(width: 12),
                    _StatusDot(color: AppTheme.absent, label: 'Absent'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }
}
